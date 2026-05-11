local commandsDir = "/Commands"

shell.setAlias("netopen", commandsDir .. "/netopen.lua")
shell.setAlias("netping", commandsDir .. "/netping.lua")
shell.setAlias("netsend", commandsDir .. "/netsend.lua")
shell.setAlias("netlisten", commandsDir .. "/netlisten.lua")
shell.setAlias("netbroadcast", commandsDir .. "/netbroadcast.lua")
shell.setAlias("sysinfo", commandsDir .. "/sysinfo.lua")

print("Command aliases from " .. commandsDir .. " have been set.")
