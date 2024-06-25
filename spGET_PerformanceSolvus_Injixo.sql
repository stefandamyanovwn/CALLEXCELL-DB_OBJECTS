USE [DwH]
GO

/****** Object:  StoredProcedure [dbo].[spGET_PerformanceSolvus_Injixo]    Script Date: 25/06/2024 15:12:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO














--EXEC "Dwh"."dbo"."spGET_PerformanceSolvus_Injixo"  'P2M', 'basis'	


--EXEC "Dwh"."dbo"."spGET_PerformanceSolvus_Injixo"  'PW', 'basis'

--EXEC "Dwh"."dbo"."spGET_PerformanceSolvus_Injixo" null, 'basis', '2023-09-01', '2023-09-15'

-- TODO: nieuwe procedure


CREATE PROCEDURE		[dbo].[spGET_PerformanceSolvus_Injixo]
	--		DECLARE				--	outcommnet	<<<---
@DateSpanStr	varchar(12)		=	'NW',
@LongShort		varchar(12)		=	'basis',
@FromDate_		Date			=	 NULL,
@ToDate_		Date			=	 NULL

AS	
BEGIN

SET NOCOUNT ON;


DECLARE @today AS DATE	= dateadd(month, -0, GetDate() )  ;
declare	@d	DATE		= getdate();
declare	@FromDate date , @ToDate date;

IF @DateSpanStr IN( 'PW', 'PWc')  -- prev week		OK
BEGIN
	SELECT	@ToDate		= DATEADD(DAY, 1-DATEPART(WEEKDAY, @d), @d)
	SELECT	@FromDate	= DATEADD(DAY, -6, @ToDate )
END -- PW

IF @DateSpanStr IN( 'CW', 'CWc')	-- current week		OK
BEGIN
	SELECT	@FromDate		=	DATEADD(DAY, 1-DATEPART(WEEKDAY, @d ) +1, @d)
	SELECT	@ToDate			=	DATEADD(DAY, 6, @FromDate )	
END -- PW

IF @DateSpanStr IN(  'NW', 'NWc') -- next Week			NOK
BEGIN
	SELECT	@FromDate		=   DATEADD([day], ((DATEDIFF([day], '19000101', getdate()) / 7) * 7) + 7, '19000101')
	SELECT	@ToDate			=		DATEADD(DAY, 6, @FromDate )
END -- PW


IF @DateSpanStr IN(  'PM', 'PMc')	-- prev month		OK  
BEGIN
	SET		@FromDate	= ( SELECT DATEADD( DAY, 1, EOMONTH ( @today, -2 )	))  --Begin Prev Month
	SET		@ToDate		= ( SELECT EOMONTH ( @today, -1 ) )						--End Prev Month
END -- PM

--	new 2022-10-28BB
-- Months	---------------------------------------------------------
IF @DateSpanStr IN(  'P2M', 'P2Mc')	-- prev 2 months		OK  
BEGIN
	SET		@FromDate	= ( SELECT DATEADD( DAY, 1, EOMONTH ( @today, -3 )	))  --Begin Prev 2 Month
	SET		@ToDate		= ( SELECT DATEADD( DAY, -1, EOMONTH ( GETDATE() )	)) 						--End Prev 1 Month
	--SET		@ToDate		= ( SELECT EOMONTH ( @today, -1 ) )						--End Prev 1 Month
END -- P2M

--	new 2022-10-28BB
--	CURRENT and PREV MONTH
IF @DateSpanStr IN(  'C2M', 'C2Mc') -- current month		OK
BEGIN
	SET		@FromDate = (SELECT DATEADD( DAY, 1, EOMONTH ( @today, -2 )	))
	SET		@ToDate =	( SELECT EOMONTH ( @today ) )
END -- C2M

---------------------------------
IF @DateSpanStr IN(  'CM', 'CMc') -- current month		OK
BEGIN
	SET		@FromDate = (SELECT DATEADD( DAY, 1, EOMONTH ( @today, -1 )	))
	SET		@ToDate =	( SELECT EOMONTH ( @today ) )
END -- PW
---------------------------------
IF @DateSpanStr IN(  'NM', 'NMc')	-- next month		OK
BEGIN
	SELECT	@FromDate	=	(SELECT DATEADD( DAY, 1, EOMONTH ( @today )))
	SELECT	@ToDate		=	(SELECT EOMONTH ( @today, 1 )	)
END -- PW

IF 1=1
BEGIN
	SELECT	@FromDate	=	(SELECT DATEADD( DAY, -1, @FromDate ))
	SELECT	@ToDate		=	(SELECT DATEADD( DAY,  1, @ToDate ))
END 

-- GET count Working Days per Agent till NOW
IF( object_id('tempdb..#tmp1')	is not null )					DROP table	#tmp1;
IF( object_id('tempdb..#tmp2')	is not null )					DROP table	#tmp2;
IF( object_id('tempdb..#tmp3')	is not null )					DROP table	#tmp3;
IF( object_id('tempdb..#tmp4')	is not null )					DROP table	#tmp4;
IF( object_id('tempdb..#tmp10') is not null )					DROP table	#tmp10;
IF( object_id('tempdb..#tmp11') is not null )					DROP table	#tmp11;
IF( object_id('tempdb..#tmp100') is not null )					DROP table	#tmp100;
IF( object_id('tempdb..#tmp110') is not null )					DROP table	#tmp110;
IF( object_id('tempdb..#NightAgentHours') is not null )			DROP table	#NightAgentHours;
IF( object_id('tempdb..#OnlyFlexHours') is not null )			DROP table	#OnlyFlexHours;
IF( object_id('tempdb..#FLEX_AND_DefaultHours') is not null )	DROP table	#FLEX_AND_DefaultHours;
IF( object_id('tempdb..#tmp120') is not null )					DROP table	#tmp120;
IF( object_id('tempdb..#tmp121') is not null )					DROP table	#tmp121;
IF( object_id('tempdb..#tmp122') is not null )					DROP table	#tmp122;
IF( object_id('tempdb..#HoliDays') is not null )				DROP table	#HoliDays;
IF( object_id('tempdb..#TotalWorkDays1') is not null )			DROP table	#TotalWorkDays1;
IF( object_id('tempdb..#TotalWorkDays2') is not null )			DROP table	#TotalWorkDays2;
IF( object_id('tempdb..#BreakSplitShift') is not null )			DROP table	#BreakSplitShift;
IF( object_id('tempdb..#tmp_Night_Shift_order') is not null )	DROP table	#tmp_Night_Shift_order;


	SELECT * 
	INTO #tmp1 
	FROM											-- select * from #tmp1 where EmployeeID = 2666
		(	select	DISTINCT count(*) AS PlannedWorkDays,	EmployeeID  
			from	(		SELECT  DISTINCT 
									( cast( [ShiftStartDate] as date) )	AS	StartDate
									 ,employee_id				AS	EmployeeID		
							FROM	[Dwh].[dbo].[F_PlannedData]
							WHERE 	1=1
							and		cast( [ShiftStartDate] as date) BETWEEN (SELECT DATEADD( DAY, 1, @FromDate ))	AND (SELECT DATEADD( DAY,  -1, @ToDate ))
							)T1 
			Group By EmployeeID
		)T2

 SELECT RegisterNumber,
		LastName,
		FirstName,
		FullName,
		InterimOffice,
		Organization,
		[Address],
		ZipCode,
		Residence,
		HireDate,
		E.PlannedWorkDays,
		[StartTime],
		[EndTime],
		ShiftStartDate,
		ShiftStartHour as ShiftStartHour,
		ShiftEndDate,
		ShiftEndHour as ShiftEndHour, 
		ScheduledPaidTime, 
		ScheduledAbsenceTime, 
		ScheduledPaidTime + ScheduledAbsenceTime	AS	ScheduledTotalTime, 
		ScheduledActivity, 
		SolvusActivityGroup,	
		IsAbsenceTime,
		StopDate,
		EmployeeLogin,
		E.EmployeeID,
		PERSON_ID,		
		ROW_NUMBER()  OVER( partition	by FullName order by StartTime )	AS	RegisterNumber_RowNr,
		ROW_NUMBER()  OVER( order		by FullName, StartTime )			AS	RowNr,
		isnull( IsHoliDay, 0)		AS	IsHoliDay,
		PerformanceCode,
		[Function],
		BreakSplitShift,
		EmploymentPlace,
		[type_shift],
		[contract_name],																														
		[contract_name_short],																													
		[contract_day_max],																														
		[contract_week_max],
		[timetype],
		[weekdayname],
		ishomeworking
   INTO	#tmp2	
   FROM	(
		  --  GET: F_PlannedEvent data
		  SELECT distinct                                       --Description: Stefan Damyanov 31.07.2023 remove duplicate records
		            --------------------------------------------------------(1)---------------------------------------------------------------------------------------------------- 
		            coalesce(FP.[StartTime],cast(FP.[ShiftStartDate] as datetime)) 																		       AS [StartTime],
                    --------------------------------------------------------(1)----------------------------------------------------------------------------------------------------  
					--------------------------------------------------------(2)----------------------------------------------------------------------------------------------------
		            coalesce(FP.[EndTime],cast(FP.[ShiftEndDate] as datetime))		       														               AS [EndTime],
                    --------------------------------------------------------(2)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(3)----------------------------------------------------------------------------------------------------
		            CAST(FP.[ShiftStartDate] as date)																			                               AS ShiftStartDate,
					--------------------------------------------------------(3)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(4)----------------------------------------------------------------------------------------------------
		            coalesce(FP.[ShiftStartHour],cast(FP.[ShiftStartDate] as datetime))																           AS ShiftStartHour,		
                    --------------------------------------------------------(4)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(5)---------------------------------------------------------------------------------------------------
		            CAST(FP.[ShiftEndDate] as date)                  																                           AS ShiftEndDate,	
					--------------------------------------------------------(5)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(6)----------------------------------------------------------------------------------------------------
		            coalesce(FP.[ShiftEndHour],cast(FP.[ShiftEndDate] as datetime))  															               AS ShiftEndHour,	
                    --------------------------------------------------------(6)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(7)----------------------------------------------------------------------------------------------------  										
					FP.ScheduledTime									                                                                                       AS ScheduledTime, 
                    --------------------------------------------------------(7)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(8)---------------------------------------------------------------------------------------------------- 
					FP.ScheduledPaidTime																													   AS ScheduledPaidTime,		
                    --------------------------------------------------------(8)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(9)----------------------------------------------------------------------------------------------------					
		            case when [official_name] = 'Feestdag' then 8
					     else FP.ScheduledAbsenceTime
					end                                                                                                                                       AS ScheduledAbsenceTime,	
                    --------------------------------------------------------(9)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(10)----------------------------------------------------------------------------------------------------
 					iif( FP.ishomeworking = 1 AND DA.[official_name] = 'Prestatie', 'Homeworking', DA.[Name] )									               AS ScheduledActivity,
					--------------------------------------------------------(10)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(11)----------------------------------------------------------------------------------------------------
					--(DA.[official_name])						                   AS SolvusActivityGroup,			
					iif( FP.ishomeworking = 1 AND DA.[official_name] = 'Prestatie', 'Homeworking', [official_name] )										   AS SolvusActivityGroup,		
					--------------------------------------------------------(11)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(12)----------------------------------------------------------------------------------------------------
					FP.[employee_id]																	                                                       AS EmployeeID,	
					--------------------------------------------------------(12)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(13)----------------------------------------------------------------------------------------------------
					isnull(FP.IsAbsence,0)															                                                           AS IsAbsenceTime,
					--------------------------------------------------------(13)---------------------------------------------------------------------------------------------------
					--------------------------------------------------------(14)----------------------------------------------------------------------------------------------------
					ISNULL([isbankholiday], 0)														 		                                                   AS IsHoliDay,
					--------------------------------------------------------(14)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(15)----------------------------------------------------------------------------------------------------
					--(DA.[official_name_short])                                      AS PerformanceCode,	
					iif( FP.ishomeworking = 1 AND DA.[official_name] = 'Prestatie', '1020' , DA.[official_name_short])										   AS PerformanceCode,	
					--------------------------------------------------------(15)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(16)----------------------------------------------------------------------------------------------------
					IIF(ISNULL([isbreaksplitshift], 0) = 0 , 'No', 'Yes')										                                               AS BreakSplitShift,					
					--------------------------------------------------------(16)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(17)----------------------------------------------------------------------------------------------------
					FP.[organization]																														   AS Organization,	 
					--------------------------------------------------------(17)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(18)----------------------------------------------------------------------------------------------------
					FP.InterimOffice																														   AS InterimOffice,		  
					--------------------------------------------------------(18)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(19)----------------------------------------------------------------------------------------------------
					FP.EmploymentPlace																														   AS EmploymentPlace,
					--------------------------------------------------------(19)----------------------------------------------------------------------------------------------------
					--------------------------------------------------------(20)----------------------------------------------------------------------------------------------------
					FP.[type_shift]																															   AS [type_shift],
					--------------------------------------------------------(20)----------------------------------------------------------------------------------------------------
					FP.[contract_name]																															AS [contract_name],
					FP.[contract_name_short]																													AS [contract_name_short],
					FP.[contract_day_max]																														AS [contract_day_max],
					FP.[contract_week_max]																														AS [contract_week_max],
					FP.[timetype] as timetype,
					FP.[weekdayname] as weekdayname,
					ISNULL(FP.[ishomeworking], 0) as ishomeworking

		    FROM [DwH].[dbo].[F_PlannedData] FP					
			  ------------------------------------------------------------(1)-----------------------------------------------------------------------------
		
			  LEFT JOIN [Dwh].[dbo].[D_PlannedActivity] DA ON FP.activity_id =  DA.activity_id
			  
			  --LEFT JOIN [Dwh].[dbo].[D_PlannedActivity] DA ON FP.activity_id =  DA.activity_id

			  ------------------------------------------------------------(1)-----------------------------------------------------------------------------			  
			  ------------------------------------------------------------(2)-----------------------------------------------------------------------------
			  -- MOVED TO D_PlannedData InterimOffice
              ------------------------------------------------------------(2)-----------------------------------------------------------------------------
			  -- MOVED TO D_PlannedData EmploymentPlace
			  ------------------------------------------------------------(3)-----------------------------------------------------------------------------
              ------------------------------------------------------------(3)-----------------------------------------------------------------------------					 
		   WHERE 1 = 1
		     ---------------------------------------------------------------------------------------------------------------------------------------------
			 --Description: Filters
			 --Description: Stefan Damyanov 18.07.2023 remove only paid flag   --AND		FP.Paid		=	1			 
			
		     AND cast( FP.[ShiftStartDate] as date) BETWEEN @FromDate AND @ToDate		-- @FromDate AND @ToDate 		     		
			 --AND fp.PlannedDataKey not in (11617,11618,11619,11620,13220,13221,13222,13223,11623,11624,13226,13227)	--- ??? WHAT IS THIS ?		 			
			 AND FP.employee_id	IN ( SELECT distinct DE.INJIXO_ID 
									   FROM	[Dwh].[dbo].[D_Employee] DE									
									  WHERE	1 = 1 
									    AND DE.ValidTo	IS NULL )
             ---------------------------------------------------------------------------------------------------------------------------------------------

		) P
	 JOIN	-- Employee attributes --
		( SELECT distinct 
		                  -------------------------------------------(1)------------------------------------------------------------------------------------
						  --Description: 
		                  isnull(DE.PERSONEL_NUMBER,'')			                            AS RegisterNumber,
						  -------------------------------------------(1)------------------------------------------------------------------------------------
						  -------------------------------------------(2)------------------------------------------------------------------------------------
						  --Description: 
					      [LastName]								                        AS LastName,
						  -------------------------------------------(2)------------------------------------------------------------------------------------
						  -------------------------------------------(3)------------------------------------------------------------------------------------
						  --Description: 
					      [FirstName]								                        AS FirstName,      
						  -------------------------------------------(3)------------------------------------------------------------------------------------
						  -------------------------------------------(4)------------------------------------------------------------------------------------
						  --Description: 
					      [LastName] + ', ' + 	[FirstName]			                        AS FullName,
						  -------------------------------------------(4)------------------------------------------------------------------------------------
						  -------------------------------------------(5)------------------------------------------------------------------------------------
						  -- InterimOffice MOVED TO D_plannedData
						  -------------------------------------------(5)------------------------------------------------------------------------------------
						  -------------------------------------------(6)------------------------------------------------------------------------------------
						  -- Organization MOVED to D_plannedData
						  -------------------------------------------(6)------------------------------------------------------------------------------------
						  -------------------------------------------(7)------------------------------------------------------------------------------------
						  --Description: 
					      [Address]			                                                AS [Address],
						  -------------------------------------------(7)------------------------------------------------------------------------------------
						  -------------------------------------------(8)------------------------------------------------------------------------------------
						  --Description: 
					      ZipCode		                                                    AS ZipCode, 
						  -------------------------------------------(8)------------------------------------------------------------------------------------
						  -------------------------------------------(9)------------------------------------------------------------------------------------
						  --Description: 
					      DE.City									                        AS Residence,
						  -------------------------------------------(9)------------------------------------------------------------------------------------
						  -------------------------------------------(10)------------------------------------------------------------------------------------
						  --Description: 
					      [StartDate]								                        AS HireDate,	  
						  -------------------------------------------(10)------------------------------------------------------------------------------------
						  -------------------------------------------(11)------------------------------------------------------------------------------------
						  --Description: 
					      T1.PlannedWorkDays						                        AS PlannedWorkDays,							
						  -------------------------------------------(11)------------------------------------------------------------------------------------
						  -------------------------------------------(12)------------------------------------------------------------------------------------
						  --Description: 
					      isnull([EndDate],'2099-12-31')			                        AS StopDate,				
						  -------------------------------------------(12)------------------------------------------------------------------------------------
						  -------------------------------------------(13)------------------------------------------------------------------------------------
						  --Description: --- Fahad: extracting EmployeeLogin from email ID instead of joining firstname and last name
					      SUBSTRING(DE.[EMAIL], 0, charindex('@', DE.[EMAIL], 0))           AS EmployeeLogin,				  
						  -------------------------------------------(13)------------------------------------------------------------------------------------
						  -------------------------------------------(14)------------------------------------------------------------------------------------
						  --Description: 
					      DE.INJIXO_ID							                            AS EmployeeID,		
						  -------------------------------------------(14)------------------------------------------------------------------------------------
						  -------------------------------------------(15)------------------------------------------------------------------------------------
						  --Description: --- employee id is taken as PERSON_ID
					      INJIXO_ID								                            AS PERSON_ID,                    
						  -------------------------------------------(15)------------------------------------------------------------------------------------
						  -------------------------------------------(16)------------------------------------------------------------------------------------
						  --Description: 
					      DateDiff(dd, DE.[StartDate], isnull(DE.[EndDate], GetDate()) )    AS PassedDays,						
						  -------------------------------------------(16)------------------------------------------------------------------------------------
						  -------------------------------------------(17)------------------------------------------------------------------------------------
						  --Description: --- MISO add position from D_Employee 
					      DE.Position                                                       AS [Function]				
						  -------------------------------------------(17)------------------------------------------------------------------------------------
			FROM [DwH].dbo.D_Employee DE	
			  ------------------------------------(1)--------------------------------------------------
			  ------------------------------------(2)--------------------------------------------------			 
			  -- GET working days
		      LEFT JOIN	#tmp1		T1 
	   	        ON DE.INJIXO_ID	=   T1.EmployeeID	
		      ------------------------------------(5)--------------------------------------------------
		   WHERE 1=1 
		     ---------------------------(1)---------------------------------------------------------------
			 --Description: -- only take current rows for backwards compatibility
		     AND DE.ValidTo IS NULL 				      			 
			 ---------------------------(1)---------------------------------------------------------------
		   ) E
	   ON P.EmployeeID = E.EmployeeID	
	WHERE 1=1
	  AND isnull(StopDate, '2099-01-01')	>	@FromDate						                         --take users with StopDate > @FromDate				-- 2017-07-11	  


   DELETE FROM #tmp2 WHERE ScheduledActivity = 'Lunch' -- LUNCH


   DELETE FROM #tmp2 WHERE ScheduledActivity = 'Unavailable/Off' -- Unavailable/Off
   ----------------------------------------------------------------------------------------

	SELECT 
		--RegisterNumber, FirstName, StartTime, EndTime
		*
		,0				AS  Gr			--importand, neede to make groupings with update
		,     IsNull( DateDiff( MINUTE, LAG( EndTime ) OVER ( PARTITION BY EmployeeID ORDER BY RowNr ASC ) , StartTime ) , 0)					AS	NewShiftTime	--
		,iif( IsNull( DateDiff( MINUTE, LAG( EndTime ) OVER ( PARTITION BY EmployeeID ORDER BY RowNr ASC ) , StartTime ) , 0) > 240 , 1, 0) 	AS	NewShift		--
		,DATEDIFF( DAY, ShiftStartDate, ShiftEndDate )																							AS	DaysDiff 	
		
	INTO		#tmp10		--	drop table #tmp10  -- select * from #tmp10 where	FirstName  = 'Andy'
	FROM		#tmp2		--	select * from #tmp2
	ORDER BY	StartTime, FirstName 
	


	declare		@i int=0;	
	;WITH	q AS (
				SELECT		TOP 1000000 *
				FROM		#tmp10
				ORDER BY	RowNr
				)            
	UPDATE  q
	set @i = Gr = Case when NewShift = 1 then @i + 1  else @i end



   IF( object_id('tempdb..#NightShift')	is not null )					DROP table	#NightShift;

   create table #NightShift (date_key NVARCHAR(8), 
                             employee_id NVARCHAR(maX), 
							 type_shift nvarchar(5));

   INSERT INTO #NightShift (date_key,employee_id,type_shift)
   SELECT DISTINCT datekey, employee_id, type_shift FROM [dbo].[F_PlannedData]


    select distinct df.* 
      INTO #tmp11		
     from(( select T1.*, 
				   T2.FirstStartTime, 
				   T3.LastEndTime, 
				   convert(varchar(8), T2.FirstStartTime, 108) 	AS	FirstStartHour,
				   convert(varchar(8), T3.LastEndTime, 108)		AS	LastEndHour, 																	
				   convert(varchar(8), T2.FirstStartTime, 108) + ' - ' + convert(varchar(8), T3.LastEndTime, 108)	AS	'Day_FirstLastHour',
				   'LN' as NightShift
			   FROM #tmp10	T1   		
			-- GET FirstStartTime
			   left join ( select min(coalesce(StartTime,ShiftStartDate)) AS FirstStartTime, 
								  EmployeeID,	
								  Gr, 
								  cast(coalesce(StartTime,ShiftStartDate) as date) AS SD  
							 from #tmp10 
                            where 1 = 1
						      --and PERSON_ID = 1001
							group by EmployeeID, 
									 Gr, 
									 cast( coalesce(StartTime,ShiftStartDate) as date) )	T2
				 on	(T1.EmployeeID = T2.EmployeeID
					 and T1.Gr = T2.Gr		
					 and cast( coalesce(t1.StartTime,t1.ShiftStartDate) as date) =	T2.SD )
			   -- GET FirstStartTime	
 			   -- GET LastEndTime	
			   left join	( select max(coalesce(EndTime,ShiftEndDate)) AS LastEndTime, 
									 EmployeeID,	
									 Gr, 
									 cast( coalesce(EndTime,ShiftEndDate) as date) AS SD	
								from #tmp10 
							   where 1 = 1
						         --and PERSON_ID = 1001
							   group by EmployeeID, 
										Gr, 
										cast( coalesce(EndTime,ShiftEndDate) as date) )	T3
				 on	(T1.EmployeeID = T3.EmployeeID
					 and T1.Gr = T3.Gr
					 and cast(coalesce(t1.EndTime,t1.ShiftEndDate) as date) =	T3.SD)
               ------------------------------------------------------------------
			   --Description: Stefan Damyanov, 22-Aug-2023, add join instead of inline SQL 
			   LEFT JOIN (select d.employee_id,
			                     d.date_key
			                from #NightShift d
						   where 1 = 1
						     --and d.employee_id = 1001
						     and d.type_shift = 'LN') d_LN
                 ON (t1.EmployeeID = d_LN.employee_id
				     and t1.ShiftStartDate = d_LN.date_key)
			   ------------------------------------------------------------------	
		     where 1 = 1
			   and ((T1.SolvusActivityGroup not in ('Feestdag')
			        and isnull(convert(varchar(8), T3.LastEndTime, 108),'23:59:59') not in ('23:30:00')
			        and isnull(convert(varchar(8), T2.FirstStartTime, 108),'23:59:59') not in ('00:00:00'))
                   or 
				   (T1.SolvusActivityGroup in ('Feestdag')
			        and isnull(convert(varchar(8), T3.LastEndTime, 108),'23:59:59') in ('00:00:00')
			        and isnull(convert(varchar(8), T2.FirstStartTime, 108),'23:59:59') in ('00:00:00')))
			   --and PERSON_ID = 1001
            --order by 14 desc
          ) 
	     union 
	      ( select T1_b.*, 
				   T2.FirstStartTime, 
				   T3.LastEndTime, 
				   convert(varchar(8), T2.FirstStartTime, 108) 	AS	FirstStartHour,
				   convert(varchar(8), T3.LastEndTime, 108)		AS	LastEndHour, 																	
				   convert(varchar(8), T2.FirstStartTime, 108) + ' - ' + convert(varchar(8), T3.LastEndTime, 108)	AS	'Day_FirstLastHour',
				   'NLN' as NightShift 				            
			   FROM #tmp10	T1_b					  
			   -- GET FirstStartTime
			   left join ( select min(coalesce(StartTime,ShiftStartDate)) AS FirstStartTime, 
								  EmployeeID,	
								  Gr
							 from #tmp10 sd
							inner join #NightShift t2_b
			                   on sd.EmployeeID = t2_b.employee_id				                  
                            where 1 = 1
							  and cast( coalesce(sd.StartTime,sd.ShiftStartDate) as date) between dateadd(day,-1,cast( T2_b.date_key as date)) and dateadd(day,1,cast( t2_b.date_key as date))
							  and t2_b.type_shift = 'NLN'
							group by EmployeeID, 
									 Gr )	T2
				 on	(T1_b.EmployeeID = T2.EmployeeID
					 and T1_b.Gr = T2.Gr )
			   -- GET FirstStartTime	
 			   -- GET LastEndTime	
			   left join	( select max(coalesce(EndTime,ShiftEndDate)) AS LastEndTime, 
									 EmployeeID,	
									 Gr
								from #tmp10 sd_b
							   inner join #NightShift t2_b
			                     on sd_b.EmployeeID = t2_b.employee_id				                  
                              where 1 = 1
							    and cast( coalesce(sd_b.EndTime,sd_b.ShiftEndDate) as date) between cast( T2_b.date_key as date) and dateadd(day,1,cast( t2_b.date_key as date))
								and t2_b.type_shift = 'NLN'
							  group by EmployeeID, 
										Gr )	T3
				 on	(T1_b.EmployeeID = T3.EmployeeID
					 and T1_b.Gr = T3.Gr)
               -- GET LastEndTime	
			 where 1 = 1
			   and ((T1_b.SolvusActivityGroup not in ('Feestdag')
			        and isnull(convert(varchar(8), T3.LastEndTime, 108),'23:59:59') not in ('23:30:00')
			        and isnull(convert(varchar(8), T2.FirstStartTime, 108),'23:59:59') not in ('00:00:00'))
                   or 
				   (T1_b.SolvusActivityGroup in ('Feestdag')
			        and isnull(convert(varchar(8), T3.LastEndTime, 108),'23:59:59') in ('00:00:00')
			        and isnull(convert(varchar(8), T2.FirstStartTime, 108),'23:59:59') in ('00:00:00')))
			   --and PERSON_ID = 1001
			   and t1_b.EmployeeID in (select b.employee_id 
			                             from #NightShift b
									    where 1 = 1
									      and b.type_shift = 'NLN'
										  /*and b.date_key = ShiftStartDate*/)
          )) df
	   order by	df.StartTime

