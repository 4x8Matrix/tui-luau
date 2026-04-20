local Block = require("./block")

local setCell = require("../utilities/setCell")

--[=[
	@class Tabs
	@__index Prototype
]=]
local Tabs = {}

Tabs.Interface = {}
Tabs.Prototype = {}

local function renderText(
	text: string,
	startX: number,
	rowY: number,
	maxX: number,
	foreground: number,
	background: number,
	context: { width: number, height: number },
	renderBuffer: buffer
): number
	local characterOffset = 0

	for byteStart, _ in utf8.codes(text) do
		local drawX = startX + characterOffset

		if drawX >= maxX then
			break
		end

		local nextByte = utf8.offset(text, 2, byteStart)
		local character = text:sub(byteStart, nextByte and nextByte - 1 or #text)

		setCell({
			context = context,
			renderBuffer = renderBuffer,
			x = drawX,
			y = rowY,
			character = character,
			foreground = foreground,
			background = background,
		})

		characterOffset += 1
	end

	return characterOffset
end

--[=[
	@method
	@within Tabs
]=]
function Tabs.Prototype.setTabs(self: TabsBuilder, tabs: { string }): TabsBuilder
	self.tabs = tabs

	return self
end

--[=[
	@method
	@within Tabs
]=]
function Tabs.Prototype.setSelected(self: TabsBuilder, index: number?): TabsBuilder
	self.selected = index

	return self
end

--[=[
	@method
	@within Tabs
]=]
function Tabs.Prototype.setDivider(self: TabsBuilder, divider: string): TabsBuilder
	self.divider = divider

	return self
end

--[=[
	@method
	@within Tabs
]=]
function Tabs.Prototype.setBlock(self: TabsBuilder, block: Block.BlockBuilder): TabsBuilder
	self.block = block

	return self
end

--[=[
	@method
	@within Tabs
]=]
function Tabs.Prototype.setStyle(self: TabsBuilder, foreground: number?, background: number?): TabsBuilder
	self.style.foreground = foreground
	self.style.background = background

	return self
end

--[=[
	@method
	@within Tabs
]=]
function Tabs.Prototype.setHighlightStyle(self: TabsBuilder, foreground: number?, background: number?): TabsBuilder
	self.highlightStyle.foreground = foreground
	self.highlightStyle.background = background

	return self
end

--[=[
	@method
	@within Tabs
]=]
function Tabs.Prototype.render(
	self: TabsBuilder,
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

	if renderArea.height < 1 or renderArea.width < 1 or #self.tabs == 0 then
		return
	end

	local rowY = renderArea.y
	local maxX = renderArea.x + renderArea.width
	local cursorX = renderArea.x

	for tabIndex, tabName in self.tabs do
		local isSelected = self.selected == tabIndex
		local tabForeground: number = if isSelected
			then self.highlightStyle.foreground or self.style.foreground or 0
			else self.style.foreground or 0
		local tabBackground: number = if isSelected
			then self.highlightStyle.background or defaultBackground
			else defaultBackground

		if tabIndex > 1 then
			local dividerForeground = self.style.foreground or 0

			cursorX += renderText(
				self.divider,
				cursorX,
				rowY,
				maxX,
				dividerForeground,
				defaultBackground,
				context,
				renderBuffer
			)
		end

		if cursorX >= maxX then
			break
		end

		local paddedLabel = " " .. tabName .. " "

		cursorX += renderText(paddedLabel, cursorX, rowY, maxX, tabForeground, tabBackground, context, renderBuffer)
	end

	for fillX = cursorX, maxX - 1 do
		setCell({
			context = context,
			renderBuffer = renderBuffer,
			x = fillX,
			y = rowY,
			character = " ",
			foreground = self.style.foreground or 0,
			background = defaultBackground,
		})
	end
end

--[=[
	@within Tabs
]=]
function Tabs.Interface.new(): TabsBuilder
	local self = (
		setmetatable({
			tabs = {},
			divider = "│",
			style = {},
			highlightStyle = {},
		}, { __index = Tabs.Prototype }) :: any
	) :: TabsBuilder

	return self
end

export type TabsBuilder = {
	tabs: { string },
	selected: number?,
	divider: string,

	block: Block.BlockBuilder?,
	style: { foreground: number?, background: number? },
	highlightStyle: { foreground: number?, background: number? },
} & typeof(Tabs.Prototype)

return Tabs.Interface
