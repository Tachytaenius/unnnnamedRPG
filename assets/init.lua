local json = require("lib.json")

local consts = require("consts")
local registry = require("registry")

local saveDirectory = require("util.saveDirectory")

local assets = {
	entityTypes = {},
	tileTypes = {}
}

local function tryFile(path, itemName, addExtensions)
	-- addExtensions is when trying to see if the asset points to a single file. it is false when doing normal recursive directory traversal
	-- with addExtensions true, itemName is something like "blah" and we are checking for files called "blah.json", "blah.png" etc
	-- with addExtensions false, itemName is the name of a file traverse found, itemName has an extension and we are checking which one it is
	if not addExtensions and not love.filesystem.getInfo(path, "file") then
		return false
	end
	local entryName, newEntry
	local function tryExtension(extension, fileReadingFunction)
		if not (
			addExtensions and love.filesystem.getInfo(path .. "." .. extension, "file") or
			itemName:match("%." .. extension .. "$")
		) then
			return false
		end
		if addExtensions then
			path = path .. "." .. extension
		else
			entryName = itemName:sub(1, -(#extension + 2)) -- remove file extension
		end
		newEntry = fileReadingFunction(path)
	end
	if tryExtension("json", function(path) return json.decode(love.filesystem.read(path)) end) then -- idk it was modified from previous code it doesnt matter if it works and is self-contained
	elseif tryExtension("png", love.graphics.newImage) then
	elseif tryExtension("bin", love.filesystem.read) then
	end
	entryName = tonumber(entryName) or entryName
	return entryName, newEntry
end

local function traverse(table, path)
	for _, itemName in ipairs(love.filesystem.getDirectoryItems(path)) do
		local path = path .. itemName
		if love.filesystem.getInfo(path, "directory") then
			local newTable = {}
			table[itemName] = newTable
			traverse(newTable, path .. "/")
		end
		local entryName, newEntry = tryFile(path, itemName)
		table[entryName] = newEntry
	end
end

function assets.load()
	assets.font = {}
	assets.font.imageData = love.image.newImageData("assets/font/image.png")
	assets.font.info = json.decode(love.filesystem.read("assets/font/info.json"))
	assets.font.font = love.graphics.newImageFont(assets.font.imageData, assets.font.info.glyphs)
	
	for entityTypeName, entityType in pairs(registry.entityTypes) do
		local _, entityAsset = tryFile("assets/entityTypes/" .. entityType.assetPath, entityType.assetPath:match("[^/]+$"), true)
		if not entityAsset then
			entityAsset = {}
			traverse(entityAsset, "assets/entityTypes/" .. entityType.assetPath .. "/")
		end
		assets.entityTypes[entityTypeName] = entityAsset
	end
	
	assert(registry.numTileTypes > 0, "No tile types!")
	local atlasCanvas = love.graphics.newCanvas(consts.tileSize * registry.numTileTypes, consts.tileSize)
	love.graphics.setCanvas(atlasCanvas)
	local i = 0
	for tileName, tile in pairs(registry.tileTypes) do
		local _, tileAsset = tryFile("assets/tileTypes/" .. tile.assetPath, tile.assetPath:match("[^/]+$"), true)
		local imageForAtlas
		if tileAsset then
			imageForAtlas = tileAsset
		else
			tileAsset = {}
			traverse(tileAsset, tile.assetPath .. "/")
			imageForAtlas = tileAsset[0]
		end
		assets.tileTypes[tileName] = tileAsset
		love.graphics.draw(imageForAtlas, consts.tileSize * i, 0)
		i = i + 1
	end
	love.graphics.setCanvas()
	saveDirectory:enable()
	atlasCanvas:newImageData():encode("png", "exportedTileAtlas.png")
	saveDirectory:disable()
end

return assets
