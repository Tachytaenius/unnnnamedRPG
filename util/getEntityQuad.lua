local quadreasonable = require("lib.quadreasonable")

local function getEntityQuad(entity, spritesheetName)
	local assetInfo = entity.asset.info
	local spritesheetInfo = assetInfo.spritesheetInfo[spritesheetName]
	local spriteX, spriteY, spriteCountX, spriteCountY, spriteWidth, spriteHeight, padding
	spriteWidth, spriteHeight = spritesheetInfo.width, spritesheetInfo.height
	padding = 0
	spriteCountX = spritesheetInfo.directionalSpritesheet and 4 or 1
	spriteCountY = (spritesheetInfo.walkCycleFrames or 0) + 1 -- 1 for stationary
	spriteX = spritesheetInfo.directionalSpritesheet and (entity.direction == "up" and 0 or entity.direction == "right" and 1 or entity.direction == "down" and 2 or 3) or 0
	spriteY = entity.moveProgress and spritesheetInfo.walkCycleFrames and math.floor(spritesheetInfo.walkCycleFrames * entity.walkCyclePos) or 0
	return quadreasonable.getQuad(spriteX, spriteY, spriteCountX, spriteCountY, spriteWidth, spriteHeight, padding)
end

return getEntityQuad
