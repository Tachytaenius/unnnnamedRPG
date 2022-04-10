local function translateByDirection(x, y, direction, amount)
	amount = amount or 1
	if direction == "up" then
		y = y - amount
	elseif direction == "down" then
		y = y + amount
	elseif direction == "left" then
		x = x - amount
	elseif direction == "right" then
		x = x + amount
	end
	return x, y
end

return translateByDirection
