/*=================================================(0.0.0)=================================================
-- Date: 13-Jun-2024
*/
USE [DwH]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spGET_PerformanceSolvus_Injixo]
@DateSpanStr varchar(12) = 'NW',
@LongShort varchar(12) = 'basis',
@FromDate_ Date = NULL,
@ToDate_ Date = NULL

AS
BEGIN



/*=================================================(1.0)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Ensures that no count messages are sent to the client
*/



SET NOCOUNT ON;



/*=================================================(1.1)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Declare and initialize variables for today's date
*/



DECLARE @today AS DATE = dateadd(month, -0, GetDate());
DECLARE @d DATE = getdate();
DECLARE @FromDate date, @ToDate date;



/*=================================================(1.2)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Determine date range based on @DateSpanStr input
*/



IF @DateSpanStr IN( 'PW', 'PWc')
BEGIN
    SELECT @ToDate = DATEADD(DAY, 1-DATEPART(WEEKDAY, @d), @d)
    SELECT @FromDate = DATEADD(DAY, -6, @ToDate)
END

IF @DateSpanStr IN( 'CW', 'CWc')
BEGIN
    SELECT @FromDate = DATEADD(DAY, 1-DATEPART(WEEKDAY, @d) +1, @d)
    SELECT @ToDate = DATEADD(DAY, 6, @FromDate)
END

IF @DateSpanStr IN( 'NW', 'NWc')
BEGIN
    SELECT @FromDate = DATEADD([day], ((DATEDIFF([day], '19000101', getdate()) / 7) * 7) + 7, '19000101')
    SELECT @ToDate = DATEADD(DAY, 6, @FromDate)
END

IF @DateSpanStr IN( 'PM', 'PMc')
BEGIN
    SET @FromDate = (SELECT DATEADD(DAY, 1, EOMONTH(@today, -2)))
    SET @ToDate = (SELECT EOMONTH(@today, -1))
END

IF @DateSpanStr IN( 'P2M', 'P2Mc')
BEGIN
    SET @FromDate = (SELECT DATEADD(DAY, 1, EOMONTH(@today, -3)))
    SET @ToDate = (SELECT DATEADD(DAY, -1, EOMONTH(GETDATE())))
END

IF @DateSpanStr IN( 'C2M', 'C2Mc')
BEGIN
    SET @FromDate = (SELECT DATEADD(DAY, 1, EOMONTH(@today, -2)))
    SET @ToDate = (SELECT EOMONTH(@today))
END

IF @DateSpanStr IN( 'CM', 'CMc')
BEGIN
    SET @FromDate = (SELECT DATEADD(DAY, 1, EOMONTH(@today, -1)))
    SET @ToDate = (SELECT EOMONTH(@today))
END

IF @DateSpanStr IN( 'NM', 'NMc')
BEGIN
    SELECT @FromDate = (SELECT DATEADD(DAY, 1, EOMONTH(@today)))
    SELECT @ToDate = (SELECT EOMONTH(@today, 1))
END



/*=================================================(2.0)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Adjust date range to include the day before and after
*/



IF 1=1
BEGIN
    SELECT @FromDate = (SELECT DATEADD(DAY, -1, @FromDate))
    SELECT @ToDate = (SELECT DATEADD(DAY, 1, @ToDate))
END



/*=================================================(3.0.0)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Drop temporary tables if they exist
*/



IF (object_id('tempdb..#tmp1') is not null) DROP table #tmp1;
IF (object_id('tempdb..#tmp2') is not null) DROP table #tmp2;
IF (object_id('tempdb..#tmp3') is not null) DROP table #tmp3;
IF (object_id('tempdb..#tmp4') is not null) DROP table #tmp4;
IF (object_id('tempdb..#tmp10') is not null) DROP table #tmp10;
IF (object_id('tempdb..#tmp11') is not null) DROP table #tmp11;
IF (object_id('tempdb..#tmp100') is not null) DROP table #tmp100;
IF (object_id('tempdb..#tmp110') is not null) DROP table #tmp110;
IF (object_id('tempdb..#NightAgentHours') is not null) DROP table #NightAgentHours;
IF (object_id('tempdb..#OnlyFlexHours') is not null) DROP table #OnlyFlexHours;
IF (object_id('tempdb..#FLEX_AND_DefaultHours') is not null) DROP table #FLEX_AND_DefaultHours;
IF (object_id('tempdb..#tmp120') is not null) DROP table #tmp120;
IF (object_id('tempdb..#tmp121') is not null) DROP table #tmp121;
IF (object_id('tempdb..#tmp122') is not null) DROP table #tmp122;
IF (object_id('tempdb..#HoliDays') is not null) DROP table #HoliDays;
IF (object_id('tempdb..#TotalWorkDays1') is not null) DROP table #TotalWorkDays1;
IF (object_id('tempdb..#TotalWorkDays2') is not null) DROP table #TotalWorkDays2;
IF (object_id('tempdb..#BreakSplitShift') is not null) DROP table #BreakSplitShift;
IF (object_id('tempdb..#tmp_Night_Shift_order') is not null) DROP table #tmp_Night_Shift_order;



/*=================================================(3.0.1)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Create temporary table #tmp1 to store planned workdays for each employee
*/



SELECT * 
INTO #tmp1 
FROM
    (select DISTINCT count(*) AS PlannedWorkDays, EmployeeID  
     from (SELECT DISTINCT (cast([ShiftStartDate] as date)) AS StartDate, employee_id AS EmployeeID		
           FROM [Dwh].[dbo].[F_PlannedData]
           WHERE 1=1
           and cast([ShiftStartDate] as date) BETWEEN (SELECT DATEADD(DAY, 1, @FromDate)) AND (SELECT DATEADD(DAY, -1, @ToDate))
          )T1 
     Group By EmployeeID
    )T2
	
	
	
