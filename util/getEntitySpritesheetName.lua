local function getEntitySpritesheetName(entity)
	if entity.type.door then
		return entity.open and entity.asset.info.openSpritesheetName or entity.asset.info.closedSpritesheetName
	end
	return entity.asset.info.defaultSpritesheetName
end

return getEntitySpritesheetName
