local skynet = require("skynet")
local netpack = require("netpack")
local log = require("loggerproxy")
local gate = require("gateproxy")
local agentmanager = require("agentmanagerproxy")
local WatchdogService = class("WatchdogService")
local AuthSession = require("watchdog.authsession")

local inst = nil
function WatchdogService.instance()
	if not inst then
		inst = WatchdogService.new()
	end
	return inst
end

function WatchdogService:ctor()
	self.CMD = {
		start = self.onCommandStart,
		close = self.onCommandClose,
	}
	self.SOCKET = {
		open = self.onSocketOpen,
		close = self.onSocketClose,
		error = self.onSocketError,
		warning = self.onSocketWarning,
		data = self.onSocketData,
	}
	self.mapSession = {}
end

function WatchdogService:closeSession(fd)
	if self.mapSession[fd] == nil then
		agentmanager.sendDisconnect(fd)
	else
		self.mapSession[fd] = nil
		gate.callKick(fd)
	end
end

function WatchdogService:onSocketOpen(fd, addr)
	log.debug("watchdog", "New client from : " .. addr)
	local session = AuthSession.new()
	session:init(fd, addr, LOGIN_PROTOCOL_INDEX, 0, 0)
	self.mapSession[fd] = session

	gate.callForward(fd, fd)
end

function WatchdogService:onSocketClose(fd)
	log.debug("watchdog", "socket close : " .. fd)
	self:closeSession(fd)
end

function WatchdogService:onSocketError(fd, msg)
	log.info("watchdog", "socket error", fd, msg)
	self:closeSession(fd)
end

function WatchdogService:onSocketWarning(fd, size)
	log.info("watchdog", "socket warning", fd, size)
end

function WatchdogService:onSocketData(fd, msg)

end

function WatchdogService:onCommandStart(conf)
	gate.callOpen(conf)
end

function WatchdogService:onCommandClose(fd)
	self:closeSession(fd)
end

function WatchdogService:acceptSession(strAccount, fd, ip, nEncodeIdx, nDecodeIdx)
	self.mapSession[fd] = nil
	local agent = agentmanager.callCreateAgent(strAccount, fd, ip, nEncodeIdx, nDecodeIdx)
	assert(agent)
	gate.callForward(fd, 0, agent)
end

function WatchdogService:start()
	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = function (msg, sz)
			return msg, sz
		end,
		dispatch = function(_, fd, msg, sz)
			local session = self.mapSession[fd]
			if session then
				if session:processMsgLogin(session:unpackMessage(msg, sz)) then
					self:acceptSession(session.strAccount, session.fd, session.ip, session.nEncodeIdx, session.nDecodeIdx)
				else
					self:closeSession(session.fd)
				end
			end
		end
	}

	skynet.start(function()
		skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
			if cmd == "socket" then
				local f = self.SOCKET[subcmd]
				f(self, ...)
				-- socket api don't need return
			else
				local f = assert(self.CMD[cmd])
				skynet.ret(skynet.pack(f(self, subcmd, ...)))
			end
		end)

		skynet.uniqueservice("gate")
		gate.initServiceAddr()
		agentmanager.initServiceAddr()
	end)
end

return WatchdogService
