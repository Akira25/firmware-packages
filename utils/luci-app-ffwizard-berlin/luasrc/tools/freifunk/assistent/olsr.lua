local util = require "luci.util"
local uci = require "luci.model.uci".cursor()
local tools = require "luci.tools.freifunk.assistent.ffwizard"

local sharenet = uci:get("ffwizard","settings","sharenet")
local community = "profile_"..uci:get("freifunk", "community", "name")

module "luci.tools.freifunk.assistent.olsr"

function prepareOLSR()
	local c = uci.cursor()
	uci:delete_all("olsrd", "olsrd")
	uci:delete_all("olsrd", "InterfaceDefaults")
	uci:delete_all("olsrd", "Interface")
	uci:delete_all("olsrd", "Hna4")
	uci:delete_all("olsrd", "Hna6")
	uci:delete_all("olsrd", "LoadPlugin", {library="olsrd_dyn_gw.so.0.5"})

	uci:delete_all("olsrd6", "olsrd")
	uci:delete_all("olsrd6", "InterfaceDefaults")
	uci:delete_all("olsrd6", "Interface")
	uci:delete_all("olsrd6", "Hna4")
	uci:delete_all("olsrd6", "Hna6")
	uci:delete_all("olsrd6", "LoadPlugin", {library="olsrd_dyn_gw.so.0.5"})

	uci:save("olsrd")
	uci:save("olsrd6")
end

function configureOLSR()
	-- olsr 4
	local olsrbase = uci:get_all("freifunk", "olsrd") or {}
	util.update(olsrbase, uci:get_all(community, "olsrd") or {})
	uci:section("olsrd", "olsrd", nil, olsrbase)

	-- olsr 6
	local olsr6base = uci:get_all("freifunk", "olsrd6") or {}
	util.update(olsr6base, uci:get_all(community, "olsrd6") or {})
	uci:section("olsrd6", "olsrd", nil, olsr6base)

	-- olsr 4 and 6 interface defaults
	local olsrifbase = uci:get_all("freifunk", "olsr_interface") or {}
	util.update(olsrifbase, uci:get_all(community, "olsr_interface") or {})
	uci:section("olsrd", "InterfaceDefaults", nil, olsrifbase)
	uci:section("olsrd6", "InterfaceDefaults", nil, olsrifbase)


	uci:save("olsrd")
	uci:save("olsrd6")
end

function configureOLSRPlugins()
	local suffix = uci:get_first(community, "community", "suffix") or "olsr"
	updatePlugin("olsrd_nameservice.so.0.3", "suffix", "."..suffix)
	uci:save("olsrd")
	uci:save("olsrd6")
end

function updatePluginInConfig(config, pluginName, key, value)
	uci:foreach(config, "LoadPlugin",
		function(plugin)
			if (plugin.library == pluginName) then
				uci:set("olsrd", plugin['.name'], key, value)
			end
		end)
end

function updatePlugin(pluginName, key, value)
	updatePluginInConfig("olsrd", pluginName, key, value)
	updatePluginInConfig("olsrd6", pluginName, key, value)
end
