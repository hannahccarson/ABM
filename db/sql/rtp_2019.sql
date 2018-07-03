SET NOCOUNT ON;

-- Create rtp_2019 schema
IF NOT EXISTS (SELECT schema_name FROM information_schema.schemata WHERE schema_name='rtp_2019')
EXEC ('CREATE SCHEMA [rtp_2019]')
GO

-- Add metadata for [rtp_2019]
IF EXISTS(SELECT * FROM [db_meta].[data_dictionary] WHERE [ObjectType] = 'SCHEMA' AND [FullObjectName] = '[rtp_2019]' AND [PropertyName] = 'MS_Description')
EXECUTE [db_meta].[drop_xp] 'rtp_2019', 'MS_Description'
EXECUTE [db_meta].[add_xp] 'rtp_2019', 'MS_Description', 'schema to hold all objects associated with the 2019 Regional Transportation Plan'
GO




-- grant read/execute permissions to abm_user role
GRANT EXECUTE ON SCHEMA :: [rtp_2019] TO [abm_user]
GRANT SELECT ON SCHEMA :: [rtp_2019] TO [abm_user]
GRANT VIEW DEFINITION ON SCHEMA :: [rtp_2019] TO [abm_user]




-- Create stored procedure for performance metric #1a
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_1a]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_1a]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_1a]
	@scenario_id integer
AS

/*	Author: Ziying Ouyang and Gregor Schroeder
	Date: Revised 4/6/2018
	Description: Performance Measure 1A, Daily vehicle delay per capita (minutes)
		formerly Performance Measure 1B in the 2015 RTP
		sum of link level vehicle flows multiplied by difference
		between congested and free flow travel time and then divided
		by total synthetic population */

-- subquery for total synthetic population
DECLARE @population integer = (SELECT SUM([weight_person]) FROM [dimension].[person] WHERE [scenario_id] = @scenario_id)

SELECT
	@scenario_id AS [scenario_id]
	,SUM(([time] - ([tm] + [tx])) * [flow]) / @population AS [veh_delay_per_capita]
FROM
	[fact].[hwy_flow]
INNER JOIN
	[dimension].[hwy_link_ab_tod]
ON
	[hwy_flow].[scenario_id] = [hwy_link_ab_tod].[scenario_id]
	AND [hwy_flow].[hwy_link_ab_tod_id] = [hwy_link_ab_tod].[hwy_link_ab_tod_id]
WHERE
	[hwy_flow].[scenario_id] = @scenario_id
	AND [hwy_link_ab_tod].[scenario_id] = @scenario_id
	AND ([time] - ([tm] + [tx])) >= 0
GO

-- Add metadata for [rtp_2019].[sp_pm_1a]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_1a', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_1a', 'MS_Description', 'performance metric 1a'
GO




-- Create stored procedure for performance metric #2a
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_2a]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_2a]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_2a]
	@scenario_id integer,
	@uats bit = 0, -- switch to limit origin and/or destination geographies to UATS zones
	@work bit = 0 -- switch to limit trip purpose to work
AS

/*	Author: Gregor Schroeder
	Date: Revised 4/21/2018
	Description: Percent of trips by walk, bike, transit, and carpool (work trips and all trips) regionwide and within
		Urban Area Transit Strategy (UATS) districts */

SET NOCOUNT ON;

-- get mgras that are fully contained within UATS districts
DECLARE @uats_mgras TABLE ([mgra] nchar(15) PRIMARY KEY NOT NULL)
INSERT INTO @uats_mgras
SELECT CONVERT(nchar, [mgra]) AS [mgra] FROM
OPENQUERY(
	[sql2014b8],
	'SELECT [mgra] FROM [lis].[gis].[uats2014],[lis].[gis].[MGRA13PT]
		WHERE [uats2014].[Shape].STContains([MGRA13PT].[Shape]) = 1');

-- get person trips by mode
-- for resident models only (Individual, Internal-External, Joint)
-- potentially filtered by destination work purpose or mgra in UATS district
DECLARE @aggregated_trips TABLE (
	[mode_aggregate] nchar(15) NOT NULL,
	[person_trips] float NOT NULL)
INSERT INTO @aggregated_trips
SELECT
	ISNULL(CASE	WHEN [mode_trip_description] IN ('Drive Alone Non-Toll',
												 'Drive Alone Toll Eligible')
				THEN 'Drive Alone'
				WHEN [mode_trip_description] IN ('Shared Ride 2 Non-Toll',
											 	 'Shared Ride 2 Toll Eligible',
												 'Shared Ride 3 Non-Toll',
												 'Shared Ride 3 Toll Eligible')
				THEN 'Shared Ride'
				WHEN [mode_trip_description] IN ('Kiss and Ride to Transit - Local Bus and Premium Transit',
												 'Kiss and Ride to Transit - Local Bus Only',
												 'Kiss and Ride to Transit - Premium Transit Only' ,
												 'Park and Ride to Transit - Local Bus and Premium Transit',
												 'Park and Ride to Transit - Local Bus Only',
												 'Park and Ride to Transit - Premium Transit Only',
												 'Walk to Transit - Local Bus and Premium Transit',
												 'Walk to Transit - Local Bus Only',
												 'Walk to Transit - Premium Transit Only')
				THEN 'Transit'
				ELSE [mode_trip_description] END, 'Total') AS [mode_aggregate]
	,SUM([weight_person_trip]) AS [person_trips]
FROM
	[fact].[person_trip]
INNER JOIN
	[dimension].[model_trip]
ON
	[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
INNER JOIN
	[dimension].[mode_trip]
ON
	[person_trip].[mode_trip_id] = [mode_trip].[mode_trip_id]
INNER JOIN
	[dimension].[purpose_trip_destination]
ON
	[person_trip].[purpose_trip_destination_id] = [purpose_trip_destination].[purpose_trip_destination_id]
INNER JOIN
	[dimension].[geography_trip_origin]
ON
	[person_trip].[geography_trip_origin_id] = [geography_trip_origin].[geography_trip_origin_id]
INNER JOIN
	[dimension].[geography_trip_destination]
ON
	[person_trip].[geography_trip_destination_id] = [geography_trip_destination].[geography_trip_destination_id]
LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
	@uats_mgras AS [uats_mgras_origin_xref]
ON
	[geography_trip_origin].[trip_origin_mgra_13] = [uats_mgras_origin_xref].[mgra]
LEFT OUTER JOIN -- keep as outer join since where clause is OR condition
	@uats_mgras AS [uats_mgras_dest_xref]
ON
	[geography_trip_destination].[trip_destination_mgra_13] = [uats_mgras_dest_xref].[mgra]
WHERE
	[scenario_id] = @scenario_id
	AND [model_trip].[model_trip_description] IN ('Individual',
												  'Internal-External', -- can use external TAZs but they will not be in UATS districts
												  'Joint') -- resident models only
	AND ((@work = 1 AND [purpose_trip_destination].[purpose_trip_destination_description] = 'Work')
			OR @work = 0) -- if work trips then filter by destination work purpose
	AND ((@uats = 1 AND ([uats_mgras_origin_xref].[mgra] IS NOT NULL OR [uats_mgras_dest_xref].[mgra] IS NOT NULL))
			OR @uats = 0) -- if UATS districts option selected only count trips originating and/or ending in UATS mgras
GROUP BY
	CASE	WHEN [mode_trip_description] IN ('Drive Alone Non-Toll',
											 'Drive Alone Toll Eligible')
			THEN 'Drive Alone'
			WHEN [mode_trip_description] IN ('Shared Ride 2 Non-Toll',
											 'Shared Ride 2 Toll Eligible',
											 'Shared Ride 3 Non-Toll',
											 'Shared Ride 3 Toll Eligible')
			THEN 'Shared Ride'
			WHEN [mode_trip_description] IN ('Kiss and Ride to Transit - Local Bus and Premium Transit',
											 'Kiss and Ride to Transit - Local Bus Only',
											 'Kiss and Ride to Transit - Premium Transit Only' ,
											 'Park and Ride to Transit - Local Bus and Premium Transit',
											 'Park and Ride to Transit - Local Bus Only',
											 'Park and Ride to Transit - Premium Transit Only',
											 'Walk to Transit - Local Bus and Premium Transit',
											 'Walk to Transit - Local Bus Only',
											 'Walk to Transit - Premium Transit Only')
			THEN 'Transit'
			ELSE [mode_trip_description] END
WITH ROLLUP

SELECT
	@scenario_id AS [scenario_id]
	,[mode_aggregate]
	,100.0 * [person_trips] / (SELECT [person_trips] FROM @aggregated_trips WHERE [mode_aggregate] = 'Total') AS [pct_person_trips]
	,[person_trips]
FROM
	@aggregated_trips

GO

-- Add metadata for [rtp_2019].[sp_pm_2a]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_2a', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_2a', 'MS_Description', 'performance metric 2a'
GO




-- Create stored procedure for performance metric #2b
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_2b]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_2b]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_2b]
	@scenario_id integer
AS

/*	Author: Gregor Schroeder
	Date: 4/17/2018
	Description: Performance Measure 2b, VMT per capita and regionwide
		similar to sp_eval_vmt in the 2015 RTP */

-- subquery for total synthetic population
DECLARE @population integer = (SELECT SUM([weight_person]) FROM [dimension].[person] WHERE [scenario_id] = @scenario_id)

SELECT
	@scenario_id AS [scenario_id]
	,SUM([hwy_flow].[flow] * [hwy_link].[length_mile]) / @population AS [vmt_per_capita]
	,SUM([hwy_flow].[flow] * [hwy_link].[length_mile]) AS [vmt]
FROM
	[fact].[hwy_flow]
INNER JOIN
	[dimension].[hwy_link]
ON
	[hwy_flow].[scenario_id] = [hwy_link].[scenario_id]
	AND [hwy_flow].[hwy_link_id] = [hwy_link].[hwy_link_id]
WHERE
	[hwy_flow].[scenario_id] = @scenario_id
	AND [hwy_link].[scenario_id] = @scenario_id
GO

-- Add metadata for [rtp_2019].[sp_pm_2b]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_2b', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_2b', 'MS_Description', 'performance metric 2b'
GO




-- Create stored procedure for performance metric #6a
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_6a]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_6a]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_6a]
	@scenario_id integer,
	@senior bit = 0, -- indicator to use senior population segmentation
	@minority bit = 0, -- indicator to use minority population segmentation
	@low_income bit = 0 -- indicator to use low income population segmentation
AS

/*	Author: Gregor Schroeder
	Date: Revised 4/17/2018
	Description: Time engaged in transportation-related physical activity per capita (minutes)
		similar to Performance Measure 7F in the 2015 RTP
*/

IF CONVERT(int, @senior) + CONVERT(int, @minority) + CONVERT(int, @low_income) > 1
BEGIN
RAISERROR ('Select only one population segmentation.', 16, 1)
RETURN -1
END;

