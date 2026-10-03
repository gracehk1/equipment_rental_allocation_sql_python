/** DATA ANALYSIS for Financial Utilization = (Annualized Revenue)/OEC **/



--generate missing dates for rental_date. Need to make sure all asset_ids have revenue for entire 2017. If asset_id did not earn revenue for a month, show 0 for rental_revneue.
WITH full_rental_dates AS (
	SELECT 
		GENERATE_SERIES(MIN(rental_date), '2017-12-01', INTERVAL '1 month')::date AS full_rental_date
	FROM equipment_rentals
)

--prep distinct equipment_rental columns to do cross join with full_rental_dates
, distinct_columns AS (
	SELECT DISTINCT 
		rental_id
		,asset_id
		,market_id
	FROM equipment_rentals
)

--need intermediate cte for all rental_ids to map to entire generated 2017 rental_date
,mapped_rental_date AS (
SELECT 
	rental_id
	,asset_id
	,market_id
	,full_rental_date
FROM full_rental_dates
CROSS JOIN distinct_columns --each row of the first table is paired with every row of the second table
ORDER BY rental_id
)

--Now that all asset_ids have rental_date period from 2017-01-01 to 2017-12-01, show 0 for rental_revenue 
SELECT 
	m.rental_id
	,m.asset_id
	,m.market_id
	,m.full_rental_date
	,COALESCE(SUM(e.rental_revenue), 0)
FROM mapped_rental_date AS m --left join to show all rental_date period from 2017-01-01 to 2017-12-01
LEFT JOIN equipment_rentals AS e ON m.full_rental_date = e.rental_date AND m.rental_id = e.rental_id
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4
;


SELECT * FROM equipment_asset_oec
ORDER BY asset_id, market_id;

SELECT * FROM equipment_rentals WHERE rental_id = 2056 ORDER BY rental_id,asset_id, market_id, rental_date; --rental_id 2056, asset_id 1176, missing 2017-05-01 ~ 2017-12-01