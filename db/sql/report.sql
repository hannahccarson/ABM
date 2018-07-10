-- Create report schema
IF NOT EXISTS (SELECT schema_name FROM information_schema.schemata WHERE schema_name='report')
EXEC ('CREATE SCHEMA [report]')
GO

-- Add metadata for [report]
IF EXISTS(SELECT * FROM [db_meta].[data_dictionary] WHERE [ObjectType] = 'SCHEMA' AND [FullObjectName] = '[report]' AND [PropertyName] = 'MS_Description')
EXECUTE [db_meta].[drop_xp] 'report', 'MS_Description'

EXECUTE [db_meta].[add_xp] 'report', 'MS_Description', 'schema to hold all objects associated with reporting outputs of the abm model'
GO




-- grant read/execute permissions to abm_user role
GRANT EXECUTE ON SCHEMA :: [report] TO [abm_user]
GRANT SELECT ON SCHEMA :: [report] TO [abm_user]
GRANT VIEW DEFINITION ON SCHEMA :: [report] TO [abm_user]




-- Create bike flow report view
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('[report].[bike_flow]') AND type in ('V'))
DROP VIEW [report].[bike_flow]
GO

CREATE VIEW [report].[bike_flow] AS
	SELECT
		[bike_flow].[scenario_id]
		,[bike_flow].[bike_link_id]
		,[bike_link].[roadsegid]
		,[bike_link].[nm]
		,[bike_link].[functional_class]
		,[bike_link].[bike2sep]
		,[bike_link].[bike3blvd]
		,[bike_link].[speed]
		,[bike_link].[distance]
		,[bike_link].[scenicldx]
		,[bike_link].[shape]
		,[bike_flow].[bike_link_ab_id]
		,[bike_link_ab].[ab]
		,[bike_link_ab].[from_node]
		,[bike_link_ab].[to_node]
		,[bike_link_ab].[gain]
		,[bike_link_ab].[bike_class]
		,[bike_link_ab].[lanes]
		,[bike_link_ab].[from_signal]
		,[bike_link_ab].[to_signal]
		,[bike_flow].[time_id]
		,[time].[abm_half_hour]
		,[time].[abm_half_hour_period_start]
		,[time].[abm_half_hour_period_end]
		,[time].[abm_5_tod]
		,[time].[abm_5_tod_period_start]
		,[time].[abm_5_tod_period_end]
		,[time].[day]
		,[time].[day_period_start]
		,[time].[day_period_end]
		,[bike_flow].[flow]
	FROM
		[fact].[bike_flow]
	INNER JOIN
		[dimension].[bike_link]
	ON
		[bike_flow].[scenario_id] = [bike_link].[scenario_id]
		AND [bike_flow].[bike_link_id] = [bike_link].[bike_link_id]
	INNER JOIN
		[dimension].[bike_link_ab]
	ON
		[bike_flow].[scenario_id] = [bike_link_ab].[scenario_id]
		AND [bike_flow].[bike_link_ab_id] = [bike_link_ab].[bike_link_ab_id]
	INNER JOIN
		[dimension].[time]
	ON
		[bike_flow].[time_id] = [time].[time_id]
GO

-- Add metadata for [report].[bike_flow]
EXECUTE [db_meta].[add_xp] 'report.bike_flow', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.bike_flow', 'MS_Description', 'bike flow fact table joined to all dimension tables'
GO




-- Create highway flow report view
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('[report].[hwy_flow]') AND type in ('V'))
DROP VIEW [report].[hwy_flow]
GO

CREATE VIEW [report].[hwy_flow] AS
	SELECT
		[hwy_flow].[scenario_id]
		,[hwy_flow].[hwy_flow_id]
		,[hwy_flow].[hwy_link_id]
		,[hwy_link].[hwycov_id]
		,[hwy_link].[length_mile]
		,[hwy_link].[sphere]
		,[hwy_link].[nm]
		,[hwy_link].[cojur]
		,[hwy_link].[costat]
		,[hwy_link].[coloc]
		,[hwy_link].[rloop]
		,[hwy_link].[adtlk]
		,[hwy_link].[adtvl]
		,[hwy_link].[aspd]
		,[hwy_link].[iyr]
		,[hwy_link].[iproj]
		,[hwy_link].[ijur]
		,[hwy_link].[ifc]
		,[hwy_link].[ihov]
		,[hwy_link].[itruck]
		,[hwy_link].[ispd]
		,[hwy_link].[iway]
		,[hwy_link].[imed]
		,[hwy_link].[shape]
		,[hwy_flow].[hwy_link_ab_id]
		,[hwy_link_ab].[ab]
		,[hwy_link_ab].[from_node]
		,[hwy_link_ab].[to_node]
		,[hwy_link_ab].[from_nm]
		,[hwy_link_ab].[to_nm]
		,[hwy_link_ab].[au]
		,[hwy_link_ab].[pct]
		,[hwy_link_ab].[cnt]
		,[hwy_flow].[hwy_link_tod_id]
		,[hwy_link_tod].[itoll]
		,[hwy_link_tod].[itoll2]
		,[hwy_link_tod].[itoll3]
		,[hwy_link_tod].[itoll4]
		,[hwy_link_tod].[itoll5]
		,[hwy_flow].[hwy_link_ab_tod_id]
		,[hwy_link_ab_tod].[cp]
		,[hwy_link_ab_tod].[cx]
		,[hwy_link_ab_tod].[tm]
		,[hwy_link_ab_tod].[tx]
		,[hwy_link_ab_tod].[ln]
		,[hwy_link_ab_tod].[stm]
		,[hwy_link_ab_tod].[htm]
		,[hwy_flow].[time_id]
		,[time].[abm_half_hour]
		,[time].[abm_half_hour_period_start]
		,[time].[abm_half_hour_period_end]
		,[time].[abm_5_tod]
		,[time].[abm_5_tod_period_start]
		,[time].[abm_5_tod_period_end]
		,[time].[day]
		,[time].[day_period_start]
		,[time].[day_period_end]
		,[hwy_flow].[flow_pce]
		,[hwy_flow].[time]
		,[hwy_flow].[voc]
		,[hwy_flow].[v_dist_t]
		,[hwy_flow].[vht]
		,[hwy_flow].[speed]
		,[hwy_flow].[vdf]
		,[hwy_flow].[msa_flow]
		,[hwy_flow].[msa_time]
		,[hwy_flow].[flow]
	FROM
		[fact].[hwy_flow]
	INNER JOIN
		[dimension].[hwy_link]
	ON
		[hwy_flow].[scenario_id] = [hwy_link].[scenario_id]
		AND [hwy_flow].[hwy_link_id] = [hwy_link].[hwy_link_id]
	INNER JOIN
		[dimension].[hwy_link_ab]
	ON
		[hwy_flow].[scenario_id] = [hwy_link_ab].[scenario_id]
		AND [hwy_flow].[hwy_link_ab_id] = [hwy_link_ab].[hwy_link_ab_id]
	INNER JOIN
		[dimension].[hwy_link_tod]
	ON
		[hwy_flow].[scenario_id] = [hwy_link_tod].[scenario_id]
		AND [hwy_flow].[hwy_link_tod_id] = [hwy_link_tod].[hwy_link_tod_id]
	INNER JOIN
		[dimension].[hwy_link_ab_tod]
	ON
		[hwy_flow].[scenario_id] = [hwy_link_ab_tod].[scenario_id]
		AND [hwy_flow].[hwy_link_ab_tod_id] = [hwy_link_ab_tod].[hwy_link_ab_tod_id]
	INNER JOIN
		[dimension].[time]
	ON
		[hwy_flow].[time_id] = [time].[time_id]
GO

-- Add metadata for [report].[hwy_flow]
EXECUTE [db_meta].[add_xp] 'report.hwy_flow', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.hwy_flow', 'MS_Description', 'highway flow fact table joined to all dimension tables'
GO




-- Create highway flow by mode report view
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('[report].[hwy_flow_mode]') AND type in ('V'))
DROP VIEW [report].[hwy_flow_mode]
GO

