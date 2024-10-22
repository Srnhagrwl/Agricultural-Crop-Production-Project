CREATE DATABASE Crop_project;
USE Crop_project;
select * from crop_production ORDER BY Crop_Year;

                 --Calculate crop yield (production per unit area) to assess which crops are the most efficient in production--
SELECTCrop,
	Area,
	 Production,
	ROUND((Production/Area), 2) as Crop_yield
FROM
	crop_production
ORDER BY
	Crop_yield DESC;


	       --Calculates each state's average yield (production per area) and identifies the top N states with the highest average yield over multiple years--
WITH CTE AS(
	SELECT
		State_Name,
		Crop_Year,
		Production,
		Area,
		ROUND(AVG(Production/Area), 2) as average_yield,
		DENSE_RANK() OVER(PARTITION BY Crop_Year ORDER BY AVG(Production/Area) DESC) as rnk
	FROM
		crop_production
	GROUP BY
		State_Name,
		Crop_Year,
		Production,
		Area
)
SELECT
	State_Name,
	Crop_Year,
	average_yield
FROM
	CTE
WHERE
	rnk = 1

SELECT
	State_Name,
	Crop_Year,
	ROUND(AVG(Production/Area), 2) as average_yield
FROM
	crop_production
GROUP BY
	State_Name,
	Crop_Year
ORDER BY
	average_yield DESC


	                 --Calculates the year-over-year percentage growth in crop production for each state and crop--

SELECT
    current_year.State_Name,
    current_year.Crop,
    current_year.Crop_Year,
    current_year.production AS current_production,
    previous.production AS previous_production,
	case when
		previous.Production > 0
	then
		((current_year.production - previous.production) / previous.production) * 100
	else
		null
	end AS yoy_growth_percentage
FROM
    crop_production current_year
JOIN
    crop_production previous
    ON current_year.State_Name = previous.State_Name
    AND current_year.Crop = previous.Crop
    AND current_year.Crop_Year = previous.Crop_Year + 1
ORDER BY
    current_year.State_Name,
    current_year.Crop,
    current_year.Crop_Year;

	                         --Calculates the variance in production across different crops and states--

SELECT
	Crop,
	State_Name,
	VAR(Production) AS Variance_In_Production
FROM
	crop_production
GROUP BY
	Crop,
	State_Name
ORDER BY
	State_Name,
	Crop

                     --Identifies states that have the largest increase in cultivated area for a specific crop between two years--

with years_grouping as(
	select
		State_Name,
		Crop_Year,
		Crop,
		CONCAT(FLOOR((crop_year - 1997) / 2) * 2 + 1997, '-', FLOOR((crop_year - 1997) / 2) * 2 + 1998) as Year_group,
		sum(Area) as total_area
	from
		crop_production
	group by
		Crop_Year,
		State_Name,
		Crop
),
previous_area_table as(
	select
		State_Name,
		Year_group,
		Crop,
		total_area as current_area,
		LAG(total_area, 1) over(partition by year_group order by total_area desc) as previous_area
	from
		years_grouping
),
Total_area_changed as(
	Select
		State_Name,
		Crop,
		Year_group,
		current_area,
		previous_area,
		(previous_area - current_area) as changed_area
	from
		previous_area_table
),
ranking as(
	select
		State_Name,
		Year_group,
		Crop,
		changed_area,
		DENSE_RANK() over(partition by Year_group order by changed_area desc) as rnk
	from
		Total_area_changed
)
select
	State_Name,
	Crop,
	Year_group,
	changed_area
from
	ranking
where
	rnk = 1;