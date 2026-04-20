local CELL_BYTE_SIZE = 8

return function(params: {
	context: {
		width: number,
		height: number,
	},
	renderBuffer: buffer,
	x: number,
	y: number,
	character: string,
	foreground: number,
	background: number,
})
	if params.x < 1 or params.x > params.context.width or params.y < 1 or params.y > params.context.height then
		return
	end

	local cellIndex = (params.y - 1) * params.context.width + (params.x - 1)
	local offset = cellIndex * CELL_BYTE_SIZE
	local characterLength = #params.character

	buffer.writestring(params.renderBuffer, offset, params.character)
	buffer.writeu8(params.renderBuffer, offset + 7, characterLength)

	buffer.writeu8(params.renderBuffer, offset + 4, params.foreground)
	buffer.writeu8(params.renderBuffer, offset + 5, params.background)
end
