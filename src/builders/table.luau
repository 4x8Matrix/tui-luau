local Block = require("./block")
local setCell = require("../utilities/setCell")
local utf8len = require("../utilities/utf8len")
local utf8sub = require("../utilities/utf8sub")

--[=[
	@class Table
	@__index Prototype
]=]
local Table = {}

Table.Interface = {}
Table.Prototype = {}

local function renderRow(
	cells: { string },
	columnWidths: { number },
	columnPositions: { number },
	rowY: number,
	foreground: number,
	background: number,
	context: { width: number, height: number },
	renderBuffer: buffer
)
	for columnIndex, cell in cells do
		local columnWidth = columnWidths[columnIndex]

		if not columnWidth then
			continue
		end

		local visibleText = if utf8len(cell) > columnWidth
			then utf8sub(cell, 1, columnWidth - 1) .. "…"
			else cell
		local characterOffset = 0

		for byteStart, _ in utf8.codes(visibleText) do
			local nextByte = utf8.offset(visibleText, 2, byteStart)
			local character = visibleText:sub(byteStart, nextByte and nextByte - 1 or #visibleText)

			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = columnPositions[columnIndex] + characterOffset,
				y = rowY,
				character = character,
				foreground = foreground,
				background = background,
			})

			characterOffset += 1
		end
	end
end

--[=[
	@method
	@within Table
]=]
function Table.Prototype.setHeaders(self: TableBuilder, headers: { string }): TableBuilder
	self.headers = headers

	return self
end

--[=[
	@method
	@within Table
]=]
function Table.Prototype.setRows(self: TableBuilder, rows: { { string } }): TableBuilder
	self.rows = rows

	return self
end

--[=[
	@method
	@within Table
	Each number is the fixed character width of the corresponding column.
	Unspecified columns divide the remaining width equally.
]=]
function Table.Prototype.setWidths(self: TableBuilder, widths: { number }): TableBuilder
	self.widths = widths

	return self
end

--[=[
	@method
	@within Table
]=]
function Table.Prototype.setColumnSpacing(self: TableBuilder, spacing: number): TableBuilder
	self.columnSpacing = spacing

	return self
end

--[=[
	@method
	@within Table
]=]
function Table.Prototype.setBlock(self: TableBuilder, block: Block.BlockBuilder): TableBuilder
	self.block = block

	return self
end

--[=[
	@method
	@within Table
]=]
function Table.Prototype.setStyle(self: TableBuilder, foreground: number?, background: number?): TableBuilder
	self.style.foreground = foreground
	self.style.background = background

	return self
end

--[=[
	@method
	@within Table
]=]
function Table.Prototype.setHeaderStyle(self: TableBuilder, foreground: number?, background: number?): TableBuilder
	self.headerStyle.foreground = foreground
	self.headerStyle.background = background

	return self
end

--[=[
	@method
	@within Table
]=]
function Table.Prototype.setHighlightStyle(self: TableBuilder, foreground: number?, background: number?): TableBuilder
	self.highlightStyle.foreground = foreground
	self.highlightStyle.background = background

	return self
end

--[=[
	@method
	@within Table
]=]
function Table.Prototype.setHighlightSymbol(self: TableBuilder, symbol: string): TableBuilder
	self.highlightSymbol = symbol

	return self
end

--[=[
	@method
	@within Table
]=]
function Table.Prototype.setSelected(self: TableBuilder, index: number?): TableBuilder
	self.selected = index

	return self
end

