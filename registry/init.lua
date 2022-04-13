local json = require("lib.json")

local registry = {
	entityTypes = {},
	tileTypes = {}, numTileTypes = 0,
	itemTypes = {}
}

local function traverse(registryTable, path, createFromJson, registryPathPrefixLength)
	registryPathPrefixLength = registryPathPrefixLength or path
	for _, itemName in ipairs(love.filesystem.getDirectoryItems(path)) do
		local path = path .. itemName
		if love.filesystem.getInfo(path, "directory") then
			traverse(registryTable, path .. "/", createFromJson, registryPathPrefixLength)
		elseif love.filesystem.getInfo(path, "file") then
			if itemName:match("%.json$") then
				local entryName = itemName:sub(1, -6) -- remove .json
				local jsonData = json.decode(love.filesystem.read(path))
				local entry = createFromJson(jsonData, path)
				entry.assetPath = path:sub(#registryPathPrefixLength + 1, -6) -- remove registryPathPrefixLength and .json
				entry.name = entryName
				registryTable[entryName] = entry
			end
		end
	end
end

local function createEntityType(jsonData, path)
	return jsonData
end

local function createTileType(jsonData, path)
	registry.numTileTypes = registry.numTileTypes + 1
	return jsonData
end

local function createItemType(jsonData, path)
	return jsonData
end

traverse(registry.entityTypes, "registry/entityTypes/", createEntityType)
traverse(registry.tileTypes, "registry/tileTypes/", createTileType)
traverse(registry.itemTypes, "registry/itemTypes/", createItemType)

return registry
