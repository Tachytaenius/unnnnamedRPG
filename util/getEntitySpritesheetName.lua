local registry = require("registry")
local assets = require("assets")

local function getEntitySpritesheetName(entity)
	local entityAsset = assets.entityTypes[entity.typeName]
	if registry.entityTypes[entity.typeName].door then
		return entity.open and entityAsset.info.openSpritesheetName or entityAsset.info.closedSpritesheetName
	elseif registry.entityTypes[entity.typeName].fruitPlant then
		return entity.hasFruit and entityAsset.info.withFruitSpritesheetName or entityAsset.info.withoutFruitSpritesheetName
	end
	return entityAsset.info.defaultSpritesheetName
end

return getEntitySpritesheetName
