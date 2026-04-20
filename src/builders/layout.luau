local Constraint = require("./constraint")

--[=[
	@class Layout
	@__index Prototype
]=]
local Layout = {}

Layout.Interface = {}
Layout.Prototype = {}

--[=[
	@method
	@within Layout
]=]
function Layout.Prototype.setDirection(self: LayoutBuilder, direction: "horizontal" | "vertical"): LayoutBuilder
	self.direction = direction

	return self
end

--[=[
	@method
	@within Layout
]=]
function Layout.Prototype.setConstraints(self: LayoutBuilder, constraints: { Constraint.Constraint }): LayoutBuilder
	self.constraints = constraints

	return self
end

--[=[
	Divides `area` into chunks according to the constraints and returns the resulting Rects.

	@method
	@within Layout
]=]
function Layout.Prototype.split(self: LayoutBuilder, area: Rect): { Rect }
	local isHorizontal = self.direction == "horizontal"
	local total = isHorizontal and area.width or area.height
	local sizes = table.create(#self.constraints, 0)
	local available = total

	for index, currentConstraint in self.constraints do
		if currentConstraint.type == "length" then
			sizes[index] = math.min(currentConstraint.value, available)
			available -= sizes[index]
		elseif currentConstraint.type == "percentage" then
			sizes[index] = math.min(math.floor(total * math.clamp(currentConstraint.value, 0, 100) / 100), available)
			available -= sizes[index]
		end
	end

	local totalWeight = 0

	for _, currentConstraint in self.constraints do
		if currentConstraint.type == "fill" then
			totalWeight += currentConstraint.value
		elseif currentConstraint.type == "min" or currentConstraint.type == "max" then
			totalWeight += 1
		end
	end

	if totalWeight > 0 then
		for index, currentConstraint in self.constraints do
			if currentConstraint.type == "fill" then
				sizes[index] = math.min(math.floor(available * currentConstraint.value / totalWeight), available)
			elseif currentConstraint.type == "min" then
				sizes[index] =
					math.min(math.max(currentConstraint.value, math.floor(available / totalWeight)), available)
			elseif currentConstraint.type == "max" then
				sizes[index] = math.min(currentConstraint.value, math.floor(available / totalWeight))
			end
			available -= sizes[index]
		end
	end

	local chunks: { Rect } = {}
	local cursor = isHorizontal and area.x or area.y

	for _, size in sizes do
		if isHorizontal then
			table.insert(chunks, {
				x = cursor,
				y = area.y,
				width = size,
				height = area.height,
			})
		else
			table.insert(chunks, {
				x = area.x,
				y = cursor,
				width = area.width,
				height = size,
			})
		end

		cursor += size
	end

	return chunks
end

--[=[
	@within Layout
]=]
function Layout.Interface.new(): LayoutBuilder
	local self = (
		setmetatable({
			direction = "vertical",
			constraints = {},
		}, { __index = Layout.Prototype }) :: any
	) :: LayoutBuilder

	return self
end

export type Rect = {
	x: number,
	y: number,
	width: number,
	height: number,
}

export type LayoutBuilder = {
	direction: "horizontal" | "vertical",
	constraints: { Constraint.Constraint },
} & typeof(Layout.Prototype)

return Layout.Interface