/*=================================================(3.0.2)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Create temporary table #tmp2 with detailed information for each planned shift
*/



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
       ScheduledPaidTime + ScheduledAbsenceTime AS ScheduledTotalTime, 
       ScheduledActivity, 
       SolvusActivityGroup,	
       IsAbsenceTime,
       StopDate,
       EmployeeLogin,
       E.EmployeeID,
       PERSON_ID,		
       ROW_NUMBER()  OVER(partition by FullName order by StartTime) AS RegisterNumber_RowNr,
       ROW_NUMBER()  OVER(order by FullName, StartTime) AS RowNr,
       isnull(IsHoliDay, 0) AS IsHoliDay,
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
INTO #tmp2	
FROM (
      SELECT distinct
             coalesce(FP.[StartTime],cast(FP.[ShiftStartDate] as datetime)) AS [StartTime],
             coalesce(FP.[EndTime],cast(FP.[ShiftEndDate] as datetime)) AS [EndTime],
             CAST(FP.[ShiftStartDate] as date) AS ShiftStartDate,
             coalesce(FP.[ShiftStartHour],cast(FP.[ShiftStartDate] as datetime)) AS ShiftStartHour,
             CAST(FP.[ShiftEndDate] as date) AS ShiftEndDate,
             coalesce(FP.[ShiftEndHour],cast(FP.[ShiftEndDate] as datetime)) AS ShiftEndHo										
             FP.ScheduledTime AS ScheduledTime, 
             FP.ScheduledPaidTime AS ScheduledPaidTime,				
             case when [official_name] = 'Feestdag' then 8
                  else FP.ScheduledAbsenceTime
             end AS ScheduledAbsenceTime,
             iif(FP.ishomeworking = 1 AND DA.[official_name] = 'Prestatie', 'Homeworking', DA.[Name]) AS ScheduledActivity,		
             iif(FP.ishomeworking = 1 AND DA.[official_name] = 'Prestatie', 'Homeworking', [official_name]) AS SolvusActivityGroup,
             FP.[employee_id] AS EmployeeID,
             isnull(FP.IsAbsence,0) AS IsAbsenceTime,
             ISNULL([isbankholiday], 0) AS IsHoliDay,
             iif(FP.ishomeworking = 1 AND DA.[official_name] = 'Prestatie', '1020' , DA.[official_name_short]) AS PerformanceCode,
             IIF(ISNULL([isbreaksplitshift], 0) = 0 , 'No', 'Yes') AS BreakSplitShift,
             FP.[organization] AS Organization,
             FP.InterimOffice AS InterimOffice,		  
             FP.EmploymentPlace AS EmploymentPlace,
             FP.[type_shift] AS [type_shift],
             FP.[contract_name] AS [contract_name],
             FP.[contract_name_short] AS [contract_name_short],
             FP.[contract_day_max] AS [contract_day_max],
             FP.[contract_week_max] AS [contract_week_max],
             FP.[timetype] as timetype,
             FP.[weekdayname] as weekdayname,
             ISNULL(FP.[ishomeworking], 0) as ishomeworking
      FROM [DwH].[dbo].[F_PlannedData] FP
      LEFT JOIN [Dwh].[dbo].[D_PlannedActivity] DA ON FP.activity_id = DA.activity_id				 
      WHERE 1 = 1
        AND cast(FP.[ShiftStartDate] as date) BETWEEN @FromDate AND @ToDate	     		
        AND FP.employee_id IN (SELECT distinct DE.INJIXO_ID 
                               FROM [Dwh].[dbo].[D_Employee] DE									
                               WHERE 1 = 1 
                                 AND DE.ValidTo IS NULL)
     ) P
JOIN (
     SELECT distinct 
            isnull(DE.PERSONEL_NUMBER,'') AS RegisterNumber,
            [LastName] AS LastName, 
            [FirstName] AS FirstName,
            [LastName] + ', ' +  [FirstName] AS FullName,
            [Address] AS [Address],
            ZipCode AS ZipCode,
            DE.City AS Residence,
            [StartDate] AS HireDate, 
            T1.PlannedWorkDays AS PlannedWorkDays,
            isnull([EndDate],'2099-12-31') AS StopDate,
            SUBSTRING(DE.[EMAIL], 0, charindex('@', DE.[EMAIL], 0)) AS EmployeeLogin,
            DE.INJIXO_ID AS EmployeeID,
            INJIXO_ID AS PERSON_ID,
            DateDiff(dd, DE.[StartDate], isnull(DE.[EndDate], GetDate())) AS PassedDays,
            DE.Position AS [Function]
     FROM [DwH].dbo.D_Employee DE
     LEFT JOIN #tmp1 T1 ON DE.INJIXO_ID = T1.EmployeeID
     WHERE 1=1
       AND DE.ValidTo IS NULL
     ) E
ON P.EmployeeID = E.EmployeeID	
WHERE 1=1
  AND isnull(StopDate, '2099-01-01') > @FromDate



/*=================================================(3.0.3)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Remove records with Lunch or Unavailable/Off activities
*/



DELETE FROM #tmp2 WHERE ScheduledActivity = 'Lunch'  
DELETE FROM #tmp2 WHERE ScheduledActivity = 'Unavailable/Off'



/*=================================================(3.0.4)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Create #tmp10 with calculated fields for new shifts
*/



SELECT *,
       0 AS Gr,
       IsNull(DateDiff(MINUTE, LAG(EndTime) OVER (PARTITION BY EmployeeID ORDER BY RowNr ASC), StartTime), 0) AS NewShiftTime,
       iif(IsNull(DateDiff(MINUTE, LAG(EndTime) OVER (PARTITION BY EmployeeID ORDER BY RowNr ASC), StartTime), 0) > 240 , 1, 0) AS NewShift,
       DATEDIFF(DAY, ShiftStartDate, ShiftEndDate) AS DaysDiff 	
INTO #tmp10
FROM #tmp2
ORDER BY StartTime, FirstName



/*=================================================(3.0.5)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Update Group identifier in #tmp10
*/



DECLARE @i int = 0;	
WITH q AS (
    SELECT TOP 1000000 *
    FROM #tmp10
    ORDER BY RowNr
)            
UPDATE q
SET @i = Gr = CASE WHEN NewShift = 1 THEN @i + 1 ELSE @i END



/*=================================================(3.0.6)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Drop #NightShift if it exists and create a new table
*/
IF (object_id('tempdb..#NightShift') is not null) DROP table #NightShift;

CREATE TABLE #NightShift (date_key NVARCHAR(8), 
                          employee_id NVARCHAR(max), 
                          type_shift nvarchar(5));
						  
						  
						  
/*=================================================(3.0.7)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Insert distinct shift data into #NightShift
*/



INSERT INTO #NightShift (date_key, employee_id, type_shift)
SELECT DISTINCT datekey, employee_id, type_shift FROM [dbo].[F_PlannedData]



/*=================================================(3.0.7)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Create #tmp11 with additional shift details and flags for night shifts
*/



