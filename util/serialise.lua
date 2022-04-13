local json = require("lib.json")

local consts = require("consts")

local function serialise(world, player, camera)
	-- backup and remove info that is serialised into other files
	local entities = world.entities
	local tileInventories = world.tileInventories
	local backgroundTiles = world.backgroundTiles
	local foregroundTiles = world.foregroundTiles
	local tileTypesById = world.tileTypesById
	world.entities = nil
	world.tileInventories = nil
	world.backgroundTiles = nil
	world.foregroundTiles = nil
	world.tileTypesById = nil
	-- serialise
	info = json.encode(world)
	-- restore
	world.entities = entities
	world.tileInventories = tileInventories
	world.backgroundTiles = backgroundTiles
	world.foregroundTiles = foregroundTiles
	world.tileTypesById = tileTypesById
	
	if player then player.player = true end
	if camera then camera.camera = true end
	entities = json.encode(entities.objects)
	if player then player.player = nil end
	if camera then camera.camera = nil end
	
	local tileInventoriesToSerialise = {}
	for x = 0, world.tileMapWidth - 1 do
		for y = 0, world.tileMapHeight - 1 do
			local tileInventory = world.tileInventories[x][y]
			if #tileInventory > 0 then
				tileInventoriesToSerialise[#tileInventoriesToSerialise+1] = {x = x, y = y, items = tileInventory}
				tileInventory.capacity = nil -- temporary
			end
		end
	end
	tileInventories = json.encode(tileInventoriesToSerialise)
	for _, tileInventoryEntry in ipairs(tileInventoriesToSerialise) do
		tileInventoryEntry.items.capacity = consts.tileInventoryCapacity
	end
	
	local tileIdsByTileType = {} -- for serialising tile data
	local tileIds = ""
	for i = 0, #tileTypesById do
		tileIds = tileIds .. tileTypesById[i].name .. "\n"
		tileIdsByTileType[tileTypesById[i].name] = i
	end
	
	-- TODO: Those are tile type names, not tile types
	backgroundTileDataTable = {}
	foregroundTileDataTable = {}
	for x = 0, world.tileMapWidth - 1 do
		for y = 0, world.tileMapHeight - 1 do
			backgroundTileDataTable[#backgroundTileDataTable+1] = string.char(tileIdsByTileType[world.backgroundTiles[x][y].name])
			foregroundTileDataTable[#foregroundTileDataTable+1] = string.char(tileIdsByTileType[world.foregroundTiles[x][y].name])
		end
	end
	backgroundTileData = table.concat(backgroundTileDataTable)
	foregroundTileData = table.concat(foregroundTileDataTable)
	
	return info, entities, tileInventories, tileIds, backgroundTileData, foregroundTileData
end

return serialise
