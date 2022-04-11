local function getStationaryEntitiesAtTile(world, x, y, exclude)
	local ret = {}
	for entity in world.entities:elements() do
		if not entity.moveProgress and entity.x == x and entity.y == y and entity ~= exclude then
			ret[#ret + 1] = entity
		end
	end
	return ret
end

return getStationaryEntitiesAtTile
