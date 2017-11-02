#//////////////////////////////////////////////////////////////////////////////
#////                                                                       ///
#//// Copyright INRO, 2016-2017.                                            ///
#//// Rights to use and modify are granted to the                           ///
#//// San Diego Association of Governments and partner agencies.            ///
#//// This copyright notice must be preserved.                              ///
#////                                                                       ///
#//// export_data_loader_network.py                                         ///
#////                                                                       ///
#////                                                                       ///
#////                                                                       ///
#////                                                                       ///
#//////////////////////////////////////////////////////////////////////////////
#
# Exports the network results to csv file for use by the Java Data export process
# and the Data loader to the reporting database.
# 
#
# Inputs:
#    main_directory: main ABM directory
#    base_scenario_id: scenario ID for the base scenario (same used in the Import network tool)
#    traffic_emmebank: the base, traffic, Emme database
#    transit_emmebank: the transit database
#    num_processors: number of processors to use in the transit analysis calculations 
#
# Files created:
#    report/hwyload_pp.csv
#    report/hwy_tcad.csv
#    report/transit_aggflow.csv 
#    report/transit_flow.csv
#    report/transit_onoff.csv
#
# Script example:
"""
    import os
    import inro.emme.database.emmebank as _eb
    modeller = inro.modeller.Modeller()
    main_directory = os.path.dirname(os.path.dirname(modeller.desktop.project.path))
    main_emmebank = _eb.Emmebank(os.path.join(main_directory, "emme_project", "Database", "emmebank"))
    transit_emmebank = _eb.Emmebank(os.path.join(main_directory, "emme_project", "Database", "emmebank"))
    num_processors = "MAX-1"
    export_data_loader_network = modeller.tool(
        "sandag.model.export.export_data_loader_network")
    export_data_loader_network(main_directory, 100, main_emmebank, transit_emmebank, num_processors)
"""

TOOLBOX_ORDER = 73


import inro.modeller as _m
import traceback as _traceback
import inro.emme.database.emmebank as _eb
import inro.emme.core.exception as _except
from contextlib import contextmanager as _context
from collections import OrderedDict
from itertools import chain as _chain
import math
import os

gen_utils = _m.Modeller().module("sandag.utilities.general")
dem_utils = _m.Modeller().module("sandag.utilities.demand")

format = lambda x: ("%.7f" % x).rstrip('0').rstrip(".")
id_format = lambda x: str(int(x))


