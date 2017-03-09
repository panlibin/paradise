local skynet = require "skynet"
require "skynet.manager"

local logpath = skynet.getenv("logpath") or ""
local tbLogFile = {}

local function format_log(address, ...)
	return string.format("[%s][:%08x]: " .. string.rep("%s", select("#", ...), " "), os.date("%Y-%m-%d %H:%M:%S", math.floor(skynet.time())), address, ...)
end

local function write_log(address, fileName, ...)
	if nil == tbLogFile[fileName] then
		print(format_log(address, string.format("open log file(%s)!", logpath .. "/" .. fileName .. ".log")))
		tbLogFile[fileName] = io.open(logpath .. "/" .. fileName .. ".log", "a")
	end

	local file = tbLogFile[fileName]
	local strlog = format_log(address, ...)
	if nil ~= file then
		file:write(strlog .. "\n")
		file:flush()
	else
		print(format_log(address, string.format("open log file(%s) failed!", logpath .. "/" .. fileName .. ".log")))
	end
	print(strlog)
end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, address, ...)
		write_log(address, "stderr", ...)
	end
}

skynet.register_protocol {
	name = "SYSTEM",
	id = skynet.PTYPE_SYSTEM,
	unpack = function(...) return ... end,
	dispatch = function()
		-- reopen signal
		print("SIGHUP")
	end
}

skynet.start(function()
	skynet.dispatch("lua", function(_, address, fileName, ...)
		print(fileName)
		write_log(address, fileName, ...)
		skynet.ret()
	end)
	skynet.register ".logger"
end)