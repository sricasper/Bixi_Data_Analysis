/*--------------------------------------------------*/
-- Author: Sri Casper
-- Date: 2023.03.06
-- Description: Bixi1Deliverable
/*--------------------------------------------------*/

-- Set as a default schema
USE bixi;

-- Config SQL mode
SET GLOBAL sql_mode = 'ONLY_FULL_GROUP_BY';

-- Investigate the data
SELECT *
FROM trips;

-- 1) First, we will attempt to gain an overall view of the volume of usage 
-- of Bixi Bikes and what factors influence it. 
-- 1.1) The total number of trips for the year of 2016
-- 3917401 trips
SELECT COUNT(*)
FROM trips
WHERE YEAR(start_date) = 2016;

-- 1.2) The total number of trips for the year of 2017
-- 4666765 trips
SELECT COUNT(*)
FROM trips
WHERE YEAR(start_date) = 2017;

-- 1.3) The total number of trips for the year of 2016 broken down by month
SELECT MONTH(start_date) AS month_, 
	   COUNT(*) AS MonthlyTotalTrips
FROM trips
WHERE YEAR(start_date) = 2016
GROUP BY month_
ORDER BY MonthlyTotalTrips DESC;

-- 1.4) The total number of trips for the year of 2017 broken down by month
SELECT MONTH(start_date) AS month_, 
	   COUNT(*) AS MonthlyTotalTrips
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY month_
ORDER BY MonthlyTotalTrips DESC;

-- 1.5) The average number of trips a day for each year-month combination in the dataset.
SELECT month_data.Year_,
	   month_data.Month_,
       month_data.MonthlyTotalTrips / month_data.duration AS avg_per_day
FROM
(
	SELECT YEAR(start_date) AS Year_, 
		   MONTH(start_date) AS Month_, 
	       COUNT(*) AS MonthlyTotalTrips,
           DAYOFMONTH(LAST_DAY(start_date)) AS Duration
	FROM trips
	GROUP BY YEAR(start_date), 
		     MONTH(start_date),
             Duration
	ORDER BY YEAR(start_date), 
			 MONTH(start_date) DESC
) AS month_data;

/*
-- This would work if we only care about days with rentals as opposed to the whole month
SELECT YEAR(start_date) AS Year_, 
	   MONTH(start_date) AS Month_, 
	   COUNT(*) AS MonthlyTotalTrips,
	   COUNT(DISTINCT DATE(start_date)) AS Duration,
	   COUNT(*) / (COUNT(DISTINCT DATE(start_date))) AS AvgTripsPerDay
FROM trips
GROUP BY YEAR(start_date), 
		 MONTH(start_date)
ORDER BY YEAR(start_date), 
		 MONTH(start_date) DESC;
*/

-- 1.6) Save your query results from the provious question (Q 1.5) by creating a table called 'working_table1'
CREATE TABLE working_table1
AS 
SELECT month_data.year_,
	   month_data.month_,
       month_data.MonthlyTotalTrips / month_data.duration AS avg_per_day
FROM
(
SELECT YEAR(start_date) AS year_, 
	   MONTH(start_date) AS month_, 
	   COUNT(*) AS MonthlyTotalTrips,
       DAYOFMONTH(LAST_DAY(start_date)) AS Duration
FROM trips
GROUP BY YEAR(start_date), 
		 MONTH(start_date),
         Duration
ORDER BY YEAR(start_date), MONTH(start_date) DESC
) AS month_data;

-- checking the table
select *
from working_table1;

/*--------------------------------------------------*/

-- 2) Unsurprisingly, the number of trips varies greatly throughout the year.
-- How about membership status? Should we expect members and non-members to behave differently?

-- 2.1) The total number of trips in the year 2017 broken down by membership status (member/non-member).
-- Member: 3784682
-- Non-member: 882083
SELECT COUNT(*) AS TotalTrips, 
       is_member
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY is_member
ORDER BY TotalTrips;

-- 2.2) The percentage of total trips by members for the year 2017 broken down by month.
SELECT MONTH(start_date) AS Month,
	   COUNT(*) AS TotalTrips
FROM trips
WHERE YEAR(start_date) = 2017 AND is_member = 1
GROUP BY Month
ORDER BY Month;

SELECT sq.month_ AS month_,
	   (sq.MemberTotalTrips / sq.TotalTrips) * 100 AS percent
       FROM
		(
		SELECT MONTH(start_date) AS month_,
			   COUNT(*) AS TotalTrips,
			   (
				SELECT COUNT(*) AS MemberTotalTrips
				FROM trips
				WHERE YEAR(start_date) = 2017
				AND is_member = 1
				AND MONTH(start_date) = month_
				) AS MemberTotalTrips
		FROM trips
        WHERE YEAR(start_date) = 2017
		GROUP BY month_
		ORDER BY month_
		) AS sq;

/*--------------------------------------------------*/

-- 3) Use the above queries to answer the questions below.

-- 3.1) At which time(s) of the year is the demand for Bixi bikes at its peak?
-- The top 3 months (in order):
-- 1: July
-- 2: Ausgust
-- 3: June
-- Note: This data aligns with my initial expectation because these months align with most people's summer vacations.

-- 3.2) If you were to offer non-members a special promotion in an attempt to convert them to members,
-- when would you do it? Describe the promotion and explain the motivation and your reasoning behind it.

-- Option 1: I would offer the promotion in 'June'. Although it has a slightly lower percentage of non-member trips
-- compared to July's, it is still in the top three rankings.
-- Moreover, June is in the beginning of the four busiest month of the year.
-- So, if they sign-up, they are likely to come back to use our service later in the summer or during the year.

