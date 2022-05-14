local util = require("util")
local ui = require("ui")

local registry = require("registry")

local function tryInteraction(world, player, entity, onEntityTile)
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
				if not util.checkCollision(world, interactee.x, interactee.y, interactee) then
					interactee.open = false
				end
			else
				interactee.open = true
			end
		elseif interacteeType.fruitPlant then
			if interactee.hasFruit then
				local amountToGet = interacteeType.fruitCount
				local success, error = util.inventory.give(entity.inventory, interacteeType.fruitType, interacteeType.fruitMetadata, amountToGet)
				if success then
					interactee.hasFruit = false
					interactee.fruitGrowthTimer = interacteeType.fruitGrowthTime
				elseif entity == player then
					if error == "notEnoughSpace" then
						local inventorySpace = entity.inventory.capacity - util.inventory.getCountSize(entity.inventory)
						local spaceYieldWouldOccupy = amountToGet * registry.itemTypes[interacteeType.fruitType].size
						ui.textBoxWrapper("Not enough space\nin inventory for\nthe item(s), need\n" .. spaceYieldWouldOccupy - inventorySpace .. " more\n")
					end
				end
			end
		elseif interacteeType.container and entity == player then
			ui.showTransferringInventories(interactee.inventory, player.inventory, interacteeType.containerDisplayName, "Player")
		elseif interacteeType.crafting and entity == player then
			ui.crafting(entity.inventory, interacteeType.craftingDisplayName, interacteeType.craftingRecipeClasses)
		end
	end
	if #interactees <= 0 then
		if not util.checkCollision(world, interactionTileX, interactionTileY) then
			local equippedItem = entity.inventory and entity.inventory.equippedItem
			if equippedItem then
				local equippedItemType = registry.itemTypes[equippedItem.type]
				local entityTypeNameToCreate = equippedItemType.spawnsEntity
				if entityTypeNameToCreate then
					local ok = false
					if equippedItemType.entitySpawnTiles then
						local tileTypeName = world.backgroundTiles[interactionTileX][interactionTileY].name
						for _, name in ipairs(equippedItemType.entitySpawnTiles) do
							if tileTypeName == name then
								ok = true
								break
							end
						end
					else
						ok = true
					end
					if ok then
						util.inventory.takeFromStack(entity.inventory, equippedItem, 1)
						local direction = (not entity.direction and "down") or entity.direction == "up" and "down" or entity.direction == "down" and "up" or entity.direction == "left" and "right" or entity.direction == "right" and "left"
						local newEntity = {
							typeName = entityTypeNameToCreate,
							direction = direction,
							x = interactionTileX,
							y = interactionTileY
						}
						if equippedItemType.entitySpawnAttributes then
							for k, v in pairs(equippedItemType.entitySpawnAttributes) do
								if type(v) == "table" then error("NYI") end -- TODO (when needed)
								newEntity[k] = v
							end
						end
						util.createEntity(world, newEntity)
					end
				end
			end
		end
	end
end

return tryInteraction