SELECT distinct df.* 
INTO #tmp11		
FROM (
    SELECT T1.*, 
           T2.FirstStartTime, 
           T3.LastEndTime, 
           convert(varchar(8), T2.FirstStartTime, 108) AS FirstStartHour,
           convert(varchar(8), T3.LastEndTime, 108) AS LastEndHour, 																	
           convert(varchar(8), T2.FirstStartTime, 108) + ' - ' + convert(varchar(8), T3.LastEndTime, 108) AS 'Day_FirstLastHour',
           'LN' as NightShift
    FROM #tmp10 T1
    LEFT JOIN (SELECT min(coalesce(StartTime, ShiftStartDate)) AS FirstStartTime, 
                      EmployeeID,	
                      Gr, 
                      cast(coalesce(StartTime, ShiftStartDate) as date) AS SD  
               FROM #tmp10 
               WHERE 1 = 1
               GROUP BY EmployeeID, Gr, cast(coalesce(StartTime, ShiftStartDate) as date)) T2
    ON (T1.EmployeeID = T2.EmployeeID AND T1.Gr = T2.Gr AND cast(coalesce(t1.StartTime, t1.ShiftStartDate) as date) = T2.SD)
    LEFT JOIN (SELECT max(coalesce(EndTime, ShiftEndDate)) AS LastEndTime, 
                      EmployeeID,	
                      Gr, 
                      cast(coalesce(EndTime, ShiftEndDate) as date) AS SD	
               FROM #tmp10 
               WHERE 1 = 1
               GROUP BY EmployeeID, Gr, cast(coalesce(EndTime, ShiftEndDate) as date)) T3
    ON (T1.EmployeeID = T3.EmployeeID AND T1.Gr = T3.Gr AND cast(coalesce(t1.EndTime, t1.ShiftEndDate) as date) = T3.SD)
    LEFT JOIN (SELECT d.employee_id, d.date_key
               FROM #NightShift d
               WHERE 1 = 1 AND d.type_shift = 'LN') d_LN
    ON (t1.EmployeeID = d_LN.employee_id AND t1.ShiftStartDate = d_LN.date_key)	
    WHERE 1 = 1
    AND ((T1.SolvusActivityGroup not in ('Feestdag')
         AND isnull(convert(varchar(8), T3.LastEndTime, 108),'23:59:59') not in ('23:30:00')
         AND isnull(convert(varchar(8), T2.FirstStartTime, 108),'23:59:59') not in ('00:00:00'))
         OR (T1.SolvusActivityGroup in ('Feestdag')
         AND isnull(convert(varchar(8), T3.LastEndTime, 108),'23:59:59') in ('00:00:00')
         AND isnull(convert(varchar(8), T2.FirstStartTime, 108),'23:59:59') in ('00:00:00'))
         )
UNION 
SELECT T1_b.*, 
       T2.FirstStartTime, 
       T3.LastEndTime, 
       convert(varchar(8), T2.FirstStartTime, 108) AS FirstStartHour,
       convert(varchar(8), T3.LastEndTime, 108) AS LastEndHour, 																	
       convert(varchar(8), T2.FirstStartTime, 108) + ' - ' + convert(varchar(8), T3.LastEndTime, 108) AS 'Day_FirstLastHour',
       'NLN' as NightShift 				            
FROM #tmp10 T1_b
LEFT JOIN (SELECT min(coalesce(StartTime, ShiftStartDate)) AS FirstStartTime, 
                  EmployeeID, Gr
           FROM #tmp10 sd
           INNER JOIN #NightShift t2_b ON sd.EmployeeID = t2_b.employee_id				                  
           WHERE 1 = 1
           AND cast(coalesce(sd.StartTime, sd.ShiftStartDate) as date) between dateadd(day, -1, cast(T2_b.date_key as date)) and dateadd(day, 1, cast(t2_b.date_key as date))
           AND t2_b.type_shift = 'NLN'
           GROUP BY EmployeeID, Gr) T2
ON (T1_b.EmployeeID = T2.EmployeeID AND T1_b.Gr = T2.Gr)
LEFT JOIN (SELECT max(coalesce(EndTime, ShiftEndDate)) AS LastEndTime, 
                  EmployeeID, Gr
           FROM #tmp10 sd_b
           INNER JOIN #NightShift t2_b ON sd_b.EmployeeID = t2_b.employee_id				                  
           WHERE 1 = 1
           AND cast(coalesce(sd_b.EndTime, sd_b.ShiftEndDate) as date) between cast(T2_b.date_key as date) and dateadd(day, 1, cast(t2_b.date_key as date))
           AND t2_b.type_shift = 'NLN'
           GROUP BY EmployeeID, Gr) T3
ON (T1_b.EmployeeID = T3.EmployeeID AND T1_b.Gr = T3.Gr)	
WHERE 1 = 1
AND ((T1_b.SolvusActivityGroup not in ('Feestdag')
     AND isnull(convert(varchar(8), T3.LastEndTime, 108),'23:59:59') not in ('23:30:00')
     AND isnull(convert(varchar(8), T2.FirstStartTime, 108),'23:59:59') not in ('00:00:00'))
     OR (T1_b.SolvusActivityGroup in ('Feestdag')
     AND isnull(convert(varchar(8), T3.LastEndTime, 108),'23:59:59') in ('00:00:00')
     AND isnull(convert(varchar(8), T2.FirstStartTime, 108),'23:59:59') in ('00:00:00'))
     )
AND t1_b.EmployeeID in (SELECT b.employee_id 
                        FROM #NightShift b
                        WHERE 1 = 1 AND b.type_shift = 'NLN')
) df
ORDER BY df.StartTime



/*=================================================(3.0.8)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Remove records with LN night shift from #tmp11 if the employee has NLN night shift
*/



DELETE FROM #tmp11
WHERE 1 = 1
AND NightShift = 'LN'
AND EmployeeID in (SELECT b.employee_id 
                   FROM #NightShift b
                   WHERE 1 = 1 AND b.type_shift = 'NLN');
		

		
/*=================================================(3.0.9)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Create #tmp_Night_Shift_order with shift order based on time intervals
*/