with [coc_pop] AS (
	SELECT
		[person_id]
		,[person].[weight_person]
		,CASE WHEN [person].[age] >= 75 THEN 'Senior' ELSE 'Non-Senior' END AS [senior]
		,CASE	WHEN [person].[race] IN ('Some Other Race Alone',
											'Asian Alone',
											'Black or African American Alone',
											'Two or More Major Race Groups',
											'Native Hawaiian and Other Pacific Islander Alone',
											'American Indian and Alaska Native Tribes specified; or American Indian or Alaska Native, not specified and no other races')
						OR [person].[hispanic] = 'Hispanic' THEN 'Minority'
					ELSE 'Non-Minority' END AS [minority]
		,CASE WHEN [household].[poverty] <= 2 THEN 'Low Income' ELSE 'Non-Low Income' END AS [low_income]
	FROM
		[dimension].[person]
	INNER JOIN
		[dimension].[household]
	ON
		[person].[scenario_id] = [household].[scenario_id]
		AND [person].[household_id] = [household].[household_id]
	WHERE
		[person].[scenario_id] = @scenario_id
		AND [household].[scenario_id] = @scenario_id),
[agg_coc_pop] AS (
	SELECT
		ISNULL(CASE	WHEN @senior = 1 THEN [senior]
						WHEN @minority = 1 THEN [minority]
						WHEN @low_income = 1 THEN [low_income]
						ELSE 'All' END, 'Total') AS [pop_segmentation]
		,SUM([weight_person]) AS [weight_person]
	FROM
		[coc_pop]
	GROUP BY
		CASE	WHEN @senior = 1 THEN [senior]
				WHEN @minority = 1 THEN [minority]
				WHEN @low_income = 1 THEN [low_income]
				ELSE 'All' END
	WITH ROLLUP),
[physical_activity] AS (
	SELECT
		ISNULL(CASE	WHEN @senior = 1 THEN [senior]
						WHEN @minority = 1 THEN [minority]
						WHEN @low_income = 1 THEN [low_income]
						ELSE 'All' END, 'Total') AS [pop_segmentation]
		,SUM([time_walk] + [time_bike]) AS [physical_activity_minutes] -- time_walk includes transit walk times
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[model_trip]
	ON
		[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
	INNER JOIN
		[coc_pop]
	ON
		[person_trip].[scenario_id] = @scenario_id
		AND [person_trip].[person_id] = [coc_pop].[person_id]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
		AND [model_trip].[model_trip_description] IN ('Individual',
													  'Internal-External',
													  'Joint') -- synthetic population only used in resident models
	GROUP BY
		CASE	WHEN @senior = 1 THEN [senior]
				WHEN @minority = 1 THEN [minority]
				WHEN @low_income = 1 THEN [low_income]
				ELSE 'All' END
	WITH ROLLUP)
SELECT
	@scenario_id AS [scenario_id]
	,[physical_activity].[pop_segmentation]
	,[physical_activity].[physical_activity_minutes] / [agg_coc_pop].[weight_person] AS [physical_activity_per_capita]
FROM
	[physical_activity]
INNER JOIN
	[agg_coc_pop]
ON
	[physical_activity].[pop_segmentation] = [agg_coc_pop].[pop_segmentation]
ORDER BY
	[physical_activity].[pop_segmentation]
GO

-- Add metadata for [rtp_2019].[sp_pm_6a]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_6a', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_6a', 'MS_Description', 'performance metric 6a'
GO




-- Create stored procedure for performance metric #7a using auto skims
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_7a_auto]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_7a_auto]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_7a_auto]
	@scenario_id integer,
	@uats bit = 0 -- switch to limit origin and destination geographies to UATS zones
AS

/*	Author: Gregor Schroeder
	Date: 4/25/2018
	Description: Percent of population within 30 minutes jobs and higher
		education via driving (total population, disadvantaged
		communities (seniors, low-income, and minority) and non-disadvantaged
		communities). Can be run just for origin and destinations
		within UATS districts.
		Note this measure has been adjusted to be the percent of total
		employment and enrollment in the region accessible by the average person
		similar to Highway Evaluation Criteria 9a and Performance Measure 8ab_auto in the 2015 RTP */

SET NOCOUNT ON;

-- get mgras that are fully contained within UATS districts
DECLARE @uats_mgras TABLE ([mgra] nchar(15) PRIMARY KEY NOT NULL)
INSERT INTO @uats_mgras
SELECT CONVERT(nchar, [mgra]) AS [mgra] FROM
OPENQUERY(
	[sql2014b8],
	'SELECT [mgra] FROM [lis].[gis].[uats2014],[lis].[gis].[MGRA13PT]
		WHERE [uats2014].[Shape].STContains([MGRA13PT].[Shape]) = 1');

-- for resident models only (Individual, Internal-External, Joint)
-- get the weighted average by auto person trips of TAZ-TAZ trip time
-- note if a TAZ-TAZ pair does not appear in this trip list it is not considered
-- keeping only trip times under 30 minutes
with [skims] AS (
	SELECT
		[geography_trip_origin].[trip_origin_taz_13]
		,[geography_trip_destination].[trip_destination_taz_13]
		,SUM(([weight_person_trip] * [time_total])) / SUM([weight_person_trip]) AS [time_avg]
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[model_trip]
	ON
		[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
	INNER JOIN
		[dimension].[mode_trip]
	ON
		[person_trip].[mode_trip_id] = [mode_trip].[mode_trip_id]
	INNER JOIN
		[dimension].[geography_trip_origin]
	ON
		[person_trip].[geography_trip_origin_id] = [geography_trip_origin].[geography_trip_origin_id]
	INNER JOIN
		[dimension].[geography_trip_destination]
	ON
		[person_trip].[geography_trip_destination_id] = [geography_trip_destination].[geography_trip_destination_id]
	LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
		@uats_mgras AS [uats_origin_xref]
	ON
		[geography_trip_origin].[trip_origin_mgra_13] = [uats_origin_xref].[mgra]
	LEFT OUTER JOIN -- keep as outer join since where clause is OR condition
		@uats_mgras AS [uats_dest_xref]
	ON
		[geography_trip_destination].[trip_destination_mgra_13] = [uats_dest_xref].[mgra]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
		AND [model_trip].[model_trip_description] IN ('Individual',
													  'Internal-External',
													  'Joint') -- resident models only
		AND [mode_trip].[mode_trip_description] IN ('Drive Alone Non-Toll',
													'Drive Alone Toll Eligible',
													'Shared Ride 2 Non-Toll',
													'Shared Ride 2 Toll Eligible',
													'Shared Ride 3 Non-Toll',
													'Shared Ride 3 Toll Eligible') -- auto modes only
		AND ((@uats = 1 AND ([uats_origin_xref].[mgra] IS NOT NULL AND [uats_dest_xref].[mgra] IS NOT NULL))
			OR @uats = 0) -- if UATS districts option selected only count trips originating and ending in UATS mgras
	GROUP BY
		[geography_trip_origin].[trip_origin_taz_13]
		,[geography_trip_destination].[trip_destination_taz_13]
	HAVING
		SUM(([weight_person_trip] * [time_total])) / SUM([weight_person_trip]) <= 30), -- remove skims over 30 minutes
-- get the amount of jobs and college+ education enrollment within each TAZ
-- adult school enrollment is included because the model sends university students to this enrollment
[destinations] AS (
	SELECT
		[geography].[taz_13]
		,SUM([emp_total] + [collegeenroll] + [othercollegeenroll] + [adultschenrl]) AS [emp_educ]
	FROM
		[fact].[mgra_based_input]
	INNER JOIN
		[dimension].[geography]
	ON
		[mgra_based_input].[geography_id] = [geography].[geography_id]
	LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
		@uats_mgras AS [uats_xref]
	ON
		[geography].[mgra_13] = [uats_xref].[mgra]
	WHERE
		[mgra_based_input].[scenario_id] = @scenario_id
		AND ((@uats = 1 AND [uats_xref].[mgra] IS NOT NULL)
			OR @uats = 0) -- if UATS districts option selected only count destinations within UATS district
	GROUP BY
		[geography].[taz_13]
	HAVING
		SUM([emp_total] + [collegeenroll] + [othercollegeenroll] + [adultschenrl]) > 0),
-- get population by Community of Concern/Non-Community of Concern
-- within each TAZ
[taz_pop] AS (
	SELECT
		[taz_13]
		,[pop]
		,[pop_senior]
		,[pop] - [pop_senior] AS [pop_non_senior]
		,[pop_minority]
		,[pop] - [pop_minority] AS [pop_non_minority]
		,[pop_low_income]
		,[pop] - [pop_low_income] AS [pop_non_low_income]
	FROM (
		SELECT
			[geography_household_location].[household_location_taz_13] AS [taz_13]
			,SUM([person].[weight_person]) AS [pop]
			,SUM(CASE WHEN [person].[age] >= 75 THEN [person].[weight_person] ELSE 0 END) AS [pop_senior]
			,SUM(CASE	WHEN [person].[race] IN ('Some Other Race Alone',
												 'Asian Alone',
												 'Black or African American Alone',
												 'Two or More Major Race Groups',
												 'Native Hawaiian and Other Pacific Islander Alone',
												 'American Indian and Alaska Native Tribes specified; or American Indian or Alaska Native, not specified and no other races')
							 OR [person].[hispanic] = 'Hispanic' THEN [person].[weight_person]
							 ELSE 0 END) AS [pop_minority]
			,SUM(CASE WHEN [household].[poverty] <= 2 THEN [person].[weight_person] ELSE 0 END) AS [pop_low_income]
		FROM
			[dimension].[person]
		INNER JOIN
			[dimension].[household]
		ON
			[person].[scenario_id] = [household].[scenario_id]
			AND [person].[household_id] = [household].[household_id]
		INNER JOIN
			[dimension].[geography_household_location]
		ON
			[household].[geography_household_location_id] = [geography_household_location].[geography_household_location_id]
		LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
			@uats_mgras AS [uats_xref]
		ON
			[geography_household_location].[household_location_mgra_13] = [uats_xref].[mgra]
		WHERE
			[person].[scenario_id] = @scenario_id
			AND [household].[scenario_id] = @scenario_id
			AND ((@uats = 1 AND [uats_xref].[mgra] IS NOT NULL)
			    OR @uats = 0) -- if UATS districts option selected only count population within UATS district
		GROUP BY
			[geography_household_location].[household_location_taz_13]
		HAVING
			SUM([person].[weight_person]) > 0) AS [tt]),
[agg_destinations] AS (
	SELECT
		[trip_origin_taz_13]
		,SUM([emp_educ]) AS [emp_educ]
	FROM
		[skims]
	INNER JOIN
		[destinations]
	ON
		[skims].[trip_destination_taz_13] = [destinations].[taz_13]
	GROUP BY
		[trip_origin_taz_13])
SELECT
	@scenario_id AS [scenario_id]
	,'auto' AS [accessibility_mode]
	,SUM(100.0 * [pop] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop]) AS [pop_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_senior] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_senior]) AS [pop_senior_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_non_senior] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_non_senior]) AS [pop_non_senior_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_minority] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_minority]) AS [pop_minority_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_non_minority] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_non_minority]) AS [pop_non_minority_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_low_income] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_low_income]) AS [pop_low_income_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_non_low_income] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_non_low_income]) AS [pop_non_low_income_wgt_avg_job_sch_enroll]