CREATE VIEW [report].[hwy_flow_mode] AS
	SELECT
		[hwy_flow_mode].[scenario_id]
		,[hwy_flow_mode].[hwy_flow_mode_id]
		,[hwy_flow_mode].[hwy_link_id]
		,[hwy_link].[hwycov_id]
		,[hwy_link].[length_mile]
		,[hwy_link].[sphere]
		,[hwy_link].[nm]
		,[hwy_link].[cojur]
		,[hwy_link].[costat]
		,[hwy_link].[coloc]
		,[hwy_link].[rloop]
		,[hwy_link].[adtlk]
		,[hwy_link].[adtvl]
		,[hwy_link].[aspd]
		,[hwy_link].[iyr]
		,[hwy_link].[iproj]
		,[hwy_link].[ijur]
		,[hwy_link].[ifc]
		,[hwy_link].[ihov]
		,[hwy_link].[itruck]
		,[hwy_link].[ispd]
		,[hwy_link].[iway]
		,[hwy_link].[imed]
		,[hwy_link].[shape]
		,[hwy_flow_mode].[hwy_link_ab_id]
		,[hwy_link_ab].[ab]
		,[hwy_link_ab].[from_node]
		,[hwy_link_ab].[to_node]
		,[hwy_link_ab].[from_nm]
		,[hwy_link_ab].[to_nm]
		,[hwy_link_ab].[au]
		,[hwy_link_ab].[pct]
		,[hwy_link_ab].[cnt]
		,[hwy_flow_mode].[hwy_link_tod_id]
		,[hwy_link_tod].[itoll]
		,[hwy_link_tod].[itoll2]
		,[hwy_link_tod].[itoll3]
		,[hwy_link_tod].[itoll4]
		,[hwy_link_tod].[itoll5]
		,[hwy_flow_mode].[hwy_link_ab_tod_id]
		,[hwy_link_ab_tod].[cp]
		,[hwy_link_ab_tod].[cx]
		,[hwy_link_ab_tod].[tm]
		,[hwy_link_ab_tod].[tx]
		,[hwy_link_ab_tod].[ln]
		,[hwy_link_ab_tod].[stm]
		,[hwy_link_ab_tod].[htm]
		,[hwy_flow_mode].[time_id]
		,[time].[abm_half_hour]
		,[time].[abm_half_hour_period_start]
		,[time].[abm_half_hour_period_end]
		,[time].[abm_5_tod]
		,[time].[abm_5_tod_period_start]
		,[time].[abm_5_tod_period_end]
		,[time].[day]
		,[time].[day_period_start]
		,[time].[day_period_end]
		,[hwy_flow_mode].[mode_id]
		,[mode].[mode_description]
		,[hwy_flow_mode].[flow]
	FROM
		[fact].[hwy_flow_mode]
	INNER JOIN
		[dimension].[hwy_link]
	ON
		[hwy_flow_mode].[scenario_id] = [hwy_link].[scenario_id]
		AND [hwy_flow_mode].[hwy_link_id] = [hwy_link].[hwy_link_id]
	INNER JOIN
		[dimension].[hwy_link_ab]
	ON
		[hwy_flow_mode].[scenario_id] = [hwy_link_ab].[scenario_id]
		AND [hwy_flow_mode].[hwy_link_ab_id] = [hwy_link_ab].[hwy_link_ab_id]
	INNER JOIN
		[dimension].[hwy_link_tod]
	ON
		[hwy_flow_mode].[scenario_id] = [hwy_link_tod].[scenario_id]
		AND [hwy_flow_mode].[hwy_link_tod_id] = [hwy_link_tod].[hwy_link_tod_id]
	INNER JOIN
		[dimension].[hwy_link_ab_tod]
	ON
		[hwy_flow_mode].[scenario_id] = [hwy_link_ab_tod].[scenario_id]
		AND [hwy_flow_mode].[hwy_link_ab_tod_id] = [hwy_link_ab_tod].[hwy_link_ab_tod_id]
	INNER JOIN
		[dimension].[time]
	ON
		[hwy_flow_mode].[time_id] = [time].[time_id]
	INNER JOIN
		[dimension].[mode]
	ON
		[hwy_flow_mode].[mode_id] = [mode].[mode_id]
GO

-- Add metadata for [report].[hwy_flow_mode]
EXECUTE [db_meta].[add_xp] 'report.hwy_flow_mode', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.hwy_flow_mode', 'MS_Description', 'highway flow by mode fact table joined to all dimension tables'
GO




-- Create mgra based input report view
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('[report].[mgra_based_input]') AND type in ('V'))
DROP VIEW [report].[mgra_based_input]
GO

CREATE VIEW [report].[mgra_based_input] AS
	SELECT
		[mgra_based_input].[scenario_id]
		,[mgra_based_input].[mgra_based_input_id]
		,[mgra_based_input].[geography_id]
		,[geography].[mgra_13]
		,[geography].[mgra_13_shape]
		,[geography].[taz_13]
		,[geography].[taz_13_shape]
		,[geography].[luz_13]
		,[geography].[luz_13_shape]
		,[geography].[cicpa_2016]
		,[geography].[cicpa_2016_name]
		,[geography].[cicpa_2016_shape]
		,[geography].[cocpa_2016]
		,[geography].[cocpa_2016_name]
		,[geography].[cocpa_2016_shape]
		,[geography].[jurisdiction_2016]
		,[geography].[jurisdiction_2016_name]
		,[geography].[jurisdiction_2016_shape]
		,[geography].[region_2004]
		,[geography].[region_2004_name]
		,[geography].[region_2004_shape]
		,[geography].[external_zone]
		,[mgra_based_input].[hs]
		,[mgra_based_input].[hs_sf]
		,[mgra_based_input].[hs_mf]
		,[mgra_based_input].[hs_mh]
		,[mgra_based_input].[hh]
		,[mgra_based_input].[hh_sf]
		,[mgra_based_input].[hh_mf]
		,[mgra_based_input].[hh_mh]
		,[mgra_based_input].[gq_civ]
		,[mgra_based_input].[gq_mil]
		,[mgra_based_input].[i1]
		,[mgra_based_input].[i2]
		,[mgra_based_input].[i3]
		,[mgra_based_input].[i4]
		,[mgra_based_input].[i5]
		,[mgra_based_input].[i6]
		,[mgra_based_input].[i7]
		,[mgra_based_input].[i8]
		,[mgra_based_input].[i9]
		,[mgra_based_input].[i10]
		,[mgra_based_input].[hhs]
		,[mgra_based_input].[pop]
		,[mgra_based_input].[hhp]
		,[mgra_based_input].[emp_ag]
		,[mgra_based_input].[emp_const_non_bldg_prod]
		,[mgra_based_input].[emp_const_non_bldg_office]
		,[mgra_based_input].[emp_utilities_prod]
		,[mgra_based_input].[emp_utilities_office]
		,[mgra_based_input].[emp_const_bldg_prod]
		,[mgra_based_input].[emp_const_bldg_office]
		,[mgra_based_input].[emp_mfg_prod]
		,[mgra_based_input].[emp_mfg_office]
		,[mgra_based_input].[emp_whsle_whs]
		,[mgra_based_input].[emp_trans]
		,[mgra_based_input].[emp_retail]
		,[mgra_based_input].[emp_prof_bus_svcs]
		,[mgra_based_input].[emp_prof_bus_svcs_bldg_maint]
		,[mgra_based_input].[emp_pvt_ed_k12]
		,[mgra_based_input].[emp_pvt_ed_post_k12_oth]
		,[mgra_based_input].[emp_health]
		,[mgra_based_input].[emp_personal_svcs_office]
		,[mgra_based_input].[emp_amusement]
		,[mgra_based_input].[emp_hotel]
		,[mgra_based_input].[emp_restaurant_bar]
		,[mgra_based_input].[emp_personal_svcs_retail]
		,[mgra_based_input].[emp_religious]
		,[mgra_based_input].[emp_pvt_hh]
		,[mgra_based_input].[emp_state_local_gov_ent]
		,[mgra_based_input].[emp_fed_non_mil]
		,[mgra_based_input].[emp_fed_mil]
		,[mgra_based_input].[emp_state_local_gov_blue]
		,[mgra_based_input].[emp_state_local_gov_white]
		,[mgra_based_input].[emp_public_ed]
		,[mgra_based_input].[emp_own_occ_dwell_mgmt]
		,[mgra_based_input].[emp_fed_gov_accts]
		,[mgra_based_input].[emp_st_lcl_gov_accts]
		,[mgra_based_input].[emp_cap_accts]
		,[mgra_based_input].[emp_total]
		,[mgra_based_input].[enrollgradekto8]
		,[mgra_based_input].[enrollgrade9to12]
		,[mgra_based_input].[collegeenroll]
		,[mgra_based_input].[othercollegeenroll]
		,[mgra_based_input].[adultschenrl]
		,[mgra_based_input].[ech_dist]
		,[mgra_based_input].[hch_dist]
		,[mgra_based_input].[pseudomsa]
		,[mgra_based_input].[parkarea]
		,[mgra_based_input].[hstallsoth]
		,[mgra_based_input].[hstallssam]
		,[mgra_based_input].[hparkcost]
		,[mgra_based_input].[numfreehrs]
		,[mgra_based_input].[dstallsoth]
		,[mgra_based_input].[dstallssam]
		,[mgra_based_input].[dparkcost]
		,[mgra_based_input].[mstallsoth]
		,[mgra_based_input].[mstallssam]
		,[mgra_based_input].[mparkcost]
		,[mgra_based_input].[totint]
		,[mgra_based_input].[duden]
		,[mgra_based_input].[empden]
		,[mgra_based_input].[popden]
		,[mgra_based_input].[retempden]
		,[mgra_based_input].[totintbin]
		,[mgra_based_input].[empdenbin]
		,[mgra_based_input].[dudenbin]
		,[mgra_based_input].[zip09]
		,[mgra_based_input].[parkactive]
		,[mgra_based_input].[openspaceparkpreserve]
		,[mgra_based_input].[beachactive]
		,[mgra_based_input].[budgetroom]
		,[mgra_based_input].[economyroom]
		,[mgra_based_input].[luxuryroom]
		,[mgra_based_input].[midpriceroom]
		,[mgra_based_input].[upscaleroom]
		,[mgra_based_input].[hotelroomtotal]
		,[mgra_based_input].[truckregiontype]
		,[mgra_based_input].[district27]
		,[mgra_based_input].[milestocoast]
		,[mgra_based_input].[acres]
		,[mgra_based_input].[effective_acres]
		,[mgra_based_input].[land_acres]
	FROM
		[fact].[mgra_based_input]
	INNER JOIN
		[dimension].[geography]
	ON
		[mgra_based_input].[geography_id] = [geography].[geography_id]
GO

-- Add metadata for [report].[mgra_based_input]
EXECUTE [db_meta].[add_xp] 'report.mgra_based_input', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.mgra_based_input', 'MS_Description', 'mgra based input fact table joined to all dimension tables'
GO




-- Create person trip report view
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('[report].[person_trip]') AND type in ('V'))
DROP VIEW [report].[person_trip]
GO

