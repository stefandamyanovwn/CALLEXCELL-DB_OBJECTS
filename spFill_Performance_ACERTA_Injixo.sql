/*======================================================(0.0.0)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - spFill_Performance_ACERTA_Injixo

USE [DwH]
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*======================================================(1.0.0)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Procedure to fill Performance ACERTA Injixo data

CREATE PROCEDURE [dbo].[spFill_Performance_ACERTA_Injixo] AS
BEGIN

/*======================================================(1.0.0)======================================================*/

/*======================================================(1.0.1)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop temporary tables if they exist to ensure a clean start

    IF (OBJECT_ID('tempdb..#dates') IS NOT NULL) DROP TABLE #dates;
    IF (OBJECT_ID('tempdb..#tmp1') IS NOT NULL) DROP TABLE #tmp1;
    IF (OBJECT_ID('tempdb..#tmp2') IS NOT NULL) DROP TABLE #tmp2;
    IF (OBJECT_ID('tempdb..#tmp3') IS NOT NULL) DROP TABLE #tmp3;
    IF (OBJECT_ID('tempdb..#tmp4') IS NOT NULL) DROP TABLE #tmp4;

/*======================================================(1.0.1)======================================================*/

/*======================================================(1.0.2)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Declare date variables to be used in the procedure

    DECLARE @Tempdate DATE;
    DECLARE @Enddate DATE;
    DECLARE @Startdate DATE;
    DECLARE @RealStartdate DATE;
    DECLARE @RealEndDate DATE;
    DECLARE @RealPrevStartdate DATE;
    DECLARE @RealPrevEndDate DATE;
/*======================================================(1.0.2)======================================================*/

/*======================================================(1.0.3)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Initialize the date variables based on existing data

    SET @Tempdate = (SELECT MIN(ShiftStartDate) FROM dbo.PerformanceSolvus);
    SET @Startdate = @Tempdate;
    SET @Enddate = EOMONTH(GETDATE());
    SET @RealStartdate = (SELECT DATEADD(DAY, 1, EOMONTH(@Enddate, -1)));
    SET @RealEndDate = (SELECT MAX(ShiftStartDate) FROM dbo.PerformanceSolvus);
    SET @RealPrevStartdate = (SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0));
    SET @RealPrevEndDate = (SELECT DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE()) - 1, -1));

/*======================================================(1.0.3)======================================================*/

/*======================================================(1.0.4)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Create a temporary table with dates from StartDate to EndDate
    SELECT
        DATEADD(DAY, number, @Startdate) AS Date1,
        CONVERT(VARCHAR, DATEADD(DAY, number, @Startdate), 103) AS Date2
    INTO #dates
    FROM master..spt_values
    WHERE type = 'P' AND DATEADD(DAY, number, @Startdate) <= @Enddate;

/*======================================================(1.0.4)======================================================*/

/*======================================================(1.0.5)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop temporary table if it exists

    DROP TABLE IF EXISTS #tmp0;

/*======================================================(1.0.5)======================================================*/

/*======================================================(1.0.6)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Create a temporary table with relevant data from PerformanceSolvus
    SELECT
        RegisterNumber,
        ShiftStartDate,
        CAST(PerformanceCode AS VARCHAR(MAX)) AS PerformanceCode,
        ScheduledActivity,
        PERSON_ID,
        EmployeeLogin,
        FirstName,
        LastName,
        ScheduledTotalTime
    INTO #tmp0
    FROM [DWH].[dbo].PerformanceSolvus
    WHERE ShiftStartDate >= @Startdate;
/*======================================================(1.0.6)======================================================*/

/*======================================================(1.0.7)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop temporary table if it exists
    DROP TABLE IF EXISTS #tmp1;

/*======================================================(1.0.7)======================================================*/

/*======================================================(1.0.8)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Create a temporary table with aggregated data

    SELECT
        M.[Externe referentie] AS [Externe referentie],
        CONVERT(VARCHAR, P.ShiftStartDate, 101) AS Datum,
        P.ShiftStartDate AS ShiftStartDate,
        P.PerformanceCode,
        SUM(P.ScheduledTotalTime) AS ActivityDuration,
        M.Overeenkomstnummer,
        P.PERSON_ID,
        M.[login],
        P.FirstName,
        P.LastName,
        SUM(P.ScheduledTotalTime) AS ActivityDuration_float
    INTO #tmp1
    FROM #tmp0 P
    INNER JOIN dbo.v_Mapping_ACERTA_xlsx M ON P.EmployeeLogin = M.[Login]
    WHERE P.ShiftStartDate >= @Startdate
    GROUP BY M.[Externe referentie], P.ShiftStartDate, P.PerformanceCode, M.Overeenkomstnummer,
             P.EmployeeLogin, P.PERSON_ID, M.[login], P.FirstName, P.LastName;

/*======================================================(1.0.8)======================================================*/

