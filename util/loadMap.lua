local json = require("lib.json")
local list = require("lib.list")

local consts = require("consts")
local registry = require("registry")
local util = require("util")

local csvToBin = require("util.csvToBin")

local function loadMap(path)
	path = "assets/scenes/" .. path .. "/"
	local world, player, camera
	world = {}
	
	-- info.json
	local world = json.decode(love.filesystem.read(path .. "info.json"))
	world.tint = world.tint or {1, 1, 1}
	
	-- entities.json
	local entitiesJson = json.decode(love.filesystem.read(path .. "entities.json"))
	world.entities = list()
	for _, entity in ipairs(entitiesJson) do
		if entity.player then
			-- extendable for multiplayer
			player = entity
			entity.player = nil
		end
		if entity.camera then
			camera = entity
			entity.camera = nil
		end
		util.createEntity(world, entity)
	end
	
	-- tileIds.txt
	local tileTypesById = {}
	local i = 0
	for name in love.filesystem.lines(path .. "tileIds.txt") do
		tileTypesById[i] = registry.tileTypes[name]
		assert(tileTypesById[i], "Unknown tile type name " .. i .. " " .. name)
		i = i + 1
	end
	
	-- background/foregroundTileData.bin (or csv)
	local function loadTileData(name, colliders)
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
		
	return world, player, camera
end

return loadMap
