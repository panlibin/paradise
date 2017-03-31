local skynet = require("skynet")

local agentmanager = {}

local hAddr = nil

function agentmanager.callCreateAgent(strAccount, fd, ip, nEncodeIdx, nDecodeIdx)
	return skynet.call(hAddr, "lua", "createagent", strAccount, fd, ip, nEncodeIdx, nDecodeIdx)
end

function agentmanager.callGetAgent(uidCharacterId)
	return skynet.call(hAddr, "lua", "getagent", uidCharacterId)
end

function agentmanager.sendDisconnect(fd)
	skynet.send(hAddr, "lua", "disconnect", fd)
end

function agentmanager.initServiceAddr()
	hAddr = skynet.uniqueservice("agentmanager")
end

return agentmanager