--[=[
	@method
	@within Table
]=]
function Table.Prototype.render(
	self: TableBuilder,
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

	local hasHeaders = #self.headers > 0
	local symbolWidth = self.highlightSymbol and utf8len(self.highlightSymbol) or 0
	local rowsAreaHeight = renderArea.height - (hasHeaders and 1 or 0)

	if renderArea.height <= (hasHeaders and 1 or 0) then
		return
	end

	local columnCount = #self.headers
	for _, row in self.rows do
		if #row > columnCount then
			columnCount = #row
		end
	end

	if columnCount == 0 then
		return
	end

	local columnWidths: { number } = {}

	if self.widths then
		for index = 1, columnCount do
			columnWidths[index] = self.widths[index] or 0
		end
	else
		local totalSpacing = self.columnSpacing * math.max(0, columnCount - 1)
		local totalAvailable = renderArea.width - symbolWidth - totalSpacing
		local perColumn = math.floor(totalAvailable / columnCount)
		local remainder = totalAvailable - perColumn * columnCount

		for index = 1, columnCount do
			columnWidths[index] = math.max(0, perColumn + (index <= remainder and 1 or 0))
		end
	end

	local columnPositions: { number } = {}
	local cursorX = renderArea.x + symbolWidth

	for index = 1, columnCount do
		columnPositions[index] = cursorX
		cursorX += columnWidths[index] + self.columnSpacing
	end

	local scrollOffset = 0

	if self.selected then
		local selectedIndex = self.selected - 1
		if selectedIndex >= rowsAreaHeight then
			scrollOffset = selectedIndex - rowsAreaHeight + 1
		end
	end

	local currentY = renderArea.y

	if hasHeaders then
		local headerForeground = self.headerStyle.foreground or self.style.foreground or 0
		local headerBackground = self.headerStyle.background or defaultBackground

		if symbolWidth > 0 then
			for paddingColumn = 0, symbolWidth - 1 do
				setCell({
					context = context,
					renderBuffer = renderBuffer,
					x = renderArea.x + paddingColumn,
					y = currentY,
					character = " ",
					foreground = headerForeground,
					background = headerBackground,
				})
			end
		end

		renderRow(
			self.headers,
			columnWidths,
			columnPositions,
			currentY,
			headerForeground,
			headerBackground,
			context,
			renderBuffer
		)

		currentY += 1
	end

	for rowOffset = 0, rowsAreaHeight - 1 do
		local rowIndex = rowOffset + scrollOffset + 1
		local row = self.rows[rowIndex]

		if not row then
			break
		end

		local isSelected = self.selected == rowIndex
		local rowForeground: number = if isSelected
			then self.highlightStyle.foreground or self.style.foreground or 0
			else self.style.foreground or 0
		local rowBackground: number = if isSelected
			then self.highlightStyle.background or defaultBackground
			else defaultBackground

		if isSelected and self.highlightStyle.background then
			for fillX = renderArea.x, renderArea.x + renderArea.width - 1 do
				setCell({
					context = context,
					renderBuffer = renderBuffer,
					x = fillX,
					y = currentY + rowOffset,
					character = " ",
					foreground = rowForeground,
					background = rowBackground,
				})
			end
		end

		if self.highlightSymbol then
			local symbol = isSelected and self.highlightSymbol or string.rep(" ", symbolWidth)
			local characterOffset = 0

			for byteStart, _ in utf8.codes(symbol) do
				local nextByte = utf8.offset(symbol, 2, byteStart)
				local character = symbol:sub(byteStart, nextByte and nextByte - 1 or #symbol)

				setCell({
					context = context,
					renderBuffer = renderBuffer,
					x = renderArea.x + characterOffset,
					y = currentY + rowOffset,
					character = character,
					foreground = rowForeground,
					background = rowBackground,
				})

				characterOffset += 1
			end
		end

		renderRow(
			row,
			columnWidths,
			columnPositions,
			currentY + rowOffset,
			rowForeground,
			rowBackground,
			context,
			renderBuffer
		)
	end
end

--[=[
	@within Table
]=]
function Table.Interface.new(): TableBuilder
	local self = (
		setmetatable({
			headers = {},
			rows = {},
			columnSpacing = 1,
			style = {},
			headerStyle = {},
			highlightStyle = {},
		}, { __index = Table.Prototype }) :: any
	) :: TableBuilder

	return self
end

export type TableBuilder = {
	headers: { string },
	rows: { { string } },
	widths: { number }?,
	columnSpacing: number,

	block: Block.BlockBuilder?,
	style: { foreground: number?, background: number? },
	headerStyle: { foreground: number?, background: number? },
	highlightStyle: { foreground: number?, background: number? },
	highlightSymbol: string?,
	selected: number?,
} & typeof(Table.Prototype)
export type Table = {}

return Table.Interface
