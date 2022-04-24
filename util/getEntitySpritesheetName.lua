local registry = require("registry")
local assets = require("assets")
local util = require("util")

local function getEntitySpritesheetName(entity)
	local entityAsset = assets.entityTypes[entity.typeName]
	local entityType = registry.entityTypes[entity.typeName]
	if entityType.door then
		return entity.open and entityAsset.info.openSpritesheetName or entityAsset.info.closedSpritesheetName
	elseif entityType.fruitPlant then
		return entity.seedling and entityAsset.info.seedlingSpritesheetName or entity.stump and entityAsset.info.stumpSpritesheetName or entity.hasFruit and entityAsset.info.withFruitSpritesheetName or entityAsset.info.withoutFruitSpritesheetName
	elseif entityType.producerProductFarm then
		local spritesheetNameTable
		local hasProducer = entity.inventory and util.inventory.getCount(entity.inventory, entityType.producer) > 0
		local spritesheetNameTable = hasProducer and entityAsset.info.withProducerSpritesheetNames or entityAsset.info.withoutProducerSpritesheetNames
		local hasProduct = entity.inventory and util.inventory.getCount(entity.inventory, entityType.product) > 0
		return hasProduct and spritesheetNameTable.withProduct or spritesheetNameTable.withoutProduct
	end
	return entityAsset.info.defaultSpritesheetName
end

return getEntitySpritesheetName
