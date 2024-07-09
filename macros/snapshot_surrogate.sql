{% macro snapshot_surrogate(staging_model) %}

{% set cols = adapter.get_columns_in_relation(relation=ref(staging_model)) %}
{% set col_names = [] %}
{% for col in cols %}
    {% set col_names = col_names.append(col.name) %}
{% endfor %}

select distinct * from (
    select 
        *,
        {{dbt_utils.generate_surrogate_key(col_names)}} as snapshot_row_key,
        count( {{ dbt_utils.generate_surrogate_key(col_names) }} ) over (partition by {{dbt_utils.generate_surrogate_key(col_names)}}) as snapshot_row_key_count
    from {{ ref(staging_model) }}
)

 
{% endmacro %}