local Session = require("session")
local AuthSession = class("AuthSession", Session)

function AuthSession:ctor(...)
	AuthSession.super.ctor(self, ...)
	self.strAccount = nil
end

function AuthSession:init(...)
	AuthSession.super.init(self, ...)
end

function AuthSession:processMsgLogin(_, _, msg)
	self.strAccount = assert(msg.account)
	self:sendMessage(self:packMessage("MsgLoginRet", {errno = 0}))
	return true
end

return AuthSession
