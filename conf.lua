local consts = require("consts")

function love.conf(t)
	t.window.width = consts.contentWidth * consts.contentScale
	t.window.height = consts.contentHeight * consts.contentScale
end
