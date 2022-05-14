local tableEqual = require("lib.tableEqual")
local deepCopy = require("lib.deepCopy")
local registry = require("registry")
local util = require("util")

local function metadataEqual(md1, md2)
	if md1 == md2 then
		return true
	end
	if type(md1) == "table" and type(md2) == "table" then
		return tableEqual(md1, md2)
	end
	return false
end

local inventory = {}

function inventory.getCountSize(inv, itemType, itemMetadata)
	local total = 0
	for _, stack in ipairs(inv) do
		if not itemType or stack.type == itemType and metadataEqual(stack.metadata, itemMetadata) then
			total = total + stack.count * registry.itemTypes[stack.type].size
		end
	end
	return total
end

function inventory.getCount(inv, itemType, itemMetadata)
	local total = 0
	for _, stack in ipairs(inv) do
		if not itemType or stack.type == itemType and metadataEqual(stack.metadata, itemMetadata) then
			total = total + stack.count
		end
	end
	return total
end

function inventory.give(inv, itemType, metadata, amountToGive, allowOverCapacity)
	assert(amountToGive >= 0, "Can't give negative amount!")
	local currentInventorySize = inventory.getCountSize(inv, metadata)
	if not allowOverCapacity then
		if currentInventorySize + amountToGive * registry.itemTypes[itemType].size > inv.capacity then
			return false, "notEnoughSpace"
		end
	end
	local stackToGiveTo
	for _, stack in ipairs(inv) do
		if stack.type == itemType and metadataEqual(stack.metadata, metadata) then
			stackToGiveTo = stack
			break
		end
	end
	if not stackToGiveTo then
		stackToGiveTo = {type = itemType, count = 0, metadata = deepCopy(metadata)}
		inv[#inv+1] = stackToGiveTo
	end
	stackToGiveTo.count = stackToGiveTo.count + amountToGive
	return true
end

function inventory.take(inv, itemType, metadata, amountToTake)
	assert(amountToTake >= 0, "Can't take negative amount!")
	local currentAmount = inventory.getCount(inv, itemType, metadata)
	if currentAmount - amountToTake < 0 then
		return false, "notEnoughOfItem"
	end
	local amountTaken = 0
	local i = 1
	while i <= #inv and amountTaken < amountToTake do
		local stack = inv[i] 
		if stack.type == itemType and metadataEqual(stack.metadata, metadata) then
			local amountLeftToTake = amountToTake - amountTaken
			local amountTakenThisStack = math.min(amountLeftToTake, stack.count)
			stack.count = stack.count - amountTakenThisStack
			amountTaken = amountTaken + amountTakenThisStack
			if stack.count <= 0 then
				table.remove(inv, i)
				if stack == inv.equippedItem then
					inv.equippedItem = nil
				end
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
		if stack == inv.equippedItem then
			inv.equippedItem = nil
		end
	end
	return true
end

return inventory
