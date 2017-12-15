##//////////////////////////////////////////////////////////////////////////////
#////                                                                       ///
#//// Copyright INRO, 2016-2017.                                            ///
#//// Rights to use and modify are granted to the                           ///
#//// San Diego Association of Governments and partner agencies.            ///
#//// This copyright notice must be preserved.                              ///
#////                                                                       ///
#////  utilities/properties.py                                              ///
#////                                                                       ///
#////                                                                       ///
#////                                                                       ///
#////                                                                       ///
#//////////////////////////////////////////////////////////////////////////////

TOOLBOX_ORDER = 103


import inro.modeller as _m
import traceback as _traceback
from collections import OrderedDict
import os


class PropertiesSetter(object):

    startFromIteration = _m.Attribute(int)
    sample_rates = _m.Attribute(str)

    skipBuildNetwork = _m.Attribute(bool)
    skipCopyWarmupTripTables = _m.Attribute(bool)
    skipCopyBikeLogsum = _m.Attribute(bool)
    skipCopyWalkImpedance = _m.Attribute(bool)
    skipWalkLogsums = _m.Attribute(bool)
    skipBikeLogsums = _m.Attribute(bool)
    skipInitialization = _m.Attribute(bool)
    deleteAllMatrices = _m.Attribute(bool)

    skipHighwayAssignment_1 = _m.Attribute(bool)
    skipHighwayAssignment_2 = _m.Attribute(bool)
    skipHighwayAssignment_3 = _m.Attribute(bool)
    skipHighwaySkimming_1 = _m.Attribute(bool)
    skipHighwaySkimming_2 = _m.Attribute(bool)
    skipHighwaySkimming_3 = _m.Attribute(bool)
    skipTransitSkimming_1 = _m.Attribute(bool)
    skipTransitSkimming_2 = _m.Attribute(bool)
    skipTransitSkimming_3 = _m.Attribute(bool)
    skipCoreABM_1 = _m.Attribute(bool)
    skipCoreABM_2 = _m.Attribute(bool)
    skipCoreABM_3 = _m.Attribute(bool)
    skipOtherSimulateModel_1 = _m.Attribute(bool)
    skipOtherSimulateModel_2 = _m.Attribute(bool)
    skipOtherSimulateModel_3 = _m.Attribute(bool)
    skipCTM_1 = _m.Attribute(bool)
    skipCTM_2 = _m.Attribute(bool)
    skipCTM_3 = _m.Attribute(bool)
    skipEI_1 = _m.Attribute(bool)
    skipEI_2 = _m.Attribute(bool)
    skipEI_3 = _m.Attribute(bool)
    skipExternalExternal_1 = _m.Attribute(bool)
    skipExternalExternal_2 = _m.Attribute(bool)
    skipExternalExternal_3 = _m.Attribute(bool)
    skipTruck_1 = _m.Attribute(bool)
    skipTruck_2 = _m.Attribute(bool)
    skipTruck_3 = _m.Attribute(bool)
    skipTripTableCreation_1 = _m.Attribute(bool)
    skipTripTableCreation_2 = _m.Attribute(bool)
    skipTripTableCreation_3 = _m.Attribute(bool)

    skipFinalHighwayAssignment = _m.Attribute(bool)
    skipFinalTransitAssignment = _m.Attribute(bool)
    skipFinalHighwaySkimming = _m.Attribute(bool)
    skipFinalTransitSkimming = _m.Attribute(bool)
    skipDataExport = _m.Attribute(bool)
    skipDataLoadRequest = _m.Attribute(bool)
    skipDeleteIntermediateFiles = _m.Attribute(bool)

    def _get_list_prop(self, name):
        return [getattr(self, name + suffix) for suffix in ["_1", "_2", "_3"]]

    def _set_list_prop(self, name, value):
        try:
            for v_sub, suffix in zip(value, ["_1", "_2", "_3"]):
                setattr(self, name + suffix, v_sub)
        except:
            for suffix in  ["_1", "_2", "_3"]:
                setattr(self, name + suffix, False)

    skipHighwayAssignment = property(
        fget=lambda self: self._get_list_prop("skipHighwayAssignment"),
        fset=lambda self, value: self._set_list_prop("skipHighwayAssignment", value))
    skipTransitSkimming = property(
        fget=lambda self: self._get_list_prop("skipTransitSkimming"),
        fset=lambda self, value: self._set_list_prop("skipTransitSkimming", value))
    skipCoreABM = property(
        fget=lambda self: self._get_list_prop("skipCoreABM"),
        fset=lambda self, value: self._set_list_prop("skipCoreABM", value))
    skipOtherSimulateModel = property(
        fget=lambda self: self._get_list_prop("skipOtherSimulateModel"),
        fset=lambda self, value: self._set_list_prop("skipOtherSimulateModel", value))
    skipCTM = property(
        fget=lambda self: self._get_list_prop("skipCTM"),
        fset=lambda self, value: self._set_list_prop("skipCTM", value))
    skipEI = property(
        fget=lambda self: self._get_list_prop("skipEI"),
        fset=lambda self, value: self._set_list_prop("skipEI", value))
    skipExternalExternal = property(
        fget=lambda self: self._get_list_prop("skipExternalExternal"),
        fset=lambda self, value: self._set_list_prop("skipExternalExternal", value))
    skipTruck = property(
        fget=lambda self: self._get_list_prop("skipTruck"),
        fset=lambda self, value: self._set_list_prop("skipTruck", value))
    skipTripTableCreation = property(
        fget=lambda self: self._get_list_prop("skipTripTableCreation"),
        fset=lambda self, value: self._set_list_prop("skipTripTableCreation", value))

    def add_properties_interface(self, pb, disclosure=False):
        tool_proxy_tag = pb.tool_proxy_tag
        title = "Run model - skip steps"

        options = [(1, "Iteration 1"), (2, "Iteration 2"), (3, "Iteration 3"), (4, "Iteration 4")]
        pb.add_text_box('sample_rates', title="Sample rate by iteration:", size=20)
        pb.add_select("startFromIteration", keyvalues=options, title="Start from iteration")


        skip_startup_items = [
            ("skipBuildNetwork",        "Skip build of highway and transit network"),
            ("skipInitialization",      "Skip matrix and transit database initialization"),
            ("deleteAllMatrices",       "&nbsp;&nbsp;&nbsp;&nbsp;Delete all matrices"),
            ("skipCopyWarmupTripTables","Skip import of warmup trip tables"),
            ("skipCopyBikeLogsum",      "Skip copy of bike logsum"),
            ("skipCopyWalkImpedance",   "Skip copy of walk impedance"),
            ("skipWalkLogsums",         "Skip walk logsums"),
            ("skipBikeLogsums",         "Skip bike logsums"),
        ]
        skip_per_iteration_items = [
            ("skipHighwayAssignment",   "Skip highway assignment"),
            ("skipTransitSkimming",     "Skip transit skimming"),
            ("skipCoreABM",             "Skip core ABM"),
            ("skipOtherSimulateModel",  "Skip other simulation model"),
            ("skipCTM",                 "Skip commercial vehicle sub-model"),
            ("skipEI",                  "Skip external-internal sub-model"),
            ("skipExternalExternal",    "Skip external-external sub-model"),
            ("skipTruck",               "Skip truck sub-model"),
            ("skipTripTableCreation",   "Skip trip table creation"),
        ]
        skip_final_items = [
            ("skipFinalHighwayAssignment",  "Skip final highway assignments"),
            ("skipFinalTransitAssignment",  "Skip final transit assignments"),
            ("skipFinalHighwaySkimming",    "Skip final highway skimming"),
            ("skipFinalTransitSkimming",    "Skip final transit skimming"),
            ("skipDataExport",              "Skip data export"),
            ("skipDataLoadRequest",         "Skip data load request"),
            ("skipDeleteIntermediateFiles", "Skip delete intermediate files"),
        ]

        contents = ["""
        <div>
            <table class="skipitems">
                <tbody>
                <tr>
                    <th width="250px"></th>
                    <th width="90px">Iteration 1</th>
                    <th width="90px">Iteration 2</th>
                    <th width="90px">Iteration 3</th>
                </tr>"""]

        if disclosure:
            contents.insert(0, """
                <div class="t_block t_element -inro-util-disclosure">
                    <div class="-inro-util-disclosure-header t_local_title">%s</div>""" % title)
            title = ""
        
        checkbox = '<td><input class="-inro-modeller checkbox_entry" type="checkbox" id="%(name)s" data-ref="%(tag)s.%(name)s"></td>'
        checkbox_no_data = '<td><input class="-inro-modeller checkbox_entry" type="checkbox" id="%(name)s"></td>'
            
        for name, label in skip_startup_items:
            contents.append("<tr><td>%s</td>" % label)
            contents.append(checkbox % {"name": name, "tag": tool_proxy_tag})
            contents.append("<td></td><td></td>")
        contents.append("</tr><tr><td>Set / reset all</td>")
        for i in range(1,4):
            contents.append(checkbox_no_data % {"name": "all" + "_" + str(i)})
        for name, label in skip_per_iteration_items:
            contents.append("</tr><tr><td>&nbsp;&nbsp;&nbsp;&nbsp;%s</td>" % label)
            for i in range(1,4):
                contents.append(checkbox % {"name": name + "_" + str(i), "tag": tool_proxy_tag})
        for name, label in skip_final_items:
            contents.append("</tr><tr><td>%s</td>" % label)
            contents.append("<td></td><td></td>")
            contents.append(checkbox % {"name": name, "tag": tool_proxy_tag})

        contents.append("</tr></tbody></table></div>")
        if disclosure:
            contents.append("</div>")

        pb.wrap_html(title, "".join(contents))

        pb.add_html("""
<script>
    $(document).ready( function ()
    {
        var tool = new inro.modeller.util.Proxy(%(tool_proxy_tag)s) ;

        var iter_names = %(iter_items)s;

        for (var j = 1; j <= 3; j++){
            var number = j.toString();
            $("#all_" + number)
                .prop("number", number)
                .bind('click', function()    {
                    var state = $(this).prop("checked");
                    for (var i = 0; i < iter_names.length; i++) { 
                        $("#" + iter_names[i] + "_" + $(this).prop("number"))
                            .prop("checked", state)
                            .trigger('change');
                    }
                });
        }
        
        $("#startFromIteration").bind('change', function()    {
            $(this).commit();
            var iter = $(this).val();
            for (var j = 1; j < iter; j++)
                for (var i = 0; i < iter_names.length; i++) { 
                    $("#" + iter_names[i] + "_" + j.toString()).prop('disabled', true);
            }
            for (var j = iter; j <= 3; j++)
                for (var i = 0; i < iter_names.length; i++) { 
                    $("#" + iter_names[i] + "_" + j.toString()).prop('disabled', false);
            }
        }).trigger('change');
   });
</script>""" % {"tool_proxy_tag": tool_proxy_tag, 
                "iter_items": str([x[0] for x in skip_per_iteration_items])})
        return

    @_m.method(return_type=bool, argument_types=(str,))
    def get_value(self, name):
        return bool(getattr(self, name))

    @_m.method()
    def load_properties(self):
        self._properties = props = Properties(self.properties_path)

        self.startFromIteration = props.get("RunModel.startFromIteration")
        self.sample_rates = ",".join(str(x) for x in props.get("sample_rates"))
        self.skipCopyWarmupTripTables = props.get("RunModel.skipCopyWarmupTripTables")
        self.skipCopyBikeLogsum = props.get("RunModel.skipCopyBikeLogsum")
        self.skipCopyWalkImpedance = props.get("RunModel.skipCopyWalkImpedance")
        self.skipWalkLogsums = props.get("RunModel.skipWalkLogsums")
        self.skipBikeLogsums = props.get("RunModel.skipBikeLogsums")
        self.skipBuildNetwork = props.get("RunModel.skipBuildNetwork")
        self.skipInitialization = props.get("RunModel.skipInitialization")
        self.deleteAllMatrices = props.get("RunModel.deleteAllMatrices")

        self.skipHighwayAssignment = props.get("RunModel.skipHighwayAssignment")
        self.skipHighwaySkimming = props.get("RunModel.skipHighwaySkimming")
        self.skipTransitSkimming = props.get("RunModel.skipTransitSkimming")
        self.skipCoreABM = props.get("RunModel.skipCoreABM")
        self.skipOtherSimulateModel = props.get("RunModel.skipOtherSimulateModel")
        self.skipCTM = props.get("RunModel.skipCTM")
        self.skipEI = props.get("RunModel.skipEI")
        self.skipExternalExternal = props.get("RunModel.skipExternalExternal")
        self.skipTruck = props.get("RunModel.skipTruck")
        self.skipTripTableCreation = props.get("RunModel.skipTripTableCreation")

        self.skipFinalHighwayAssignment = props.get("RunModel.skipFinalHighwayAssignment")
        self.skipFinalTransitAssignment = props.get("RunModel.skipFinalTransitAssignment")
        self.skipFinalHighwaySkimming = props.get("RunModel.skipFinalHighwaySkimming")
        self.skipFinalTransitSkimming = props.get("RunModel.skipFinalTransitSkimming")
        self.skipDataExport = props.get("RunModel.skipDataExport")
        self.skipDataLoadRequest = props.get("RunModel.skipDataLoadRequest")
        self.skipDeleteIntermediateFiles = props.get("RunModel.skipDeleteIntermediateFiles")

    def save_properties(self):
        props = self._properties
        props["RunModel.startFromIteration"] = self.startFromIteration
        props["sample_rates"] = [float(x) for x in self.sample_rates.split(",")]
        props["RunModel.skipCopyWarmupTripTables"] = self.skipCopyWarmupTripTables
        props["RunModel.skipCopyBikeLogsum"] = self.skipCopyBikeLogsum
        props["RunModel.skipCopyWalkImpedance"] = self.skipCopyWalkImpedance
        props["RunModel.skipWalkLogsums"] = self.skipWalkLogsums
        props["RunModel.skipBikeLogsums"] = self.skipBikeLogsums
        props["RunModel.skipBuildNetwork"] = self.skipBuildNetwork
        props["RunModel.skipInitialization"] = self.skipInitialization
        props["RunModel.deleteAllMatrices"] = self.deleteAllMatrices
        
        props["RunModel.skipHighwayAssignment"] = self.skipHighwayAssignment
        props["RunModel.skipHighwaySkimming"] = self.skipHighwaySkimming
        props["RunModel.skipTransitSkimming"] = self.skipTransitSkimming
        props["RunModel.skipCoreABM"] = self.skipCoreABM
        props["RunModel.skipOtherSimulateModel"] = self.skipOtherSimulateModel
        props["RunModel.skipCTM"] = self.skipCTM
        props["RunModel.skipEI"] = self.skipEI
        props["RunModel.skipExternalExternal"] = self.skipExternalExternal
        props["RunModel.skipTruck"] = self.skipTruck
        props["RunModel.skipTripTableCreation"] = self.skipTripTableCreation

        props["RunModel.skipFinalHighwayAssignment"] = self.skipFinalHighwayAssignment
        props["RunModel.skipFinalTransitAssignment"] = self.skipFinalTransitAssignment
        props["RunModel.skipFinalHighwaySkimming"] = self.skipFinalHighwaySkimming
        props["RunModel.skipFinalTransitSkimming"] = self.skipFinalTransitSkimming
        props["RunModel.skipDataExport"] = self.skipDataExport
        props["RunModel.skipDataLoadRequest"] = self.skipDataLoadRequest
        props["RunModel.skipDeleteIntermediateFiles"] = self.skipDeleteIntermediateFiles

        props.save()


