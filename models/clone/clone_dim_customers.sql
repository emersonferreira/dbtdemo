{{
    config(
        materialized='table',
        tags=['clone_model']
    )
}}

select 
    *,
    '{{ env_var("DBT_CLOUD_RUN_ID", "manualy") }}' as _audit_run_id,
    '{{ run_started_at.astimezone(modules.pytz.timezone("Australia/Sydney")) }}' as run_started_est
from {{ ref('dim_customers') }}