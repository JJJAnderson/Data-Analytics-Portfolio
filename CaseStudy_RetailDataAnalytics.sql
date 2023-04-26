-- Getting a feel of the data in the dataset

SELECT *
FROM Features;

EXEC sp_help 'Features';

SELECT *
FROM Sales;

EXEC sp_help 'Sales';

SELECT *
FROM Stores;

EXEC sp_help 'Stores';

-- Running TRIM on all columns

UPDATE Sales
SET 
    Store = LTRIM(RTRIM(Store)),
    Dept = LTRIM(RTRIM(Dept)),
    Date = LTRIM(RTRIM(Date)),
    Weekly_Sales = LTRIM(RTRIM(Weekly_Sales)),
    IsHoliday = LTRIM(RTRIM(IsHoliday))


UPDATE Features
SET 
    Store = LTRIM(RTRIM(Store)),
    Date = LTRIM(RTRIM(Date)),
    Temperature = LTRIM(RTRIM(Temperature)),
    Fuel_Price = LTRIM(RTRIM(Fuel_Price)),
    MarkDown1 = LTRIM(RTRIM(MarkDown1)),
    MarkDown2 = LTRIM(RTRIM(MarkDown2)),
    MarkDown3 = LTRIM(RTRIM(MarkDown3)),
    MarkDown4 = LTRIM(RTRIM(MarkDown4)),
    MarkDown5 = LTRIM(RTRIM(MarkDown5)),
    CPI = LTRIM(RTRIM(CPI)),
    Unemployment = LTRIM(RTRIM(Unemployment)),
    IsHoliday = LTRIM(RTRIM(IsHoliday));


UPDATE Stores
SET 
	Store = LTRIM(RTRIM(Store)),
	Type = LTRIM(RTRIM(Type)),
	Size = LTRIM(RTRIM(Size));

-- Checking for NULL Values

SELECT *
FROM Sales
WHERE Store IS NULL
   OR Dept IS NULL
   OR Date IS NULL
   OR Weekly_Sales IS NULL
   OR IsHoliday IS NULL;

SELECT *
FROM Features
WHERE Store IS NULL 
OR Date IS NULL 
OR MarkDown1 IS NULL 
OR MarkDown2 IS NULL 
OR MarkDown3 IS NULL 
OR MarkDown4 IS NULL 
OR MarkDown5 IS NULL 
OR IsHoliday IS NULL;

SELECT *
FROM Stores
WHERE Store IS NULL 
OR Type IS NULL 
OR Size IS NULL;

-- No NULL values but there are several 'NA' in the Markdown columns on the Features Table
-- Cleaning the Features table

UPDATE Features
SET MarkDown1 = 0
WHERE MarkDown1 = 'NA';

UPDATE Features
SET MarkDown2 = 0
WHERE MarkDown2 = 'NA';

UPDATE Features
SET MarkDown3 = 0
WHERE MarkDown3 = 'NA';

UPDATE Features
SET MarkDown4 = 0
WHERE MarkDown4 = 'NA';

UPDATE Features
SET MarkDown5 = 0
WHERE MarkDown5 = 'NA';

SELECT *
FROM Features;

ALTER TABLE Features
ALTER COLUMN MarkDown1 float;

ALTER TABLE Features
ALTER COLUMN MarkDown2 float;

ALTER TABLE Features
ALTER COLUMN MarkDown3 float;

ALTER TABLE Features
ALTER COLUMN MarkDown4 float;

ALTER TABLE Features
ALTER COLUMN MarkDown5 float;

EXEC sp_help 'Features';

SELECT *
FROM Features
WHERE IsHoliday > 1;

-- The dates in the Sales and Features table are nvarchar, and not a date format.

ALTER TABLE Sales 
ALTER COLUMN Date date;

-- Conversion didn't work. I'm going to try to convert one date to see if something is wrong with the whole column or just some select dates. 

SELECT Store, Dept, Date, Weekly_Sales, IsHoliday, 
       TRY_CONVERT(date, Date, 103) AS NewDate
FROM Sales
WHERE Store = 9 AND Dept = 8

UPDATE Sales
SET Date = CONVERT(date, Date, 103)
WHERE Store = 9 AND Dept = 8 AND Date = '04/05/2012'

-- It worked, now I'm going to do the whole date into the British/French format (103) and it will convert the date to NULL if it doesn't work. 

SELECT Store, Dept, 
    TRY_CONVERT(date, Date, 103) AS Date, 
    Weekly_Sales, 
    IsHoliday
FROM Sales
ORDER BY CASE WHEN TRY_CONVERT(date, Date, 103) IS NULL THEN 0 ELSE 1 END, 
         TRY_CONVERT(date, Date, 103)

