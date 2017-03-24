local skynet = require("skynet")
local netpack = require("netpack")
local log = require("loggerproxy")
local gate = require("gateproxy")
local WatchdogService = class("WatchdogService")
local AuthSession = require("watchdog.authsession")

require("databaseproxy", require("dbconfig").service, 0)

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
	self.gate = nil
	self.session = {}
end

function WatchdogService:closeSession(fd)
	local s = self.session[fd]
	self.session[fd] = nil
	if s then
		skynet.call(self.gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(s, "lua", "disconnect")
	end
end

function WatchdogService:onSocketOpen(fd, addr)
	log.debug("watchdog", "New client from : " .. addr)
	self.session[fd] = AuthSession.new(fd, addr, self.gate, LOGIN_PROTOCOL_INDEX)
	gate.callForward(self.gate, fd, fd)
	-- skynet.call(self.session[fd], "lua", "start", { gate = self.gate, client = fd, watchdog = skynet.self() })
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
	skynet.call(self.gate, "lua", "open" , conf)
end

function WatchdogService:onCommandClose(fd)
	self:closeSession(fd)
end

function WatchdogService:start()
	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = function (msg, sz)
			return msg, sz
		end,
		dispatch = function (_, fd, msg, sz)
			local session = self.session[fd]
			if session then
				session:processMsgLogin(session:unpackMessage(msg, sz))
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

		self.gate = skynet.newservice("gate")
	end)
end

return WatchdogService