SELECT '16:00:01' as Hour_Start, '17:00:00' as Hour_End, 1 as Shift_Order
UNION
SELECT '17:00:01' as Hour_Start, '18:00:00' as Hour_End, 2 as Shift_Order
UNION
SELECT '18:00:01' as Hour_Start, '19:00:00' as Hour_End, 3 as Shift_Order
UNION
SELECT '19:00:01' as Hour_Start, '20:00:00' as Hour_End, 4 as Shift_Order
UNION
SELECT '20:00:01' as Hour_Start, '21:00:00' as Hour_End, 5 as Shift_Order
UNION
SELECT '21:00:01' as Hour_Start, '22:00:00' as Hour_End, 6 as Shift_Order
UNION
SELECT '22:00:01' as Hour_Start, '23:00:00' as Hour_End, 7 as Shift_Order
UNION
SELECT '23:00:01' as Hour_Start, '00:00:00' as Hour_End, 8 as Shift_Order
UNION
SELECT '00:00:01' as Hour_Start, '01:00:00' as Hour_End, 9 as Shift_Order
UNION
SELECT '01:00:01' as Hour_Start, '02:00:00' as Hour_End, 10 as Shift_Order
UNION
SELECT '02:00:01' as Hour_Start, '03:00:00' as Hour_End, 11 as Shift_Order
UNION
SELECT '03:00:01' as Hour_Start, '04:00:00' as Hour_End, 12 as Shift_Order
UNION
SELECT '04:00:01' as Hour_Start, '05:00:00' as Hour_End, 13 as Shift_Order
UNION
SELECT '05:00:01' as Hour_Start, '06:00:00' as Hour_End, 14 as Shift_Order
UNION
SELECT '06:00:01' as Hour_Start, '07:00:01' as Hour_End, 15 as Shift_Order
UNION
SELECT '07:00:01' as Hour_Start, '08:00:01' as Hour_End, 16 as Shift_Order
UNION
SELECT '08:00:01' as Hour_Start, '09:00:00' as Hour_End, 17 as Shift_Order
UNION
SELECT '09:00:01' as Hour_Start, '10:00:00' as Hour_End, 18 as Shift_Order
UNION
SELECT '10:00:01' as Hour_Start, '11:00:00' as Hour_End, 19 as Shift_Order
UNION
SELECT '11:00:01' as Hour_Start, '12:00:00' as Hour_End, 20 as Shift_Order
UNION
SELECT '12:00:01' as Hour_Start, '13:00:00' as Hour_End, 21 as Shift_Order
UNION
SELECT '13:00:01' as Hour_Start, '14:00:00' as Hour_End, 22 as Shift_Order
UNION
SELECT '14:00:01' as Hour_Start, '15:00:00' as Hour_End, 23 as Shift_Order
UNION
SELECT '15:00:01' as Hour_Start, '16:00:00' as Hour_End, 24 as Shift_Order



/*=================================================(3.1.0)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Create #tmp100 and filter records to exclude specific date ranges
*/



SELECT *
INTO #tmp100	
FROM #tmp11

DELETE
FROM #tmp100
WHERE cast(FirstStartTime as date) = @FromDate

DELETE
FROM #tmp100
WHERE 1=1
AND ShiftStartDate BETWEEN DATEADD(day, -1, @ToDate) AND @ToDate
AND cast(FirstStartTime as date) <> DATEADD(day, -1, @ToDate)
AND ShiftEndDate <> DATEADD(day, -1, @ToDate)



/*=================================================(3.1.1)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Calculate Flex and Default hours and store in #tmp110
*/



