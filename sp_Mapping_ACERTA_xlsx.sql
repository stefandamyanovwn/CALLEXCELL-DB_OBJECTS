USE [DwH]
GO

/****** Object:  StoredProcedure [dbo].[sp_Mapping_ACERTA_xlsx]    Script Date: 25/06/2024 15:06:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







/*==================================================(0)=============================================================================*/
--Description: Stefan Damyanov, 09-Nov-2023
--Description: oude methode, do not use: 	
--Description: I:\Documentation\Backups\Stored Perocedure\2022-10-17 sp_MappingAccerta_xlsx oude methode niet gebruiken.sql

/*  118708 - KLX bestand 

	match first on  RijksRegisterNr

	SOURCE		ExcelFiles.HR.vMapping_ACERTA_xlsx

	TARGET:		CXL_Reporting.HR.Mapping_ACERTA_xlsx
	
	EXEC	[HR].[sp_Mapping_ACERTA_xlsx]		


	Select * From CXL_Reporting.HR.Mapping_ACERTA_xlsx*/
/*==================================================(0)============================================================================*/

CREATE	PROCEDURE	[dbo].[sp_Mapping_ACERTA_xlsx]			AS

	/*==================================================(1)============================================================================*/
	--Description: Stefan Damyanov, 09-Nov-2023
	--Description: Exit sp if source is empty
	DECLARE		@aantal int;

	SELECT @aantal =count(*)
		FROM [DWH].[dbo].[vMapping_ACERTA_xlsx]


		PRINT @aantal;

	IF @aantal	= 0	
		  
    RETURN
	/*==================================================(1)============================================================================*/


	/*==================================================(2)============================================================================*/
	--Description: Stefan Damyanov, 09-Nov-2023
	--Description: Main part of procedure 


		/*==================================================(2.1)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description: Get Employee Mapping
		--Description: TODO: Not ready because need to use tables in DWH 

		DROP TABLE if exists #AcertaEmployeeMapping;

		SELECT distinct T1.[Login] as username, 
		                TRY_CAST(T1.PERSONEL_NUMBER  as int) AS Overeenkomstnummer, 
						T2.EmployeeKey as PERSON_ID
          INTO #AcertaEmployeeMapping					
		  FROM DWH.dbo.[vD_Employee_ETL] T1 
		 INNER JOIN	DWH.dbo.D_Employee T2      
		    ON T1.INJIXO_ID = T2.INJIXO_ID
		 WHERE 1 = 1				   
		   AND T2.INJIXO_ID	<> -1;		  	
		/*==================================================(2.1)============================================================================*/

		/*==================================================(2.2)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description: Determine current table MonthFlag :	'CurrentMonth', 'PrevMonth', 'Older'

		UPDATE T1
		   SET MonthFlag =	
				IIF( DATEPART(month, LoadDate) - DATEPART(month, Getdate()) = 0, 'CurrentMonth', 
				IIF( DATEPART(month, LoadDate) - DATEPART(month, Getdate()) = -1, 'PrevMonth',	'Older' ))
		  FROM DWH.dbo.Mapping_ACERTA_xlsx T1;
		/*==================================================(2.2)============================================================================*/

		/*==================================================(2.3)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description: delete & reload current month data

		DELETE FROM	DWH.dbo.Mapping_ACERTA_xlsx
		 WHERE MonthFlag = 'CurrentMonth';
		/*==================================================(2.3)============================================================================*/

		/*==================================================(2.4)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description: select * from DWH.dbo.Mapping_ACERTA_xlsx where  naam like '%Gerardu%'

		INSERT INTO	DWH.dbo.Mapping_ACERTA_xlsx	
		        (Naam, 
				 [Externe referentie], 
				 Overeenkomstnummer, 
				 PERSON_ID, 
				 [Login], 
				 LoadDate, 
				 MonthFlag)
		  SELECT Naam, 
		         [Externe referentie], 
				 Overeenkomstnummer, 
				 PERSON_ID, 
				 username AS [Login],
				 LoadDate	=	cast(Getdate() as date), 
				 MonthFlag	=	'CurrentMonth' 
		    FROM (SELECT T1.*, 
			             T2.username,  
						 T2.PERSON_ID,	
						 ROW_NUMBER() over( partition by T1.Overeenkomstnummer order by [Externe referentie]) RN
		            FROM [DWH].[dbo].[vMapping_ACERTA_xlsx] T1	
		            LEFT JOIN #AcertaEmployeeMapping T2
		              ON T1.Overeenkomstnummer	= T2.Overeenkomstnummer
		           WHERE T1.Naam  is not null) T
		   WHERE RN = 1;
		/*==================================================(2.1)============================================================================*/
	/*==================================================(2)============================================================================*/
GO
