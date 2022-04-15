local util = require("util")
local ui = require("ui")

local registry = require("registry")

local function tryInteraction(world, player, camera, entity, onEntityTile)
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
		elseif interacteeType.fruitPlant then
			if interactee.hasFruit then
				local amountToGet = interacteeType.fruitCount
				local success, error = util.inventory.give(entity.inventory, interacteeType.fruitType, amountToGet)
				if success then
					interactee.hasFruit = false
					interactee.fruitGrowthTimer = interacteeType.fruitGrowthTime
				elseif entity == player then
					if error == "notEnoughSpace" then
						local inventorySpace = entity.inventory.capacity - util.inventory.getAmount(entity.inventory)
						local spaceYieldWouldOccupy = amountToGet * registry.itemTypes[interacteeType.fruitType].size
						ui.textBoxWrapper("Not enough space\nin inventory for\nthe item(s), need\n" .. spaceYieldWouldOccupy - inventorySpace .. " more\n")
					end
				end
			end
		end
	end
end

return tryInteraction
