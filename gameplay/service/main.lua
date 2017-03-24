local skynet = require("skynet")
local log = require("loggerproxy")
local dbconfig = require("dbconfig")
local database = require("databaseproxy")

local max_client = 64

skynet.start(function()
	log.stdout("Server start")
	skynet.uniqueservice("protoloader")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)

	local playerDbConf = dbconfig.player
	for i = 0, playerDbConf.instAmount - 1 do
		local strName = string.format(playerDbConf.dbServiceName, i)
		skynet.newservice("database", strName)
		database.setDbSrvName(strName)
		database.callConnect(playerDbConf.conf)
	end

	local serviceDbConf = dbconfig.service
	for i = 0, serviceDbConf.instAmount - 1 do
		local strName = string.format(serviceDbConf.dbServiceName, i)
		skynet.newservice("database", strName)
		database.setDbSrvName(strName)
		database.callConnect(serviceDbConf.conf)
	end

	-- skynet.newservice("simpledb")
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})
	log.stdout("Watchdog listen on", 8888)

	skynet.exit()
end)
