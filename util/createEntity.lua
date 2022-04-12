local list = require("lib.list")

local registry = require("registry")
local assets = require("assets")

local function createEntity(world, entity)
	local entityType = registry.entityTypes[entity.typeName]
	entity.type = entityType
	entity.asset = assets.entityTypes[entity.typeName]
	world.entities:add(entity)
	entity.world = world
	if entityType.walkCycleTime then
		entity.nextWalkCycleStartPos = entity.nextWalkCycleStartPos or 0
	end
	if entityType.inventoryCapacity then
		entity.inventory = entity.inventory or list()
		entity.inventory.capacity = entityType.inventoryCapacity
	end
	return entity
end

return createEntity
