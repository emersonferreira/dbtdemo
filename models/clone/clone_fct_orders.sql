{{
    config(
        materialized='table'
    )
}}

select 
    *,
    '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' as _audit_run_id,
    '{{ run_started_at.astimezone(modules.pytz.timezone("Australia/Sydney")) }}' as run_started_est
from {{ target.schema }}_marts.fct_orders