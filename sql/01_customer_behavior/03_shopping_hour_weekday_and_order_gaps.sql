--which hour of the day and day of the week has highest order activity.

select
    count(*) as total_orders,
    order_day_of_week,
    order_hour_of_day
from silver_tables.vw_orders_explore
GROUP by order_day_of_week,order_hour_of_day
order by count(*) desc;

---days since first order
SELECT
    round( AVG(days_since_prior_order),2) as avg_days_betn_order,
    min(days_since_prior_order) as min_days_order,
    max(days_since_prior_order) as max_days_order,
    round(STDEV(days_since_prior_order),2) as days_order_std_dev
from silver_tables.vw_orders_explore
where days_since_prior_order is not NULL;

