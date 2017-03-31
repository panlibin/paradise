local skynet = require("skynet")
local mysql = require("mysql")
local dbconfig = require("dbconfig")
local log = require("loggerproxy")
require("skynet.manager")
local DatabaseService = class("DatabaseService")

local MAX_RECONNECT_TIMES = 3
local inst = nil
local NORET = NORET

local DatabaseState = {
	Disconnected = 0,
	Connecting = 1,
	Working = 2,
	Recovering = 3,
}

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
	self.state = DatabaseState.Disconnected
	self.arrWaitingOperation = {}
end

function DatabaseService:connect(conf)
	if self.state == DatabaseState.Connecting or conf == nil then
		return false
	end
	local lastState = self.state
	self.state = DatabaseState.Connecting
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
		self.nReconnectTimes = 0
		if next(self.arrWaitingOperation) == nil then
			self.state = DatabaseState.Working
		else
			self.state = DatabaseState.Recovering
			if lastState ~= DatabaseState.Recovering then
				skynet.fork(function()
					self:recover()
				end)
			end
		end
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

function DatabaseService:execute(sql, isRecover)
	local ok = false
	local res = nil
	if self.db ~= nil and (self.state == DatabaseState.Working or isRecover) then
		ok, res = pcall(self.db.query, self.db, sql)
		if ok then
			if res.errno then
				log.info("database", dump(res))
				if res.errno == 1053 then
					ok = false
				end
			end
		end
	end
	if not ok then
		if not isRecover then
			table.insert(self.arrWaitingOperation, {
				fun = self.execute,
				sql = sql,
				ret = nil
			})
			self:connect(self.conf)
		else
			return NORET
		end
	end
end

function DatabaseService:query(sql, isRecover)
	local ok = false
	local res = nil
	if self.db ~= nil and (self.state == DatabaseState.Working or isRecover) then
		ok, res = pcall(self.db.query, self.db, sql)
		if ok then
			if res.errno then
				log.info("database", dump(res))
				if res.errno == 1053 then
					ok = false
				else
					return nil
				end
			elseif res.mulitresultset then
				return res[1]
			else
				return res
			end
		end
	end
	if not ok then
		if not isRecover then
			table.insert(self.arrWaitingOperation, {
				fun = self.query,
				sql = sql,
				ret = skynet.response()
			})
			self:connect(self.conf)
		end
		return NORET
	end
end

function DatabaseService:recover()
	while next(self.arrWaitingOperation) ~= nil do
		local mapRecoverContex = self.arrWaitingOperation[1]
		res = mapRecoverContex.fun(self, mapRecoverContex.sql, true)
		if res ~= NORET then
			local f = mapRecoverContex.ret
			if f then
				f(true, res)
			end
			table.remove(self.arrWaitingOperation, 1)
		else
			if not self:connect(self.conf) then
				return
			end
		end
	end
	self.state = DatabaseState.Working
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
