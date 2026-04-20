local CELL_BYTE_SIZE = 8

type Area = {
	x: number,
	y: number,
	width: number,
	height: number,
}

type Widget = {
	render: (self: any, context: { width: number, height: number }, area: Area, renderBuffer: buffer) -> (),
}

type RenderObject = {
	widget: Widget,
	area: Area,
}

return function(
	context: {
		width: number,
		height: number,
	},
	objects: { RenderObject }
): buffer
	local renderBuffer = buffer.create((context.width * context.height) * CELL_BYTE_SIZE)

	for _, object in objects do
		object.widget:render(context, object.area, renderBuffer)
	end

	return renderBuffer
end
