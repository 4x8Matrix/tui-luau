local Block = require("./block")

local setCell = require("../utilities/setCell")

--[=[
	@class Popup
	@__index Prototype
]=]
local Popup = {}

Popup.Interface = {}
Popup.Prototype = {}

--[=[
	@method
	@within Popup
]=]
function Popup.Prototype.setWidth(self: PopupBuilder, width: number): PopupBuilder
	self.width = width

	return self
end

--[=[
	@method
	@within Popup
]=]
function Popup.Prototype.setHeight(self: PopupBuilder, height: number): PopupBuilder
	self.height = height

	return self
end

--[=[
	@method
	@within Popup
]=]
function Popup.Prototype.setBorders(
	self: PopupBuilder,
	borders: { top: boolean?, bottom: boolean?, left: boolean?, right: boolean? }
): PopupBuilder
	self.block:setBorders(borders)

	return self
end

--[=[
	@method
	@within Popup
]=]
function Popup.Prototype.setBorderSet(
	self: PopupBuilder,
	borderSet: "plain" | "rounded" | "double" | "thick"
): PopupBuilder
	self.block:setBorderSet(borderSet)

	return self
end

--[=[
	@method
	@within Popup
]=]
function Popup.Prototype.setBorderForegroundColor(self: PopupBuilder, color: number): PopupBuilder
	self.block:setBorderForegroundColor(color)

	return self
end

--[=[
	@method
	@within Popup
]=]
function Popup.Prototype.setBorderBackgroundColor(self: PopupBuilder, color: number): PopupBuilder
	self.block:setBorderBackgroundColor(color)

	return self
end

--[=[
	@method
	@within Popup
]=]
function Popup.Prototype.setBackgroundColor(self: PopupBuilder, color: number): PopupBuilder
	self.block:setBackgroundColor(color)

	return self
end

--[=[
	@method
	@within Popup
]=]
function Popup.Prototype.setPadding(
	self: PopupBuilder,
	padding: { left: number?, right: number?, top: number?, bottom: number? }
): PopupBuilder
	self.block:setPadding(padding)

	return self
end

--[=[
	@method
	@within Popup
]=]
function Popup.Prototype.addTitle(
	self: PopupBuilder,
	title: {
		text: string,
		alignment: ("left" | "center" | "right")?,
		position: ("top" | "bottom")?,
	}
): PopupBuilder
	self.block:addTitle(title)

	return self
end

--[=[
	Returns a centered Rect of the popup's dimensions within `parentArea`.

	@method
	@within Popup
]=]
function Popup.Prototype.area(
	self: PopupBuilder,
	parentArea: { x: number, y: number, width: number, height: number }
): { x: number, y: number, width: number, height: number }
	local width = math.min(self.width, parentArea.width)
	local height = math.min(self.height, parentArea.height)
	local x = parentArea.x + math.floor((parentArea.width - width) / 2)
	local y = parentArea.y + math.floor((parentArea.height - height) / 2)

	return { x = x, y = y, width = width, height = height }
end

--[=[
	Returns the inner area of the popup after accounting for borders and padding.

	@method
	@within Popup
]=]
function Popup.Prototype.inner(
	self: PopupBuilder,
	area: { x: number, y: number, width: number, height: number }
): { x: number, y: number, width: number, height: number }
	return self.block:inner(area)
end

--[=[
	@method
	@within Popup
]=]
function Popup.Prototype.render(
	self: PopupBuilder,
	context: { width: number, height: number },
	area: { x: number, y: number, width: number, height: number },
	renderBuffer: buffer
)
	local background = self.block.backgroundColor or 0

	for row = area.y, area.y + area.height - 1 do
		for column = area.x, area.x + area.width - 1 do
			setCell({
				context = context,
				renderBuffer = renderBuffer,
				x = column,
				y = row,
				character = " ",
				foreground = 0,
				background = background,
			})
		end
	end

	self.block:render(context, area, renderBuffer)
end

--[=[
	@within Popup
]=]
function Popup.Interface.new(): PopupBuilder
	local self = (
		setmetatable({
			width = 40,
			height = 10,
			block = Block.new()
				:setBorders({ top = true, bottom = true, left = true, right = true })
				:setBorderSet("rounded"),
		}, { __index = Popup.Prototype }) :: any
	) :: PopupBuilder

	return self
end

export type PopupBuilder = {
	width: number,
	height: number,
	block: Block.BlockBuilder,
} & typeof(Popup.Prototype)

return Popup.Interface
