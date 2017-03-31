local CommandDispatcher = class("CommandDispatcher")

function CommandDispatcher:ctor()
	self.mapHandler = {}
end

function CommandDispatcher:setCommandHandler(nCmdType, handler)
	assert(self.mapHandler[nCmdType] == nil)
	assert(nCmdType)
	assert(handler)
	self.mapHandler[nCmdType] = handler
end

function CommandDispatcher:dispatch(nCmdType, ...)
	local f = self.mapHandler[nCmdType]
	assert(f)
	return f(...)
end

return CommandDispatcher
