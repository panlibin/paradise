local skynet = require("skynet")
local log = require("loggerproxy")
local Session = require("session")
local MessageDispatcher = require("agent.messagedispatcher")
local CharacterManager = require("agent.character.charactermanager")
local Player = class("Player")

local getAccountIdByCharacterId = getAccountIdByCharacterId

local inst = nil
function Player.instance()
	if not inst then
		inst = Player.new()
	end
	return inst
end

function Player:ctor()
	self.session = Session.new()
	self.uidAccountId = nil
	self.strAccount = nil
	self.messagedispatcher = MessageDispatcher.instance()
	self.charactermanager = CharacterManager.instance()

	skynet.register_protocol {
		name = "text",
		id = skynet.PTYPE_TEXT,
		pack = skynet.pack,
		unpack = skynet.unpack,
		dispatch = function (_, _, uidCharacterId, ...)
			if self:isCharacterOwner(uidCharacterId) then
				self.charactermanager:dispatch(uidCharacterId, ...)
			end
		end
	}

	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = function (msg, sz)
			return self.session:unpackMessage(msg, sz)
		end,
		dispatch = function (_, _, _, msgName, args)
			log.debug("recvmessage", msgName, dump(args))
			if msgName then
				self.messagedispatcher:dispatchEvent({name = msgName, msg = args})
			end
		end
	}
end

function Player:init(uidAccountId)
	self.uidAccountId = uidAccountId
end

function Player:login(strAccount, fd, ip, nEncodeIdx, nDecodeIdx)
	self.strAccount = strAccount
	self.session:init(fd, ip, GAMEPLAY_PROTOCOL_INDEX, nEncodeIdx, nDecodeIdx)
end

function Player:logout()
	self.session:release()
end

function Player:release()
	self.uidAccountId = nil
	self.strAccount = nil
end

function Player:sendMessage(strProtoName, args)
	self.session:sendMessage(self.session:packMessage(strProtoName, args))
end

function Player:isCharacterOwner(uidCharacterId)
	return self.uidAccountId and self.uidAccountId == getAccountIdByCharacterId(uidCharacterId)
end

return Player
