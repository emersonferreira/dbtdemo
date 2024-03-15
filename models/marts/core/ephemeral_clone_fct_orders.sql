{{
    config(
        materialized='ephemeral'
    )
}}

select * from {{ ref('clone_fct_orders') }}