FROM
	[taz_pop]
LEFT OUTER JOIN
	[agg_destinations]
ON
	[taz_pop].[taz_13] = [agg_destinations].[trip_origin_taz_13]
CROSS JOIN (
	SELECT
		SUM([emp_educ]) AS [total_emp_educ]
	FROM
		[destinations]) AS [total_destinations]
OPTION(MAXDOP 1)
GO

-- Add metadata for [rtp_2019].[sp_pm_7a_auto]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_7a_auto', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_7a_auto', 'MS_Description', 'performance metric 7a auto mode'
GO




-- Create stored procedure for performance metric #7a using transit skims
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_7a_transit]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_7a_transit]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_7a_transit]
	@scenario_id integer,
	@uats bit = 0 -- switch to limit origin and destination geographies to UATS zones
AS

/*	Author: Gregor Schroeder
	Date: 4/25/2018
	Description: Percent of population within 30 minutes jobs and higher
		education via transit (total population, disadvantaged
		communities (seniors, low-income, and minority) and non-disadvantaged
		communities)
		Note this measure has been adjusted to be the percent of total
		employment and enrollment in the region accessible by the average person
		similar to Highway Evaluation Criteria 9a and Performance Measure 8ab_auto in the 2015 RTP */

SET NOCOUNT ON;

-- get mgras that are fully contained within UATS districts
DECLARE @uats_mgras TABLE ([mgra] nchar(15) PRIMARY KEY NOT NULL)
INSERT INTO @uats_mgras
SELECT CONVERT(nchar, [mgra]) AS [mgra] FROM
OPENQUERY(
	[sql2014b8],
	'SELECT [mgra] FROM [lis].[gis].[uats2014],[lis].[gis].[MGRA13PT]
		WHERE [uats2014].[Shape].STContains([MGRA13PT].[Shape]) = 1');

-- for resident models only (Individual, Internal-External, Joint)
-- get the weighted average by transit person trips of MGRA-MGRA trip time
-- note if a MGRA-MGRA pair does not appear in this trip list it is not considered
-- keeping only trip times under 30 minutes
with [skims] AS (
	SELECT
		[geography_trip_origin].[trip_origin_mgra_13]
		,[geography_trip_destination].[trip_destination_mgra_13]
		,SUM(([weight_person_trip] * [time_total])) / SUM([weight_person_trip]) AS [time_avg]
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[model_trip]
	ON
		[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
	INNER JOIN
		[dimension].[mode_trip]
	ON
		[person_trip].[mode_trip_id] = [mode_trip].[mode_trip_id]
	INNER JOIN
		[dimension].[geography_trip_origin]
	ON
		[person_trip].[geography_trip_origin_id] = [geography_trip_origin].[geography_trip_origin_id]
	INNER JOIN
		[dimension].[geography_trip_destination]
	ON
		[person_trip].[geography_trip_destination_id] = [geography_trip_destination].[geography_trip_destination_id]
	LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
		@uats_mgras AS [uats_origin_xref]
	ON
		[geography_trip_origin].[trip_origin_mgra_13] = [uats_origin_xref].[mgra]
	LEFT OUTER JOIN -- keep as outer join since where clause is OR condition
		@uats_mgras AS [uats_dest_xref]
	ON
		[geography_trip_destination].[trip_destination_mgra_13] = [uats_dest_xref].[mgra]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
		AND [model_trip].[model_trip_description] IN ('Individual',
													  'Internal-External',
													  'Joint') -- resident models only
		AND [mode_trip].[mode_trip_description] IN ('Walk to Transit - Local Bus Only',
													'Walk to Transit - Premium Transit Only',
													'Walk to Transit - Local Bus and Premium Transit',
													'Park and Ride to Transit - Local Bus Only',
													'Park and Ride to Transit - Premium Transit Only',
													'Park and Ride to Transit - Local Bus and Premium Transit',
													'Kiss and Ride to Transit - Local Bus Only',
													'Kiss and Ride to Transit - Premium Transit Only',
													'Kiss and Ride to Transit - Local Bus and Premium Transit') -- transit mode only
		AND ((@uats = 1 AND ([uats_origin_xref].[mgra] IS NOT NULL AND [uats_dest_xref].[mgra] IS NOT NULL))
			OR @uats = 0) -- if UATS districts option selected only count trips originating and ending in UATS mgras
	GROUP BY
		[geography_trip_origin].[trip_origin_mgra_13]
		,[geography_trip_destination].[trip_destination_mgra_13]
	HAVING
		SUM(([weight_person_trip] * [time_total])) / SUM([weight_person_trip]) <= 30), -- remove skims over 30 minutes
-- get the amount of jobs and college+ education enrollment within each TAZ
-- adult school enrollment is included because the model sends university students to this enrollment
[destinations] AS (
	SELECT
		[geography].[mgra_13]
		,SUM([emp_total] + [collegeenroll] + [othercollegeenroll] + [adultschenrl]) AS [emp_educ]
	FROM
		[fact].[mgra_based_input]
	INNER JOIN
		[dimension].[geography]
	ON
		[mgra_based_input].[geography_id] = [geography].[geography_id]
	LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
		@uats_mgras AS [uats_xref]
	ON
		[geography].[mgra_13] = [uats_xref].[mgra]
	WHERE
		[mgra_based_input].[scenario_id] = @scenario_id
		AND ((@uats = 1 AND [uats_xref].[mgra] IS NOT NULL)
			OR @uats = 0) -- if UATS districts option selected only count destinations within UATS district
	GROUP BY
		[geography].[mgra_13]
	HAVING
		SUM([emp_total] + [collegeenroll] + [othercollegeenroll] + [adultschenrl]) > 0),
-- get population by Community of Concern/Non-Community of Concern
-- within each MGRA
[mgra_pop] AS (
	SELECT
		[mgra_13]
		,[pop]
		,[pop_senior]
		,[pop] - [pop_senior] AS [pop_non_senior]
		,[pop_minority]
		,[pop] - [pop_minority] AS [pop_non_minority]
		,[pop_low_income]
		,[pop] - [pop_low_income] AS [pop_non_low_income]
	FROM (
		SELECT
			[geography_household_location].[household_location_mgra_13] AS [mgra_13]
			,SUM([person].[weight_person]) AS [pop]
			,SUM(CASE WHEN [person].[age] >= 75 THEN [person].[weight_person] ELSE 0 END) AS [pop_senior]
			,SUM(CASE	WHEN [person].[race] IN ('Some Other Race Alone',
												 'Asian Alone',
												 'Black or African American Alone',
												 'Two or More Major Race Groups',
												 'Native Hawaiian and Other Pacific Islander Alone',
												 'American Indian and Alaska Native Tribes specified; or American Indian or Alaska Native, not specified and no other races')
							 OR [person].[hispanic] = 'Hispanic' THEN [person].[weight_person]
							 ELSE 0 END) AS [pop_minority]
			,SUM(CASE WHEN [household].[poverty] <= 2 THEN [person].[weight_person] ELSE 0 END) AS [pop_low_income]
		FROM
			[dimension].[person]
		INNER JOIN
			[dimension].[household]
		ON
			[person].[scenario_id] = [household].[scenario_id]
			AND [person].[household_id] = [household].[household_id]
		INNER JOIN
			[dimension].[geography_household_location]
		ON
			[household].[geography_household_location_id] = [geography_household_location].[geography_household_location_id]
		LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
			@uats_mgras AS [uats_xref]
		ON
			[geography_household_location].[household_location_mgra_13] = [uats_xref].[mgra]
		WHERE
			[person].[scenario_id] = @scenario_id
			AND [household].[scenario_id] = @scenario_id
			AND ((@uats = 1 AND [uats_xref].[mgra] IS NOT NULL)
				OR @uats = 0) -- if UATS districts option selected only count population within UATS district
		GROUP BY
			[geography_household_location].[household_location_mgra_13]
		HAVING
			SUM([person].[weight_person]) > 0) AS [tt]),
[agg_destinations] AS (
	SELECT
		[trip_origin_mgra_13]
		,SUM([emp_educ]) AS [emp_educ]
	FROM
		[skims]
	INNER JOIN
		[destinations]
	ON
		[skims].[trip_destination_mgra_13] = [destinations].[mgra_13]
	GROUP BY
		[trip_origin_mgra_13])
SELECT
	@scenario_id AS [scenario_id]
	,'transit' AS [accessibility_mode]
	,SUM(100.0 * [pop] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop]) AS [pop_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_senior] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_senior]) AS [pop_senior_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_non_senior] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_non_senior]) AS [pop_non_senior_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_minority] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_minority]) AS [pop_minority_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_non_minority] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_non_minority]) AS [pop_non_minority_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_low_income] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_low_income]) AS [pop_low_income_wgt_avg_job_sch_enroll]
	,SUM(100.0 * [pop_non_low_income] * ISNULL([emp_educ], 0) / [total_emp_educ]) / SUM([pop_non_low_income]) AS [pop_non_low_income_wgt_avg_job_sch_enroll]
FROM
	[mgra_pop]
LEFT OUTER JOIN
	[agg_destinations]
ON
	[mgra_pop].[mgra_13] = [agg_destinations].[trip_origin_mgra_13]
CROSS JOIN (
	SELECT
		SUM([emp_educ]) AS [total_emp_educ]
	FROM
		[destinations]) AS [total_destinations]
OPTION(MAXDOP 1)
GO

-- Add metadata for [rtp_2019].[sp_pm_7a_transit]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_7a_transit', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_7a_transit', 'MS_Description', 'performance metric 7a transit mode'
GO




-- Create stored procedure for performance metric #7b using auto skims
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_7b_auto]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_7b_auto]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_7b_auto]
	@scenario_id integer,
	@uats bit = 0, -- switch to limit origin and destination geographies to UATS zones
	@senior bit = 0, -- indicator to use senior population segmentation
	@minority bit = 0, -- indicator to use minority population segmentation
	@low_income bit = 0 -- indicator to use low income population segmentation
AS

IF CONVERT(int, @senior) + CONVERT(int, @minority) + CONVERT(int, @low_income) > 1
BEGIN
RAISERROR ('Select only one population segmentation.', 16, 1)
RETURN -1
END;

/*	Author: Gregor Schroeder
	Date: 4/25/2018
	Description: Percent of population within 15 minutes of goods and services
		(retail, medical, parks, and beaches) via driving (total
		population, disadvantaged communities (seniors, low-income, and minority)
		and non-disadvantaged communities)
		Note that for retail and medical the measure is adjusted to be the percent
		of total retail and medical employment in the region accessible by the
		average person
		similar to Performance Measure 8ab_auto in the 2015 RTP */

SET NOCOUNT ON;