CREATE VIEW [report].[person_trip] AS
	SELECT
		[person_trip].[scenario_id]
		,[person_trip].[person_trip_id]
		,[person_trip].[person_id]
		,[person].[age]
		,[person].[sex]
		,[person].[military_status]
		,[person].[employment_status]
		,[person].[student_status]
		,[person].[abm_person_type]
		,[person].[education]
		,[person].[grade]
		,[person].[weeks]
		,[person].[hours]
		,[person].[race]
		,[person].[hispanic]
		,[person].[version_person]
		,[person].[abm_activity_pattern]
		,[person].[freeparking_choice]
		,[person].[freeparking_reimbpct]
		,[person].[work_segment]
		,[person].[school_segment]
		,[person].[geography_work_location_id]
		,[geography_work_location].[work_location_mgra_13]
		,[geography_work_location].[work_location_mgra_13_shape]
		,[geography_work_location].[work_location_taz_13]
		,[geography_work_location].[work_location_taz_13_shape]
		,[geography_work_location].[work_location_luz_13]
		,[geography_work_location].[work_location_luz_13_shape]
		,[geography_work_location].[work_location_cicpa_2016]
		,[geography_work_location].[work_location_cicpa_2016_name]
		,[geography_work_location].[work_location_cicpa_2016_shape]
		,[geography_work_location].[work_location_cocpa_2016]
		,[geography_work_location].[work_location_cocpa_2016_name]
		,[geography_work_location].[work_location_cocpa_2016_shape]
		,[geography_work_location].[work_location_jurisdiction_2016]
		,[geography_work_location].[work_location_jurisdiction_2016_name]
		,[geography_work_location].[work_location_jurisdiction_2016_shape]
		,[geography_work_location].[work_location_region_2004]
		,[geography_work_location].[work_location_region_2004_name]
		,[geography_work_location].[work_location_region_2004_shape]
		,[geography_work_location].[work_location_external_zone]
		,[person].[geography_school_location_id]
		,[geography_school_location].[school_location_mgra_13]
		,[geography_school_location].[school_location_mgra_13_shape]
		,[geography_school_location].[school_location_taz_13]
		,[geography_school_location].[school_location_taz_13_shape]
		,[geography_school_location].[school_location_luz_13]
		,[geography_school_location].[school_location_luz_13_shape]
		,[geography_school_location].[school_location_cicpa_2016]
		,[geography_school_location].[school_location_cicpa_2016_name]
		,[geography_school_location].[school_location_cicpa_2016_shape]
		,[geography_school_location].[school_location_cocpa_2016]
		,[geography_school_location].[school_location_cocpa_2016_name]
		,[geography_school_location].[school_location_cocpa_2016_shape]
		,[geography_school_location].[school_location_jurisdiction_2016]
		,[geography_school_location].[school_location_jurisdiction_2016_name]
		,[geography_school_location].[school_location_jurisdiction_2016_shape]
		,[geography_school_location].[school_location_region_2004]
		,[geography_school_location].[school_location_region_2004_name]
		,[geography_school_location].[school_location_region_2004_shape]
		,[geography_school_location].[school_external_zone]
		,[person].[work_distance]
		,[person].[school_distance]
		,[person].[weight_person]
		,[person_trip].[household_id]
		,[household].[income]
		,[household].[income_category]
		,[household].[household_size]
		,[household].[bldgsz]
		,[household].[unittype]
		,[household].[autos]
		,[household].[transponder]
		,[household].[poverty]
		,[household].[geography_household_location_id]
		,[geography_household_location].[household_location_mgra_13]
		,[geography_household_location].[household_location_mgra_13_shape]
		,[geography_household_location].[household_location_taz_13]
		,[geography_household_location].[household_location_taz_13_shape]
		,[geography_household_location].[household_location_luz_13]
		,[geography_household_location].[household_location_luz_13_shape]
		,[geography_household_location].[household_location_cicpa_2016]
		,[geography_household_location].[household_location_cicpa_2016_name]
		,[geography_household_location].[household_location_cicpa_2016_shape]
		,[geography_household_location].[household_location_cocpa_2016]
		,[geography_household_location].[household_location_cocpa_2016_name]
		,[geography_household_location].[household_location_cocpa_2016_shape]
		,[geography_household_location].[household_location_jurisdiction_2016]
		,[geography_household_location].[household_location_jurisdiction_2016_name]
		,[geography_household_location].[household_location_jurisdiction_2016_shape]
		,[geography_household_location].[household_location_region_2004]
		,[geography_household_location].[household_location_region_2004_name]
		,[geography_household_location].[household_location_region_2004_shape]
		,[geography_household_location].[household_external_zone]
		,[household].[version_household]
		,[household].[weight_household]
		,[person_trip].[tour_id]
		,[tour].[model_tour_id]
		,[model_tour].[model_tour_description]
		,[tour].[abm_tour_id]
		,[tour].[time_tour_start_id]
		,[time_tour_start].[tour_start_abm_half_hour]
		,[time_tour_start].[tour_start_abm_half_hour_period_start]
		,[time_tour_start].[tour_start_abm_half_hour_period_end]
		,[time_tour_start].[tour_start_abm_5_tod]
		,[time_tour_start].[tour_start_abm_5_tod_period_start]
		,[time_tour_start].[tour_start_abm_5_tod_period_end]
		,[time_tour_start].[tour_start_day]
		,[time_tour_start].[tour_start_day_period_start]
		,[time_tour_start].[tour_start_day_period_end]
		,[tour].[time_tour_end_id]
		,[time_tour_end].[tour_end_abm_half_hour]
		,[time_tour_end].[tour_end_abm_half_hour_period_start]
		,[time_tour_end].[tour_end_abm_half_hour_period_end]
		,[time_tour_end].[tour_end_abm_5_tod]
		,[time_tour_end].[tour_end_abm_5_tod_period_start]
		,[time_tour_end].[tour_end_abm_5_tod_period_end]
		,[time_tour_end].[tour_end_day]
		,[time_tour_end].[tour_end_day_period_start]
		,[time_tour_end].[tour_end_day_period_end]
		,[tour].[geography_tour_origin_id]
		,[geography_tour_origin].[tour_origin_mgra_13]
		,[geography_tour_origin].[tour_origin_mgra_13_shape]
		,[geography_tour_origin].[tour_origin_taz_13]
		,[geography_tour_origin].[tour_origin_taz_13_shape]
		,[geography_tour_origin].[tour_origin_luz_13]
		,[geography_tour_origin].[tour_origin_luz_13_shape]
		,[geography_tour_origin].[tour_origin_cicpa_2016]
		,[geography_tour_origin].[tour_origin_cicpa_2016_name]
		,[geography_tour_origin].[tour_origin_cicpa_2016_shape]
		,[geography_tour_origin].[tour_origin_cocpa_2016]
		,[geography_tour_origin].[tour_origin_cocpa_2016_name]
		,[geography_tour_origin].[tour_origin_cocpa_2016_shape]
		,[geography_tour_origin].[tour_origin_jurisdiction_2016]
		,[geography_tour_origin].[tour_origin_jurisdiction_2016_name]
		,[geography_tour_origin].[tour_origin_jurisdiction_2016_shape]
		,[geography_tour_origin].[tour_origin_region_2004]
		,[geography_tour_origin].[tour_origin_region_2004_name]
		,[geography_tour_origin].[tour_origin_region_2004_shape]
		,[geography_tour_origin].[tour_origin_external_zone]
		,[tour].[geography_tour_destination_id]
		,[geography_tour_destination].[tour_destination_mgra_13]
		,[geography_tour_destination].[tour_destination_mgra_13_shape]
		,[geography_tour_destination].[tour_destination_taz_13]
		,[geography_tour_destination].[tour_destination_taz_13_shape]
		,[geography_tour_destination].[tour_destination_luz_13]
		,[geography_tour_destination].[tour_destination_luz_13_shape]
		,[geography_tour_destination].[tour_destination_cicpa_2016]
		,[geography_tour_destination].[tour_destination_cicpa_2016_name]
		,[geography_tour_destination].[tour_destination_cicpa_2016_shape]
		,[geography_tour_destination].[tour_destination_cocpa_2016]
		,[geography_tour_destination].[tour_destination_cocpa_2016_name]
		,[geography_tour_destination].[tour_destination_cocpa_2016_shape]
		,[geography_tour_destination].[tour_destination_jurisdiction_2016]
		,[geography_tour_destination].[tour_destination_jurisdiction_2016_name]
		,[geography_tour_destination].[tour_destination_jurisdiction_2016_shape]
		,[geography_tour_destination].[tour_destination_region_2004]
		,[geography_tour_destination].[tour_destination_region_2004_name]
		,[geography_tour_destination].[tour_destination_region_2004_shape]
		,[geography_tour_destination].[tour_destination_external_zone]
		,[tour].[mode_tour_id]
		,[mode_tour].[mode_tour_description]
		,[tour].[purpose_tour_id]
		,[purpose_tour].[purpose_tour_description]
		,[tour].[tour_category]
		,[tour].[tour_crossborder_point_of_entry]
		,[tour].[tour_crossborder_sentri]
		,[tour].[tour_visitor_auto]
		,[tour].[tour_visitor_income]
		,[tour].[weight_person_tour]
		,[tour].[weight_tour]
		,[person_trip].[model_trip_id]
		,[model_trip].[model_trip_description]
		,[person_trip].[mode_trip_id]
		,[mode_trip].[mode_trip_description]
		,[person_trip].[purpose_trip_origin_id]
		,[purpose_trip_origin].[purpose_trip_origin_description]
		,[person_trip].[purpose_trip_destination_id]
		,[purpose_trip_destination].[purpose_trip_destination_description]
		,[person_trip].[inbound_id]
		,[inbound].[inbound_description]
		,[person_trip].[time_trip_start_id]
		,[time_trip_start].[trip_start_abm_half_hour]
		,[time_trip_start].[trip_start_abm_half_hour_period_start]
		,[time_trip_start].[trip_start_abm_half_hour_period_end]
		,[time_trip_start].[trip_start_abm_5_tod]
		,[time_trip_start].[trip_start_abm_5_tod_period_start]
		,[time_trip_start].[trip_start_abm_5_tod_period_end]
		,[time_trip_start].[trip_start_day]
		,[time_trip_start].[trip_start_day_period_start]
		,[time_trip_start].[trip_start_day_period_end]
		,[person_trip].[time_trip_end_id]
		,[time_trip_end].[trip_end_abm_half_hour]
		,[time_trip_end].[trip_end_abm_half_hour_period_start]
		,[time_trip_end].[trip_end_abm_half_hour_period_end]
		,[time_trip_end].[trip_end_abm_5_tod]
		,[time_trip_end].[trip_end_abm_5_tod_period_start]
		,[time_trip_end].[trip_end_abm_5_tod_period_end]
		,[time_trip_end].[trip_end_day]
		,[time_trip_end].[trip_end_day_period_start]
		,[time_trip_end].[trip_end_day_period_end]
		,[person_trip].[geography_trip_origin_id]
		,[geography_trip_origin].[trip_origin_mgra_13]
		,[geography_trip_origin].[trip_origin_mgra_13_shape]
		,[geography_trip_origin].[trip_origin_taz_13]
		,[geography_trip_origin].[trip_origin_taz_13_shape]
		,[geography_trip_origin].[trip_origin_luz_13]
		,[geography_trip_origin].[trip_origin_luz_13_shape]
		,[geography_trip_origin].[trip_origin_cicpa_2016]
		,[geography_trip_origin].[trip_origin_cicpa_2016_name]
		,[geography_trip_origin].[trip_origin_cicpa_2016_shape]
		,[geography_trip_origin].[trip_origin_cocpa_2016]
		,[geography_trip_origin].[trip_origin_cocpa_2016_name]
		,[geography_trip_origin].[trip_origin_cocpa_2016_shape]
		,[geography_trip_origin].[trip_origin_jurisdiction_2016]
		,[geography_trip_origin].[trip_origin_jurisdiction_2016_name]
		,[geography_trip_origin].[trip_origin_jurisdiction_2016_shape]
		,[geography_trip_origin].[trip_origin_region_2004]
		,[geography_trip_origin].[trip_origin_region_2004_name]
		,[geography_trip_origin].[trip_origin_region_2004_shape]
		,[geography_trip_origin].[trip_origin_external_zone]
		,[person_trip].[geography_trip_destination_id]
		,[geography_trip_destination].[trip_destination_mgra_13]
		,[geography_trip_destination].[trip_destination_mgra_13_shape]
		,[geography_trip_destination].[trip_destination_taz_13]
		,[geography_trip_destination].[trip_destination_taz_13_shape]
		,[geography_trip_destination].[trip_destination_luz_13]
		,[geography_trip_destination].[trip_destination_luz_13_shape]
		,[geography_trip_destination].[trip_destination_cicpa_2016]
		,[geography_trip_destination].[trip_destination_cicpa_2016_name]
		,[geography_trip_destination].[trip_destination_cicpa_2016_shape]
		,[geography_trip_destination].[trip_destination_cocpa_2016]
		,[geography_trip_destination].[trip_destination_cocpa_2016_name]
		,[geography_trip_destination].[trip_destination_cocpa_2016_shape]
		,[geography_trip_destination].[trip_destination_jurisdiction_2016]
		,[geography_trip_destination].[trip_destination_jurisdiction_2016_name]
		,[geography_trip_destination].[trip_destination_jurisdiction_2016_shape]
		,[geography_trip_destination].[trip_destination_region_2004]
		,[geography_trip_destination].[trip_destination_region_2004_name]
		,[geography_trip_destination].[trip_destination_region_2004_shape]
		,[geography_trip_destination].[trip_destination_external_zone]
		,[person_trip].[person_escort_drive_id] -- leaving this as is for now
		,[person_trip].[escort_stop_type_origin_id]
		,[escort_stop_type_origin].[escort_stop_type_origin_description]
		,[person_trip].[person_escort_origin_id] -- leaving this as is for now
		,[person_trip].[escort_stop_type_destination_id]
		,[escort_stop_type_destination].[escort_stop_type_destination_description]
		,[person_trip].[person_escort_destination_id] -- leaving this as is for now
		,[person_trip].[mode_airport_arrival_id]
		,[mode_airport_arrival].[mode_airport_arrival_description]
		,[person_trip].[time_drive]
		,[person_trip].[dist_drive]
		,[person_trip].[toll_cost_drive]
		,[person_trip].[operating_cost_drive]
		,[person_trip].[time_walk]
		,[person_trip].[dist_walk]
		,[person_trip].[time_bike]
		,[person_trip].[dist_bike]
		,[person_trip].[time_transit_in_vehicle_local]
		,[person_trip].[time_transit_in_vehicle_express]
		,[person_trip].[time_transit_in_vehicle_rapid]
		,[person_trip].[time_transit_in_vehicle_light_rail]
		,[person_trip].[time_transit_in_vehicle_commuter_rail]
		,[person_trip].[time_transit_in_vehicle]
		,[person_trip].[cost_transit]
		,[person_trip].[time_transit_auxiliary]
		,[person_trip].[time_transit_wait]
		,[person_trip].[transit_transfers]
		,[person_trip].[time_total]
		,[person_trip].[dist_total]
		,[person_trip].[cost_total]
		,[person_trip].[value_of_time]
		,[person_trip].[value_of_time_drive_bin_id]
		,[person_trip].[weight_person_trip]
		,[person_trip].[weight_trip]
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[person]
	ON
		[person_trip].[scenario_id] = [person].[scenario_id]
		AND [person_trip].[person_id] = [person].[person_id]
	INNER JOIN
		[dimension].[geography_work_location]
	ON
		[person].[geography_work_location_id] = [geography_work_location].[geography_work_location_id]
	INNER JOIN
		[dimension].[geography_school_location]
	ON
		[person].[geography_school_location_id] = [geography_school_location].[geography_school_location_id]
	INNER JOIN
		[dimension].[household]
	ON
		[person_trip].[scenario_id] = [household].[scenario_id]
		AND [person_trip].[household_id] = [household].[household_id]
	INNER JOIN
		[dimension].[geography_household_location]
	ON
		[household].[geography_household_location_id] = [geography_household_location].[geography_household_location_id]
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
		[dimension].[time_tour_end]
	ON
		[tour].[time_tour_end_id] = [time_tour_end].[time_tour_end_id]
	INNER JOIN
		[dimension].[geography_tour_origin]
	ON
		[tour].[geography_tour_origin_id] = [geography_tour_origin].[geography_tour_origin_id]
	INNER JOIN
		[dimension].[geography_tour_destination]
	ON
		[tour].[geography_tour_destination_id] = [geography_tour_destination].[geography_tour_destination_id]
	INNER JOIN
		[dimension].[mode_tour]
	ON
		[tour].[mode_tour_id] = [mode_tour].[mode_tour_id]
	INNER JOIN
		[dimension].[purpose_tour]
	ON
		[tour].[purpose_tour_id] = [purpose_tour].[purpose_tour_id]
	INNER JOIN
		[dimension].[model_trip]
	ON
		[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
	INNER JOIN
		[dimension].[mode_trip]
	ON
		[person_trip].[mode_trip_id] = [mode_trip].[mode_trip_id]
	INNER JOIN
		[dimension].[purpose_trip_origin]
	ON
		[person_trip].[purpose_trip_origin_id] = [purpose_trip_origin].[purpose_trip_origin_id]
	INNER JOIN
		[dimension].[purpose_trip_destination]
	ON
		[person_trip].[purpose_trip_destination_id] = [purpose_trip_destination].[purpose_trip_destination_id]
	INNER JOIN
		[dimension].[inbound]
	ON
		[person_trip].[inbound_id] = [inbound].[inbound_id]
	INNER JOIN
		[dimension].[time_trip_start]
	ON
		[person_trip].[time_trip_start_id] = [time_trip_start].[time_trip_start_id]
	INNER JOIN
		[dimension].[time_trip_end]
	ON
		[person_trip].[time_trip_end_id] = [time_trip_end].[time_trip_end_id]
	INNER JOIN
		[dimension].[geography_trip_origin]
	ON
		[person_trip].[geography_trip_origin_id] = [geography_trip_origin].[geography_trip_origin_id]
	INNER JOIN
		[dimension].[geography_trip_destination]
	ON
		[person_trip].[geography_trip_destination_id] = [geography_trip_destination].[geography_trip_destination_id]
	INNER JOIN
		[dimension].[escort_stop_type_origin]
	ON
		[person_trip].[escort_stop_type_origin_id] = [escort_stop_type_origin].[escort_stop_type_origin_id]
	INNER JOIN
		[dimension].[escort_stop_type_destination]
	ON
		[person_trip].[escort_stop_type_destination_id] = [escort_stop_type_destination].[escort_stop_type_destination_id]
	INNER JOIN
		[dimension].[mode_airport_arrival]
	ON
		[person_trip].[mode_airport_arrival_id] = [mode_airport_arrival].[mode_airport_arrival_id]
GO

-- Add metadata for [report].[person_trip]
EXECUTE [db_meta].[add_xp] 'report.person_trip', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.person_trip', 'MS_Description', 'person trip fact table joined to all dimension tables'
GO




-- Create transit aggflow report view
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('[report].[transit_aggflow]') AND type in ('V'))
DROP VIEW [report].[transit_aggflow]
GO

