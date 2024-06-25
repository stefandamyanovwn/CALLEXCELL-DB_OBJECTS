USE [DwH]
GO

/****** Object:  StoredProcedure [dbo].[spFill_Performance_ACERTA_Injixo_File]    Script Date: 25/06/2024 14:53:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







	/*==================================================(0)=============================================================================*/
	--Description: Stefan Damyanov, 09-Nov-2023
	--Description:
	-- bcp to file
	/*
	File:		"bcp to file.sql"
	Goal:		EXPORT employees activity data to ACERTA formated file
	Autor:		Blazej Blazejczak
	RunTime:	5sec
	Date:		
	Source:		
	TARGET: 	\\cxl-file-01\TCSHARE\KLX\
				CXL_ACERTA_KLX.txt

	Nota:	Each time, we generate dataset	with PROCEDURE		[HR].[spFill_Performance_ACERTA_KLX]	
			for: 
			Previous Month 
			Current Month (MTD)

			And in PROCEDURE [HR].[spFill_Performance_ACERTA_KLX_File]	
				we create TWO (2) files 
				one for Prev Month
				one for Current Month


	-- old
	-- Format:	D:\CallExcell\Tickets\66782  LoonsRapportering\KLX\[Copy of Definitie file interface Callexcell 07-02-2017.xlsx]KLX
	Next files will be created: 
	ACERTA_KLX.txt						file for ACERTA web tool to be imported
	ACERTA_KLX_Details.txt				file for ACERTA_KLX_DetailsAll  with data details
	ACERTA_KLX_DetailsHeaders.txt		file for ACERTA_KLX_DetailsAll  with data headers
	ACERTA_KLX_DetailsAll.txt			file for verification or data control



		EXEC	 [HR].[spFill_Performance_ACERTA_KLX_File]

		SELECT * FROM 	HR.Performance_ACERTA_KLX 


	HISTORY



	*/


		--	Select distinct  Datum from	HR.Performance_ACERTA_KLX order by Datum
 
		-- Prepare data for export to file: ACERTA_KLX.txt
	/*==================================================(0)=============================================================================*/

