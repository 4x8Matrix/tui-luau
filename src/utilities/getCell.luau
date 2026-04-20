local CELL_BYTE_SIZE = 8

return function(params: {
	context: {
		width: number,
		height: number,
	},
	renderBuffer: buffer,
	x: number,
	y: number,
}): (string, number, number)
	if params.x < 1 or params.x > params.context.width or params.y < 1 or params.y > params.context.height then
		return " ", 0, 0
	end

	local cellIndex = (params.y - 1) * params.context.width + (params.x - 1)
	local offset = cellIndex * CELL_BYTE_SIZE
	local characterLength = buffer.readu8(params.renderBuffer, offset + 7)

	if characterLength == 0 then
		return " ", 0, 0
	end

	local character = buffer.readstring(params.renderBuffer, offset, characterLength)
	local foreground = buffer.readu8(params.renderBuffer, offset + 4)
	local background = buffer.readu8(params.renderBuffer, offset + 5)

	return character, foreground, background
end
