local skynet = require("skynet")
local mysql = require("mysql")
local dbconfig = require("dbconfig")
local log = require("loggerproxy")
require("skynet.manager")
local DatabaseService = class("DatabaseService")

local MAX_RECONNECT_TIMES = 3
local inst = nil
local NORET = {}

function DatabaseService.instance()
	if not inst then
		inst = DatabaseService.new()
	end
	return inst
end

function DatabaseService:ctor()
	self.sendCommand = {
		execute = DatabaseService.execute,
	}
	self.callCommand = {
		connect = DatabaseService.connect,
		disconnect = DatabaseService.disconnect,
		query = DatabaseService.query,
	}
	self.db = nil
	self.nReconnectTimes = 0
	self.conf = nil
	self.isConnecting = false
	self.arrWaitingOperation = {}
end

function DatabaseService:connect(conf)
	if self.isConnecting == true or conf == nil then
		return false
	end
	self.isConnecting = true
	self.conf = conf
	local ok
	ok, self.db = pcall(mysql.connect, conf)
	while not ok and self.nReconnectTimes < MAX_RECONNECT_TIMES do
		self.db = nil
		self.nReconnectTimes = self.nReconnectTimes + 1
		log.info("database", "database connect failed, retry in 10s!", self.nReconnectTimes)
		skynet.sleep(1000)
		ok, self.db = pcall(mysql.connect, conf)
	end

	if ok then
		local nAmount = #self.arrWaitingOperation
		for _, v in ipairs(self.arrWaitingOperation) do
			v(true)
		end
		if nAmount ~= #self.arrWaitingOperation then
			skynet.abort()
			return false
		end

		self.arrWaitingOperation = {}
		self.nReconnectTimes = 0
		self.isConnecting = false
		return true
	else
		skynet.abort()
		return false
	end
end

function DatabaseService:disconnect()
	if self.db ~= nil then
		pcall(self.db.disconnect(), self.db)
		self.db = nil
	end
end

function DatabaseService:execute(sql)
	local ok, res
	if self.db ~= nil then
		ok, res = pcall(self.db.query, self.db, sql)
		if ok then
			if res.err then
				log.info("database", dump(res))
			end
		end
	end
	if not ok then
		table.insert(self.arrWaitingOperation, function()
			self:execute(sql)
		end)
		self:connect(self.conf)
	end
end

function DatabaseService:query(sql)
	local ok, res
	if self.db ~= nil then
		ok, res = pcall(self.db.query, self.db, sql)
		if ok then
			if res.err then
				log.info("database", dump(res))
				return nil
			elseif res.mulitresultset then
				return res[1]
			else
				return res
			end
		end
	end
	if not ok then
		local closure = skynet.response(function()
			return skynet.pack(self:query(sql))
		end)
		table.insert(self.arrWaitingOperation, closure)
		self:connect(self.conf)
		return NORET
	end
end

function DatabaseService:start(serviceName)
	skynet.start(function()
		skynet.dispatch("lua", function(_, _, cmd, ...)
			if self.sendCommand[cmd] then
				self.sendCommand[cmd](self, ...)
			elseif self.callCommand[cmd] then
				local res = self.callCommand[cmd](self, ...)
				if res ~= NORET then
					skynet.ret(skynet.pack(res))
				end
			end
		end)

		skynet.register(serviceName)
	end)
end

return DatabaseService
