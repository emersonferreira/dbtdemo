{%- test expect_amount_in_between(model, column_name, min_value, max_value) -%}
{%- if execute -%}
    with base_test_cte as (
        select {{ column_name }},
            case 
                when {{ column_name }} < {{ min_value }} then false
                when {{ column_name }} > {{ max_value }} then false
                else true
            end as result
        from {{ model }}
    )

    select * from base_test_cte
    where result = false

{%- endif -%}
{%- endtest -%}