SELECT *,
    IIF(ShiftStartHour < '20:00:00' AND ShiftEndHour > '00:00:00'
        AND DATENAME(dw, ShiftStartDate) IN('Saturday') 
        AND IsHoliDay <> 1,
        DATEDIFF(second, cast(StartTime as time), IIF(cast(EndTime as time) > '20:00:00', '20:00:00', cast(EndTime as time)))/ 3600.000000, 0) AS FlexSaturdayHours,
    IIF(ShiftStartHour < '22:00:00' AND ShiftEndHour > '20:00:00'
        AND DATENAME(dw, ShiftStartDate) IN('Saturday')
        AND IsHoliDay <> 1,
        DATEDIFF(second, IIF(ShiftStartHour <= '20:00:00', '20:00:00', ShiftStartHour),
        IIF(ShiftEndDate > ShiftStartDate, '20:00:00', IIF(ShiftEndHour >= '22:00:00', '22:00:00', ShiftEndHour)))/ 3600.000000, 0) AS FlexEveningSaturdayHours,
    IIF(ShiftStartHour < '23:59:59' AND ShiftEndHour > '22:00:00'
        AND DATENAME(dw, ShiftStartDate) IN('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday','Saturday') 
        AND IsHoliDay <> 1,
        DATEDIFF(second, IIF(cast(StartTime as time) < '22:00:00', '22:00:00', cast(StartTime as time),
        IIF(cast(EndTime as time) < '23:59:59', cast(EndTime as time), '23:59:59')))/ 3600.000000, 0) AS FlexEveningWorkSaturdayHours,
    IIF(ShiftStartHour < '22:00:00' AND ShiftEndHour > '20:00:00'
        AND DATENAME(dw, ShiftStartDate) IN('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
        AND IsHoliDay <> 1,
        DATEDIFF(second, iif(cast(StartTime as time) < '20:00:00', '20:00:00', cast(StartTime as time),
        iif(cast(EndTime as time) > '21:59:59', '22:00:00', cast(EndTime as time)))/ 3600.000000, 0) AS FlexEveningWorkDayHours,
    IIF(DATENAME(dw, ShiftStartDate) IN('Sunday'),
        (DATEDIFF(second, StartTime, EndTime) / 3600.000000), 0) AS FlexSundayHours,
    IIF(IsHoliDay = 1 AND SolvusActivityGroup IN ('Prestatie' , 'Homeworking' , 'Opleiding met BEV'),
        (DATEDIFF(second, StartTime, EndTime) / 3600.000000), 0) AS FlexHoliDayHou						
INTO #tmp110
FROM #tmp100 T1
WHERE T1.[TimeType] <> 'NightAgent'



/*=================================================(3.1.2)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Calculate NightAgent hours and store in #NightAgentHours
*/



SELECT *,
    DATEDIFF(minute, StartTime, EndTime) / 60.00 AS NightAgentHours
INTO #NightAgentHours
FROM #tmp100 WHERE [TimeType] = 'NightAgent'


 
/*=================================================(3.1.3)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Combine Flex and Default hours into #FLEX_AND_DefaultHours
*/



SELECT *,
    ScheduledTotalTime - isnull(FlexSaturdayHours + FlexEveningSaturdayHours + FlexEveningWorkSaturdayHours + FlexEveningWorkDayHours + FlexSundayHours + FlexHoliDayHours, 0) AS DefaultHours
INTO #FLEX_AND_DefaultHours
FROM #tmp110
WHERE 1=1



/*=================================================(3.1.4)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Create #tmp120 with union of night agent and flex/default hours data
*/



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
       PlannedWorkDays, 
       StartTime, 
       EndTime, 
       CAST(FirstStartTime as date) AS ShiftStartDate,	
       ShiftStartHour,			
       ShiftEndDate,		
       ShiftEndHour,
       ScheduledPaidTime,	
       ScheduledAbsenceTime,	
       ScheduledTotalTime,		 
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
FROM #NightAgentHours	
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
       CAST(c.FirstStartTime as date) AS ShiftStartDate,					
       c.ShiftStartHour,			
       c.ShiftEndDate,		
       c.ShiftEndHour,
       c.ScheduledPaidTime,	
       c.ScheduledAbsenceTime,	
       c.ScheduledTotalTime,		
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
       NULL AS NightAgentHours 
FROM #FLEX_AND_DefaultHours c;



/*=================================================(3.1.5)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Calculate dates with sick codes and their planned data
*/



WITH get_dates_with_sick_codes AS (
    SELECT distinct dd.PERSON_ID, hd.FullDate, dd.start_month, dd.end_month
    FROM D_Date hd
    INNER JOIN (SELECT d.PERSON_ID, max(d.ShiftStartDate) as end_month, min(DATEADD(mm, DATEDIFF(m,0,d.ShiftStartDate),0)) as start_month
                FROM #tmp120 d 
                WHERE 1 = 1 AND d.PerformanceCode in (4503,3523)
                GROUP BY d.PERSON_ID) dd
    ON hd.FullDate between dd.start_month and dd.end_month
),
get_plan_data_for_sick_per_person_id AS (
    SELECT distinct d.RegisterNumber, d.LastName, d.FirstName, d.FullName, d.InterimOffice, d.Organization, d.[Address], d.ZipCode, d.Residence, d.HireDate, d.PlannedWorkDays, null as StartTime, null as EndTime, null as ShiftStartDate, null as ShiftStartHour, null as ShiftEndDate, null as ShiftEndHour, 0 as ScheduledPaidTime, 0 as ScheduledAbsenceTime, 0 as ScheduledTotalTime, d.ScheduledActivity, d.SolvusActivityGroup, d.IsAbsenceTime, d.StopDate, d.EmployeeLogin, d.EmployeeID, d.PERSON_ID, 1 as RegisterNumber_RowNr, 1 as RowNr, 0 as IsHoliDay, d.PerformanceCode, d.[Function], d.BreakSplitShift, d.EmploymentPlace, 1 as Gr, 0 as NewShiftTime, 0 as NewShift, 0 as DaysDiff, null as FirstStartTime, null as LastEndTime, null as FirstStartHour, null as LastEndHour, null as Day_FirstLastHour, d.TimeType, null as WeekDayName, 0 as FlexSaturdayHours, 0 as FlexEveningSaturdayHours, 0 as FlexEveningWorkSaturdayHours, 0 as FlexEveningWorkDayHours, 0 as FlexSundayHours, 0 as FlexHoliDayHours, 0 as DefaultHours, 0 as NightAgentHours
    FROM #tmp120 d 
    WHERE 1 = 1 AND d.PerformanceCode in (4503,3523)
)



/*=================================================(3.1.6)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Select distinct planned data for sick dates and store in #missing_sick_dates
*/



SELECT sp.RegisterNumber,
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
       concat(sc.FullDate, ' 08:00:00') as StartTime,
       concat(sc.FullDate, ' 16:30:00') as EndTime,
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
       datename(weekday, sc.FullDate) as WeekDayName,
       sp.FlexSaturdayHours,
       sp.FlexEveningSaturdayHours,
       sp.FlexEveningWorkSaturdayHours,
       sp.FlexEveningWorkDayHours,
       sp.FlexSundayHours,
       sp.FlexHoliDayHours,
       sp.DefaultHours,
       sp.NightAgentHours
INTO #missing_sick_dates
FROM get_dates_with_sick_codes sc
LEFT JOIN #tmp120 dad ON sc.PERSON_ID = dad.PERSON_ID AND sc.FullDate = dad.ShiftStartDate AND dad.PerformanceCode in (4503,3523)
INNER JOIN get_plan_data_for_sick_per_person_id sp ON sc.PERSON_ID = sp.PERSON_ID
WHERE 1 = 1 AND dad.PERSON_ID is null 	 
ORDER BY 1, 2 desc



/*=================================================(3.1.7)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Insert missing sick dates data into #tmp120
*/



INSERT INTO #tmp120
SELECT * 
FROM #missing_sick_dates 

DECLARE @PERSON_ID_curr VARCHAR(50)

DECLARE db_cursor CURSOR FOR 
SELECT distinct d.PERSON_ID as PERSON_ID_curr
FROM #tmp120 d 
WHERE 1 = 1 AND d.PerformanceCode in (4503,3523) AND d.PERSON_ID not in (1239,1248,1258)

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @PERSON_ID_curr  

WHILE @@FETCH_STATUS = 0  
BEGIN  



/*=================================================(3.1.8)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Handle cases where two sick codes exist for the same date
*/



WITH exists_2_codes AS (
    SELECT distinct sub_d.ShiftStartDate as ShiftStartDate
    FROM (SELECT d.ShiftStartDate, d.PERSON_ID, d.PerformanceCode, sum(d.ScheduledTotalTime) as TotalTime, d.weekdayname, row_number() over(partition by d.ShiftStartDate, d.PERSON_ID order by d.PerformanceCode desc) as cnt_rw
          FROM #tmp120 d
          WHERE 1 = 1 AND d.person_id = @PERSON_ID_curr AND d.weekdayname not in ('Saturday','Sunday')
          GROUP BY d.ShiftStartDate, d.PERSON_ID, d.PerformanceCode, d.weekdayname) sub_d
    WHERE 1 = 1 AND sub_d.cnt_rw = 2
)



/*=================================================(3.1.9)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Merge and update scheduled total time for sick codes
*/



MERGE INTO #tmp120 m_d
USING (
    SELECT distinct d2.ShiftStartDate, d2.PERSON_ID, d2.PerformanceCode,
           CASE WHEN d2.PERSON_ID = 1174 AND d2.ShiftStartDate = '20231103' THEN 0
                WHEN d2.PERSON_ID = 1174 AND d2.ShiftStartDate = '20231117' THEN 0
                WHEN d2.PERSON_ID = 1174 AND d2.ShiftStartDate = '20231124' THEN 0
                WHEN d2.PERSON_ID = 1174 AND d2.ShiftStartDate = '20231201' THEN 0
                WHEN d2.PERSON_ID = 1174 AND d2.ShiftStartDate = '20231215' THEN 0
                WHEN d2.PERSON_ID = 1174 AND d2.ShiftStartDate = '20231229' THEN 0
                WHEN d2.PERSON_ID = 1174 AND d2.ShiftStartDate = '20240311' THEN 0
                WHEN d2.PERSON_ID = 1174 AND d2.ShiftStartDate = '20240314' THEN 0
                WHEN d2.PERSON_ID = 1308 AND d2.ShiftStartDate = '20231117' THEN 0
                WHEN d2.ScheduledTotalTime = 0 AND [ScheduledActivity] <> 'Off Day' THEN 8
                ELSE d2.ScheduledTotalTime
           END as TotalTime, d2.weekdayname
    FROM #tmp120 d2
    WHERE 1 = 1 AND d2.PERSON_ID = @PERSON_ID_curr AND d2.weekdayname not in ('Saturday','Sunday')
    AND NOT EXISTS (SELECT 1 FROM exists_2_codes df WHERE 1 = 1 AND d2.ShiftStartDate = df.ShiftStartDate)
) f_d
ON 1 = 1 AND m_d.ShiftStartDate = f_d.ShiftStartDate AND m_d.PERSON_ID = f_d.PERSON_ID AND m_d.PerformanceCode = f_d.PerformanceCode AND m_d.PerformanceCode in (4503,3523)
WHEN MATCHED THEN UPDATE 
SET m_d.ScheduledTotalTime = f_d.TotalTime;

FETCH NEXT FROM db_cursor INTO @PERSON_ID_curr 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor



/*=================================================(3.2.0)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Remove records with 'Off Day' activity from #tmp120
*/



DELETE FROM #tmp120 WHERE [ScheduledActivity] = 'Off Day' 



/*=================================================(3.2.1)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Set default hours to zero if null or less than 0.0001
*/



UPDATE #tmp120
SET DefaultHours = 0.000000
WHERE DefaultHours < 0.0001 OR DefaultHours is null



/*=================================================(3.2.2)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Set FlexSaturdayHours to zero if null or less than 0.0001
*/



UPDATE #tmp120
SET FlexSaturdayHours = 0.000000
WHERE FlexSaturdayHours < 0.0001 OR FlexSaturdayHours is null



/*=================================================(3.2.3)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Set FlexEveningSaturdayHours to zero if null or less than 0.0001
*/



UPDATE #tmp120
SET FlexEveningSaturdayHours = 0.000000
WHERE FlexEveningSaturdayHours < 0.0001 OR FlexEveningSaturdayHours is null



/*=================================================(3.2.4)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Set FlexEveningWorkSaturdayHours to zero if null or less than 0.0001
*/



UPDATE #tmp120
SET FlexEveningWorkSaturdayHours = 0.000000
WHERE FlexEveningWorkSaturdayHours < 0.0001 OR FlexEveningWorkSaturdayHours is null



/*=================================================(3.2.5)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Set FlexEveningWorkDayHours to zero if null or less than 0.0001
*/



UPDATE #tmp120
SET FlexEveningWorkDayHours = 0.000000
WHERE FlexEveningWorkDayHours < 0.0001 OR FlexEveningWorkDayHours is null



/*=================================================(3.2.6)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Set FlexSundayHours to zero if null or less than 0.0001
*/



UPDATE #tmp120
SET FlexSundayHours = 0.000000
WHERE FlexSundayHours < 0.0001 OR FlexSundayHours is null



/*=================================================(3.2.7)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Set FlexHoliDayHours to zero if null or less than 0.0001
*/



UPDATE #tmp120
SET FlexHoliDayHours = 0.000000
WHERE FlexHoliDayHours < 0.0001 OR FlexHoliDayHours is null



/*=================================================(3.2.8)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Set NightAgentHours to zero if null or less than 0.0001
*/



UPDATE #tmp120
SET NightAgentHours = 0.000000   
WHERE NightAgentHours < 0.0001 OR NightAgentHours is null  
    

	
/*=================================================(3.2.9)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Calculate total workdays for each employee and store in #TotalWorkDays1 and #TotalWorkDays2
*/



SELECT distinct EmployeeLogin, cast(FirstStartTime as date) FirstStart_Date
INTO #TotalWorkDays1            
FROM #tmp120
WHERE SolvusActivityGroup = 'Prestatie' AND EmployeeLogin <> ''

SELECT EmployeeLogin, count(*) AS TotalWorkDays
INTO #TotalWorkDays2
FROM #TotalWorkDays1
GROUP BY EmployeeLogin
ORDER BY EmployeeLogin



/*=================================================(3.3.0)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Combine total workdays data with main dataset and store in #tmp121
*/



SELECT T1.*, T2.TotalWorkDays 
INTO #tmp121
FROM #tmp120 T1
LEFT JOIN #TotalWorkDays2 T2 ON T1.EmployeeLogin = T2.EmployeeLogin



/*=================================================(3.3.1)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Store final dataset in #tmp122
*/



SELECT *
INTO #tmp122
FROM #tmp121


	
/*=================================================(3.3.2)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Drop unnecessary temporary tables if they exist
*/



IF (object_id('tempdb..#Basis') is not null) DROP table #Basis;
IF (object_id('tempdb..#ReturnData2') is not null) DROP table #ReturnData2;
IF (object_id('tempdb..#ReturnData3') is not null) DROP table #ReturnData3;



/*=================================================(3.3.3)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Create #Basis table with final selected columns and formatted data
*/



SELECT RegisterNumber, LastName, FirstName, FullName, InterimOffice, 
       SUBSTRING(Day_FirstLastHour, 1 , 5) + '-' + SUBSTRING(Day_FirstLastHour, 12, 5) AS Day_FirstLastHour,
       Organization, [Address], ZipCode, Residence, HireDate, StartTime, EndTime, ShiftStartDate,
       FORMAT(cast(ShiftStartHour as time), N'hh:mm') AS ShiftStartHour,	
       ShiftEndDate,	
       FORMAT(cast(ShiftEndHour as time), N'hh:mm') AS ShiftEndHour,			
       ScheduledPaidTime, ScheduledAbsenceTime, ScheduledTotalTime, ScheduledActivity, SolvusActivityGroup, IsAbsenceTime, StopDate, EmployeeLogin, EmployeeID, PERSON_ID, RegisterNumber_RowNr, RowNr,	
       ISNULL(IsHoliDay, '0') AS IsHoliDay,	
       PerformanceCode, [Function], Gr, NewShiftTime, NewShift, DaysDiff, FirstStartTime, LastEndTime,	
       FORMAT(cast(FirstStartHour as time), N'hh:mm') AS FirstStartHour,			
       FORMAT(cast(LastEndHour as time), N'hh:mm') AS LastEndHour,			
       TimeType, WeekDayName,	
       CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexSaturdayHours)) AS FlexSaturdayHours,		
       CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexEveningSaturdayHours)) AS FlexEveningSaturdayHours,
       CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexEveningWorkSaturdayHours)) AS FlexEveningWorkSaturdayHours,
       CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexEveningWorkDayHours)) AS FlexEveningWorkDayHours,
       CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexSundayHours)) AS FlexSundayHours,
       CONVERT(decimal(15,11), CONVERT(varbinary(20), FlexHoliDayHours)) AS FlexHoliDayHours,
       DefaultHours AS DefaultHours,
       CONVERT(decimal(15,11), CONVERT(varbinary(20), NightAgentHours)) AS NightAgentHours,
       PlannedWorkDays, TotalWorkDays, BreakSplitShift, EmploymentPlace
