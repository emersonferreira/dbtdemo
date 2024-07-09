{% test assert_vera_percentage(model, compare_to_table, date_column, distinct_column, first_interval, max_interval, first_interval_value, second_interval_value, time_fraction, compare_table_is_snapshot=FALSE, remove_n_outlier=0) %}

{# Set the current_runmonth_day variable with BigQuery functions to parse string value to Date #}
{% set current_runmonth_day = "PARSE_DATE('%Y%m%d', '" ~ var('current_runmonth') ~ "01')"%}

{# Set the current interval value to the last day of the month specified by 'current_runmonth' variable #}
{% set current_interval_value = "LAST_DAY(" ~ current_runmonth_day ~ ")" %}

{# Calculate the maximum limit for the second interval based on the difference between max_interval and first_interval #}
{% set max_limit = max_interval - first_interval %}

{# Determine the date format based on the time_fraction (e.g., month, week, day, year) #}
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

{# Get current row count for the first interval #}
WITH get_current_row_count_first_interval as (
    select
        count(distinct {{ distinct_column }}) as current_row_count,
        FORMAT_DATE({{ "'" ~ format_value ~ "'" }}, DATE({{ date_column }})) as interval_{{ time_fraction|lower }}
    from {{ model }}
    where DATE({{ date_column }}) > DATE_ADD({{ current_interval_value }}, INTERVAL -{{ first_interval }} {{ time_fraction }})
    and DATE({{ date_column }}) <= {{ current_interval_value }}
    group by FORMAT_DATE({{ "'" ~ format_value ~ "'" }}, DATE({{ date_column }}))
),

{# Get previous row count for the first interval from the comparison table #}
get_previous_row_count_first_interval as (
    select
        count(distinct {{ distinct_column }}) as previous_row_count,
        FORMAT_DATE({{ "'" ~ format_value ~ "'" }}, DATE({{ date_column }})) as interval_{{ time_fraction|lower }}
    from {{ compare_to_table }}
    where DATE({{ date_column }}) > DATE_ADD({{ current_interval_value }}, INTERVAL -{{ first_interval }} {{ time_fraction }})
    and DATE({{ date_column }}) <= {{ current_interval_value }}
    {% if compare_table_is_snapshot %}
    and dbt_valid_to is null
    {% endif %}
    group by FORMAT_DATE({{ "'" ~ format_value ~ "'" }}, DATE({{ date_column }}))
),

{# Get current row count for the second interval #}
get_current_row_count_second_interval as (
    select
        count(distinct {{ distinct_column }}) as current_row_count,
        FORMAT_DATE({{ "'" ~ format_value ~ "'" }}, DATE({{ date_column }})) as interval_{{ time_fraction|lower }}
    from {{ model }}
    where DATE({{ date_column }}) <= DATE_ADD({{ current_interval_value }}, INTERVAL -{{ first_interval }} {{ time_fraction }})
    group by FORMAT_DATE({{ "'" ~ format_value ~ "'" }}, DATE({{ date_column }}))
    order by 2 desc
    limit {{ max_limit }}
),

{# Get previous row count for the second interval from the comparison table #}
get_previous_row_count_second_interval as (
    select
        count(distinct {{ distinct_column }}) as previous_row_count,
        FORMAT_DATE({{ "'" ~ format_value ~ "'" }}, DATE({{ date_column }})) as interval_{{ time_fraction|lower }}
    from {{ compare_to_table }}
    where DATE({{ date_column }}) <= DATE_ADD({{ current_interval_value }}, INTERVAL -{{ first_interval }} {{ time_fraction }})
    {% if compare_table_is_snapshot %}
    and dbt_valid_to is null
    {% endif %}
    group by FORMAT_DATE({{ "'" ~ format_value ~ "'" }}, DATE({{ date_column }}))
    order by 2 desc
    limit {{ max_limit }}
),

{# Compare current and previous row counts for the first interval #}
compare_table_first_interval as (
    select
        current_data.current_row_count,
        coalesce(previous.previous_row_count, 0) as previous_row_count,
        current_data.interval_{{ time_fraction|lower }},
        TRUE as first_interval,
        (current_data.current_row_count - coalesce(previous.previous_row_count, 0)) as diff_row_count,
        ((current_data.current_row_count - coalesce(previous.previous_row_count, 0)) / current_data.current_row_count) * 100 as perc_row_count
    from get_current_row_count_first_interval current_data
    left join get_previous_row_count_first_interval previous on current_data.interval_{{ time_fraction|lower }} = previous.interval_{{ time_fraction|lower }}
),

{# Compare current and previous row counts for the second interval #}
compare_table_second_interval as (
    select
        current_data.current_row_count,
        coalesce(previous.previous_row_count, 0) as previous_row_count,
        current_data.interval_{{ time_fraction|lower }},
        FALSE as first_interval,
        (current_data.current_row_count - coalesce(previous.previous_row_count, 0)) as diff_row_count,
        ((current_data.current_row_count - coalesce(previous.previous_row_count, 0)) / current_data.current_row_count) * 100 as perc_row_count
    from get_current_row_count_second_interval current_data
    left join get_previous_row_count_second_interval previous on current_data.interval_{{ time_fraction|lower }} = previous.interval_{{ time_fraction|lower }}
),

{# Validate differences in row counts for the first interval #}
validate_first_interval as (
    select
        *,
        case
        when abs(perc_row_count) > {{ first_interval_value }} then
            FALSE
        else
            TRUE
        end as draft_pass
    from compare_table_first_interval
),

{# Validate differences in row counts for the second interval #}
validate_second_interval as (
    select
        *,
        case
        when abs(perc_row_count) > {{ second_interval_value }} then
            FALSE
        else
            TRUE
        end as draft_pass
    from compare_table_second_interval
),

{# Additional validation for the current interval #}
validate_current_interval as (
    select 
        *,
        case
            when interval_{{ time_fraction|lower }} = {{ "'" ~ var('current_runmonth') ~ "'" }} and current_row_count = 0 then
                FALSE
            else
                draft_pass
        end as final_pass
    from validate_first_interval
),

{# Combine comparisons for both intervals #}
combined_comparison as (
  select  
    *
  from validate_current_interval
  union all
  select
    *,
    draft_pass as final_pass
  from validate_second_interval
  order by interval_{{ time_fraction|lower }}
),

{# Rank the combined results by row count difference #}
ranked_by_row_count as (
    select
        *,
        RANK() OVER (ORDER BY abs(perc_row_count) DESC) AS diff_row_count_rank
    from combined_comparison
),

{# Final selection, excluding rows based on outlier removal threshold #}
final as (
    select
        * except(diff_row_count_rank)
    from ranked_by_row_count
    where diff_row_count_rank > {{ remove_n_outlier }}
    order by interval_{{ time_fraction|lower }}
)

{# Select final results where validation failed #}
select
    *
from final
where final_pass <> TRUE

{% endtest %}