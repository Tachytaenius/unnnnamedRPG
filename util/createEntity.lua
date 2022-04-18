local list = require("lib.list")

local registry = require("registry")
local assets = require("assets")

local function createEntity(world, entity)
	local entityType = registry.entityTypes[entity.typeName]
	world.entities:add(entity)
	if entityType.walkCycleTime then
		entity.nextWalkCycleStartPos = entity.nextWalkCycleStartPos or 0
	end
	if entityType.inventoryCapacity then
		entity.inventory = entity.inventory or {}
		entity.inventory.capacity = entityType.inventoryCapacity
		entity.inventory.canEquip = entityType.canEquip
	end
	if entityType.defaultSpriteColour and not entity.spriteColour then
		entity.spriteColour = {
			entityType.defaultSpriteColour[1],
			entityType.defaultSpriteColour[2],
			entityType.defaultSpriteColour[3]
		}
	end
	return entity
end

return createEntity
