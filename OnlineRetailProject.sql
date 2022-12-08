--Cleaning the Data
--Total records = 541909
--No of records with no CustomerID=135080
--No of records with CustomerID=406829

WITH online_retail AS
(	SELECT *
	FROM ['Online Retail$']
	WHERE CustomerID IS NOT NULL
)
,quantity_unit_price AS
--No of records with quantity and unitprice = 397884
(	SELECT*
	FROM online_retail
	WHERE Quantity > 0 AND UnitPrice > 0
)
,Dup_check AS
--Checking for duplicates
(	SELECT *, ROW_NUMBER() OVER(PARTITION BY InvoiceNo,StockCode,Quantity ORDER BY InvoiceDate) AS Dup_flag
	FROM quantity_unit_price
)
--No of clean data = 392669
--No of duplicates = 5215
SELECT *
INTO #online_retail_main
FROM Dup_check
WHERE Dup_flag = 1

--Clean Data
--Cohort Analysis Begins
SELECT *
FROM #online_retail_main
--Required points for cohort analysis

--Unique Identifier(CustomerID)
--Initial Startdate(First Invoice data)
--Revenue Data
SELECT 
	CustomerID,
	MIN(InvoiceDate) AS First_Purchase,
	DATEFROMPARTS(year(MIN(InvoiceDate)),month(MIN(InvoiceDate)),1) AS Cohort_Date
INTO #cohort
FROM #online_retail_main
GROUP BY CustomerID

SELECT *
FROM #cohort

--Creating the Cohort Index
SELECT ci.*,
	cohort_index = year_diff * 12 + month_diff + 1
INTO #cohort_retention
FROM
(	SELECT ymd.*,
		year_diff = Invoice_year - Cohort_year,
		month_diff = Invoice_month - Cohort_month
	FROM
	(		SELECT 
				m.*,
				c.Cohort_Date,
				year(m.InvoiceDate) Invoice_year,
				month(m.InvoiceDate) Invoice_month,
				year(c.Cohort_Date) Cohort_year,
				month(c.Cohort_Date) Cohort_month
			FROM #online_retail_main AS m
			LEFT JOIN #cohort AS c
			ON m.CustomerID = c.CustomerID
	)ymd
)ci

--Pivot data to see cohort table
SELECT*
INTO #cohort_pivot
FROM
(  SELECT DISTINCT
		CustomerID,
		Cohort_Date,
		cohort_index
   FROM #cohort_retention
) tble
pivot(
	Count(CustomerID)
	FOR Cohort_Index IN
	 (
	  [1],
	  [2],
	  [3],
	  [4],
	  [5],
	  [6],
	  [7],
	  [8],
	  [9],
	  [10],
	  [11],
	  [12],
	  [13]
	  )
) pivot_table

--To get the retention rate
SELECT Cohort_Date,
	  (1.0 *[1]/[1]*100) as [1],
	  1.0 *[2]/[1]*100 as [2],
	  1.0*[3]/[1]*100 as [3],
	  1.0*[4]/[1]*100 as [4],
	  1.0*[5]/[1]*100 as [5],
	  1.0*[6]/[1]*100 as [6],
	  1.0*[7]/[1]*100 as [7],
	  1.0*[8]/[1]*100 as [8],
	  1.0*[9]/[1]*100 as [9],
	  1.0*[10]/[1]*100 as [10],
	  1.0*[11]/[1]*100 as [11],
	  1.0*[12]/[1]*100 as [12],
	  1.0*[13]/[1]*100 as [13]
FROM #cohort_pivot
 ORDER BY Cohort_Date




 