---- TEMP 11 TEST START

--- TEMP 11 TEST 1
select distinct df.* 
      INTO #tmp11_TEST1		
     from(( select T1.*, 
				   T2.FirstStartTime, 
				   T3.LastEndTime, 
				   convert(varchar(8), T2.FirstStartTime, 108) 	AS	FirstStartHour,
				   convert(varchar(8), T3.LastEndTime, 108)		AS	LastEndHour, 																	
				   convert(varchar(8), T2.FirstStartTime, 108) + ' - ' + convert(varchar(8), T3.LastEndTime, 108)	AS	'Day_FirstLastHour',
				   'LN' as NightShift
			   FROM #tmp10	T1   		
			-- GET FirstStartTime
			   left join ( select min(coalesce(StartTime,ShiftStartDate)) AS FirstStartTime, 
								  EmployeeID,	
								  Gr, 
								  cast(coalesce(StartTime,ShiftStartDate) as date) AS SD  
							 from #tmp10 
                            where 1 = 1
						      --and PERSON_ID = 1001
							group by EmployeeID, 
									 Gr, 
									 cast( coalesce(StartTime,ShiftStartDate) as date) )	T2
				 on	(T1.EmployeeID = T2.EmployeeID
					 and T1.Gr = T2.Gr		
					 and cast( coalesce(t1.StartTime,t1.ShiftStartDate) as date) =	T2.SD )
			   -- GET FirstStartTime	
 			   -- GET LastEndTime	
			   left join	( select max(coalesce(EndTime,ShiftEndDate)) AS LastEndTime, 
									 EmployeeID,	
									 Gr, 
									 cast( coalesce(EndTime,ShiftEndDate) as date) AS SD	
								from #tmp10 
							   where 1 = 1
						         --and PERSON_ID = 1001
							   group by EmployeeID, 
										Gr, 
										cast( coalesce(EndTime,ShiftEndDate) as date) )	T3
				 on	(T1.EmployeeID = T3.EmployeeID
					 and T1.Gr = T3.Gr
					 and cast(coalesce(t1.EndTime,t1.ShiftEndDate) as date) =	T3.SD)
               ------------------------------------------------------------------
			   --Description: Stefan Damyanov, 22-Aug-2023, add join instead of inline SQL 
			   LEFT JOIN (select d.employee_id,
			                     d.date_key
			                from #NightShift d
						   where 1 = 1
						     --and d.employee_id = 1001
						     and d.type_shift = 'LN') d_LN
                 ON (t1.EmployeeID = d_LN.employee_id
				     and t1.ShiftStartDate = d_LN.date_key)
			   ------------------------------------------------------------------	
		     where 1 = 1
			   and ((T1.SolvusActivityGroup not in ('Feestdag')
			        and isnull(convert(varchar(8), T3.LastEndTime, 108),'23:59:59') not in ('23:30:00')
			        and isnull(convert(varchar(8), T2.FirstStartTime, 108),'23:59:59') not in ('00:00:00'))
                   or 
				   (T1.SolvusActivityGroup in ('Feestdag')
			        and isnull(convert(varchar(8), T3.LastEndTime, 108),'23:59:59') in ('00:00:00')
			        and isnull(convert(varchar(8), T2.FirstStartTime, 108),'23:59:59') in ('00:00:00')))
			   --and PERSON_ID = 1001
            --order by 14 desc
          ) 
	) df
	   order by	df.StartTime
