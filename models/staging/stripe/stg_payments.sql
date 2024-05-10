{{
    config(
        materialized=env_var('DBT_STAGING_MAT')
    )
}}

select
    payments.id as payment_id,
    payments.order_id as order_id,
    payments.payment_method as payment_method,
    orders.status,

    -- amount is stored in cents, convert it to dollars
    payments.amount / 100 as amount,
    orders.order_date as created_at

from {{ source('stripe', 'payments') }} payments
left join {{ source('jaffle_shop', 'orders') }} orders on orders.id = payments.order_id