CREATE	PROCEDURE	[dbo].[spFill_Performance_ACERTA_Injixo_File]		AS


	/*==================================================(1)=============================================================================*/
	--Description: Stefan Damyanov, 09-Nov-2023
	--Description: Main program

		/*==================================================(1.1)=============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:	
		--	CREATE DATASET <<<	   PREVIOUS		>>>		month

		--	To format text file: ACERTA_KLX.txt >> output KLX file
		DROP TABLE IF EXISTS #tmp3;

		print '1.1';
		/*==================================================(1.1)=============================================================================*/

		/*==================================================(1.2)=============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:	

		SELECT	--	 top 10
			Prefix						--	KLX 1 0 264838	"juridische entiteit"
		+	[Externe referentie]		--	
		+	'   '	--3ch
		+	convert(varchar, cast(Datum as date), 103)

		+	'  '	--2ch
		+	RIGHT('0' + PerformanceCode,4)			--	Kalendercode  4ch
		+	'  '	--2ch

		--- +	isnull(ActivityDuration,'   ')		--Aantal uren	4ch					
		+	IIF(	TRY_CAST( ActivityDuration as int) = 0, '', isnull(ActivityDuration,'   ') ) 


		AS		ACERTA_INJIXO
		,		[Datum]		
		INTO	#tmp3			--	select * from #tmp3		drop table ##tmp3
		---		Select count(*)
		FROM	DWH.dbo.Performance_ACERTA_Injixo	--  select * FROM	CXL_Reporting.HR.Performance_ACERTA_KLX		
		
		WHERE	[Externe referentie]	<>	''
		AND		DATEPART(month, [Datum]) =  MONTH(DATEADD(MONTH, -1, GETDATE())) /** this does not work => Datepart(month, getdate() )  - 1	**/ -->> Prev month
		--AND	DATEPART(month, [Datum]) =  Datepart(month, getdate() )	- 0	-- Current month
		AND		[Login]	IN
				(	Select	distinct [Login]
					From	DWH.dbo.Mapping_ACERTA_xlsx
					where	MonthFlag	=	'PrevMonth' ---> no flag exists in table with data 'PrevMonth'
					and		[Login]		is not null
				)

		print '1.2';	
		/*==================================================(1.2)=============================================================================*/

		/*==================================================(1.3)=============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:	
		--		create for previous month
		DROP TABLE IF EXISTS ##PrevMonth;

		select	ACERTA_INJIXO 
		INTO	##PrevMonth		--	SELECT * FROM	##PrevMonth
		from	#tmp3			--	SELECT * FROM	#tmp3
		WHERE	ACERTA_INJIXO	IS NOT NULL

		print '1.3';
		/*==================================================(1.3)=============================================================================*/

		/*==================================================(1.4)=============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:	

		-- EXPORT ACERTA_KLX  data to ACERTA_KLX.txt;  Is used for ACERTA Web tool
		--old:	--	\\cxl-file-01\TCSHARE\INJIXO\CXL_ACERTA_INJIXO '
		--new:	--  \\cxl-file-01\OPERATIONS\INJIXO '
		--	Previous month
		DECLARE	@SQL_cmd	varchar(1000),	@FromDate varchar(30), @ToDate varchar(30) ;

		SET		@FromDate	=	(Select  MIN(Datum) as FromDate From #tmp3	)
		SET		@ToDate		=	(Select  MAX(Datum) as FromDate From #tmp3	)

		--SET		
		--@SQL_cmd	=	('bcp "Select * From ##PrevMonth" queryout "\\cxl-file-01\OPERATIONS\KLX\KLX_Previous_Month_' + @FromDate +' to '+ @ToDate + '.txt" -T -c ');
		--print	@SQL_cmd;

		--	Exec	xp_cmdshell
		--			@SQL_cmd

		print '1.4';
		/*==================================================(1.4)=============================================================================*/

		/*==================================================(1.5)=============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:		
		
		---------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------
		--		create for <<<	   CURRENT		>>> month
		DROP TABLE IF EXISTS #tmp4;

		SELECT	--	 top 10
			Prefix						--	KLX 1 0 264838	"juridische entiteit"
		+	[Externe referentie]		--	
		+	'   '	--3ch
		+	convert(varchar, cast(Datum as date), 103)

		+	'  '	--2ch
		+	RIGHT('0' + PerformanceCode,4)			--	Kalendercode  4ch
		+	'  '	--2ch

		--- +	isnull(ActivityDuration,'   ')		--Aantal uren	4ch					
		+	IIF(	TRY_CAST( ActivityDuration as int) = 0, '', isnull(ActivityDuration,'   ') ) 


		AS		ACERTA_INJIXO
		,		[Datum]	

		INTO	#tmp4			--	select * from #tmp4		drop table ##tmp4
		---		Select count(*)
		FROM	DWH.dbo.Performance_ACERTA_Injixo	--  select * FROM	HR.Performance_ACERTA_KLX 		
		
		WHERE	[Externe referentie]	<>	''
		--AND	DATEPART(month, [Datum]) =  Datepart(month, getdate() ) - 1	-->> Prev month
		AND		DATEPART(month, [Datum]) =  Datepart(month, getdate() )	- 1	-- Current month
		AND		[Login]	IN
				(	Select	distinct [Login]
					From	DWH.dbo.Mapping_ACERTA_xlsx
					where	MonthFlag	=	'CurrentMonth'
					and		[Login]		is not null
				)

        --select * from #tmp4

        print '1.5';  
		/*==================================================(1.5)=============================================================================*/

		/*==================================================(1.6)=============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:	
		
		DROP TABLE IF EXISTS ##CurrentMonth;
		select  ACERTA_INJIXO 
		INTO	##CurrentMonth		--	SELECT * FROM	##CurrentMonth
		from	#tmp4				--	SELECT * FROM	#tmp4
		WHERE	ACERTA_INJIXO	IS NOT NULL


		--	Current month
		--	DECLARE	@SQL_cmd	varchar(1000),	@FromDate varchar(30), @ToDate varchar(30) ;
		SET		@FromDate	=	(Select  MIN(Datum) as FromDate From #tmp4	)
		SET		@ToDate		=	(Select  MAX(Datum) as FromDate From #tmp4	)		--	CXL_Reporting.HR.Performance_ACERTA_INJIXO

		SET		
		--@SQL_cmd	=	('bcp "Select * From ##CurrentMonth" queryout "\\cxl-file-01\OPERATIONS\INJIXO\INJIXO_Current_Month_' + @FromDate +' to '+ @ToDate + '.txt" -T -c ');
		@SQL_cmd	=	('bcp "Select * From ##CurrentMonth order by 1" queryout "\\Cxl-file-01\operations\KLX\KLX_Current_Month_' + @FromDate +'_to_'+ @ToDate + '_test.txt" -T -c ');

		print	@SQL_cmd;

			Exec master..xp_cmdshell
			@SQL_cmd
        print '1.6'; 
		/*==================================================(1.6)=============================================================================*/

		/*==================================================(1.7)=============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:	
		/*	============================================================================================================================	*/

		-- 'bcp "Select * From ##tmp3" queryout "D:\Temp\ACERTA\ACERTA_KLX.txt" -T -c'

		--->>>	'bcp "Select * From ##tmp3" queryout "\\cxl-file-01\TCSHARE\KLX\CXL_ACERTA_KLX.txt" -T -c'

		--	TARGET: 	\\cxl-file-01\OPERATIONS\KLX

		-- GO
		-- EXPORT ACERTA_KLX_Details.txt;	Is used for verification, tests, evaluation
		---Exec xp_cmdshell	'bcp "Select * From ##tmp4" queryout "D:\Temp\ACERTA\ACERTA_KLX_Details.txt" -T -c '

		-- EXPORT the Headers for ACERTA_KLX_Details
		---Exec xp_cmdshell 'BCP "select ''Prefix'',''PrefixRijkskNr'',''RijksNr'',''PostfixRijksNr'',''Datum'',''Blanko2'',''PrefixPerformanceCode'',''PerformanceCode'',''PostfixPerformanceCode'',''ActivityDurationH'',''ActivityName'',''IsPaid'',''EmployeeID'',''FirstName'',''LastName''" queryout "D:\Temp\ACERTA\ACERTA_KLX_DetailsHeaders.txt"  -T -c'

		-- EXPORT combinations : Headers with data
		---Exec xp_cmdshell 'copy /b "D:\Temp\ACERTA\ACERTA_KLX_DetailsHeaders.txt"	  +   "D:\Temp\ACERTA\ACERTA_KLX_Details.txt"   "D:\Temp\ACERTA\ACERTA_KLX_DetailsAll.txt"'


		-- select *	from dbo.D_Employee	where		InterimKantoor	= 'Vast' and		( EndDate between '2017-01-01' and '2017-01-31' OR EndDate is null )
		--exec master..xp_cmdshell 'BCP "select 'SETTINGS_ID','GROUP_NAME'" queryout d:\header.csv  -c  -T -t,'
		--exec master..xp_cmdshell 'BCP "select SETTINGS_ID,GROUP_NAME from [DB]..[TABLE]" queryout "d:\columns.csv" -c -t, -T '
		--exec master..xp_cmdshell 'copy /b "d:\header.csv" + "d:\columns.csv" "d:/result.csv"'

		print '1.7';
		/*==================================================(1.7)=============================================================================*/	
	/*==================================================(1)=============================================================================*/
GO