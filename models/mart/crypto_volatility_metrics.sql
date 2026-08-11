-- models/marts/crypto_volatility_metrics.sql
--
-- stg_crypto_prices üzerine window fonksiyonlarıyla:
-- - Günlük yüzde getiri
-- - 7 ve 30 günlük hareketli ortalama fiyat
-- - 7 ve 30 günlük hareketli volatilite (günlük getirinin std sapması)
-- hesaplar. Volatilite, "riskin" temel ölçüsüdür: ne kadar yüksekse
-- fiyat o kadar oynak demektir.

with prices as (

    select
        price_date,
        coin_id,
        symbol,
        price_usd
    from {{ ref('stg_crypto_prices') }}

),

with_daily_return as (

    select
        price_date,
        coin_id,
        symbol,
        price_usd,
        lag(price_usd) over (
            partition by coin_id order by price_date
        ) as prev_price_usd,
        safe_divide(
            price_usd - lag(price_usd) over (partition by coin_id order by price_date),
            lag(price_usd) over (partition by coin_id order by price_date)
        ) as daily_return

    from prices

),

with_rolling_metrics as (

    select
        price_date,
        coin_id,
        symbol,
        price_usd,
        daily_return,

        -- 7 günlük hareketli ortalama fiyat
        avg(price_usd) over (
            partition by coin_id
            order by price_date
            rows between 6 preceding and current row
        ) as moving_avg_price_7d,

        -- 30 günlük hareketli ortalama fiyat
        avg(price_usd) over (
            partition by coin_id
            order by price_date
            rows between 29 preceding and current row
        ) as moving_avg_price_30d,

        -- 7 günlük volatilite (günlük getirinin std sapması)
        stddev(daily_return) over (
            partition by coin_id
            order by price_date
            rows between 6 preceding and current row
        ) as volatility_7d,

        -- 30 günlük volatilite
        stddev(daily_return) over (
            partition by coin_id
            order by price_date
            rows between 29 preceding and current row
        ) as volatility_30d

    from with_daily_return

)

select
    price_date,
    coin_id,
    symbol,
    price_usd,
    round(daily_return * 100, 2)        as daily_return_pct,
    round(moving_avg_price_7d, 4)       as moving_avg_price_7d,
    round(moving_avg_price_30d, 4)      as moving_avg_price_30d,
    round(volatility_7d * 100, 2)       as volatility_7d_pct,
    round(volatility_30d * 100, 2)      as volatility_30d_pct
from with_rolling_metrics
order by symbol, price_date