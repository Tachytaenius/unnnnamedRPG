require("monkeypatch")
require("run")

local list = require("lib.list")

local consts = require("consts")
local registry = require("registry")
local assets = require("assets")
local settings = require("settings")
local animatedTiles = require("animatedTiles")
local util = require("util")

do -- load util
	-- TODO: directories --> tables
	for i, itemName in ipairs(love.filesystem.getDirectoryItems("util")) do
		if itemName ~= "init.lua" then
			local moduleName = itemName:sub(1, -5) -- remove .lua
			util[moduleName] = require("util." .. moduleName)
		end
	end
end

local world, player, camera, paused
local contentCanvas
local inputPriority
local commandPressed, commandReleased, commandHeld

function love.load(args)
	if args[1] == "convert" then
		converters(args)
		return
	end
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setLineStyle("rough")
	assets.load()
	animatedTiles:reset()
	world, player, camera = util.loadMap("testScene")
	inputPriority = "vertical"
	paused = false
	contentCanvas = love.graphics.newCanvas(consts.contentWidth, consts.contentHeight)
	commandPressed, commandReleased, commandHeld = {}, {}, {}
end

function love.draw(lerpI)
	lerpI = 1
	love.graphics.setCanvas(contentCanvas)
	love.graphics.clear()
	local cw, ch = contentCanvas:getDimensions()
	if camera then
		local camX, camY = math.lerp(camera.prev.drawX, camera.drawX, lerpI), math.lerp(camera.prev.drawY, camera.drawY, lerpI)
		camX, camY = camX * consts.tileSize, camY * consts.tileSize
		camX, camY = math.floor(camX), math.floor(camY)
		love.graphics.translate(-camX, -camY)
		love.graphics.translate(cw / 2, ch / 2)
		
		for x = 0, world.tileMapWidth - 1 do
			for y = 0, world.tileMapHeight - 1 do
				love.graphics.draw(assets.tileTypes[world.backgroundTiles[x][y].name], x * consts.tileSize, y * consts.tileSize)
			end
		end
		
		for entity in world.entities:elements() do
			local quad = util.getEntityQuad(entity, entity.asset.info.defaultSpritesheetName)
			local spritesheetName = entity.asset.info.defaultSpritesheetName
			local image = entity.asset[spritesheetName]
			local x, y = math.lerp(entity.prev.drawX, entity.drawX, lerpI), math.lerp(entity.prev.drawY, entity.drawY, lerpI)
			x, y = x * consts.tileSize, y * consts.tileSize
			x = x + consts.tileSize / 2 - entity.asset.info.spritesheetInfo[spritesheetName].width / 2
			y = y + consts.tileSize / 2 - entity.asset.info.spritesheetInfo[spritesheetName].height / 2
			x, y = math.floor(x), math.floor(y) -- stop bleeding
			love.graphics.draw(image, quad, x, y)
		end
	end
	love.graphics.origin()
	love.graphics.setCanvas()
	local ww, wh = love.graphics.getDimensions()
	local scale = consts.contentScale -- TEMP
	cw, ch = cw * scale, ch * scale
	love.graphics.draw(contentCanvas, (ww - cw) / 2, (wh - ch) / 2, 0, scale)
end

function love.keypressed(key)
	for command, key2 in pairs(settings.commands) do
		if type(key2) == "string" and consts.commands[command] == "pressed" and key == key2 then
			commandPressed[command] = true
		end
	end
end

function love.keyreleased(key)
	for command, key2 in pairs(settings.commands) do
		if type(key2) == "string" and consts.commands[command] == "released" and key == key2 then
			commandPressed[command] = true
		end
	end
end

function love.mousepressed(x, y, button)
	for command, button2 in pairs(settings.commands) do
		if type(button2) == "number" and consts.commands[command] == "pressed" and button == button2 then
			commandPressed[command] = true
		end
	end
end

function love.mousereleased(x, y, button)
	for command, button2 in pairs(settings.commands) do
		if type(button2) == "number" and consts.commands[command] == "released" and button == button2 then
			commandPressed[command] = true
		end
	end
end

function love.frameUpdate(dt)
	for command, commandType in pairs(consts.commands) do
		if commandType == "held" then
			local binding = settings.commands[command]
			if type(binding) == "string" then
				if love.keyboard.isDown(binding) then
					commandHeld[command] = true
				end
			elseif type(binding) == "number" then
				if love.mouse.isDown(binding) then
					commandHeld[command] = true
				end
			end
		end
	end
end

function love.fixedUpdate(dt)
	for entity in world.entities:elements() do
		local entityType = entity.type
		entity.prev = setmetatable({}, getmetatable(entity.prev) or {__index = entity})
		entity.prev.drawX, entity.prev.drawY = entity.drawX, entity.drawY
		-- if we're moving, do movement
		if entity.moveProgress then
			entity.moveProgress = entity.moveProgress + dt / entityType.moveTime
			if entity.moveProgress >= 1 then
				entity.x, entity.y = util.translateByDirection(entity.x, entity.y, entity.moveDirection)
				entity.moveProgress = nil
				entity.moveDirection = nil
				entity.nextWalkCycleStartPos = (not entityType.alternateWalkCycleStartPos) and 0 or entity.nextWalkCycleStartPos == 0 and 0.5 or 0
			end
		end
		-- if we're not moving, see if we are to move
		if entity.moveProgress == nil then
			local up, down, left, right
			if entity == player then
				up = commandHeld.up
				down = commandHeld.down
				left = commandHeld.left
				right = commandHeld.right
				if up and down then
					up, down = false, false
				end
				if left and right then
					left, right = false, false
				end
				local vertical = up or down
				local horizontal = left or right
				if vertical and horizontal then
					if inputPriority == "vertical" then
						left, right = false, false
					else
						up, down = false, false
					end
				else
					inputPriority = vertical and "horizontal" or "vertical"
				end
			end
			if up then
				entity.direction = "up"
				if not util.isOccupied(world, entity.x, entity.y - 1) then
					entity.moveDirection = "up"
				end
			elseif down then
				entity.direction = "down"
				if not util.isOccupied(world, entity.x, entity.y + 1) then
					entity.moveDirection = "down"
				end
			elseif left then
				entity.direction = "left"
				if not util.isOccupied(world, entity.x - 1, entity.y) then
					entity.moveDirection = "left"
				end
			elseif right then
				entity.direction = "right"
				if not util.isOccupied(world, entity.x + 1, entity.y) then
					entity.moveDirection = "right"
				end
			end
			if entity.moveDirection then
				entity.moveProgress = 0
			end
		end
		-- do walk cycle
		if entity.moveProgress == nil then
			entity.walkCyclePos = nil
		else
			entity.walkCyclePos = entity.walkCyclePos or entity.nextWalkCycleStartPos
			entity.walkCyclePos = (entity.walkCyclePos + dt / entityType.walkCycleTime) % 1
		end
		-- get draw pos
		entity.drawX, entity.drawY = util.translateByDirection(entity.x, entity.y, entity.moveDirection, entity.moveProgress)
	end
	animatedTiles:update(dt)
	commandPressed, commandReleased, commandHeld = {}, {}, {}
end
