local skynet = require("skynet")
local agent = require("agentproxy")
local gate = require("gateproxy")
local AgentStub = class("AgentStub")

local AgentState = {
	None = 0,
	Idle = 1,
	Locked = 2,
	Offline = 3,
	Online = 4,
}

function AgentStub:ctor()
	self.addr = nil
	self.uidAccountId = nil
	self.fd = nil
	self.state = AgentState.None
	self.activeTime = skynet.time()
	self.arrWaitingOperation = {}
end

function AgentStub:create()
	if self.state == AgentState.None then
		self.state = AgentState.Locked
		self.addr = skynet.newservice("agent")
		self.state = AgentState.Idle
		return true
	end
	return false
end

function AgentStub:init(uidAccountId)
	if self.state == AgentState.Idle then
		assert(self.addr ~= nil)
		self.state = AgentState.Locked
		self.uidAccountId = uidAccountId
		agent.callInit(self.addr, uidAccountId)
		self.state = AgentState.Offline
		return true
	end
	return false
end

function AgentStub:login(strAccount, fd, ip, nEncodeIdx, nDecodeIdx)
	if self.state == AgentState.Offline then
		assert(self.addr ~= nil)
		self.state = AgentState.Locked
		self.fd = fd
		agent.callLogin(self.addr, strAccount, fd, ip, nEncodeIdx, nDecodeIdx)
		self.state = AgentState.Online
		return true
	end
	return false
end

function AgentStub:logout()
	if self.state == AgentState.Online then
		assert(self.addr ~= nil)
		self.state = AgentState.Locked
		gate.callKick(fd)
		self.fd = nil
		agent.callLogout(self.addr)
		self.state = AgentState.Offline
		return true
	end
	return false
end

function AgentStub:release()
	if self.state == AgentState.Offline then
		self.state = AgentState.Locked
		self.uidAccountId = nil
		self.fd = nil
		agent.callRelease(self.addr)
		self.state = AgentState.Idle
		return true
	end
	return false
end

function AgentStub:exit()
	agent.sendExit(self.addr)
end

function AgentStub:active()
	self.activeTime = skynet.time()
end

function AgentStub:isDead(curTime)
	return self.state == AgentState.Offline and self.activeTime < curTime - 600
end

function AgentStub:isLocked()
	return self.state == AgentState.Locked
end

function AgentStub:isOnline()
	return self.state == AgentState.Online
end

function AgentStub:addWaitingOperation(func)
	table.insert(self.arrWaitingOperation, func)
end

function AgentStub:executeWaitingOperation()
	if next(self.arrWaitingOperation) ~= nil then
		skynet.fork(function()
			for _, v in ipairs(self.arrWaitingOperation) do
				v(true)
			end
			self.arrWaitingOperation = {}
		end)
	end
end

function AgentStub:isWaitingOperationEmpty()
	return next(self.arrWaitingOperation) == nil
end

return AgentStub
