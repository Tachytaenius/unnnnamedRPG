local list = require("lib.list")

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

function ui.inventory(inventory, selectionFunction)
	local window = {}
	ui.windows:add(window)
	window.selectionFunction = selectionFunction
	window.type = "inventory"
	window.items = inventory
	window.active = true
	window.cursor = 1
	window.visibleSlots = 10
	window.viewOffset = 0
	window.x, window.y = 8, 8
	window.width, window.height = 144, 128
	return window
end

function ui.showEntityInventory(entity)
	if not entity.inventory then return end
	ui.focusedWindow = ui.inventory(entity.inventory)
end

function ui.update(dt, commandDone)
	if commandDone.cancel then
		ui.cancel()
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
		if window.type == "inventory" then
			if window.viewOffset > 0 then
				-- draw up arrow showing that there is more
			end
			if window.viewOffset + window.visibleSlots < #window.items then
				-- draw down arrow showing that there is more
				-- likely off-by-one error here, check when the time comes
			end
			local viewOffset = 0
			for stackIndex = 1 + window.viewOffset, math.min(#window.items, 1 + window.viewOffset + window.visibleSlots) do
				local stack = window.items[stackIndex]
				drawText(stack.type .. " x" .. stack.count, 0, 0, viewOffset)
				viewOffset = viewOffset + 1
			end
		end
		love.graphics.pop()
	end
end

return ui
