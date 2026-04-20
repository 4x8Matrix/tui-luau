local setCell = require("../utilities/setCell")
local utf8len = require("../utilities/utf8len")
local utf8sub = require("../utilities/utf8sub")

local BORDER_SETS = {
	plain = {
		horizontal = "─",
		vertical = "│",
		topLeft = "┌",
		topRight = "┐",
		bottomLeft = "└",
		bottomRight = "┘",
	},
	rounded = {
		horizontal = "─",
		vertical = "│",
		topLeft = "╭",
		topRight = "╮",
		bottomLeft = "╰",
		bottomRight = "╯",
	},
	double = {
		horizontal = "═",
		vertical = "║",
		topLeft = "╔",
		topRight = "╗",
		bottomLeft = "╚",
		bottomRight = "╝",
	},
	thick = {
		horizontal = "━",
		vertical = "┃",
		topLeft = "┏",
		topRight = "┓",
		bottomLeft = "┗",
		bottomRight = "┛",
	},
}

--[=[
	@class Block
	@__index Prototype
]=]
local Block = {}

Block.Interface = {}
Block.Prototype = {}

--[=[
	@method
	@within Block
]=]
function Block.Prototype.setBorders(
	self: BlockBuilder,
	borders: { top: boolean?, bottom: boolean?, left: boolean?, right: boolean? }
): BlockBuilder
	if borders.top ~= nil then
		self.borders.top = borders.top
	end
	if borders.bottom ~= nil then
		self.borders.bottom = borders.bottom
	end
	if borders.left ~= nil then
		self.borders.left = borders.left
	end
	if borders.right ~= nil then
		self.borders.right = borders.right
	end

	return self
end

--[=[
	@method
	@within Block
]=]
function Block.Prototype.setBorderSet(
	self: BlockBuilder,
	borderSet: "plain" | "rounded" | "double" | "thick"
): BlockBuilder
	self.borderSet = borderSet

	return self
end

--[=[
	@method
	@within Block
]=]
function Block.Prototype.setBorderForegroundColor(self: BlockBuilder, color: number): BlockBuilder
	self.borderForegroundColor = color

	return self
end

--[=[
	@method
	@within Block
]=]
function Block.Prototype.setBorderBackgroundColor(self: BlockBuilder, color: number): BlockBuilder
	self.borderBackgroundColor = color

	return self
end

--[=[
	@method
	@within Block
]=]
function Block.Prototype.addTitle(
	self: BlockBuilder,
	title: { text: string, alignment: ("left" | "center" | "right")?, position: ("top" | "bottom")? }
): BlockBuilder
	table.insert(self.titles, {
		text = title.text,
		alignment = title.alignment or "left",
		position = title.position or "top",
	})

	return self
end

--[=[
	@method
	@within Block
]=]
function Block.Prototype.setPadding(
	self: BlockBuilder,
	padding: { left: number?, right: number?, top: number?, bottom: number? }
): BlockBuilder
	if padding.left ~= nil then
		self.padding.left = padding.left
	end
	if padding.right ~= nil then
		self.padding.right = padding.right
	end
	if padding.top ~= nil then
		self.padding.top = padding.top
	end
	if padding.bottom ~= nil then
		self.padding.bottom = padding.bottom
	end

	return self
end

--[=[
	@method
	@within Block
]=]
function Block.Prototype.setBackgroundColor(self: BlockBuilder, color: number): BlockBuilder
	self.backgroundColor = color

	return self
end

