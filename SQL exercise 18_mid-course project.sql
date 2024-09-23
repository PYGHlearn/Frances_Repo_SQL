use mavenfuzzyfactory;

/* 
1. Gsearch is the biggest driver of the business. 
so, pull monthly trends for gsearch sessions and orders to showcase growth. 
*/

select
	year(website_sessions.created_at) as Yr,
    month(website_sessions.created_at) as Mth,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conversion_rate
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.utm_source = 'gsearch'
	and website_sessions.created_at < '2012-11-27'
group by 1,2;

/* 
2. next, split out nonbrand and brand campaigns for gsearch sessions.alter
want to know if brand is picking up at all. 
*/

select
	year(website_sessions.created_at) as Yr,
    month(website_sessions.created_at) as Mth,
    count(distinct case when utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as nonbrand_sessions,
    count(distinct case when utm_campaign = 'nonbrand' then order_id else null end) as nonbrand_orders,
    count(distinct case when utm_campaign = 'brand' then website_sessions.website_session_id else null end) as brand_sessions,
    count(distinct case when utm_campaign = 'brand' then order_id else null end) as brand_orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.utm_source = 'gsearch'
	and website_sessions.created_at < '2012-11-27'
group by 1,2;

/*
for gsearch, dive into nonbrand, pull monthly trend by device type.
show the board that we really know our traffic
*/

select
	year(website_sessions.created_at) as Yr,
    month(website_sessions.created_at) as Mth,
    count(distinct case when device_type = 'desktop' then website_sessions.website_session_id else null end) as desktop_sessions,
    count(distinct case when device_type = 'desktop' then order_id else null end) as desktop_orders,
    count(distinct case when device_type = 'mobile' then website_sessions.website_session_id else null end) as mobile_sessions,
    count(distinct case when device_type = 'mobile' then order_id else null end) as mobile_orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.utm_source = 'gsearch'
	and website_sessions.created_at < '2012-11-27'
group by 1,2;

/* pull monthly trends for Gsearch, 
alongside monthly trends for each of other channels
*/

-- first, find the various utm_source channels and referers to see the traffic we are getting

select
	year(website_sessions.created_at) as Yr,
    month(website_sessions.created_at) as Mth,
    count(distinct case when utm_source='gsearch' then website_sessions.website_session_id else null end) as gsearch_paid_sessions,
    count(distinct case when utm_source='bsearch' then website_sessions.website_session_id else null end) as bsearch_paid_sessions,
	count(distinct case when utm_source is null and http_referer is not null then website_sessions.website_session_id else null end) as organic_search_sessions,
	count(distinct case when utm_source is null and http_referer is null then website_sessions.website_session_id else null end) as direct_type_in_sessions
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where 
	website_sessions.created_at < '2012-11-27'
group by 1,2;


/* 
5. show the story of website performance improvement over the course of the first 8 months
pull session to order conversion rate, by month
*/

select
	year(website_sessions.created_at) as Yr,
    month(website_sessions.created_at) as Mth,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conversion_rate
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where 
	website_sessions.created_at < '2012-11-27'
group by 1, 2;

/*
6. for the gsearch lander test, estimate the revenue that test earned use
(hint: look at the increase in CVR from the test (6/19 - 7/28)
and use nonbrand sessions and revenue since then to calculate incremental value)
*/

use mavenfuzzyfactory;

select
	min(website_pageviews.website_pageview_id) as first_test_pv
from website_pageviews
where pageview_url = '/lander-1';

-- for this step, find the first pageview id for each session

create temporary table first_test_pageviews
select
	website_pageviews.website_session_id,
    min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
	inner join website_sessions
		on website_pageviews.website_session_id = website_sessions.website_session_id
        and website_sessions.created_at < '2012-07-28'
        and website_pageviews.website_pageview_id >= 23504  -- first pageview id
        and website_sessions.utm_source = 'gsearch'
        and website_sessions.utm_campaign = 'nonbrand'
group by 
	website_pageviews.website_session_id;
    
-- next, bring in the landing page to each session, restrict to home and lander-1

create temporary table nonbrand_test_sessions_w_landing_pages
select
	first_test_pageviews.website_session_id,
    website_pageviews.pageview_url as landing_page
from first_test_pageviews
	left join website_pageviews
		on first_test_pageviews.min_pageview_id = website_pageviews.website_pageview_id
where 
	website_pageviews.pageview_url in ('/home', '/lander-1');

-- then make a table to bring in orders

create temporary table nonbrand_test_sessions_w_orders
select
	nonbrand_test_sessions_w_landing_pages.website_session_id,
    nonbrand_test_sessions_w_landing_pages.landing_page,
    orders.order_id as order_id
from nonbrand_test_sessions_w_landing_pages
	left join orders
		on nonbrand_test_sessions_w_landing_pages.website_session_id = orders.website_session_id;
        

-- to find the difference between conversion rates
select
	landing_page,
    count(distinct website_session_id) as sessions,
    count(distinct order_id) as orders,
    count(distinct order_id)/count(distinct website_session_id) as conversion_rate
from nonbrand_test_sessions_w_orders
group by landing_page;

-- 0.0318 for /home page, vs. 0.0406 for /lander-1 page
-- 0.0087 additional order per session

-- find the most recent pageview for gsearch nonbrand where the traffic was sent to /home page

select
	max(website_sessions.website_session_id) as most_recent_gsearch_nonbrand_home_pageview
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where utm_source = 'gsearch'
	and utm_campaign = 'nonbrand'
    and pageview_url = '/home'
    and website_sessions.created_at < '2012-11-27';
    
-- max website_session_id = 17145

select
	count(distinct website_session_id) as sessions_since_test
from website_sessions
where
	created_at < '2012-11-27'
    and website_session_id > 17145  -- last /home session before switching to lander-1 landing page
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand';
    
-- 22,972 website sessions since the test
-- multiply 0.0087 incremental conversion = 202 incremental orders since 7/29
	-- roughly 4 months, so roughtly 50 extra orders per month, not bad.  
    

/* 
7. for the landing page test you analyzed previously, show a full conversion funnel
from each of the two pages to order.
ok to use time period you analyzed last time 6/19 - 7/28.  
*/

-- to be used as subquery

select 
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at as pageview_created_at, 
    case when pageview_url = '/home' then 1 else 0 end as homepage,
    case when pageview_url = '/lander-1' then 1 else 0 end as custom_lander,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page, 
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where 
	website_sessions.created_at < '2012-07-28' 
    and website_sessions.created_at > '2012-06-19'
	and website_sessions.utm_source = 'gsearch'
    and website_sessions.utm_campaign = 'nonbrand'
order by
	website_sessions.website_session_id,
    website_pageviews.created_at;


create temporary table session_level_made_it_flagged2
select
	website_session_id,
    max(homepage) as saw_homepage,
    max(custom_lander) as saw_custom_lander,
	max(products_page) as product_made_it,
    max(mrfuzzy_page) as mrfuzzy_made_it,
    max(cart_page) as cart_made_it,
    max(cart_page) as shipping_made_it,
    max(cart_page) as billing_made_it,
    max(cart_page) as thankyou_made_it
from(
select 
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at as pageview_created_at, 
    case when pageview_url = '/home' then 1 else 0 end as homepage,
    case when pageview_url = '/lander-1' then 1 else 0 end as custom_lander,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page, 
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where 
	website_sessions.created_at < '2012-07-28' 
    and website_sessions.created_at > '2012-06-19'
	and website_sessions.utm_source = 'gsearch'
    and website_sessions.utm_campaign = 'nonbrand'
order by
	website_sessions.website_session_id,
    website_pageviews.created_at
) as pageview_content

group by 
	website_session_id;


-- then this would produce the final output, part 1

select
	case
		when saw_homepage = 1 then 'saw_homepage'
        when saw_custom_lander =1 then 'saw_custom_lander'
        else 'uh oh ... check logic'
	end as segment,
	count(distinct website_session_id) as sessions,
    count(distinct case when product_made_it = 1 then website_session_id else null end) as to_products,
    count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end) as to_mrfuzzy,
	count(distinct case when cart_made_it = 1 then website_session_id else null end) as to_cart,
    count(distinct case when shipping_made_it = 1 then website_session_id else null end) as to_shipping,
    count(distinct case when billing_made_it = 1 then website_session_id else null end) as to_billing,
    count(distinct case when thankyou_made_it = 1 then website_session_id else null end) as to_thankyou
