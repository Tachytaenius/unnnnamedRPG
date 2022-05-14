local list = require("lib.list")

local registry = require("registry")
local settings = require("settings")
local consts = require("consts")
local assets = require("assets")
local util = require("util")

local ui = {}

function ui.clear()
	ui.focusedWindow = nil
	ui.windows = {}
end

function ui.active()
	local active = false
	for _, window in ipairs(ui.windows) do
		if window.active then
			active = true
			break
		end
	end
	return active
end

function ui.cancelAll()
	-- if can't cancel then return false end
	local i = 1
	while i <= #ui.windows do
		local window = ui.windows[i]
		if window.active then
			table.remove(ui.windows, i)
			if window == ui.focusedWindow then
				ui.focusedWindow = nil
			end
		else
			i = i + 1
		end
	end
	return true
end

function ui.cancelFocused()
	-- cancels focused
	-- if can't cancel then return false end
	if ui.focusedWindow then
		table.remove(ui.windows, util.getIndex(ui.windows, ui.focusedWindow))
		ui.focusedWindow = ui.focusedWindow.windowToFocusWhenDismissed or nil
	end
	return true
end

function ui.inventory(inventory, displayName, selectionFunction)
	local window = {}
	ui.windows[#ui.windows+1] = window
	window.selectionFunction = selectionFunction
	window.type = "inventory"
	window.items = inventory
	window.displayName = displayName
	window.active = true
	window.cursor = 1
	window.extraSlotsOffset = 8
	window.viewOffset = 0
	window.x, window.y = 80, 48
	window.width, window.height = 208, 176
	return window
end

function ui.showEntityInventory(entity, displayName)
	if not entity.inventory then return end
	ui.focusedWindow = ui.inventory(entity.inventory, displayName)
end

function ui.showTransferringInventories(inventoryA, inventoryB, displayNameA, displayNameB)
	local window
	window = ui.inventory(inventoryA, displayNameA, function(self)
		if #self.items <= 0 then return end
		local selectedStack = self.items[self.cursor]
		local amountToTransfer = 1
		local inventoryAmount = util.inventory.getCountSize(self.otherItems)
		local stackSize = registry.itemTypes[selectedStack.type].size
		if inventoryAmount + amountToTransfer * stackSize <= self.otherItems.capacity then
			local success, error = util.inventory.takeFromStack(self.items, selectedStack, amountToTransfer)
			if success then
				if selectedStack == self.items.equippedItem and selectedStack.count <= 0 then
					self.items.equippedItem = nil
				end
				util.inventory.give(self.otherItems, selectedStack.type, selectedStack.metadata, amountToTransfer)
			else
				ui.textBoxWrapper("Not enough of item to transfer")
			end
		else
			ui.textBoxWrapper("Not enough space\nin other inventory\n(" .. window.otherDisplayName .. ") to transfer,\nneed " .. stackSize - (self.otherItems.capacity - inventoryAmount) .. " more\n")
		end
	end)
	ui.focusedWindow = window
	window.type = "transferInventories"
	window.otherItems = inventoryB
	window.otherDisplayName = displayNameB
	window.swapped = false
end

function ui.crafting(inventory, displayName, classes)
	local window = ui.inventory(inventory, displayName, function(self)
		if #self.items <= 0 then return end
		local item = self.items[self.cursor]
		if item == self.items.equippedItem then return end
		self.selectedItems[item] = not self.selectedItems[item] or nil
	end)
	ui.focusedWindow = window
	window.type = "crafting"
	window.selectedItems = {}
	window.classes = classes
end

function ui.craftingChoiceMenu(getMatchingRecipesOutput, inventoryToGiveTo, displayName)
	local window = ui.inventory(getMatchingRecipesOutput, displayName, function(self)
		local item = self.items[self.cursor]
		ui.howManyMenu(self, item.maxAmount, registry.itemTypes[item.type].size)
	end)
	ui.focusedWindow = window
	window.type = "craftingChoiceMenu"
	window.inventoryToGiveTo = inventoryToGiveTo
end

function ui.howManyMenu(windowToSendTo, maxAmount, sizeOfSingle)
	local window = {}
	ui.windows[#ui.windows+1] = window
	window.sizeOfSingle = sizeOfSingle
	window.windowToFocusWhenDismissed = ui.focusedWindow
	window.windowToSendTo = windowToSendTo
	window.maxAmount = maxAmount
	window.amount = 1
	window.type = "howMany"
	window.text = "How many?"
	window.textX, window.textY = 0, 0
	local textWidth = assets.font.font:getWidth(window.text)
	local textHeight = 32
	local windowX, windowY = (consts.contentWidth - textWidth) / 2, (consts.contentHeight - textHeight) / 2
	window.x, window.y, window.width, window.height = math.floor(windowX), math.floor(windowY), math.ceil(textWidth+1), math.ceil(textHeight+1)
	ui.focusedWindow = window
end

function ui.textBox(text, x, y, tx, ty, width, height)
	local window = {}
	ui.windows[#ui.windows+1] = window
	window.x, window.y = x, y
	window.width, window.height = width, height
	window.type = "textBox"
	window.active = true
	window.text = text
	window.textX, window.textY = tx, ty
	window.windowToFocusWhenDismissed = ui.focusedWindow
	return window
end

function ui.textBoxWrapper(text)
	local textWidth = assets.font.font:getWidth(text)
	local endlineCount = select(2, text:gsub("\n", "\n"))
	if endlineCount == 0 then endlineCount = 1 end
	local textHeight = assets.font.font:getHeight() * endlineCount
	local windowX, windowY = (consts.contentWidth - textWidth) / 2, (consts.contentHeight - textHeight) / 2
	ui.focusedWindow = ui.textBox(text, math.floor(windowX), math.floor(windowY), 0, 0, math.ceil(textWidth+1), math.ceil(textHeight+1))
end

function ui.statusWindow(entity, x, y, w, h)
	local window = {}
	ui.windows[#ui.windows+1] = window
	window.x, window.y = x, y
	window.width, window.height = w, h
	window.entity = entity
	window.type = "status"
	window.active = false
	window.textX, window.textY = 0, 0
	window.dontDarken = true
	return window
end

function ui.update(dt, world, player, commandDone)
	-- Only allow commands to be registered once per frame
	local commandDoneCopy = {}
	for k, v in pairs(commandDone) do
		commandDoneCopy[k] = v
	end
	local commandDoneCopyUsed = {}
	local uiCommandDone = {} -- empty so that __index will work
	setmetatable(uiCommandDone, {__index = function(uiCommandDone, command)
		if commandDoneCopyUsed[command] then
			return nil
		end
		commandDoneCopyUsed[command] = true
		return rawget(commandDoneCopy, command)
	end})
	
	-- try opening inventory
	if not ui.active() then
		if player.moveProgress == nil and world.tileInventories[player.x] and world.tileInventories[player.x][player.y] then
			if uiCommandDone.openInventory then
				ui.showTransferringInventories(player.inventory, world.tileInventories[player.x][player.y], "Player", "Ground")
			elseif uiCommandDone.openCrafting then
				-- (function() return uiCommandDone.craft end)() -- HACK: disable crafting on same frame -- not needed because without anything selected it doesn't do anything
				ui.crafting(player.inventory, "Crafting", {"hands"})
			end
		end
	end
	
	-- try closing
	if ui.focusedWindow and (ui.focusedWindow.type == "inventory" or ui.focusedWindow.type == "transferInventories" or ui.focusedWindow.type == "crafting" or ui.focusedWindow.type == "craftingChoiceMenu") and (uiCommandDone.openInventory or uiCommandDone.cancel) then
		ui.cancelFocused()
	end
	if ui.focusedWindow and ui.focusedWindow.type == "textBox" then
		if uiCommandDone.cancel or uiCommandDone.confirm then
			ui.cancelFocused()
		end
	end
	if ui.focusedWindow and ui.focusedWindow.type == "howMany" then
		if uiCommandDone.selectLeft then
			ui.focusedWindow.amount = math.max(1, ui.focusedWindow.amount - 1)
		end
		if uiCommandDone.selectRight then
			ui.focusedWindow.amount = math.min(ui.focusedWindow.maxAmount, ui.focusedWindow.amount + 1)
		end
		if uiCommandDone.confirm then
			ui.focusedWindow.windowToSendTo.howManyResult = ui.focusedWindow.amount
			ui.cancelFocused()
		elseif uiCommandDone.cancel then
			ui.focusedWindow.windowToSendTo.howManyResult = nil
			ui.cancelFocused()
		end
	end
	
	for _, window in ipairs(ui.windows) do
		if window.type == "craftingChoiceMenu" then
			if window.howManyResult then
				local howManyResult = window.howManyResult
				window.howManyResult = nil
				-- try giving the items
				local item = window.items[window.cursor]
				local spaceRemaining = window.inventoryToGiveTo.capacity - util.inventory.getCountSize(window.inventoryToGiveTo)
				local spaceFreedByReagentsGone = 0
				for _, reagentStack in ipairs(item.recipe.reagents) do
					spaceFreedByReagentsGone = spaceFreedByReagentsGone + registry.itemTypes[reagentStack.type].size * reagentStack.count * howManyResult
				end
				local spaceTakenUpByProducts = 0
				for _, product in ipairs(item.recipe) do
					spaceTakenUpByProducts = spaceTakenUpByProducts + registry.itemTypes[product.type].size * product.count * howManyResult
				end
				local finalSpace = spaceRemaining + spaceFreedByReagentsGone - spaceTakenUpByProducts
				if finalSpace < 0 then
					ui.textBoxWrapper("Not enough space\nin inventory for\nproducts, need " .. -finalSpace .. " more\n")
				else
					local recipe = item.recipe
					-- take from the right stacks in the right order
					local selectedItemsArray = {}
					for stack in pairs(window.selectedItems) do
						selectedItemsArray[#selectedItemsArray + 1] = stack
					end
					table.sort(selectedItemsArray, function(a, b)
						return util.getIndex(window.inventoryToGiveTo, a) < util.getIndex(window.inventoryToGiveTo, b)
					end)
					for _, reagent in ipairs(recipe.reagents) do
						local amountNeeded = reagent.count * howManyResult
						for _, stack in ipairs(selectedItemsArray) do
							if stack.type == reagent.type then
								local amountToTake = math.min(stack.count, amountNeeded)
								util.inventory.takeFromStack(window.inventoryToGiveTo, stack, amountToTake)
								amountNeeded = amountNeeded - amountToTake
								assert(amountNeeded >= 0, "temporary assert")
								if amountNeeded <= 0 then
									break
								end
							end
						end
					end
					-- now give
					for _, product in ipairs(recipe.products) do
						util.inventory.give(window.inventoryToGiveTo, product.type, product.metadata, product.count * howManyResult)
					end
					-- update window.selectedItems
					for item in pairs(window.selectedItems) do
						if not util.getIndex(window.inventoryToGiveTo, item) then
							window.selectedItems[item] = nil
						end
					end
					assert(window == ui.focusedWindow, "not focused window")
					ui.cancelFocused()
				end
			end
		end
		if window.type == "status" then
			window.text = "Health: " .. window.entity.health .. "/" .. registry.entityTypes[window.entity.typeName].maxHealth -- .. "\nMoney: " .. (window.entity.money or 0)
		end
		if window.type == "howMany" then
			local sizeText = ""
			if window.sizeOfSingle then
				sizeText = " (" .. window.amount * window.sizeOfSingle .. ")"
			end
			window.text = "How many?\n" .. window.amount .. "/" .. window.maxAmount .. sizeText
		end
		if window == ui.focusedWindow then
			if window.type == "inventory" or window.type == "transferInventories" or window.type == "crafting" or window.type == "craftingChoiceMenu" then
				if uiCommandDone.confirm then
					if window.selectionFunction then
						window:selectionFunction()
					end
				end
				if window.type ~= "craftingChoiceMenu" and player and window.items == player.inventory and window.items.canEquip and uiCommandDone.equip then
					local selectedStack = window.items[window.cursor]
					if selectedStack then
						if selectedStack == window.items.equippedItem then
							window.items.equippedItem = nil
						else
							window.items.equippedItem = selectedStack
						end
					else
						window.items.equippedItem = nil
					end
				end
				if #window.items > 0 then
					if uiCommandDone.selectUp then
						window.cursor = math.max(1, window.cursor - 1)
					end
					if uiCommandDone.selectDown then
						window.cursor = math.min(#window.items, window.cursor + 1)
					end
					if window.cursor < window.viewOffset + 1 then
						window.viewOffset = window.cursor - 1
					end
					if window.cursor > window.viewOffset + window.extraSlotsOffset + 1 then
						window.viewOffset = window.cursor - window.extraSlotsOffset - 1
					end
					if window.cursor > #window.items then
						window.cursor = #window.items
					end
				else
					window.cursor = 1
					window.viewOffset = 0
				end
			end
			if window.type == "transferInventories" then
				if uiCommandDone.changeInventoryScreens then
					window.cursor = 1
					window.swapped = not window.swapped
					window.items, window.otherItems = window.otherItems, window.items
					window.displayName, window.otherDisplayName = window.otherDisplayName, window.displayName
				end
			end
			if window.type == "crafting" then
				if uiCommandDone.craft then
					local selectedItemsArray = {}
					for stack in pairs(window.selectedItems) do
						if util.getIndex(window.items, stack) then
							selectedItemsArray[#selectedItemsArray + 1] = stack
						end
					end
					if #selectedItemsArray > 0 then
						local craftables = util.getMatchingRecipes(selectedItemsArray, window.classes)
						if #craftables > 0 then
							-- ui.cancelFocused()
							ui.craftingChoiceMenu(craftables, window.items, "Pick something to make")
							ui.focusedWindow.windowToFocusWhenDismissed = window
							ui.focusedWindow.selectedItems = window.selectedItems
						else
							ui.textBoxWrapper("Can't make anything\nwith the current\nselection of items\n")
						end
					end
				end
			end
		end
	end
end

local function drawText(text, x, y, yLines)
	local yLines = yLines or 0
	local processedText = util.parseFontSpecials(text)
	love.graphics.print(processedText, x, y + yLines * assets.font.font:getHeight())
	-- Maybe do wrapping and return new yLines deopending on how many times it wrapped?
end

local function uiSetColor(window, r, g, b)
	love.graphics.setColor(r, g, b)
	if window ~= ui.focusedWindow and not window.dontDarken then
		love.graphics.multiplyColor(0.75, 0.75, 0.75)
	end
end

function ui.draw()
	for _, window in ipairs(ui.windows) do
		love.graphics.push("all")
		love.graphics.origin()
		love.graphics.translate(window.x, window.y)
		uiSetColor(window, 0.25, 0.25, 0.25)
		love.graphics.rectangle("fill", -3, -3, window.width + 6, window.height + 6)
		uiSetColor(window, 0.5, 0.5, 0.5)
		love.graphics.rectangle("fill", 0, 0, window.width, window.height)
		uiSetColor(window, 1, 1, 1)
		if window.type == "textBox" or window.type == "status" or window.type == "howMany" then
			drawText(window.text or "", window.textX, window.textY, 0)
		end
		if window.type == "inventory" or window.type == "transferInventories" or window.type == "crafting" or window.type == "craftingChoiceMenu" then
			-- handle (keybinding) for title when in a transferring inventory screen
			local extraText = ""
			if window.type == "transferInventories" then
				local binding = settings.commands.changeInventoryScreens
				if type(binding) == "string" then
					extraText = " (" .. binding .. ")"
				elseif type(binding) == "number" then
					extraText = " (mouse " .. binding .. ")"
				end
			end
			-- do title
			local capacityText = window.items.capacity and (" (" .. util.inventory.getCountSize(window.items) .. "/" .. window.items.capacity .. ") ") or ""
			drawText(window.displayName .. capacityText .. extraText, 0, 0, 0)
			-- more above indicator
			if window.viewOffset > 0 then
				love.graphics.draw(assets.inventory.upMoreIndicator, 8, 1 * assets.font.font:getHeight())
			end
			-- do items
			local thisViewOffset = 1
			for stackIndex = 1 + window.viewOffset, math.min(#window.items, 1 + window.viewOffset + window.extraSlotsOffset) do
				-- check for cursor
				local x
				if stackIndex == window.cursor then
					x = assets.inventory.cursor:getWidth()
					love.graphics.draw(assets.inventory.cursor, 0, 8 + thisViewOffset * assets.font.font:getHeight())
				else
					-- x = 0
					x = assets.inventory.cursor:getWidth()
				end
				local stack = window.items[stackIndex]
				local equippedIndicator = stack == window.items.equippedItem and "(E) " or ""
				local craftingSelectedIndicator = window.selectedItems and window.selectedItems[stack] and "(C) " or ""
				local itemName = registry.itemTypes[stack.type].displayName
				local itemSize = registry.itemTypes[stack.type].size
				local craftingChoiceMenuMaxAmountText = window.type == "craftingChoiceMenu" and (" (x" .. stack.maxAmount .. ")") or ""
				local text = equippedIndicator .. craftingSelectedIndicator .. itemName .. " x" .. stack.count .. " (" .. stack.count * itemSize .. ")" .. craftingChoiceMenuMaxAmountText
				drawText(text, x, 8, thisViewOffset)
				thisViewOffset = thisViewOffset + 1
			end
			-- more below indicator
			if window.viewOffset + window.extraSlotsOffset + 1 < #window.items then
				love.graphics.draw(assets.inventory.downMoreIndicator, 8, 8 + (2 + window.extraSlotsOffset) * assets.font.font:getHeight())
			end
		end
		love.graphics.pop()
	end
end

return ui
