select
    *
from {{ source('jaffle_shop', 'sentencing_data_csv') }}