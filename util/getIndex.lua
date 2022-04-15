local function getIndex(table, object)
	for i, v in ipairs(table) do
		if object == v then
			return i
		end
	end
end

return getIndex
