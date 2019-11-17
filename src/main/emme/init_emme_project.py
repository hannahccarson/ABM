#///////////////////////////////////////////////////////////////////////////////
#////                                                                        ///
#//// Copyright INRO, 2016-2019.                                             ///
#//// Rights to use and modify are granted to the                            ///
#//// San Diego Association of Governments and partner agencies.             ///
#//// This copyright notice must be preserved.                               ///
#////                                                                        ///
#//// init_emme_project.py                                                   ///
#////                                                                        ///
#////     Usage: init_emme_project.py [-r root] [-t title]                   ///
#////                                                                        ///
#////         [-r root]: Specifies the root directory in which to create     ///
#////              the Emme project.                                         ///
#////              If omitted, defaults to the current working directory     ///
#////         [-t title]: The title of the Emme project and Emme database.   ///
#////              If omitted, defaults to SANDAG empty database.            ///
#////         [-v emmeversion]: Emme version to use to create the project.   ///
#////              If omitted, defaults to 4.3.7.                            ///
#////                                                                        ///
#////                                                                        ///
#////                                                                        ///
#////                                                                        ///
#///////////////////////////////////////////////////////////////////////////////

import inro.emme.desktop.app as _app
import inro.emme.desktop.types as _ws_types
import inro.emme.database.emmebank as _eb
import argparse
import os


def init_emme_project(root, title, emmeversion):
    project_path = _app.create_project(root, "emme_project")
    desktop = _app.start_dedicated(
        project=project_path, user_initials="WS", visible=False)
    project = desktop.project
    project.name = "SANDAG Emme project"
    prj_file_path = os.path.expandvars(
        r"%EMMEPATH%\Coordinate Systems\Projected Coordinate Systems\State Plane"
        r"\NAD 1983 NSRS2007 (US Feet)\NAD 1983 NSRS2007 StatePlane California VI FIPS 0406 (US Feet).prj")
    project.spatial_reference_file = prj_file_path
    project.initial_view = _ws_types.Box(6.18187e+06, 1.75917e+06, 6.42519e+06, 1.89371e+06)

    project_root = os.path.dirname(project_path)
    dimensions = {
        'scalar_matrices': 9999,
        'destination_matrices': 999,
        'origin_matrices': 999,
        'full_matrices': 1600,

        'scenarios': 10,
        'centroids': 5000,
        'regular_nodes': 29999,
        'links': 90000,
        'turn_entries': 13000,
        'transit_vehicles': 200,
        'transit_lines': 450,
        'transit_segments': 40000,
        'extra_attribute_values': 18000000,

        'functions': 99,
        'operators': 5000
    }

    # for Emme version > 4.3.7, add the sola_analyses dimension
    if emmeversion != '4.3.7':
        dimensions['sola_analyses'] = 240

    os.mkdir(os.path.join(project_root, "Database"))
    emmebank = _eb.create(os.path.join(project_root, "Database", "emmebank"), dimensions)
    emmebank.title = title
    emmebank.coord_unit_length = 0.000189394  # feet to miles
    emmebank.unit_of_length = "mi"
    emmebank.unit_of_cost = "$"
    emmebank.unit_of_energy = "MJ"
    emmebank.node_number_digits = 6
    emmebank.use_engineering_notation = True
    scenario = emmebank.create_scenario(100)
    scenario.title = "Empty scenario"
    emmebank.dispose()

    desktop.data_explorer().add_database(emmebank.path)
    desktop.add_modeller_toolbox("%<$ProjectPath>%/scripts/sandag_toolbox.mtbx")
    project.save()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create a new empty Emme project and database with Sandag defaults.")
    parser.add_argument('-r', '--root', help="path to the root ABM folder, default is the working folder", 
                        default=os.path.abspath(os.getcwd()))
    parser.add_argument('-t', '--title', help="the Emmebank title", 
                        default="SANDAG empty database")
    parser.add_argument('-v', '--emmeversion', help='the Emme version', default='4.3.7')
    args = parser.parse_args()

    init_emme_project(args.root, args.title, args.emmeversion)
