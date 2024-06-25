/*======================================================(0)======================================================*/

USE [DwH]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
/*======================================================(1.0.0)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Procedure to generate ACERTA Injixo data for file export

CREATE PROCEDURE [dbo].[spFill_Performance_ACERTA_Injixo_File] AS
BEGIN

/*======================================================(1.0.0)======================================================*/

/*======================================================(1.0.1)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop the temporary table if it exists to ensure a clean start
    DROP TABLE IF EXISTS #tmp3;

/*======================================================(1.0.1)======================================================*/

/*======================================================(1.0.2)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Print progress message
    PRINT '1.1';

/*======================================================(1.0.2)======================================================*/

/*======================================================(1.0.3)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Select and format data into a temporary table #tmp3

    SELECT
        Prefix
        + [Externe referentie]
        + '   '
        + CONVERT(VARCHAR, CAST(Datum AS DATE), 103)
        + '  '
        + RIGHT('0' + PerformanceCode, 4)
        + '  '
        + IIF(TRY_CAST(ActivityDuration AS INT) = 0, '', ISNULL(ActivityDuration, '   '))
        AS ACERTA_INJIXO,
        [Datum]
    INTO #tmp3
    FROM DWH.dbo.Performance_ACERTA_Injixo
    WHERE [Externe referentie] <> ''
    AND DATEPART(month, [Datum]) = MONTH(DATEADD(MONTH, -1, GETDATE()))
    AND [Login] IN (
        SELECT DISTINCT [Login]
        FROM DWH.dbo.Mapping_ACERTA_xlsx
        WHERE MonthFlag = 'PrevMonth'
        AND [Login] IS NOT NULL
    );

/*======================================================(1.0.3)======================================================*/

/*======================================================(1.0.4)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Print progress message
    PRINT '1.2';

/*======================================================(1.0.4)======================================================*/

/*======================================================(1.0.5)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop the temporary table ##PrevMonth if it exists

    DROP TABLE IF EXISTS ##PrevMonth;

/*======================================================(1.0.5)======================================================*/

/*======================================================(1.0.6)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Select data from #tmp3 into a global temporary table ##PrevMonth

    SELECT ACERTA_INJIXO 
    INTO ##PrevMonth
    FROM #tmp3
    WHERE ACERTA_INJIXO IS NOT NULL;

/*======================================================(1.0.6)======================================================*/

/*======================================================(1.0.7)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Print progress message

    PRINT '1.3';

/*======================================================(1.0.7)======================================================*/

/*======================================================(1.0.8)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Declare variables for dynamic SQL command and date range

    DECLARE @SQL_cmd VARCHAR(1000), @FromDate VARCHAR(30), @ToDate VARCHAR(30);

/*======================================================(1.0.8)======================================================*/

/*======================================================(1.0.9)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Set the @FromDate and @ToDate variables based on the data in #tmp3

    SET @FromDate = (SELECT MIN(Datum) AS FromDate FROM #tmp3);
    SET @ToDate = (SELECT MAX(Datum) AS FromDate FROM #tmp3);

/*======================================================(1.0.9)======================================================*/

/*======================================================(1.0.10)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Print progress message
    PRINT '1.4';

/*======================================================(1.0.10)======================================================*/

/*======================================================(1.0.11)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop the temporary table #tmp4 if it exists

    DROP TABLE IF EXISTS #tmp4;

/*======================================================(1.0.11)======================================================*/

/*======================================================(1.0.12)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Select and format data into a temporary table #tmp4

    SELECT
        Prefix
        + [Externe referentie]
        + '   '
        + CONVERT(VARCHAR, CAST(Datum AS DATE), 103)
        + '  '
        + RIGHT('0' + PerformanceCode, 4)
        + '  '
        + IIF(TRY_CAST(ActivityDuration AS INT) = 0, '', ISNULL(ActivityDuration, '   '))
        AS ACERTA_INJIXO,
        [Datum]
    INTO #tmp4
    FROM DWH.dbo.Performance_ACERTA_Injixo
    WHERE [Externe referentie] <> ''
    AND DATEPART(month, [Datum]) = DATEPART(month, GETDATE()) - 1
    AND [Login] IN (
        SELECT DISTINCT [Login]
        FROM DWH.dbo.Mapping_ACERTA_xlsx
        WHERE MonthFlag = 'CurrentMonth'
        AND [Login] IS NOT NULL
    );

/*======================================================(1.0.12)======================================================*/

/*======================================================(1.0.13)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Print progress message
    PRINT '1.5';

/*======================================================(1.0.13)======================================================*/

/*======================================================(1.0.14)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Drop the temporary table ##CurrentMonth if it exists

    DROP TABLE IF EXISTS ##CurrentMonth;

/*======================================================(1.0.14)======================================================*/

/*======================================================(1.0.15)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Select data from #tmp4 into a global temporary table ##CurrentMonth

    SELECT ACERTA_INJIXO 
    INTO ##CurrentMonth
    FROM #tmp4
    WHERE ACERTA_INJIXO IS NOT NULL;

/*======================================================(1.0.15)======================================================*/

/*======================================================(1.0.16)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov - Set the @FromDate and @ToDate variables based on the data in #tmp4

    SET @FromDate = (SELECT MIN(Datum) AS FromDate FROM #tmp4);
    SET @ToDate = (SELECT MAX(Datum) AS FromDate FROM #tmp4);

/*======================================================(1.0.16)======================================================*/

/*======================================================(1.0.17)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov -  Construct the BCP command to export data from ##CurrentMonth to a file
    SET @SQL_cmd = ('bcp "SELECT * FROM ##CurrentMonth ORDER BY 1" queryout "\\Cxl-file-01\operations\KLX\KLX_Current_Month_' + @FromDate + '_to_' + @ToDate + '_test.txt" -T -c');

/*======================================================(1.0.17)======================================================*/

/*======================================================(1.0.18)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov -   Print the dynamic SQL command for debugging purposes
    PRINT @SQL_cmd;

/*======================================================(1.0.18)======================================================*/

/*======================================================(1.0.19)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov -  Execute the dynamic SQL command using xp_cmdshell
    EXEC master..xp_cmdshell @SQL_cmd;

/*======================================================(1.0.19)======================================================*/

/*======================================================(1.0.20)======================================================*/
-- Date: 17-Jun-2024
-- Description: Stefan Damyanov -  Print progress messages
    PRINT '1.6';
    PRINT '1.7';
END
GO
/*======================================================(1.0.20)======================================================*/