--[=[
	@method
	@within Block
]=]
function Block.Prototype.render(
	self: BlockBuilder,
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
	if area.width < 2 or area.height < 2 then
		return
	end

	local borderCharacters = BORDER_SETS[self.borderSet]
	local borderForeground = self.borderForegroundColor or 0
	local borderBackground = self.borderBackgroundColor or 0

	if self.backgroundColor then
		local background = self.backgroundColor

		for row = 0, area.height - 1 do
			for column = 0, area.width - 1 do
				setCell({
					context = context,
					renderBuffer = renderBuffer,
					x = area.x + column,
					y = area.y + row,
					character = " ",
					foreground = 0,
					background = background,
				})
			end
		end
	end

	if self.borders.top then
		local topY = area.y

		setCell({
			context = context,
			renderBuffer = renderBuffer,
			x = area.x,
			y = topY,
			character = self.borders.left and borderCharacters.topLeft or borderCharacters.horizontal,
			foreground = borderForeground,
			background = borderBackground,
		})

		for column = 1, area.width - 2 do
			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = area.x + column,
				y = topY,
				character = borderCharacters.horizontal,
				foreground = borderForeground,
				background = borderBackground,
			})
		end

		setCell({
			context = context,
			renderBuffer = renderBuffer,
			x = area.x + area.width - 1,
			y = topY,
			character = self.borders.right and borderCharacters.topRight or borderCharacters.horizontal,
			foreground = borderForeground,
			background = borderBackground,
		})
	end

	if self.borders.bottom then
		local bottomY = area.y + area.height - 1

		setCell({
			context = context,
			renderBuffer = renderBuffer,
			x = area.x,
			y = bottomY,
			character = self.borders.left and borderCharacters.bottomLeft or borderCharacters.horizontal,
			foreground = borderForeground,
			background = borderBackground,
		})

		for column = 1, area.width - 2 do
			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = area.x + column,
				y = bottomY,
				character = borderCharacters.horizontal,
				foreground = borderForeground,
				background = borderBackground,
			})
		end

		setCell({
			context = context,
			renderBuffer = renderBuffer,
			x = area.x + area.width - 1,
			y = bottomY,
			character = self.borders.right and borderCharacters.bottomRight or borderCharacters.horizontal,
			foreground = borderForeground,
			background = borderBackground,
		})
	end

	if self.borders.left then
		local startRow = self.borders.top and 1 or 0
		local endRow = area.height - 1 - (self.borders.bottom and 1 or 0)

		for row = startRow, endRow do
			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = area.x,
				y = area.y + row,
				character = borderCharacters.vertical,
				foreground = borderForeground,
				background = borderBackground,
			})
		end
	end

	if self.borders.right then
		local startRow = self.borders.top and 1 or 0
		local endRow = area.height - 1 - (self.borders.bottom and 1 or 0)

		for row = startRow, endRow do
			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = area.x + area.width - 1,
				y = area.y + row,
				character = borderCharacters.vertical,
				foreground = borderForeground,
				background = borderBackground,
			})
		end
	end

	local titleStartX = area.x + (self.borders.left and 1 or 0)
	local titleEndX = area.x + area.width - 1 - (self.borders.right and 1 or 0)
	local availableWidth = titleEndX - titleStartX + 1

	for _, title in self.titles do
		local onBottom = title.position == "bottom"
		local hasBorder = onBottom and self.borders.bottom or self.borders.top

		if not hasBorder then
			continue
		end

		local titleY = onBottom and area.y + area.height - 1 or area.y
		local text = title.text
		local textLength = utf8len(text)

		if textLength > availableWidth then
			text = utf8sub(text, 1, availableWidth)
			textLength = availableWidth
		end

		local titleStartColumn
		if title.alignment == "right" then
			titleStartColumn = titleEndX - textLength + 1
		elseif title.alignment == "center" then
			titleStartColumn = titleStartX + math.floor((availableWidth - textLength) / 2)
		else
			titleStartColumn = titleStartX
		end

		local characterOffset = 0
		for byteStart, _ in utf8.codes(text) do
			local nextByte = utf8.offset(text, 2, byteStart)
			local character = text:sub(byteStart, nextByte and nextByte - 1 or #text)

			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = titleStartColumn + characterOffset,
				y = titleY,
				character = character,
				foreground = borderForeground,
				background = borderBackground,
			})

			characterOffset += 1
		end
	end
end

--[=[
	@method
	@within Block
]=]
function Block.Prototype.inner(
	self: BlockBuilder,
	area: {
		width: number,
		height: number,
		x: number,
		y: number,
	}
)
	local leftOffset = (self.borders.left and 1 or 0) + self.padding.left
	local rightOffset = (self.borders.right and 1 or 0) + self.padding.right
	local topOffset = (self.borders.top and 1 or 0) + self.padding.top
	local bottomOffset = (self.borders.bottom and 1 or 0) + self.padding.bottom

	return {
		x = area.x + leftOffset,
		y = area.y + topOffset,
		width = math.max(0, area.width - leftOffset - rightOffset),
		height = math.max(0, area.height - topOffset - bottomOffset),
	}
end

--[=[
	@within Block
]=]
function Block.Interface.new(): BlockBuilder
	local self = (
		setmetatable({
			borders = { top = false, bottom = false, left = false, right = false },
			borderSet = "plain",
			titles = {},
			padding = { left = 0, right = 0, top = 0, bottom = 0 },
		}, { __index = Block.Prototype }) :: any
	) :: BlockBuilder

	return self
end

export type BlockBuilder = {
	borders: { top: boolean, bottom: boolean, left: boolean, right: boolean },
	borderSet: "plain" | "rounded" | "double" | "thick",
	borderForegroundColor: number?,
	borderBackgroundColor: number?,

	titles: { { text: string, alignment: "left" | "center" | "right", position: "top" | "bottom" } },

	padding: { left: number, right: number, top: number, bottom: number },

	backgroundColor: number?,
} & typeof(Block.Prototype)
export type Block = {}

return Block.Interface