-- get mgras that are fully contained within UATS districts
DECLARE @uats_mgras TABLE ([mgra] nchar(15) PRIMARY KEY NOT NULL)
INSERT INTO @uats_mgras
SELECT CONVERT(nchar, [mgra]) AS [mgra] FROM
OPENQUERY(
	[sql2014b8],
	'SELECT [mgra] FROM [lis].[gis].[uats2014],[lis].[gis].[MGRA13PT]
		WHERE [uats2014].[Shape].STContains([MGRA13PT].[Shape]) = 1');

-- for resident models only (Individual, Internal-External, Joint)
-- get the weighted average by auto person trips of TAZ-TAZ trip time
-- note if a TAZ-TAZ pair does not appear in this trip list it is not considered
-- keeping only trip times under 15 minutes
with [skims] AS (
	SELECT
		[geography_trip_origin].[trip_origin_taz_13]
		,[geography_trip_destination].[trip_destination_taz_13]
		,SUM(([weight_person_trip] * [time_total])) / SUM([weight_person_trip]) AS [time_avg]
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[model_trip]
	ON
		[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
	INNER JOIN
		[dimension].[mode_trip]
	ON
		[person_trip].[mode_trip_id] = [mode_trip].[mode_trip_id]
	INNER JOIN
		[dimension].[geography_trip_origin]
	ON
		[person_trip].[geography_trip_origin_id] = [geography_trip_origin].[geography_trip_origin_id]
	INNER JOIN
		[dimension].[geography_trip_destination]
	ON
		[person_trip].[geography_trip_destination_id] = [geography_trip_destination].[geography_trip_destination_id]
	LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
		@uats_mgras AS [uats_origin_xref]
	ON
		[geography_trip_origin].[trip_origin_mgra_13] = [uats_origin_xref].[mgra]
	LEFT OUTER JOIN -- keep as outer join since where clause is OR condition
		@uats_mgras AS [uats_dest_xref]
	ON
		[geography_trip_destination].[trip_destination_mgra_13] = [uats_dest_xref].[mgra]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
		AND [model_trip].[model_trip_description] IN ('Individual',
													  'Internal-External',
													  'Joint') -- resident models only
		AND [mode_trip].[mode_trip_description] IN ('Drive Alone Non-Toll',
													'Drive Alone Toll Eligible',
													'Shared Ride 2 Non-Toll',
													'Shared Ride 2 Toll Eligible',
													'Shared Ride 3 Non-Toll',
													'Shared Ride 3 Toll Eligible') -- drive modes only
		AND ((@uats = 1 AND ([uats_origin_xref].[mgra] IS NOT NULL AND [uats_dest_xref].[mgra] IS NOT NULL))
			OR @uats = 0) -- if UATS districts option selected only count trips originating and ending in UATS mgras
	GROUP BY
		[geography_trip_origin].[trip_origin_taz_13]
		,[geography_trip_destination].[trip_destination_taz_13]
	HAVING
		SUM(([weight_person_trip] * [time_total])) / SUM([weight_person_trip]) <= 15), -- remove skims over 15 minutes
-- add an indicator if goods and services are present within each TAZ
[destinations] AS (
	SELECT
		[geography].[taz_13]
		,MAX(CASE WHEN [beachactive] > .5 THEN 1 ELSE 0 END) AS [beachactive]
		,SUM([emp_health]) AS [emp_health]
		,MAX(CASE WHEN [parkactive] > .5 THEN 1 ELSE 0 END) AS [parkactive]
		,SUM([emp_retail]) AS [emp_retail]
	FROM
		[fact].[mgra_based_input]
	INNER JOIN
		[dimension].[geography]
	ON
		[mgra_based_input].[geography_id] = [geography].[geography_id]
	LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
		@uats_mgras AS [uats_xref]
	ON
		[geography].[mgra_13] = [uats_xref].[mgra]
	WHERE
		[mgra_based_input].[scenario_id] = @scenario_id
		AND ((@uats = 1 AND [uats_xref].[mgra] IS NOT NULL)
			OR @uats = 0) -- if UATS districts option selected only count destinations within UATS district
	GROUP BY
		[geography].[taz_13]
	HAVING
		SUM([beachactive]) > .5
		OR SUM([emp_health]) > 1
		OR SUM([parkactive]) > 0.5
		OR SUM([emp_retail]) > 1),
-- get population by Community of Concern/Non-Community of Concern
-- within each TAZ
[taz_pop] AS (
	SELECT
		[taz_13]
		,CASE	WHEN @senior = 1 THEN [senior]
				WHEN @minority = 1 THEN [minority]
				WHEN @low_income = 1 THEN [low_income]
				ELSE 'All' END AS [pop_segmentation]
		,SUM([weight_person]) AS [weight_person]
	FROM (
		SELECT
			[geography_household_location].[household_location_taz_13] AS [taz_13]
			,[person].[weight_person]
			,CASE WHEN [person].[age] >= 75 THEN 'Senior' ELSE 'Non-Senior' END AS [senior]
			,CASE	WHEN [person].[race] IN ('Some Other Race Alone',
													'Asian Alone',
													'Black or African American Alone',
													'Two or More Major Race Groups',
													'Native Hawaiian and Other Pacific Islander Alone',
													'American Indian and Alaska Native Tribes specified; or American Indian or Alaska Native, not specified and no other races')
								OR [person].[hispanic] = 'Hispanic' THEN 'Minority'
								ELSE 'Non-Minority' END AS [minority]
			,CASE WHEN [household].[poverty] <= 2 THEN 'Low Income' ELSE 'Non-Low Income' END AS [low_income]
		FROM
			[dimension].[person]
		INNER JOIN
			[dimension].[household]
		ON
			[person].[scenario_id] = [household].[scenario_id]
			AND [person].[household_id] = [household].[household_id]
		INNER JOIN
			[dimension].[geography_household_location]
		ON
			[household].[geography_household_location_id] = [geography_household_location].[geography_household_location_id]
		LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
			@uats_mgras AS [uats_xref]
		ON
			[geography_household_location].[household_location_mgra_13] = [uats_xref].[mgra]
		WHERE
			[person].[scenario_id] = @scenario_id
			AND [household].[scenario_id] = @scenario_id
			AND ((@uats = 1 AND [uats_xref].[mgra] IS NOT NULL
				OR @uats = 0))) AS [tt] -- if UATS districts option selected only count population within UATS district
	GROUP BY
		[taz_13]
		,CASE	WHEN @senior = 1 THEN [senior]
				WHEN @minority = 1 THEN [minority]
				WHEN @low_income = 1 THEN [low_income]
				ELSE 'All' END),
[agg_destinations] AS (
	SELECT
		[trip_origin_taz_13]
		,MAX([beachactive]) AS [beachactive]
		,SUM([emp_health]) AS [emp_health]
		,MAX([parkactive]) AS [parkactive]
		,SUM([emp_retail]) AS [emp_retail]
	FROM
		[skims]
	INNER JOIN
		[destinations]
	ON
		[skims].[trip_destination_taz_13] = [destinations].[taz_13]
	GROUP BY
		[trip_origin_taz_13])
SELECT
	@scenario_id AS [scenario_id]
	,'auto' AS [accessibility_mode]
	,ISNULL([pop_segmentation], 'Total') AS [pop_segmentation]
	,100.0 * SUM([weight_person] * ISNULL([emp_health], 0) / [total_emp_health]) / SUM([weight_person]) AS [emp_health]
	,100.0 * SUM([weight_person] * ISNULL([emp_retail], 0) / [total_emp_retail]) / SUM([weight_person]) AS [emp_retail]
	,100.0 * SUM(CASE WHEN [beachactive] = 1 THEN [weight_person] ELSE 0 END) / SUM([weight_person]) AS [beachactive]
	,100.0 * SUM(CASE WHEN [parkactive] = 1 THEN [weight_person] ELSE 0 END) / SUM([weight_person]) AS [parkactive]
FROM
	[taz_pop]
LEFT OUTER JOIN
	[agg_destinations]
ON
	[taz_pop].[taz_13] = [agg_destinations].[trip_origin_taz_13]
CROSS JOIN (
	SELECT
		SUM([emp_health]) AS [total_emp_health]
		,SUM([emp_retail]) AS [total_emp_retail]
	FROM
		[destinations]) AS [total_destinations]
GROUP BY
	[pop_segmentation]
WITH ROLLUP
OPTION(MAXDOP 1)
GO

-- Add metadata for [rtp_2019].[sp_pm_7b_auto]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_7b_auto', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_7b_auto', 'MS_Description', 'performance metric 7b auto mode'
GO




-- Create stored procedure for performance metric #7b using transit skims
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_7b_transit]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_7b_transit]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_7b_transit]
	@scenario_id integer,
	@uats bit = 0, -- switch to limit origin and destination geographies to UATS zones
	@senior bit = 0, -- indicator to use senior population segmentation
	@minority bit = 0, -- indicator to use minority population segmentation
	@low_income bit = 0 -- indicator to use low income population segmentation
AS

IF CONVERT(int, @senior) + CONVERT(int, @minority) + CONVERT(int, @low_income) > 1
BEGIN
RAISERROR ('Select only one population segmentation.', 16, 1)
RETURN -1
END;

/*	Author: Gregor Schroeder
	Date: 4/25/2018
	Description: Percent of population within 15 minutes of goods and services
		(retail, medical, parks, and beaches) via transit (total
		population, disadvantaged communities (seniors, low-income, and minority)
		and non-disadvantaged communities)
		Note that for retail and medical the measure is adjusted to be the percent
		of total retail and medical employment in the region accessible by the
		average person
		similar to Performance Measure 8ab_auto in the 2015 RTP */

SET NOCOUNT ON;