/*======================================================(1.0.9)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop temporary table if it exists
    DROP TABLE IF EXISTS #tmp10;
/*======================================================(1.0.9)======================================================*/

/*======================================================(1.0.10)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Create a temporary table to filter specific performance codes

    SELECT
        [Externe referentie],
        Datum,
        TRY_CAST(PerformanceCode AS INT) AS PerformanceCode,
        ShiftStartDate,
        IIF(PerformanceCode = 100, 1020, PerformanceCode) AS Perf1020_
    INTO #tmp10
    FROM #tmp1
    WHERE PerformanceCode IN ('0100', '1020');

/*======================================================(1.0.10)======================================================*/

/*======================================================(1.0.11)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop temporary table if it exists

    DROP TABLE IF EXISTS #tmp12;

/*======================================================(1.0.11)======================================================*/

/*======================================================(1.0.12)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Create a temporary table to identify rows with duplicate performance codes
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY [Externe referentie], Datum, Perf1020_ ORDER BY PerformanceCode DESC) AS R2
    INTO #tmp12
    FROM #tmp10;

/*======================================================(1.0.12)======================================================*/

/*======================================================(1.0.13)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop temporary table if it exists

    DROP TABLE IF EXISTS #ListWithDoublesPerfCode;

/*======================================================(1.0.13)======================================================*/

/*======================================================(1.0.14)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Create a temporary table with duplicate performance codes

    SELECT T1.*
    INTO #ListWithDoublesPerfCode
    FROM #tmp10 T1
    LEFT JOIN (
        SELECT *
        FROM #tmp12
        WHERE Perf1020_ = '1020' AND R2 > 1
    ) T2 ON T1.[Externe referentie] = T2.[Externe referentie] AND T1.Datum = T2.Datum
    WHERE T2.[Externe referentie] IS NOT NULL;
/*======================================================(1.0.14)======================================================*/

/*======================================================(1.0.15)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Update the performance code to handle specific cases
    UPDATE T1
    SET T1.PerformanceCode = T2.Perf1020_
    FROM #tmp1 T1
    INNER JOIN #ListWithDoublesPerfCode T2 ON T1.[Externe referentie] = T2.[Externe referentie]
                                          AND T1.ShiftStartDate = T2.ShiftStartDate
    WHERE T1.PerformanceCode = 100;
/*======================================================(1.0.15)======================================================*/

/*======================================================(1.0.16)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop temporary table if it exists

    DROP TABLE IF EXISTS #CrossJOIN;

/*======================================================(1.0.16)======================================================*/

/*======================================================(1.0.17)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Create a temporary table with a cross join of external references and dates
    SELECT a.[Externe referentie], d.Date1
    INTO #CrossJOIN
    FROM (SELECT [Externe referentie] FROM #tmp1 GROUP BY [Externe referentie]) a
    CROSS JOIN #dates d;

/*======================================================(1.0.17)======================================================*/

/*======================================================(1.0.18)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop temporary table if it exists
    DROP TABLE IF EXISTS #tmp2;

/*======================================================(1.0.18)======================================================*/

/*======================================================(1.0.19)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Create a temporary table with a full join of previous results and the cross join
    SELECT
        COALESCE(T1.[Externe referentie], T2.[Externe referentie]) AS [Externe referentie],
        COALESCE(T1.Datum, T2.Date1) AS Datum,
        T1.PerformanceCode,
        T1.ActivityDuration,
        LAG_PerformanceCode = ISNULL(LAG(T1.PerformanceCode, 1) OVER (PARTITION BY T2.[Externe referentie] ORDER BY T2.Date1),
                                     LAG(T1.PerformanceCode, 2) OVER (PARTITION BY T2.[Externe referentie] ORDER BY T2.Date1)),
        LEAD_PerformanceCode = ISNULL(LEAD(T1.PerformanceCode, 1) OVER (PARTITION BY T2.[Externe referentie] ORDER BY T2.Date1),
                                      LEAD(T1.PerformanceCode, 2) OVER (PARTITION BY T2.[Externe referentie] ORDER BY T2.Date1)),
        T1.Overeenkomstnummer,
        T1.PERSON_ID,
        T1.[login],
        T1.FirstName,
        T1.LastName,
        ActivityDuration_float
    INTO #tmp2
    FROM #tmp1 T1
    FULL JOIN #CrossJOIN T2 ON T1.Datum = T2.Date1 AND T1.[Externe referentie] = T2.[Externe referentie];

/*======================================================(1.0.19)======================================================*/

/*======================================================(1.0.20)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov -  Delete rows with null performance code and invalid adjacent performance codes
    DELETE
    FROM #tmp2
    WHERE PerformanceCode IS NULL
    AND (
        LAG_PerformanceCode NOT IN ('0050', '0359', '3031', '4503', '3523', '0353', '0250')
        OR LEAD_PerformanceCode NOT IN ('0050', '0359', '3031', '4503', '3523', '0353', '0250')
    );

/*======================================================(1.0.20)======================================================*/

