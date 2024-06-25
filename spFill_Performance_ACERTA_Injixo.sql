USE [DwH]
GO

/****** Object:  StoredProcedure [dbo].[spFill_Performance_ACERTA_Injixo]    Script Date: 25/06/2024 14:55:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO









	/*==================================================(0)=============================================================================*/
	--Description: Stefan Damyanov, 09-Nov-2023
	--Description: oude methode, do not use: 
	/*
	Goal		Generate data for Injixo file into a Table
	Source		[CXL_DWH].[HR].PerformanceSolvus
	Target		CXL_Reporting.[HR].[Performance_ACERTA_Injixo]
	Autor
	Date

	Nota:	Each time, we generate dataset for: 
			Previous Month 
			Current Month (MTD)
			And in PROCEDURE [HR].[spFill_Performance_ACERTA_Injixo_File]	
				we create TWO (2) files 
				one for Prev Month
				one for Current Month

	How to generate the KLX file

	1)	GENERATE dataset source by

		EXEC  CXL_DWH.HR.spGET_PerformanceSolvus_V1 'P2M', 'basis'	
		TARGET:		[CXL_DWH].[HR].[PerformanceSolvus]

	2)	PREPARE dataset for KLX file

		EXEC	[HR].[spFill_Performance_ACERTA_Injixo]
		TARGET:		CXL_Reporting.[HR].[Performance_ACERTA_Injixo]

	3)	GENEREATE KLX file

		EXEC		[HR].[spFill_Performance_ACERTA_Injixo_File]	
		TARGET:		\\cxl-file-01\OPERATIONS\INJIXO\		CXL_ACERTA_Injixo 2022-10-01 to 2022-11-01.txt
		File format:	"CXL_ACERTA_KLX " + FromDate + "to" + ToDate + ".txt"
		File data format:	txt, scv

	The 3 steps are Joined into one JOB:	ACERTA_Injixo_File

	HISTORY
	TEST

	Default is 'P'
		EXEC	[HR].[spFill_Performance_ACERTA_INJIXO]
	

		to fill the table [CXL_DWH].[HR].PerformanceSolvus   do :  this is our source

		EXEC "CXL_DWH"."HR"."spGET_PerformanceSolvus_V1" 'pém', 'basis'
		OR
		EXEC  CXL_DWH.HR.spGET_PerformanceSolvus_V1 'P2M', 'basis'	-- use previous twoo months all the time for KLX
	
		TARGET		Select * from CXL_Reporting.[HR].[Performance_ACERTA_INJIXO] 

	

	HISTORY
	,	RIGHT( sum( P.ScheduledTotalTime ) * 100 + 100000 , 4)	AS	ActivityDuration

	and Group by: 
	,	RIGHT(	ISNULL( cast(P.PerformanceCode as char(4)), cast( '100' as char(4))) + 10000 , 4 )

						EXEC	[HR].[spFill_Performance_ACERTA_INJIXO]	
	*/	
	/*==================================================(0)=============================================================================*/


 CREATE	PROCEDURE		[dbo].[spFill_Performance_ACERTA_Injixo]					AS

	/*==================================================(1)============================================================================*/
	--Description: Stefan Damyanov, 09-Nov-2023
	--Description: Main part of procedure 


		/*==================================================(1.1)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description: STEP1 a:	Declare vars & create All month dates
		-- the month is from the >> SELECT MIN( ShiftStartDate ) FROM HR.PerformanceSolvus 	

		IF( OBJECT_ID('tempdb..#dates') is not null )	drop table	#dates;
		IF( OBJECT_ID('tempdb..#tmp1')  is not null )	drop table	#tmp1;
		IF( OBJECT_ID('tempdb..#tmp2')  is not null )	drop table	#tmp2;
		IF( OBJECT_ID('tempdb..#tmp3')  is not null )	drop table	#tmp3;
		IF( OBJECT_ID('tempdb..#tmp4')  is not null )	drop table	#tmp4;
		/*==================================================(1.1)============================================================================*/

		/*==================================================(1.2)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		DECLARE		@Tempdate			DATE;
		DECLARE		@Enddate			DATE;	--	calculation dates are : prev2M last day + prev M + current M MTD
		DECLARE		@Startdate			DATE;
		DECLARE		@RealStartdate		DATE;	--	MTD reporting
		DECLARE		@RealEndDate		DATE;	--	MTD reporting
		DECLARE		@RealPrevStartdate	DATE;	--	prev M reporting
		DECLARE		@RealPrevEndDate	DATE;	--	prev M reporting
		/*==================================================(1.2)============================================================================*/
		
		/*==================================================(1.3)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		--  for testing only 
		--	declare	@CP varchar(16)	=	'C'
		--	select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0) --First day of previous month
		--	select DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) --Last Day of previous month

		SET			@Tempdate	= ( select MIN( ShiftStartDate ) from dbo.PerformanceSolvus );--	2022-09-01
		--SET			@StartDate	=	EOMONTH(@Tempdate);
		SET			@StartDate	=	@Tempdate;
		SET			@EndDate	=	EOMONTH( Getdate() );

		SET			@RealStartdate	= ( select DATEADD(DAY, 1, EOMONTH( @Enddate, -1)) )
		SET			@RealEndDate	= ( select MAX( ShiftStartDate ) from dbo.PerformanceSolvus );--	2022-11-01
	
		SET			@RealPrevStartdate	= ( select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0)	);	--First day of previous month
		SET			@RealPrevEndDate	= ( select DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1)	); --Last Day of previous month	
	

		--Print		'@Tempdate:		' + cast( @Tempdate as varchar(55));		--	used only to calculate dates		2022-08-01

		--Print		'@StartDate:		' + cast( @StartDate as varchar(55));	--	calculation		Start date			2022-08-31	calculate using this date
		--Print		'@Enddate:		' + cast( @Enddate as varchar(55));			--	calculation		End date			2022-09-30	deliver dataset with this date
	
		--Print		'@RealStartdate:	' + cast( @RealStartdate as varchar(55));--	Reporting	Start Date for dataset		2022-09-01  deliver dataset with this date
		--Print		'@RealEndDate:	' + cast( @RealEndDate as varchar(55));		--	Reporting	End Date	

		--Print		'@RealPrevStartdate:	' + cast( @RealPrevStartdate as varchar(55));--	Reporting	Start Date for dataset		2022-09-01  deliver dataset with this date
		--Print		'@RealPrevEndDate:	' + cast( @RealPrevEndDate as varchar(55));		--	Reporting	End Date	

		--	IF we generate data for current month we must change the @StartDate; @RealStartdate; @Enddate;
		--	SELECT MONTH(GETDATE()) AS Month;
		/*==================================================(1.3)============================================================================*/

		/*==================================================(1.4)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		--	GET DATES
		SELECT	DATEADD(DAY,number, @Startdate)							AS	Date1, 
				convert(varchar, DATEADD(DAY,number, @Startdate), 103)	AS	Date2				
		INTO	#dates  -- select * from #dates
		FROM	master..spt_values
		WHERE	type	= 'P'
		AND		DATEADD(DAY,number, @Startdate) <= @Enddate
		 -- select * from #dates
        /*==================================================(1.4)============================================================================*/

		/*==================================================(1.5)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		---------------------------------------------------------------------------------------------------
		--	Externe referentie
		--	SELECT * FROM  CXL_Reporting.dbo.MappingAccerta_xlsx  where naam like 'blazej%'
		--	JOIN ON 

		--	353 = Ziek zonder Attest; Ziekte niet vergoed
		--  

		--	BR  SET all "ziek" to code  50
		DROP TABLE IF EXISTS	#tmp0;		--	select * from #tmp0

			Select		RegisterNumber	
					,	ShiftStartDate	
					----BR105	all "ziek" gets 50 except  4503 --- CHECK WITH MARIEKE ....
					, cast(PerformanceCode as varchar(max)) as PerformanceCode
					--,	PerformanceCode	=	IIF(	CHARINDEX('ziek', ScheduledActivity) > 0 
					--								AND		PerformanceCode NOT IN(	4503, 3523, 353,250),																						
					--								50, 
					--						PerformanceCode)

					,	ScheduledActivity
					,	PERSON_ID
					,	EmployeeLogin
					,	FirstName
					,	LastName
					,	ScheduledTotalTime
			INTO	#tmp0								--	select distinct ShiftStartDate
			FROM	[DWH].[dbo].PerformanceSolvus		--	order by ShiftStartDate
			WHERE 1 = 1	
			  and ShiftStartDate >=	@StartDate	

			-- SELECT min(ShiftStartDate), max(ShiftStartDate) FROM	[CXL_DWH].[HR].PerformanceSolvus
		/*==================================================(1.5)============================================================================*/
		
		/*==================================================(1.6)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		---------------------------------------------------------------------------------------------------
		-- STEP1 b:	Create Activity duration Table with formated data
		DROP TABLE IF EXISTS	#tmp1;

		SELECT	--	'KLX10264838'											AS	Prefix,					                              --10 char  KLX + 1 + juridische entiteit
			    M.[Externe referentie]									AS	[Externe referentie],	                                  --17 char  Arbeidsovereenkomst HRM
			    convert(varchar, P.ShiftStartDate, 101)					AS  Datum,					                                  --10 char
			    P.ShiftStartDate										AS	ShiftStartDate,
				P.PerformanceCode, 
			    --PerformanceCode	=	RIGHT(	ISNULL( cast(	P.PerformanceCode as varchar(4)), cast( '100' as varchar(4))) + 10000 , 4 ),
			    --round(RIGHT( sum(P.ScheduledTotalTime),5),3) * 100 + 100000 	AS	ActivityDuration,                                         --BR: Kalendercode : IF Blank THEN "100"  
				sum(P.ScheduledTotalTime) AS	ActivityDuration,
			    M.Overeenkomstnummer,
				p.PERSON_ID,
			    M.[login],
			    P.FirstName,
			    P.LastName,
			    sum( P.ScheduledTotalTime )		AS	ActivityDuration_float
   		   INTO #tmp1	 										
		   FROM	#tmp0 P
		  INNER JOIN dbo.v_Mapping_ACERTA_xlsx	M	
		     ON	P.EmployeeLogin	=M.[Login]
		  WHERE	1 = 1		
		    and	P.ShiftStartDate >=	@StartDate				
		  GROUP BY M.[Externe referentie],
		           P.ShiftStartDate,	
				   P.PerformanceCode,
			       --RIGHT(	ISNULL( cast(P.PerformanceCode as varchar(4)), cast( '100' as varchar(4))) + 10000 , 4 ),
		           M.Overeenkomstnummer,
				   P.EmployeeLogin,
				   p.PERSON_ID,
			       M.[login],
		           P.FirstName,
		           P.LastName;
		/*==================================================(1.6)============================================================================*/

		/*==================================================(1.7)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description: TODO test purposes
		--=========================================================================================================================

			--	select * from #tmp1 where PerformanceCode = '0359' and [Externe referentie]='02648380090487001' order by [Externe referentie],	[Datum]	

		--=========================================================================================================================
		/*==================================================(1.7)============================================================================*/

		/*==================================================(1.8)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		--	BR101	
		--	IF       on the same day we have 100 and	1020 as performance code                      
		--	THEN     performance code 100  is  SET to	1020
		--	101a)
			DROP TABLE IF EXISTS	#tmp10;

			SELECT	[Externe referentie], Datum, 
				TRY_CAST(PerformanceCode as int) AS PerformanceCode, 
				ShiftStartDate
			,	iif( PerformanceCode = 100, 1020, PerformanceCode) AS Perf1020_
			INTO	#tmp10		--	drop table #tmp10
			FROM	#tmp1	
			WHERE	PerformanceCode IN (  '0100', '1020' ) 

		--	101b)
			DROP TABLE IF EXISTS	#tmp12;	--	Select * from #tmp12
			SELECT  *
			,		ROW_NUMBER() over( partition by [Externe referentie], Datum, Perf1020_  order by PerformanceCode desc)	AS	R2
			INTO	#tmp12	--	drop table #tmp12	--	select * from #tmp12 order by ShiftStartDate
			FROM	#tmp10 

		--	101c)
			--		this is the list with double PerformanceCode on 1 day with 100 & 1020
			DROP TABLE IF EXISTS	#ListWithDoublesPerfCode;
			SELECT		T1.*	--, '--', T2.* 
			INTO		#ListWithDoublesPerfCode
			FROM		#tmp10	T1
			LEFT JOIN
					(
					Select	* 
					From	#tmp12		--	select * from #tmp12
					Where	Perf1020_	=	'1020'
					and		R2		>	1		--  order by ShiftStartDate
					)		T2		
			ON		T1.[Externe referentie] =	T2.[Externe referentie]
			AND		T1.Datum				=	T2.Datum
			WHERE	T2.[Externe referentie]	is not null

		--	101d)
			UPDATE		T1	
			SET			T1.PerformanceCode		=	T2.Perf1020_
		--	SELECT		distinct	T1.[Externe referentie], T1.PerformanceCode, T1.ShiftStartDate, T2.PerfC_
			FROM		#tmp1						T1
			INNER JOIN	#ListWithDoublesPerfCode	T2	--	select * from #ListWithDoublesPerfCode
			on			T1.[Externe referentie]	=	T2.[Externe referentie]
			and			T1.ShiftStartDate		=	T2.ShiftStartDate
			where		T1.PerformanceCode		=	100

		-- #tmp1 is now UPDATED with BR101
		/*==================================================(1.8)============================================================================*/

		/*==================================================(1.9)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		--=========================================================================================================================
		--	select * from #tmp1 where PerformanceCode = '0359' and [Externe referentie]='02648380090487001' order by [Externe referentie],	[Datum]	

		--	select * from #CrossJOIN 	 where [Externe referentie] = '02648380090487001' order by Date1	 

		--=========================================================================================================================
		/*==================================================(1.9)============================================================================*/

		/*==================================================(1.10)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		-- STEP4:	Generate missing dates	
			--a)	cross join of all Dates x  [Externe referentie]	
			DROP TABLE IF EXISTS #CrossJOIN;		--	select * from #CrossJOIN	
			SELECT	a.[Externe referentie], d.Date1 	
			INTO	#CrossJOIN					--		SELECT min(Date1)  from #CrossJOIN  where  [Externe referentie] = '02648380090746001'
			FROM(	select		[Externe referentie]
					from		#tmp1			--		SELECT * from #tmp2	 where  [Externe referentie] = '02648380090746001' order by Datum 
					group by	[Externe referentie]
				)a
			CROSS JOIN	#dates d	-- select * from #dates  

		---	2 steps at ones: 
		--	1)	FULL JOIN with missing dates  
		--	2)	get LAG Performance code
		/*==================================================(1.10)============================================================================*/

		/*==================================================(1.11)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		--	BR104
		--	het overbruggen van Weekends als men op Vrijdag of Maandag ziek is
		--	BK: if PerformanceCode='' AND LAG  Code = '0050' THEN  50 ELSE CODE
		--	BK: if PerformanceCode='' AND LEAD Code = '0050' THEN  50 ELSE CODE
	--	============
		DROP TABLE IF EXISTS #tmp2;
		SELECT	
				coalesce( T1.[Externe referentie], T2.[Externe referentie])	AS [Externe referentie] ,
				coalesce( T1.Datum, T2.Date1)   AS	Datum,
				T1.PerformanceCode,
				T1.ActivityDuration

		,	LAG_PerformanceCode  =	
			ISNULL( LAG(T1.PerformanceCode,1) over( partition by  T2.[Externe referentie] order by T2.Date1)  ,
					LAG(T1.PerformanceCode,2) over( partition by  T2.[Externe referentie] order by T2.Date1)  ) 

		,	LEAD_PerformanceCode	=	
			ISNULL( LEAD(T1.PerformanceCode,1) over( partition by  T2.[Externe referentie] order by T2.Date1)  ,
					LEAD(T1.PerformanceCode,2) over( partition by  T2.[Externe referentie] order by T2.Date1)  ) 

		,	T1.Overeenkomstnummer
		,	T1.PERSON_ID
		,	T1.[login]
		,	T1.FirstName
		,	T1.LastName
		,	ActivityDuration_float
		INTO		#tmp2				--	select * from #tmp2		where [Externe referentie] LIKE	'%2648380091031001%' 
		FROM		#tmp1		T1		--	select * from #tmp1
		full join	#CrossJOIN	T2		--	select * from #CrossJOIN
		on			T1.Datum					=	T2.Date1
		and			T1.[Externe referentie]		=	T2.[Externe referentie]

		--	where		T2.[Externe referentie]		LIKE	'%2648380091031001%' 
		--	order by	coalesce( T1.Datum, T2.Date1)


		--	select * from #tmp2 where [Externe referentie] = '02648380090487001' order by Datum	 

		-- DELETE Not needed rows from the Main dataset, generated by Date CrossJoin
		--select *	
		DELETE		--	SELECT *
		FROM		#tmp2	--		select * from #tmp2 where PerformanceCode = '0359' and [Externe referentie]='02648380090487001' order by [Externe referentie],	[Datum]	
		WHERE		PerformanceCode			IS NULL

		AND	(		LAG_PerformanceCode		NOT IN ('0050', '0359', '3031', '4503', '3523', '0353', '0250' )		--	old NOT IN ('0050', '0060', '0065', '0059', '0055', '0359', '3031', '4503' )
				OR	LEAD_PerformanceCode	NOT IN ('0050', '0359', '3031', '4503', '3523', '0353', '0250' )
			)
		/*==================================================(1.11)============================================================================*/

		/*==================================================(1.12)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		--	================================================================================================
		/*==================================================(1.12)============================================================================*/

		/*==================================================(1.13)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		DROP TABLE IF EXISTS #tmp3;
		SELECT	
				'INJ10264838'	AS	Prefix
			,	[Externe referentie],	[Datum]		

		                          
		---,	COALESCE(PerformanceCode, IIF( LAG_PerformanceCode='0050' OR LEAD_PerformanceCode='0050', '0050', PerformanceCode) ) AS [PerformanceCode]
			,	[PerformanceCode]	=	
					COALESCE(PerformanceCode, 
						IIF( LAG_PerformanceCode='0050' OR LEAD_PerformanceCode='0050', '0050', 
						IIF( LAG_PerformanceCode='0250' OR LEAD_PerformanceCode='0250', '0250', 
						IIF( LAG_PerformanceCode='0359' OR LEAD_PerformanceCode='0359', '0359', 
						IIF( LAG_PerformanceCode='3031' OR LEAD_PerformanceCode='3031', '3031',
						IIF( LAG_PerformanceCode='3523' OR LEAD_PerformanceCode='3523', '3523',
						IIF( LAG_PerformanceCode='0353'	OR LEAD_PerformanceCode='0353' ,'0353' ,
						IIF( LAG_PerformanceCode='4503' OR LEAD_PerformanceCode='4503', '4503', PerformanceCode
							)))))))) 

			--,	[ActivityDuration]
			,	Overeenkomstnummer
			,	PERSON_ID
			,	[login]
			,	FirstName
			,	LastName	
			,	sum(	ActivityDuration_float)															AS	ActivityDuration_float
			,	RIGHT( CAST( ROUND( sum( ActivityDuration_float ) , 2) * 100 + 10000 as INT), 4 )		AS	ActivityDuration
		INTO	#tmp3			--	select * from #tmp3		where [Externe referentie] LIKE	'%2648380091031001%'   	order by Datum		--'%90746001%' 
		FROM	#tmp2			--	select * from #tmp2		where [Externe referentie] LIKE	'%2648380091031001%'  	order by Datum	
		WHERE	1=1	
			--	and 	ActivityDuration  IS NOT NULL
			--	and		[Externe referentie] like '%2648380090526001%'
			--	and		[Datum]		= '2022-10-19'	
		group by	[Externe referentie],	
					[Datum]	, 

			---	COALESCE(	PerformanceCode, IIF( LAG_PerformanceCode='0050' OR LEAD_PerformanceCode='0050', '0050', PerformanceCode) )
				COALESCE(PerformanceCode, 
						IIF( LAG_PerformanceCode='0050' OR LEAD_PerformanceCode='0050', '0050', 
						IIF( LAG_PerformanceCode='0250' OR LEAD_PerformanceCode='0250', '0250', 
						IIF( LAG_PerformanceCode='0359' OR LEAD_PerformanceCode='0359', '0359', 
						IIF( LAG_PerformanceCode='3031' OR LEAD_PerformanceCode='3031', '3031', 
						IIF( LAG_PerformanceCode='3523' OR LEAD_PerformanceCode='3523', '3523', 
						IIF( LAG_PerformanceCode='0353'	OR LEAD_PerformanceCode='0353' ,'0353', 
						IIF( LAG_PerformanceCode='4503' OR LEAD_PerformanceCode='4503', '4503', PerformanceCode
							))))))))

			,	Overeenkomstnummer
			,	PERSON_ID
			,	[login], FirstName, LastName	
		/*==================================================(1.13)============================================================================*/

		/*==================================================(1.14)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		--	================================================================================================

				--	select * from #tmp2
				--  select * from #tmp3	where 

		/*
			Some lines are produced with NULL for Overeenkomstnummer
			To fill these NULL lines, generate a matrix with all user attributes
		*/
		DROP TABLE IF EXISTS #ALL_Overeenkomstnummer;
		Select	DISTINCT		[Externe referentie],	Overeenkomstnummer
			,	PERSON_ID
			,	[login],	FirstName,	LastName
		INTO	#ALL_Overeenkomstnummer					---  Select * from #ALL_Overeenkomstnummer where 	  [Externe referentie] = 02648380090873001
		From	#tmp3		--	select * from #tmp3
		WHERE	Overeenkomstnummer IS NOT NULL
		/*==================================================(1.14)============================================================================*/

		/*==================================================(1.15)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		UPDATE	T1
		SET		T1.Overeenkomstnummer	= T2.Overeenkomstnummer,
				T1.PERSON_ID			= T2.PERSON_ID,	
				T1.[login]				= T2.[login],	
 				T1.FirstName			= T2.FirstName,	
				T1.LastName				= T2.LastName
		FROM		#tmp3	T1
		INNER JOIN	#ALL_Overeenkomstnummer	T2
		ON			T1.[Externe referentie]		=	T2.[Externe referentie] 
		WHERE		T1.Overeenkomstnummer IS NULL
		/*==================================================(1.15)============================================================================*/

		/*==================================================(1.16)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
		---  --------------------------------------------
		-- Generate TABLE Output

		--	select * from  CXL_Reporting.[HR].[Performance_ACERTA_Inxjixo]

			--	IF( object_id('HR.PerformanceSolvus_KLX') is not null )	DROP table	HR.PerformanceSolvus_KLX;
			TRUNCATE TABLE	DWH.[dbo].[Performance_ACERTA_Injixo];
			INSERT	INTO	DWH.[dbo].[Performance_ACERTA_Injixo]	-- 
			--	select * from CXL_Reporting.HR.[Performance_ACERTA_Injixo] where RijksNr =  '65102921262' order by Datum
			(	Prefix
			,	[Externe referentie]
			,	[Datum]
			, 	[PerformanceCode]
			,	Overeenkomstnummer
			,	PERSON_ID
			,	[login]
			,	FirstName
			,	LastName
			,	ActivityDuration_float
			,	[ActivityDuration] 
			)
			SELECT * FROM	#tmp3 
			WHERE	[Datum] >= @RealPrevStartdate	-- this is the first of previous month
		/*==================================================(1.16)============================================================================*/

		/*==================================================(1.17)============================================================================*/
		--Description: Stefan Damyanov, 09-Nov-2023
		--Description:
	
			--	where [Externe referentie] like '%2648380090526001%'
		/*	
				Select	* 		
				From	CXL_Reporting.[HR].[Performance_ACERTA_Injixo] 
				where	[Externe referentie] like '02648380090820001'
				order by [Datum] 

				Select * from	[CXL_DWH].[HR].PerformanceSolvus
				Where	FirstName= 'Dirk' and  LastName= 'Grosemans'
				order by ShiftStartDate 
		*/	
	
			--select	* 
			--from	CXL_Reporting.[HR].[Performance_ACERTA_Injixo]	
			--where	[Externe referentie] 
			--LIKE	'%90746001%'	--	'%2648380091031001%'   
			--order by Datum		

			--	Select * from CXL_Reporting.[HR].[Performance_ACERTA_Injixo]	
		/*==================================================(1.17)============================================================================*/		
	/*==================================================(1)============================================================================*/
GO