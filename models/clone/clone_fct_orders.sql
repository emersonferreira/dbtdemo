{{
    config(
        materialized='table',
        tags=['clone_model']
    )
}}

select 
    *,
    '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' as audit_run_id,
    '{{ env_var("DBT_CLOUD_RUN_ID", "manual") }}' as audit_run_id_v2,
    '{{ run_started_at.astimezone(modules.pytz.timezone("Australia/Sydney")) }}' as run_started_est
from {{ ref("fct_orders") }}