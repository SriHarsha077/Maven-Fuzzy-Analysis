CREATE database  evershop;
use evershop;

CREATE TABLE website_sessions (
    website_session_id INT,
    created_at DATETIME,
    user_id INT,
    is_repeat_session INT,
    utm_source VARCHAR(45),
    utm_campaign VARCHAR(45),
    utm_content VARCHAR(45),
    device_type VARCHAR(50),
    http_referer VARCHAR(50)
);
 
select * from website_sessions;
SHOW VARIABLES LIKE 'secure_file_priv';
 
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\website_sessions.csv'
INTO TABLE website_sessions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
 
CREATE TABLE website_pageviews(
	website_pageview_id INT,	
	created_at DATETIME,
	website_session_id INT,
	pageview_url varchar(255)
);
select * from website_pageviews;
SHOW VARIABLES LIKE 'secure_file_priv';
 
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\website_pageviews.csv"
INTO TABLE website_pageviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;



/* 01. Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions 
and orders so that we can showcase the growth there? */

select
	year(website_sessions.created_at) as Yr,
    Month(website_sessions.created_at) as Mon,
    count(website_sessions.website_session_id) as sessions,
    count(orders.order_id) as orders,
    count(orders.order_id)/count(website_sessions.website_session_id) as conv_rates
from website_sessions
	left join orders
		on website_sessions.website_session_id=orders.website_session_id
where website_sessions.created_at<'2012-11-27'
and website_sessions.utm_source='gsearch'
group by 1,2;


 
 
 /* 02. Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and 
brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell. */

use evershop;
select
    year(website_sessions.created_at) as Yr,
    Month(website_sessions.created_at) as Mon,
    count(case when website_sessions.utm_campaign='nonbrand' then website_sessions.website_session_id else null end) as nonbrand_sessions,
    count(case when website_sessions.utm_campaign='nonbrand' then orders.order_id else null end) as nonbrand_orders,
    count(case when website_sessions.utm_campaign='brand' then website_sessions.website_session_id else null end) as brand_sessions,
    count(case when website_sessions.utm_campaign='brand' then orders.order_id else null end) as brand_orders
from website_sessions
	left join orders
		on website_sessions.website_session_id=orders.website_session_id
where website_sessions.created_at<'2012-11-27'
and website_sessions.utm_source='gsearch'
group by 1,2;


/* 03. While we’re on Gsearch, could you dive into nonbrand, and pull monthly 
sessions and orders split by device 3 type? I want to flex our analytical muscles a little and show the board we really know our traffic sources. */


use evershop;
select
    year(website_sessions.created_at) as Yr,
    Month(website_sessions.created_at) as Mon,
    count(case when website_sessions.device_type='mobile' then website_sessions.website_session_id else null end) as mobile_sessions,
    count(case when website_sessions.device_type='mobile' then orders.order_id else null end) as mobile_orders,
    count(case when website_sessions.device_type='desktop' then website_sessions.website_session_id else null end) as desktop_sessions,
    count(case when website_sessions.device_type='desktop' then orders.order_id else null end) as desktop_orders
from website_sessions
	left join orders
		on website_sessions.website_session_id=orders.website_session_id
where website_sessions.created_at<'2012-11-27'
and website_sessions.utm_source='gsearch'
and website_sessions.utm_campaign='nonbrand'
group by 1,2;


/* 04. I’m worried that one of our more pessimistic board members may be concerned about the 
large % of traffic from 4 Gsearch. Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels */

use evershop;
select distinct
	utm_source,
    utm_campaign,
    http_referer
from website_sessions
where created_at<'2012-11-27';

select 
	year(created_at) as yr,
    month(created_at) as mon,
    count(distinct case when utm_source='gsearch' then website_session_id else null end) as gsearch_paidtraffic_sessions,
    count(distinct case when utm_source='bsearch' then website_session_id else null end) as bsearch_paidtraffic_Sessions,
    count(distinct case when utm_source is null and http_referer is not null then website_session_id else null end) as organic_search_Sessions,
    count(distinct case when utm_source is null and http_referer is null then website_session_id else null end) as direct_type_in_Sessions
from website_sessions
where created_at<'2012-11-27'
group by 1,2;



/* 05.  I’d like to tell the story of our website performance improvements over the course of the 
first 8 months. Could you pull session to order conversion rates, by month? */

use evershop;
select
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mon,
    count(website_sessions.website_session_id) as sessions,
    count(orders.order_id) as orders,
    count(orders.order_id)/count(website_sessions.website_session_id) as conv_rates
from website_sessions
	left join orders
		on website_sessions.website_session_id=orders.website_session_id
