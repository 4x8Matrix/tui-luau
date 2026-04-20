local Block = require("./block")
local setCell = require("../utilities/setCell")
local utf8len = require("../utilities/utf8len")
local utf8sub = require("../utilities/utf8sub")

--[=[
	@class Paragraph
	@__index Prototype
]=]
local Paragraph = {}

Paragraph.Interface = {}
Paragraph.Prototype = {}

--[=[
	@method
	@within Paragraph
]=]
function Paragraph.Prototype.setText(self: ParagraphBuilder, text: string): ParagraphBuilder
	self.text = text

	return self
end

--[=[
	@method
	@within Paragraph
]=]
function Paragraph.Prototype.setBlock(self: ParagraphBuilder, block: Block.BlockBuilder): ParagraphBuilder
	self.block = block

	return self
end

--[=[
	@method
	@within Paragraph
]=]
function Paragraph.Prototype.setAlignment(
	self: ParagraphBuilder,
	alignment: "left" | "center" | "right"
): ParagraphBuilder
	self.alignment = alignment

	return self
end

--[=[
	@method
	@within Paragraph
]=]
function Paragraph.Prototype.setWrap(self: ParagraphBuilder, trim: boolean?): ParagraphBuilder
	self.wrap = { trim = if trim ~= nil then trim else false }

	return self
end

--[=[
	@method
	@within Paragraph
]=]
function Paragraph.Prototype.setScroll(self: ParagraphBuilder, x: number, y: number): ParagraphBuilder
	self.scroll.x = x
	self.scroll.y = y

	return self
end

--[=[
	@method
	@within Paragraph
]=]
function Paragraph.Prototype.setStyle(
	self: ParagraphBuilder,
	foreground: number?,
	background: number?
): ParagraphBuilder
	self.style.foreground = foreground
	self.style.background = background

	return self
end

--[=[
	@method
	@within Paragraph
]=]
function Paragraph.Prototype.render(
	self: ParagraphBuilder,
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

	local lines: { string } = {}

	for line in (self.text .. "\n"):gmatch("([^\n]*)\n") do
		table.insert(lines, line)
	end

	if self.wrap then
		local wrappedLines: { string } = {}

		for _, line in lines do
			if utf8len(line) <= renderArea.width then
				table.insert(wrappedLines, line)
				continue
			end

			local parts: { string } = {}
			local totalLength = 0

			for word in line:gmatch("%S+") do
				local wordLength = utf8len(word)

				if wordLength > renderArea.width then
					if #parts > 0 then
						table.insert(wrappedLines, table.concat(parts, " "))
						parts = {}
						totalLength = 0
					end

					local position = 1
					while position <= wordLength do
						local chunkEnd = math.min(position + renderArea.width - 1, wordLength)
						table.insert(wrappedLines, utf8sub(word, position, chunkEnd))
						position = chunkEnd + 1
					end
				else
					local needed = totalLength == 0 and wordLength or totalLength + 1 + wordLength

					if needed <= renderArea.width then
						table.insert(parts, word)
						totalLength = needed
					else
						table.insert(wrappedLines, table.concat(parts, " "))
						parts = { word }
						totalLength = wordLength
					end
				end
			end

			if #parts > 0 then
				table.insert(wrappedLines, table.concat(parts, " "))
			end
		end

		lines = wrappedLines
	end

	for lineOffset = 0, renderArea.height - 1 do
		local line = lines[lineOffset + self.scroll.y + 1]

		if not line then
			break
		end

		line = utf8sub(line, self.scroll.x + 1, self.scroll.x + renderArea.width)

		local lineLength = utf8len(line)
		local alignmentOffset = 0

		if self.alignment == "center" then
			alignmentOffset = math.floor((renderArea.width - lineLength) / 2)
		elseif self.alignment == "right" then
			alignmentOffset = renderArea.width - lineLength
		end

		local characterOffset = 0
		for byteStart, _ in utf8.codes(line) do
			local nextByte = utf8.offset(line, 2, byteStart)
			local character = line:sub(byteStart, nextByte and nextByte - 1 or #line)

			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = renderArea.x + alignmentOffset + characterOffset,
				y = renderArea.y + lineOffset,
				character = character,
				foreground = self.style.foreground or 0,
				background = defaultBackground,
			})

			characterOffset += 1
		end
	end
end

--[=[
	@within Paragraph
]=]
function Paragraph.Interface.new(): ParagraphBuilder
	local self = (
		setmetatable({
			text = "",
			alignment = "left",
			scroll = { x = 0, y = 0 },
			style = {},
		}, { __index = Paragraph.Prototype }) :: any
	) :: ParagraphBuilder

	return self
end

export type ParagraphBuilder = {
	text: string,

	block: Block.BlockBuilder?,
	alignment: "left" | "center" | "right",
	wrap: { trim: boolean }?,
	scroll: { x: number, y: number },

	style: { foreground: number?, background: number? },
} & typeof(Paragraph.Prototype)
export type Paragraph = {}

return Paragraph.Interface