class PropertiesTool(_m.Tool(), PropertiesSetter):

    properties_path = _m.Attribute(unicode)

    def __init__(self):
        project_dir = os.path.dirname(_m.Modeller().desktop.project.path)
        self.properties_path = os.path.join(
            os.path.dirname(project_dir), "conf", "sandag_abm.properties")
        self._properties = None
        if os.path.exists(self.properties_path):
            self.load_properties()

    tool_run_msg = ""

    @_m.method(return_type=_m.UnicodeType)
    def tool_run_msg_status(self):
        return self.tool_run_msg

    def page(self):
        pb = _m.ToolPageBuilder(self)
        pb.title = 'Set properties'
        pb.description = """Properties setting tool."""
        pb.branding_text = ' - SANDAG - Utilities'
        tool_proxy_tag = pb.tool_proxy_tag

        pb.add_select_file('properties_path', 'file', title='Path to properties file:')

        pb.wrap_html("", """
            <div><button id="load_reset" style="width:150px; text-align:center;">
                Load / Reset
            </button></div>""")

        pb.add_html("""
<script>
    $(document).ready( function ()
    {
        var tool = new inro.modeller.util.Proxy(%(tool_proxy_tag)s) ;

        var run_text = $(".-inro-util-execute-button").children().next();
        run_text.html("Save")
        
        $("#load_reset").bind('click', function()    {
            tool.load_properties()
            $("input:checkbox").each(function() {
                $(this).prop('checked', tool.get_value($(this).prop('id')) );
            });
            $("#startFromIteration").prop('value', tool.startFromIteration);
            $("#sample_rates").prop('value', tool.sample_rates);
        });
   });
</script>""" % {"tool_proxy_tag": tool_proxy_tag})
        self.add_properties_interface(pb)
        return pb.render()

    def run(self):
        self.tool_run_msg = ""
        try:
            self.save_properties()
            message = "Properties file saved"
            self.tool_run_msg = _m.PageBuilder.format_info(message, escape=False)
        except Exception, e:
            self.tool_run_msg = _m.PageBuilder.format_exception(
                e, _traceback.format_exc(e))
            raise

    def __call__(self, file_path):
        return Properties(file_path)


