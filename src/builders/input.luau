local Block = require("./block")

local setCell = require("../utilities/setCell")
local utf8len = require("../utilities/utf8len")

--[=[
	@class Input
	@__index Prototype
]=]
local Input = {}

Input.Interface = {}
Input.Prototype = {}

--[=[
	@method
	@within Input
]=]
function Input.Prototype.setText(self: InputBuilder, text: string): InputBuilder
	self.text = text

	return self
end

--[=[
	@method
	@within Input
	Character index (1-based). Pass nil to hide the cursor.
]=]
function Input.Prototype.setCursor(self: InputBuilder, position: number?): InputBuilder
	self.cursor = position

	return self
end

--[=[
	@method
	@within Input
]=]
function Input.Prototype.setPlaceholder(self: InputBuilder, placeholder: string): InputBuilder
	self.placeholder = placeholder

	return self
end

--[=[
	@method
	@within Input
	When set every character in the text is replaced with this symbol, e.g. "●".
]=]
function Input.Prototype.setMask(self: InputBuilder, mask: string): InputBuilder
	self.mask = mask

	return self
end

--[=[
	@method
	@within Input
]=]
function Input.Prototype.setBlock(self: InputBuilder, block: Block.BlockBuilder): InputBuilder
	self.block = block

	return self
end

--[=[
	@method
	@within Input
]=]
function Input.Prototype.setStyle(self: InputBuilder, foreground: number?, background: number?): InputBuilder
	self.style.foreground = foreground
	self.style.background = background

	return self
end

--[=[
	@method
	@within Input
]=]
function Input.Prototype.setCursorStyle(self: InputBuilder, foreground: number?, background: number?): InputBuilder
	self.cursorStyle.foreground = foreground
	self.cursorStyle.background = background

	return self
end

--[=[
	@method
	@within Input
]=]
function Input.Prototype.setPlaceholderStyle(self: InputBuilder, foreground: number?, background: number?): InputBuilder
	self.placeholderStyle.foreground = foreground
	self.placeholderStyle.background = background

	return self
end

--[=[
	@method
	@within Input
]=]
function Input.Prototype.render(
	self: InputBuilder,
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

	local rowY = renderArea.y + math.floor(renderArea.height / 2)
	local textForeground = self.style.foreground or 0
	local cursorForeground = self.cursorStyle.foreground or defaultBackground
	local cursorBackground = self.cursorStyle.background or textForeground
	local placeholderForeground = self.placeholderStyle.foreground or self.style.foreground or 0

	local isEmpty = self.text == ""

	for rowOffset = 0, renderArea.height - 1 do
		local drawY = renderArea.y + rowOffset

		if drawY ~= rowY then
			for columnOffset = 0, renderArea.width - 1 do
				setCell({
					context = context,
					renderBuffer = renderBuffer,
					x = renderArea.x + columnOffset,
					y = drawY,
					character = " ",
					foreground = textForeground,
					background = defaultBackground,
				})
			end
		end
	end

	if isEmpty and self.placeholder then
		local characterOffset = 0

		for byteStart, _ in utf8.codes(self.placeholder) do
			if characterOffset >= renderArea.width then
				break
			end

			local nextByte = utf8.offset(self.placeholder, 2, byteStart)
			local character = self.placeholder:sub(byteStart, nextByte and nextByte - 1 or #self.placeholder)

			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = renderArea.x + characterOffset,
				y = rowY,
				character = character,
				foreground = placeholderForeground,
				background = defaultBackground,
			})

			characterOffset += 1
		end

		for paddingOffset = characterOffset, renderArea.width - 1 do
			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = renderArea.x + paddingOffset,
				y = rowY,
				character = " ",
				foreground = textForeground,
				background = defaultBackground,
			})
		end

		return
	end

	local displayText = self.text or ""

	if self.mask then
		local characterCount = utf8len(displayText)
		local maskCharacter = self.mask

		displayText = string.rep(maskCharacter, characterCount)
	end

	local characters: { string } = {}

	for byteStart, _ in utf8.codes(displayText) do
		local nextByte = utf8.offset(displayText, 2, byteStart)
		table.insert(characters, displayText:sub(byteStart, nextByte and nextByte - 1 or #displayText))
	end

	local textLength = #characters
	local cursorIndex = self.cursor

	local scrollOffset = 0

	if cursorIndex then
		local zeroBasedCursor = cursorIndex - 1
		if zeroBasedCursor >= renderArea.width then
			scrollOffset = zeroBasedCursor - renderArea.width + 1
		end
	end

	for columnOffset = 0, renderArea.width - 1 do
		local characterIndex = scrollOffset + columnOffset + 1
		local drawX = renderArea.x + columnOffset
		local isCursorPosition = cursorIndex and (scrollOffset + columnOffset + 1 == cursorIndex)
		local character = characters[characterIndex] or " "
		local isEndCursor = cursorIndex == textLength + 1 and characterIndex == textLength + 1

		if isCursorPosition or isEndCursor then
			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = drawX,
				y = rowY,
				character = character,
				foreground = cursorForeground,
				background = cursorBackground,
			})
		else
			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = drawX,
				y = rowY,
				character = character,
				foreground = textForeground,
				background = defaultBackground,
			})
		end
	end
end

--[=[
	@within Input
]=]
function Input.Interface.new(): InputBuilder
	local self = (
		setmetatable({
			text = "",
			style = {},
			cursorStyle = {},
			placeholderStyle = {},
		}, { __index = Input.Prototype }) :: any
	) :: InputBuilder

	return self
end

export type InputBuilder = {
	text: string,
	cursor: number?,
	placeholder: string?,
	mask: string?,

	block: Block.BlockBuilder?,
	style: { foreground: number?, background: number? },
	cursorStyle: { foreground: number?, background: number? },
	placeholderStyle: { foreground: number?, background: number? },
} & typeof(Input.Prototype)

return Input.Interface
