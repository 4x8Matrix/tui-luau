local getCell = require("../utilities/getCell")

local ANSI_RESET = "\27[0m"

local function foregroundColorEscape(colorCode: number): string
	return `\27[38;5;{colorCode}m`
end

local function backgroundColorEscape(colorCode: number): string
	return `\27[48;5;{colorCode}m`
end

return function(
	context: {
		width: number,
		height: number,
	},
	renderBuffer: buffer
)
	local outputParts = {}

	table.insert(outputParts, ANSI_RESET)

	local currentForeground = 0
	local currentBackground = 0

	for row = 1, context.height do
		for column = 1, context.width do
			local character, foreground, background = getCell({
				context = context,
				renderBuffer = renderBuffer,
				x = column,
				y = row,
			})

			if foreground ~= currentForeground or background ~= currentBackground then
				if foreground == 0 and background == 0 then
					table.insert(outputParts, ANSI_RESET)
				else
					if foreground ~= currentForeground then
						table.insert(outputParts, foreground == 0 and "\27[39m" or foregroundColorEscape(foreground))
					end
					if background ~= currentBackground then
						table.insert(outputParts, background == 0 and "\27[49m" or backgroundColorEscape(background))
					end
				end

				currentForeground = foreground
				currentBackground = background
			end

			table.insert(outputParts, character)
		end

		if row < context.height then
			table.insert(outputParts, "\n")
		end
	end

	table.insert(outputParts, ANSI_RESET)

	return `\27[H\27[J{table.concat(outputParts)}`
end
