CREATE DATABASE Casestudy2
use Casestudy2

--Q1) List all states in which we have customers who have bought cell phones from 2005 till today

SELECT DISTINCT State
FROM DIM_LOCATION
WHERE EXISTS 
           ( SELECT IDCustomer 
             FROM FACT_TRANSACTIONS 
             WHERE DIM_LOCATION.IDLocation=	FACT_TRANSACTIONS.IDLocation AND Date >='01/01/2005')

-- OPTION 2 : USING JOIN

SELECT DISTINCT State
FROM FACT_TRANSACTIONS T LEFT JOIN DIM_LOCATION L ON T.IDLocation = L.IDLocation
WHERE Date>='01/01/2005'

--Q2) What states in US are buying more Samsung cell phones?

SELECT TOP 1 State,COUNT(*) AS [SALES_SAMSUNG PHONES]
FROM FACT_TRANSACTIONS T LEFT JOIN DIM_LOCATION L ON T.IDLocation = L.IDLocation 
     INNER JOIN DIM_MODEL M ON T.IDModel=M.IDModel
WHERE Country='US' AND 
	  IDManufacturer= (SELECT IDManufacturer FROM DIM_MANUFACTURER WHERE Manufacturer_Name = 'Samsung')
GROUP BY State
ORDER BY [SALES_SAMSUNG PHONES] DESC

--Q3) Show the no of transactions for each zip code per state

SELECT ZipCode,State,COUNT(*) AS [NO. OF TRANSACTIONS]
FROM FACT_TRANSACTIONS T LEFT JOIN DIM_LOCATION L ON T.IDLocation = L.IDLocation
GROUP BY  ZipCode,State

--Q4) Show the cheapest cell phone

SELECT TOP 1 *
FROM DIM_MODEL 
ORDER BY Unit_price

--Q5) Find the average price for each model in the TOP 5 manufacturers in terms of Sales quantity and order by average price

SELECT T.IDModel, AVG(CAST(TotalPrice as float)/Quantity)AS [AVG PRICE]
FROM FACT_TRANSACTIONS T LEFT JOIN DIM_MODEL M ON T.IDModel=M.IDModel 
WHERE IDManufacturer IN 
						(
						SELECT TOP 5 IDManufacturer
						FROM FACT_TRANSACTIONS T LEFT JOIN DIM_MODEL M ON T.IDModel=M.IDModel
						GROUP BY IDManufacturer
						ORDER BY SUM(Quantity) DESC
						)
GROUP BY T.IDModel
ORDER BY [AVG PRICE] 

--Q6) List the names of the customers and the avereage amount spend in 2009, where the aveage is higher than 500

SELECT Customer_Name,AVG(TotalPrice) AS [AVG AMOUNT SPENT IN 2009] 
FROM FACT_TRANSACTIONS T LEFT JOIN DIM_CUSTOMER C ON T.IDCustomer=C.IDCustomer
WHERE YEAR(DATE)=2009 
GROUP BY Customer_Name
HAVING AVG(TotalPrice)>500

--Q7) List if there is any model in top 5 simultaneously in 2008,2009 and 2010

SELECT * FROM

(SELECT TOP 5 IDModel
FROM FACT_TRANSACTIONS
WHERE YEAR(Date) = 2008
GROUP BY IDModel
ORDER BY SUM(Quantity) DESC

INTERSECT

SELECT TOP 5 IDModel
FROM FACT_TRANSACTIONS
WHERE YEAR(Date) = 2009
GROUP BY IDModel 
ORDER BY SUM(Quantity) DESC

INTERSECT

SELECT TOP 5 IDModel
FROM FACT_TRANSACTIONS
WHERE YEAR(Date) = 2010
GROUP BY IDModel
ORDER BY SUM(Quantity) DESC

) AS SUBQUERY

--Q8) Show the manufacturer with the 2nd Top Sales in the year 2009 and the manufacturer with the 2nd top sales in the year 2010


