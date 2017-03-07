local skynet = require "skynet"
require "skynet.manager"

logpath = skynet.getenv("logpath") or ""
tbLogFile = {}

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, address, msg)
		print(string.format("[%s][:%08x]: %s", os.date("%Y-%m-%d %H:%M:%S", math.floor(skynet.time())), address, msg))
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
	skynet.dispatch("lua", function(_, address, fileName, msg)
		if nil == tbLogFile[fileName] then
			print(string.format("[%s][:%08x]: open log file(%s)", os.date("%Y-%m-%d %H:%M:%S", math.floor(skynet.time())), address, logpath .. "/" .. fileName .. ".log"))
			tbLogFile[fileName] = io.open(logpath .. "/" .. fileName .. ".log", "a")
		end
		local file = tbLogFile[fileName]
		local strlog = string.format("[%s][:%08x]: %s", os.date("%Y-%m-%d %H:%M:%S", math.floor(skynet.time())), address, msg)
		if nil ~= file then
			file:write(strlog .. "\n")
			file:flush()
		else
			print(string.format("[%s][:%08x]: open log file(%s) failed!", os.date("%Y-%m-%d %H:%M:%S", math.floor(skynet.time())), address, logpath .. "/" .. fileName .. ".log"))
		end
		print(strlog)
	end)
	skynet.register ".logger"
end)