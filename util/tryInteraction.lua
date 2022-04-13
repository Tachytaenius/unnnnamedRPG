local util = require("util")

local registry = require("registry")

local function tryInteraction(world, entity)
	local interactionTileX, interactionTileY = util.translateByDirection(entity.x, entity.y, entity.direction)
	local interactees = util.getStationaryEntitiesAtTile(world, interactionTileX, interactionTileY, entity)
	for _, interactee in ipairs(interactees) do
		if registry.entityTypes[interactee.typeName].door then
			interactee.open = not interactee.open
		end
	end
end

return tryInteraction
