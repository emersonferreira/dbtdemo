{% snapshot snap_bdm_sentencing %}

    {{ config(unique_key="snapshot_row_key", strategy="check", check_cols="all", target_schema=env_var('DBT_SNP_SCHEMA')) }}
    with final as ({{ snapshot_surrogate("stg_sentencing_data") }})
    select *
    from final

{% endsnapshot %}
