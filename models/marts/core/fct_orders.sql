{{
    config(
        tags = ['contains_pii','hr'],
        labels = {'pii_data': 'true', 'human_resource_data': ''}
    )
}}

with
    orders as (select * from {{ ref("stg_orders") }}),

    payments as (select * from {{ ref("stg_payments") }}),

    order_payments as (
        select order_id, sum(case when status = 'completed' then amount end) as amount

        from payments
        group by 1
    ),

    final as (

        select
            orders.order_id,
            orders.customer_id,
            orders.order_date,
            coalesce(order_payments.amount, 0) + 5 as amount,
            CURRENT_DATETIME() as updated_at

        from orders
        left join order_payments on orders.order_id = order_payments.order_id
    )

select *
from final
where extract(month from order_date) <= 2
