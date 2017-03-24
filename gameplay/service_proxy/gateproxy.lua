local skynet = require("skynet")

local gate = {}

function gate.callForward(gateaddr, fd, client, target)
	return skynet.call(gateaddr, "lua", "forward", fd, client, target)
end

return gate