--- TEMP 11 TEST 2

--- TEMP 12 TEST 3

---- TEMP 11 TEST STOP

DELETE FROM #tmp11
   WHERE 1 = 1
     AND NightShift = 'LN'
	 AND EmployeeID in (select b.employee_id 
			              from #NightShift b
					     where 1 = 1
					   	   and b.type_shift = 'NLN');


SELECT d.* 
  into #tmp_Night_Shift_order
  FROM (select '16:00:01' as Hour_Start, 
			   '17:00:00' as Hour_End,
			   1 as Shift_Order
		union
		select '17:00:01' as Hour_Start, 
			   '18:00:00' as Hour_End,
			   2 as Shift_Order
		union
		select '18:00:01' as Hour_Start, 
			   '19:00:00' as Hour_End,
			   3 as Shift_Order
		union
		select '19:00:01' as Hour_Start, 
			   '20:00:00' as Hour_End,
			   4 as Shift_Order
		union
		select '20:00:01' as Hour_Start, 
			   '21:00:00' as Hour_End,
			   5 as Shift_Order
		union
		select '21:00:01' as Hour_Start, 
			   '22:00:00' as Hour_End,
			   6 as Shift_Order
		union
		select '22:00:01' as Hour_Start, 
			   '23:00:00' as Hour_End,
			   7 as Shift_Order
		union
		select '23:00:01' as Hour_Start, 
			   '00:00:00' as Hour_End,
			   8 as Shift_Order
		union
		select '00:00:01' as Hour_Start, 
			   '01:00:00' as Hour_End,
			   9 as Shift_Order
		union
		select '01:00:01' as Hour_Start, 
			   '02:00:00' as Hour_End,
			   10 as Shift_Order
		union
		select '02:00:01' as Hour_Start, 
			   '03:00:00' as Hour_End,
			   11 as Shift_Order
		union
		select '03:00:01' as Hour_Start, 
			   '04:00:00' as Hour_End,
			   12 as Shift_Order
		union
		select '04:00:01' as Hour_Start, 
			   '05:00:00' as Hour_End,
			   13 as Shift_Order
		union
		select '05:00:01' as Hour_Start, 
			   '06:00:00' as Hour_End,
			   14 as Shift_Order
		union
		select '06:00:01' as Hour_Start, 
			   '07:00:01' as Hour_End,
			   15 as Shift_Order
		union
		select '07:00:01' as Hour_Start, 
			   '08:00:01' as Hour_End,
			   16 as Shift_Order
		union
		select '08:00:01' as Hour_Start, 
			   '09:00:00' as Hour_End,
			   17 as Shift_Order
		union
		select '09:00:01' as Hour_Start, 
			   '10:00:00' as Hour_End,
			   18 as Shift_Order
		union
		select '10:00:01' as Hour_Start, 
			   '11:00:00' as Hour_End,
			   19 as Shift_Order
		union
		select '11:00:01' as Hour_Start, 
			   '12:00:00' as Hour_End,
			   20 as Shift_Order
		union
		select '12:00:01' as Hour_Start, 
			   '13:00:00' as Hour_End,
			   21 as Shift_Order
		union
		select '13:00:01' as Hour_Start, 
			   '14:00:00' as Hour_End,
			   22 as Shift_Order
		union
		select '14:00:01' as Hour_Start, 
			   '15:00:00' as Hour_End,
			   23 as Shift_Order
		union
		select '15:00:01' as Hour_Start, 
			   '16:00:00' as Hour_End,
			   24 as Shift_Order) d

	Select  *
	INTO	#tmp100	
	FROM	#tmp11


	DELETE
	FROM		#tmp100
	WHERE		cast( FirstStartTime as date) =	@FromDate  --'2017-09-03' -- 
	

	DELETE
	FROM		#tmp100		--	select * from #tmp100
	WHERE		1=1
	AND			ShiftStartDate					BETWEEN		DATEADD(day, -1, @ToDate )	AND		@ToDate		-->		@ToDate -1	AND		@ToDate		--> take only last two days 
	AND			cast( FirstStartTime as date)	<>			DATEADD(day, -1, @ToDate )						-->		@ToDate -1;	take only the first day of the last two days
	AND			ShiftEndDate					<>			DATEADD(day, -1, @ToDate )						-->		@ToDate   -1	do not take with


