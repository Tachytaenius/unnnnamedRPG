local util = require("util")

local function save(world, player, camera)
	local info, entities, tileInventories, tileIds, backgroundTileData, foregroundTileData = util.serialise(world, player, camera)
	local path = "scenes/" .. world.location .. "/"
	util.saveDirectory.enable()
	love.filesystem.write(path .. "info.json", info)
	love.filesystem.write(path .. "entities.json", entities)
	love.filesystem.write(path .. "tileInventories.json", tileInventories)
	love.filesystem.write(path .. "tileIds.txt", tileIds)
	love.filesystem.write(path .. "backgroundTileData.bin", backgroundTileData)
	love.filesystem.write(path .. "foregroundTileData.bin", foregroundTileData)
	util.saveDirectory.disable()
end

return save
