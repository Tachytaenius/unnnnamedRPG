local util = require("util")
local ui = require("ui")

local registry = require("registry")

local function tryInteraction(world, entity, onEntityTile)
	local entityType = registry.entityTypes[entity.typeName]
	local interactionTileX, interactionTileY
	if onEntityTile then
		interactionTileX, interactionTileY = entity.x, entity.y
	else
		interactionTileX, interactionTileY = util.translateByDirection(entity.x, entity.y, entity.direction)
	end
	local interactees = util.getStationaryEntitiesAtTile(world, interactionTileX, interactionTileY, entity)
	for _, interactee in ipairs(interactees) do
		local interacteeType = registry.entityTypes[interactee.typeName]
		if interacteeType.door then
			if interactee.open then
				if not util.checkCollision(world, interactee.x, interactee.y, interacte) then
					interactee.open = false
				end
			else
				interactee.open = true
			end
		elseif interacteeType.bush then
			if interactee.hasBerries then
				local amountToGet = 1
				local success, error = util.inventory.give(entity.inventory, interacteeType.berryType, amountToGet)
				if success then
					interactee.hasBerries = false
				else
					if error == "notEnoughSpace" then
						ui.textBoxWrapper("Not enough space\nin inventory for\nthe item(s)\n")
					end
				end
			end
		end
	end
end

return tryInteraction
