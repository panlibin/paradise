local skynet = require "skynet"
require "skynet.manager"
local LoggerService = class("LoggerService")

local inst = nil
function LoggerService.instance()
	if not inst then
		inst = LoggerService.new()
	end
	return inst
end

function LoggerService:ctor()
	self.strLogPath = skynet.getenv("logpath") or "."
	self.mapLogFile = {}
end

function LoggerService:formatLog(address, ...)
	return string.format("[%s][:%08x]: " .. string.rep("%s", select("#", ...), " "), os.date("%Y-%m-%d %H:%M:%S", math.floor(skynet.time())), address, ...)
end

function LoggerService:writeLog(address, fileName, ...)
	if nil == self.mapLogFile[fileName] then
		print(self:formatLog(address, string.format("open log file(%s)!", self.strLogPath .. "/" .. fileName .. ".log")))
		self.mapLogFile[fileName] = io.open(self.strLogPath .. "/" .. fileName .. ".log", "a")
	end

	local file = self.mapLogFile[fileName]
	local strlog = self:formatLog(address, ...)
	if nil ~= file then
		file:write(strlog .. "\n")
		file:flush()
	else
		print(self:formatLog(address, string.format("open log file(%s) failed!", self.strLogPath .. "/" .. fileName .. ".log")))
	end
	print(strlog)
end

function LoggerService:start()
	skynet.register_protocol {
		name = "text",
		id = skynet.PTYPE_TEXT,
		unpack = skynet.tostring,
		dispatch = function(_, address, ...)
			self:writeLog(address, "stderr", ...)
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
			if type(fileName) == "string" and fileName ~= "" then
				self:writeLog(address, fileName, ...)
			else
				self:writeLog(address, "stderr", "invalid file name!")
			end
		end)
		local file = io.open(self.strLogPath)
		if nil == file then
			print(self:formatLog(0, string.format("create log path(%s).", self.strLogPath)))
			os.execute("mkdir "..self.strLogPath)
			file = io.open(self.strLogPath)
			if nil == file then
				print(self:formatLog(0, string.format("create log path(%s) failed!", self.strLogPath)))
				skynet.exit()
			end
		end
		file:close()
		skynet.register ".logger"
	end)
end

return LoggerService