local json = require("lib.json")

local function updateWarps(world)
	local path = "assets/defaultScenes/" .. world.location .. "/"
	world.warps = json.decode(love.filesystem.read(path .. "warps.json"))
end

return updateWarps