/*======================================================(1.0.21)======================================================*/
 -- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop temporary table if it exists
    DROP TABLE IF EXISTS #tmp3;

/*======================================================(1.0.21)======================================================*/

/*======================================================(1.0.22)======================================================*/
 -- Date: 17-Jun-2024
-- Description: Stefan Damyanov -  Create a temporary table with consolidated performance codes and calculated durations
    SELECT
        'INJ10264838' AS Prefix,
        [Externe referentie], Datum,
        [PerformanceCode] = COALESCE(PerformanceCode,
                                     IIF(LAG_PerformanceCode = '0050' OR LEAD_PerformanceCode = '0050', '0050',
                                     IIF(LAG_PerformanceCode = '0250' OR LEAD_PerformanceCode = '0250', '0250',
                                     IIF(LAG_PerformanceCode = '0359' OR LEAD_PerformanceCode = '0359', '0359',
                                     IIF(LAG_PerformanceCode = '3031' OR LEAD_PerformanceCode = '3031', '3031',
                                     IIF(LAG_PerformanceCode = '3523' OR LEAD_PerformanceCode = '3523', '3523',
                                     IIF(LAG_PerformanceCode = '0353' OR LEAD_PerformanceCode = '0353', '0353',
                                     IIF(LAG_PerformanceCode = '4503' OR LEAD_PerformanceCode = '4503', '4503', PerformanceCode)))))))),
        Overeenkomstnummer,
        PERSON_ID,
        [login],
        FirstName,
        LastName,
        SUM(ActivityDuration_float) AS ActivityDuration_float,
        RIGHT(CAST(ROUND(SUM(ActivityDuration_float), 2) * 100 + 10000 AS INT), 4) AS ActivityDuration
    INTO #tmp3
    FROM #tmp2
    WHERE 1 = 1
    GROUP BY [Externe referentie], Datum,
             COALESCE(PerformanceCode,
                     IIF(LAG_PerformanceCode = '0050' OR LEAD_PerformanceCode = '0050', '0050',
                     IIF(LAG_PerformanceCode = '0250' OR LEAD_PerformanceCode = '0250', '0250',
                     IIF(LAG_PerformanceCode = '0359' OR LEAD_PerformanceCode = '0359', '0359',
                     IIF(LAG_PerformanceCode = '3031' OR LEAD_PerformanceCode = '3031', '3031',
                     IIF(LAG_PerformanceCode = '3523' OR LEAD_PerformanceCode = '3523', '3523',
                     IIF(LAG_PerformanceCode = '0353' OR LEAD_PerformanceCode = '0353', '0353',
                     IIF(LAG_PerformanceCode = '4503' OR LEAD_PerformanceCode = '4503', '4503', PerformanceCode)))))))),
             Overeenkomstnummer, PERSON_ID, [login], FirstName, LastName;

/*======================================================(1.0.22)======================================================*/

/*======================================================(1.0.23)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov -  Drop temporary table if it exists

    DROP TABLE IF EXISTS #ALL_Overeenkomstnummer;

/*======================================================(1.0.23)======================================================*/

/*======================================================(1.0.24)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov -  Create a temporary table with unique external references and agreement numbers
    SELECT DISTINCT
        [Externe referentie], Overeenkomstnummer,
        PERSON_ID, [login], FirstName, LastName
    INTO #ALL_Overeenkomstnummer
    FROM #tmp3
    WHERE Overeenkomstnummer IS NOT NULL;

/*======================================================(1.0.24)======================================================*/

/*======================================================(1.0.25)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov -  Update the main temporary table with missing agreement numbers and personal details
    UPDATE T1
    SET T1.Overeenkomstnummer = T2.Overeenkomstnummer,
        T1.PERSON_ID = T2.PERSON_ID,
        T1.[login] = T2.[login],
        T1.FirstName = T2.FirstName,
        T1.LastName = T2.LastName
    FROM #tmp3 T1
    INNER JOIN #ALL_Overeenkomstnummer T2 ON T1.[Externe referentie] = T2.[Externe referentie]
    WHERE T1.Overeenkomstnummer IS NULL;

/*======================================================(1.0.25)======================================================*/

/*======================================================(1.0.26)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov -  Truncate the target table before inserting new data
    TRUNCATE TABLE DWH.[dbo].[Performance_ACERTA_Injixo];

/*======================================================(1.0.26)======================================================*/

/*======================================================(1.0.27)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov -  Insert data from the main temporary table into the target table
    INSERT INTO DWH.[dbo].[Performance_ACERTA_Injixo]
        (Prefix, [Externe referentie], [Datum], [PerformanceCode], Overeenkomstnummer, PERSON_ID, [login], FirstName, LastName, ActivityDuration_float, [ActivityDuration])
    SELECT * FROM #tmp3 WHERE [Datum] >= @RealPrevStartdate;
END
GO
/*======================================================(1.0.27)======================================================*/
