local skynet = require("skynet")
local AgentManagerService = class("AgentManagerService")

local inst = nil
function AgentManagerService.instance()
	if not inst then
		inst = AgentManagerService.new()
	end
	return inst
end

function AgentManagerService:ctor()
	self.mapWorkingAgentByAccount = {}
	self.mapWorkingAgentByCharacterId = {}
	self.mapIdleAgent = {}
end

function AgentManagerService:startAgent(account)

end

function AgentManagerService:start()

end

return AgentManagerService
