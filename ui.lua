local list = require("lib.list")

local settings = require("settings")
local assets = require("assets")
local util = require("util")

local ui = {}

function ui.clear()
	ui.focusedWindow = nil
	ui.windows = list()
end

function ui.active()
	local active = false
	for window in ui.windows:elements() do
		if window.active then
			active = true
			break
		end
	end
	return active
end

function ui.cancel()
	-- if can't cancel then return false end
	local i = 1
	while i <= ui.windows.size do
		local window = ui.windows:get(i)
		if window.active then
			ui.windows:remove(window)
		end
		if window == ui.focusedWindow then
			ui.focusedWindow = nil
		end
	end
	return true
end

function ui.inventory(inventory, displayName, selectionFunction)
	local window = {justOpened = true}
	ui.windows:add(window)
	window.selectionFunction = selectionFunction
	window.type = "inventory"
	window.items = inventory
	window.displayName = displayName
	window.active = true
	window.cursor = 1
	window.visibleSlots = 5
	window.viewOffset = 0
	window.x, window.y = 8, 8
	window.width, window.height = 144, 128
	return window
end

function ui.showEntityInventory(entity, displayName)
	if not entity.inventory then return end
	ui.focusedWindow = ui.inventory(entity.inventory, displayName)
end

function ui.showTransferringInventories(inventoryA, inventoryB, displayNameA, displayNameB)
	local window = ui.inventory(inventoryA, displayNameA, function(self)
		if #self.items <= 0 then return end
		local selectedStack = self.items[self.cursor]
		local amountToTransfer = 1
		if util.inventory.getAmount(self.otherItems) + amountToTransfer <= self.otherItems.capacity then
			local success, error = util.inventory.takeFromStack(self.items, selectedStack, amountToTransfer)
			if success then
				util.inventory.give(self.otherItems, selectedStack.type, amountToTransfer)
			end
		end
	end)
	ui.focusedWindow = window
	window.type = "transferInventories"
	window.otherItems = inventoryB
	window.otherDisplayName = displayNameB
	window.swapped = false
end

function ui.update(dt, commandDone)
	if ui.focusedWindow and (ui.focusedWindow.type == "inventory" or ui.focusedWindow.type == "transferInventories") and not ui.focusedWindow.justOpened and commandDone.openInventory or commandDone.cancel then
		ui.cancel()
	end
	for window in ui.windows:elements() do
		if window == ui.focusedWindow then
			if window.type == "inventory" or window.type == "transferInventories" then
				if commandDone.confirm then
					if window.selectionFunction then
						window:selectionFunction()
					end
				end
				if #window.items > 0 then
					if commandDone.selectUp then
						window.cursor = math.max(1, window.cursor - 1)
					end
					if commandDone.selectDown then
						
						window.cursor = math.min(#window.items, window.cursor + 1)
					end
					if window.cursor < window.viewOffset + 1 then
						window.viewOffset = window.cursor - 1
					end
					if window.cursor > window.viewOffset + window.visibleSlots + 1 then
						window.viewOffset = window.cursor - window.visibleSlots - 1
					end
				else
					window.cursor = 1
					window.viewOffset = 0
				end
			end
			if window.type == "transferInventories" then
				if commandDone.changeInventoryScreens then
					window.cursor = 1
					window.swapped = not window.swapped
					window.items, window.otherItems = window.otherItems, window.items
					window.displayName, window.otherDisplayName = window.otherDisplayName, window.displayName
				end
			end
		end
	end
	for window in ui.windows:elements() do
		window.justOpened = nil
	end
end

local function drawText(text, x, y, yLines)
	local yLines = yLines or 0
	local processedText = util.parseFontSpecials(text)
	love.graphics.print(processedText, x, y + yLines * assets.font.font:getHeight())
	-- Maybe do wrapping and return new yLines deopending on how many times it wrapped?
end

function ui.draw()
	for window in ui.windows:elements() do
		love.graphics.push("all")
		love.graphics.origin()
		love.graphics.translate(window.x, window.y)
		love.graphics.setColor(0.5, 0.5, 0.5)
		love.graphics.rectangle("fill", 0, 0, window.width, window.height)
		love.graphics.setColor(1, 1, 1)
		if window.type == "inventory" or window.type == "transferInventories" then
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
			drawText(window.displayName .. extraText, 0, 0, 0)
			-- more above indicator
			if window.viewOffset > 0 then
				love.graphics.draw(assets.inventory.upMoreIndicator, 8, 1 * assets.font.font:getHeight())
			end
			-- do items
			local thisViewOffset = 1
			for stackIndex = 1 + window.viewOffset, math.min(#window.items, 1 + window.viewOffset + window.visibleSlots) do
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
				drawText(stack.type .. " x" .. stack.count, x, 8, thisViewOffset)
				thisViewOffset = thisViewOffset + 1
			end
			-- more below indicator
			if window.viewOffset + window.visibleSlots + 1 < #window.items then
				love.graphics.draw(assets.inventory.downMoreIndicator, 8, 8 + (2 + window.visibleSlots) * assets.font.font:getHeight())
			end
		end
		love.graphics.pop()
	end
end

return ui
