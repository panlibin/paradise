local skynet = require "skynet"

function skynet.infoLog(fileName, ...)
	skynet.send(".logger", "lua", fileName, ...)
end

function skynet.debugLog(fileName, ...)
	if DEBUG then
		skynet.send(".logger", "lua", fileName, ...)
	end
end