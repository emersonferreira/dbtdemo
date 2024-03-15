{% macro delete_tables_by_tag(tag) -%}
    -- Create an array variable to store all tables with a specific tag
    {% set models_with_tag = [] %}

    -- Navigate in all models and retrieve the model name that uses a specific tag
    {% for model in graph.nodes.values() | selectattr("resource_type", "equalto", "model") %}

        {% if tag in model.config.tags %}
            {{ models_with_tag.append(model.name) }}
        {% endif %}

    {% endfor %}

    -- Execute the drop table statement for all tables into the models_with_tag array
    {% for model_name in models_with_tag %}
    
    {%- set drop_query -%}
        DROP TABLE IF EXISTS {{ ref(model_name) }}
    {%- endset -%}
    {% do run_query(drop_query) %}

    {% endfor %}

{%- endmacro %}