local Block = require("./block")
local setCell = require("../utilities/setCell")

--[=[
	@class Sparkline
	@__index Prototype
]=]
local Sparkline = {}

Sparkline.Interface = {}
Sparkline.Prototype = {}

local EIGHTH_BLOCKS = { " ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }

--[=[
	@method
	@within Sparkline
]=]
function Sparkline.Prototype.setData(self: SparklineBuilder, data: { number }): SparklineBuilder
	self.data = data

	return self
end

--[=[
	@method
	@within Sparkline
	When omitted the maximum value in the dataset is used.
]=]
function Sparkline.Prototype.setMax(self: SparklineBuilder, max: number): SparklineBuilder
	self.max = max

	return self
end

--[=[
	@method
	@within Sparkline
]=]
function Sparkline.Prototype.setBlock(self: SparklineBuilder, block: Block.BlockBuilder): SparklineBuilder
	self.block = block

	return self
end

--[=[
	@method
	@within Sparkline
]=]
function Sparkline.Prototype.setStyle(self: SparklineBuilder, foreground: number?, background: number?): SparklineBuilder
	self.style.foreground = foreground
	self.style.background = background

	return self
end

--[=[
	@method
	@within Sparkline
]=]
function Sparkline.Prototype.render(
	self: SparklineBuilder,
	context: {
		width: number,
		height: number,
	},
	area: {
		x: number,
		y: number,
		width: number,
		height: number,
	},
	renderBuffer: buffer
)
	local renderArea = area
	local defaultBackground = self.style.background or 0

	if self.block then
		renderArea = self.block:inner(area)
		defaultBackground = self.style.background or self.block.backgroundColor or 0
	end

	if renderArea.width < 1 or renderArea.height < 1 or #self.data == 0 then
		return
	end

	local foreground = self.style.foreground or 0
	local totalSubUnits = renderArea.height * 8

	local resolvedMax = self.max
	if not resolvedMax then
		resolvedMax = self.data[1]
		for _, value in self.data do
			if value > resolvedMax then
				resolvedMax = value
			end
		end
	end

	local dataOffset = math.max(0, #self.data - renderArea.width)

	for columnOffset = 0, renderArea.width - 1 do
		local dataIndex = dataOffset + columnOffset + 1
		local value = self.data[dataIndex]

		local barSubUnits = if value and resolvedMax > 0
			then math.floor(math.clamp(value / resolvedMax, 0, 1) * totalSubUnits)
			else 0

		for rowOffset = 0, renderArea.height - 1 do
			local drawX = renderArea.x + columnOffset
			local drawY = renderArea.y + rowOffset

			local rowFromBottom = renderArea.height - 1 - rowOffset
			local rowBottomSubUnit = rowFromBottom * 8

			local character: string

			if barSubUnits >= rowBottomSubUnit + 8 then
				character = "█"
			elseif barSubUnits > rowBottomSubUnit then
				local partialEighths = barSubUnits - rowBottomSubUnit
				character = EIGHTH_BLOCKS[partialEighths + 1]
			else
				character = " "
			end

			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = drawX,
				y = drawY,
				character = character,
				foreground = foreground,
				background = defaultBackground,
			})
		end
	end
end

--[=[
	@within Sparkline
]=]
function Sparkline.Interface.new(): SparklineBuilder
	local self = (
		setmetatable({
			data = {},
			style = {},
		}, { __index = Sparkline.Prototype }) :: any
	) :: SparklineBuilder

	return self
end

export type SparklineBuilder = {
	data: { number },
	max: number?,

	block: Block.BlockBuilder?,
	style: { foreground: number?, background: number? },
} & typeof(Sparkline.Prototype)

return Sparkline.Interface