SELECT *,	

	IIF(	ShiftStartHour < '20:00:00'	AND	ShiftEndHour > '00:00:00'	-- overlapping of times
			AND		DATENAME(dw, ShiftStartDate)	IN('Saturday') 
			AND		IsHoliDay <> 1
			,DATEDIFF(second,	cast( StartTime as time),															-- From
								IIF( cast( EndTime   as time) > '20:00:00', '20:00:00',  cast( EndTime  as time) )	-- To
							)/ 3600.000000   , 0)															AS FlexSaturdayHours							

	,IIF(	ShiftStartHour < '22:00:00'	AND	ShiftEndHour > '20:00:00'	-- overlapping of times
			AND		DATENAME(dw, ShiftStartDate)	IN('Saturday')    	-- is Saturday
			AND		IsHoliDay <> 1
			,DATEDIFF (second, 
							 IIF( ShiftStartHour <= '20:00:00'    , '20:00:00', ShiftStartHour ),											-- From
							 IIF( ShiftEndDate   >  ShiftStartDate, '20:00:00',	IIF(ShiftEndHour >= '22:00:00', '22:00:00', ShiftEndHour ))	-- To													-- 
					  ) / 3600.000000   , 0)																	AS FlexEveningSaturdayHours

	,IIF(	ShiftStartHour < '23:59:59'	AND	ShiftEndHour > '22:00:00'	-- overlapping of times
			AND		DATENAME(dw, ShiftStartDate)	IN('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday','Saturday') 
			AND		IsHoliDay <> 1
			,DATEDIFF(second, 
							IIF( cast( StartTime as time) < '22:00:00', '22:00:00', cast( StartTime as time) ),		--	From 
							IIF( cast( EndTime  as time)  < '23:59:59', cast( EndTime  as time), '23:59:59'   )		--	To										
						) / 3600.000000   , 0)															AS FlexEveningWorkSaturdayHours

