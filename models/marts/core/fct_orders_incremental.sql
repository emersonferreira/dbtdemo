{{
    config(
        materialized='incremental',
        partition_by={
            "field": "order_date",
            "data_type": "date",
            "granularity": "day"
        },
        partition_expiration_days = 6825
    )
}}

with final as (
    select * from {{ ref('fct_orders') }}

    {% if is_incremental() %}
        -- this filter will only be applied on an incremental run
        -- (uses >= to include records arriving later on the same day as the last run of this model)
        where order_date >= date_add((select max(order_date) from {{ this }}), interval -7 day)
    {% endif %}
)

select
    order_id,
    customer_id,
    DATE_ADD(order_date, INTERVAL 5 YEAR) as order_date,
    amount,
    CAST('2024-04-12T02:28:49' AS DATETIME) as updated_at,
    notes_number
from final