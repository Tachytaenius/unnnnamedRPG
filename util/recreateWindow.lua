local consts = require("consts")
local settings = require("settings")

local function recreateWindow()
	local flags = {
		fullscreen = settings.graphics.fullscreen,
		fullscreentype = settings.graphics.borderlessFullscreen and "desktop" or "exclusive",
		vsync = settings.graphics.vsync,
		display = settings.graphics.displayNumber
	}
	local width, height
	if settings.graphics.fullscreen then
		width, height = love.window.getDesktopDimensions(settings.graphics.displayNumber)
	else
		width, height = consts.contentWidth * settings.graphics.contentScale, consts.contentHeight * settings.graphics.contentScale
	end
	love.window.setMode(width, height, flags)
	love.window.setTitle(consts.title)
end

return recreateWindow
