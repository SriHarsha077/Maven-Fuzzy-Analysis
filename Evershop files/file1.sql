
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



/* 06. For the gsearch lander test, 
please estimate the revenue that test earned us (Hint: Look at the increase in CVR 
from the test (Jun 19 – Jul 28), 
and use nonbrand sessions and revenue since then to calculate incremental value) */


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


/* 08.  I’d love for you to quantify the impact of our billing test, as well. 
Please analyze the lift generated from the test 
(Sep 10 – Nov 10), in terms of revenue per billing page session, 
and then pull the number of billing page sessions 
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
and created_at<'2012-11-10'

-- result is 1311 sessions are there in last month.
-- 1311*8.512= 11159.232 dollars are the last month revenue from billing-2 page change test
-- $11,159 revenue last month







/* I would like to request an analysis to identify which product has the highest success rate. 
Specifically, could you provide insights into the total revenue generated and the total refund amounts for each product?
 This will allow us to determine which product demonstrates the most favorable performance metrics.
 */



SELECT 
    o.primary_product_id,
    p.product_name,
    SUM(b.refund_amount_usd) AS total_refund_amount,
    SUM(o.price_usd) AS total_revenue,
    CASE 
        WHEN SUM(b.refund_amount_usd) = 0 THEN SUM(o.price_usd)  -- To avoid division by zero
        ELSE SUM(o.price_usd) / SUM(b.refund_amount_usd) 
    END AS success_rate
FROM 
    orders AS o
LEFT JOIN 
    order_item_refunds AS b ON o.order_id = b.order_id
JOIN 
    products AS p ON o.primary_product_id = p.product_id
GROUP BY 
    o.primary_product_id, p.product_name
ORDER BY 
    success_rate DESC;  -- Order by success rate for easy comparison
--- For the Gsearch lander test, please estimate the revenue that test earned us.
WITH ProductSuccessRates AS (
    SELECT 
        o.primary_product_id,
        p.product_name,
        SUM(b.refund_amount_usd) AS total_refund_amount,
        SUM(o.price_usd) AS total_revenue,
        CASE 
            WHEN SUM(b.refund_amount_usd) = 0 THEN SUM(o.price_usd)  -- To avoid division by zero
            ELSE SUM(o.price_usd) / SUM(b.refund_amount_usd) 
        END AS success_rate
    FROM 
        orders AS o
    LEFT JOIN 
        order_item_refunds AS b ON o.order_id = b.order_id
    JOIN 
        products AS p ON o.primary_product_id = p.product_id
    GROUP BY 
        o.primary_product_id, p.product_name
)

SELECT 
    primary_product_id,
    product_name,
    total_revenue,
    total_refund_amount,
    success_rate,
    RANK() OVER (ORDER BY success_rate DESC) AS success_rank
FROM 
    ProductSuccessRates
ORDER BY 
    success_rate DESC;


