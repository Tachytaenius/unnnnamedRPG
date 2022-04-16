local util = require("util")

local function save(saveFileName, world, player)
	local info, entities, tileInventories, tileIds, backgroundTileData, foregroundTileData, warps = util.serialise(world, player)
	util.saveDirectory.enable()
	local path = "saves/" .. saveFileName .. "/"
	love.filesystem.write(path .. "playerLocation.txt", world.location)
	local path = path .. "scenes/" .. world.location .. "/"
	if not love.filesystem.getInfo(path) then
		love.filesystem.createDirectory(path)
	end
	love.filesystem.write(path .. "info.json", info)
	love.filesystem.write(path .. "entities.json", entities)
	love.filesystem.write(path .. "tileInventories.json", tileInventories)
	love.filesystem.write(path .. "tileIds.txt", tileIds)
	love.filesystem.write(path .. "backgroundTileData.bin", backgroundTileData)
	love.filesystem.write(path .. "foregroundTileData.bin", foregroundTileData)
	love.filesystem.write(path .. "warps.json", warps)
	util.saveDirectory.disable()
end

return save
