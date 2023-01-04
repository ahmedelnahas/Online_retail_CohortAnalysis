    -- Data Instpecting 
    SELECT [InvoiceNo]
        ,[StockCode]
        ,[Description]
        ,[Quantity]
        ,[InvoiceDate]
        ,[UnitPrice]
        ,[CustomerID]
        ,[Country]
    FROM [Online_retial].[dbo].[Online_Retail2]
    where CustomerID IS NULL

    -- we have 135080 NULL Customer ... we have to create a New table without those Customers 
    -- we have some Values in Quantity with - Sign means the product have retain again and unitPrice Equal to 0
    -- lets Check how many Quantity with - Sign in our table and UnitPrice equal to 0
    SELECT * from Online_Retail2
    where Quantity < 0 and UnitPrice = 0
    -- we have 1336 records with quantity vlaue < 0  and unitprice  = 0



    -- Data Cleaning 
    -- New_Online_retail with No Null Values and quantity vlaue < 0  and unitprice  = 0
    --  

    ;WITH Online_retail2 as 
    (
        SELECT [InvoiceNo]
        ,[StockCode]
        ,[Description]
        ,[Quantity]
        ,[InvoiceDate]
        ,[UnitPrice]
        ,[CustomerID]
        ,[Country]
    FROM [Online_retial].[dbo].[Online_Retail2]
    where CustomerID IS Not NULL
    ), New_Online_Retial as 
    -- 397884 recordes with Quantity and UnitPrice 
    (
        select * from Online_Retail2
    where Quantity > 0 and  unitprice > 0
    ), duplication_check as 
    -- duplicate Check
    (
        select * , ROW_NUMBER() OVER (PARTITION by InvoiceNo, StockCode,Quantity ORDER By InvoiceDate) Duplication_Flag 
    from New_Online_Retial
    )
    -- here we select all recordes with duplication flag = 1 without any duplcation 
    -- 5215 duplicated recordes 
    -- 392669 Our redcordes Now 
    -- lets create table has the cleaned Data
    SELECT * 
    into #Online_retial_main
    From duplication_check
    where Duplication_Flag  = 1 

    -- clean Data
    -- Begin COHORT ANALYSIS
    -- COHORT ANALYSIS IS AN ANALYSIS OF SEVERAL DIFFERENT CHOHORTS TO GET A BETTER UNDERSTANDING OF BEHAVIORS,PATTERN,TRENDS
    -- COHORT ANALYSIS CONSIST OF (TIME-BASE COHORT , SIZE-BASE COHORT , SEGMENT-BASE COHORT)
    -- We are using  Time-base Cohort so we can understand the lifetime value (LTV) with retention anlysis
    SELECT* FROM #Online_retial_main

    --Unique Identifier (CustomerID)
    --Intial Start Date (The First Invoice Date)
    --Revenue Data
    SELECT CustomerID,
    min(InvoiceDate) first_purchase_date,
    DATEFROMPARTS(year(min(InvoiceDate)),MONTH(min(InvoiceDate)),1) Cohort_Date
    into #Cohort
    from #Online_retial_main
    GROUP BY CustomerID

    select* from #Cohort
    -- create COHORT index 
    -- Cohort Index is an integer representation of the number of monthes that has passed since the customer first engagement 
    -- we will join two tables #Cohort and #Online_retial_main
    SELECT
    mmm.*,
    Cohort_Index = year_diff * 12 + month_diff + 1
    INTO #Cohort_retention
    FROM
    (
        SELECT mm.*,
    year_diff =  Invoice_year - Cohort_year ,
    month_diff = Invoice_month - Cohort_month
    FROM
    (
        SELECT
    m.*, 
    c.Cohort_Date,
    year(c.Cohort_Date) Cohort_year,
    MONTH(c.Cohort_Date) Cohort_month,
    YEAR(m.InvoiceDate) Invoice_year,
    MONTH(m.InvoiceDate) Invoice_month
    from #Online_retial_main m 
    LEFT JOIN #Cohort c 
    ON m.CustomerID = c.CustomerID
    )
    mm
    )mmm
    -- so we can see the first customer has 1 in Cohort_Indext means that this customer have made the seconde batches in the same month that had made the first one 
    -- created #Cohort_retention from Tableau Viz 
    -- Pivot Data to see the Cohort table 
    SELECT *
    into #cohort_pivot
    from
    (
        SELECT distinct 
    CustomerId,
    cohort_Date,
    cohort_Index
    from #Cohort_retention
    )tab
    PIVOT(
    COUNT(CustomerID) FOR
    Cohort_Index in(
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


    ) as Pivot_table
    select *
    from #cohort_pivot
    order by Cohort_Date

    select Cohort_Date ,
        (1.0 * [1]/[1] * 100) as [1], 
        1.0 * [2]/[1] * 100 as [2], 
        1.0 * [3]/[1] * 100 as [3],  
        1.0 * [4]/[1] * 100 as [4],  
        1.0 * [5]/[1] * 100 as [5], 
        1.0 * [6]/[1] * 100 as [6], 
        1.0 * [7]/[1] * 100 as [7], 
        1.0 * [8]/[1] * 100 as [8], 
        1.0 * [9]/[1] * 100 as [9], 
        1.0 * [10]/[1] * 100 as [10],   
        1.0 * [11]/[1] * 100 as [11],  
        1.0 * [12]/[1] * 100 as [12],  
        1.0 * [13]/[1] * 100 as [13]
    from #cohort_pivot
    order by Cohort_Date
    --SELECT distinct 
    --cohort_Index
    --from #Cohort_retention



