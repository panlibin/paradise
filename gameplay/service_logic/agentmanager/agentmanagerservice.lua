local skynet = require("skynet")
local queue = require("skynet.queue")
local gate = require("gateproxy")
local database = require("databaseproxy")
local log = require("loggerproxy")
local AgentStub = require("agentmanager.agentstub")
local AgentManagerService = class("AgentManagerService")

local cs = queue()
local NORET = NORET
local inst = nil
function AgentManagerService.instance()
	if not inst then
		inst = AgentManagerService.new()
	end
	return inst
end

local fnStringFormat = string.format
local getAccountIdByCharacterId = getAccountIdByCharacterId

function AgentManagerService:ctor()
	self.command = {
		createagent = self.createAgentByAccount,
		getagent = self.getAgentByCharacterId,
		disconnect = self.agentDisconnect,
	}

	self.mapWorkingAgent = {}
	self.arrIdleAgent = {}
	self.mapFdAgent = {}
end

function AgentManagerService:createAgentByAccount(strAccount, fd, ip, nEncodeIdx, nDecodeIdx)
	local arrRes = database.callQuery(fnStringFormat("call pr_select_account('%s')", strAccount))
	local res = nil
	if arrRes[1] then
		res = arrRes[1]
		if res.v_errcode ~= nil or res.v_accountid == nil then
			return nil
		end
	end
	local agent = self:createAgent(res.v_accountid)

	if not agent:isLocked() then
		if agent:isOnline() then
			self.mapFdAgent[agent.fd] = nil
			agent:logout()
		end
		self.mapFdAgent[fd] = agent
		agent:login(strAccount, fd, ip, nEncodeIdx, nDecodeIdx)
	else
		agent:addWaitingOperation(skynet.response(function()
			skynet.pack(self:createAgentByAccount(strAccount, fd, ip, nEncodeIdx, nDecodeIdx))
		end))
		return NORET
	end

	if not agent:isWaitingOperationEmpty() then
		cs(agent.executeWaitingOperation, agent)
	end

	return agent.addr
end

function AgentManagerService:getAgentByCharacterId(uidCharacterId)
	local uidAccountId = getAccountIdByCharacterId(uidCharacterId)
	local agent = self:createAgent(uidAccountId)

	if agent.state == AgentState.Locked then
		agent:addWaitingOperation(skynet.response(function()
			skynet.pack(self:getAgentByCharacterId(uidCharacterId))
		end))
		return NORET
	end

	if not agent:isWaitingOperationEmpty() then
		cs(agent.executeWaitingOperation, agent)
	end

	return agent.addr
end

function AgentManagerService:createAgent(uidAccountId)
	local agent = self.mapWorkingAgent[uidAccountId]
	if agent == nil then
		agent = table.remove(self.arrIdleAgent)
		if agent == nil then
			agent = AgentStub.new()
			self.mapWorkingAgent[uidAccountId] = agent
			agent:create()
		else
			self.mapWorkingAgent[uidAccountId] = agent
		end
		agent:init(uidAccountId)
	end
	agent:active()
	return agent
end

function AgentManagerService:destroyAgent()
	for i = #self.arrIdleAgent, 100, -1 do
		local agent = self.arrIdleAgent[i]
		self.arrIdleAgent[i] = nil
		agent:exit()
	end
end

function AgentManagerService:agentDisconnect(fd)
	local agent = self.mapFdAgent[fd]
	if agent then
		self.mapFdAgent[fd] = nil
		agent:active()
		agent:logout()
	end
	return NORET
end

function AgentManagerService:start()
	skynet.start(function()
		skynet.dispatch("lua", function(session, source, cmd, ...)
			local f = self.command[cmd]
			if f ~= nil then
				local res = f(self, ...)
				if res ~= NORET then
					skynet.ret(skynet.pack(res))
				end
			end
		end)

		database.setDbSrvName(".servicedb0")
		gate.initServiceAddr()

		local function releaseDeadAgent()
			local curTime = skynet.time()
			local arrDeadAgent = {}
			local mapWorkingAgent = self.mapWorkingAgent
			local arrIdleAgent = self.arrIdleAgent
			for k, v in pairs(mapWorkingAgent) do
				if v:isDead(curTime) then
					table.insert(arrDeadAgent, k)
				end
			end
			for _, v in ipairs(arrDeadAgent) do
				local agent = mapWorkingAgent[v]
				assert(agent)
				agent:release()
				mapWorkingAgent[v] = nil
				table.insert(arrIdleAgent, agent)
			end
			local i = 0
			for _, _ in pairs(mapWorkingAgent) do
				i = i + 1
			end

			self:destroyAgent()
			log.stdout("working agent amount :", i)
			log.stdout("idle agent amount :", #arrIdleAgent)
			skynet.timeout(6000, releaseDeadAgent)
		end
		skynet.timeout(6000, releaseDeadAgent)
	end)
end

return AgentManagerService
