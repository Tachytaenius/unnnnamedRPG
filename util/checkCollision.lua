local registry = require("registry")
local util = require("util")

local function checkCollision(world, x, y, exclude)
	if x < 0 or x >= world.tileMapWidth or y < 0 or y >= world.tileMapHeight then
		return true
	end
	if world.backgroundTiles[x][y].solid then
		return true
	end
	for entity in world.entities:elements() do
		local entityType = registry.entityTypes[entity.typeName]
		if not exclude and (not entityType.fruitPlant and entityType.solid) or (entityType.door and not entity.open) or (entityType.fruitPlant and entityType.solid and not entity.isStump) then
			if entity.x == x and entity.y == y then
				return true
			end
			if entity.moveDirection then
				local ex2, ey2 = util.translateByDirection(entity.x, entity.y, entity.moveDirection)
				if x == ex2 and y == ey2 then
					return true
				end
			end
		end
	end
	return false
end

return checkCollision
