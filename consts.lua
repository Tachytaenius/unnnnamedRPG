local consts = {}

consts.title = "Unnnnamed RPG"
consts.identity = "unnnnamedrpg"

consts.contentWidth = 160
consts.contentHeight = 144

consts.tileSize = 16

consts.entityLayersByIndex = {"decals", "furniture", "actors"}
consts.entityLayerIndicesByName = {}
for i, v in ipairs(consts.entityLayersByIndex) do
	consts.entityLayerIndicesByName[v] = i
end

consts.commands = {}
consts.commands.moveUp = "held"
consts.commands.moveDown = "held"
consts.commands.moveLeft = "held"
consts.commands.moveRight = "held"
consts.commands.interact = "pressed"
consts.commands.previousDisplay = "released"
consts.commands.nextDisplay = "released"
consts.commands.scaleDown = "released"
consts.commands.scaleUp = "released"
consts.commands.toggleFullscreen = "released"

return consts
