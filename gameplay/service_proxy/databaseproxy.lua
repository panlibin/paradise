local skynet = require("skynet")
local dbconfig = require("dbconfig")
local log = require("loggerproxy")

local database = {}

local strDbSrvName = nil

function database.sendMessage( ... )
	return skynet.call(strDbSrvName, "lua", "msg", ...)
end

function database.callConnect(conf)
	return skynet.call(strDbSrvName, "lua", "connect", conf)
end

function database.callDisconnect()
	return skynet.call(strDbSrvName, "lua", "disconnect")
end

function database.callQuery(sql)
	return skynet.call(strDbSrvName, "lua", "query", sql)
end

function database.sendExecute(sql)
	skynet.send(strDbSrvName, "lua", "execute", sql)
end

function database.setDbSrvName(strName)
	strDbSrvName = strName
end

return database