--			ShiftStartHour <  ToTime		ShiftEndHour >	FromTime	-- overlapping of times
	,IIF(	ShiftStartHour < '22:00:00'	AND	ShiftEndHour > '20:00:00'	-- overlapping of times
			AND		DATENAME(dw, ShiftStartDate)	IN('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
			AND		IsHoliDay <> 1			
			,DATEDIFF(second , iif( cast( StartTime as time) < '20:00:00', '20:00:00',	cast( StartTime as time)	)
									, iif( cast( EndTime  as time)  > '21:59:59', '22:00:00',	cast( EndTime   as time)	)					
							) / 3600.000000   , 0)															AS FlexEveningWorkDayHours
--	---------------------------------------------------------------------------------------------------------------
--	--	 FlexSundayHours			=	 IF Sun 
	,IIF(	DATENAME(dw, ShiftStartDate)	IN('Sunday')
			--AND		IsHoliDay <> 1
			,
			(	DATEDIFF(second, StartTime,		--	From 
								 EndTime		--  To
						) / 3600.000000   ), 0)																AS FlexSundayHours
								
--	---------------------------------------------------------------------------------------------------------------

   ,IIF( IsHoliDay = 1 AND SolvusActivityGroup IN ( 'Prestatie' , 'Homeworking' , 'Opleiding met BEV' ) ,
				(	DATEDIFF(second, StartTime,		--	From 
									 EndTime		--  To
							) / 3600.000000   ), 0)															AS FlexHoliDayHours
--	---------------------------------------------------------------------------------------------------------------							

	INTO	#tmp110		-- contains all recores min NightAgents -- WITH FLEX
	FROM	#tmp100	T1	-- contains all records				
	WHERE	T1.[TimeType] <> 'NightAgent'	--Do Not Calculte Flex Hours for Night Agents
--	---------------------------------------------------------------------------------------------------------------

--	STEP30: Calculate NightAgent for Night Agents Only
	SELECT	*,  DATEDIFF(minute , StartTime , EndTime) / 60.00  AS NightAgentHours	--Description: Stefan Damyanov, 28.07.2023  - typo in the name
	INTO	#NightAgentHours			--60			-- drop table #NightAgentHours  Select * from #NightAgentHours
	FROM	#tmp100 where [TimeType] = 'NightAgent' 

--	STEP31: Calculate DefaultHours = work hours for all the rest ( ALL h minus Flex h minus Night h )
	SELECT	*,	
				-- Goal: #tmp110 min FLEX
				ScheduledTotalTime	 
						-   isnull(FlexSaturdayHours + FlexEveningSaturdayHours + FlexEveningWorkSaturdayHours + FlexEveningWorkDayHours + FlexSundayHours+FlexHoliDayHours, 0)
							AS	DefaultHours	
			
	INTO		#FLEX_AND_DefaultHours		--6443			-- drop table #FLEX_AND_DefaultHours	-- select * from #FLEX_AND_DefaultHours
	FROM		#tmp110										-- select * from #tmp110	
	WHERE		1=1
	 
SELECT * 
  INTO	#tmp120		
  FROM ( SELECT	RegisterNumber,	
                LastName,	
				FirstName,	
				FullName,	
				InterimOffice,	
				Organization,	
				[Address],	
				ZipCode,	
				Residence,	
				HireDate,	
				PlannedWorkDays, 
				StartTime, 
				EndTime, 
	            CAST( FirstStartTime as date) AS ShiftStartDate,	--Description: change by Stefan Damyanov 17-Aug-2023	
				--ShiftStartDate,
	            ShiftStartHour,			
				ShiftEndDate,		
				ShiftEndHour,
				ScheduledPaidTime,	
				ScheduledAbsenceTime,	
				ScheduledTotalTime as ScheduledTotalTime,		 
				ScheduledActivity,	
				SolvusActivityGroup,	
	            IsAbsenceTime,			
				StopDate,			
				EmployeeLogin,	
				EmployeeID,			
				PERSON_ID,				
				RegisterNumber_RowNr,	
				RowNr, 
	            NULL AS 'IsHoliDay',	
				PerformanceCode,	
				[Function],		
				BreakSplitShift,	
	            EmploymentPlace,
	            Gr,						
				NewShiftTime,		
				NewShift,		
				DaysDiff,	
	            FirstStartTime,			
				LastEndTime,		
				FirstStartHour,	
				LastEndHour,		
				Day_FirstLastHour,		
				TimeType,				
				WeekDayName,	
	            NULL AS FlexSaturdayHours,			
				NULL AS FlexEveningSaturdayHours,	
				NULL AS FlexEveningWorkSaturdayHours, 
	            NULL AS FlexEveningWorkDayHours,	
				NULL AS FlexSundayHours,			
				NULL AS FlexHoliDayHours, 
				NULL AS DefaultHours,
	            NightAgentHours                
	       FROM	#NightAgentHours	
	     UNION 		
	      SELECT c.RegisterNumber,	
                 c.LastName,	
				 c.FirstName,	
				 c.FullName,	
				 c.InterimOffice,	
				 c.Organization,	
				 c.[Address],	
				 c.ZipCode,	
				 c.Residence,	
				 c.HireDate,	
				 c.PlannedWorkDays, 
				 c.StartTime, 
				 c.EndTime, 
	             CAST( c.FirstStartTime as date) AS ShiftStartDate,	--Description: change by Stefan Damyanov 17-Aug-2023					
	             c.ShiftStartHour,			
				 c.ShiftEndDate,		
				 c.ShiftEndHour,
				 c.ScheduledPaidTime,	
				 c.ScheduledAbsenceTime,	
				 c.ScheduledTotalTime as ScheduledTotalTime,		
				 c.ScheduledActivity,	
				 c.SolvusActivityGroup,	
	             c.IsAbsenceTime,			
				 c.StopDate,			
				 c.EmployeeLogin,	
				 c.EmployeeID,			
				 c.PERSON_ID,				
				 c.RegisterNumber_RowNr,	
				 c.RowNr, 
	             c.IsHoliDay,	
				 c.PerformanceCode,	
				 c.[Function],		
				 c.BreakSplitShift,	
	             c.EmploymentPlace,
	             c.Gr,						
				 c.NewShiftTime,		
				 c.NewShift,		
				 c.DaysDiff,	
	             c.FirstStartTime,			
				 c.LastEndTime,		
				 c.FirstStartHour,	
				 c.LastEndHour,		
				 c.Day_FirstLastHour,		
				 c.TimeType,				
				 c.WeekDayName,	
	             c.FlexSaturdayHours,			
				 c.FlexEveningSaturdayHours,	
				 c.FlexEveningWorkSaturdayHours, 
	             c.FlexEveningWorkDayHours,	
				 c.FlexSundayHours,			
				 c.FlexHoliDayHours, 
				 c.DefaultHours, 
		         NULL AS  NightAgentHours 
	       FROM	#FLEX_AND_DefaultHours c) T1	;
	
with get_dates_with_sick_codes as ( select distinct dd.PERSON_ID,
										   hd.FullDate,
										   dd.start_month,
										   dd.end_month
									  from D_Date hd
									 inner join ( select d.PERSON_ID,									                     
	  													 max(d.ShiftStartDate) as end_month,
														 min(DATEADD(mm, DATEDIFF(m,0,d.ShiftStartDate),0)) as start_month
													from #tmp120 d 
												   where 1 = 1
													 and d.PerformanceCode in (4503,3523)
												   group by d.PERSON_ID ) dd
										on hd.FullDate between dd.start_month and dd.end_month),
     get_plan_data_for_sick_per_perdon_id as (select distinct d.RegisterNumber,
																d.LastName,
																d.FirstName,
																d.FullName,
																d.InterimOffice,
																d.Organization,
																d.[Address],
																d.ZipCode,
																d.Residence,
																d.HireDate,
																d.PlannedWorkDays,
																null as StartTime,
																null as EndTime,
																null as ShiftStartDate,
																null as ShiftStartHour,
																null as ShiftEndDate,
																null as ShiftEndHour,
																0 as ScheduledPaidTime,
																0 as ScheduledAbsenceTime,
																0 as ScheduledTotalTime,
																d.ScheduledActivity,
																d.SolvusActivityGroup,
																d.IsAbsenceTime,
																d.StopDate,
																d.EmployeeLogin,
																d.EmployeeID,
																d.PERSON_ID,
																1 as RegisterNumber_RowNr,
																1 as RowNr,
																0 as IsHoliDay,     -- calc when get holiday 
																d.PerformanceCode,
																d.[Function],
																d.BreakSplitShift,
																d.EmploymentPlace,
																1 as Gr,
																0 as NewShiftTime,
																0 as NewShift,
																0 as DaysDiff,
																null as FirstStartTime,
																null as LastEndTime,
																null as FirstStartHour,
																null as LastEndHour,
																null as Day_FirstLastHour,
																d.TimeType,
																null as WeekDayName,  -- calc when get date
																0 as FlexSaturdayHours,
																0 as FlexEveningSaturdayHours,
																0 as FlexEveningWorkSaturdayHours,
																0 as FlexEveningWorkDayHours,
																0 as FlexSundayHours,
																0 as FlexHoliDayHours,
																0 as DefaultHours,
																0 as NightAgentHours
														from #tmp120 d 
														where 1 = 1
															and d.PerformanceCode in (4503,3523))
  select distinct sp.RegisterNumber,
				 sp.LastName,
				 sp.FirstName,
				 sp.FullName,
				 sp.InterimOffice,
				 sp.Organization,
				 sp.[Address],
				 sp.ZipCode,
				 sp.Residence,
				 sp.HireDate,
				 sp.PlannedWorkDays,
				 concat(sc.FullDate,' 08:00:00') as StartTime,
				 concat(sc.FullDate,' 16:30:00') as EndTime,
				 sc.FullDate as ShiftStartDate,
				 '08:00:00' as ShiftStartHour,
				 sc.FullDate as ShiftEndDate,
				 '16:30:00' as ShiftEndHour,
				 sp.ScheduledPaidTime,
				 sp.ScheduledAbsenceTime,
				 sp.ScheduledTotalTime,
				 case when sp.PERSON_ID in (1030) then max(sp.ScheduledActivity) over(partition by sp.PERSON_ID)
				      else min(sp.ScheduledActivity) over(partition by sp.PERSON_ID) 
				 end as ScheduledActivity,
				 case when sp.PERSON_ID in (1030) then max(sp.SolvusActivityGroup) over(partition by sp.PERSON_ID)
				      else min(sp.SolvusActivityGroup) over(partition by sp.PERSON_ID)
				 end as SolvusActivityGroup,
				 sp.IsAbsenceTime,
				 sp.StopDate,
				 sp.EmployeeLogin,
				 sp.EmployeeID,
				 sp.PERSON_ID,
				 sp.RegisterNumber_RowNr,
				 sp.RowNr,
				 sp.IsHoliDay,
				 case when sp.PERSON_ID in (1030) then min(sp.PerformanceCode) over(partition by sp.PERSON_ID) 
				      else max(sp.PerformanceCode) over(partition by sp.PERSON_ID) 
				 end as PerformanceCode,
				 sp.[Function],
				 sp.BreakSplitShift,
				 sp.EmploymentPlace,
				 sp.Gr,
				 sp.NewShiftTime,
				 sp.NewShift,
				 sp.DaysDiff,
				 sp.FirstStartTime,
				 sp.LastEndTime,
				 sp.FirstStartHour,
				 sp.LastEndHour,
				 '08:00:00 - 16:30:00' as Day_FirstLastHour,
				 sp.TimeType,
				 datename(weekday,sc.FullDate) as WeekDayName,
				 sp.FlexSaturdayHours,
				 sp.FlexEveningSaturdayHours,
				 sp.FlexEveningWorkSaturdayHours,
				 sp.FlexEveningWorkDayHours,
				 sp.FlexSundayHours,
				 sp.FlexHoliDayHours,
				 sp.DefaultHours,
				 sp.NightAgentHours
    into #missing_sick_dates
    from get_dates_with_sick_codes sc
    left join #tmp120 dad
      on sc.PERSON_ID = dad.PERSON_ID
	     and sc.FullDate = dad.ShiftStartDate
		 and dad.PerformanceCode in (4503,3523)
   inner join get_plan_data_for_sick_per_perdon_id sp
	  on sc.PERSON_ID = sp.PERSON_ID
   where 1 = 1
     and dad.PERSON_ID is null 	 
   order by 1,
            2 desc


insert into #tmp120
select * 
  from #missing_sick_dates 

DECLARE @PERSON_ID_curr VARCHAR(50)

DECLARE db_cursor CURSOR FOR 
select distinct d.PERSON_ID as PERSON_ID_curr
	from #tmp120 d 
	where 1 = 1
		and d.PerformanceCode in (4503,3523)
		and d.PERSON_ID not in (1239,1248,1258)

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @PERSON_ID_curr  

WHILE @@FETCH_STATUS = 0  
BEGIN  
   

with exists_2_codes as (select distinct sub_d.ShiftStartDate as ShiftStartDate
                          from (select d.ShiftStartDate,
									   d.PERSON_ID,
									   d.PerformanceCode,
									   sum(d.ScheduledTotalTime) as TotalTime,
									   d.weekdayname,
									   row_number() over(partition by d.ShiftStartDate, d.PERSON_ID order by d.PerformanceCode desc) as cnt_rw
								  from  #tmp120 d
								 where 1 = 1
								   and d.person_id = @PERSON_ID_curr
								   and d.weekdayname not in ('Saturday','Sunday')
								 group by d.ShiftStartDate,
										  d.PERSON_ID,
										  d.PerformanceCode,
										  d.weekdayname) sub_d
                         where 1 = 1
						   and sub_d.cnt_rw = 2)
merge into #tmp120 m_d
using (
  select distinct d2.ShiftStartDate,
		 d2.PERSON_ID,
		 d2.PerformanceCode,
		 case when d2.PERSON_ID = 1174 and d2.ShiftStartDate = '20231103' then 0
		      when d2.PERSON_ID = 1174 and d2.ShiftStartDate = '20231117' then 0
			  when d2.PERSON_ID = 1174 and d2.ShiftStartDate = '20231124' then 0
			  when d2.PERSON_ID = 1174 and d2.ShiftStartDate = '20231201' then 0
			  when d2.PERSON_ID = 1174 and d2.ShiftStartDate = '20231215' then 0
			  when d2.PERSON_ID = 1174 and d2.ShiftStartDate = '20231229' then 0
			  when d2.PERSON_ID = 1174 and d2.ShiftStartDate = '20240311' then 0
			  when d2.PERSON_ID = 1174 and d2.ShiftStartDate = '20240314' then 0
			  when d2.PERSON_ID = 1308 and d2.ShiftStartDate = '20231117' then 0
		      when d2.ScheduledTotalTime = 0 and [ScheduledActivity] <> 'Off Day' then 8
		      else d2.ScheduledTotalTime
	     end as TotalTime,
		 d2.weekdayname
    from  #tmp120 d2
   where 1 = 1	 
     and d2.PERSON_ID = @PERSON_ID_curr
	 and d2.weekdayname not in ('Saturday','Sunday')
	 and not exists (select 1 
	                   from exists_2_codes df
					  where 1 = 1
					    and d2.ShiftStartDate = df.ShiftStartDate)) f_d
  on 1 = 1 
     and m_d.ShiftStartDate = f_d.ShiftStartDate 
	 and m_d.PERSON_ID = f_d.PERSON_ID 
	 and m_d.PerformanceCode = f_d.PerformanceCode 
	 and m_d.PerformanceCode in (4503,3523)
 when matched then update 
      set m_d.ScheduledTotalTime = f_d.TotalTime;

      FETCH NEXT FROM db_cursor INTO @PERSON_ID_curr 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor


DELETE FROM #tmp120 WHERE [ScheduledActivity] = 'Off Day' --Off Day


UPDATE	#tmp120
SET		DefaultHours	=	0.000000
WHERE	DefaultHours	<   0.0001
OR		DefaultHours	is null

UPDATE	#tmp120
SET		FlexSaturdayHours	=	0.000000
WHERE	FlexSaturdayHours	<   0.0001
OR		FlexSaturdayHours	is null

UPDATE	#tmp120
SET		FlexEveningSaturdayHours	=	0.000000
WHERE	FlexEveningSaturdayHours	<   0.0001
OR		FlexEveningSaturdayHours	is null

UPDATE	#tmp120
SET		FlexEveningWorkSaturdayHours	=	0.000000
WHERE	FlexEveningWorkSaturdayHours	<   0.0001
OR		FlexEveningWorkSaturdayHours	is null

UPDATE	#tmp120
SET		FlexEveningWorkDayHours	=	0.000000
WHERE	FlexEveningWorkDayHours	<   0.0001
OR		FlexEveningWorkDayHours	is null

UPDATE	#tmp120
SET		FlexSundayHours	=	0.000000
WHERE	FlexSundayHours	<   0.0001
OR		FlexSundayHours	is null

UPDATE	#tmp120
SET		FlexHoliDayHours	=	0.000000
WHERE	FlexHoliDayHours	<   0.0001
OR		FlexHoliDayHours	is null

UPDATE	#tmp120
SET		NightAgentHours	=	0.000000    --Description: Stefan Damyanov, 28.07.2023  - typo in the name
WHERE	NightAgentHours	<   0.0001      --Description: Stefan Damyanov, 28.07.2023  - typo in the name
OR		NightAgentHours	is null         --Description: Stefan Damyanov, 28.07.2023  - typo in the name 


select		distinct EmployeeLogin, cast(FirstStartTime as date) FirstStart_Date
into		#TotalWorkDays1            
from		#tmp120				-- select * from #tmp120
where		SolvusActivityGroup = 'Prestatie'
and			EmployeeLogin <> ''

-----------------------------------------
select		EmployeeLogin, count(*)	AS TotalWorkDays			-- drop table #TotalWorkDays2
into		#TotalWorkDays2		--- select * from #TotalWorkDays2 where EmployeeLogin = 'aadam'
from		#TotalWorkDays1
group by	EmployeeLogin
order by	EmployeeLogin
------------------------------------------

SELECT	T1.*, T2.TotalWorkDays 
INTO		#tmp121					--#tmp121   : with TotalWorkDays
FROM		#tmp120			T1		-- select * from 	#tmp120	
LEFT JOIN	#TotalWorkDays2	T2
ON			T1.EmployeeLogin = T2.EmployeeLogin


	Select	*
	
	
								
	INTO	#tmp122		-- select * from #tmp122		--#tmp122   : with ShiftCoupé
		
	FROM	#tmp121	


-- Return Long list (all columns)
IF( object_id('tempdb..#Basis') is not null )		DROP table	#Basis;
IF( object_id('tempdb..#ReturnData2') is not null )	DROP table	#ReturnData2;
IF( object_id('tempdb..#ReturnData3') is not null )	DROP table	#ReturnData3;

	SELECT	

	RegisterNumber,	LastName,	FirstName,	FullName,	InterimOffice,	
	SUBSTRING( Day_FirstLastHour, 1 , 5) + '-' + SUBSTRING( Day_FirstLastHour, 12, 5)		AS Day_FirstLastHour
	,Organization,	[Address],	ZipCode,	Residence,	HireDate,	StartTime,	EndTime,	ShiftStartDate,	
	FORMAT(cast(ShiftStartHour as time), N'hh\:mm') AS ShiftStartHour,	
	ShiftEndDate,	
	FORMAT(cast(ShiftEndHour as time), N'hh\:mm')	AS ShiftEndHour,			
	ScheduledPaidTime,	ScheduledAbsenceTime,	ScheduledTotalTime,	ScheduledActivity,	SolvusActivityGroup,	IsAbsenceTime,	StopDate,	EmployeeLogin,	EmployeeID,	PERSON_ID,	RegisterNumber_RowNr,	RowNr,	
	ISNULL( IsHoliDay, '0')	AS IsHoliDay,	
	PerformanceCode,	[Function],	
	Gr,	NewShiftTime,	NewShift,	DaysDiff,	FirstStartTime,	LastEndTime,	
	FORMAT(cast(FirstStartHour as time), N'hh\:mm') AS FirstStartHour,			
	FORMAT(cast(LastEndHour as time), N'hh\:mm')	AS LastEndHour,			
	TimeType,	WeekDayName,	
	
	--		2022-08-09BB:   
	--		was:	decimal(10,2)  
	--		new:	decimal(15,11)
	CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexSaturdayHours ))				AS	FlexSaturdayHours,		
	CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexEveningSaturdayHours ))		AS	FlexEveningSaturdayHours,
	CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexEveningWorkSaturdayHours ))	AS	FlexEveningWorkSaturdayHours,
	CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexEveningWorkDayHours ))		AS	FlexEveningWorkDayHours,
	CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexSundayHours ))				AS	FlexSundayHours,
	CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexHoliDayHours ))				AS	FlexHoliDayHours,
	DefaultHours																	AS	DefaultHours,
	CONVERT(decimal(15,11), CONVERT(varbinary(20), NightAgentHours ))				AS	NightAgentHours,    --Description: Stefan Damyanov, 28.07.2023  - typo in the name

	PlannedWorkDays,
	TotalWorkDays,
	BreakSplitShift
	,EmploymentPlace
	INTO	#Basis		--	Select * from #Basis where EmployeeLogin like '%donder%'
	FROM	#tmp122		--	select * from #tmp122 where	EmployeeLogin like '%donder%'

	--TRUNCATE TABLE TERUG NAAR PERFSOLV
	TRUNCATE TABLE	[DwH].[dbo].[PerformanceSolvus]
	INSERT INTO		[DwH].[dbo].[PerformanceSolvus]
	SELECT d.RegisterNumber,
		   d.ShiftStartDate,
		   d.PerformanceCode,
		   d.ScheduledActivity,	
		   d.PERSON_ID,
		   d.FirstName,
		   d.LastName,
		   d.EmployeeLogin,			
		   CASE WHEN d.ScheduledTotalTime between 0.99 and 1.00 THEN round(d.ScheduledTotalTime,0)
		        WHEN d.ScheduledTotalTime between 1.99 and 2.00 THEN round(d.ScheduledTotalTime,0)
				WHEN d.ScheduledTotalTime between 2.99 and 3.00 THEN round(d.ScheduledTotalTime,0)
				WHEN d.ScheduledTotalTime between 3.99 and 4.00 THEN round(d.ScheduledTotalTime,0)
				WHEN d.ScheduledTotalTime between 4.99 and 5.00 THEN round(d.ScheduledTotalTime,0)
				WHEN d.ScheduledTotalTime between 5.99 and 6.00 THEN round(d.ScheduledTotalTime,0)
				WHEN d.ScheduledTotalTime between 6.99 and 7.00 THEN round(d.ScheduledTotalTime,0)
				WHEN d.ScheduledTotalTime between 7.99 and 8.00 THEN round(d.ScheduledTotalTime,0)
				WHEN d.ScheduledTotalTime between 8.99 and 9.00 THEN round(d.ScheduledTotalTime,0)
				WHEN d.ScheduledTotalTime between 9.99 and 10.00 THEN round(d.ScheduledTotalTime,0)
				WHEN d.ScheduledTotalTime between 10.99 and 11.00 THEN round(d.ScheduledTotalTime,0)
				WHEN d.ScheduledTotalTime between 11.99 and 12.00 THEN round(d.ScheduledTotalTime,0)
				WHEN d.ScheduledTotalTime between 12.99 and 13.00 THEN round(d.ScheduledTotalTime,0)
		        ELSE d.ScheduledTotalTime 
		   END AS ScheduledTotalTime
	  FROM (SELECT 
						iif(RegisterNumber='' OR isnull(RegisterNumber,'Y')='Y',  'NoNr', RegisterNumber ) 	AS RegisterNumber
			,			ShiftStartDate
			,			PerformanceCode
			,			ScheduledActivity	
			,			PERSON_ID
			,			FirstName
			,			LastName
			,			EmployeeLogin
			--,			convert( decimal(8,2), SUM(ScheduledTotalTime) )			AS	ScheduledTotalTime
			,			SUM(ScheduledTotalTime)	AS	ScheduledTotalTime
			FROM		#tmp122					--		select * from #tmp122	
			WHERE		LOWER(InterimOffice) like 'vast%'		--	For KLX take only VAST (no interim)			
			GROUP BY	iif(RegisterNumber='' OR isnull(RegisterNumber,'Y')='Y',  'NoNr', RegisterNumber ) 
			,			ShiftStartDate
			,			PerformanceCode
			,			ScheduledActivity	
			,			PERSON_ID
			,			FirstName
			,			LastName
			,			EmployeeLogin) d