INTO #Basis	
FROM #tmp122


	
/*=================================================(3.3.3)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Truncate and insert final data into PerformanceSolvus table
*/



TRUNCATE TABLE [DwH].[dbo].[PerformanceSolvus]
INSERT INTO [DwH].[dbo].[PerformanceSolvus]
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
FROM (SELECT iif(RegisterNumber='' OR isnull(RegisterNumber,'Y')='Y',  'NoNr', RegisterNumber) AS RegisterNumber,
             ShiftStartDate, PerformanceCode, ScheduledActivity, PERSON_ID, FirstName, LastName, EmployeeLogin,
             SUM(ScheduledTotalTime) AS ScheduledTotalTime
      FROM #tmp122
      WHERE LOWER(InterimOffice) like 'vast%' -- For KLX take only VAST (no interim)
      GROUP BY iif(RegisterNumber='' OR isnull(RegisterNumber,'Y')='Y',  'NoNr', RegisterNumber), ShiftStartDate, PerformanceCode, ScheduledActivity, PERSON_ID, FirstName, LastName, EmployeeLogin) d



/*=================================================(3.3.4)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Return for KLX
*/



IF @LongShort = 'KLX'
BEGIN	
    RETURN;
END



/*=================================================(3.3.5)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Return detailed data for 'basis'
*/



