local skynet = require("skynet")

local gate = {}
local hAddr = nil

function gate.callOpen(conf)
	return skynet.call(hAddr, "lua", "open" , conf)
end

function gate.callKick(fd)
	return skynet.call(hAddr, "lua", "kick", fd)
end

function gate.callForward(fd, client, target)
	return skynet.call(hAddr, "lua", "forward", fd, client, target)
end

function gate.initServiceAddr()
	hAddr = skynet.uniqueservice("gate")
end

return gate
