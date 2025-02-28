USE CLEANING_LAYOFFS;
SET SQL_SAFE_UPDATES=0;
SELECT * FROM 
layoffs;

-- Remove Duplicates
-- Standardize the Data
-- Null Values
-- Remove any Columns

CREATE TABLE layoff_copy
LIKE layoffs;

SELECT * FROM
layoff_copy;

INSERT layoff_copy
SELECT * FROM 
layoffs;

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
country,funds_raised_millions, stage , date) as row_num
FROM layoff_copy;

WITH duplicate_cte AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
country,funds_raised_millions, stage , date) as row_num
FROM layoff_copy
)
SELECT * FROM
duplicate_cte WHERE row_num > 1;
-- lets cross-check
SELECT * FROM
layoff_copy WHERE company = 'Yahoo';
SELECT * FROM
layoff_copy WHERE company = 'Casper';

WITH duplicate_cte AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
country,funds_raised_millions, stage , date) as row_num
FROM layoff_copy
)
DELETE FROM
duplicate_cte WHERE row_num > 1;
-- this syntax does not work for MYSQL
-- LETS try another way

CREATE TABLE `layoff_copy2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SELECT * FROM
layoff_copy2;

INSERT INTO layoff_copy2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
country,funds_raised_millions, stage , date) as row_num
FROM layoff_copy;

SELECT *
FROM layoff_copy2
WHERE row_num > 1;

DELETE
FROM layoff_copy2
WHERE row_num > 1;

-- Standardizing Data
SELECT *
FROM layoff_copy2;
-- Notice some space in front of the first two values in the company column
SELECT company, (TRIM(company))
FROM layoff_copy2;
SELECT DISTINCT(TRIM(company))
FROM layoff_copy2;

UPDATE layoff_copy2
SET company = TRIM(company);

SELECT DISTINCT(industry)
FROM layoff_copy2
ORDER BY 1;
-- notice there is a null and blank value
-- also crypto, cryptocurrency is thesame

SELECT *
FROM layoff_copy2
WHERE industry LIKE 'Crypto%';

UPDATE layoff_copy2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT(industry)
FROM layoff_copy2
ORDER BY 1;

SELECT DISTINCT(location)
FROM layoff_copy2
ORDER BY 1;
-- notice Dusseldorf,Florianpolice, Malama

SELECT *
FROM layoff_copy2
WHERE location LIKE 'Dusseldorf';
SELECT *
FROM layoff_copy2
WHERE location = 'DÃ¼sseldorf';
UPDATE layoff_copy2 
SET location = 'Dusseldorf'
WHERE location = 'DÃ¼sseldorf';

SELECT DISTINCT(location),
CASE
	WHEN location = 'FlorianÃ³polis' THEN 'Florianopolis'
	WHEN location = 'MalmÃ¶' THEN 'Malmo'
	ELSE location
END as loca_update
FROM layoff_copy2
ORDER BY 1;

UPDATE layoff_copy2 
SET location = 
CASE
	WHEN location = 'FlorianÃ³polis' THEN 'Florianopolis'
	WHEN location = 'MalmÃ¶' THEN 'Malmo'
	ELSE location
END;
SELECT DISTINCT(location)
FROM layoff_copy2
ORDER BY 1;


SELECT DISTINCT(country)
FROM layoff_copy2
ORDER BY 1;
-- notice united states, 'United States.'

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoff_copy2 -- this removes the period at the end of United States
ORDER BY 1;

UPDATE layoff_copy2
SET country =  TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoff_copy2;
UPDATE layoff_copy2
SET date =  STR_TO_DATE(`date`, '%m/%d/%Y');
-- its still a text after changing it to date format, so we just have to modify the column
-- to date type

ALTER TABLE layoff_copy2
MODIFY COLUMN `date` DATE;

SELECT DISTINCT(date)
FROM layoff_copy2;

-- NULL and BLANK values
SELECT * FROM
layoff_copy2;

SELECT * FROM
layoff_copy2
WHERE total_laid_off is NULL;
-- This might be relevant because there might be no workers laid off
SELECT * FROM
layoff_copy2
WHERE total_laid_off is NULL AND percentage_laid_off IS NULL;

-- check the null values in column industry
SELECT * FROM layoff_copy2
WHERE industry IS NULL OR 
industry = '';
-- lests populate the industry column

UPDATE layoff_copy2
SET industry = NULL 
WHERE industry = '';

SELECT *
FROM layoff_copy2 AS t1
JOIN layoff_copy2 AS t2
    ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL  AND t2.industry
IS NOT NULL;

UPDATE layoff_copy2 AS t1
JOIN layoff_copy2 AS t2
    ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry
IS NOT NULL;

SELECT * FROM layoff_copy2
WHERE industry IS NULL;
-- seems Ballys is the only one not affected

SELECT * FROM layoff_copy2
WHERE company LIKE 'Bally%';
-- so there was not another row unlike Airbnb and the rest

-- we might be able to populate  total and percentage_laid_off if we 
-- had more info on the total number of employees before laid off.
-- funds raised we might be able to scrape some data from the web

-- Remove any Columns
SELECT * FROM
layoff_copy2
WHERE total_laid_off is NULL AND percentage_laid_off IS NULL;

DELETE FROM
layoff_copy2
WHERE total_laid_off is NULL AND percentage_laid_off IS NULL;

ALTER TABLE layoff_copy2
DROP COLUMN row_num;

SELECT * FROM
layoff_copy2;

-- Exploratory Data Analysis
SELECT * FROM
layoff_copy2;

-- company with the highest laid off in a day
SELECT company, total_laid_off, percentage_laid_off
FROM layoff_copy2
WHERE total_laid_off IN (SELECT MAX(total_laid_off)
FROM layoff_copy2);

-- List of companies with the highest percentage_laid_off
-- means companies that are no longer in buisness
SELECT *
FROM layoff_copy2 WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;
-- order it by funds raised
SELECT *
FROM layoff_copy2 WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Industry that had more companies shut_down
WITH CTE AS(
SELECT *
FROM layoff_copy2 WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC)
SELECT industry,COUNT(industry) as count_ind
FROM CTE
GROUP BY industry
ORDER BY count_ind DESC;

-- company with the most laid off
SELECT company, SUM(total_laid_off)
FROM layoff_copy2
GROUP BY company
ORDER BY 2 DESC;

-- industry with the most laid off
SELECT industry, SUM(total_laid_off)
FROM layoff_copy2
GROUP BY industry
ORDER BY 2 DESC;

-- country with the most laid off
SELECT country, SUM(total_laid_off)
FROM layoff_copy2
GROUP BY country
ORDER BY 2 DESC;

-- How many did Nigeria laid off?
SELECT country, SUM(total_laid_off)
FROM layoff_copy2
WHERE country = 'Nigeria'
GROUP BY country
ORDER BY 2 DESC;

-- year with the most laid off
SELECT YEAR(date), SUM(total_laid_off)
FROM layoff_copy2
GROUP BY YEAR(date)
ORDER BY 2 DESC;

-- company stage with the most laid off
SELECT stage, SUM(total_laid_off)
FROM layoff_copy2
GROUP BY stage
ORDER BY 2 DESC;

-- month with the most laid off
-- substring(column, start_index, number of elements)
SELECT SUBSTRING(date, 1, 7) AS `month`, SUM(total_laid_off)
FROM layoff_copy2
WHERE SUBSTRING(date, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC;

-- lets return thw rolling_sum/total groupby month.
-- the total of previous month would be added onto the next
WITH rolling_cte AS(
SELECT SUBSTRING(date, 1, 7) AS `month`, SUM(total_laid_off) AS total_off
FROM layoff_copy2
WHERE SUBSTRING(date, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC)
SELECT month, total_off, SUM(total_off) OVER(ORDER BY month )
FROM rolling_cte;

-- How many the companies where laying off per Year
SELECT company, YEAR(date), SUM(total_laid_off)
FROM layoff_copy2
GROUP BY company, YEAR(date)
ORDER BY 1 ASC;

SELECT company, YEAR(date), SUM(total_laid_off)
FROM layoff_copy2
GROUP BY company, YEAR(date)
ORDER BY 3 DESC;

-- return the total_laid_off by a company partitioned by year
-- ranked by the highest laid off per year
WITH company_year (company, years, total_laid_off) AS(
SELECT company, YEAR(date), SUM(total_laid_off)
FROM layoff_copy2
GROUP BY company, YEAR(date))
SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC)
AS ranking
FROM company_year
WHERE years IS NOT NULL;

-- TOP 5 companies to lay_off per year
WITH company_year (company, years, total_laid_off) AS(
SELECT company, YEAR(date), SUM(total_laid_off)
FROM layoff_copy2
GROUP BY company, YEAR(date)
), Company_Year_rank AS (
SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC)
AS ranking
FROM company_year
WHERE years IS NOT NULL)
SELECT * FROM Company_Year_rank
WHERE ranking <= 5;

-- TOP 5 industries to lay_off per year
WITH industry_year (industry, years, total_laid_off) AS(
SELECT industry, YEAR(date), SUM(total_laid_off)
FROM layoff_copy2
GROUP BY industry, YEAR(date)
), industry_Year_rank AS (
SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC)
AS ranking
FROM industry_year
WHERE years IS NOT NULL)
SELECT * FROM industry_Year_rank
WHERE ranking <= 5;

-- date range
SELECT MAX(date), MIN(date)
FROM layoff_copy2