/*	Generate KLX file: "KLX"		*/
IF @LongShort	= 'KLX'
BEGIN	
	

		
		RETURN;	--	 Exits stored procedure
END 	--> 'KLX'


IF @LongShort	= 'basis'
BEGIN	
		--->>>	SELECT * FROM 	#Basis  was untill 2022-12-16BB

---	NEW	 from 2022-12-16BB	  added:  CAST & ROUND on numbers 
	SELECT 

	RegisterNumber,	LastName,	FirstName,	FullName,	InterimOffice,	Day_FirstLastHour,	Organization,	[Address],	ZipCode,	Residence,	HireDate,	StartTime,	EndTime,
	ShiftStartDate,	ShiftStartHour,	ShiftEndDate,	ShiftEndHour,

	ScheduledPaidTime	AS	ScheduledPaidTime,	  
	--cast( ROUND(ScheduledAbsenceTime,	2, 0) as float )	AS	ScheduledAbsenceTime,	  
	ScheduledAbsenceTime	AS	ScheduledAbsenceTime,	  
	ScheduledTotalTime AS	ScheduledTotalTime,	  

	ScheduledActivity,	SolvusActivityGroup,	IsAbsenceTime,	StopDate,	EmployeeLogin,	EmployeeID,	PERSON_ID,	RegisterNumber_RowNr,	RowNr,	IsHoliDay,	PerformanceCode,
	[Function],	Gr,	NewShiftTime,	NewShift,	DaysDiff,	FirstStartTime,	LastEndTime,	FirstStartHour,	LastEndHour,	TimeType,	WeekDayName,

	FlexSaturdayHours	AS	FlexSaturdayHours,
	FlexEveningSaturdayHours	AS	FlexEveningSaturdayHours,
	FlexEveningWorkSaturdayHours AS	FlexEveningWorkSaturdayHours,
	FlexEveningWorkDayHours AS	FlexEveningWorkDayHours,
	FlexSundayHours AS	FlexSundayHours,
	FlexHoliDayHours AS	FlexHoliDayHours,
	DefaultHours  AS	DefaultHours,
	NightAgentHours AS	NightAgentHours, --Description: Stefan Damyanov, 28.07.2023  - typo in the name

	PlannedWorkDays,TotalWorkDays,	BreakSplitShift,	EmploymentPlace

	FROM	#Basis 
	--where EmployeeID = 1075

	RETURN;	--	 Exits stored procedure