-- There is one NULL value, with the Store 9, Dept 8 and Weekly_Sales of 23138.81

SELECT *
FROM Sales
WHERE Weekly_Sales = 23138.81;

-- This date is in the wrong format 2012-05-11 instead of 11/05/2012

UPDATE Sales
SET Date = '11/05/2012'
WHERE Store = 9 AND Dept = 8 AND Weekly_Sales = 23138.81;

SELECT Store, Dept, 
    TRY_CONVERT(date, Date, 103) AS Date, 
    Weekly_Sales, 
    IsHoliday
FROM Sales
ORDER BY CASE WHEN TRY_CONVERT(date, Date, 103) IS NULL THEN 0 ELSE 1 END, 
         TRY_CONVERT(date, Date, 103)

-- No more NULL values. Proceeding with converting from nvarchar to date.


UPDATE Sales
SET Date = CONVERT(date, Date, 103)
WHERE ISDATE(Date) = 1

-- Didn't work. Checking to see if there are any more rows that can't convert

SELECT *
FROM Sales
WHERE ISDATE(Date) = 0;


-- 253,414 rows. Going to try to convert with a select statement into a standard format. 

SELECT *
FROM Sales
WHERE ISDATE(Date) = 1 AND TRY_CONVERT(date, Date, 103) IS NULL;

UPDATE Sales
SET Date = CONVERT(date, Date, 103)
WHERE ISDATE(Date) = 0;

UPDATE Sales
SET Date = CONVERT(date, Date, 103)
WHERE ISDATE(Date) = 1;

-- The ISDATE(Date) = 1 is not converting. I'm going to use a function to parse the dates

CREATE FUNCTION dbo.ParseDate (@dateStr NVARCHAR(50))
RETURNS DATE
AS
BEGIN
    DECLARE @day INT
    DECLARE @month INT
    DECLARE @year INT

    SET @day = CAST(SUBSTRING(@dateStr, 1, 2) AS INT)
    SET @month = CAST(SUBSTRING(@dateStr, 4, 2) AS INT)
    SET @year = CAST(SUBSTRING(@dateStr, 7, 4) AS INT)

    RETURN DATEFROMPARTS(@year, @month, @day)
END


SELECT *
FROM Sales
WHERE ISDATE(Date) = 1;

UPDATE Sales
SET Date = dbo.ParseDate(Date)
WHERE ISDATE(Date) = 1

-- Not working. Conversion fails. It looks like it's failing while updating already converted dates. Updating the function. 

CREATE FUNCTION dbo.ParseDateV2 (@input VARCHAR(50))
RETURNS DATE
AS
BEGIN
    DECLARE @output DATE

    SELECT @output =
        CASE
            -- Checking if input matches the format of previous conversion attempts
            WHEN @input LIKE '__-__-____' THEN NULL
            -- Try converting using format 103 (dd/mm/yyyy)
            WHEN TRY_CONVERT(DATE, @input, 103) IS NOT NULL THEN TRY_CONVERT(DATE, @input, 103)
            -- Try converting using format 110 (mm-dd-yyyy)
            WHEN TRY_CONVERT(DATE, @input, 110) IS NOT NULL THEN TRY_CONVERT(DATE, @input, 110)
            -- Try converting using format 101 (mm/dd/yyyy)
            WHEN TRY_CONVERT(DATE, @input, 101) IS NOT NULL THEN TRY_CONVERT(DATE, @input, 101)
            -- Return NULL if all attempts fail
            ELSE NULL
        END

    RETURN @output
END

UPDATE Sales
SET Date = dbo.ParseDateV2(Date)
WHERE ISDATE(Date) = 1 AND Date NOT LIKE '%/%/%';

-- It's returning Null values. 

SELECT Store, Dept, PARSE(Date AS datetime USING 'en-US') AS Date, Weekly_Sales, IsHoliday
FROM Sales
WHERE TRY_PARSE(Date AS datetime USING 'en-US') IS NOT NULL;

UPDATE Sales
SET Date = CONVERT(datetime, CONVERT(varchar(10), Date, 120), 120)
WHERE ISDATE(Date) = 1;

-- Now converting it all to ISO 8601 format

UPDATE Sales
SET Date = CONVERT(varchar(30), CONVERT(datetime, Date), 126)
WHERE ISDATE(Date) = 1;

-- IT WORKS! Now to convert the date in the Features table 

ALTER TABLE Features 
ALTER COLUMN Date date;

SELECT *
FROM Features
WHERE ISDATE(Date) = 0;

--There are 4905 rows the resulted from that query. 

SELECT Store, CPI,
    TRY_CONVERT(date, Date, 103) AS Date,  
    IsHoliday
