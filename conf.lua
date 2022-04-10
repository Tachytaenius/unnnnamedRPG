local consts = require("consts")

function love.conf(t)
	t.window.title = consts.title
	t.window.width = consts.contentWidth * consts.contentScale
	t.window.height = consts.contentHeight * consts.contentScale
end
