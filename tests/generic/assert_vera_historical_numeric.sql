{% test assert_vera_historical_numeric(model, date_column, distinct_column, interval, abs_value, time_fraction, remove_n_outliers=0) %}

{# Set the current_runmonth_day variable with BigQuery functions to parse string value to Date #}
{% set current_runmonth_day = "PARSE_DATE('%Y%m%d', '" ~ var('current_runmonth') ~ "01')"%}

{# Set the current_interval_value variable with BigQuery function to get the latest day of that month #}
{% set current_interval_value = "LAST_DAY(" ~ current_runmonth_day ~ ")" %}

{# Determine the date format based on the time fraction (month, week, day, year) #}
{% if time_fraction|upper == 'MONTH' %}
{%   set format_value = '%Y-%m' %}
{% elif time_fraction|upper == 'WEEK' %}
{%   set format_value = '%Y-%W' %}
{% elif time_fraction|upper == 'DAY' %}
{%   set format_value = '%Y-%m-%d' %}
{% elif time_fraction|upper == 'YEAR' %}
{%   set format_value = '%Y' %}
{% else %}
{%   set format_value = '%Y-%m' %}
{% endif %}

{# Get the row count for distinct values in the specified interval #}
WITH get_row_count as (
    select
        count(distinct {{ distinct_column }}) as row_count,
        FORMAT_DATE({{ "'" ~ format_value ~ "'" }}, DATE({{ date_column }})) as interval_{{ time_fraction|lower }}
    from {{ model }}
    where DATE({{ date_column }}) > DATE_ADD({{ current_interval_value }}, INTERVAL -({{ interval }} + 1) {{ time_fraction }})
    and DATE({{ date_column }}) <= {{ current_interval_value }}
    group by FORMAT_DATE({{ "'" ~ format_value ~ "'" }}, DATE({{ date_column }}))
),

{# Get the previous row count using the LAG function to access the previous row #}
get_previous_row_count as (
    select
        *,
        coalesce(lag(row_count, 1) over (order by interval_{{ time_fraction|lower }}), 0) as previous_row_count
    from get_row_count
),

{# Compare the current row count with the previous row count #}
compare_row_count as(
    select
        *,
        (previous_row_count - row_count) as diff_row_count
    from get_previous_row_count
),

{# Validate the difference in row count, marking as pass if the difference is within the acceptable absolute value #}
validate_diff_row_count as (
    select
        *,
        case
            when abs(diff_row_count) > {{ abs_value }} then
                FALSE
            else
                TRUE
        end as pass
    from compare_row_count
    order by interval_{{ time_fraction|lower }} desc
    limit {{ interval }}
),

{# Rank the rows based on the absolute value of the row count difference #}
rank_validate_diff_row_count as (
    select
        *,
        RANK() OVER (ORDER BY abs(diff_row_count) DESC) AS diff_row_count_rank
    from validate_diff_row_count
),

{# Select the final set of rows, excluding the top N outliers #}
final as (
    select
        *
    from rank_validate_diff_row_count
    where diff_row_count_rank > {{ remove_n_outliers }}
    order by interval_{{ time_fraction|lower }}
)

{# Return the rows where the validation failed (pass is not TRUE) #}
select
    *
from final
where pass <> TRUE

{% endtest %}