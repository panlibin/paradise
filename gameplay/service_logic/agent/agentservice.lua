local skynet = require("skynet")
local database = require("databaseproxy")
local dbconfig = require("dbconfig")
local log = require("loggerproxy")
local Player = require("agent.player")
local AgentService = class("AgentService")

local fnStringFormat = string.format

local NORET = NORET
local inst = nil
function AgentService.instance()
	if not inst then
		inst = AgentService.new()
	end
	return inst
end

function AgentService:ctor()
	self.command = {
		init = self.init,
		login = self.login,
		logout = self.logout,
		release = self.release,
		exit = self.exit,
	}
	self.player = Player.instance()
end

function AgentService:init(...)
	log.stdout("AgentService:init()", ...)
	self.player:init(...)
end

function AgentService:login(...)
	log.stdout("AgentService:login()", ...)
	self.player:login(...)
end

function AgentService:logout(...)
	log.stdout("AgentService:logout()", ...)
	self.player:logout(...)
end

function AgentService:release(...)
	log.stdout("AgentService:release()", ...)
	self.player:release(...)
end

function AgentService:exit()
	skynet.exit()
end

function AgentService:start()
	skynet.start(function()
		skynet.dispatch("lua", function(_, _, cmd, ...)
			local f = self.command[cmd]
			if f ~= nil then
				local res = f(self, ...)
				if res ~= NORET then
					skynet.ret(skynet.pack(res))
				end
			end
		end)

		database.setDbSrvName(fnStringFormat(".playerdb%d", skynet.self() % dbconfig.player.instAmount))
	end)
end

return AgentService
