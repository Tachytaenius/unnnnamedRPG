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
	local window
	window = ui.inventory(inventoryA, displayNameA, function(self)
		if #self.items <= 0 then return end
		local selectedStack = self.items[self.cursor]
		local amountToTransfer = 1
		if util.inventory.getAmount(self.otherItems) + amountToTransfer * registry.itemTypes[selectedStack.type].size <= self.otherItems.capacity then
			local success, error = util.inventory.takeFromStack(self.items, selectedStack, amountToTransfer)
			if success then
				util.inventory.give(self.otherItems, selectedStack.type, amountToTransfer)
			else
				ui.textBoxWrapper("Not enough of item to transfer")
			end
		else
			ui.textBoxWrapper("Not enough space\nin other inventory\n(" .. window.otherDisplayName .. ") to transfer\n")
		end
	end)
	ui.focusedWindow = window
	window.type = "transferInventories"
	window.otherItems = inventoryB
	window.otherDisplayName = displayNameB
	window.swapped = false
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

function ui.update(dt, world, player, camera, commandDone)
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
	if not ui.active() and uiCommandDone.openInventory then
		if player.moveProgress == nil and world.tileInventories[player.x] and world.tileInventories[player.x][player.y] then
			ui.showTransferringInventories(player.inventory, world.tileInventories[player.x][player.y], "Player", "Ground")
		else
			-- ui.showEntityInventory(player, "Player")
		end
	end
	
	-- try closing
	if ui.focusedWindow and (ui.focusedWindow.type == "inventory" or ui.focusedWindow.type == "transferInventories") and (uiCommandDone.openInventory or uiCommandDone.cancel) then
		ui.cancelFocused()
	end
	if ui.focusedWindow and ui.focusedWindow.type == "textBox" then
		if uiCommandDone.cancel or uiCommandDone.confirm then
			ui.cancelFocused()
		end
	end
	
	for _, window in ipairs(ui.windows) do
		if window == ui.focusedWindow then
			if window.type == "inventory" or window.type == "transferInventories" then
				if uiCommandDone.confirm then
					if window.selectionFunction then
						window:selectionFunction()
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
					if window.cursor > window.viewOffset + window.visibleSlots + 1 then
						window.viewOffset = window.cursor - window.visibleSlots - 1
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
		if window ~= ui.focusedWindow then love.graphics.multiplyColor(0.75, 0.75, 0.75) end
		if window.type == "textBox" then
			drawText(window.text, window.textX, window.textY, 0)
		end
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
			drawText(window.displayName .. " (" .. util.inventory.getAmount(window.items) .. "/" .. window.items.capacity .. ") " .. extraText, 0, 0, 0)
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
				drawText(registry.itemTypes[stack.type].displayName .. " x" .. stack.count .. " (" .. stack.count * registry.itemTypes[stack.type].size .. ")", x, 8, thisViewOffset)
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