END 	--> 'short'


IF		@LongShort		=	'long'
AND		@DateSpanStr	NOT IN	('PWc','PMc','CWc','CMc','NWc','NMc')	
BEGIN

--	GET #FLEX_DayLevel	-- 9832
	SELECT		RegisterNumber						AS	RR, 
				LastName							AS	Naam,
				FirstName							AS	Voornaam,
				InterimOffice						AS	[Temp kantoor],
				ShiftStartDate						AS	Datum,
				BreakSplitShift						AS	BreakSplitShift,
				sum(ScheduledTotalTime)				AS	[Gepresteerde Uren],
				sum(FlexSaturdayHours)				AS	FlexSaturdayHours,
				sum(FlexSundayHours)				AS	FlexSundayHours,
				sum(FlexEveningWorkDayHours)		AS	FlexEveningWorkDayHours,
				sum(FlexEveningSaturdayHours)		AS	FlexEveningSaturdayHours,
				sum(FlexEveningWorkSaturdayHours)	AS	FlexEveningWorkSaturdayHours,			
				sum(FlexHoliDayHours)				AS	FlexHolidayHours,			
				sum(NightAgentHours)				AS	NightAgentHours,   --Description: Stefan Damyanov, 28.07.2023  - typo in the name
				sum(DefaultHours)					AS	DefaultHours

	INTO		#FLEX_DayLevel			-- drop table #FLEX_DayLevel -- select * from #FLEX_DayLevel

	FROM		#tmp121
	Group by	RegisterNumber, LastName, FirstName, InterimOffice, ShiftStartDate, BreakSplitShift

