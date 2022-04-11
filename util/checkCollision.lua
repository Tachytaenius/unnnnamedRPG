local function checkCollision(world, x, y)
	if x < 0 or x >= world.tileMapWidth or y < 0 or y >= world.tileMapHeight then
		return true
	end
	if world.backgroundTiles[x][y].solid then
		return true
	end
	for entity in world.entities:elements() do
		if entity.type.solid or entity.type.door and not entity.open then
			if entity.x == x and entity.y == y then
				return true
			end
			if entity.moveDirection then
				local ex2, ey2 = translateByDirection(entity.x, entity.y, entity.moveDirection)
				if x == ex2 and y == ey2 then
					return true
				end
			end
		end
	end
	return false
end

return checkCollision
