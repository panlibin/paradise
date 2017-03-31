local skynet = require("skynet")

local agent = {}

function agent.callInit(hAgentAddr, uidAccountId)
	return skynet.call(hAgentAddr, "lua", "init", uidAccountId)
end

function agent.callLogin(hAgentAddr, strAccount, fd, ip, nEncodeIdx, nDecodeIdx)
	return skynet.call(hAgentAddr, "lua", "login", strAccount, fd, ip, nEncodeIdx, nDecodeIdx)
end

function agent.callLogout(hAgentAddr)
	return skynet.call(hAgentAddr, "lua", "logout")
end

function agent.callRelease()
	return skynet.call(hAgentAddr, "lua", "release")
end

function agent.sendExit()
	skynet.send(hAgentAddr, "lua", "exit")
end

return agent
