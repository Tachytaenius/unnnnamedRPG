local consts = {}

consts.title = "Unnnnamed RPG"
consts.identity = "unnnnamedrpg"

consts.contentWidth = 160
consts.contentHeight = 144

consts.tileSize = 16

consts.startingScene = "testScene"
consts.tileInventoryCapacity = 40 -- how much dropped item can fit on one tile?
consts.warpFadeTime = 0.5

consts.entityLayersByIndex = {"terrain", "decals", "furniture", "tileInventories", "actors"}
consts.entityLayerIndicesByName = {}
for i, v in ipairs(consts.entityLayersByIndex) do
	consts.entityLayerIndicesByName[v] = i
end

consts.commands = {}
consts.commands.moveUp = "held"
consts.commands.moveDown = "held"
consts.commands.moveLeft = "held"
consts.commands.moveRight = "held"
consts.commands.changeDirectionOnly = "held"
consts.commands.aimOnStandingTile = "held"
consts.commands.interact = "pressed"
consts.commands.tryWarpOnSametile = "pressed"
consts.commands.openInventory = "pressed"
consts.commands.confirm = "pressed"
consts.commands.cancel = "pressed"
consts.commands.changeInventoryScreens = "pressed"
consts.commands.selectUp = "pressed"
consts.commands.selectDown = "pressed"
consts.commands.selectLeft = "pressed"
consts.commands.selectRight = "pressed"
consts.commands.previousDisplay = "released"
consts.commands.nextDisplay = "released"
consts.commands.scaleDown = "released"
consts.commands.scaleUp = "released"
consts.commands.toggleFullscreen = "released"

return consts
