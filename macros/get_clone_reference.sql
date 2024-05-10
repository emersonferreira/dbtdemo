{% macro get_clone_reference(model_name) %}
    {{ adapter.dispatch.render_node(
        node=dbt.utils.ModelSource(
            database=None,
            schema=env_var("DBT_CLONE_SCHEMA"),
            identifier=model_name
        ),
        node_context={}
    ) }}
{% endmacro %}
