SELECT * FROM us_household_income.ushouseholdincome;
SELECT * FROM us_household_income.ushouseholdincome_statistics;

-- changing badly formatted column name during import
ALTER TABLE us_household_income.ushouseholdincome_statistics RENAME COLUMN `ï»¿id` TO `ID`;

-- check for number of ids in each table, it is a bit less than the amount in original csv files so some where missing during import
SELECT COUNT(ID) FROM us_household_income.ushouseholdincome_statistics;
SELECT COUNT(ID) FROM us_household_income.ushouseholdincome;

-- check for duplicate id in household income table
SELECT ID, COUNT(ID)
FROM us_household_income.ushouseholdincome
GROUP BY ID
HAVING COUNT(ID) >1;

-- delete duplicate id from household income table
DELETE FROM us_household_income.ushouseholdincome
WHERE row_id IN (
	SELECT row_id
	FROM (SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY ID ORDER BY ID) row_num 
	FROM us_household_income.ushouseholdincome) as Duplicate
	WHERE row_num > 1);

-- check for duplicate id in household income stats table; none found
SELECT ID, COUNT(ID)
FROM us_household_income.ushouseholdincome_statistics
GROUP BY ID
HAVING COUNT(ID) >1;

-- checking for consistency in state name, as one seems wrong
SELECT DISTINCT state_name
FROM us_household_income.ushouseholdincome
GROUP BY state_name;
-- found georia instead of Georgia

-- updating the name georia
UPDATE us_household_income.ushouseholdincome
SET state_name = 'Georgia'
WHERE state_name = 'georia';

-- updating name alabama to Alabama
UPDATE us_household_income.ushouseholdincome
SET state_name = 'Alabama'
WHERE state_name = 'alabama';

-- check for consistency in state abbreviation, everything seems correct
SELECT DISTINCT state_ab
FROM us_household_income.ushouseholdincome
ORDER BY 1;

-- there's one row where Place contains no data
SELECT *
FROM us_household_income.ushouseholdincome
WHERE Place = '';

-- populate the missing Place
UPDATE us_household_income.ushouseholdincome
SET Place = 'Autaugaville'
WHERE county = 'Autauga County' AND city = 'Vinemont';

-- checking Type, found Borough and Boroughs
SELECT Type, COUNT(type)
FROM us_household_income.ushouseholdincome
GROUP BY type;

-- change Boroughs into Borough
UPDATE us_household_income.ushouseholdincome
SET Type = 'Borough'
WHERE Type = 'Boroughs';

-- checking Aland, Awater
SELECT Aland
FROM us_household_income.ushouseholdincome
WHERE aland = 0 OR aland = '' OR aland IS NULL;

SELECT Awater
FROM us_household_income.ushouseholdincome
WHERE awater = 0 OR awater = '' OR awater IS NULL;

-- EDA -- 

-- checking for largest land, top 10
SELECT state_name, SUM(aland), SUM(awater)
FROM us_household_income.ushouseholdincome
GROUP BY state_name
ORDER BY 2 DESC
LIMIT 10;

-- checking for largest water, top 10
SELECT state_name, SUM(aland), SUM(awater)
FROM us_household_income.ushouseholdincome
GROUP BY state_name
ORDER BY 3 DESC
LIMIT 10;

-- joining the two tables using id
SELECT * 
FROM us_household_income.ushouseholdincome u
JOIN us_household_income.ushouseholdincome_statistics us
	ON u.id = us.id
ORDER BY 1;

-- some data have missing mean, median, stdev; exclude those
-- look at the average and median income from each state
SELECT u.state_name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income.ushouseholdincome u
JOIN us_household_income.ushouseholdincome_statistics us
	ON u.id = us.id
WHERE mean <> 0
GROUP BY u.state_name
ORDER BY 2;
-- this is data from 2022, the average household income in Mississippi is around 5k, that's pretty low!

-- explore the income data by type
SELECT type, COUNT(type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income.ushouseholdincome u
JOIN us_household_income.ushouseholdincome_statistics us
	ON u.id = us.id
WHERE mean <> 0
GROUP BY type
ORDER BY 3 DESC;
-- screenshot

-- for median income
SELECT type, COUNT(type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income.ushouseholdincome u
JOIN us_household_income.ushouseholdincome_statistics us
	ON u.id = us.id
WHERE mean <> 0
GROUP BY type
ORDER BY 4 DESC;
-- screenshot: CDP and Track have very high median income

-- look at which state has the Communities (low income)
SELECT DISTINCT State_Name, type
FROM ushouseholdincome
WHERE Type  = 'Community';
-- Puerto Rico！

-- now filter out outliers
SELECT type, COUNT(type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income.ushouseholdincome u
JOIN us_household_income.ushouseholdincome_statistics us
	ON u.id = us.id
WHERE mean <> 0
GROUP BY type
HAVING COUNT(type) > 100
ORDER BY 4 DESC;


SELECT u.state_name, city, ROUND(AVG(mean),1)
FROM us_household_income.ushouseholdincome u
JOIN us_household_income.ushouseholdincome_statistics us
	ON u.id = us.id
GROUP BY u.state_name, city
ORDER BY ROUND(AVG(mean),1) DESC;
-- Screenshot: Alaska!









