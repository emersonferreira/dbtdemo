{{
    config(
        materialized='table'
    )
}}

with order_fct_orders as (
    select
        *
    from {{ ref('eph_remove_top_10') }}
    order by amount, order_date
),

final as (
    select
        *
    from order_fct_orders
    limit 5
)

select
    *
from final