-------------------------------
--	GET #Absence_DayLevel	-- PIVOT [SolvusActivityGroup] with sum(ScheduledTotalTime)
	SELECT		RegisterNumber	AS	RR, 				
				ShiftStartDate	AS	Datum,

				-- Create total Absense Hours [Afwezige uren]
				(
				isnull([Langdurig ziek],0)		+		
				
				isnull([Ziek],0)				+
				isnull([Familiaal verlof],0)	+
				isnull([Feestdag],0)			+
				isnull([vakantie],0)			+
				isnull([Bevallingsverlof],0)	+
				isnull([ADV],0)					+
				isnull([Ongewettigd afwezig],0)	+
				isnull([Klein Verlet],0)		+	
				isnull([Ouderschapsverlof],0)		
					)							AS	[Afwezige uren],
				isnull([Feestdag],0)			AS	[Feestdag],
				isnull([Ziek],0)				AS	[Ziek],
				isnull([ADV],0)					AS	[ADV],	
				isnull([vakantie],0)			AS	[vakantie],
				isnull([Ongewettigd afwezig],0)	AS	[Ongewettigd afwezig],
				isnull([Bevallingsverlof],0)	AS	[Bevallingsverlof],
				isnull([Educatief verlof],0)	AS	[Educatief verlof],
				isnull([Familiaal verlof],0)	AS	[Familiaal verlof],
				isnull([Klein Verlet],0)		AS	[Klein Verlet],
				isnull([Langdurig ziek],0)		AS	[Langdurig ziek],
				isnull([Ouderschapsverlof],0)	AS	[Ouderschapsverlof]


	INTO		#Absence_DayLevel	-- drop table #Absence_DayLevel  -- select * from #Absence_DayLevel

	FROM (
			SELECT	SolvusActivityGroup, 					
					RegisterNumber,
					ShiftStartDate,
					case when ScheduledTotalTime between 0.99 and 1.00 then round(ScheduledTotalTime,0)
					     when ScheduledTotalTime between 1.99 and 2.00 then round(ScheduledTotalTime,0)
						 when ScheduledTotalTime between 2.99 and 3.00 then round(ScheduledTotalTime,0)
						 when ScheduledTotalTime between 3.99 and 4.00 then round(ScheduledTotalTime,0)
						 when ScheduledTotalTime between 4.99 and 5.00 then round(ScheduledTotalTime,0)
						 when ScheduledTotalTime between 5.99 and 6.00 then round(ScheduledTotalTime,0)
						 when ScheduledTotalTime between 6.99 and 7.00 then round(ScheduledTotalTime,0)
						 when ScheduledTotalTime between 7.99 and 8.00 then round(ScheduledTotalTime,0)
						 when ScheduledTotalTime between 8.99 and 9.00 then round(ScheduledTotalTime,0)
						 when ScheduledTotalTime between 9.99 and 10.00 then round(ScheduledTotalTime,0)
						 when ScheduledTotalTime between 10.99 and 11.00 then round(ScheduledTotalTime,0)
						 when ScheduledTotalTime between 11.99 and 12.00 then round(ScheduledTotalTime,0)
						 when ScheduledTotalTime between 12.99 and 13.00 then round(ScheduledTotalTime,0)
					     else ScheduledTotalTime
					end as ScheduledTotalTime
			FROM	#tmp121
			WHERE	SolvusActivityGroup <> 'Prestatie'
			AND		RegisterNumber		<>	''
		) up
	PIVOT(	SUM( ScheduledTotalTime )  
			FOR	SolvusActivityGroup	IN
			(	
				[Feestdag],	
				[Ziek],
				[ADV],
				[vakantie],							
				[Ongewettigd afwezig],
				[Bevallingsverlof],
				[Educatief verlof],
				[Familiaal verlof],
				[Klein Verlet],
				[Langdurig ziek],
				[Ouderschapsverlof]

			)
		 )	AS pvt	
	order by	RegisterNumber,	ShiftStartDate	
	-- END #Absence_DayLevel

-- COMBINE #FLEX_DayLevel & #Absence_DayLevel

	Select		T1.*, 
	isnull(T2.[Afwezige uren],0)[Afwezige uren],  
	isnull(T2.[Feestdag],0)[Feestdag],
	isnull(T2.[Ziek],0)[Ziek],
	isnull(T2.[ADV],0)[ADV],
	isnull(T2.[vakantie],0)[vakantie],
	isnull(T2.[Ongewettigd afwezig],0)[Ongewettigd afwezig],
	isnull(T2.[Bevallingsverlof],0)[Bevallingsverlof],
	isnull(T2.[Educatief verlof],0)[Educatief verlof],
	isnull(T2.[Familiaal verlof],0)[Familiaal verlof],      
	isnull(T2.[Klein Verlet],0)[Klein Verlet], 
	isnull(T2.[Langdurig ziek],0)[Langdurig ziek],   
	isnull(T2.[Ouderschapsverlof],0)[Ouderschapsverlof]

	
	FROM		#FLEX_DayLevel		T1		--9832
	FULL JOIN	#Absence_DayLevel	T2		--2532
	ON			T1.RR		=	T2.RR
	AND			T1.Datum	=	T2.Datum

	Return;	--	 Exits stored procedure
END	--> IF  @LongShort	= 'long'


IF( object_id('tempdb..#ReturnDataShort') is not null )	DROP table	#ReturnDataShort;
IF		@LongShort		= 'short'
AND		@DateSpanStr	NOT IN	('PWc','PMc','CWc','CMc','NWc','NMc')	
	BEGIN	
	SELECT  d1.col_1  AS    'Rijksregisternummer', 
			d1.col_2  AS	[Naam, Voornaam	], 
			d1.col_3  AS	'Project',	 
			d1.col_4  AS	'Function',
			d1.col_5  AS	[Temp kantoor],
			d1.col_6  AS	'Datum',
			d1.col_7  AS	'Datum_',
			case when d1.col_8 between 0.99 and 1.00 then round(d1.col_8,0)
			     when d1.col_8 between 1.99 and 2.00 then round(d1.col_8,0)
				 when d1.col_8 between 2.99 and 3.00 then round(d1.col_8,0)
				 when d1.col_8 between 3.99 and 4.00 then round(d1.col_8,0)
				 when d1.col_8 between 4.99 and 5.00 then round(d1.col_8,0)
				 when d1.col_8 between 5.99 and 6.00 then round(d1.col_8,0)
				 when d1.col_8 between 6.99 and 7.00 then round(d1.col_8,0)
				 when d1.col_8 between 7.99 and 8.00 then round(d1.col_8,0)
				 when d1.col_8 between 8.99 and 9.00 then round(d1.col_8,0)
				 when d1.col_8 between 9.99 and 10.00 then round(d1.col_8,0)
				 when d1.col_8 between 10.99 and 11.00 then round(d1.col_8,0)
				 when d1.col_8 between 11.99 and 12.00 then round(d1.col_8,0)
				 when d1.col_8 between 12.99 and 13.00 then round(d1.col_8,0)
			     else d1.col_8
		    end AS	[Aantal Werkuren],
			d1.col_9  AS	'BreakSplitShift',
			d1.col_10 AS    'StartUur1',
			d1.col_11 AS    'EindUur1'
      INTO #ReturnDataShort
	  FROM ( SELECT --top 10 	
					RegisterNumber										AS	col_1, 
					LastName +','+ FirstName							AS	col_2, 
					Organization										AS	col_3,	 
					[Function]											AS	col_4,
					InterimOffice										AS	col_5,
					ShiftStartDate										AS	col_6,
					CONVERT(varchar,ShiftStartDate, 103)				AS	col_7,
					SUM(ScheduledTotalTime)								AS	col_8,
					BreakSplitShift										AS	col_9,
					FirstStartHour										AS  col_10,
					LastEndHour											AS  col_11		
		FROM		#tmp122					-- select * from #tmp122
		WHERE		1=1

		GROUP BY	RegisterNumber,		
					LastName +','+ FirstName,
					Organization,			
					[Function],	
					[EmploymentPlace],
					InterimOffice,			
					ShiftStartDate,			
					CONVERT(varchar,ShiftStartDate, 103),
					ShiftStartDate,		
					FirstStartHour,	
					LastEndHour,
					BreakSplitShift) d1	


	SELECT * FROM	#ReturnDataShort	--	output for  EXCEL
	Return;	--	 Exits stored procedure
	END 

--	Declare @DateSpanStr varchar(12) = 'PMc',  @FromDate Date='2017-08-01', @ToDate Date='2017-08-31';
IF( object_id('tempdb..#ReturnDataShortCumul') is not null )	DROP table	#ReturnDataShortCumul;
IF	@DateSpanStr	IN	('PWc','PMc','CWc','CMc','NWc','NMc')	-->>	Short Cumul, no dates		'CMc'=Current Month Cumul;  'CWc'=Current Week cumul
	BEGIN	
	--	declare	@FromDate date='2017-08-01', @ToDate date='2017-08-10';
	SELECT d2.col_1 AS	Rijksregisternummer,
		   d2.col_2 AS	[Naam, Voornaam	], 
		   d2.col_3 AS	Project,	 
		   d2.col_4 AS	[Function],
		   d2.col_5 AS	[EmploymentPlace],
		   d2.col_6 AS	[Temp kantoor],		
		   case when d2.col_7 between 0.99 and 1.00 then round(d2.col_7,0)
		        when d2.col_7 between 1.99 and 2.00 then round(d2.col_7,0)
				when d2.col_7 between 2.99 and 3.00 then round(d2.col_7,0)
				when d2.col_7 between 3.99 and 4.00 then round(d2.col_7,0)
				when d2.col_7 between 4.99 and 5.00 then round(d2.col_7,0)
				when d2.col_7 between 5.99 and 6.00 then round(d2.col_7,0)
				when d2.col_7 between 6.99 and 7.00 then round(d2.col_7,0)
				when d2.col_7 between 7.99 and 8.00 then round(d2.col_7,0)
				when d2.col_7 between 8.99 and 9.00 then round(d2.col_7,0)
				when d2.col_7 between 9.99 and 10.00 then round(d2.col_7,0)
				when d2.col_7 between 10.99 and 11.00 then round(d2.col_7,0)
				when d2.col_7 between 11.99 and 12.00 then round(d2.col_7,0)
				when d2.col_7 between 12.99 and 13.00 then round(d2.col_7,0)
		        else d2.col_7
		   end AS	[Aantal Werkuren],	
		   d2.col_8 AS	FromDate,
		   d2.col_9 AS	ToDate 				
	  INTO	#ReturnDataShortCumul
	  FROM (SELECT	--top 10 	
					RegisterNumber										AS	col_1, 
					LastName +','+ FirstName							AS	col_2, 
					Organization										AS	col_3,	 
					[Function]											AS	col_4,
					[EmploymentPlace]									AS	col_5,
					InterimOffice										AS	col_6,			
					SUM(ScheduledTotalTime)								AS	col_7			
					,@FromDate											AS	col_8
					,@ToDate											AS	col_9 					
		FROM		#tmp122
		GROUP BY	RegisterNumber,		
					LastName +','+ FirstName,
					Organization,			
					[Function],	
					[EmploymentPlace],
					InterimOffice) d2
      ORDER BY	d2.col_1


	-- Generate output
	SELECT * FROM	#ReturnDataShortCumul	--	output for  EXCEL

	END 
 

END
GO
