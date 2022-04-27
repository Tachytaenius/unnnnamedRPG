-- TODO: json
-- TODO: gui

local settings = {}

settings.graphics = {}
settings.graphics.contentScale = 3
settings.graphics.fullscreen = false
settings.graphics.borderlessFullscreen = true
settings.graphics.vsync = 1
settings.graphics.displayNumber = 0

settings.commands = {}
settings.commands.moveUp = "w"
settings.commands.moveDown = "s"
settings.commands.moveLeft = "a"
settings.commands.moveRight = "d"
settings.commands.changeDirectionOnly = "lshift"
settings.commands.aimOnStandingTile = "lctrl"
settings.commands.interact = "e"
settings.commands.attack = "space"
settings.commands.tryWarpOnSametile = "tab"
settings.commands.rotateFurniture = "r"
settings.commands.openInventory = "i"
settings.commands.confirm = "return"
settings.commands.cancel = "escape"
settings.commands.equip = "e"
settings.commands.openCrafting = "c"
settings.commands.craft = "c"
settings.commands.changeInventoryScreens = "tab"
settings.commands.selectUp = "w"
settings.commands.selectDown = "s"
settings.commands.selectLeft = "a"
settings.commands.selectRight = "d"
settings.commands.previousDisplay = "f7"
settings.commands.nextDisplay = "f8"
settings.commands.scaleDown = "f9"
settings.commands.scaleUp = "f10"
settings.commands.toggleFullscreen = "f11"
settings.commands.save = "f1"
settings.commands.updateWarps = "f2"

return settings
