require("monkeypatch")

local list = require("lib.list")

local consts = require("consts")
local registry = require("registry")
local assets = require("assets")
local settings = require("settings")
local animatedTiles = require("animatedTiles")
local ui = require("ui")
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

local contentCanvas
local colouriseSpriteShader

local world, player, paused
local commandDone, commandDone, commandDone

function love.load(args)
	if args[1] == "convert" then
		util.converters(args)
		return
	end
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setLineStyle("rough")
	util.recreateWindow()
	assets.load()
	animatedTiles:reset()
	world, player = util.loadMap("testScene")
	ui.clear()
	paused = false
	contentCanvas = love.graphics.newCanvas(consts.contentWidth, consts.contentHeight)
	colouriseSpriteShader = love.graphics.newShader("shaders/colouriseSprite.glsl")
	commandDone = {}
end

function love.quit()
	util.save(world, player)
end

function love.draw()
	love.graphics.setFont(assets.font.font)
	love.graphics.setCanvas(contentCanvas)
	love.graphics.clear()
	local cw, ch = contentCanvas:getDimensions()
	if player then
		local camX, camY = util.translateByDirection(player.x, player.y, player.moveDirection, player.moveProgress)
		camX, camY = (camX + 0.5) * consts.tileSize, (camY + 0.5) * consts.tileSize
		camX, camY = math.floor(camX), math.floor(camY)
		love.graphics.translate(-camX, -camY)
		love.graphics.translate(cw / 2, ch / 2)
		
		local minTileX = math.max(0, math.floor((camX-cw/2) / consts.tileSize))
		local maxTileX = math.min(world.tileMapWidth - 1, math.ceil((camX+cw/2) / consts.tileSize))
		local minTileY = math.max(0, math.floor((camY-ch/2) / consts.tileSize))
		local maxTileY = math.min(world.tileMapHeight - 1, math.ceil((camY+ch/2) / consts.tileSize))
		
		for x = minTileX, maxTileX do
			for y = minTileY, maxTileY do
				love.graphics.draw(assets.tileTypes[world.backgroundTiles[x][y].name], x * consts.tileSize, y * consts.tileSize)
			end
		end
		
		local drewTileInventories = false
		local function drawTileInventories()
			for x = minTileX, maxTileX do
				for y = minTileY, maxTileY do
					if world.tileInventories[x][y] and #world.tileInventories[x][y] > 0 then
						love.graphics.draw(assets.tileInventory, x * consts.tileSize, y * consts.tileSize)
					end
				end
			end
		end
		
		local entityDrawOrder = {}
		for entity in world.entities:elements() do
			entityDrawOrder[#entityDrawOrder+1] = entity
		end
		table.sort(entityDrawOrder, function(a, b)
			return consts.entityLayerIndicesByName[registry.entityTypes[a.typeName].layer] < consts.entityLayerIndicesByName[registry.entityTypes[b.typeName].layer]
		end)
		love.graphics.setShader(colouriseSpriteShader)
		for _, entity in ipairs(entityDrawOrder) do
			-- do tile inventories if we just passed the tile inventories layer
			if not drewTileInventories and consts.entityLayerIndicesByName[registry.entityTypes[entity.typeName].layer] >= consts.entityLayerIndicesByName.tileInventories then
				colouriseSpriteShader:send("colourise", false)
				drawTileInventories()
				drewTileInventories = true
			end
			local entityAsset = assets.entityTypes[entity.typeName]
			local spritesheetName = util.getEntitySpritesheetName(entity)
			local spriteSheetInfo = entityAsset.info.spritesheetInfo[spritesheetName]
			local quad = util.getEntityQuad(entity, spritesheetName)
			local image = entityAsset[spritesheetName]
			local x, y = util.translateByDirection(entity.x, entity.y, entity.moveDirection, entity.moveProgress)
			x, y = x * consts.tileSize, y * consts.tileSize
			x = x + consts.tileSize / 2 - spriteSheetInfo.width / 2
			y = y + consts.tileSize / 2 - spriteSheetInfo.height / 2
			x, y = math.floor(x), math.floor(y) -- stop bleeding
			if spriteSheetInfo.colourised then
				colouriseSpriteShader:send("spriteColour", entity.spriteColour)
				colouriseSpriteShader:send("colourise", true)
			else
				colouriseSpriteShader:send("colourise", false)
			end
			love.graphics.draw(image, quad, x, y)
		end
		if not drewTileInventories then
			drawTileInventories() -- if there are no entities
			drewTileInventories = true
		end
		love.graphics.setShader()
		
		for x = minTileX, maxTileX do
			for y = minTileY, maxTileY do
				love.graphics.draw(assets.tileTypes[world.foregroundTiles[x][y].name], x * consts.tileSize, y * consts.tileSize)
			end
		end
	end
	ui.draw()
	love.graphics.origin()
	love.graphics.setCanvas()
	local ww, wh = love.graphics.getDimensions()
	local scale = settings.graphics.contentScale -- TEMP
	cw, ch = cw * scale, ch * scale
	love.graphics.draw(contentCanvas, (ww - cw) / 2, (wh - ch) / 2, 0, scale)
	-- love.graphics.setColor(0.2, 0.2, 0.2)
	-- love.graphics.rectangle("line", (ww - cw) / 2 - 1, (wh - ch) / 2 - 1, cw + 2, ch + 2)
	-- love.graphics.setColor(1, 1, 1)
end

function love.keypressed(key)
	for command, key2 in pairs(settings.commands) do
		if type(key2) == "string" and consts.commands[command] == "pressed" and key == key2 then
			commandDone[command] = true
		end
	end
end

function love.keyreleased(key)
	for command, key2 in pairs(settings.commands) do
		if type(key2) == "string" and consts.commands[command] == "released" and key == key2 then
			commandDone[command] = true
		end
	end
end

function love.mousepressed(x, y, button)
	for command, button2 in pairs(settings.commands) do
		if type(button2) == "number" and consts.commands[command] == "pressed" and button == button2 then
			commandDone[command] = true
		end
	end
end

function love.mousereleased(x, y, button)
	for command, button2 in pairs(settings.commands) do
		if type(button2) == "number" and consts.commands[command] == "released" and button == button2 then
			commandDone[command] = true
		end
	end
end

function love.update(dt)
	for command, commandType in pairs(consts.commands) do
		if commandType == "held" then
			local binding = settings.commands[command]
			if type(binding) == "string" then
				if love.keyboard.isDown(binding) then
					commandDone[command] = true
				end
			elseif type(binding) == "number" then
				if love.mouse.isDown(binding) then
					commandDone[command] = true
				end
			end
		end
	end
	local recreateWindow = false
	if commandDone.previousDisplay then
		local prevDisplayNumber = settings.graphics.displayNumber
		settings.graphics.displayNumber = (settings.graphics.displayNumber - 1) % love.window.getDisplayCount()
		recreateWindow = recreateWindow or prevDisplayNumber ~= settings.graphics.displayNumber
	end
	if commandDone.nextDisplay then
		local prevDisplayNumber = settings.graphics.displayNumber
		settings.graphics.displayNumber = (settings.graphics.displayNumber + 1) % love.window.getDisplayCount()
		recreateWindow = recreateWindow or prevDisplayNumber ~= settings.graphics.displayNumber
	end
	if commandDone.toggleFullscreen then
		settings.graphics.fullscreen = not settings.graphics.fullscreen
		recreateWindow = recreateWindow or true
	end
	if commandDone.scaleDown then
		local prevScale = settings.graphics.contentScale
		settings.graphics.contentScale = math.max(1, settings.graphics.contentScale - 1)
		recreateWindow = recreateWindow or not settings.graphics.fullscreen and prevScale ~= settings.graphics.contentScale
	end
	if commandDone.scaleUp then
		settings.graphics.contentScale = settings.graphics.contentScale + 1
		recreateWindow = recreateWindow or not settings.graphics.fullscreen
	end
	if recreateWindow then
		util.recreateWindow()
	end
	
	ui.update(dt, world, player, commandDone)
	
	if not ui.active() and not paused then
		-- Actual content update
		util.updateEntities(world, player, dt, commandDone)
		animatedTiles:update(dt)
	end
	
	commandDone = {}
end