where website_sessions.created_at<'2012-11-27'
group by 1,2;



/* 06. For the gsearch lander test, please estimate the revenue that test earned us (Hint: Look at the increase in CVR 
from the test (Jun 19 – Jul 28), and use nonbrand sessions and revenue since then to calculate incremental value) */


USE evershop;

SELECT
	MIN(website_pageview_id) AS first_test_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';



-- for this step, we'll find the first pageview id 

CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	website_pageviews.website_session_id, 
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews 
	INNER JOIN website_sessions 
		ON website_sessions.website_session_id = website_pageviews.website_session_id
		AND website_sessions.created_at < '2012-07-28' -- prescribed by the assignment
		AND website_pageviews.website_pageview_id >= 23504 -- first page_view
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY 
	website_pageviews.website_session_id;

-- next, we'll bring in the landing page to each session, like last time, but restricting to home or lander-1 this time
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_pages
SELECT 
	first_test_pageviews.website_session_id, 
    website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
	LEFT JOIN website_pageviews 
		ON website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url IN ('/home','/lander-1'); 

-- SELECT * FROM nonbrand_test_sessions_w_landing_pages;

-- then we make a table to bring in orders
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_orders
SELECT
	nonbrand_test_sessions_w_landing_pages.website_session_id, 
    nonbrand_test_sessions_w_landing_pages.landing_page, 
    orders.order_id AS order_id

FROM nonbrand_test_sessions_w_landing_pages
LEFT JOIN orders 
	ON orders.website_session_id = nonbrand_test_sessions_w_landing_pages.website_session_id
;

-- SELECT * FROM nonbrand_test_sessions_w_orders;

-- to find the difference between conversion rates 
SELECT
	landing_page, 
    COUNT(DISTINCT website_session_id) AS sessions, 
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS conv_rate
FROM nonbrand_test_sessions_w_orders
GROUP BY 1; 

-- .0319 for /home, vs .0406 for /lander-1 
-- .0087 additional orders per session

-- finding the most recent pageview for gsearch nonbrand where the traffic was sent to /home
SELECT 
	MAX(website_sessions.website_session_id) AS most_recent_gsearch_nonbrand_home_pageview 
FROM website_sessions 
	LEFT JOIN website_pageviews 
		ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    AND pageview_url = '/home'
    AND website_sessions.created_at < '2012-11-27'
;
-- max website_session_id = 17145


SELECT 
	COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-27'
	AND website_session_id > 17145 -- last /home session
	AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
;
-- 22,972 website sessions since the test

-- X .0087 incremental conversion = 202 incremental orders since 7/29
	-- roughly 4 months, so roughly 50 extra orders per month. Not bad!


/* 07. For the landing page test you analyzed previously, it would be great to show a full conversion funnel from each 
of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28). */

USE evershop;
SELECT
	website_sessions.website_session_id, 
    website_pageviews.pageview_url, 
    -- website_pageviews.created_at AS pageview_created_at, 
    CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page, 
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions 
	LEFT JOIN website_pageviews 
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.utm_source = 'gsearch' 
	AND website_sessions.utm_campaign = 'nonbrand' 
    AND website_sessions.created_at < '2012-07-28'
		AND website_sessions.created_at > '2012-06-19'
ORDER BY 
	website_sessions.website_session_id,
    website_pageviews.created_at;


CREATE TEMPORARY TABLE session_level_made_it_flagged
SELECT
	website_session_id, 
    MAX(homepage) AS saw_homepage, 
    MAX(custom_lander) AS saw_custom_lander,
    MAX(products_page) AS product_made_it, 
    MAX(mrfuzzy_page) AS mrfuzzy_made_it, 
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT
	website_sessions.website_session_id, 
    website_pageviews.pageview_url, 
    -- website_pageviews.created_at AS pageview_created_at, 
    CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page, 
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions 
	LEFT JOIN website_pageviews 
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.utm_source = 'gsearch' 
	AND website_sessions.utm_campaign = 'nonbrand' 
    AND website_sessions.created_at < '2012-07-28'
		AND website_sessions.created_at > '2012-06-19'
ORDER BY 
	website_sessions.website_session_id,
    website_pageviews.created_at
) AS pageview_level

GROUP BY 
	website_session_id
;


-- then this would produce the final output, part 1
SELECT
	CASE 
		WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'uh oh... check logic' 
	END AS segment, 
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_made_it_flagged 
GROUP BY 1
;


-- then this as final output part 2 - click rates

SELECT
	CASE 
		WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'uh oh... check logic' 
	END AS segment, 
	COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS lander_click_rt,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS products_click_rt,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM session_level_made_it_flagged
