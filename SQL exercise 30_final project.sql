-- final advanced MySQL course project

use mavenfuzzyfactory;

/*
1. first, show the volume growth. 
pull overall session and order volume trended by quarter for the life of the business.
recent quarter is incomplete, you decide how to handle it.
*/


select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1, 2
order by 1, 2
;
        

/*
2. next, showcase all efficient improvements.  
show quarterly figures since launch, for session-to-order conversion rate, revenue per order, and revenue per session.
*/

select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders, 
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conversion_rate,
    sum(orders.price_usd) as revenue,
    sum(orders.price_usd)/count(distinct orders.order_id) as revenue_per_order,
    sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1, 2
order by 1, 2
;


/*
3. show how the business have grown specific channels. 
pull a quarterly view of orders from Gsearch nonbrand, Bsearch nonbrand,
brand search overall, organic search, and direct type in.  
*/

select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    -- utm_source
    -- utm_campaign
    -- http_referer
    count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end) as gsearch_nonbrand_orders,
    count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end) as bsearch_nonbrand_orders,
    count(distinct case when utm_campaign = 'brand' then orders.order_id else null end) as brand_search_orders,
    count(distinct case when utm_source is null and http_referer is not null then orders.order_id else null end) as organic_search_orders,
    count(distinct case when utm_source is null and http_referer is null then orders.order_id else null end) as direct_type_in_orders
    
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1, 2
order by 1, 2
;


/*
4. show the overall session-to-order conversion rate trends for those same channels, by quarter
make a note of any period where the business made major improvements or optimization
*/

select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    -- utm_source
    -- utm_campaign
    -- http_referer
    count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end)
		/count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as gsearch_nonbrand_conv_rate,
    count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end)
		/count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as bsearch_nonbrand_conv_rate,
    count(distinct case when utm_campaign = 'brand' then orders.order_id else null end)
		/count(distinct case when utm_campaign = 'brand' then website_sessions.website_session_id else null end) as brand_search_conv_rate,
    count(distinct case when utm_source is null and http_referer is not null then orders.order_id else null end)
		/count(distinct case when utm_source is null and http_referer is not null then website_sessions.website_session_id else null end) as organic_search_conv_rate,
    count(distinct case when utm_source is null and http_referer is null then orders.order_id else null end)
		/count(distinct case when utm_source is null and http_referer is null then website_sessions.website_session_id else null end) as direct_type_in_conv_rate
    
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1, 2
order by 1, 2
;


/*
5. pull monthly trend for revenue and margin by product
along with total sales and revenue.
note anything you notice about seasonality.
*/

select
	year(created_at) as yr,
    month(created_at) as mth,
    sum(case when product_id = 1 then price_usd else null end) as mrfuzzy_rev,
    sum(case when product_id = 1 then price_usd - cogs_usd else null end) as mrfuzzy_margin,
    sum(case when product_id = 2 then price_usd else null end) as lovebear_rev,
    sum(case when product_id = 2 then price_usd - cogs_usd else null end) as lovebear_margin,
    sum(case when product_id = 3 then price_usd else null end) as birthdaybear_rev,
    sum(case when product_id = 3 then price_usd - cogs_usd else null end) as birthdaybear_margin,
    sum(case when product_id = 4 then price_usd else null end) as minibear_rev,
    sum(case when product_id = 4 then price_usd - cogs_usd else null end) as minibear_margin,
    sum(price_usd) as total_revenue,
    sum(price_usd - cogs_usd) as total_margin
from order_items
group by 1,2
order by 1,2
;


/*
6. dive deeper into the impact of introducing new products. 
pull monthly sessions to the /products page
show how the % of those sessions clicking through another page has changed over time, 
along with a view of how conversion from /products to placing an order has improved.  
*/

-- first, identifying all the views of the /product page

create temporary table products_pageviews2
select
	website_session_id,
    website_pageview_id,
    created_at as saw_product_page_at
from website_pageviews
where pageview_url = '/products'
;

select * from products_pageviews2;

drop table products_pageviews;
drop table products_pageviews1;

select
	year(saw_product_page_at) as yr,
    month(saw_product_page_at) as mth,
    count(distinct products_pageviews2.website_session_id) as sessions_to_product,
    count(distinct website_pageviews.website_session_id) as clicked_to_next_page,
    count(distinct website_pageviews.website_session_id)/count(distinct products_pageviews2.website_session_id) as clickthrough_rate,
	count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct products_pageviews2.website_session_id) as prod_to_order_rate
from products_pageviews2
	left join website_pageviews
		on website_pageviews.website_session_id = products_pageviews2.website_session_id
        and website_pageviews.website_pageview_id > products_pageviews2.website_pageview_id
	left join orders
		on products_pageviews2.website_session_id = orders.website_session_id
group by 1,2
;


/*
7. made 4th product available as a primary product on 12/5/2014 
(it was previously only a cross-sell item). 
please pull sales data since then, and
show how well each product cross-sells from one another
*/

create temporary table primary_products
select
	order_id,
    primary_product_id,
    created_at as ordered_at
from orders
where created_at > '2014-12-05'
;


-- create a subquery for next query, identify the primary product with cross-sold product added

select
	primary_products.*,
    order_items.product_id as cross_sell_product_id
from primary_products
	left join order_items
		on primary_products.order_id = order_items.order_id
        and order_items.is_primary_item = 0  -- meaning the order item is not a primary product item
;


-- add the subquery to the main query

select
	primary_product_id,
    count(distinct order_id) as total_orders,
    
    count(distinct case when cross_sell_product_id = 1 then order_id else null end) as x_sold_prod1,
    count(distinct case when cross_sell_product_id = 2 then order_id else null end) as x_sold_prod2,
    count(distinct case when cross_sell_product_id = 3 then order_id else null end) as x_sold_prod3,
    count(distinct case when cross_sell_product_id = 4 then order_id else null end) as x_sold_prod4,
    
    count(distinct case when cross_sell_product_id = 1 then order_id else null end)/count(distinct order_id) as x_sold_prod1_rate,
    count(distinct case when cross_sell_product_id = 2 then order_id else null end)/count(distinct order_id) as x_sold_prod2_rate,
    count(distinct case when cross_sell_product_id = 3 then order_id else null end)/count(distinct order_id) as x_sold_prod3_rate,
    count(distinct case when cross_sell_product_id = 4 then order_id else null end)/count(distinct order_id) as x_sold_prod4_rate
    
from (
select
	primary_products.*,
    order_items.product_id as cross_sell_product_id
from primary_products
	left join order_items
		on primary_products.order_id = order_items.order_id
        and order_items.is_primary_item = 0
	) as primary_w_cross_sell
group by 1
;

/*
8. In addition to telling investors about what we've already achieved,
also show them that we still have plenty of gas in the tank.
based on all the analysis done, could you share some 
recommendations and opportunities for the business going forward?
no right or wrong answer. Just to hear your perspective.
*/