# Singleton implementation to avoid re-reading the file in the same process
_properties_lookup = {}

class Properties(object):

    def __new__(cls, path="./sandag_abm.properties", *args, **kwargs):
        path = os.path.normpath(os.path.abspath(unicode(path)))
        if os.path.isdir(path):
            path = os.path.join(path, "sandag_abm.properties")
        properties = _properties_lookup.get(os.path.normcase(path), None)
        return properties or object.__new__(cls, *args, **kwargs)

    def __init__(self, path="./sandag_abm.properties"):
        if os.path.isdir(path):
            path = os.path.join(path, "sandag_abm.properties")
        timestamp = os.path.getmtime(path)
        if hasattr(self, "_created"):
            if self._timestamp == timestamp:
                return
        self._path = os.path.normpath(os.path.abspath(path))
        self._load_properties()
        self._created = True
        self._timestamp = timestamp
        _properties_lookup[os.path.normcase(self._path)] = self        

    def _load_properties(self):
        self._prop = prop = OrderedDict()
        self._comments = comments = {}
        with open(self._path, 'r') as properties:
            comment = []
            for line in properties:
                line = line.strip()
                if not line or line.startswith('#'):
                    comment.append(line)
                    continue
                key, value = line.split('=')
                key = key.strip()
                tokens = value.split(',')
                if len(tokens) > 1:
                    value = self._parse_list(tokens)
                else:
                    value = self._parse(value)
                prop[key] = value
                comments[key], comment = comment, []

    def _parse_list(self, values):
        converted_values = []
        for v in values:
            converted_values.append(self._parse(v))
        return converted_values

    def _parse(self, value):
        value = str(value).strip()
        if value == 'true':
            return True
        elif value == 'false':
            return False
        for caster in int, float:
            try:
                return caster(value)
            except ValueError:
                pass
        return value

    def _format(self, value):
        if isinstance(value, bool):
            return "true" if value else "false"
        return str(value)

    def save(self, path=None):
        if not path:
            path = self._path
        with open(path, 'w') as f:
            for key, value in self._prop.iteritems():
                if isinstance(value, list):
                    value = ",".join([self._format(v) for v in value])
                else:
                    value = self._format(value)
                comment = self._comments.get(key)
                if comment:
                    for line in comment:
                        f.write(line)
                        f.write("\n")
                f.write("%s = %s\n" % (key, value))

    def __setitem__(self, key, item): 
        self._prop[key] = item

    def __getitem__(self, key): 
        return self._prop[key]

    def __repr__(self): 
        return "Properties(%s)" % self._path

    def __len__(self): 
        return len(self._prop)

    def __delitem__(self, key): 
        del self._prop[key]

    def clear(self):
        return self._prop.clear()

    def has_key(self, k):
        return self._prop.has_key(k)

    def pop(self, k, d=None):
        return self._prop.pop(k, d)

    def update(self, *args, **kwargs):
        return self._prop.update(*args, **kwargs)

    def keys(self):
        return self._prop.keys()

    def values(self):
        return self._prop.values()

    def items(self):
        return self._prop.items()

    def pop(self, *args):
        return self._prop.pop(*args)

    def get(self, k, default=None):
        try:
            return self[k]
        except KeyError:
            return default

    def __cmp__(self, dict):
        return cmp(self._prop, dict)

    def __contains__(self, item):
        return item in self._prop

    def __iter__(self):
        return iter(self._prop)

    def __unicode__(self):
        return unicode(repr(self._prop))