FROM Features
ORDER BY CASE WHEN TRY_CONVERT(date, Date, 103) IS NULL THEN 0 ELSE 1 END, 
         TRY_CONVERT(date, Date, 103)

UPDATE Features
SET Date = CONVERT(date, Date, 103)
WHERE ISDATE(Date) = 0

UPDATE Features
SET Date = CONVERT(date, Date, 103)
WHERE ISDATE(Date) = 1

SELECT *
FROM Features

-- Successful. I think the data is now clean.  

-- TASK 1 - Predict the department-wide sales for each store for the following year

SELECT Store,Dept, Weekly_Sales
FROM Sales
ORDER BY 3, 1, 2;

SELECT Date, SUM(Weekly_Sales) AS Total_Sales
FROM Sales
GROUP BY Date
ORDER BY Date;

-- Exporting the data to Excel for forecasting

-- TASK 2 Model the effects of markdowns on holiday weeks

-- Collecting the columns I need to conduct the analysis

SELECT s.Store, s.Type, f.Date, f.MarkDown1, f.MarkDown2, f.MarkDown3, f.MarkDown4, f.MarkDown5, f.IsHoliday, ts.Total_Sales
FROM Stores s
LEFT JOIN Features f ON s.Store = f.Store
LEFT JOIN (SELECT Store, Date, SUM(Weekly_Sales) AS Total_Sales
           FROM Sales
           GROUP BY Store, Date) ts ON s.Store = ts.Store AND f.Date = ts.Date
ORDER BY f.Date, s.Store;

-- There seems to be some NULL values in Total_Sales

SELECT s.Store, s.Type, f.Date, f.MarkDown1, f.MarkDown2, f.MarkDown3, f.MarkDown4, f.MarkDown5, f.IsHoliday, ts.Total_Sales
FROM Stores s
LEFT JOIN Features f ON s.Store = f.Store
LEFT JOIN (SELECT Store, Date, SUM(Weekly_Sales) AS Total_Sales
           FROM Sales
           GROUP BY Store, Date) ts ON s.Store = ts.Store AND f.Date = ts.Date
WHERE ts.Total_Sales IS NOT NULL
ORDER BY f.Date, s.Store;


-- 4320 rows are not NULL for Total_Sales, and the remaining 3,870 rows are Null. That's a lot of missing rows, but I there's no one to ask about that NULL data. 

-- MarkDown is also showing some discount in the negative. I want to see only the negative values in the Markdown rows:

SELECT s.Store, s.Type, f.Date, 
    CASE WHEN f.MarkDown1 < 0 THEN f.MarkDown1 ELSE 0 END AS MarkDown1,
    CASE WHEN f.MarkDown2 < 0 THEN f.MarkDown2 ELSE 0 END AS MarkDown2,
    CASE WHEN f.MarkDown3 < 0 THEN f.MarkDown3 ELSE 0 END AS MarkDown3,
    CASE WHEN f.MarkDown4 < 0 THEN f.MarkDown4 ELSE 0 END AS MarkDown4,
    CASE WHEN f.MarkDown5 < 0 THEN f.MarkDown5 ELSE 0 END AS MarkDown5,
    f.IsHoliday, ts.Total_Sales
FROM Stores s
LEFT JOIN Features f ON s.Store = f.Store
LEFT JOIN (SELECT Store, Date, SUM(Weekly_Sales) AS Total_Sales
           FROM Sales
           GROUP BY Store, Date) ts ON s.Store = ts.Store AND f.Date = ts.Date
WHERE ts.Total_Sales IS NOT NULL 
  AND (f.MarkDown1 < 0 OR f.MarkDown2 < 0 OR f.MarkDown3 < 0 OR f.MarkDown4 < 0 OR f.MarkDown5 < 0)
ORDER BY f.Date, s.Store;


-- There are only 14 rows and the negative values are small. I'm going to keep them in because there's no one I can ask about what these values mean, and I think the impact the conclusion will be minimal. 

SELECT s.Store, s.Type, f.Date, f.MarkDown1, f.MarkDown2, f.MarkDown3, f.MarkDown4, f.MarkDown5, f.IsHoliday, ts.Total_Sales
FROM Stores s
LEFT JOIN Features f ON s.Store = f.Store
LEFT JOIN (SELECT Store, Date, SUM(Weekly_Sales) AS Total_Sales
           FROM Sales
           GROUP BY Store, Date) ts ON s.Store = ts.Store AND f.Date = ts.Date
WHERE ts.Total_Sales IS NOT NULL
ORDER BY f.Date, s.Store;

-- Exporting the data to Excel for modeling, and also to Tableau

-- Visualization found here: https://public.tableau.com/app/profile/josh4160/viz/CaseStudy-SalesForecast/Dashboard1

