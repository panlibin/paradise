local CharacterManager = class("CharacterManager")

local inst = nil
function CharacterManager.instance()
	if not inst then
		inst = CharacterManager.new()
	end
	return inst
end

function CharacterManager:ctor()
	self.mapCharacter = {}
end

function CharacterManager:createCharacter()
	-- body
end

function CharacterManager:destroyCharacter()
	-- body
end

function CharacterManager:loadCharacter()
	-- body
end

function CharacterManager:unloadCharacter()
	-- body
end

function CharacterManager:getCharacterList()
	-- body
end

return CharacterManager