SELECT Manufacturer_Name AS [2ND BEST SALES : 2009 FOLLOWED BY 2010] FROM
(
	SELECT TOP 1 Manufacturer_Name FROM 
		(
		SELECT TOP 2 Manufacturer_Name,SUM(TotalPrice) AS [SALES 2009]
		FROM FACT_TRANSACTIONS T LEFT JOIN DIM_MODEL M ON T.IDModel= M.IDModel 
								 INNER JOIN DIM_MANUFACTURER MR ON MR.IDManufacturer=M.IDManufacturer
		WHERE YEAR(Date)=2009
		GROUP BY Manufacturer_Name
		ORDER BY [SALES 2009] DESC
		)AS SUBQUERY1
	ORDER BY [SALES 2009]

UNION ALL

	SELECT TOP 1 Manufacturer_Name FROM 
		(
		SELECT TOP 2 Manufacturer_Name,SUM(TotalPrice) AS [SALES 2010]
		FROM FACT_TRANSACTIONS T LEFT JOIN DIM_MODEL M ON T.IDModel= M.IDModel 
								 INNER JOIN DIM_MANUFACTURER MR ON MR.IDManufacturer=M.IDManufacturer
		WHERE YEAR(Date)=2010
		GROUP BY Manufacturer_Name
		ORDER BY [SALES 2010] DESC
		)AS SUBQUERY2
	ORDER BY [SALES 2010]
)AS SUBQUERYA

--Q9) Show the manufacturers that sold cell phone in 2010 but did not sell in 2009

SELECT DISTINCT Manufacturer_Name
FROM FACT_TRANSACTIONS T LEFT JOIN DIM_MODEL M ON T.IDModel= M.IDModel 
						 INNER JOIN DIM_MANUFACTURER MR ON MR.IDManufacturer=M.IDManufacturer
WHERE YEAR(DATE) = 2010

EXCEPT

SELECT DISTINCT Manufacturer_Name
FROM FACT_TRANSACTIONS T LEFT JOIN DIM_MODEL M ON T.IDModel= M.IDModel 
						 INNER JOIN DIM_MANUFACTURER MR ON MR.IDManufacturer=M.IDManufacturer
WHERE YEAR(DATE) = 2009

--Q10) Find Top 100 Customers and their average spend,average qty by each year. 
--     Also, find the percentage of change in their spend

WITH cteCustomers AS(
SELECT TOP 100 IDCustomer,YEAR(Date) AS YEAR,AVG(CAST(TotalPrice as float)) AS [AVG SPEND],AVG(Quantity) AS [AVG QTY]
FROM FACT_TRANSACTIONS
GROUP BY IDCustomer,YEAR(Date)
ORDER BY [AVG SPEND] DESC,[AVG QTY] DESC,YEAR
)
SELECT IDCustomer,YEAR,[AVG SPEND],[AVG QTY],
100*([AVG SPEND]/LAG([AVG SPEND])OVER(ORDER BY [AVG SPEND] DESC,[AVG QTY] DESC,YEAR)-1) AS [PERCENT CHANGE]
FROM cteCustomers

--OPTION TWO FOR WHOLISTIC ANALYSIS OF PERCENT CHANGE, BASED ON IDCustomer

WITH cteCustomers AS(
SELECT IDCustomer,YEAR(Date) AS YEAR,AVG(CAST(TotalPrice as float)) AS [AVG SPEND],AVG(Quantity) AS [AVG QTY]
FROM FACT_TRANSACTIONS
GROUP BY IDCustomer,YEAR(Date)
)
SELECT IDCustomer,YEAR,[AVG SPEND],
100*([AVG SPEND]/LAG([AVG SPEND])OVER(PARTITION BY IDCustomer ORDER BY IDCustomer,Year)-1) AS [PERCENT CHANGE]
FROM cteCustomers
