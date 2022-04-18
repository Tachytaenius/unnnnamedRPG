local tableEquals = require("lib.tableEquals")
local registry = require("registry")

local function getMatchingRecipes(stacks, recipeClassNames)
	local ret = {}
	if #stacks <= 0 then
		return ret
	end
	for _, recipeClassName in ipairs(recipeClassNames) do
		local recipeClass = registry.recipeClasses[recipeClassName]
		for _, recipe in ipairs(recipeClass) do
			-- setup recipe with 0 items met
			local recipeItemMatchingProfile = {}
			-- match items with recipe
			local doesntMatch = false
			for _, stack in ipairs(stacks) do
				local matchesAny = false
				for _, recipeStack in ipairs(recipe.reagents) do
					-- check if it matches (excluding count)
					local recipeStackCount, stackCount = recipeStack.count, stack.count
					recipeStack.count, stack.count = nil, nil
					local matches = tableEquals(stack, recipeStack)
					recipeStack.count, stack.count = recipeStackCount, stackCount
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
			if not doesntMatch then
				-- get maximum amount craftable and add to return table if it's >= 1
				local maxAmount
				for recipeStack, count in pairs(recipeItemMatchingProfile) do
					local countThisStack = math.floor(count / recipeStack.count)
					maxAmount = maxAmount and math.min(maxAmount, countThisStack) or countThisStack
				end
				if maxAmount >= 1 then
					ret[#ret+1] = {recipe = recipe, maxAmount = maxAmount}
				end
			end
		end
	end
	return ret
end

return getMatchingRecipes
