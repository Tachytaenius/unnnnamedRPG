local json = require("lib.json")

local registry = {
	entityTypes = {},
	tileTypes = {}, numTileTypes = 0,
	itemTypes = {},
	recipes = {}, recipeClasses = {}
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
				local entry = createFromJson(jsonData, path, entryName)
				entry.assetPath = path:sub(#registryPathPrefixLength + 1, -6) -- remove registryPathPrefixLength and .json
				entry.name = entryName
				registryTable[entryName] = entry
			end
		end
	end
end

local function createEntityType(jsonData, path, entryName)
	return jsonData
end

local function createTileType(jsonData, path, entryName)
	assert(entryName ~= "dummy", "dummy is a reserved tile type name")
	registry.numTileTypes = registry.numTileTypes + 1
	return jsonData
end

local function createItemType(jsonData, path, entryName)
	return jsonData
end

local function createRecipe(jsonData, path, entryName)
	assert(#jsonData.reagents > 0, "Recipe " .. path .. " must have at least one reagent")
	for i, stack in ipairs(jsonData.reagents) do
		assert(stack.count > 0, "Stack " .. i .. " in recipe " .. path .. " must have a count greater than 0")
	end
	
	local classTable = registry.recipeClasses[jsonData.class]
	if not classTable then
		classTable = {}
		registry.recipeClasses[jsonData.class] = classTable
	end
	classTable[#classTable+1] = jsonData
	
	return jsonData
end

traverse(registry.entityTypes, "registry/entityTypes/", createEntityType)
traverse(registry.tileTypes, "registry/tileTypes/", createTileType)
traverse(registry.itemTypes, "registry/itemTypes/", createItemType)
traverse(registry.recipes, "registry/recipes/", createRecipe)

return registry