CREATE VIEW [report].[transit_aggflow] AS
	SELECT
		[transit_aggflow].[scenario_id]
		,[transit_aggflow].[transit_aggflow_id]
		,[transit_aggflow].[transit_link_id]
		,[transit_link].[trcov_id]
		,[transit_link].[transit_link_shape]
		,[transit_aggflow].[ab]
		,[transit_aggflow].[time_id]
		,[time].[abm_half_hour]
		,[time].[abm_half_hour_period_start]
		,[time].[abm_half_hour_period_end]
		,[time].[abm_5_tod]
		,[time].[abm_5_tod_period_start]
		,[time].[abm_5_tod_period_end]
		,[time].[day]
		,[time].[day_period_start]
		,[time].[day_period_end]
		,[transit_aggflow].[mode_transit_id]
		,[mode_transit].[mode_transit_description]
		,[transit_aggflow].[mode_transit_access_id]
		,[mode_transit_access].[mode_transit_access_description]
		,[transit_aggflow].[transit_flow]
		,[transit_aggflow].[non_transit_flow]
		,[transit_aggflow].[total_flow]
		,[transit_aggflow].[access_walk_flow]
		,[transit_aggflow].[xfer_walk_flow]
		,[transit_aggflow].[egress_walk_flow]
	FROM
		[fact].[transit_aggflow]
	INNER JOIN
		[dimension].[transit_link]
	ON
		[transit_aggflow].[scenario_id] = [transit_link].[scenario_id]
		AND [transit_aggflow].[transit_link_id] = [transit_link].[transit_link_id]
	INNER JOIN
		[dimension].[time]
	ON
		[transit_aggflow].[time_id] = [time].[time_id]
	INNER JOIN
		[dimension].[mode_transit]
	ON
		[transit_aggflow].[mode_transit_id] = [mode_transit].[mode_transit_id]
	INNER JOIN
		[dimension].[mode_transit_access]
	ON
		[transit_aggflow].[mode_transit_access_id] = [mode_transit_access].[mode_transit_access_id]
