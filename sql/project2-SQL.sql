--Project 2 | SQL Data Analysis

--***ex 1
select P.ProductID,NAME Productname,Color,ListPrice,SIZE
from  Production.Product P 
WHERE  NOT EXISTS (SELECT S.ProductID
                   FROM Sales.SalesOrderDetail S 
				   WHERE S.ProductID=P.ProductID)
ORDER BY 1


--***ex 2
SELECT C.CustomerID, isnull(LastName,'Unknown') LastName, isnull(FirstName,'Unknown') FirstName
FROM sales.Customer C left JOIN Person.Person P  ON P.BusinessEntityID=C.CustomerID
WHERE  NOT exists ( SELECT SOH.CustomerID
                    FROM Sales.SalesOrderHeader SOH 
				    WHERE C.CustomerID=SOH.CustomerID)
ORDER BY CustomerID


--***ex 3
SELECT top 10 C.CustomerID, FirstName,LastName, COUNT (*) CountOFOrders
FROM Person.Person P JOIN  sales.Customer C ON P.BusinessEntityID=C.PersonID
     JOIN Sales.SalesOrderHeader SOH ON C.CustomerID=SOH.CustomerID
GROUP BY C.CustomerID, FirstName,LastName
order by COUNT (*) desc


--***ex 4
select FirstName, LastName, JobTitle,HireDate, count (JobTitle) over (partition by JobTitle order by JobTitle) CountOFTitle
from Person.Person p join HumanResources.Employee e on p.BusinessEntityID=e.BusinessEntityID


--***ex 5
with cte_LastOrder
as
(select *
from (
      select SalesOrderID, c.CustomerID, LastName, FirstName,OrderDate 
	  ,ROW_NUMBER () over (partition by c.CustomerID order by orderdate desc ) rn
      FROM Person.Person P JOIN  sales.Customer C ON P.BusinessEntityID=C.PersonID
      JOIN Sales.SalesOrderHeader SOH ON C.CustomerID=SOH.CustomerID) f
where rn = 1),
cte_PreviousOrder
as
(select *
from (select SalesOrderID, c.CustomerID, LastName, FirstName,OrderDate 
	  ,ROW_NUMBER () over (partition by c.CustomerID order by orderdate desc ) rn
      FROM Person.Person P JOIN sales.Customer C ON P.BusinessEntityID=C.PersonID
      JOIN Sales.SalesOrderHeader SOH ON C.CustomerID=SOH.CustomerID) d
where rn = 2)

select lo.SalesOrderID, lo.CustomerID, lo.LastName, lo.FirstName,lo.OrderDate LastOrder, po.OrderDate PreviousOrder
from cte_LastOrder LO left join cte_PreviousOrder PO on lo.CustomerID=po.CustomerID


--***ex 6
with cte_order
as
(select year (orderdate) YEAR ,SOD.SalesOrderID ,LastName, FirstName
       ,sum(UnitPrice*(1-UnitPriceDiscount)*OrderQty) total
FROM Person.Person P JOIN sales.Customer C ON P.BusinessEntityID=C.PersonID
     JOIN Sales.SalesOrderHeader SOH ON C.CustomerID=SOH.CustomerID
	 JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID=SOD.SalesOrderID
group by year (orderdate) ,SOD.SalesOrderID,LastName,FirstName)

select YEAR,SalesOrderID,LastName,FirstName, FORMAT(total,'#,#.0') total
from (select *,row_number() over (partition by YEAR order by total desc ) rn
      from cte_order) h
where rn =1


--***ex 7
select Month,[2011],[2012],[2013],[2014]
from (select Year (orderdate)Year,Month (orderdate) Month,SalesOrderID
      from Sales.SalesOrderHeader) G
pivot (count(SalesOrderID) for Year in ([2011],[2012],[2013],[2014])) piv
order by Month


--***ex 8
WITH cte_sumprice
as
(select YEAR(ModifiedDate) Year, MONTH(ModifiedDate) MONTH, 
		round(SUM(UnitPrice*(1-UnitPriceDiscount)),2)  Sum_Price
from Sales.SalesOrderDetail
GROUP BY YEAR(ModifiedDate), MONTH(ModifiedDate))

SELECT Year, convert (varchar (12), MONTH) MONTH, Sum_Price, SUM(Sum_Price) OVER(PARTITION BY year ORDER BY month) as CumSum
FROM cte_sumprice
UNION
SELECT Year, 'grand_total', null, SUM(Sum_Price)
FROM cte_sumprice
GROUP BY year
ORDER BY 1,4


--***ex 9
select Dep.Name DepartmentName, EDH.BusinessEntityID EmployeesId, concat(FirstName,' ',LastName) EmployeesFullName,HireDate
       ,DATEDIFF(m,HireDate,GETDATE()) Seniority
	   ,LAG(concat(FirstName,' ',LastName)) over (partition by Dep.Name order by HireDate) PreviuseEmpName
	   ,LAG(HireDate) over (partition by Dep.Name order by HireDate) PreviuseEmpHDate
	   ,DATEDIFF(d,LAG(HireDate) over (partition by Dep.Name order by HireDate),HireDate) DiffDays
from HumanResources.Department Dep 
     JOIN HumanResources.EmployeeDepartmentHistory EDH ON Dep.DepartmentID=EDH.DepartmentID 
     JOIN HumanResources.Employee E ON E.BusinessEntityID=EDH.BusinessEntityID
	 JOIN Person.Person P ON P.BusinessEntityID=EDH.BusinessEntityID
order by Dep.Name,HireDate desc


--***ex 10
select HireDate,DepartmentID,STRING_AGG(CAST(e.BusinessEntityID AS NVARCHAR)+' '+LastName+' '+firstname,', ') Team
from HumanResources.Employee E JOIN HumanResources.EmployeeDepartmentHistory EDH ON E.BusinessEntityID=EDH.BusinessEntityID
     JOIN Person.Person Pe ON Pe.BusinessEntityID=E.BusinessEntityID
where EndDate is null
group by HireDate,DepartmentID
order by HireDate desc









