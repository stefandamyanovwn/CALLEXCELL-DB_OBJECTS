/*======================================================(0)======================================================*/
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - SP_MAPPING_ACERTA.xlsx
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
/*======================================================(1.0.0)======================================================*/
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Procedure to handle mapping of ACERTA xlsx data

CREATE PROCEDURE [dbo].[sp_Mapping_ACERTA_xlsx] AS
BEGIN

/*======================================================(1.0.0)======================================================*/

/*======================================================(1.0.1)======================================================*/
    -- Date: 13-Jun-2024
    -- Description: Stefan Damyanov - Declare a variable to store the count of records
    DECLARE @aantal int;
/*======================================================(1.0.1)======================================================*/

/*======================================================(1.0.2)======================================================*/
    -- Date: 13-Jun-2024
    -- Description: Stefan Damyanov - Count the number of records in the vMapping_ACERTA_xlsx view and assign it to @aantal
    SELECT @aantal = count(*)
    FROM [DWH].[dbo].[vMapping_ACERTA_xlsx]
/*======================================================(1.0.2)======================================================*/

/*======================================================(1.0.3)======================================================*/
    -- Date: 13-Jun-2024
    -- Description: Stefan Damyanov - Print the count of records
    PRINT @aantal;
/*======================================================(1.0.3)======================================================*/

/*======================================================(1.0.4)======================================================*/
    -- Date: 13-Jun-2024
    -- Description: Stefan Damyanov - If there are no records, exit the procedure
    IF @aantal = 0
        RETURN;
/*======================================================(1.0.4)======================================================*/

/*======================================================(1.0.5)======================================================*/
    -- Date: 13-Jun-2024
    -- Description: Stefan Damyanov - Drop the temporary table if it exists
    DROP TABLE IF EXISTS #AcertaEmployeeMapping;
/*======================================================(1.0.5)======================================================*/

/*======================================================(1.0.6)======================================================*/
    -- Date: 13-Jun-2024
    -- Description: Stefan Damyanov - Create a temporary table with distinct employee mappings
    SELECT DISTINCT 
        T1.[Login] AS username, 
        TRY_CAST(T1.PERSONEL_NUMBER AS int) AS Overeenkomstnummer, 
        T2.EmployeeKey AS PERSON_ID
    INTO #AcertaEmployeeMapping
    FROM DWH.dbo.[vD_Employee_ETL] T1
    INNER JOIN DWH.dbo.D_Employee T2      
        ON T1.INJIXO_ID = T2.INJIXO_ID
    WHERE T2.INJIXO_ID <> -1;
/*======================================================(1.0.6)======================================================*/

/*======================================================(1.0.7)======================================================*/
    -- Date: 13-Jun-2024
    -- Description: Stefan Damyanov - Update the MonthFlag based on the difference between LoadDate and current date
    UPDATE T1
    SET MonthFlag = IIF(
        DATEPART(month, LoadDate) - DATEPART(month, GETDATE()) = 0, 'CurrentMonth', 
        IIF(DATEPART(month, LoadDate) - DATEPART(month, GETDATE()) = -1, 'PrevMonth', 'Older')
    )
    FROM DWH.dbo.Mapping_ACERTA_xlsx T1;
/*======================================================(1.0.7)======================================================*/

/*======================================================(1.0.8)======================================================*/
    -- Date: 13-Jun-2024
    -- Description: Stefan Damyanov - Delete records from Mapping_ACERTA_xlsx where MonthFlag is 'CurrentMonth'
    DELETE FROM DWH.dbo.Mapping_ACERTA_xlsx
    WHERE MonthFlag = 'CurrentMonth';
/*======================================================(1.0.8)======================================================*/

/*======================================================(1.0.9)======================================================*/
    -- Date: 13-Jun-2024
    -- Description: Stefan Damyanov - Insert new records into Mapping_ACERTA_xlsx from the temporary table
    INSERT INTO DWH.dbo.Mapping_ACERTA_xlsx
        (Naam, [Externe referentie], Overeenkomstnummer, PERSON_ID, [Login], LoadDate, MonthFlag)
    SELECT 
        Naam, 
        [Externe referentie], 
        Overeenkomstnummer, 
        PERSON_ID, 
        username AS [Login],
        LoadDate = CAST(GETDATE() AS date), 
        MonthFlag = 'CurrentMonth'
    FROM (
        SELECT 
            T1.*, 
            T2.username,  
            T2.PERSON_ID, 
            ROW_NUMBER() OVER (PARTITION BY T1.Overeenkomstnummer ORDER BY [Externe referentie]) RN
        FROM [DWH].[dbo].[vMapping_ACERTA_xlsx] T1
        LEFT JOIN #AcertaEmployeeMapping T2
            ON T1.Overeenkomstnummer = T2.Overeenkomstnummer
        WHERE T1.Naam IS NOT NULL
    ) T
    WHERE RN = 1;
END
GO
/*======================================================(1.0.9)======================================================*/
