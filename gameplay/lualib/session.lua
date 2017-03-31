local socket = require("socket")
local sproto = require("sproto")
local sprotoloader = require("sprotoloader")
local Session = class("Session")

local fnStringPack = string.pack

function Session:ctor()
	self.ip = nil
	self.fd = nil
	self.sprotohost = nil
	self.sprotopack = nil
	self.nEncodeIdx = 0
	self.nDecodeIdx = 0
end

function Session:init(fd, ip, protoidx, nEncodeIdx, nDecodeIdx)
	self.ip = ip
	self.fd = fd
	self.sprotohost = sprotoloader.load(protoidx):host()
	self.sprotopack = self.sprotohost:attach(sprotoloader.load(protoidx))
	self.nEncodeIdx = nEncodeIdx
	self.nDecodeIdx = nDecodeIdx
end

function Session:unpackMessage(msg, sz)
	if self.sprotohost then
		return self.sprotohost:dispatch(msg, sz)
	end
end

function Session:packMessage(protoname, args)
	if self.sprotopack then
		return self.sprotopack(protoname, args)
	end
end

function Session:sendMessage(package)
	if self.fd then
		socket.write(self.fd, fnStringPack(">s2", package))
	end
end

function Session:release()
	self.ip = nil
	self.fd = nil
	self.sprotohost = nil
	self.sprotopack = nil
	self.nEncodeIdx = 0
	self.nDecodeIdx = 0
end

return Session
