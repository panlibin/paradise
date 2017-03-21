local Session = require "session"
local AuthSession = class("AuthSession", Session)

function AuthSession:ctor(...)
	AuthSession.super.ctor(self, ...)
end

function AuthSession:processMsgLogin(...)
	print("login", ...)
	self:sendMessage(self:packMessage("handshake"))
end

return AuthSession
