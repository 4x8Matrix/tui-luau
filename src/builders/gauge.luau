local Block = require("./block")
local setCell = require("../utilities/setCell")
local utf8len = require("../utilities/utf8len")
local utf8sub = require("../utilities/utf8sub")

--[=[
	@class Gauge
	@__index Prototype
]=]
local Gauge = {}

Gauge.Interface = {}
Gauge.Prototype = {}

--[=[
	@method
	@within Gauge
]=]
function Gauge.Prototype.setRatio(self: GaugeBuilder, ratio: number): GaugeBuilder
	self.ratio = math.clamp(ratio, 0, 1)

	return self
end

--[=[
	@method
	@within Gauge
]=]
function Gauge.Prototype.setLabel(self: GaugeBuilder, label: string): GaugeBuilder
	self.label = label

	return self
end

--[=[
	@method
	@within Gauge
]=]
function Gauge.Prototype.setBlock(self: GaugeBuilder, block: Block.BlockBuilder): GaugeBuilder
	self.block = block

	return self
end

--[=[
	@method
	@within Gauge
]=]
function Gauge.Prototype.setStyle(self: GaugeBuilder, foreground: number?, background: number?): GaugeBuilder
	self.style.foreground = foreground
	self.style.background = background

	return self
end

--[=[
	@method
	@within Gauge
]=]
function Gauge.Prototype.setFilledStyle(self: GaugeBuilder, foreground: number?, background: number?): GaugeBuilder
	self.filledStyle.foreground = foreground
	self.filledStyle.background = background

	return self
end

--[=[
	@method
	@within Gauge
]=]
function Gauge.Prototype.render(
	self: GaugeBuilder,
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

	if renderArea.width < 1 or renderArea.height < 1 then
		return
	end

	local filledForeground = self.filledStyle.foreground or self.style.foreground or 0
	local filledBackground = self.filledStyle.background or defaultBackground
	local emptyForeground = self.style.foreground or 0
	local emptyBackground = defaultBackground

	local filledWidth = math.floor(renderArea.width * self.ratio)
	local rowY = renderArea.y + math.floor(renderArea.height / 2)

	local label: string? = nil
	local labelStart = 0

	if self.label then
		local truncated = utf8sub(self.label, 1, renderArea.width)
		local truncatedLength = utf8len(truncated)
		label = truncated
		labelStart = renderArea.x + math.floor((renderArea.width - truncatedLength) / 2)
	end

	local labelCharacters: { string } = {}
	local labelLength = 0

	if label then
		for byteStart, _ in utf8.codes(label) do
			local nextByte = utf8.offset(label, 2, byteStart)
			local character = label:sub(byteStart, nextByte and nextByte - 1 or #label)
			table.insert(labelCharacters, character)
		end
		labelLength = #labelCharacters
	end

	for rowOffset = 0, renderArea.height - 1 do
		local drawY = renderArea.y + rowOffset
		local isBarRow = drawY == rowY

		for columnOffset = 0, renderArea.width - 1 do
			local drawX = renderArea.x + columnOffset
			local isFilled = isBarRow and columnOffset < filledWidth

			local foreground = if isFilled then filledForeground else emptyForeground
			local background = if isFilled then filledBackground else emptyBackground

			local character = " "

			if isBarRow and label then
				local labelCharacterIndex = drawX - labelStart + 1
				if labelCharacterIndex >= 1 and labelCharacterIndex <= labelLength then
					character = labelCharacters[labelCharacterIndex]
				end
			end

			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = drawX,
				y = drawY,
				character = character,
				foreground = foreground,
				background = background,
			})
		end
	end
end

--[=[
	@within Gauge
]=]
function Gauge.Interface.new(): GaugeBuilder
	local self = (
		setmetatable({
			ratio = 0,
			style = {},
			filledStyle = {},
		}, { __index = Gauge.Prototype }) :: any
	) :: GaugeBuilder

	return self
end

export type GaugeBuilder = {
	ratio: number,
	label: string?,

	block: Block.BlockBuilder?,
	style: { foreground: number?, background: number? },
	filledStyle: { foreground: number?, background: number? },
} & typeof(Gauge.Prototype)

return Gauge.Interface
