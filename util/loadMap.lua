local json = require("lib.json")
local list = require("lib.list")

local consts = require("consts")
local registry = require("registry")
local util = require("util")

local csvToBin = require("util.csvToBin")

local function loadMap(saveFileName, location)
	util.saveDirectory.enable()
	local path = "saves/" .. saveFileName .. "/scenes/" .. location .. "/"
	local world, player
	world = {}
	
	-- info.json
	local infoJson = love.filesystem.read(path .. "info.json")
	if not infoJson then
		util.saveDirectory.disable()
		path = "assets/defaultScenes/" .. location .. "/"
		infoJson = love.filesystem.read(path .. "info.json")
	end
	local world = json.decode(infoJson)
	world.tint = world.tint or {1, 1, 1}
	assert(world.location, "info.json for scene " .. location .. " is missing location field")
	assert(location == world.location, "info.json for scene " .. location .. " is " .. world.location)
	
	-- tileInventories.json
	world.tileInventories = {} -- for dropped items
	for x = 0, world.tileMapWidth - 1 do
		world.tileInventories[x] = {}
		for y = 0, world.tileMapHeight - 1 do
			world.tileInventories[x][y] = {capacity = consts.tileInventoryCapacity}
		end
	end
	local tileInventories = json.decode(love.filesystem.read(path .. "tileInventories.json"))
	for _, tileInventoryEntry in ipairs(tileInventories) do
		local tileInventory = tileInventoryEntry.items -- json limitations
		world.tileInventories[tileInventoryEntry.x][tileInventoryEntry.y] = tileInventory
		tileInventory.capacity = consts.tileInventoryCapacity
	end
	
	-- entities.json
	local entitiesJson = json.decode(love.filesystem.read(path .. "entities.json"))
	world.entities = list()
	for _, entity in ipairs(entitiesJson) do
		if entity.player then
			-- extendable for multiplayer
			player = entity
			entity.player = nil
		end
		if entity.inventory then
			local capacity = entity.inventory.capacity
			local equippedItem = entity.inventory.items[entity.inventory.equippedItemIndex]
			local canEquip = entity.inventory.canEquip
			entity.inventory = entity.inventory.items
			entity.inventory.capacity = capacity
			entity.inventory.equippedItem = equippedItem
			entity.inventory.canEquip = canEquip
		end
		util.createEntity(world, entity)
	end
	
	-- tileIds.txt
	local tileTypesById = {}
	local i = 0
	for name in love.filesystem.lines(path .. "tileIds.txt") do
		tileTypesById[i] = registry.tileTypes[name] or "dummy"
		i = i + 1
	end
	world.tileTypesById = tileTypesById
	
	-- background/foregroundTileData.bin (or csv)
	local function loadTileData(name)
		local layerTableName = name .. "Tiles"
		world[layerTableName] = {}
		local tileDataString = love.filesystem.read(path .. name .. "TileData.bin")
		if not tileDataString then
			tileDataString = csvToBin(love.filesystem.read(path .. name .. "TileData.csv"))
		end
		for x = 0, world.tileMapWidth - 1 do
			world[layerTableName][x] = {}
			for y = 0, world.tileMapHeight - 1 do
				local i = x + world.tileMapWidth * y
				local tile = tileTypesById[tileDataString:sub(i+1, i+1):byte()]
				world[layerTableName][x][y] = tile
			end
		end
	end
	loadTileData("background", false)
	loadTileData("foreground", false)
	
	-- warps.json
	world.warps = json.decode(love.filesystem.read(path .. "warps.json"))
	
	util.saveDirectory.disable()
	return world, player
end

return loadMap