-- get mgras that are fully contained within UATS districts
DECLARE @uats_mgras TABLE ([mgra] nchar(15) PRIMARY KEY NOT NULL)
INSERT INTO @uats_mgras
SELECT CONVERT(nchar, [mgra]) AS [mgra] FROM
OPENQUERY(
	[sql2014b8],
	'SELECT [mgra] FROM [lis].[gis].[uats2014],[lis].[gis].[MGRA13PT]
		WHERE [uats2014].[Shape].STContains([MGRA13PT].[Shape]) = 1');

-- for resident models only (Individual, Internal-External, Joint)
-- get the weighted average by transit person trips of MGRA-MGRA trip time
-- note if a MGRA-MGRA pair does not appear in this trip list it is not considered
-- do not have to consider external zones with no MGRAs as these zones
-- do not have population or employment for the San Diego region
-- keeping only trip times under 15 minutes
with [skims] AS (
	SELECT
		[geography_trip_origin].[trip_origin_mgra_13]
		,[geography_trip_destination].[trip_destination_mgra_13]
		,SUM(([weight_person_trip] * [time_total])) / SUM([weight_person_trip]) AS [time_avg]
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[model_trip]
	ON
		[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
	INNER JOIN
		[dimension].[mode_trip]
	ON
		[person_trip].[mode_trip_id] = [mode_trip].[mode_trip_id]
	INNER JOIN
		[dimension].[geography_trip_origin]
	ON
		[person_trip].[geography_trip_origin_id] = [geography_trip_origin].[geography_trip_origin_id]
	INNER JOIN
		[dimension].[geography_trip_destination]
	ON
		[person_trip].[geography_trip_destination_id] = [geography_trip_destination].[geography_trip_destination_id]
	LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
		@uats_mgras AS [uats_origin_xref]
	ON
		[geography_trip_origin].[trip_origin_mgra_13] = [uats_origin_xref].[mgra]
	LEFT OUTER JOIN -- keep as outer join since where clause is OR condition
		@uats_mgras AS [uats_dest_xref]
	ON
		[geography_trip_destination].[trip_destination_mgra_13] = [uats_dest_xref].[mgra]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
		AND [model_trip].[model_trip_description] IN ('Individual',
													  'Internal-External',
													  'Joint') -- resident models only
		AND [mode_trip].[mode_trip_description] IN ('Walk to Transit - Local Bus Only',
													'Walk to Transit - Premium Transit Only',
													'Walk to Transit - Local Bus and Premium Transit',
													'Park and Ride to Transit - Local Bus Only',
													'Park and Ride to Transit - Premium Transit Only',
													'Park and Ride to Transit - Local Bus and Premium Transit',
													'Kiss and Ride to Transit - Local Bus Only',
													'Kiss and Ride to Transit - Premium Transit Only',
													'Kiss and Ride to Transit - Local Bus and Premium Transit') -- transit mode only
		AND ((@uats = 1 AND ([uats_origin_xref].[mgra] IS NOT NULL AND [uats_dest_xref].[mgra] IS NOT NULL))
			OR @uats = 0) -- if UATS districts option selected only count trips originating and ending in UATS mgras
	GROUP BY
		[geography_trip_origin].[trip_origin_mgra_13]
		,[geography_trip_destination].[trip_destination_mgra_13]
	HAVING
		SUM(([weight_person_trip] * [time_total])) / SUM([weight_person_trip]) <= 15), -- remove skims over 15 minutes
-- add an indicator if goods and services are present within each MGRA
-- sum employment for health and retail within each MGRA
[destinations] AS (
	SELECT
		[geography].[mgra_13]
		,MAX(CASE WHEN [beachactive] > .5 THEN 1 ELSE 0 END) AS [beachactive]
		,SUM([emp_health]) AS [emp_health]
		,MAX(CASE WHEN [parkactive] > .5 THEN 1 ELSE 0 END) AS [parkactive]
		,SUM([emp_retail]) AS [emp_retail]
	FROM
		[fact].[mgra_based_input]
	INNER JOIN
		[dimension].[geography]
	ON
		[mgra_based_input].[geography_id] = [geography].[geography_id]
	LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
		@uats_mgras AS [uats_xref]
	ON
		[geography].[mgra_13] = [uats_xref].[mgra]
	WHERE
		[mgra_based_input].[scenario_id] = @scenario_id
		AND ((@uats = 1 AND [uats_xref].[mgra] IS NOT NULL)
			OR @uats = 0) -- if UATS districts option selected only count destinations within UATS district
	GROUP BY
		[geography].[mgra_13]
	HAVING
		SUM([beachactive]) > .5
		OR SUM([emp_health]) > 1
		OR SUM([parkactive]) > 0.5
		OR SUM([emp_retail]) > 1),
-- get population by Community of Concern/Non-Community of Concern
-- within each MGRA
[mgra_pop] AS (
	SELECT
		[mgra_13]
		,CASE	WHEN @senior = 1 THEN [senior]
				WHEN @minority = 1 THEN [minority]
				WHEN @low_income = 1 THEN [low_income]
				ELSE 'All' END AS [pop_segmentation]
		,SUM([weight_person]) AS [weight_person]
	FROM (
		SELECT
			[geography_household_location].[household_location_mgra_13] AS [mgra_13]
			,[person].[weight_person]
			,CASE WHEN [person].[age] >= 75 THEN 'Senior' ELSE 'Non-Senior' END AS [senior]
			,CASE	WHEN [person].[race] IN ('Some Other Race Alone',
													'Asian Alone',
													'Black or African American Alone',
													'Two or More Major Race Groups',
													'Native Hawaiian and Other Pacific Islander Alone',
													'American Indian and Alaska Native Tribes specified; or American Indian or Alaska Native, not specified and no other races')
								OR [person].[hispanic] = 'Hispanic' THEN 'Minority'
								ELSE 'Non-Minority' END AS [minority]
			,CASE WHEN [household].[poverty] <= 2 THEN 'Low Income' ELSE 'Non-Low Income' END AS [low_income]
		FROM
			[dimension].[person]
		INNER JOIN
			[dimension].[household]
		ON
			[person].[scenario_id] = [household].[scenario_id]
			AND [person].[household_id] = [household].[household_id]
		INNER JOIN
			[dimension].[geography_household_location]
		ON
			[household].[geography_household_location_id] = [geography_household_location].[geography_household_location_id]
		LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
			@uats_mgras AS [uats_xref]
		ON
			[geography_household_location].[household_location_mgra_13] = [uats_xref].[mgra]
		WHERE
			[person].[scenario_id] = @scenario_id
			AND [household].[scenario_id] = @scenario_id
			AND ((@uats = 1 AND [uats_xref].[mgra] IS NOT NULL
				OR @uats = 0))) AS [tt] -- if UATS districts option selected only count population within UATS district
	GROUP BY
		[mgra_13]
		,CASE	WHEN @senior = 1 THEN [senior]
				WHEN @minority = 1 THEN [minority]
				WHEN @low_income = 1 THEN [low_income]
				ELSE 'All' END),
[agg_destinations] AS (
	SELECT
		[trip_origin_mgra_13]
		,MAX([beachactive]) AS [beachactive]
		,SUM([emp_health]) AS [emp_health]
		,MAX([parkactive]) AS [parkactive]
		,SUM([emp_retail]) AS [emp_retail]
	FROM
		[skims]
	INNER JOIN
		[destinations]
	ON
		[skims].[trip_destination_mgra_13] = [destinations].[mgra_13]
	GROUP BY
		[trip_origin_mgra_13])
SELECT
	@scenario_id AS [scenario_id]
	,'transit' AS [accessibility_mode]
	,ISNULL([pop_segmentation], 'Total') AS [pop_segmentation]
	,100.0 * SUM([weight_person] * ISNULL([emp_health], 0) / [total_emp_health]) / SUM([weight_person]) AS [emp_health]
	,100.0 * SUM([weight_person] * ISNULL([emp_retail], 0) / [total_emp_retail]) / SUM([weight_person]) AS [emp_retail]
	,100.0 * SUM(CASE WHEN [beachactive] = 1 THEN [weight_person] ELSE 0 END) / SUM([weight_person]) AS [beachactive]
	,100.0 * SUM(CASE WHEN [parkactive] = 1 THEN [weight_person] ELSE 0 END) / SUM([weight_person]) AS [parkactive]
FROM
	[mgra_pop]
LEFT OUTER JOIN
	[agg_destinations]
ON
	[mgra_pop].[mgra_13] = [agg_destinations].[trip_origin_mgra_13]
CROSS JOIN (
	SELECT
		SUM([emp_health]) AS [total_emp_health]
		,SUM([emp_retail]) AS [total_emp_retail]
	FROM
		[destinations]) AS [total_destinations]
GROUP BY
	[pop_segmentation]
WITH ROLLUP
OPTION(MAXDOP 1)
GO

-- Add metadata for [rtp_2019].[sp_pm_7b_transit]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_7b_transit', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_7b_transit', 'MS_Description', 'performance metric 7b transit mode'
GO




-- Create stored procedure for performance metric #A
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_A]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_A]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_A]
	@scenario_id integer,
	@senior bit = 0, -- indicator to use senior population segmentation
	@minority bit = 0, -- indicator to use minority population segmentation
	@low_income bit = 0 -- indicator to use low income population segmentation
AS

/*	Author: Gregor Schroeder
	Date: 4/20/2018
	Description:  Average peak-period tour travel time to work 
		(drive alone, carpool, transit, bike, and walk) (minutes)
		similar to Performance Measures 1a and 7d in the 2015 RTP*/

IF CONVERT(int, @senior) + CONVERT(int, @minority) + CONVERT(int, @low_income) > 1
BEGIN
RAISERROR ('Select only one population segmentation.', 16, 1)
RETURN -1
END;

with [eligible_records] AS (
	SELECT
		[tour].[tour_id]
		,[mode_trip].[mode_trip_description]
		,[dist_total]
		,[time_total]
		,[weight_person_tour]
		,CASE WHEN [person].[age] >= 75 THEN 'Senior' ELSE 'Non-Senior' END AS [senior]
		,CASE	WHEN [person].[race] IN ('Some Other Race Alone',
										 'Asian Alone',
										 'Black or African American Alone',
										 'Two or More Major Race Groups',
										 'Native Hawaiian and Other Pacific Islander Alone',
										 'American Indian and Alaska Native Tribes specified; or American Indian or Alaska Native, not specified and no other races')
					 OR [person].[hispanic] = 'Hispanic' THEN 'Minority'
					ELSE 'Non-Minority' END AS [minority]
		,CASE WHEN [household].[poverty] <= 2 THEN 'Low Income' ELSE 'Non-Low Income' END AS [low_income]
		,MAX(CASE	WHEN [mode_trip].[mode_trip_description] IN ('Bike', 'Walk') 
					THEN 1 ELSE 0 END) OVER (PARTITION BY [tour].[tour_id]) AS [bike_walk_indicator]
		,MAX([person_trip].[dist_total]) OVER (PARTITION BY [tour].[tour_id]) AS [dist_max]
		,MAX([person_trip].[time_total]) OVER (PARTITION BY [tour].[tour_id]) AS [time_max]
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[person]
	ON
		[person_trip].[scenario_id] = [person].[scenario_id]
		AND [person_trip].[person_id] = [person].[person_id]
	INNER JOIN
		[dimension].[household]
	ON
		[person_trip].[scenario_id] = [household].[scenario_id]
		AND [person_trip].[household_id] = [household].[household_id]
	INNER JOIN
		[dimension].[inbound]
	ON
		[person_trip].[inbound_id] = [inbound].[inbound_id]
	INNER JOIN
		[dimension].[mode_trip]
	ON
		[person_trip].[mode_trip_id] = [mode_trip].[mode_trip_id]
	INNER JOIN
		[dimension].[tour]
	ON
		[person_trip].[scenario_id] = [tour].[scenario_id]
		AND [person_trip].[tour_id] = [tour].[tour_id]
	INNER JOIN
		[dimension].[model_tour]
	ON
		[tour].[model_tour_id] = [model_tour].[model_tour_id]
	INNER JOIN
		[dimension].[time_tour_start]
	ON
		[tour].[time_tour_start_id] = [time_tour_start].[time_tour_start_id]
	INNER JOIN
		[dimension].[purpose_tour]
	ON
		[tour].[purpose_tour_id] = [purpose_tour].[purpose_tour_id]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
		AND [person].[scenario_id] = @scenario_id
		AND [household].[scenario_id] = @scenario_id
		AND [tour].[scenario_id] = @scenario_id
		AND [inbound].[inbound_description] = 'Outbound' -- to work trips only
		AND [model_tour].[model_tour_description] IN ('Individual', 'Internal-External','Joint') -- resident models only
		AND [time_tour_start].[tour_start_abm_5_tod] IN ('2', '4') -- tours that start in abm five time of day peak periods only
		AND [purpose_tour].[purpose_tour_description] = 'Work'), -- work tours only
