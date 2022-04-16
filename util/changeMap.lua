local util = require("util")

local function changeMap(saveFileName, newMap, newPlayerX, newPlayerY, newPlayerDirection, world, player)
	world.entities:remove(player)
	util.save(saveFileName, world, nil)
	local world = util.loadMap(saveFileName, newMap)
	player.x, player.y = newPlayerX, newPlayerY
	player.moveProgress, player.moveDirection = nil, nil
	player.direction = player.direction and newPlayerDirection or player.direction or nil -- if player has direction property, write newPlayerDirection (if not newPlayerDirection then keep player.direction), and replace false with nil
	world.entities:add(player)
	util.changeWorld(world)
	util.changePlayer(player)
end

return changeMap