GO

-- Add metadata for [report].[transit_aggflow]
EXECUTE [db_meta].[add_xp] 'report.transit_aggflow', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.transit_aggflow', 'MS_Description', 'transit aggflow fact table joined to all dimension tables'
GO




-- Create transit flow report view
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('[report].[transit_flow]') AND type in ('V'))
DROP VIEW [report].[transit_flow]
GO

CREATE VIEW [report].[transit_flow] AS
	SELECT
		[transit_flow].[scenario_id]
		,[transit_flow].[transit_flow_id]
		,[transit_flow].[transit_route_id]
		,[transit_route].[route_id]
		,[transit_route].[route_name]
		,[transit_route].[mode_transit_route_id]
		,[mode_transit_route].[mode_transit_route_description]
		,[transit_route].[am_headway]
		,[transit_route].[pm_headway]
		,[transit_route].[op_headway]
		,[transit_route].[nt_headway]
		,[transit_route].[nt_hour]
		,[transit_route].[config]
		,[transit_route].[fare]
		,[transit_route].[transit_route_shape]
		,[transit_flow].[transit_stop_from_id]
		,[transit_stop_from].[transit_link_id] AS [transit_stop_from_transit_link_id]
		,[transit_stop_from_transit_link].[trcov_id] AS [transit_stop_from_trcov_id]
		,[transit_stop_from_transit_link].[transit_link_shape] AS [transit_stop_from_transit_link_shape]
		,[transit_stop_from].[stop_id] AS [transit_stop_from_stop_id]
		,[transit_stop_from].[mp] AS [transit_stop_from_mp]
		,[transit_stop_from].[near_node] AS [transit_stop_from_near_node]
		,[transit_stop_from].[fare_zone] AS [transit_stop_from_fare_zone]
		,[transit_stop_from].[stop_name] AS [transit_stop_from_stop_name]
		,[transit_stop_from].[transit_stop_shape] AS [transit_stop_from_transit_stop_shape]
		,[transit_flow].[transit_stop_to_id]
		,[transit_stop_to].[transit_link_id] AS [transit_stop_to_transit_link_id]
		,[transit_stop_to_transit_link].[trcov_id] AS [transit_stop_to_trcov_id]
		,[transit_stop_to_transit_link].[transit_link_shape] AS [transit_stop_to_transit_link_shape]
		,[transit_stop_to].[stop_id] AS [transit_stop_to_stop_id]
		,[transit_stop_to].[mp] AS [transit_stop_to_mp]
		,[transit_stop_to].[near_node] AS [transit_stop_to_near_node]
		,[transit_stop_to].[fare_zone] AS [transit_stop_to_fare_zone]
		,[transit_stop_to].[stop_name] AS [transit_stop_to_stop_name]
		,[transit_stop_to].[transit_stop_shape] AS [transit_stop_to_transit_stop_shape]
		,[transit_flow].[time_id]
		,[time].[abm_half_hour]
		,[time].[abm_half_hour_period_start]
		,[time].[abm_half_hour_period_end]
		,[time].[abm_5_tod]
		,[time].[abm_5_tod_period_start]
		,[time].[abm_5_tod_period_end]
		,[time].[day]
		,[time].[day_period_start]
		,[time].[day_period_end]
		,[transit_flow].[mode_transit_id]
		,[mode_transit].[mode_transit_description]
		,[transit_flow].[mode_transit_access_id]
		,[mode_transit_access].[mode_transit_access_description]
		,[transit_flow].[from_mp]
		,[transit_flow].[to_mp]
		,[transit_flow].[baseivtt]
		,[transit_flow].[cost]
		,[transit_flow].[transit_flow]
	FROM
		[fact].[transit_flow]
	INNER JOIN
		[dimension].[transit_route]
	ON
		[transit_flow].[scenario_id] = [transit_route].[scenario_id]
		AND [transit_flow].[transit_route_id] = [transit_route].[transit_route_id]
	INNER JOIN
		[dimension].[mode_transit_route]
	ON
		[transit_route].[mode_transit_route_id] = [mode_transit_route].[mode_transit_route_id]
	INNER JOIN
		[dimension].[transit_stop] AS [transit_stop_from] -- no role playing views for scenario specific dimensions
	ON
		[transit_flow].[scenario_id] = [transit_stop_from].[scenario_id]
		AND [transit_flow].[transit_stop_from_id] = [transit_stop_from].[transit_stop_id]
	INNER JOIN
		[dimension].[transit_link] AS [transit_stop_from_transit_link] -- no role playing views for scenario specific dimensions
	ON
		[transit_stop_from].[scenario_id] = [transit_stop_from_transit_link].[scenario_id]
		AND [transit_stop_from].[transit_link_id] = [transit_stop_from_transit_link].[transit_link_id]
	INNER JOIN
		[dimension].[transit_stop] AS [transit_stop_to] -- no role playing views for scenario specific dimensions
	ON
		[transit_flow].[scenario_id] = [transit_stop_to].[scenario_id]
		AND [transit_flow].[transit_stop_to_id] = [transit_stop_to].[transit_stop_id]
	INNER JOIN
		[dimension].[transit_link] AS [transit_stop_to_transit_link] -- no role playing views for scenario specific dimensions
	ON
		[transit_stop_from].[scenario_id] = [transit_stop_to_transit_link].[scenario_id]
		AND [transit_stop_from].[transit_link_id] = [transit_stop_to_transit_link].[transit_link_id]
	INNER JOIN
		[dimension].[time]
	ON
		[transit_flow].[time_id] = [time].[time_id]
	INNER JOIN
		[dimension].[mode_transit]
	ON
		[transit_flow].[mode_transit_id] = [mode_transit].[mode_transit_id]
	INNER JOIN
		[dimension].[mode_transit_access]
	ON
		[transit_flow].[mode_transit_access_id] = [mode_transit_access].[mode_transit_access_id]
GO

-- Add metadata for [report].[transit_flow]
EXECUTE [db_meta].[add_xp] 'report.transit_flow', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.transit_flow', 'MS_Description', 'transit flow fact table joined to all dimension tables'
GO




-- Create transit on off report view
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('[report].[transit_onoff]') AND type in ('V'))
DROP VIEW [report].[transit_onoff]
GO

CREATE VIEW [report].[transit_onoff] AS
	SELECT
		[transit_onoff].[scenario_id]
		,[transit_onoff].[transit_onoff_id]
		,[transit_onoff].[transit_route_id]
		,[transit_route].[route_name]
		,[transit_route].[mode_transit_route_id]
		,[mode_transit_route].[mode_transit_route_description]
		,[transit_route].[am_headway]
		,[transit_route].[pm_headway]
		,[transit_route].[op_headway]
		,[transit_route].[nt_headway]
		,[transit_route].[nt_hour]
		,[transit_route].[config]
		,[transit_route].[fare]
		,[transit_route].[transit_route_shape]
		,[transit_onoff].[transit_stop_id]
		,[transit_stop].[transit_link_id]
		,[transit_link].[trcov_id]
		,[transit_link].[transit_link_shape]
		,[transit_onoff].[time_id]
		,[time].[abm_half_hour]
		,[time].[abm_half_hour_period_start]
		,[time].[abm_half_hour_period_end]
		,[time].[abm_5_tod]
		,[time].[abm_5_tod_period_start]
		,[time].[abm_5_tod_period_end]
		,[time].[day]
		,[time].[day_period_start]
		,[time].[day_period_end]
		,[transit_onoff].[mode_transit_id]
		,[mode_transit].[mode_transit_description]
		,[transit_onoff].[mode_transit_access_id]
		,[mode_transit_access].[mode_transit_access_description]
		,[transit_onoff].[boardings]
		,[transit_onoff].[alightings]
		,[transit_onoff].[walk_access_on]
		,[transit_onoff].[direct_transfer_on]
		,[transit_onoff].[direct_transfer_off]
		,[transit_onoff].[egress_off]
	FROM
		[fact].[transit_onoff]
	INNER JOIN
		[dimension].[transit_route]
	ON
		[transit_onoff].[scenario_id] = [transit_route].[scenario_id]
		AND [transit_onoff].[transit_route_id] = [transit_route].[transit_route_id]
	INNER JOIN
		[dimension].[mode_transit_route]
	ON
		[transit_route].[mode_transit_route_id] = [mode_transit_route].[mode_transit_route_id]
	INNER JOIN
		[dimension].[transit_stop]
	ON
		[transit_onoff].[scenario_id] = [transit_stop].[scenario_id]
		AND [transit_onoff].[transit_stop_id] = [transit_stop].[transit_stop_id]
	INNER JOIN
		[dimension].[transit_link]
	ON
		[transit_stop].[scenario_id] = [transit_link].[scenario_id]
		AND [transit_stop].[transit_link_id] = [transit_link].[transit_link_id]
	INNER JOIN
		[dimension].[time]
	ON
		[transit_onoff].[time_id] = [time].[time_id]
	INNER JOIN
		[dimension].[mode_transit]
	ON
		[transit_onoff].[mode_transit_id] = [mode_transit].[mode_transit_id]
	INNER JOIN
		[dimension].[mode_transit_access]
	ON
		[transit_onoff].[mode_transit_access_id] = [mode_transit_access].[mode_transit_access_id]