[filtered_records_tour_mode] AS (
	SELECT
		[tour_id]
		,[mode_trip_description]
		,rn = ROW_NUMBER()OVER(PARTITION BY [tour_id] ORDER BY [mode_trip_description])
	FROM
		[eligible_records]
	WHERE
		([bike_walk_indicator] = 0 AND [time_total] = [time_max]) -- if eligible records do not contain bike/walk trips then take trip mode with maximum time
		OR ([bike_walk_indicator] = 1 AND [dist_total] = [dist_max])), -- if eligible records contain bike/walk trips then take trip mode with maximum distance
[tour_mode] AS (
	SELECT
		[tour_id]
		,CASE	WHEN [mode_trip_description] IN ('Drive Alone Non-Toll',
												 'Drive Alone Toll Eligible')
				THEN 'Drive Alone'
				WHEN [mode_trip_description] IN ('Shared Ride 2 Non-Toll',
													'Shared Ride 2 Toll Eligible',
													'Shared Ride 3 Non-Toll',
													'Shared Ride 3 Toll Eligible')
				THEN 'Shared Ride'
				WHEN [mode_trip_description] IN ('Kiss and Ride to Transit - Local Bus and Premium Transit',
													'Kiss and Ride to Transit - Local Bus Only',
													'Kiss and Ride to Transit - Premium Transit Only' ,
													'Park and Ride to Transit - Local Bus and Premium Transit',
													'Park and Ride to Transit - Local Bus Only',
													'Park and Ride to Transit - Premium Transit Only',
													'Walk to Transit - Local Bus and Premium Transit',
													'Walk to Transit - Local Bus Only',
													'Walk to Transit - Premium Transit Only')
				THEN 'Transit'
				ELSE [mode_trip_description] END AS [mode_aggregate]
	FROM
		[filtered_records_tour_mode]
	WHERE
		[rn] = 1) -- add a filter to remove ties (multiple trips with same maximum distances/times)
SELECT
	@scenario_id AS [scenario_id]
	,ISNULL(CASE	WHEN @senior = 1 THEN [senior]
					WHEN @minority = 1 THEN [minority]
					WHEN @low_income = 1 THEN [low_income]
					ELSE 'All' END, 'Total') AS [pop_segmentation]
	,ISNULL([mode_aggregate], 'Total') AS [mode_aggregate]
	,SUM([time_tour] * [weight_person_tour]) / SUM([weight_person_tour]) AS [avg_time_tour]
	,SUM([weight_person_tour]) AS [person_tours]
FROM (
	SELECT
		[eligible_records].[tour_id]
		,[tour_mode].[mode_aggregate]
		,MAX([eligible_records].[senior]) AS [senior]
		,MAX([eligible_records].[minority]) AS [minority]
		,MAX([eligible_records].[low_income]) AS [low_income]
		,MAX([eligible_records].[weight_person_tour]) AS [weight_person_tour]
		,SUM([eligible_records].[time_total]) AS [time_tour]
	FROM
		[eligible_records]
	INNER JOIN
		[tour_mode]
	ON
		[eligible_records].[tour_id] = [tour_mode].[tour_id]
	GROUP BY
		[eligible_records].[tour_id]
		,[tour_mode].[mode_aggregate]) AS [results]
GROUP BY
	CASE	WHEN @senior = 1 THEN [senior]
			WHEN @minority = 1 THEN [minority]
			WHEN @low_income = 1 THEN [low_income]
			ELSE 'All' END
	,[mode_aggregate]
WITH ROLLUP
OPTION(MAXDOP 1)
GO

-- Add metadata for [rtp_2019].[sp_pm_A]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_A', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_A', 'MS_Description', 'performance metric A'
GO




-- Create stored procedure for performance metric #B
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_B]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_B]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_B]
	@scenario_id integer
AS

/*	Author: Ziying Ouyang and Gregor Schroeder
	Date: Revised 4/10/2018
	Description:  Average travel times to/from tribal lands (minutes)
	  Average travel time of microsimulated (excluding cvm model) trips with origin/destination MGRAs
	  whose centroids are within the tribal lands
	  formerly Performance Measure 6A in the 2015 RTP */


with [xref] AS (
	SELECT [mgra] FROM
	OPENQUERY(
		[sql2014b8],
		'SELECT [mgra] FROM [lis].[gis].[INDIANRES],[lis].[gis].[MGRA13PT]
		WHERE [INDIANRES].[Shape].STContains([MGRA13PT].[Shape]) = 1'))
SELECT
	@scenario_id AS scenario_id
	,SUM([weight_person_trip] * [time_total]) / SUM([weight_person_trip]) AS [avg_travel_time]
	,SUM([weight_person_trip]) AS [person_trips]
FROM
	[fact].[person_trip]
INNER JOIN
	[dimension].[model_trip]
ON
	[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
INNER JOIN
	[dimension].[geography_trip_origin]
ON
	[person_trip].[geography_trip_origin_id] = [geography_trip_origin].[geography_trip_origin_id]
INNER JOIN
	[dimension].[geography_trip_destination]
ON
	[person_trip].[geography_trip_destination_id] = [geography_trip_destination].[geography_trip_destination_id]
LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
	[xref] AS [origin_xref]
ON
	[geography_trip_origin].[trip_origin_mgra_13] = CONVERT(nchar, [origin_xref].[mgra])
LEFT OUTER JOIN -- keep as outer join since where clause is OR condition
	[xref] AS [dest_xref]
ON
	[geography_trip_destination].[trip_destination_mgra_13] = CONVERT(nchar, [dest_xref].[mgra])
WHERE
	[person_trip].[scenario_id] = @scenario_id
	AND [model_trip].[model_trip_description] IN ('Airport - CBX',
												  'Airport - SAN',
												  'Cross Border',
												  'Individual',
												  'Internal-External',
												  'Joint',
												  'Visitor') -- all microsimulated trips excepting commercial vehicle model
	AND ([origin_xref].[mgra] IS NOT NULL OR [dest_xref].[mgra] IS NOT NULL)-- only count trips originating and ending in tribal lands mgras
GO

-- Add metadata for [rtp_2019].[sp_pm_B]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_B', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_B', 'MS_Description', 'performance metric B'
GO




-- Create stored procedure for performance metric #C
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_C]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_C]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_C]
	@scenario_id integer
AS

/*	Author: Ziying Ouyang and Gregor Schroeder
	Date: Revised 4/12/2018
	Description: Average travel times to/from Mexico (minutes)
	  formerly Performance Measure 6B in the 2015 RTP */

-- a trip from one POE TAZ to another would take the origin POE as the POE of note
SELECT
	@scenario_id AS [scenario_id]
	,ISNULL(CASE	WHEN [geography_trip_origin].[trip_origin_external_zone] = 'Not Applicable' 
					THEN [geography_trip_destination].[trip_destination_external_zone]
					ELSE [geography_trip_origin].[trip_origin_external_zone]
					END, 'Total') AS [poe_desc]
	,SUM([weight_person_trip] * [time_total]) / SUM([weight_person_trip]) AS [avg_travel_time]
	,SUM([weight_person_trip]) AS [person_trips]
FROM
	[fact].[person_trip]
INNER JOIN
	[dimension].[model_trip]
ON
	[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
INNER JOIN
	[dimension].[geography_trip_origin]
ON
	[person_trip].[geography_trip_origin_id] = [geography_trip_origin].[geography_trip_origin_id]
INNER JOIN
	[dimension].[geography_trip_destination]
ON
	[person_trip].[geography_trip_destination_id] = [geography_trip_destination].[geography_trip_destination_id]
WHERE
	[person_trip].[scenario_id] = @scenario_id
	AND [model_trip].[model_trip_description] = 'Cross Border' -- Cross Border model only
	AND ([geography_trip_origin].[trip_origin_external_zone] IN ('San Ysidro',
																 'Otay Mesa',
																 'Tecate',
																 'Otay Mesa East',
																 'Jacumba') -- POE external zones
		OR [geography_trip_destination].[trip_destination_external_zone] IN ('San Ysidro',
																			 'Otay Mesa',
																			 'Tecate',
																			 'Otay Mesa East',
																			 'Jacumba')) -- POE external zones
GROUP BY
	CASE	WHEN [geography_trip_origin].[trip_origin_external_zone] = 'Not Applicable' 
			THEN [geography_trip_destination].[trip_destination_external_zone]
			ELSE [geography_trip_origin].[trip_origin_external_zone]
			END
WITH ROLLUP
GO

-- Add metadata for [rtp_2019].[sp_pm_C]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_C', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_C', 'MS_Description', 'performance metric C'
GO




-- Create stored procedure for performance metric #D
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_D]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_D]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_D]
	@scenario_id integer
AS

/*	Author: Ziying Ouyang and Gregor Schroeder
	Date: Revised 4/12/2018
	Description: Average travel time to/from neighboring counties(Imperial, Orange, Riverside) (minutes)
	  only considers aggregate models and the commercial vehicle model
	  formerly Performance Measure 6C in the 2015 RTP */

SELECT
	@scenario_id AS [scenario_id]
	,SUM([weight_person_trip] * [time_total]) / SUM([weight_person_trip]) AS [avg_travel_time]
	,SUM([weight_person_trip]) AS [person_trips]
FROM
	[fact].[person_trip]
INNER JOIN
	[dimension].[model_trip]
ON
	[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
INNER JOIN
	[dimension].[geography_trip_origin]
ON
	[person_trip].[geography_trip_origin_id] = [geography_trip_origin].[geography_trip_origin_id]
INNER JOIN
	[dimension].[geography_trip_destination]
ON
	[person_trip].[geography_trip_destination_id] = [geography_trip_destination].[geography_trip_destination_id]
WHERE
	[person_trip].[scenario_id] = @scenario_id
	AND [model_trip].[model_trip_description] IN ('Commercial Vehicle',
												  'External-External',
												  'External-Internal',
												  'Truck') -- aggregate models and cvm only
	AND ([geography_trip_origin].[trip_origin_external_zone] IN ('I-8',
																 'CA-78',
																 'CA-79',
																 'Pala Road',
																 'I-15',
																 'CA-241 Toll Road',
																 'I-5') -- non-POE external zones
		OR [geography_trip_destination].[trip_destination_external_zone] IN ('I-8',
																			 'CA-78',
																			 'CA-79',
																			 'Pala Road',
																			 'I-15',
																			 'CA-241 Toll Road',
																			 'I-5')) -- non-POE external zones
GO

-- Add metadata for [rtp_2019].[sp_pm_D]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_D', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_D', 'MS_Description', 'performance metric D'
GO




-- Create stored procedure for performance metric #E
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_E]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_E]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_E]
	@scenario_id integer
