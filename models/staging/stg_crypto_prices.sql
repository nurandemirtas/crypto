with source as (
 
    select
        date,
        coin_id,
        symbol,
        price_usd
    from `data-analysis-504814.crypto_analysis.crypto`
 
),
 
cleaned as (
 
    select
        cast(date as date)          as price_date,
        cast(coin_id as string)     as coin_id,
        cast(symbol as string)      as symbol,
        cast(price_usd as float64)  as price_usd
    from source
    where price_usd is not null
 
),
 
deduped as (
 
    select
        price_date,
        coin_id,
        symbol,
        avg(price_usd) as price_usd
    from cleaned
    group by price_date, coin_id, symbol
 
)
 
select * from deduped