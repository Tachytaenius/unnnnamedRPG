local tableEqual = require("lib.tableEqual")
local deepCopy = require("lib.deepCopy")
local registry = require("registry")

local function metadataEqual(md1, md2)
	if md1 == md2 then
		return true
	end
	if type(md1) == "table" and type(md2) == "table" then
		return tableEqual(md1, md2)
	end
	return false
end

local function getMatchingRecipes(stacks, recipeClassNames)
	local ret = {}
	if #stacks <= 0 then
		return ret
	end
	for _, recipeClassName in ipairs(recipeClassNames) do
		local recipeClass = registry.recipeClasses[recipeClassName]
		if recipeClass then
			for _, recipe in ipairs(recipeClass) do
				-- setup recipe with 0 items met
				local recipeItemMatchingProfile = {}
				-- match items with recipe
				local doesntMatch = false
				for _, stack in ipairs(stacks) do
					local matchesAny = false
					for _, recipeStack in ipairs(recipe.reagents) do
						-- check if it matches (excluding count)
						local matches = recipeStack.type == stack.type and metadataEqual(recipeStack.metadata, stack.metadata)
						if matches then
							matchesAny = true
							recipeItemMatchingProfile[recipeStack] = (recipeItemMatchingProfile[recipeStack] or 0) + stack.count
							break
						end
					end
					if not matchesAny then
						-- if there are stacks that don't match the recipe, then the recipe isn't matched
						doesntMatch = true
						break
					end
				end
				-- if there are reagents that aren't matched in the recipe, then the recipe isn't matched
				for _, recipeStack in ipairs(recipe.reagents) do
					local profile = recipeItemMatchingProfile[recipeStack]
					if not profile or profile <= 0 then
						doesntMatch = true
					end
				end
				if not doesntMatch then
					-- get maximum amount craftable and add to return table if it's >= 1
					local maxAmount
					for recipeStack, count in pairs(recipeItemMatchingProfile) do
						local countThisStack = math.floor(count / recipeStack.count)
						maxAmount = maxAmount and math.min(maxAmount, countThisStack) or countThisStack
					end
					if maxAmount >= 1 then
						ret[#ret+1] = {recipe = recipe, type = recipe.products[1].type, count = recipe.products[1].count, metadata = deepCopy(recipe.products[1].metadata), maxAmount = maxAmount}
					end
				end
			end
		end
	end
	return ret
end

return getMatchingRecipes
