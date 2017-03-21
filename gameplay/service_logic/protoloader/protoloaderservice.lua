local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local ProtoLoaderService = class("ProtoLoaderService")

local inst = nil
function ProtoLoaderService:instance()
	if not inst then
		inst = ProtoLoaderService.new()
	end
	return inst
end

function ProtoLoaderService:ctor()

end

function ProtoLoaderService:start()
	skynet.start(function()
		local file = io.open("./gameplay/proto/login.proto", "r")
		sprotoloader.save(sprotoparser.parse(file:read("*all")), LOGIN_PROTOCOL_INDEX)
		file:close()

		file = io.open("./gameplay/proto/gameplay.proto", "r")
		sprotoloader.save(sprotoparser.parse(file:read("*all")), GAMEPLAY_PROTOCOL_INDEX)
		file:close()
	end)
end

return ProtoLoaderService
