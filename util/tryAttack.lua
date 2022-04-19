local util = require("util")

local registry = require("registry")

local function tryAttack(world, player, entity, onEntityTile)
	local entityType = registry.entityTypes[entity.typeName]
	local entityEquippedItemType = entity.inventory and entity.inventory.equippedItem and registry.itemTypes[entity.inventory.equippedItem.type]
	local attackTileX, attackTileY
	if onEntityTile then
		attackTileX, attackTileY = entity.x, entity.y
	else
		attackTileX, attackTileY = util.translateByDirection(entity.x, entity.y, entity.direction)
	end
	local attackees = util.getStationaryEntitiesAtTile(world, attackTileX, attackTileY, entity)
	for _, attackee in ipairs(attackees) do
		local attackeeType = registry.entityTypes[attackee.typeName]
		if attackeeType.fruitPlant then
			if attackee.isStump then
				if entityEquippedItemType and entityEquippedItemType.toolType == attackeeType.stumpRemovalToolTypeRequired or not attackeeType.stumpRemovalToolTypeRequired then
					local damage = (entityType.attackDamage or 0) + (entityEquippedItemType.attackDamage or 0)
					attackee.health = math.max(0, attackee.health - damage)
				end
			else
				if entityEquippedItemType and entityEquippedItemType.toolType == attackeeType.toolTypeRequired or not attackeeType.toolTypeRequired then
					local damage = (entityType.attackDamage or 0) + (entityEquippedItemType.attackDamage or 0)
					local dropItems
					if attackeeType.hasStumpForm then
						attackee.health = math.max(attackeeType.stumpFormHealth, attackee.health - damage)
						if attackee.health <= attackeeType.stumpFormHealth then
							attackee.isStump = true
							dropItems = true
						end
					else
						attackee.health = math.max(0, attackee.health - damage)
						dropItems = true
					end
					if dropItems and attackeeType.mainFormDestructionItems then
						local tileInventory = world.tileInventories[attackee.x][attackee.y]
						for _, stack in ipairs(attackeeType.mainFormDestructionItems) do
							util.inventory.give(tileInventory, stack.type, stack.count)
						end
					end
				end
			end
		end
		-- was it destroyed?
		if attackee.health <= 0 then
			world.entities:remove(attackee)
		end
	end
end

return tryAttack