GO

-- Add metadata for [report].[transit_onoff]
EXECUTE [db_meta].[add_xp] 'report.transit_onoff', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.transit_onoff', 'MS_Description', 'transit on off fact table joined to all dimension tables'
GO




-- Create transit pnr report view
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('[report].[transit_pnr]') AND type in ('V'))
DROP VIEW [report].[transit_pnr]
GO

CREATE VIEW [report].[transit_pnr] AS
	SELECT
		[transit_pnr].[scenario_id]
		,[transit_pnr].[transit_pnr_id]
		,[transit_pnr].[transit_tap_id]
		,[transit_tap].[tap]
		,[transit_tap].[transit_tap_shape]
		,[transit_pnr].[lot_id]
		,[transit_pnr].[geography_id]
		,[geography].[mgra_13]
		,[geography].[mgra_13_shape]
		,[geography].[taz_13]
		,[geography].[taz_13_shape]
		,[geography].[luz_13]
		,[geography].[luz_13_shape]
		,[geography].[cicpa_2016]
		,[geography].[cicpa_2016_name]
		,[geography].[cicpa_2016_shape]
		,[geography].[cocpa_2016]
		,[geography].[cocpa_2016_name]
		,[geography].[cocpa_2016_shape]
		,[geography].[jurisdiction_2016]
		,[geography].[jurisdiction_2016_name]
		,[geography].[jurisdiction_2016_shape]
		,[geography].[region_2004]
		,[geography].[region_2004_name]
		,[geography].[region_2004_shape]
		,[geography].[external_zone]
		,[transit_pnr].[time_id]
		,[time].[abm_half_hour]
		,[time].[abm_half_hour_period_start]
		,[time].[abm_half_hour_period_end]
		,[time].[abm_5_tod]
		,[time].[abm_5_tod_period_start]
		,[time].[abm_5_tod_period_end]
		,[time].[day]
		,[time].[day_period_start]
		,[time].[day_period_end]
		,[transit_pnr].[parking_type]
		,[transit_pnr].[capacity]
		,[transit_pnr].[distance]
		,[transit_pnr].[vehicles]
	FROM 
		[fact].[transit_pnr]
	INNER JOIN
		[dimension].[transit_tap]
	ON
		[transit_pnr].[scenario_id] = [transit_tap].[scenario_id]
		AND [transit_pnr].[transit_tap_id] = [transit_tap].[transit_tap_id]
	INNER JOIN
		[dimension].[geography]
	ON
		[transit_pnr].[geography_id] = [geography].[geography_id]
	INNER JOIN
		[dimension].[time]
	ON
		[transit_pnr].[time_id] = [time].[time_id]
GO

-- Add metadata for [report].[transit_pnr]
EXECUTE [db_meta].[add_xp] 'report.transit_pnr', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.transit_pnr', 'MS_Description', 'transit pnr fact table joined to all dimension tables'
GO




-- Create stored procedure for person trip and trip mode split
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[sp_mode_split]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[sp_mode_split]
GO

CREATE PROCEDURE [report].[sp_mode_split]
	@scenario_id integer,
	@model_list varchar(200) -- list of ABM sub-models to include delimited by commas
	-- example usage to get mode split for resident models:
	-- EXECUTE [report].[sp_mode_split] 1, 'Individual,Internal-External,Joint'
	-- see [dimension].[model_trip].[model_trip_description] for valid values
AS

/*	Author: Gregor Schroeder
	Date: 7/6/2018
	Description: Person trip and trip mode split for given input scenario
		and list of ABM sub-models.
*/

-- ensure the input @model_list parameter contains valid ABM sub-model descriptions
IF EXISTS(
	SELECT
		[value]
	FROM
		STRING_SPLIT(@model_list, ',') AS [mode_list]
	LEFT OUTER JOIN
		[dimension].[model_trip]
	ON
		[mode_list].[value] = [model_trip].[model_trip_description]
	WHERE
		[model_trip].[model_trip_id] IS NULL)
BEGIN
RAISERROR ('Input value for ABM sub-model does not exist. Check the @model_list parameter.', 16, 1)
RETURN -1
END

-- get person trips and trips by mode
DECLARE @aggregated_trips TABLE (
	[mode_aggregate] nchar(75) NOT NULL,
	[person_trips] float NOT NULL,
	[trips] float NOT NULL)

INSERT INTO @aggregated_trips
SELECT
	ISNULL(CASE	WHEN [mode_trip_description] IN ('Drive Alone Non-Toll',
												 'Drive Alone Toll Eligible')
				THEN 'Drive Alone'
				WHEN [mode_trip_description] IN ('Heavy Heavy Duty Truck (Non-Toll)',
												 'Heavy Heavy Duty Truck (Toll)')
				THEN 'Heavy Heavy Duty Truck'
				WHEN [mode_trip_description] IN ('Heavy Truck - Non-Toll',
												 'Heavy Truck - Toll')
				THEN 'Heavy Truck'
				WHEN [mode_trip_description] IN ('Intermediate Truck - Non-Toll',
												 'Intermediate Truck - Toll')
				THEN 'Intermediate Truck'
				WHEN [mode_trip_description] IN ('Light Heavy Duty Truck (Non-Toll)',
												 'Light Heavy Duty Truck (Toll)')
				THEN 'Light Heavy Duty Truck'
				WHEN [mode_trip_description] IN ('Light Vehicle - Non-Toll',
												 'Light Vehicle - Toll')
				THEN 'Light Vehicle'
				WHEN [mode_trip_description] IN ('Medium Heavy Duty Truck (Non-Toll)',
												 'Medium Heavy Duty Truck (Toll)')
				THEN 'Medium Heavy Duty Truck'
				WHEN [mode_trip_description] IN ('Medium Truck - Non-Toll',
												 'Medium Truck - Toll')
				THEN 'Medium Truck'
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
				WHEN [mode_trip_description] IN ('Shared Ride 2 Non-Toll',
											 	 'Shared Ride 2 Toll Eligible',
												 'Shared Ride 3 Non-Toll',
												 'Shared Ride 3 Toll Eligible')
				THEN 'Shared Ride'
				ELSE [mode_trip_description] END, 'Total') AS [mode_aggregate]
	,SUM([weight_person_trip]) AS [person_trips]
	,SUM([weight_trip]) AS [trips]
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
WHERE
	[scenario_id] = @scenario_id
	AND [model_trip].[model_trip_description] IN (SELECT [value] FROM STRING_SPLIT(@model_list, ','))
GROUP BY
	CASE	WHEN [mode_trip_description] IN ('Drive Alone Non-Toll',
											 'Drive Alone Toll Eligible')
			THEN 'Drive Alone'
			WHEN [mode_trip_description] IN ('Heavy Heavy Duty Truck (Non-Toll)',
											 'Heavy Heavy Duty Truck (Toll)')
			THEN 'Heavy Heavy Duty Truck'
			WHEN [mode_trip_description] IN ('Heavy Truck - Non-Toll',
											 'Heavy Truck - Toll')
			THEN 'Heavy Truck'
			WHEN [mode_trip_description] IN ('Intermediate Truck - Non-Toll',
											 'Intermediate Truck - Toll')
			THEN 'Intermediate Truck'
			WHEN [mode_trip_description] IN ('Light Heavy Duty Truck (Non-Toll)',
											 'Light Heavy Duty Truck (Toll)')
			THEN 'Light Heavy Duty Truck'
			WHEN [mode_trip_description] IN ('Light Vehicle - Non-Toll',
											 'Light Vehicle - Toll')
			THEN 'Light Vehicle'
			WHEN [mode_trip_description] IN ('Medium Heavy Duty Truck (Non-Toll)',
											 'Medium Heavy Duty Truck (Toll)')
			THEN 'Medium Heavy Duty Truck'
			WHEN [mode_trip_description] IN ('Medium Truck - Non-Toll',
											 'Medium Truck - Toll')
			THEN 'Medium Truck'
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
			WHEN [mode_trip_description] IN ('Shared Ride 2 Non-Toll',
											 'Shared Ride 2 Toll Eligible',
											 'Shared Ride 3 Non-Toll',
											 'Shared Ride 3 Toll Eligible')
			THEN 'Shared Ride'
			ELSE [mode_trip_description] END
WITH ROLLUP