AS

/*	Author: Ziying Ouyang and Gregor Schroeder
	Date: Revised 4/12/2018
	Description: Average travel time to/from military bases/installations (minutes)
	  Average travel time of micro-simulated trips with origin or destination MGRAs 
	  whose centroids are within military bases/installations
	  formerly Performance Measure 6d in the 2015 RTP */

with [xref] AS (
	SELECT [mgra] FROM
	OPENQUERY(
		[sql2014b8],
		'SELECT [mgra] FROM [lis].[gis].[OWNERSHIP], [lis].[gis].[MGRA13PT]
			WHERE [Own] = 41 AND [OWNERSHIP].[Shape].STContains([MGRA13PT].[Shape]) = 1'))
SELECT
	@scenario_id AS scenario_id
	,SUM([weight_person_trip] * [time_total]) / SUM([weight_person_trip]) AS [avg_travel_time]
	,SUM([weight_person_trip]) AS [person_trips]
FROM
	[fact].[person_trip]
INNER JOIN
	[dimension].[model_trip]
ON
	[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
INNER JOIN
	[dimension].[geography_trip_origin]
ON
	[person_trip].[geography_trip_origin_id] = [geography_trip_origin].[geography_trip_origin_id]
INNER JOIN
	[dimension].[geography_trip_destination]
ON
	[person_trip].[geography_trip_destination_id] = [geography_trip_destination].[geography_trip_destination_id]
LEFT OUTER JOIN -- keep as outer join since where clause is	OR condition
	[xref] AS [origin_xref]
ON
	[geography_trip_origin].[trip_origin_mgra_13] = CONVERT(nchar, [origin_xref].[mgra])
LEFT OUTER JOIN -- keep as outer join since where clause is OR condition
	[xref] AS [dest_xref]
ON
	[geography_trip_destination].[trip_destination_mgra_13] = CONVERT(nchar, [dest_xref].[mgra])
WHERE
	[person_trip].[scenario_id] = @scenario_id
	AND [model_trip].[model_trip_description] IN ('Airport - CBX',
												  'Airport - SAN',
												  'Cross Border',
												  'Individual',
												  'Internal-External',
												  'Joint',
												  'Visitor') -- all microsimulated trips excepting commercial vehicle model
	AND ([origin_xref].[mgra] IS NOT NULL OR [dest_xref].[mgra] IS NOT NULL)-- only count trips originating and ending in military mgras
GO

-- Add metadata for [rtp_2019].[sp_pm_E]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_E', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_E', 'MS_Description', 'performance metric E'
GO




-- Create stored procedure for performance metric #F
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_F]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_F]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_F]
	@scenario_id integer,
	@senior bit = 0, -- indicator to use senior population segmentation
	@minority bit = 0, -- indicator to use minority population segmentation
	@low_income bit = 0 -- indicator to use low income population segmentation
AS

/*	Author: Gregor Schroeder
	Date: 4/18/2018
	Description: Percent of income consumed by transportation costs
	  similar to Performance Measure 5A in the 2015 RTP
*/

IF CONVERT(int, @senior) + CONVERT(int, @minority) + CONVERT(int, @low_income) > 1
BEGIN
RAISERROR ('Select only one population segmentation.', 16, 1)
RETURN -1
END;

-- get maximum parking reimbursement percentage of person on the tour
	-- it is ok to do this at tour level since i, i-e, j trips all have tours
	-- limited to i, i-e, j trips since these use synthetic population
with [tour_freeparking_reimbpct] AS (
	SELECT 
		[tour_id]
		,CASE	WHEN MAX(CASE	WHEN [person].[freeparking_choice] IN ('Employer Pays for Parking',
																	   'Has Free Parking')
								THEN 1
								WHEN [person].[freeparking_choice] = 'Employer Reimburses for Parking'
								THEN [person].[freeparking_reimbpct]
								ELSE 0 END) > 1
				THEN 1
				ELSE MAX(CASE	WHEN [person].[freeparking_choice] IN ('Employer Pays for Parking',
																	   'Has Free Parking')
								THEN 1
								WHEN [person].[freeparking_choice] = 'Employer Reimburses for Parking'
								THEN [person].[freeparking_reimbpct]
								ELSE 0 END)
				END AS [freeparking_reimbpct]
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[model_trip]
	ON
		[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
	INNER JOIN
		[dimension].[mode_trip]
	ON
		[person_trip].[mode_trip_id] = [mode_trip].[mode_trip_id]
	INNER JOIN
		[dimension].[person]
	ON
		[person_trip].[scenario_id] = [person].[scenario_id]
		AND [person_trip].[person_id] = [person].[person_id]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
		AND [person].[scenario_id] = @scenario_id
		AND [model_trip].[model_trip_description] IN ('Individual',
													  'Internal-External',
													  'Joint') -- models that use synthetic population
		AND [mode_trip].[mode_trip_description] IN ('Drive Alone Non-Toll',
													'Drive Alone Toll Eligible',
													'Shared Ride 2 Non-Toll',
													'Shared Ride 2 Toll Eligible',
													'Shared Ride 3 Non-Toll',
													'Shared Ride 3 Toll Eligible') -- only take driving modes used in the i, i-e, and joint models
																				   -- it is assumed park and ride has free parking
	GROUP BY
		[tour_id]),
-- sum costs to the person level
-- auto = aoc split among riders, fare split among riders, and parking cost split among riders
	-- for individual and i-e models use mode to determine split (2 or 3.34), for joint model and drive alone use weight_trip
	-- for parking have to look at tour reimbursement and mgra based input parking costs
-- transit = transit fare
	-- for age >= 60 apply a 50% reduction
[person_costs] AS ( 
	SELECT
		[person_trip].[person_id]
		,[person_trip].[household_id]
		,SUM(([toll_cost_drive] + [operating_cost_drive]) * [weight_person_trip]) AS [cost_auto]
		,SUM(CASE	WHEN [mode_trip].[mode_trip_description] IN ('Drive Alone Non-Toll',
																 'Drive Alone Toll Eligible',
																 'Shared Ride 2 Non-Toll',
																 'Shared Ride 2 Toll Eligible',
																 'Shared Ride 3 Non-Toll',
																 'Shared Ride 3 Toll Eligible')
						AND [mparkcost] >= [dparkcost]
					THEN (1 - ISNULL([tour_freeparking_reimbpct].[freeparking_reimbpct], 0)) * [dparkcost] * [weight_person_trip]
					WHEN [mode_trip].[mode_trip_description] IN ('Drive Alone Non-Toll',
																 'Drive Alone Toll Eligible',
																 'Shared Ride 2 Non-Toll',
																 'Shared Ride 2 Toll Eligible',
																 'Shared Ride 3 Non-Toll',
																 'Shared Ride 3 Toll Eligible')
						AND [mparkcost] < [dparkcost]
					THEN (1 - ISNULL([tour_freeparking_reimbpct].[freeparking_reimbpct], 0)) * [mparkcost] * [weight_person_trip]
					ELSE 0 END) AS [cost_parking]
		,SUM(CASE	WHEN [person].[age] >= 60 THEN [cost_transit] * .5
					ELSE [cost_transit] END) AS [cost_transit]
		,MAX(CASE	WHEN [mode_trip].[mode_trip_description] IN ('Kiss and Ride to Transit - Local Bus and Premium Transit',
																 'Kiss and Ride to Transit - Premium Transit Only',
																 'Park and Ride to Transit - Local Bus and Premium Transit',
																 'Park and Ride to Transit - Premium Transit Only',
																 'Walk to Transit - Local Bus and Premium Transit',
																 'Walk to Transit - Premium Transit Only')
				THEN 1 ELSE 0 END) AS [premium_transit_indicator] -- indicate if premium transit was used for later transit fare cap
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[model_trip]
	ON
		[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
	INNER JOIN
		[dimension].[mode_trip]
	ON
		[person_trip].[mode_trip_id] = [mode_trip].[mode_trip_id]
	INNER JOIN
		[dimension].[person]
	ON
		[person_trip].[scenario_id] = [person].[scenario_id]
		AND [person_trip].[person_id] = [person].[person_id]
	LEFT OUTER JOIN
		[tour_freeparking_reimbpct]
	ON
		[person_trip].[scenario_id] = @scenario_id
		AND [person_trip].[tour_id] = [tour_freeparking_reimbpct].[tour_id]
	INNER JOIN
		[fact].[mgra_based_input]
	ON -- join works since i, i-e, j trips are all mgra based, do not need to account for tazs
		[person_trip].[scenario_id] = [mgra_based_input].[scenario_id]
		AND [person_trip].[geography_trip_destination_id] = [mgra_based_input].[geography_id]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
		AND [person].[scenario_id] = @scenario_id
		AND [mgra_based_input].[scenario_id] = @scenario_id
		AND [model_trip].[model_trip_description] IN ('Individual',
													  'Internal-External',
													  'Joint') -- models that use synthetic population
	GROUP BY
		[person_trip].[person_id]
		,[person_trip].[household_id]),
[household_costs] AS (
	SELECT
		-- multiply the person cost by 300 to get annual cost and sum over the household to get household costs
		-- cap person transit costs at $12 or $5 depending on if they used premium or non-premium transit
		[person_costs].[household_id]
		,SUM(300.0 * ([cost_auto] + [cost_parking] +
			 CASE	WHEN [premium_transit_indicator] = 1 AND [cost_transit] > 12 THEN 12
					WHEN [premium_transit_indicator] = 0 AND [cost_transit] > 5 THEN 5
					ELSE [cost_transit] END)) AS [cost_annual_transportation]							
	FROM
		[person_costs]
	GROUP BY
		[person_costs].[household_id])
SELECT
	@scenario_id AS [scenario_id]
	,ISNULL(CASE	WHEN @senior = 1 THEN [senior]
					WHEN @minority = 1 THEN [minority]
					WHEN @low_income = 1 THEN [low_income]
					ELSE 'All' END, 'Total') AS [pop_segmentation]
	,AVG(100.0 * CASE	WHEN [household_costs].[cost_annual_transportation] / [coc_households].[income] > 1 THEN 1
						ELSE [household_costs].[cost_annual_transportation] / [coc_households].[income]
						END) AS [pct_income_transportation_cost] -- cap percentage cost at 100% of income
FROM
	[household_costs]
INNER JOIN (-- only keeping households that actually travelled
	SELECT
		[household].[household_id]
		,[household].[income]
		,CASE	WHEN MAX(CASE WHEN [person].[age] >= 75 THEN 1 ELSE 0 END) = 1 THEN 'Senior'
				WHEN MAX(CASE WHEN [person].[age] >= 75 THEN 1 ELSE 0 END) = 0 THEN 'Non-Senior'
				ELSE NULL END AS [senior]
		,CASE	WHEN MAX(CASE	WHEN [person].[race] IN ('Some Other Race Alone',
														 'Asian Alone',
														 'Black or African American Alone',
														 'Two or More Major Race Groups',
														 'Native Hawaiian and Other Pacific Islander Alone',
														 'American Indian and Alaska Native Tribes specified; or American Indian or Alaska Native, not specified and no other races')
								OR [person].[hispanic] = 'Hispanic' THEN 1 ELSE 0 END) = 1
				THEN 'Minority'
				WHEN MAX(CASE	WHEN [person].[race] IN ('Some Other Race Alone',
														 'Asian Alone',
														 'Black or African American Alone',
														 'Two or More Major Race Groups',
														 'Native Hawaiian and Other Pacific Islander Alone',
														 'American Indian and Alaska Native Tribes specified; or American Indian or Alaska Native, not specified and no other races')
								OR [person].[hispanic] = 'Hispanic' THEN 1 ELSE 0 END) = 0
				THEN 'Non-Minority' 
				ELSE NULL END AS [minority]
		,CASE	WHEN MAX(CASE WHEN [household].[poverty] <= 2 THEN 1 ELSE 0 END) = 1
				THEN 'Low Income'
				WHEN MAX(CASE WHEN [household].[poverty] <= 2 THEN 1 ELSE 0 END) = 0
				THEN 'Non-Low Income'
				ELSE NULL END AS [low_income]
	FROM
		[dimension].[household]
	INNER JOIN
		[dimension].[person]
	ON
		[household].[scenario_id] = [person].[scenario_id]
		AND [household].[household_id] = [person].[household_id]
	WHERE
		[household].[scenario_id] = @scenario_id
		AND [person].[scenario_id] = @scenario_id
	GROUP BY
		[household].[household_id]
		,[household].[income]) AS [coc_households]
ON
	[household_costs].[household_id] = [coc_households].[household_id]
GROUP BY
	CASE	WHEN @senior = 1 THEN [senior]
			WHEN @minority = 1 THEN [minority]
			WHEN @low_income = 1 THEN [low_income]
			ELSE 'All' END
WITH ROLLUP
OPTION(MAXDOP 1)
GO

-- Add metadata for [rtp_2019].[sp_pm_F]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_F', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_F', 'MS_Description', 'performance metric F'
GO




-- Create stored procedure for performance metric #H
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_H]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_H]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_H]
	@scenario_id integer,
	@senior bit = 0, -- indicator to use senior population segmentation
	@minority bit = 0, -- indicator to use minority population segmentation
	@low_income bit = 0 -- indicator to use low income population segmentation