IF @LongShort = 'basis'
BEGIN	
    SELECT RegisterNumber, LastName, FirstName, FullName, InterimOffice, Day_FirstLastHour, Organization, [Address], ZipCode, Residence, HireDate, StartTime, EndTime, ShiftStartDate, ShiftStartHour, ShiftEndDate, ShiftEndHour, ScheduledPaidTime, ScheduledAbsenceTime, ScheduledTotalTime, ScheduledActivity, SolvusActivityGroup, IsAbsenceTime, StopDate, EmployeeLogin, EmployeeID, PERSON_ID, RegisterNumber_RowNr, RowNr, IsHoliDay, PerformanceCode, [Function], Gr, NewShiftTime, NewShift, DaysDiff, FirstStartTime, LastEndTime, FirstStartHour, LastEndHour, TimeType, WeekDayName, FlexSaturdayHours, FlexEveningSaturdayHours, FlexEveningWorkSaturdayHours, FlexEveningWorkDayHours, FlexSundayHours, FlexHoliDayHours, DefaultHours, NightAgentHours, PlannedWorkDays, TotalWorkDays, BreakSplitShift, EmploymentPlace
    FROM #Basis 
    RETURN;
END



/*=================================================(3.3.6)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Return summarized data for 'long' not in specific date spans
*/



IF @LongShort = 'long' AND @DateSpanStr NOT IN ('PWc','PMc','CWc','CMc','NWc','NMc')
BEGIN
    SELECT RegisterNumber AS RR, LastName AS Naam, FirstName AS Voornaam, InterimOffice AS [Temp kantoor], ShiftStartDate AS Datum, BreakSplitShift AS BreakSplitShift,
           SUM(ScheduledTotalTime) AS [Gepresteerde Uren], SUM(FlexSaturdayHours) AS FlexSaturdayHours, SUM(FlexSundayHours) AS FlexSundayHours, SUM(FlexEveningWorkDayHours) AS FlexEveningWorkDayHours, SUM(FlexEveningSaturdayHours) AS FlexEveningSaturdayHours, SUM(FlexEveningWorkSaturdayHours) AS FlexEveningWorkSaturdayHours, SUM(FlexHoliDayHours) AS FlexHolidayHours, SUM(NightAgentHours) AS NightAgentHours, SUM(DefaultHours) AS DefaultHours
    INTO #FLEX_DayLevel			
    FROM #tmp121
    GROUP BY RegisterNumber, LastName, FirstName, InterimOffice, ShiftStartDate, BreakSplitShift



/*=================================================(3.3.7)=================================================
-- Date: 13-Jun-2024
    -- Description: Stefan Damyanov - Create #Absence_DayLevel with pivoted absence data
	*/
	
	
	
    SELECT RegisterNumber AS RR, ShiftStartDate AS Datum,
           (isnull([Langdurig ziek],0) + isnull([Ziek],0) + isnull([Familiaal verlof],0) + isnull([Feestdag],0) + isnull([vakantie],0) + isnull([Bevallingsverlof],0) + isnull([ADV],0) + isnull([Ongewettigd afwezig],0) + isnull([Klein Verlet],0) + isnull([Ouderschapsverlof],0)) AS [Afwezige uren],
           isnull([Feestdag],0) AS [Feestdag], isnull([Ziek],0) AS [Ziek], isnull([ADV],0) AS [ADV], isnull([vakantie],0) AS [vakantie], isnull([Ongewettigd afwezig],0) AS [Ongewettigd afwezig], isnull([Bevallingsverlof],0) AS [Bevallingsverlof], isnull([Educatief verlof],0) AS [Educatief verlof], isnull([Familiaal verlof],0) AS [Familiaal verlof], isnull([Klein Verlet],0) AS [Klein Verlet], isnull([Langdurig ziek],0) AS [Langdurig ziek], isnull([Ouderschapsverlof],0) AS [Ouderschapsverlof]
    INTO #Absence_DayLevel	
    FROM (
        SELECT SolvusActivityGroup, RegisterNumber, ShiftStartDate,
               CASE WHEN ScheduledTotalTime between 0.99 and 1.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 1.99 and 2.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 2.99 and 3.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 3.99 and 4.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 4.99 and 5.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 5.99 and 6.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 6.99 and 7.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 7.99 and 8.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 8.99 and 9.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 9.99 and 10.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 10.99 and 11.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 11.99 and 12.00 THEN round(ScheduledTotalTime,0)
                    WHEN ScheduledTotalTime between 12.99 and 13.00 THEN round(ScheduledTotalTime,0)
                    ELSE ScheduledTotalTime
               END as ScheduledTotalTime
        FROM #tmp121
        WHERE SolvusActivityGroup <> 'Prestatie' AND RegisterNumber <> ''
    ) up
    PIVOT (
        SUM(ScheduledTotalTime) FOR SolvusActivityGroup IN ([Feestdag], [Ziek], [ADV], [vakantie], [Ongewettigd afwezig], [Bevallingsverlof], [Educatief verlof], [Familiaal verlof], [Klein Verlet], [Langdurig ziek], [Ouderschapsverlof])
    ) AS pvt	
    ORDER BY RegisterNumber, ShiftStartDate