GROUP BY 1
;


/* 08.  I’d love for you to quantify the impact of our billing test, as well. Please analyze the lift generated from the test 
(Sep 10 – Nov 10), in terms of revenue per billing page session, and then pull the number of billing page sessions 
for the past month to understand monthly impact*/

use evershop;
create temporary table billing_pages
select
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id,
    orders.price_usd
from website_pageviews
	left join orders
		on website_pageviews.website_session_id=orders.website_session_id
where website_pageviews.created_at>'2012-09-10'
and website_pageviews.created_at<'2012-11-10'
and website_pageviews.pageview_url in ('/billing','/billing-2');

-- select*from billing_pages

select 
	billing_version_seen,
    count(distinct website_session_id) as sessions,
    SUM(price_usd)/count(distinct website_session_id) as revenue_per_billing_page_seen
from billing_pages
group by 1;

-- here in results for billing page RPBP = 0.4566 but for billing-2 page RPBP = 0.6269
-- as we got increase of 31.339-22.826 = 8.512 dollars has increased per session seen by changing billing page to billing-2 page

-- now we calculate how revenue generated for last whole month from this change.
-- find last month total session from billing-2 and multiply with this 8.512 to get total revenue

select 
	count(website_session_id) as billing_session_last_mon
from website_pageviews
where website_pageviews.pageview_url  in ('/billing','/billing-2')
and created_at>'2012-09-10'
and created_at<'2012-11-10';

-- result is 1311 sessions are there in last month.
-- 1311*8.512= 11159.232 dollars are the last month revenue from billing-2 page change test
-- $11,159 revenue last month



/*-------------------------------Final Course Project------------------------------------------------*/

/* Question 01 : First, I’d like to show our volume growth. Can you pull overall session and order volume, trended by quarter 
for the life of the business? Since the most recent quarter is incomplete, you can decide how to handle it.*/

use evershop;

select 
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
	count(distinct website_sessions.website_session_id) as total_sessions,
    count(distinct orders.order_id) as total_orders
from website_sessions
left join orders
	on website_sessions.website_session_id=orders.website_session_id
group by 1,2
order by 1,2;

/* Question 02: Next, let’s showcase all of our efficiency improvements. I would love to show quarterly figures since we 
launched, for session-to-order conversion rate, revenue per order, and revenue per session. */

select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
	-- count(distinct website_sessions.website_session_id) as total_sessions,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate,
    sum(price_usd)/count(distinct orders.order_id) as rev_per_orders,
    sum(price_usd)/count(distinct website_sessions.website_session_id) as rev_per_session
from website_sessions
left join orders
	on website_sessions.website_session_id=orders.website_session_id
group by 1,2
order by 1,2;


/* Question 03: I’d like to show how we’ve grown specific channels. Could you pull a quarterly view of orders from Gsearch 
nonbrand, Bsearch nonbrand, brand search overall, organic search, and direct type-in? */

select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct case when utm_source = 'gsearch' and utm_campaign='nonbrand' then orders.order_id else null end) as Gsearch_nonbrand_orders,
	count(distinct case when utm_source = 'bsearch' and utm_campaign='nonbrand' then orders.order_id else null end) as Bsearch_nonbrand_orders,
	count(distinct case when utm_campaign='brand' then orders.order_id else null end) as Brand_overall_orders,
	count(distinct case when utm_source is NULL and http_referer is NULL then orders.order_id else null end) as direct_type_in_orders,
	count(distinct case when utm_source is NULL and http_referer in('https://www.gsearch.com', 'https://www.bsearch.com') then orders.order_id else null end) as Organic_search_orders
from website_sessions
		left join orders
			on website_sessions.website_session_id=orders.website_session_id
	group by 1,2
    order by 1,2;
    
    
/* Question 04: Next, let’s show the overall session-to-order conversion rate trends for those same channels, by quarter. 
Please also make a note of any periods where we made major improvements or optimizations.*/

select
	year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct case when utm_source = 'gsearch' and utm_campaign='nonbrand' then orders.order_id else null end)
			/count(distinct case when utm_source = 'gsearch' and utm_campaign='nonbrand' then website_sessions.website_session_id else null end) as Gsearch_nonbrand_conv,
	count(distinct case when utm_source = 'bsearch' and utm_campaign='nonbrand' then orders.order_id else null end)
			/count(distinct case when utm_source = 'bsearch' and utm_campaign='nonbrand' then website_sessions.website_session_id else null end) as Bsearch_nonbrand_conv,
	count(distinct case when utm_campaign='brand' then orders.order_id else null end)/
			count(distinct case when utm_campaign='brand' then website_sessions.website_session_id else null end) as Brand_overall_conv,
	count(distinct case when utm_source is NULL and http_referer is NULL then orders.order_id else null end)
			/count(distinct case when utm_source is NULL and http_referer is NULL then website_sessions.website_session_id else null end) as direct_type_in_conv,
	count(distinct case when utm_source is NULL and http_referer in('https://www.gsearch.com', 'https://www.bsearch.com') then orders.order_id else null end)
			/count(distinct case when utm_source is NULL and http_referer in('https://www.gsearch.com', 'https://www.bsearch.com') then website_sessions.website_session_id else null end) as Organic_search_conv
