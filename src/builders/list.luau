local Block = require("./block")
local setCell = require("../utilities/setCell")
local utf8len = require("../utilities/utf8len")
local utf8sub = require("../utilities/utf8sub")

--[=[
	@class List
	@__index Prototype
]=]
local List = {}

List.Interface = {}
List.Prototype = {}

--[=[
	@method
	@within List
]=]
function List.Prototype.setItems(self: ListBuilder, items: { string }): ListBuilder
	self.items = items

	return self
end

--[=[
	@method
	@within List
]=]
function List.Prototype.setBlock(self: ListBuilder, block: Block.BlockBuilder): ListBuilder
	self.block = block

	return self
end

--[=[
	@method
	@within List
]=]
function List.Prototype.setStyle(self: ListBuilder, foreground: number?, background: number?): ListBuilder
	self.style.foreground = foreground
	self.style.background = background

	return self
end

--[=[
	@method
	@within List
]=]
function List.Prototype.setHighlightStyle(self: ListBuilder, foreground: number?, background: number?): ListBuilder
	self.highlightStyle.foreground = foreground
	self.highlightStyle.background = background

	return self
end

--[=[
	@method
	@within List
]=]
function List.Prototype.setHighlightSymbol(self: ListBuilder, symbol: string): ListBuilder
	self.highlightSymbol = symbol

	return self
end

--[=[
	@method
	@within List
]=]
function List.Prototype.setSelected(self: ListBuilder, index: number?): ListBuilder
	self.selected = index

	return self
end

--[=[
	@method
	@within List
]=]
function List.Prototype.render(
	self: ListBuilder,
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

	local symbolWidth = self.highlightSymbol and utf8len(self.highlightSymbol) or 0
	local contentWidth = renderArea.width - symbolWidth

	local scrollOffset = 0

	if self.selected then
		local selectedIndex = self.selected - 1
		if selectedIndex >= renderArea.height then
			scrollOffset = selectedIndex - renderArea.height + 1
		end
	end

	for rowOffset = 0, renderArea.height - 1 do
		local itemIndex = rowOffset + scrollOffset + 1
		local item = self.items[itemIndex]

		if not item then
			break
		end

		local isSelected = self.selected == itemIndex
		local itemForeground: number = if isSelected
			then self.highlightStyle.foreground or self.style.foreground or 0
			else self.style.foreground or 0
		local itemBackground: number = if isSelected
			then self.highlightStyle.background or defaultBackground
			else defaultBackground

		local drawX = renderArea.x

		if self.highlightSymbol then
			local symbol = isSelected and self.highlightSymbol or string.rep(" ", symbolWidth)
			local characterOffset = 0

			for byteStart, _ in utf8.codes(symbol) do
				local nextByte = utf8.offset(symbol, 2, byteStart)
				local character = symbol:sub(byteStart, nextByte and nextByte - 1 or #symbol)

				setCell({
					context = context,
					renderBuffer = renderBuffer,
					x = drawX + characterOffset,
					y = renderArea.y + rowOffset,
					character = character,
					foreground = itemForeground,
					background = itemBackground,
				})

				characterOffset += 1
			end

			drawX += symbolWidth
		end

		local visibleText = utf8sub(item, 1, contentWidth)
		local visibleLength = utf8len(visibleText)

		local characterOffset = 0
		for byteStart, _ in utf8.codes(visibleText) do
			local nextByte = utf8.offset(visibleText, 2, byteStart)
			local character = visibleText:sub(byteStart, nextByte and nextByte - 1 or #visibleText)

			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = drawX + characterOffset,
				y = renderArea.y + rowOffset,
				character = character,
				foreground = itemForeground,
				background = itemBackground,
			})

			characterOffset += 1
		end

		for paddingColumn = visibleLength, contentWidth - 1 do
			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = drawX + paddingColumn,
				y = renderArea.y + rowOffset,
				character = " ",
				foreground = itemForeground,
				background = itemBackground,
			})
		end
	end
end

--[=[
	@within List
]=]
function List.Interface.new(): ListBuilder
	local self = (
		setmetatable({
			items = {},
			style = {},
			highlightStyle = {},
		}, { __index = List.Prototype }) :: any
	) :: ListBuilder

	return self
end

export type ListBuilder = {
	items: { string },

	block: Block.BlockBuilder?,
	style: { foreground: number?, background: number? },
	highlightStyle: { foreground: number?, background: number? },
	highlightSymbol: string?,
	selected: number?,
} & typeof(List.Prototype)
export type List = {}

return List.Interface