SELECT
	@scenario_id AS [scenario_id]
	,[mode_aggregate]
	,100.0 * [person_trips] / (SELECT [person_trips] FROM @aggregated_trips WHERE [mode_aggregate] = 'Total') AS [pct_person_trips]
	,[person_trips]
	,100.0 * [trips] / (SELECT [trips] FROM @aggregated_trips WHERE [mode_aggregate] = 'Total') AS [pct_trips]
	,[trips]
FROM
	@aggregated_trips

RETURN
GO

-- Add metadata for [report].[sp_mode_split]
EXECUTE [db_meta].[add_xp] 'report.sp_mode_split', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.sp_mode_split', 'MS_Description', 'person trip and trip mode split for given input scenario and list of ABM sub-models'
GO




-- Create stored procedure for resident vmt by home/workplace location cicpa
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[sp_resident_vmt_cicpa]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[sp_resident_vmt_cicpa]
GO

CREATE PROCEDURE [report].[sp_resident_vmt_cicpa]
	@scenario_id integer,
	@workers bit = 0, -- indicator to select workers only, includes telecommuters
	@home_location bit = 0, -- indicator to assign activity to home location cicpa
	@work_location bit = 0 -- indicator to assign activity to workplace location cicpa, includes telecommuters
AS

/*	Author: Gregor Schroeder
	Date: Revised 6/25/2018
	Description: Resident pmt/vmt by cicpa. Can filter activity from all residents to workers only.
				 Can assign activity to either home or workplace location cicpa.
				 Per-capita measures within the cicpa depend on the assigned activity
				 and worker filter selected.
*/

IF CONVERT(int, @home_location) + CONVERT(int, @work_location) > 1
BEGIN
RAISERROR ('Select to assign activity to either home or work location cicpa.', 16, 1)
RETURN -1
END;

IF CONVERT(int, @workers) = 0 AND CONVERT(int, @work_location) >= 1
BEGIN
RAISERROR ('Assigning activity to work location cicpa requires selection of workers only filter.', 16, 1)
RETURN -1
END;

SELECT
	CASE	WHEN @workers = 0 THEN 'All Residents'
			WHEN @workers = 1 THEN 'Workers Only'
			ELSE NULL END AS [population]
	,CASE	WHEN @home_location = 1 THEN 'Activity Assigned to Home Location'
			WHEN @work_location = 1 THEN 'Activity Assigned to Workplace Location'
			ELSE NULL END AS [activity_location]
	,[persons].[cicpa_2016_name]
	,[persons].[persons]
	,ISNULL([trips].[trips], 0) AS [trips]
	,ISNULL([trips].[trips], 0) / [persons].[persons] AS [trips_per_capita]
	,ISNULL([trips].[vmt], 0) AS [vmt]
	,ISNULL([trips].[vmt], 0) / [persons].[persons] AS [vmt_per_capita]
FROM (
	SELECT DISTINCT -- distinct here for case when only total is wanted (no home location, no work location), avoids duplicate Total column caused by ROLLUP
		ISNULL(CASE	WHEN @home_location = 1
						THEN [geography_household_location].[household_location_cicpa_2016_name]
						WHEN @work_location = 1
						THEN  [geography_work_location].[work_location_cicpa_2016_name]
						ELSE NULL
						END, 'Total') AS [cicpa_2016_name]
		,SUM([person].[weight_person]) AS [persons]
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
	INNER JOIN
		[dimension].[geography_work_location]
	ON
		[person].[geography_work_location_id] = [geography_work_location].[geography_work_location_id]
	WHERE
		[person].[scenario_id] = @scenario_id
		AND [household].[scenario_id] = @scenario_id
		AND [person].[weight_person] > 0
		AND (@workers = 0 OR (@workers = 1 AND [person].[work_segment] != 'Non-Worker')) -- exclude non-workers if worker filter is selected
	GROUP BY
		CASE	WHEN @home_location = 1
				THEN [geography_household_location].[household_location_cicpa_2016_name]
				WHEN @work_location = 1
				THEN  [geography_work_location].[work_location_cicpa_2016_name]
				ELSE NULL
				END
	WITH ROLLUP) AS [persons]