AS

/*	Author: Ziying Ouyang and Gregor Schroeder
	Date: Revised 4/12/2018
	Description: Percent of population engaging in more than 20 minutes of daily transportation related physical activity
	  formerly Performance Measure 7F in the 2015 RTP
*/

IF CONVERT(int, @senior) + CONVERT(int, @minority) + CONVERT(int, @low_income) > 1
BEGIN
RAISERROR ('Select only one population segmentation.', 16, 1)
RETURN -1
END;

SELECT
	@scenario_id AS [scenario_id]
	,ISNULL(CASE	WHEN @senior = 1 THEN [senior]
					WHEN @minority = 1 THEN [minority]
					WHEN @low_income = 1 THEN [low_income]
					ELSE 'All' END, 'Total') AS [pop_segmentation]
	,100.0 * SUM(CASE WHEN ISNULL([physical_activity].[time_physical_activity], 0) >= 20 THEN [person_coc].[weight_person] ELSE 0 END) / SUM([person_coc].[weight_person]) AS [pct_physical_activity_population]
	,SUM(CASE WHEN ISNULL([physical_activity].[time_physical_activity], 0) >= 20 THEN [person_coc].[weight_person] ELSE 0 END) AS [physical_activity_population]
	,SUM([person_coc].[weight_person]) AS [population]
FROM (
	SELECT
		[person_id]
		,[weight_person]
		,CASE	WHEN [person].[age] >= 75 THEN 'Senior'
				WHEN [person].[age] < 75 THEN 'Non-Senior'
				ELSE NULL END AS [senior]
		,CASE	WHEN [person].[race] IN ('Some Other Race Alone',
										 'Asian Alone',
										 'Black or African American Alone',
										 'Two or More Major Race Groups',
										 'Native Hawaiian and Other Pacific Islander Alone',
										 'American Indian and Alaska Native Tribes specified; or American Indian or Alaska Native, not specified and no other races')
					OR [person].[hispanic] = 'Hispanic'
				THEN 'Minority'
				ELSE 'Non-Minority' END AS [minority]
		,CASE	WHEN [household].[poverty] <= 2 THEN 'Low Income'
				WHEN [household].[poverty] > 2 THEN 'Non-Low Income'
				ELSE NULL END AS [low_income]
	FROM
		[dimension].[person]
	INNER JOIN
		[dimension].[household]
	ON
		[person].[scenario_id] = [household].[scenario_id]
		AND [person].[household_id] = [household].[household_id]
	WHERE
		[person].[scenario_id] = @scenario_id
		AND [household].[scenario_id] = @scenario_id
		AND [person].[weight_person] > 0) AS [person_coc]
LEFT OUTER JOIN ( -- keep persons who do not travel
	SELECT
		[person_id]
		,SUM([time_walk] + [time_bike]) AS [time_physical_activity]
	FROM
		[fact].[person_trip]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
	GROUP BY
		[person_id]) AS [physical_activity]
ON
	[person_coc].[person_id] = [physical_activity].[person_id]
GROUP BY
	CASE	WHEN @senior = 1 THEN [senior]
			WHEN @minority = 1 THEN [minority]
			WHEN @low_income = 1 THEN [low_income]
			ELSE 'All' END
WITH ROLLUP
OPTION(MAXDOP 1)
GO

-- Add metadata for [rtp_2019].[sp_pm_H]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_H', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_H', 'MS_Description', 'performance metric H'
GO




-- Create stored procedure for pmt and bmt inputs to performance measures 3a/3b
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_3ab_pmt_bmt]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_3ab_pmt_bmt]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_3ab_pmt_bmt]
	@scenario_id integer
AS

/*	Author: Ziying Ouyang and Gregor Schroeder
	Date: Revised 4/20/2018
	Description: Person and bicycle miles travelled used in Performance Measures 3a/3b
	  similar to sp_pmt_bmt in the 2015 RTP */

SELECT
	@scenario_id AS [scenario_id]
	,SUM([dist_bike]) AS [bmt]
	,SUM([dist_walk]) AS [pmt] -- includes transit walk distances
FROM
	[fact].[person_trip]
INNER JOIN
	[dimension].[model_trip]
ON
	[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
WHERE
	[person_trip].[scenario_id] = @scenario_id
	AND [model_trip].[model_trip_description] IN ('Airport - CBX',
												  'Airport - SAN',
												  'Cross Border',
												  'Individual',
												  'Internal-External',
												  'Joint',
												  'Visitor') -- all microsimulated trips excepting commercial vehicle model
GO

-- Add metadata for [rtp_2019].[sp_pm_3ab_pmt_bmt]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_3ab_pmt_bmt', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_3ab_pmt_bmt', 'MS_Description', 'person and bicycle miles travelled used for performance measures 3a/3b'
GO




-- Create stored procedure for vmt input to performance measure 3a/3b
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[rtp_2019].[sp_pm_3ab_vmt]') AND type in (N'P', N'PC'))
DROP PROCEDURE [rtp_2019].[sp_pm_3ab_vmt]
GO

CREATE PROCEDURE [rtp_2019].[sp_pm_3ab_vmt]
	@scenario_id integer
AS

/*	Author: Ziying Ouyang and Gregor Schroeder
	Date: Revised 4/20/2018
	Description: Vehicle miles travelled used in Performance Measures 3a/3b
	  formerly sp_eval_vmt in the 2015 RTP */

SELECT 
	@scenario_id AS [scenario_id]
	,SUM([hwy_flow].[flow] * [hwy_link].[length_mile]) AS [vmt]
	,SUM(CASE WHEN [hwy_link].[ijur] = 1 THEN [flow] * [hwy_link].[length_mile] ELSE 0 END) AS [vmt_ijur1]
	,SUM([hwy_flow_mode_wide].[flow_auto] * [hwy_link].[length_mile]) AS [vmt_auto]
	,SUM([hwy_flow_mode_wide].[flow_truck] * [hwy_link].[length_mile]) AS [vmt_truck]
	,SUM([hwy_flow_mode_wide].[flow_bus] * [hwy_link].[length_mile]) / 3.0 AS [vmt_bus]
FROM
	[fact].[hwy_flow]
INNER JOIN
	[dimension].[hwy_link]
ON
	[hwy_flow].[scenario_id] = [hwy_link].[scenario_id]
	AND [hwy_flow].[hwy_link_id] = [hwy_link].[hwy_link_id]
INNER JOIN (
	SELECT
		[hwy_link_ab_tod_id]
		,SUM(CASE	WHEN [mode].[mode_description] IN ('Drive Alone Non-Toll',
													   'Drive Alone Toll Eligible',
													   'Shared Ride 2 Non-Toll',
													   'Shared Ride 2 Toll Eligible',
													   'Shared Ride 3 Non-Toll',
													   'Shared Ride 3 Toll Eligible')
					THEN [flow] ELSE 0 END) AS [flow_auto]
		,SUM(CASE	WHEN [mode].[mode_description] IN ('Heavy Heavy Duty Truck (Non-Toll)',
													   'Heavy Heavy Duty Truck (Toll)',
													   'Light Heavy Duty Truck (Non-Toll)',
													   'Light Heavy Duty Truck (Toll)',
													   'Medium Heavy Duty Truck (Non-Toll)',
													   'Medium Heavy Duty Truck (Toll)')
					THEN [flow] ELSE 0 END) AS [flow_truck]
		,SUM(CASE	WHEN [mode].[mode_description] = 'Highway Network Preload - Bus'
					THEN [flow] ELSE 0 END) AS [flow_bus]
	FROM
		[fact].[hwy_flow_mode]
	INNER JOIN
		[dimension].[mode]
	ON
		[hwy_flow_mode].[mode_id] = [mode].[mode_id]
	WHERE
		[scenario_id] = @scenario_id
	GROUP BY
		[hwy_link_ab_tod_id]) AS [hwy_flow_mode_wide]
ON
	[hwy_flow].[scenario_id] = @scenario_id
	AND [hwy_flow].[hwy_link_ab_tod_id] = [hwy_flow_mode_wide].[hwy_link_ab_tod_id]
WHERE
	[hwy_flow].[scenario_id] = @scenario_id
	AND [hwy_link].[scenario_id] = @scenario_id
GO

-- Add metadata for [rtp_2019].[sp_pm_3ab_vmt]
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_3ab_vmt', 'SUBSYSTEM', 'rtp 2019'
EXECUTE [db_meta].[add_xp] 'rtp_2019.sp_pm_3ab_vmt', 'MS_Description', 'vehicle miles travelled used for performance measures 3a/3b'
GO