local function tint(r, g, b)
	love.graphics.push("all")
	love.graphics.setBlendMode("multiply", "premultiplied")
	love.graphics.setColor(r, g, b)
	love.graphics.rectangle("fill", 0, 0, contentCanvas:getDimensions())
	love.graphics.pop()
end

return tint
