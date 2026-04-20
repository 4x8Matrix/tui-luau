local render = require("./render")

local CELL_BYTE_SIZE = 8

type Area = { x: number, y: number, width: number, height: number }
type Context = { width: number, height: number }
type Widget = { render: (any, Context, Area, buffer) -> () }

export type Component = {
	widget: Widget,
	area: Area,
}

return function(context: Context, buildComponents: (fullArea: Area) -> { Component })
	local fullArea: Area = { x = 1, y = 1, width = context.width, height = context.height }
	local components = buildComponents(fullArea)

	local renderBuffer = buffer.create(context.width * context.height * CELL_BYTE_SIZE)

	for _, component in components do
		local widgetWithBlock = component.widget :: any

		if widgetWithBlock.block then
			widgetWithBlock.block:render(context, component.area, renderBuffer)
		end

		component.widget:render(context, component.area, renderBuffer)
	end

	return render(context, renderBuffer)
end