/*=================================================(3.3.8)=================================================
-- Date: 13-Jun-2024
    -- Description: Stefan Damyanov - Combine flex and absence data
	*/
	
	
	
    SELECT T1.*, isnull(T2.[Afwezige uren],0) [Afwezige uren], isnull(T2.[Feestdag],0) [Feestdag], isnull(T2.[Ziek],0) [Ziek], isnull(T2.[ADV],0) [ADV], isnull(T2.[vakantie],0) [vakantie], isnull(T2.[Ongewettigd afwezig],0) [Ongewettigd afwezig], isnull(T2.[Bevallingsverlof],0) [Bevallingsverlof], isnull(T2.[Educatief verlof],0) [Educatief verlof], isnull(T2.[Familiaal verlof],0) [Familiaal verlof], isnull(T2.[Klein Verlet],0) [Klein Verlet], isnull(T2.[Langdurig ziek],0) [Langdurig ziek], isnull(T2.[Ouderschapsverlof],0) [Ouderschapsverlof]
    FROM #FLEX_DayLevel T1		
    FULL JOIN #Absence_DayLevel T2 ON T1.RR = T2.RR AND T1.Datum = T2.Datum
    RETURN;
END	



/*=================================================(3.3.9)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Drop #ReturnDataShort if it exists
*/



IF (object_id('tempdb..#ReturnDataShort') is not null) DROP table #ReturnDataShort;



/*=================================================(3.4.0)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Return summarized data for 'short' not in specific date spans
*/



IF @LongShort = 'short' AND @DateSpanStr NOT IN ('PWc','PMc','CWc','CMc','NWc','NMc')	
BEGIN	
    SELECT d1.col_1 AS 'Rijksregisternummer', 
           d1.col_2 AS [Naam, Voornaam], 
           d1.col_3 AS 'Project',	 
           d1.col_4 AS 'Function',
           d1.col_5 AS [Temp kantoor],
           d1.col_6 AS 'Datum',
           d1.col_7 AS 'Datum_',
           CASE WHEN d1.col_8 between 0.99 and 1.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 1.99 and 2.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 2.99 and 3.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 3.99 and 4.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 4.99 and 5.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 5.99 and 6.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 6.99 and 7.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 7.99 and 8.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 8.99 and 9.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 9.99 and 10.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 10.99 and 11.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 11.99 and 12.00 THEN round(d1.col_8,0)
                WHEN d1.col_8 between 12.99 and 13.00 THEN round(d1.col_8,0)
                ELSE d1.col_8
           END AS [Aantal Werkuren],
           d1.col_9 AS 'BreakSplitShift',
           d1.col_10 AS 'StartUur1',
           d1.col_11 AS 'EindUur1'
    INTO #ReturnDataShort
    FROM (SELECT RegisterNumber AS col_1, 
                 LastName +','+ FirstName AS col_2, 
                 Organization AS col_3,	 
                 [Function] AS col_4,
                 InterimOffice AS col_5,
                 ShiftStartDate AS col_6,
                 CONVERT(varchar,ShiftStartDate, 103) AS col_7,
                 SUM(ScheduledTotalTime) AS col_8,
                 BreakSplitShift AS col_9,
                 FirstStartHour AS col_10,
                 LastEndHour AS col_11		
          FROM #tmp122
          WHERE 1=1
          GROUP BY RegisterNumber, LastName +','+ FirstName, Organization, [Function], [EmploymentPlace], InterimOffice, ShiftStartDate, CONVERT(varchar,ShiftStartDate, 103), ShiftStartDate, FirstStartHour, LastEndHour, BreakSplitShift) d1	

    SELECT * FROM #ReturnDataShort	
    RETURN;	
END 

/*=================================================(3.4.1)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Drop #ReturnDataShortCumul if it exists
*/



IF (object_id('tempdb..#ReturnDataShortCumul') is not null) DROP table #ReturnDataShortCumul;



/*=================================================(3.4.2)=================================================
-- Date: 13-Jun-2024
-- Description: Stefan Damyanov - Return summarized cumulative data for specific date spans
*/



IF @DateSpanStr IN ('PWc','PMc','CWc','CMc','NWc','NMc')
BEGIN	
    SELECT d2.col_1 AS Rijksregisternummer,
           d2.col_2 AS [Naam, Voornaam], 
           d2.col_3 AS Project,	 
           d2.col_4 AS [Function],
           d2.col_5 AS [EmploymentPlace],
           d2.col_6 AS [Temp kantoor],		
           CASE WHEN d2.col_7 between 0.99 and 1.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 1.99 and 2.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 2.99 and 3.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 3.99 and 4.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 4.99 and 5.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 5.99 and 6.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 6.99 and 7.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 7.99 and 8.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 8.99 and 9.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 9.99 and 10.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 10.99 and 11.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 11.99 and 12.00 THEN round(d2.col_7,0)
                WHEN d2.col_7 between 12.99 and 13.00 THEN round(d2.col_7,0)
                ELSE d2.col_7
           END AS [Aantal Werkuren],	
           d2.col_8 AS FromDate,
           d2.col_9 AS ToDate 				
    INTO #ReturnDataShortCumul
    FROM (SELECT RegisterNumber AS col_1, 
                 LastName +','+ FirstName AS col_2, 
                 Organization AS col_3,	 
                 [Function] AS col_4,
                 [EmploymentPlace] AS col_5,
                 InterimOffice AS col_6,			
                 SUM(ScheduledTotalTime) AS col_7,			
                 @FromDate AS col_8,
                 @ToDate AS col_9 					
          FROM #tmp122
          GROUP BY RegisterNumber, LastName +','+ FirstName, Organization, [Function], [EmploymentPlace], InterimOffice) d2
    ORDER BY d2.col_1

    SELECT * FROM #ReturnDataShortCumul
END 

END