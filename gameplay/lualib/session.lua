local socket = require("socket")
local sproto = require("sproto")
local sprotoloader = require("sprotoloader")
local Session = class("Session")

local fnStringPack = string.pack

function Session:ctor(fd, ip, gate, protoidx)
	self.nEncodeIdx = 0
	self.ip = ip
	self.fd = fd
	self.gate = gate
	self.sprotohost = sprotoloader.load(protoidx):host()
	self.sprotopack = self.sprotohost:attach(sprotoloader.load(protoidx))
end

function Session:init(fd, ip, gate, protoidx)
	self.ip = ip
	self.fd = fd
	self.gate = gate
	self.sprotohost = sprotoloader.load(protoidx):host()
	self.sprotopack = self.sprotohost:attach(sprotoloader.load(protoidx))
end

function Session:unpackMessage(msg, sz)
	return self.sprotohost:dispatch(msg, sz)
end

function Session:packMessage(protoname, args)
	return self.sprotopack(protoname, args)
end

function Session:sendMessage(package)
	socket.write(self.fd, fnStringPack(">s2", package))
end

return Session
