local util = require("util")
local ui = require("ui")

local registry = require("registry")

local function tryRotateFurniture(world, player, entity, onEntityTile)
	local entityType = registry.entityTypes[entity.typeName]
	local rotationTileX, rotationTileY
	if onEntityTile then
		rotationTileX, rotationTileY = entity.x, entity.y
	else
		rotationTileX, rotationTileY = util.translateByDirection(entity.x, entity.y, entity.direction)
	end
	local rotatees = util.getStationaryEntitiesAtTile(world, rotationTileX, rotationTileY, entity)
	for _, rotatee in ipairs(rotatees) do
		local rotateeType = registry.entityTypes[rotatee.typeName]
		if rotateeType.hasDirection and rotateeType.canBeRotated then
			rotatee.direction = rotatee.direction == "up" and "right" or rotatee.direction == "right" and "down" or rotatee.direction == "down" and "left" or rotatee.direction == "left" and "up"
		end
	end
end

return tryRotateFurniture
