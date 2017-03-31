local skynet = require("skynet")
local log = {}
local nDebug = DEBUG

function log.info(fileName, ...)
	skynet.send(".logger", "lua", fileName, ...)
end

function log.debug(fileName, ...)
	if nDebug > 0 then
		skynet.send(".logger", "lua", fileName, ...)
	end
end

function log.stdout(...)
	skynet.send(".logger", "lua", "stdout", ...)
end

function log.stderr(...)
	skynet.send(".logger", "lua", "stderr", ...)
end

return log
