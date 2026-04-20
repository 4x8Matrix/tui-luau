--[=[
	@class Constraint
]=]
local Constraint = {}

Constraint.Interface = {}
Constraint.Prototype = {}

--[=[
	@within Constraint
	Fixed number of cells.
]=]
function Constraint.Interface.length(value: number): Constraint
	return setmetatable({ type = "length", value = value }, { __index = Constraint.Prototype }) :: any
end

--[=[
	@within Constraint
	Percentage of the total available space (0–100).
]=]
function Constraint.Interface.percentage(value: number): Constraint
	return setmetatable({ type = "percentage", value = value }, { __index = Constraint.Prototype }) :: any
end

--[=[
	@within Constraint
	At least `value` cells; expands to claim a proportional share of any remainder.
]=]
function Constraint.Interface.min(value: number): Constraint
	return setmetatable({ type = "min", value = value }, { __index = Constraint.Prototype }) :: any
end

--[=[
	@within Constraint
	At most `value` cells; claims a proportional share up to that cap.
]=]
function Constraint.Interface.max(value: number): Constraint
	return setmetatable({ type = "max", value = value }, { __index = Constraint.Prototype }) :: any
end

--[=[
	@within Constraint
	Proportional fill. `weight` defaults to 1; higher values claim a larger share.
]=]
function Constraint.Interface.fill(weight: number?): Constraint
	return setmetatable({ type = "fill", value = weight or 1 }, { __index = Constraint.Prototype }) :: any
end

export type Constraint =
	{ type: "length", value: number }
	| { type: "percentage", value: number }
	| { type: "min", value: number }
	| { type: "max", value: number }
	| { type: "fill", value: number }

return Constraint.Interface