-- Option 2: I would offer the promotion in 'July', since it has the highest percentage of non-member trips.
SELECT sq.month_ AS month_,
	   (sq.NonMemberTotalTrips / sq.TotalTrips) * 100 AS percent
       FROM
		(
			SELECT MONTH(start_date) AS month_,
			   COUNT(*) AS TotalTrips,
			   (
				SELECT COUNT(*) AS NonMemberTotalTrips
				FROM trips
				WHERE is_member = 0
				AND MONTH(start_date) = month_
				) AS NonMemberTotalTrips
			FROM trips
			GROUP BY month_
		) AS sq
ORDER BY percent DESC;
   
/*--------------------------------------------------*/

-- 4) It is clear now that time of year and membership status are intertwined 
-- and influence greatly how people use Bixi bikes. 
-- Next, let's investigate how people use individual stations, 
-- and explore station popularity.
SELECT *
FROM stations;

-- 4.1) What are the names of the 5 most popular starting stations? 
-- Determine the answer without using a subquery.
-- Inner Join
SELECT trips.start_station_code AS station_code,
	   stations.name,
	   COUNT(*) AS num_trips
FROM trips
INNER JOIN stations
ON trips.start_station_code = stations.code
GROUP BY start_station_code, stations.name
ORDER BY num_trips DESC
LIMIT 5;

-- 4.2) Solve the same question as Q4.1, but now use a subquery.
-- Is there a difference in query run time between 4.1 and 4.2?
-- Why or why not?

-- Inner Join: 13.654 seconds
-- Subquery: 3.184 seconds

-- I found it surprising that Inner Join is slower than Subquery
-- because most resources claim that Join is almost always faster
-- since it is a single query that uses the database ability to search, filter, and sort records.

-- Subquery
SELECT start_station_code AS station_code,
	   COUNT(*) AS num_trips,
       (
			SELECT name
            FROM stations
            WHERE station_code = code
		)
FROM trips
GROUP BY station_code
ORDER BY num_trips DESC
LIMIT 5;

/*--------------------------------------------------*/

-- 5) If we break up the hours of the day as follows:
/*
SELECT CASE
	   WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
	   WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
	   WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
	   ELSE "night"
END AS "time_of_day",
	...
*/

-- 5.1) How is the number of starts and ends distributed for the station Mackay / de Maisonneuve throughout the day?
-- The majority of starts and ends are in the evening.
-- Starting station
SELECT COUNT(*),
	   CASE
	   WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
	   WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
	   WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
	   ELSE "night"
END AS time_of_day
FROM trips
WHERE start_station_code = 6100
GROUP BY time_of_day;

-- Ending station
SELECT COUNT(*),
	   CASE
	   WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
	   WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
	   WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
	   ELSE "night"
END AS time_of_day
FROM trips
WHERE end_station_code = 6100
GROUP BY time_of_day;

-- 5.2) Explain and interpret your results from above. 
-- Why do you think these patterns in Bixi usage occur for this station? 
-- Put forth a hypothesis and justify your rationale.
-- My hypothesis is that this station is in the downtown area where offices and businesses are located.
-- A large number of people use this station as a starting station indicating that people are leaving from work.
-- Also, there is another large group of people who come to the area in the evening because they either
-- come home or come to enjoy the nightlife.

/*--------------------------------------------------*/

-- 6) List all stations for which at least 10% of trips are round trips. 
-- Round trips are those that start and end in the same station. 
-- This time we will only consider stations with at least 500 starting trips. 

-- 6.1) First, write a query that counts the number of starting trips per station.
SELECT start_station_code AS station_code,
       (
			SELECT name
            FROM stations
            WHERE station_code = code
		) AS station_name,
        COUNT(*) AS num_starting_trips
FROM trips
GROUP BY station_code;

-- 6.2) Second, write a query that counts, for each station, the number of round trips.
SELECT start_station_code AS station_code,
	   count(*) AS num_round_trips
FROM trips
WHERE start_station_code = end_station_code
GROUP BY start_station_code;

-- 6.3) Combine the above queries and calculate the fraction of round trips 
-- to the total number of starting trips for each station

SELECT t.station_code,
	   t.num_starting_trips,
       t.round_trips,
       (t.round_trips / t.num_starting_trips) * 100 AS round_trip_ratio
       FROM
       (
			SELECT start_station_code AS station_code,
			COUNT(*) AS num_starting_trips,
			(
				SELECT COUNT(*)
				FROM trips
				WHERE start_station_code = station_code
				AND start_station_code = end_station_code
			) as round_trips
		FROM trips
		GROUP BY station_code
        ) as t
        ORDER BY round_trip_ratio DESC;

-- 6.4) Filter down to stations with at least 500 trips originating from them 
-- and having at least 10% of their trips as round trips.
CREATE TABLE station_trip_data AS
SELECT t.station_code,
	   t.num_starting_trips,
       t.round_trips,
       (t.round_trips / t.num_starting_trips) * 100 AS round_trip_ratio
       FROM
       (
       SELECT start_station_code AS station_code,
		COUNT(*) AS num_starting_trips,
        (
			SELECT COUNT(*)
            FROM trips
            WHERE start_station_code = station_code
            AND start_station_code = end_station_code
        ) as round_trips
		FROM trips
		GROUP BY station_code) as t
        ORDER BY round_trip_ratio DESC;
        
SELECT * 
FROM station_trip_data 
WHERE num_starting_trips > 500 
AND round_trip_ratio > 10;

-- 6.5) Where would you expect to find stations with a high fraction of round trips? 
-- Describe why and justify your reasoning.
-- I would expect to find stations with a high fraction of round trips in a park or recreation area,
-- where people come to the station to rent a bike for working out or pleasure in the area for a couple hours then return it.

/*--------------------------------------------------*/