from website_sessions
		left join orders
			on website_sessions.website_session_id=orders.website_session_id
	group by 1,2
    order by 1,2;

/* Question 05: We’ve come a long way since the days of selling a single product. Let’s pull monthly trending for revenue 
and margin by product, along with total sales and revenue. Note anything you notice about seasonality */

select 
	year(created_at) as yr,
    month(created_at) as mon,
    sum(case when product_id=1 then price_usd else null end) as mrfuzzy_rev,
    sum(case when product_id=1 then price_usd-cogs_usd else null end) as mrfuzzy_marg,
    sum(case when product_id=2 then price_usd else null end) as lovebear_rev,
    sum(case when product_id=2 then price_usd-cogs_usd else null end) as lovebear_marg,
	sum(case when product_id=3 then price_usd else null end) as birthdaybear_rev,
	sum(case when product_id=3 then price_usd-cogs_usd else null end) as birthdaybear_marg,
    sum(case when product_id=4 then price_usd else null end) as minibear_rev,
    sum(case when product_id=4 then price_usd-cogs_usd else null end) as minibear_marg,
    sum(price_usd) as total_revenue,
    sum(price_usd-cogs_usd) as total_margin
from order_items
group by 1,2
order by 1,2
;

/* Question 06: Let’s dive deeper into the impact of introducing new products. Please pull monthly sessions to the /products 
page, and show how the % of those sessions clicking through another page has changed over time, along with 
a view of how conversion from /products to placing an order has improved */

create temporary table product_pageviews
select 
	website_session_id,
    website_pageview_id,
    created_at as product_page_seen_at
from website_pageviews
where pageview_url='/products';
    
-- select*from product_pageviews

select 
	year(product_page_seen_at) as yr,
    month(product_page_seen_at) as mon,
    count(distinct product_pageviews.website_session_id) as sessions_to_product_page,
    count(distinct website_pageviews.website_session_id) as clicked_to_next_page,
    count(distinct website_pageviews.website_session_id)/count(distinct product_pageviews.website_session_id) as clickthru_rt,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct product_pageviews.website_session_id) as product_to_order_rt
from product_pageviews
	left join website_pageviews
		on website_pageviews.website_session_id=product_pageviews.website_session_id
        and website_pageviews.website_pageview_id>product_pageviews.website_pageview_id
	left join orders
		on orders.website_session_id=product_pageviews.website_session_id
group by 1,2;


/* Question 07: We made our 4th product available as a primary product on December 05, 2014 (it was previously only a cross-sell 
item). Could you please pull sales data since then, and show how well each product cross-sells from one another? */

create temporary table primary_products
select
	order_id,
    primary_product_id,
    created_at as ordered_at
from orders
where created_at>'2014-12-05'   -- when the 4th product was added 
;
-- select*from primary_products

select 
	primary_product_id,
    count(distinct order_id) as total_orders,
    count(distinct case when cross_sell_product_id=1 then order_id else null end) as _xsold_p1,
    count(distinct case when cross_sell_product_id=2 then order_id else null end) as _xsold_p2,
    count(distinct case when cross_sell_product_id=3 then order_id else null end) as _xsold_p3,
    count(distinct case when cross_sell_product_id=4 then order_id else null end) as _xsold_p4,
    count(distinct case when cross_sell_product_id=1 then order_id else null end)/count(distinct order_id) as p1_xsell_rt,
    count(distinct case when cross_sell_product_id=2 then order_id else null end)/count(distinct order_id) as p2_xsell_rt,
    count(distinct case when cross_sell_product_id=3 then order_id else null end)/count(distinct order_id) as p3_xsell_rt,
    count(distinct case when cross_sell_product_id=4 then order_id else null end)/count(distinct order_id) as p4_xsell_rt
from 
	(
		select
			primary_products.*,
			order_items.product_id as cross_sell_product_id
		from primary_products
			left join order_items
				on order_items.order_id=primary_products.order_id
                and order_items.is_primary_item=0 -- only bringing in cross-sells;
		) as primary_w_cross_sell
	group by 1;










