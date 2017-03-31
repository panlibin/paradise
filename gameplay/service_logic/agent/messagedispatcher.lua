local MessageDispatcher = class("MessageDispatcher")

local inst = nil
function MessageDispatcher.instance()
	if not inst then
		inst = MessageDispatcher.new()
	end
	return inst
end

function MessageDispatcher:ctor()
	GameObject.extend(self):addComponent("components.behavior.EventProtocol"):exportMethods()
end

return MessageDispatcher
