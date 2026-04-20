local Block = require("@self/builders/block")
local Paragraph = require("@self/builders/paragraph")
local List = require("@self/builders/list")
local Table = require("@self/builders/table")
local Tabs = require("@self/builders/tabs")
local Gauge = require("@self/builders/gauge")
local Sparkline = require("@self/builders/sparkline")
local Input = require("@self/builders/input")
local Popup = require("@self/builders/popup")
local Layout = require("@self/builders/layout")
local Constraint = require("@self/builders/constraint")

local draw = require("@self/callbacks/draw")
local render = require("@self/callbacks/render")
local step = require("@self/callbacks/step")

export type Component = step.Component

export type BlockBuilder = Block.BlockBuilder
export type ParagraphBuilder = Paragraph.ParagraphBuilder
export type ListBuilder = List.ListBuilder
export type TableBuilder = Table.TableBuilder
export type TabsBuilder = Tabs.TabsBuilder
export type GaugeBuilder = Gauge.GaugeBuilder
export type SparklineBuilder = Sparkline.SparklineBuilder
export type InputBuilder = Input.InputBuilder
export type PopupBuilder = Popup.PopupBuilder
export type LayoutBuilder = Layout.LayoutBuilder
export type Constraint = Constraint.Constraint

export type Area = {
	x: number,
	y: number,
	width: number,
	height: number,
}

export type Context = {
	width: number,
	height: number,
}

return {
	block = Block,
	paragraph = Paragraph,
	list = List,
	table = Table,
	tabs = Tabs,
	gauge = Gauge,
	sparkline = Sparkline,
	input = Input,
	popup = Popup,
	layout = Layout,
	constraint = Constraint,

	draw = draw,
	render = render,
	step = step,
}
