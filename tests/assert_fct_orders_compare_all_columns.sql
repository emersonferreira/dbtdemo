with
    base_clone_fct_orders as (
        select * from {{ ref('clone_fct_orders') }}
    ),
    base_fct_orders as (
        {{
            audit_helper.compare_all_columns(
                a_relation=ref("fct_orders"),
                b_relation=ref("ephemeral_clone_fct_orders"),
                exclude_columns=["updated_at","audit_run_id", "run_started_est"],
                primary_key="order_id",
            )
        }}
        where conflicting_values > 0
    )

select *
from base_fct_orders