from session_level_made_it_flagged2
group by 1;

-- final output part 2 - click rates

select
	case
		when saw_homepage = 1 then 'saw_homepage'
        when saw_custom_lander =1 then 'saw_custom_lander'
        else 'uh oh ... check logic'
	end as segment,
	count(distinct website_session_id) as sessions,
    count(distinct case when product_made_it = 1 then website_session_id else null end)
		/count(distinct website_session_id) as lander_click_rate,
    count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end)
		/count(distinct case when product_made_it = 1 then website_session_id else null end) as product_click_rate,
	count(distinct case when cart_made_it = 1 then website_session_id else null end)
		/count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end) as mrfuzzy_click_rate,
    count(distinct case when shipping_made_it = 1 then website_session_id else null end)
		/count(distinct case when cart_made_it = 1 then website_session_id else null end) as cart_click_rate,
    count(distinct case when billing_made_it = 1 then website_session_id else null end)
		/count(distinct case when shipping_made_it = 1 then website_session_id else null end) as shipping_click_rate,
    count(distinct case when thankyou_made_it = 1 then website_session_id else null end)
		/count(distinct case when billing_made_it = 1 then website_session_id else null end) as billing_click_rate
from session_level_made_it_flagged2
group by 1;

/* 
8. quantify the impact of billing test, as well
analyze the lift generated from the test (9/10 - 11/10), in terms of revenue per billing page session
then pull the number of billing page sessions for the past month to understand monthly impact. 
*/

-- create a subquery

select
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id,
    orders.price_usd
from website_pageviews
	left join orders
		on website_pageviews.website_session_id = orders.website_session_id

where website_pageviews.created_at > '2012-09-10'
	and website_pageviews.created_at > '2012-11-10'
    and website_pageviews.pageview_url in ('/billing', '/billing-2');
    
-- add the subquery as a table for the new query

select
	billing_version_seen,
    count(distinct website_session_id) as sessions,
    sum(price_usd)/count(distinct website_session_id) as revenue_per_billing_page_seen
from(
select
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id,
    orders.price_usd
from website_pageviews
	left join orders
		on website_pageviews.website_session_id = orders.website_session_id
where website_pageviews.created_at > '2012-09-10'
	and website_pageviews.created_at > '2012-11-10'
    and website_pageviews.pageview_url in ('/billing', '/billing-2')
) as billing_pageviews_and_order_data
group by 1;

-- $22.83 revenue per billing page seen for the old version
-- $31.34 for the new version
-- lift:  $8.52 per billing page view. 

select
	count(website_session_id) as billing_sessions_past_month
from website_pageviews
where pageview_url in ('/billing', '/billing-2')
	and created_at between '2012-10-27' and '2012-11-27';


-- 1,194 billing sessions past month
-- lift:  $8.52 per billing page view.
-- value of billing test: $10,160.  