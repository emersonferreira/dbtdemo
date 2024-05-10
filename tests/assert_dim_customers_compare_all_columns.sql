with
    base_dim_customers as (
        {{
            audit_helper.compare_all_columns(
                a_relation=ref('dim_customers'),
                b_relation=api.Relation.create(
                    database=env_var('DBT_DB'), schema=env_var('DBT_CLONE_SCHEMA', 'dev_clone'), identifier="clone_dim_customers"
                ),
                exclude_columns=["_audit_run_id", "run_started_est"],
                primary_key="customer_id",
            )
        }}
        where conflicting_values > 0
    )

select *
from base_dim_customers
