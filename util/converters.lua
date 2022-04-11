-- For scene development

local json = require("lib.json")
local consts = require("consts")

local saveDirectory = require("util.saveDirectory")

local function converters(args) -- this splits off from love.load
	if args[2] == "csvToBin" then
		saveDirectory:enable()
		local csv = love.filesystem.read(args[3])
		love.filesystem.write(args[3]:sub(1, -5)..".bin", csvToBin(csv))
		saveDirectory:disable()
		print("done")
		love.event.quit()
		return
	elseif args[2] == "tiledExportToScene" then
		saveDirectory:enable()
		local folderPath = "tiled/" .. args[3] .. "/"
		local import
		for _, itemName in ipairs(love.filesystem.getDirectoryItems(folderPath)) do
			local wholePath = folderPath .. itemName
			if love.filesystem.getInfo(wholePath, "file") then
				if itemName:match("%.tmj$") then
					import = json.decode(love.filesystem.read(wholePath))
					break
				end
			end
		end
		-- info.json and tileIds.txt assumed to already be present
		local btd -- backgroundTileData.bin
		local ftd -- foregroundTileData.bin
		local ent -- entities.json
		for _, layer in ipairs(import.layers) do
			if layer.name == "entities" then
				ent = "[\n"
				local noEntities = true
				for _, object in ipairs(layer.objects) do
					noEntities = false
					ent = ent .. "\t{\"x\": " .. math.floor(object.x / consts.tileSize) .. ", \"y\": " .. math.floor(object.y / consts.tileSize) .. ", "
					for _, v in ipairs(object.properties) do
						local valueString = v.type == "string" and "\"" .. v.value .. "\"" or tostring(v.value)
						ent = ent .. "\"" .. v.name .. "\": " .. valueString .. ", "
					end
					ent = ent:sub(1, -3) .. "},\n"
				end
				ent = noEntities and "[]" or ent:sub(1, -3) .. "\n]\n"
			else
				local data = layer.data
				for i, v in ipairs(data) do
					data[i] = string.char(v - 1) -- -1 because Tiled is exporting with tile ids +1
					-- data[i] = (v - 1) .. "," -- csv
				end
				local bin = table.concat(data)
				if layer.name == "background" then
					btd = bin
				elseif layer.name == "foreground" then
					ftd = bin
				end
			end
		end
		love.filesystem.write(folderPath .. "backgroundTileData.bin", btd)
		love.filesystem.write(folderPath .. "foregroundTileData.bin", ftd)
		love.filesystem.write(folderPath .. "entities.json", ent)
		saveDirectory:disable()
		print("done")
		love.event.quit()
		return
	end
end

return converters