LEFT OUTER JOIN ( -- keep zones with residents/employees even if 0 trips/vmt
	SELECT DISTINCT -- distinct here for case when only total is wanted (no home location, no work location), avoids duplicate Total column caused by ROLLUP
		ISNULL(CASE	WHEN @home_location = 1
						THEN [geography_household_location].[household_location_cicpa_2016_name]
						WHEN @work_location = 1
						THEN  [geography_work_location].[work_location_cicpa_2016_name]
						ELSE NULL
						END, 'Total') AS [cicpa_2016_name]
		,SUM([person_trip].[weight_trip]) AS [trips]
		,SUM([person_trip].[weight_trip] * [person_trip].[dist_drive]) AS [vmt]
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[model_trip]
	ON
		[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
	INNER JOIN
		[dimension].[household]
	ON
		[person_trip].[scenario_id] = [household].[scenario_id]
		AND [person_trip].[household_id] = [household].[household_id]
	INNER JOIN
		[dimension].[person]
	ON
		[person_trip].[scenario_id] = [person].[scenario_id]
		AND [person_trip].[person_id] = [person].[person_id]
	INNER JOIN
		[dimension].[geography_household_location]
	ON
		[household].[geography_household_location_id] = [geography_household_location].[geography_household_location_id]
	INNER JOIN
		[dimension].[geography_work_location]
	ON
		[person].[geography_work_location_id] = [geography_work_location].[geography_work_location_id]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
		AND [person].[scenario_id] = @scenario_id
		AND [household].[scenario_id] = @scenario_id
		AND [model_trip].[model_trip_description] IN ('Individual',
													  'Internal-External',
													  'Joint') -- only resident models use synthetic population
		AND (@workers = 0 OR (@workers = 1 AND [person].[work_segment] != 'Non-Worker')) -- exclude non-workers if worker filter is selected
	GROUP BY
		CASE	WHEN @home_location = 1
				THEN [geography_household_location].[household_location_cicpa_2016_name]
				WHEN @work_location = 1
				THEN  [geography_work_location].[work_location_cicpa_2016_name]
				ELSE NULL
				END
	WITH ROLLUP) AS [trips]
ON
	[persons].[cicpa_2016_name] = [trips].[cicpa_2016_name]
ORDER BY -- keep sort order of alphabetical with Total at bottom
	CASE WHEN [persons].[cicpa_2016_name] = 'Total' THEN 'ZZ'
	ELSE [persons].[cicpa_2016_name] END ASC
OPTION(MAXDOP 1)
GO

-- Add metadata for [report].[sp_resident_vmt_cicpa]
EXECUTE [db_meta].[add_xp] 'report.sp_resident_vmt_cicpa', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.sp_resident_vmt_cicpa', 'MS_Description', 'vehicle miles travelled by residents home/workplace location cicpa'
GO




-- Create stored procedure for resident vmt by home/workplace location cocpa
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[sp_resident_vmt_cocpa]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[sp_resident_vmt_cocpa]
GO

CREATE PROCEDURE [report].[sp_resident_vmt_cocpa]
	@scenario_id integer,
	@workers bit = 0, -- indicator to select workers only, includes telecommuters
	@home_location bit = 0, -- indicator to assign activity to home location cocpa
	@work_location bit = 0 -- indicator to assign activity to workplace location cocpa, includes telecommuters
AS

/*	Author: Gregor Schroeder
	Date: Revised 6/25/2018
	Description: Resident pmt/vmt by cocpa. Can filter activity from all residents to workers only.
				 Can assign activity to either home or workplace location cocpa.
				 Per-capita measures within the cocpa depend on the assigned activity
				 and worker filter selected.
*/

IF CONVERT(int, @home_location) + CONVERT(int, @work_location) > 1
BEGIN
RAISERROR ('Select to assign activity to either home or work location cocpa.', 16, 1)
RETURN -1
END;

IF CONVERT(int, @workers) = 0 AND CONVERT(int, @work_location) >= 1
BEGIN
RAISERROR ('Assigning activity to work location cocpa requires selection of workers only filter.', 16, 1)
RETURN -1
END;

SELECT
	CASE	WHEN @workers = 0 THEN 'All Residents'
			WHEN @workers = 1 THEN 'Workers Only'
			ELSE NULL END AS [population]
	,CASE	WHEN @home_location = 1 THEN 'Activity Assigned to Home Location'
			WHEN @work_location = 1 THEN 'Activity Assigned to Workplace Location'
			ELSE NULL END AS [activity_location]
	,[persons].[cocpa_2016_name]
	,[persons].[persons]
	,ISNULL([trips].[trips], 0) AS [trips]
	,ISNULL([trips].[trips], 0) / [persons].[persons] AS [trips_per_capita]
	,ISNULL([trips].[vmt], 0) AS [vmt]
	,ISNULL([trips].[vmt], 0) / [persons].[persons] AS [vmt_per_capita]
FROM (
	SELECT DISTINCT -- distinct here for case when only total is wanted (no home location, no work location), avoids duplicate Total column caused by ROLLUP
		ISNULL(CASE	WHEN @home_location = 1
						THEN [geography_household_location].[household_location_cocpa_2016_name]
						WHEN @work_location = 1
						THEN  [geography_work_location].[work_location_cocpa_2016_name]
						ELSE NULL
						END, 'Total') AS [cocpa_2016_name]
		,SUM([person].[weight_person]) AS [persons]
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
	INNER JOIN
		[dimension].[geography_work_location]
	ON
		[person].[geography_work_location_id] = [geography_work_location].[geography_work_location_id]
	WHERE
		[person].[scenario_id] = @scenario_id
		AND [household].[scenario_id] = @scenario_id
		AND [person].[weight_person] > 0
		AND (@workers = 0 OR (@workers = 1 AND [person].[work_segment] != 'Non-Worker')) -- exclude non-workers if worker filter is selected
	GROUP BY
		CASE	WHEN @home_location = 1
				THEN [geography_household_location].[household_location_cocpa_2016_name]
				WHEN @work_location = 1
				THEN  [geography_work_location].[work_location_cocpa_2016_name]
				ELSE NULL
				END
	WITH ROLLUP) AS [persons]
LEFT OUTER JOIN ( -- keep zones with residents/employees even if 0 trips/vmt
	SELECT DISTINCT -- distinct here for case when only total is wanted (no home location, no work location), avoids duplicate Total column caused by ROLLUP
		ISNULL(CASE	WHEN @home_location = 1
						THEN [geography_household_location].[household_location_cocpa_2016_name]
						WHEN @work_location = 1
						THEN  [geography_work_location].[work_location_cocpa_2016_name]
						ELSE NULL
						END, 'Total') AS [cocpa_2016_name]
		,SUM([person_trip].[weight_trip]) AS [trips]
		,SUM([person_trip].[weight_trip] * [person_trip].[dist_drive]) AS [vmt]
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[model_trip]
	ON
		[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
	INNER JOIN
		[dimension].[household]
	ON
		[person_trip].[scenario_id] = [household].[scenario_id]
		AND [person_trip].[household_id] = [household].[household_id]
	INNER JOIN
		[dimension].[person]
	ON
		[person_trip].[scenario_id] = [person].[scenario_id]
		AND [person_trip].[person_id] = [person].[person_id]
	INNER JOIN
		[dimension].[geography_household_location]
	ON
		[household].[geography_household_location_id] = [geography_household_location].[geography_household_location_id]
	INNER JOIN
		[dimension].[geography_work_location]
	ON
		[person].[geography_work_location_id] = [geography_work_location].[geography_work_location_id]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
		AND [person].[scenario_id] = @scenario_id
		AND [household].[scenario_id] = @scenario_id
		AND [model_trip].[model_trip_description] IN ('Individual',
													  'Internal-External',
													  'Joint') -- only resident models use synthetic population
		AND (@workers = 0 OR (@workers = 1 AND [person].[work_segment] != 'Non-Worker')) -- exclude non-workers if worker filter is selected
	GROUP BY
		CASE	WHEN @home_location = 1
				THEN [geography_household_location].[household_location_cocpa_2016_name]
				WHEN @work_location = 1
				THEN  [geography_work_location].[work_location_cocpa_2016_name]
				ELSE NULL
				END
	WITH ROLLUP) AS [trips]
ON
	[persons].[cocpa_2016_name] = [trips].[cocpa_2016_name]
ORDER BY -- keep sort order of alphabetical with Total at bottom
	CASE WHEN [persons].[cocpa_2016_name] = 'Total' THEN 'ZZ'
	ELSE [persons].[cocpa_2016_name] END ASC
OPTION(MAXDOP 1)
GO

-- Add metadata for [report].[sp_resident_vmt_cocpa]
EXECUTE [db_meta].[add_xp] 'report.sp_resident_vmt_cocpa', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.sp_resident_vmt_cocpa', 'MS_Description', 'vehicle miles travelled by residents home/workplace location cocpa'
GO




-- Create stored procedure for resident vmt by home/workplace location jurisdiction
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[sp_resident_vmt_jurisdiction]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[sp_resident_vmt_jurisdiction]
GO

CREATE PROCEDURE [report].[sp_resident_vmt_jurisdiction]
	@scenario_id integer,
	@workers bit = 0, -- indicator to select workers only, includes telecommuters
	@home_location bit = 0, -- indicator to assign activity to home location jurisdiction
	@work_location bit = 0 -- indicator to assign activity to workplace location jurisdiction, includes telecommuters
AS

/*	Author: Gregor Schroeder
	Date: Revised 6/25/2018
	Description: Resident pmt/vmt by jurisdiction. Can filter activity from all residents to workers only.
				 Can assign activity to either home or workplace location jurisdiction.
				 Per-capita measures within the jurisdiction depend on the assigned activity 
				 and worker filter selected.
*/

IF CONVERT(int, @home_location) + CONVERT(int, @work_location) > 1
BEGIN
RAISERROR ('Select to assign activity to either home or work location jurisdiction.', 16, 1)
RETURN -1
END;

IF CONVERT(int, @workers) = 0 AND CONVERT(int, @work_location) >= 1
BEGIN
RAISERROR ('Assigning activity to work location jurisdiction requires selection of workers only filter.', 16, 1)
RETURN -1
END;

SELECT
	CASE	WHEN @workers = 0 THEN 'All Residents'
			WHEN @workers = 1 THEN 'Workers Only'
			ELSE NULL END AS [population]
	,CASE	WHEN @home_location = 1 THEN 'Activity Assigned to Home Location'
			WHEN @work_location = 1 THEN 'Activity Assigned to Workplace Location'
			ELSE NULL END AS [activity_location]
	,[persons].[jurisdiction_2016_name]
	,[persons].[persons]
	,ISNULL([trips].[trips], 0) AS [trips]
	,ISNULL([trips].[trips], 0) / [persons].[persons] AS [trips_per_capita]
	,ISNULL([trips].[vmt], 0) AS [vmt]
	,ISNULL([trips].[vmt], 0) / [persons].[persons] AS [vmt_per_capita]
FROM (
	SELECT DISTINCT -- distinct here for case when only total is wanted (no home location, no work location), avoids duplicate Total column caused by ROLLUP
		ISNULL(CASE	WHEN @home_location = 1
						THEN [geography_household_location].[household_location_jurisdiction_2016_name]
						WHEN @work_location = 1
						THEN  [geography_work_location].[work_location_jurisdiction_2016_name]
						ELSE NULL
						END, 'Total') AS [jurisdiction_2016_name]
		,SUM([person].[weight_person]) AS [persons]
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
	INNER JOIN
		[dimension].[geography_work_location]
	ON
		[person].[geography_work_location_id] = [geography_work_location].[geography_work_location_id]
	WHERE
		[person].[scenario_id] = @scenario_id
		AND [household].[scenario_id] = @scenario_id
		AND [person].[weight_person] > 0
		AND (@workers = 0 OR (@workers = 1 AND [person].[work_segment] != 'Non-Worker')) -- exclude non-workers if worker filter is selected
	GROUP BY
		CASE	WHEN @home_location = 1
				THEN [geography_household_location].[household_location_jurisdiction_2016_name]
				WHEN @work_location = 1
				THEN  [geography_work_location].[work_location_jurisdiction_2016_name]
				ELSE NULL
				END
	WITH ROLLUP) AS [persons]
LEFT OUTER JOIN ( -- keep zones with residents/employees even if 0 trips/vmt
	SELECT DISTINCT -- distinct here for case when only total is wanted (no home location, no work location), avoids duplicate Total column caused by ROLLUP
		ISNULL(CASE	WHEN @home_location = 1
						THEN [geography_household_location].[household_location_jurisdiction_2016_name]
						WHEN @work_location = 1
						THEN  [geography_work_location].[work_location_jurisdiction_2016_name]
						ELSE NULL
						END, 'Total') AS [jurisdiction_2016_name]
		,SUM([person_trip].[weight_trip]) AS [trips]
		,SUM([person_trip].[weight_trip] * [person_trip].[dist_drive]) AS [vmt]
	FROM
		[fact].[person_trip]
	INNER JOIN
		[dimension].[model_trip]
	ON
		[person_trip].[model_trip_id] = [model_trip].[model_trip_id]
	INNER JOIN
		[dimension].[household]
	ON
		[person_trip].[scenario_id] = [household].[scenario_id]
		AND [person_trip].[household_id] = [household].[household_id]
	INNER JOIN
		[dimension].[person]
	ON
		[person_trip].[scenario_id] = [person].[scenario_id]
		AND [person_trip].[person_id] = [person].[person_id]
	INNER JOIN
		[dimension].[geography_household_location]
	ON
		[household].[geography_household_location_id] = [geography_household_location].[geography_household_location_id]
	INNER JOIN
		[dimension].[geography_work_location]
	ON
		[person].[geography_work_location_id] = [geography_work_location].[geography_work_location_id]
	WHERE
		[person_trip].[scenario_id] = @scenario_id
		AND [person].[scenario_id] = @scenario_id
		AND [household].[scenario_id] = @scenario_id
		AND [model_trip].[model_trip_description] IN ('Individual',
													  'Internal-External',
													  'Joint') -- only resident models use synthetic population
		AND (@workers = 0 OR (@workers = 1 AND [person].[work_segment] != 'Non-Worker')) -- exclude non-workers if worker filter is selected
	GROUP BY
		CASE	WHEN @home_location = 1
				THEN [geography_household_location].[household_location_jurisdiction_2016_name]
				WHEN @work_location = 1
				THEN  [geography_work_location].[work_location_jurisdiction_2016_name]
				ELSE NULL
				END
	WITH ROLLUP) AS [trips]
ON
	[persons].[jurisdiction_2016_name] = [trips].[jurisdiction_2016_name]
ORDER BY -- keep sort order of alphabetical with Total at bottom
	CASE WHEN [persons].[jurisdiction_2016_name] = 'Total' THEN 'ZZ'
	ELSE [persons].[jurisdiction_2016_name] END ASC
OPTION(MAXDOP 1)
GO

-- Add metadata for [report].[sp_resident_vmt_jurisdiction]
EXECUTE [db_meta].[add_xp] 'report.sp_resident_vmt_jurisdiction', 'SUBSYSTEM', 'report'
EXECUTE [db_meta].[add_xp] 'report.sp_resident_vmt_jurisdiction', 'MS_Description', 'vehicle miles travelled by residents home/workplace location jurisdiction'
GO