local skynet = require "skynet"

local gate = {}

function gate.forward(gateaddr, fd, client, target)
	skynet.call(gateaddr, "lua", "forward", fd, client, target)
end

return gate
