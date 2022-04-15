local registry = require("registry")
local util = require("util")

local inventory = {}

function inventory.getAmount(inv, itemType)
	local total = 0
	for _, stack in ipairs(inv) do
		if not itemType or stack.type == itemType then
			total = total + stack.count * registry.itemTypes[stack.type].size
		end
	end
	return total
end

function inventory.give(inv, itemType, amountToGive)
	assert(amountToGive >= 0, "Can't give negative amount!")
	local currentInventorySize = inventory.getAmount(inv)
	if currentInventorySize + amountToGive * registry.itemTypes[itemType].size > inv.capacity then
		return false, "notEnoughSpace"
	end
	local stackToGiveTo
	for _, stack in ipairs(inv) do
		if stack.type == itemType then
			stackToGiveTo = stack
			break
		end
	end
	if not stackToGiveTo then
		stackToGiveTo = {type = itemType, count = 0}
		inv[#inv+1] = stackToGiveTo
	end
	stackToGiveTo.count = stackToGiveTo.count + amountToGive
	return true
end

function inventory.take(inv, itemType, amountToTake)
	assert(amountToTake >= 0, "Can't take negative amount!")
	local currentAmount = inventory.getAmount(inv, itemType)
	if currentAmount - amountToTake < 0 then
		return false, "notEnoughOfItem"
	end
	local amountTaken = 0
	local i = 1
	while i <= #inv and amountTaken < amountToTake do
		local stack = inv[i] 
		if stack.type == itemType then
			local amountLeftToTake = amountToTake - amountTaken
			local amountTakenThisStack = math.min(amountLeftToTake, stack.count)
			stack.count = stack.count - amountTakenThisStack
			amountTaken = amountTaken + amountTakenThisStack
			if stack.count <= 0 then
				table.remove(inv, i)
			else
				i = i + 1
			end
		else
			i = i + 1
		end
	end
	return true
end

function inventory.takeFromStack(inv, stack, amountToTake)
	local stackIndex = util.getIndex(inv, stack)
	if not stackIndex then
		error("Stack not found in inventory")
	end
	if stack.count < amountToTake then
		return false, "notEnoughOfItem"
	end
	stack.count = stack.count - amountToTake
	if stack.count == 0 then
		table.remove(inv, stackIndex)
	end
	return true
end

return inventory