class ExportDataLoaderNetwork(_m.Tool(), gen_utils.Snapshot):

    main_directory = _m.Attribute(str)
    base_scenario_id = _m.Attribute(int)
    traffic_emmebank = _m.Attribute(str)
    transit_emmebank = _m.Attribute(str)
    num_processors = _m.Attribute(str)

    tool_run_msg = ""

    def __init__(self):
        project_dir = os.path.dirname(_m.Modeller().desktop.project.path)
        self.main_directory = os.path.dirname(project_dir)
        self.base_scenario_id = 100
        self.traffic_emmebank = os.path.join(project_dir, "Database", "emmebank")
        self.transit_emmebank = os.path.join(project_dir, "Database_transit", "emmebank")
        self.num_processors = "MAX-1"
        self.attributes = ["main_directory", "base_scenario_id", "traffic_emmebank", "transit_emmebank", "num_processors"]

    def page(self):
        pb = _m.ToolPageBuilder(self)
        pb.title = "Export network for Data Loader"
        pb.description = """
Export network results to csv files for SQL data loader."""
        pb.branding_text = "- SANDAG - Export"
        if self.tool_run_msg != "":
            pb.tool_run_status(self.tool_run_msg_status)

        pb.add_select_file('main_directory', 'directory',
                           title='Select main directory')

        pb.add_text_box('base_scenario_id', title="Base scenario ID:", size=10)
        pb.add_select_file('traffic_emmebank', 'file',
                           title='Select traffic emmebank')
        pb.add_select_file('transit_emmebank', 'file',
                           title='Select transit emmebank')

        dem_utils.add_select_processors("num_processors", pb, self)

        return pb.render()

    def run(self):
        self.tool_run_msg = ""
        try:
            results = self(self.main_directory, self.base_scenario_id,
                           self.traffic_emmebank, self.transit_emmebank,
                           self.num_processors)
            run_msg = "Export completed"
            self.tool_run_msg = _m.PageBuilder.format_info(run_msg)
        except Exception as error:
            self.tool_run_msg = _m.PageBuilder.format_exception(
                error, _traceback.format_exc(error))
            raise

    @_m.logbook_trace("Export network results for Data Loader", save_arguments=True)
    def __call__(self, main_directory, base_scenario_id, traffic_emmebank, transit_emmebank, num_processors):
        attrs = {
            "traffic_emmebank": str(traffic_emmebank),
            "transit_emmebank": str(transit_emmebank),
            "main_directory": main_directory,
            "base_scenario_id": base_scenario_id,
            "self": str(self)
        }
        gen_utils.log_snapshot("Export network results", str(self), attrs)

        traffic_emmebank = _eb.Emmebank(traffic_emmebank)
        transit_emmebank = _eb.Emmebank(transit_emmebank)
        export_path = os.path.join(main_directory, "report")
        num_processors = dem_utils.parse_num_processors(num_processors)

        periods = ["EA", "AM", "MD", "PM", "EV"]
        period_scenario_id = OrderedDict((v, i) for i, v in enumerate(periods, start=base_scenario_id + 1))

        base_scenario = traffic_emmebank.scenario(base_scenario_id)
        
        self.export_traffic_attribute(base_scenario, export_path, traffic_emmebank, period_scenario_id)
        self.export_traffic_load_by_period(export_path, traffic_emmebank, period_scenario_id)
        self.export_transit_results(export_path, transit_emmebank, period_scenario_id, num_processors)

    @_m.logbook_trace("Export traffic attribute data")
    def export_traffic_attribute(self, base_scenario, export_path, traffic_emmebank, period_scenario_id):
        ##cojur, costat, rloop, adtlk, adtvl: attributes not imported, export zero value columns
        hwylink_atts = [
            ("ID", "@tcov_id"),
            ("Length", "length"), ("SPHERE", "@sphere"),
            ("NM", "#name"),
            ("FXNM", "#name_from"), ("TXNM", "#name_to"),
            ("AN", "i"), ("BN", "j"),
            ("COJUR", "zero"), ("COSTAT", "zero"), ("COLOC", "zero"),
            ("RLOOP", "zero"), ("ADTLK", "zero"), ("ADTLV", "zero"),
            ("ASPD", "@speed_adjusted"), ("IYR", "@year_open_traffic"),
            ("IPROJ", "@project_code"), ("IJUR", "@jurisdiction_type"),
            ("IFC", "type"), ("IHOV", "@lane_restriction"),
            ("ITRUCK", "@truck_restriction"), ("ISPD", "@speed_posted"),
            ("IWAY", "1/2 way"), ("IMED", "@median"),
            ("ABAU", "@lane_auxiliary"), ("ABCNT", "@traffic_control"),
            ("BAAU", ("@lane_auxiliary", "0")), ("BACNT", ("@traffic_control", "0")),
            ("ITOLL2_EA", "@toll_ea"),
            ("ITOLL2_AM", "@toll_am"),
            ("ITOLL2_MD", "@toll_md"),
            ("ITOLL2_PM", "@toll_pm"),
            ("ITOLL2_EV", "@toll_ev"),
            ("ITOLL3_EA", "@cost_auto_ea"),
            ("ITOLL3_AM", "@cost_auto_am"),
            ("ITOLL3_MD", "@cost_auto_md"),
            ("ITOLL3_PM", "@cost_auto_pm"),
            ("ITOLL3_EV", "@cost_auto_ev"),
            ("ITOLL4_EA", "@cost_med_truck_ea"),
            ("ITOLL4_AM", "@cost_med_truck_am"),
            ("ITOLL4_MD", "@cost_med_truck_md"),
            ("ITOLL4_PM", "@cost_med_truck_pm"),
            ("ITOLL4_EV", "@cost_med_truck_ev"),
            ("ITOLL5_EA", "@cost_hvy_truck_ea"),
            ("ITOLL5_AM", "@cost_hvy_truck_am"),
            ("ITOLL5_MD", "@cost_hvy_truck_md"),
            ("ITOLL5_PM", "@cost_hvy_truck_pm"),
            ("ITOLL5_EV", "@cost_hvy_truck_ev"),
            ("ABCP_EA", "@capacity_link_ea"),   ("BACP_EA", ("@capacity_link_ea", "999999")),
            ("ABCP_AM", "@capacity_link_am"),   ("BACP_AM", ("@capacity_link_am", "999999")),
            ("ABCP_MD", "@capacity_link_md"),   ("BACP_MD", ("@capacity_link_md", "999999")),
            ("ABCP_PM", "@capacity_link_pm"),   ("BACP_PM", ("@capacity_link_pm", "999999")),
            ("ABCP_EV", "@capacity_link_ev"),   ("BACP_EV", ("@capacity_link_ev", "999999")),
            ("ABCX_EA", "@capacity_inter_ea"),  ("BACX_EA", ("@capacity_inter_ea", "999999")),
            ("ABCX_AM", "@capacity_inter_am"),  ("BACX_AM", ("@capacity_inter_am", "999999")),
            ("ABCX_MD", "@capacity_inter_md"),  ("BACX_MD", ("@capacity_inter_md", "999999")),
            ("ABCX_PM", "@capacity_inter_pm"),  ("BACX_PM", ("@capacity_inter_pm", "999999")),
            ("ABCX_EV", "@capacity_inter_ev"),  ("BACX_EV", ("@capacity_inter_ev", "999999")),
            ("ABTM_EA", "@time_link_ea"),       ("BATM_EA", ("@time_link_ea", "999")),
            ("ABTM_AM", "@time_link_am"),       ("BATM_AM", ("@time_link_am", "999")),
            ("ABTM_MD", "@time_link_md"),       ("BATM_MD", ("@time_link_md", "999")),
            ("ABTM_PM", "@time_link_pm"),       ("BATM_PM", ("@time_link_pm", "999")),
            ("ABTM_EV", "@time_link_ev"),       ("BATM_EV", ("@time_link_ev", "999")),
            ("ABTX_EA", "@time_inter_ea"),      ("BATX_EA", ("@time_inter_ea", "0")),
            ("ABTX_AM", "@time_inter_am"),      ("BATX_AM", ("@time_inter_am", "0")),
            ("ABTX_MD", "@time_inter_md"),      ("BATX_MD", ("@time_inter_md", "0")),
            ("ABTX_PM", "@time_inter_pm"),      ("BATX_PM", ("@time_inter_pm", "0")),
            ("ABTX_EV", "@time_inter_ev"),      ("BATX_EV", ("@time_inter_ev", "0")),
            ("ABLN_EA", "@lane_ea"),            ("BALN_EA", ("@lane_ea", "0")),
            ("ABLN_AM", "@lane_am"),            ("BALN_AM", ("@lane_am", "0")),
            ("ABLN_MD", "@lane_md"),            ("BALN_MD", ("@lane_md", "0")),
            ("ABLN_PM", "@lane_pm"),            ("BALN_PM", ("@lane_pm", "0")),
            ("ABLN_EV", "@lane_ev"),            ("BALN_EV", ("@lane_ev", "0")),
            ("ABSTM_EA", "@auto_time_ea"),      ("BASTM_EA", ("@auto_time_ea", "")),
            ("ABSTM_AM", "@auto_time_am"),      ("BASTM_AM", ("@auto_time_am", "")),
            ("ABSTM_MD", "@auto_time_md"),      ("BASTM_MD", ("@auto_time_md", "")),
            ("ABSTM_PM", "@auto_time_pm"),      ("BASTM_PM", ("@auto_time_pm", "")),
            ("ABSTM_EV", "@auto_time_ev"),      ("BASTM_EV", ("@auto_time_ev", "")),
            ("ABHTM_EA", "@auto_time_ea"),      ("BAHTM_EA", ("@auto_time_ea", "")),
            ("ABHTM_AM", "@auto_time_am"),      ("BAHTM_AM", ("@auto_time_am", "")),
            ("ABHTM_MD", "@auto_time_md"),      ("BAHTM_MD", ("@auto_time_md", "")),
            ("ABHTM_PM", "@auto_time_pm"),      ("BAHTM_PM", ("@auto_time_pm", "")),
            ("ABHTM_EV", "@auto_time_ev"),      ("BAHTM_EV", ("@auto_time_ev", "")),
            ("ABPRELOAD_EA", "@volad_ea"),      ("BAPRELOAD_EA", ("@volad_ea", "")),
            ("ABPRELOAD_AM", "@volad_am"),      ("BAPRELOAD_AM", ("@volad_am", "")),
            ("ABPRELOAD_MD", "@volad_md"),      ("BAPRELOAD_MD", ("@volad_md", "")),
            ("ABPRELOAD_PM", "@volad_pm"),      ("BAPRELOAD_PM", ("@volad_pm", "")),
            ("ABPRELOAD_EV", "@volad_ev"),      ("BAPRELOAD_EV", ("@volad_ev", ""))
        ]

        #copy assignment from period scenarios
        network = base_scenario.get_partial_network(["LINK"], include_attributes=True)
        network.create_attribute("LINK", "zero", 0)

        for period, scenario_id in period_scenario_id.iteritems():
            from_scenario = traffic_emmebank.scenario(scenario_id)
            src_attrs = ["@auto_time", "additional_volume"]
            dst_attrs = ["@auto_time_" + period.lower(), "@volad_" + period.lower()]
            for dst_attr in dst_attrs:
                network.create_attribute("LINK", dst_attr)
            values = from_scenario.get_attribute_values("LINK", src_attrs)
            network.set_attribute_values("LINK", dst_attrs, values)

        hwylink_atts_file = os.path.join(export_path, "hwy_tcad.csv")
        self.export_traffic_to_csv(hwylink_atts_file, hwylink_atts, network)

    @_m.logbook_trace("Export traffic load data by period")
    def export_traffic_load_by_period(self, export_path, traffic_emmebank, period_scenario_id):
        create_attribute = _m.Modeller().tool(
            "inro.emme.data.extra_attribute.create_extra_attribute")
        net_calculator = _m.Modeller().tool(
            "inro.emme.network_calculation.network_calculator")
        hwyload_atts = [("ID1", "@tcov_id")]
        dir_atts = [
            ("AB_Flow_PCE", "@pce_flow"),   # sum of pce flow
            ("AB_Time", "@auto_time"),      # computed vdf based on pce flow
            ("AB_VOC", "@voc"),
            ("AB_V_Dist_T", "length"),
            ("AB_VHT", "@vht"),
            ("AB_Speed", "@speed"),
            ("AB_VDF", "@msa_time"),
            ("AB_MSA_Flow", "@msa_flow"),
            ("AB_MSA_Time", "@msa_time"),
            ("AB_Flow_SOV_GP", "@sovgp"),
            ("AB_Flow_SOV_PAY", "@sovtoll"),
            ("AB_Flow_SR2_GP", "@hov2gp"),
            ("AB_Flow_SR2_HOV", "@hov2hov"),
            ("AB_Flow_SR2_PAY", "@hov2toll"),
            ("AB_Flow_SR3_GP", "@hov3gp"),
            ("AB_Flow_SR3_HOV", "@hov3hov"),
            ("AB_Flow_SR3_PAY", "@hov3toll"),
            ("AB_Flow_lhdn", "@trklgp"),
            ("AB_Flow_mhdn", "@trkmgp"),
            ("AB_Flow_hhdn", "@trkhgp"),
            ("AB_Flow_lhdt", "@trkltoll"),
            ("AB_Flow_mhdt", "@trkmtoll"),
            ("AB_Flow_hhdt", "@trkhtoll"),
            ("AB_Flow", "@non_pce_flow"),
        ]
        for key, attr in dir_atts:
            hwyload_atts.append((key, attr))
            hwyload_atts.append((key.replace("AB_", "BA_"), (attr, "")))  # default for BA on one-way links is blank
        for p, scen_id in period_scenario_id.iteritems():
            scenario = traffic_emmebank.scenario(scen_id)
            new_atts = [("@msa_flow", "MSA flow", "@auto_volume"), #updated with vdf on msa flow
                        ("@msa_time", "MSA time", "timau"),  #skim assignment time on msa flow
                        ("@voc", "volume over capacity", "@auto_volume/ul3"),
                        ("@vht", "vehicle hours travelled", "@auto_volume*timau/60"),
                        ("@speed", "link travel speed", "length*60/timau"),
                        ("@pce_flow", "total number of vehicles in Pce",
                                 "@sovgp+@sovtoll+ \
                                  @hov2gp+@hov2hov+@hov2toll+ \
                                  @hov3gp+@hov3hov+@hov3toll+ \
                                  (@trklgp+@trkltoll) + (@trkmgp+@trkltoll) + \
                                  (@trkhgp+@trkhtoll)" ),
                        ("@non_pce_flow", "total number of vehicles in non-Pce",
                                 "@sovgp+@sovtoll+ \
                                  @hov2gp+@hov2hov+@hov2toll+ \
                                  @hov3gp+@hov3hov+@hov3toll+ \
                                  (@trklgp+@trkltoll)/1.3 + (@trkmgp+@trkltoll)/1.5 + \
                                  (@trkhgp+@trkhtoll)/2.5" )
                        ]
            for name, des, formula in new_atts:
                att = scenario.extra_attribute(name)
                if not att:
                    att = create_attribute("LINK", name, des, 0, overwrite=True, scenario=scenario)
                cal_spec = {"result": att.id,
                            "expression": formula,
                            "aggregation": None,
                            "selections": {"link": "mode=d"},
                            "type": "NETWORK_CALCULATION"
                        }
                net_calculator(cal_spec, scenario=scenario)
            file_path = os.path.join(export_path, "hwyload_%s.csv" % p)
            network = self.get_partial_network(scenario, {"LINK": [a[1] for a in dir_atts]})
            self.export_traffic_to_csv(file_path, hwyload_atts, network)

    def export_traffic_to_csv(self, filename, att_list, network):
        auto_mode = network.mode("d")
        # only the original forward direction links and auto links only
        links = [l for l in network.links() 
                 if l["@tcov_id"] > 0 and 
                 (auto_mode in l.modes or (l.reverse_link and auto_mode in l.reverse_link.modes))
                ]
        links.sort(key=lambda l: l["@tcov_id"])
        with open(filename, 'w') as fout:
            fout.write(",".join(['"%s"' % x[0] for x in att_list]))
            fout.write("\n")
            for link in links:
                key, att = att_list[0]  # expected to be the link id
                values = [id_format(link[att])]
                reverse_link = link.reverse_link
                for key, att in att_list[1:]:
                    if key == "AN":
                        values.append(link.i_node.id)
                    elif key == "BN":
                        values.append(link.j_node.id)
                    elif key == "IWAY":
                        values.append("2" if reverse_link else "1")
                    elif key.startswith("BA"):
                        name, default = att
                        values.append(format(reverse_link[name]) if reverse_link else default)
                    elif att.startswith("#"):
                        values.append(link[att])
                    else:
                        values.append(format(link[att]))
                fout.write(",".join(values))
                fout.write("\n")

    @_m.logbook_trace("Export transit results")
    def export_transit_results(self, export_path, transit_emmebank, period_scenario_id, num_processors):
        # Note: Node analysis for transfers is VERY time consuming
        #       this implementation will be replaced when new Emme version is available
        use_node_analysis_to_get_transit_transfers = False
        
        copy_scenario = _m.Modeller().tool(
            "inro.emme.data.scenario.copy_scenario")
        create_attribute = _m.Modeller().tool(
            "inro.emme.data.extra_attribute.create_extra_attribute")
        net_calculator = _m.Modeller().tool(
            "inro.emme.network_calculation.network_calculator")
        copy_attribute= _m.Modeller().tool(
            "inro.emme.data.network.copy_attribute")
        delete_scenario = _m.Modeller().tool(
            "inro.emme.data.scenario.delete_scenario")
        transit_flow_atts = [
            "MODE",
            "ACCESSMODE",
            "TOD",
            "ROUTE",
            "FROM_STOP",
            "TO_STOP",
            "CENTROID",
            "FROMMP",
            "TOMP",
            "TRANSITFLOW",
            "BASEIVTT",
            "COST",
            "VOC",
        ]
        transit_aggregate_flow_atts = [
            "MODE",
            "ACCESSMODE",
            "TOD",
            "LINK_ID",
            "AB_TransitFlow",
            "BA_TransitFlow",
            "AB_NonTransit",
            "BA_NonTransit",
            "AB_TotalFlow",
            "BA_TotalFlow",
            "AB_Access_Walk_Flow",
            "BA_Access_Walk_Flow",
            "AB_Xfer_Walk_Flow",
            "BA_Xfer_Walk_Flow",
            "AB_Egress_Walk_Flow",
            "BA_Egress_Walk_Flow"
        ]
        transit_onoff_atts = [
            "MODE",
            "ACCESSMODE",
            "TOD",
            "ROUTE",
            "STOP",
            "BOARDINGS",
            "ALIGHTINGS",
            "WALKACCESSON",
            "DIRECTTRANSFERON",
            "WALKTRANSFERON",
            "DIRECTTRANSFEROFF",
            "WALKTRANSFEROFF",
            "EGRESSOFF"
        ]

        transit_flow_file = os.path.join(export_path, "transit_flow.csv")
        fout_seg = open(transit_flow_file, 'w')
        fout_seg.write(",".join(['"%s"' % x for x in transit_flow_atts]))
        fout_seg.write("\n")

        transit_aggregate_flow_file = os.path.join(export_path, "transit_aggflow.csv")
        fout_link = open(transit_aggregate_flow_file, 'w')
        fout_link.write(",".join(['"%s"' % x for x in transit_aggregate_flow_atts]))
        fout_link.write("\n")

        transit_onoff_file = os.path.join(export_path, "transit_onoff.csv")
        fout_stop = open(transit_onoff_file, 'w')
        fout_stop.write(",".join(['"%s"' % x for x in transit_onoff_atts]))
        fout_stop.write("\n")
        try:
            access_modes = ["WLK", "PNR", "KNR"]
            main_modes = ["BUS", "LRT", "CMR", "BRT", "EXP"]
            all_modes = ["b", "c", "e", "l", "r", "p", "y", "a", "w", "x"]
            local_bus_modes = ["b", "a", "w", "x"]
            for tod, scen_id in period_scenario_id.iteritems():
                with _m.logbook_trace("Processing period %s" % tod):
                    scenario = transit_emmebank.scenario(scen_id)
                    self.check_network_adj(scenario)
                    # attributes
                    total_walk_flow = create_attribute("LINK", "@volax", "total walk flow on links",
                                0, overwrite=True, scenario=scenario)
                    segment_flow = create_attribute("TRANSIT_SEGMENT", "@voltr", "transit segment flow",
                                0, overwrite=True, scenario=scenario)
                    link_transit_flow = create_attribute("LINK", "@link_voltr", "total transit flow on link",
                                0, overwrite=True, scenario=scenario)
                    initial_boardings = create_attribute("TRANSIT_SEGMENT",
                                "@init_boardings", "transit initial boardings",
                                0, overwrite=True, scenario=scenario)
                    xfer_boardings = create_attribute("TRANSIT_SEGMENT",
                                "@xfer_boardings", "transit transfer boardings",
                                0, overwrite=True, scenario=scenario)
                    total_boardings = create_attribute("TRANSIT_SEGMENT",
                                "@total_boardings", "transit total boardings",
                                0, overwrite=True, scenario=scenario)
                    final_alightings = create_attribute("TRANSIT_SEGMENT",
                                "@final_alightings", "transit final alightings",
                                0, overwrite=True, scenario=scenario)
                    xfer_alightings = create_attribute("TRANSIT_SEGMENT",
                                "@xfer_alightings", "transit transfer alightings",
                                0, overwrite=True, scenario=scenario)
                    total_alightings = create_attribute("TRANSIT_SEGMENT",
                                "@total_alightings", "transit total alightings",
                                0, overwrite=True, scenario=scenario)

                    access_walk_flow = create_attribute("LINK",
                                "@access_walk_flow", "access walks (orig to init board)",
                                0, overwrite=True, scenario=scenario)
                    xfer_walk_flow = create_attribute("LINK",
                                "@xfer_walk_flow", "xfer walks (init board to final alight)",
                                0, overwrite=True, scenario=scenario)
                    egress_walk_flow = create_attribute("LINK",
                                "@egress_walk_flow", "egress walks (final alight to dest)",
                                0, overwrite=True, scenario=scenario)

                    for main_mode in main_modes:
                        mode = "LOC" if main_mode == "BUS" else main_mode
                        mode_list = local_bus_modes if main_mode == "BUS" else all_modes
                        for access_type in access_modes:
                            with _m.logbook_trace("Main mode %s access mode %s" % (main_mode, access_type)):
                                class_name = "%s_%s%s" % (tod, access_type, main_mode)
                                segment_results = {
                                    "transit_volumes": segment_flow.id,
                                    "initial_boardings": initial_boardings.id,
                                    "total_boardings": total_boardings.id,
                                    "final_alightings": final_alightings.id,
                                    "total_alightings": total_alightings.id,
                                    "transfer_boardings": xfer_boardings.id,
                                    "transfer_alightings": xfer_alightings.id
                                }
                                link_results = {
                                    "total_walk_flow": total_walk_flow.id,
                                    "link_transit_flow": link_transit_flow.id,
                                    "access_walk_flow": access_walk_flow.id,
                                    "xfer_walk_flow": xfer_walk_flow.id,
                                    "egress_walk_flow": egress_walk_flow.id
                                }

                                self.calc_additional_results(
                                    scenario, class_name, num_processors,
                                    total_walk_flow, segment_results, link_transit_flow,
                                    access_walk_flow, xfer_walk_flow, egress_walk_flow)
                                attributes = {
                                    "NODE": ["@network_adj"],#, "initial_boardings", "final_alightings"],
                                    "LINK": link_results.values() + ["@tcov_id", "length"],
                                    "TRANSIT_LINE": ["@route_id"],
                                    "TRANSIT_SEGMENT": segment_results.values() + ["@stop_id", "allow_boardings", "allow_alightings"],
                                }
                                network = self.get_partial_network(scenario, attributes)
                                self.collapse_network_adjustments(network, segment_results, link_results)
                                # ===============================================
                                # analysis for nodes with/without walk option
                                if use_node_analysis_to_get_transit_transfers:
                                    stop_on, stop_off = self.transfer_analysis(scenario, class_name, num_processors)
                                else:
                                    stop_on, stop_off = {}, {}
                                # ===============================================
                                links = [link for link in network.links() if link["@tcov_id"] > 0]
                                links.sort(key=lambda l: l["@tcov_id"])
                                lines = [line for line in network.transit_lines() if line.mode.id in mode_list]
                                lines.sort(key=lambda l: l["@route_id"])
                                
                                label = ",".join([mode, access_type, tod])
                                self.output_transit_flow(label, lines, segment_flow.id, fout_seg)
                                self.output_transit_aggregate_flow(
                                   label, links, link_transit_flow.id, total_walk_flow.id, access_walk_flow.id,
                                    xfer_walk_flow.id, egress_walk_flow.id, fout_link)
                                self.output_transit_onoff(
                                    label, lines, total_boardings.id, total_alightings.id, initial_boardings.id,
                                    xfer_boardings.id, xfer_alightings.id, final_alightings.id,
                                    stop_on, stop_off, fout_stop)
        finally:
            fout_stop.close()
            fout_link.close()
            fout_seg.close()
        return
        
    def get_partial_network(self, scenario, attributes):
        domains = attributes.keys()
        network = scenario.get_partial_network(domains, include_attributes=False)
        for domain, attrs in attributes.iteritems():
            if attrs:
                values = scenario.get_attribute_values(domain, attrs)
                network.set_attribute_values(domain, attrs, values)
        return network

    def output_transit_flow(self, label, lines, segment_flow, fout_seg):
        # output segment data (transit_flow)
        centroid = "0"  # always 0
        voc = ""  # volume/capacity, not actually used, 
        for line in lines:
            line_id = id_format(line["@route_id"])
            ivtt = from_mp = to_mp = 0
            segments = iter(line.segments())
            seg = segments.next()
            for next_seg in segments:
                to_mp += seg.link.length
                ivtt += seg.transit_time
                if not next_seg.allow_boardings :
                    continue
                transit_flow = seg[segment_flow]
                format_ivtt = format(ivtt)
                fout_seg.write(",".join([
                    label, line_id, id_format(seg["@stop_id"]), id_format(next_seg["@stop_id"]), centroid, 
                    format(from_mp), format(to_mp), format(transit_flow), format_ivtt, format_ivtt, voc]))
                fout_seg.write("\n")
                seg = next_seg
                from_mp = to_mp
                ivtt = 0

    def output_transit_aggregate_flow(self, label, links,
                                      link_transit_flow, total_walk_flow, access_walk_flow,
                                      xfer_walk_flow, egress_walk_flow, fout_link):
        # output link data (transit_aggregate_flow)        
        for link in links:
            link_id = id_format(link["@tcov_id"])
            ab_transit_flow = link[link_transit_flow]
            ab_non_transit_flow = link[total_walk_flow]
            ab_total_flow = ab_transit_flow + ab_non_transit_flow
            ab_access_walk_flow = link[access_walk_flow]
            ab_xfer_walk_flow = link[xfer_walk_flow]
            ab_egress_walk_flow = link[egress_walk_flow]
            if link.reverse_link:
                ba_transit_flow = link.reverse_link[link_transit_flow]
                ba_non_transit_flow = link.reverse_link[total_walk_flow]
                ba_total_flow = ba_transit_flow + ba_non_transit_flow
                ba_access_walk_flow = link.reverse_link[access_walk_flow]
                ba_xfer_walk_flow = link.reverse_link[xfer_walk_flow]
                ba_egress_walk_flow = link.reverse_link[egress_walk_flow]
            else:
                ba_transit_flow = 0.0
                ba_non_transit_flow = 0.0
                ba_total_flow = 0.0
                ba_access_walk_flow = 0.0
                ba_xfer_walk_flow = 0.0
                ba_egress_walk_flow = 0.0

            fout_link.write(",".join(
                [label, link_id,
                 format(ab_transit_flow), format(ba_transit_flow),
                 format(ab_non_transit_flow), format(ba_non_transit_flow),
                 format(ab_total_flow), format(ba_total_flow),
                 format(ab_access_walk_flow), format(ba_access_walk_flow),
                 format(ab_xfer_walk_flow), format(ba_xfer_walk_flow),
                 format(ab_egress_walk_flow), format(ba_egress_walk_flow)]))
            fout_link.write("\n")

    def output_transit_onoff(self, label, lines, 
                             total_boardings, total_alightings, initial_boardings,
                             xfer_boardings, xfer_alightings, final_alightings,
                             stop_on, stop_off, fout_stop):
        # output stop data (transit_onoff)
        for line in lines:
            line_id = id_format(line["@route_id"])
            for seg in line.segments(True):
                if not (seg.allow_alightings or seg.allow_boardings):
                    continue
                i_node = seg.i_node.id
                boardings = seg[total_boardings]
                alightings = seg[total_alightings]
                walk_access_on = seg[initial_boardings]
                direct_xfer_on = seg[xfer_boardings]
                walk_xfer_on = 0.0
                direct_xfer_off = seg[xfer_alightings]
                walk_xfer_off = 0.0
                if stop_on.has_key(i_node):
                    if stop_on[i_node].has_key(line.id):
                        if direct_xfer_on > 0:
                            walk_xfer_on = direct_xfer_on - stop_on[i_node][line.id]
                            direct_xfer_on = stop_on[i_node][line.id]
                if stop_off.has_key(i_node):
                    if stop_off[i_node].has_key(line.id):
                        if direct_xfer_off > 0:
                            walk_xfer_off = direct_xfer_off - stop_off[i_node][line.id]
                            direct_xfer_off = stop_off[i_node][line.id]

                egress_off = seg[final_alightings]
                fout_stop.write(",".join([
                    label, line_id, id_format(seg["@stop_id"]),
                    format(boardings), format(alightings), format(walk_access_on),
                    format(direct_xfer_on), format(walk_xfer_on), format(direct_xfer_off),
                    format(walk_xfer_off), format(egress_off)]))
                fout_stop.write("\n")

    def check_network_adj(self, scenario):
        if scenario.extra_attribute("@network_adj"):
            return
        # This is normally generated by the build transit network
        # tool, but in case the attribute is missing the calculation
        # here will label the nodes.
        # Identify and label network constuction nodes
        #     1 = TAP adjcent nodes, 
        #     2 = circle line free transfer nodes
        #     3 = timed xfer walk connection nodes

        network = self.get_partial_network(scenario, 
            {"LINK": ["@tcov_id"], "TRANSIT_SEGMENT": None})

        max_node_id = max(n.number for n in network.nodes())
        adj_node_id = math.floor(max_node_id / 10000.0) * 10000

        # TAP adjacent stops
        xfer_mode = network.mode('x')
        walk_mode = network.mode('w')
        access_mode  = network.mode('a')
        for centroid in network.centroids():
            stop_node = centroid.outgoing_links().next().j_node
            if stop_node.number < adj_node_id:
                continue
            out_links = [l for l in stop_node.outgoing_links() if access_mode not in l.modes]
            if len(out_links) > 1:
                continue
            transit_egress_link = out_links[0] 
            has_adjacent_transfer_links = False
            has_adjacent_walk_links = False
            for stop_link in transit_egress_link.j_node.outgoing_links():
                if xfer_mode in stop_link.modes :
                    has_adjacent_transfer_links = True
                if walk_mode in stop_link.modes :
                    has_adjacent_walk_links = True

            if has_adjacent_transfer_links and not has_adjacent_walk_links:
                stop_node.network_adj = 1

        for line in network.transit_lines():    
            # check if circle line
            first_seg = line.segment(0)
            last_seg = line.segment(-1)
            if first_seg.i_node == last_seg.i_node:
                first_seg.i_node["@network_adj"] = 2
                
            # Check if there are timed xfer nodes
            all_segs = line.segments()
            prev_seg = all_segs.next()
            for seg in all_segs:
                if prev_seg.link["@tcov_id"] == seg.link["@tcov_id"]:
                    prev_seg.j_node["@network_adj"] = 3
                prev_seg = seg

        xatt = scenario.create_extra_attribute("NODE", "@network_adj")
        xatt.description = "Model: 1=TAP adj, 2=circle, 3=timedxfer"
        values = network.get_attribute_values("NODE", ["network_adj"])
        xatt = scenario.create_extra_attribute("NODE", "@network_adj")
        xatt.description = "Model: 1=TAP adj, 2=circle, 3=timedxfer"
        scenario.set_attribute_values("NODE", ["@network_adj"], values)

    def collapse_network_adjustments(self, network, segment_results, link_results):
        segment_result_attrs = [v for k, v in segment_results.items() if k != "transit_volumes"]
        link_result_attrs = link_results.values()
        link_attrs = network.attributes("LINK")
        seg_attrs = network.attributes("TRANSIT_SEGMENT")
        line_attrs = network.attributes("TRANSIT_LINE")

        transit_modes = set([network.mode(m) for m in "blryepc"])
        aux_modes = set([network.mode(m) for m in "wxa"])
        xfer_mode = network.mode('x')

        def copy_seg_attrs(src_seg, dst_seg):
            for attr in segment_result_attrs:
                dst_seg[attr] += src_seg[attr]
            dst_seg["allow_alightings"] |= src_seg["allow_alightings"]
            dst_seg["allow_boardings"] |= src_seg["allow_boardings"]

        def get_short_link(node): 
            for link in _chain(node.outgoing_links(), node.incoming_links()):
                if link.length == 0 and (link.modes & transit_modes) and not (link.modes & aux_modes):
                    return link
            return None
            
        def get_xfer_link(node, timed_xfer_link, is_outgoing): 
            links = node.outgoing_links() if is_outgoing else node.incoming_links()
            for link in links:
                if xfer_mode in link.modes and link.length == timed_xfer_link.length:
                    return link
            return None

        def remove_timed_xfer_links(node, short_link):
            if short_link.i_node == node:
                stop_node = short_link.j_node
            else:
                stop_node = short_link.i_node
            for link in node.outgoing_links():
                if xfer_mode in link.modes and link.j_node["@network_adj"] == 3:
                    xfer_link = get_xfer_link(stop_node, link, is_outgoing=True)
                    for attr in link_result_attrs:
                        xfer_link[attr] += link[attr]
                    network.delete_link(link.i_node, link.j_node)
            for link in node.incoming_links():
                if xfer_mode in link.modes and link.i_node["@network_adj"] == 3:
                    xfer_link = get_xfer_link(stop_node, link, is_outgoing=False)
                    for attr in link_result_attrs:
                        xfer_link[attr] += link[attr]
                    network.delete_link(link.i_node, link.j_node)

        lines_to_update = set([])
        nodes_to_merge = []
        nodes_to_delete = []

        for node in network.nodes():
            if 1 <= node["@network_adj"] <= 2:
                if node["@network_adj"] == 1:
                    nodes_to_merge.append(node)
                    incoming_seg_shift = 2
                if node["@network_adj"] == 2:
                    nodes_to_delete.append(node)
                    incoming_seg_shift = -1
                node_pairs = set([])
                # copy boarding / alighting attributes for the segments to the original segment / stop
                for seg in node.incoming_segments():
                    lines_to_update.add(seg.line)
                    node_pairs.add((seg.i_node, seg.j_node))
                    copy_seg_attrs(seg, seg.line.segment(seg.number+incoming_seg_shift))
                for seg in node.outgoing_segments():
                    lines_to_update.add(seg.line)
                    node_pairs.add((seg.j_node, seg.i_node))
                    copy_seg_attrs(seg, seg.line.segment(seg.number+1))
                # optimization: skip setting node results as they are unused in this script
                #for node, dup_node in node_pairs:
                #    node.initial_boardings += dup_node.initial_boardings
                #    node.final_alightings += dup_node.final_alightings
            elif node["@network_adj"] == 3:
                short_link = get_short_link(node)
                remove_timed_xfer_links(node, short_link)
                mapping = network.merge_links_mapping(node)
                for (link1, link2), attr_map in mapping['links'].iteritems():
                    if link1 is short_link or link1.reverse_link is short_link:
                        for attr in link_attrs:
                            attr_map[attr] = link2[attr]
                    else:
                        for attr in link_attrs:
                            attr_map[attr] = link1[attr]
                        
                for (seg1, seg2), attr_map in mapping['transit_segments'].iteritems():
                    if seg1.link is short_link or seg1.link.reverse_link is short_link:
                        short_seg, long_seg = seg1, seg2
                    else:
                        short_seg, long_seg = seg2, seg1
                    for attr in seg_attrs:
                        attr_map[attr] = long_seg[attr]
                    for attr in segment_result_attrs:
                        attr_map[attr] = long_seg[attr] + short_seg[attr]
                network.merge_links(node, mapping)
        
        # Backup transit lines with altered routes and remove from network
        lines = []
        for line in lines_to_update:
            seg_data ={}
            itinerary = []
            for seg in line.segments(include_hidden=True):
                if seg.i_node["@network_adj"] in [1,2] or (seg.j_node and seg.j_node["@network_adj"] in [1,2]):
                    continue
                seg_data[(seg.i_node, seg.j_node, seg.loop_index)] = \
                    dict((k, seg[k]) for k in seg_attrs)
                itinerary.append(seg.i_node.number)
            lines.append({
                "id": line.id,
                "vehicle": line.vehicle,
                "itinerary": itinerary,
                "attributes": dict((k, line[k]) for k in line_attrs),
                "seg_attributes": seg_data})
            network.delete_transit_line(line)
        # Remove duplicate network elements (undo network adjustments)
        for node in nodes_to_delete:
            for link in _chain(node.incoming_links(), node.outgoing_links()):
                network.delete_link(link.i_node, link.j_node)
            network.delete_node(node)
        for node in nodes_to_merge:
            mapping = network.merge_links_mapping(node)
            for (link1, link2), attr_map in mapping["links"].iteritems():
                if link2.j_node.is_centroid:
                    link1, link2 = link2, link1
                for attr in link_attrs:
                    attr_map[attr] = link1[attr]
            network.merge_links(node, mapping)
        # Re-create transit lines on new itineraries
        for line_data in lines:
            new_line = network.create_transit_line(
                line_data["id"], line_data["vehicle"], line_data["itinerary"])
            for k, v in line_data["attributes"].iteritems():
                new_line[k] = v
            seg_data = line_data["seg_attributes"]
            for seg in new_line.segments(include_hidden=True):
                data = seg_data.get((seg.i_node, seg.j_node, seg.loop_index), {})
                for k, v in data.iteritems():
                    seg[k] = v

    def calc_additional_results(self, scenario, class_name, num_processors,
                                total_walk_flow, segment_results, link_transit_flow,
                                access_walk_flow, xfer_walk_flow, egress_walk_flow):
        network_results = _m.Modeller().tool(
            "inro.emme.transit_assignment.extended.network_results")
        path_based_analysis = _m.Modeller().tool(
            "inro.emme.transit_assignment.extended.path_based_analysis")
        net_calculator = _m.Modeller().tool(
            "inro.emme.network_calculation.network_calculator")

        spec = {
            "on_links": {
                "aux_transit_volumes": total_walk_flow.id
            },
            "on_segments": segment_results,
            "aggregated_from_segments": None,
            "analyzed_demand": None,
            "constraint": None,
            "type": "EXTENDED_TRANSIT_NETWORK_RESULTS"
        }
        network_results(specification=spec, scenario=scenario,
                        class_name=class_name, num_processors=num_processors)
        cal_spec = {
            "result": "%s" % link_transit_flow.id,
            "expression": "%s" % segment_results["transit_volumes"],
            "aggregation": "+",
            "selections": {
                "link": "all",
                "transit_line": "all"
            },
            "type": "NETWORK_CALCULATION"
        }
        net_calculator(cal_spec, scenario=scenario)

        walk_flows = [("INITIAL_BOARDING_TO_FINAL_ALIGHTING", access_walk_flow.id),
                      ("INITIAL_BOARDING_TO_FINAL_ALIGHTING", xfer_walk_flow.id),
                      ("FINAL_ALIGHTING_TO_DESTINATION", egress_walk_flow.id)]
        for portion_of_path, aux_transit_volumes in walk_flows:
            spec = {
                    "portion_of_path": portion_of_path,
                    "trip_components": {
                        "in_vehicle": None,
                        "aux_transit": "length",
                        "initial_boarding": None,
                        "transfer_boarding": None,
                        "transfer_alighting": None,
                        "final_alighting": None
                    },
                    "path_operator": ".max.",
                    "path_selection_threshold": {
                        "lower": -1.0,
                        "upper": 999999.0
                    },
                    "path_to_od_aggregation": None,
                    "constraint": None,
                    "analyzed_demand": None,
                    "results_from_retained_paths": {
                        "paths_to_retain": "SELECTED",
                        "aux_transit_volumes": aux_transit_volumes
                    },
                    "path_to_od_statistics": None,
                    "path_details": None,
                    "type": "EXTENDED_TRANSIT_PATH_ANALYSIS"
                }
            path_based_analysis(
                specification=spec, scenario=scenario,
                class_name=class_name, num_processors=num_processors)
        
    def transfer_analysis(self, scenario, net, class_name, num_processors):
        create_attribute = _m.Modeller().tool(
            "inro.emme.data.extra_attribute.create_extra_attribute")
        transfers_at_stops = _m.Modeller().tool(
            "inro.emme.transit_assignment.extended.apps.transfers_at_stops")

        # find stop with/without walk transfer option
        stop_walk_list = []  # stop (id) with walk option
        stop_flag = "@stop_flag"
        create_attribute("NODE", att, "1=stop without walk option, 2=otherwise",
                                     0, overwrite=True, scenario=scenario)
        stop_nline = "@stop_nline"
        create_attribute("NODE", stop_nline, "number of lines on the stop",
                                      0, overwrite=True, scenario=scenario)

        for line in net.transit_lines():
            for seg in line.segments(True):
                node = seg.i_node
                if seg.allow_alightings or seg.allow_boardings:
                    node[stop_nline] += 1
                if node[stop_flag] > 0 :  #node checked
                    continue
                if seg.allow_alightings or seg.allow_boardings:
                    node[stop_flag] = 1
                    for ilink in node.incoming_links():
                        # skip connector
                        if ilink.i_node.is_centroid:
                            continue
                        for m in ilink.modes:
                            if m.type=="AUX_TRANSIT":
                                node[stop_flag] = 2
                                stop_walk_list.append(node.id)
                                break
                        if node[stop_flag]>=2:
                            break
                    if node[stop_flag]>=2:
                        continue
                    for olink in node.outgoing_links():
                        # skip connector
                        if olink.j_node.is_centroid:
                            continue
                        for m in olink.modes:
                            if m.type=="AUX_TRANSIT":
                                node[stop_flag] = 2
                                stop_walk_list.append(node.id)
                                break
                        if node[stop_flag]>=2:
                            break
        #scenario.publish_network(net)
        stop_off = {}
        stop_on = {}
        for stop in stop_walk_list:
            stop_off[stop] = {}
            stop_on[stop] = {}
            selection = "i=%s" % stop
            results = transfers_at_stops(
                selection, scenario=scenario,
                class_name=class_name, num_processors=num_processors)
            for off_line in results:
                stop_off[stop][off_line] = 0.0
                for on_line in results[off_line]:
                    trip = float(results[off_line][on_line])
                    stop_off[stop][off_line] += trip
                    if not stop_on[stop].has_key(on_line):
                        stop_on[stop][on_line] = 0.0
                    stop_on[stop][on_line] += trip
        return stop_off, stop_on

    @_m.method(return_type=unicode)
    def tool_run_msg_status(self):
        return self.tool_run_msg
