{{
    config(
        materialized='ephemeral'
    )
}}

with fct_orders_temp as (
    select
        *,
        RANK() over (order by amount desc) as rank
    from {{ ref('fct_orders') }}
),

final as (
    select
        * except(rank)
    from fct_orders_temp
    where rank <= 10
)

select
    *
from final