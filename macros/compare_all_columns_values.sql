{%- test compare_all_columns_values(model, a_relation, b_relation, exclude_columns, primary_key) -%}
{%- if execute -%}
    with
        base_compare_table as (
            {{
                audit_helper.compare_all_columns(
                    a_relation=model,
                    b_relation=b_relation,
                    exclude_columns=exclude_columns,
                    primary_key=primary_key,
                )
            }}
            where conflicting_values > 0
        )

    select *
    from base_compare_table

{%- endif -%}
{%- endtest -%}