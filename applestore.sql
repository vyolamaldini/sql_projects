-- ** EXPLORATORY ANALYSIS **

-- Check the number of unique apps in both tables

SELECT COUNT(DISTINCT id) AS UniqueApps FROM AppleStore

SELECT COUNT(DISTINCT id) AS UniqueApps FROM AppStoreDescription_combined

-- Search for any missing values in key fields

SELECT COUNT(*) AS MissingValues
FROM AppleStore
WHERE track_name IS NULL or user_rating IS NULL OR prime_genre IS NULL

SELECT COUNT(*) AS MissingValues
FROM AppStoreDescription_combined
WHERE track_name IS NULL OR app_desc IS NULL

-- Find out the number off apps per genre

SELECT prime_genre, COUNT(id) AS NumApps
FROM AppleStore
GROUP BY prime_genre
ORDER BY NumApps DESC

-- Get an overview of apps' ratings

SELECT MIN(user_rating) as MinRating, AVG(user_rating) as AverageRating, MAX(user_rating) AS MaxRating
FROM AppleStore

-- ** DATA ANALYSIS **

-- Determine wether paid apps have higher rating than free apps

SELECT CASE 
	WHEN price > 0 
	THEN 'Paid'
	ELSE 'Free'
        END AS AppType, 
        AVG(user_rating) AS AverageRating
FROM AppleStore
GROUP BY AppType

-- Determine wether apps with more supported languages have higher rating

SELECT CASE
	WHEN lang.num < 10 THEN '< 10 Languages'
	WHEN lang.num BETWEEN 10 AND 30 THEN '10-30 Languages'
        ELSE '> 30 Languages'
        END AS LangNumType,
        AVG(user_rating) AS AverageRating
FROM AppleStore
GROUP BY LangNumType

-- Check genres with low ratings

SELECT prime_genre, AVG(user_rating) AS AverageRating FROM AppleStore
GROUP BY prime_genre
ORDER BY AverageRating ASC

-- Check if there is correlation between length of description with user rating

SELECT CASE
	WHEN length(d.app_desc) < 500 then 'Short'
        WHEN length(d.app_desc) BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Long'
        END AS DescLengthType,
        AVG(user_rating) as AverageRating
FROM AppleStore a 
JOIN AppStoreDescription_combined d
ON a.id = d.id
GROUP BY DescLengthType
ORDER BY AverageRating DESC

-- Check the top-rated apps for each genre

SELECT prime_genre, track_name, user_rating
FROM (
	SELECT prime_genre, track_name, user_rating,
	RANK() OVER (PARTITION BY prime_genre ORDER BY user_rating DESC, rating_count_tot DESC) AS rank
	FROM AppleStore
) AS a
WHERE a.rank = 1
