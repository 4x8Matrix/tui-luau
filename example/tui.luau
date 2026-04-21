local io = zune.io
local task = zune.task

local tui = require("../src")

local block = tui.block
local tabs = tui.tabs
local table = tui.table
local list = tui.list
local gauge = tui.gauge
local sparkline = tui.sparkline
local input = tui.input
local popup = tui.popup
local paragraph = tui.paragraph
local layout = tui.layout
local constraint = tui.constraint
local step = tui.step

local GRAY = 245
local WHITE = 255
local DARK_GRAY = 238
local BLUE = 33
local DARK_BLUE = 17
local GREEN = 35

io.terminal.enableRawMode()
io.stdout:writeSync("\27[?1049h\27[?25l")

local selectedIndex = 1
local lastKey = ""
local running = true

task.spawn(function()
	while running do
		local char = io.stdin:read(1)
		if not char or #char == 0 then
			continue
		end

		if char == "\27" then
			local bracket = io.stdin:read(1)
			if bracket == "[" then
				local code = io.stdin:read(1)
				if code == "C" then
					selectedIndex = selectedIndex % 6 + 1
					lastKey = "ArrowRight"
				elseif code == "D" then
					selectedIndex = ((selectedIndex - 2) % 6) + 1
					lastKey = "ArrowLeft"
				else
					lastKey = `ESC[{code}`
				end
			else
				lastKey = "ESC"
			end
		elseif char == "q" or char == "\3" then
			running = false
		else
			lastKey = char
		end
	end
end)

while running do
	local termWidth, termHeight = io.terminal.getSize()
	local context = { width = termWidth or 80, height = termHeight or 24 }

	local shellBlock = block
		.new()
		:setBorders({ top = true, bottom = true, left = true, right = true })
		:setBorderSet("rounded")
		:setBorderForegroundColor(GRAY)

	local tabBar = tabs.new()
		:setTabs({ "People", "Tasks", "Progress", "Sparkline", "Input", "Popup" })
		:setSelected(1)
		:setStyle(GRAY)
		:setHighlightStyle(WHITE)

	local peopleTable = table
		.new()
		:setHeaders({ "Name", "Role", "Status" })
		:setRows({
			{ "Alice", "Engineer", "Active" },
			{ "Bob", "Designer", "Active" },
			{ "Charlie", "Manager", "Away" },
			{ "Diana", "Engineer", "Offline" },
			{ "Eve", "Analyst", "Active" },
		})
		:setWidths({ 12, 14, 10 })
		:setColumnSpacing(2)
		:setHeaderStyle(GRAY)
		:setStyle(WHITE)
		:setHighlightStyle(WHITE, DARK_GRAY)
		:setSelected(1)

	local taskList = list.new()
		:setItems({
			"Fix login page bug",
			"Review pull requests",
			"Update documentation",
			"Deploy staging build",
			"Write unit tests",
		})
		:setStyle(WHITE)
		:setHighlightStyle(WHITE, DARK_GRAY)
		:setHighlightSymbol("▶ ")
		:setSelected(2)

	local function makeGauge(label: string, ratio: number)
		return gauge.new():setRatio(ratio):setLabel(label):setStyle(GRAY):setFilledStyle(WHITE, BLUE):setBlock(
			block
				.new()
				:setBorders({ top = true, bottom = true, left = true, right = true })
				:setBorderSet("rounded")
				:setBorderForegroundColor(DARK_BLUE)
		)
	end

	local function makeSparkline(title: string, data: { number })
		return sparkline.new():setData(data):setStyle(GREEN):setBlock(
			block
				.new()
				:setBorders({ top = true, bottom = true, left = true, right = true })
				:setBorderSet("rounded")
				:addTitle({ text = title, alignment = "left" })
		)
	end

	local nameInput = input
		.new()
		:setText("Ada Lovelace")
		:setCursor(4)
		:setStyle(WHITE, DARK_GRAY)
		:setCursorStyle(DARK_GRAY, WHITE)
		:setBlock(
			block
				.new()
				:setBorders({ top = true, bottom = true, left = true, right = true })
				:setBorderSet("rounded")
				:setBorderForegroundColor(GRAY)
				:addTitle({ text = " Name ", alignment = "left" })
		)

	local passwordInput = input
		.new()
		:setText("hunter2")
		:setMask("●")
		:setCursor(3)
		:setStyle(WHITE, DARK_GRAY)
		:setCursorStyle(DARK_GRAY, WHITE)
		:setBlock(
			block
				.new()
				:setBorders({ top = true, bottom = true, left = true, right = true })
				:setBorderSet("rounded")
				:setBorderForegroundColor(GRAY)
				:addTitle({ text = " Password ", alignment = "left" })
		)

	local emptyInput = input
		.new()
		:setText("")
		:setCursor(1)
		:setPlaceholder("Enter email address…")
		:setCursorStyle(DARK_GRAY, WHITE)
		:setPlaceholderStyle(GRAY)
		:setBlock(
			block
				.new()
				:setBorders({ top = true, bottom = true, left = true, right = true })
				:setBorderSet("rounded")
				:setBorderForegroundColor(GRAY)
				:addTitle({ text = " Email ", alignment = "left" })
		)

	local confirmPopup = popup
		.new()
		:setWidth(44)
		:setHeight(7)
		:setBorderSet("rounded")
		:setBorderForegroundColor(WHITE)
		:addTitle({ text = " Delete Member ", alignment = "center" })

	local confirmText = paragraph
		.new()
		:setText("Are you sure you want to remove\nAlice from the team?\n\n[ Confirm ]   [ Cancel ]")
		:setAlignment("center")
		:setStyle(WHITE)

	tabBar:setSelected(selectedIndex)

	io.stdout:writeSync(step(context, function(fullArea)
		local shellChunks = layout
			.new()
			:setDirection("vertical")
			:setConstraints({ constraint.length(1), constraint.fill(1), constraint.length(1) })
			:split(shellBlock:inner(fullArea))

		local tabArea = shellChunks[1]
		local contentArea = shellChunks[2]
		local statusArea = shellChunks[3]

		local statusBar = paragraph
			.new()
			:setText(
				if #lastKey > 0
					then `last key: {lastKey}  ←/→ switch tabs  q quit`
					else "←/→ switch tabs  q quit"
			)
			:setStyle(GRAY)

		local selected = tabBar.selected

		if selected == 1 then
			return {
				{ widget = shellBlock, area = fullArea },
				{ widget = tabBar, area = tabArea },
				{ widget = peopleTable, area = contentArea },
				{ widget = statusBar, area = statusArea },
			}
		elseif selected == 2 then
			return {
				{ widget = shellBlock, area = fullArea },
				{ widget = tabBar, area = tabArea },
				{ widget = taskList, area = contentArea },
				{ widget = statusBar, area = statusArea },
			}
		elseif selected == 3 then
			local gaugeChunks = layout
				.new()
				:setDirection("vertical")
				:setConstraints({
					constraint.length(3),
					constraint.length(3),
					constraint.length(3),
					constraint.length(3),
				})
				:split(contentArea)

			return {
				{ widget = shellBlock, area = fullArea },
				{ widget = tabBar, area = tabArea },
				{ widget = makeGauge("Build  72%", 0.72), area = gaugeChunks[1] },
				{ widget = makeGauge("Tests  48%", 0.48), area = gaugeChunks[2] },
				{ widget = makeGauge("Deploy 91%", 0.91), area = gaugeChunks[3] },
				{ widget = makeGauge("Uptime 100%", 1.00), area = gaugeChunks[4] },
				{ widget = statusBar, area = statusArea },
			}
		elseif selected == 4 then
			local sparklineChunks = layout
				.new()
				:setDirection("horizontal")
				:setConstraints({ constraint.fill(1), constraint.fill(1) })
				:split(contentArea)

			return {
				{ widget = shellBlock, area = fullArea },
				{ widget = tabBar, area = tabArea },
				{
					widget = makeSparkline("CPU %", {
						12,
						18,
						24,
						30,
						22,
						40,
						55,
						60,
						58,
						70,
						65,
						72,
						68,
						80,
						75,
						90,
						85,
						78,
						60,
						45,
						50,
						55,
						62,
						70,
						66,
						74,
						80,
						72,
						65,
						58,
					}),
					area = sparklineChunks[1],
				},
				{
					widget = makeSparkline("Memory MB", {
						200,
						210,
						215,
						220,
						218,
						225,
						230,
						240,
						238,
						245,
						250,
						260,
						255,
						270,
						265,
						280,
						275,
						268,
						260,
						255,
						258,
						262,
						270,
						278,
						274,
						282,
						290,
						285,
						278,
						272,
					}),
					area = sparklineChunks[2],
				},
				{ widget = statusBar, area = statusArea },
			}
		elseif selected == 5 then
			local inputChunks = layout
				.new()
				:setDirection("vertical")
				:setConstraints({ constraint.length(3), constraint.length(3), constraint.length(3) })
				:split(contentArea)

			return {
				{ widget = shellBlock, area = fullArea },
				{ widget = tabBar, area = tabArea },
				{ widget = nameInput, area = inputChunks[1] },
				{ widget = passwordInput, area = inputChunks[2] },
				{ widget = emptyInput, area = inputChunks[3] },
				{ widget = statusBar, area = statusArea },
			}
		else
			local popupArea = confirmPopup:area(fullArea)

			return {
				{ widget = shellBlock, area = fullArea },
				{ widget = tabBar, area = tabArea },
				{ widget = peopleTable, area = contentArea },
				{ widget = confirmPopup, area = popupArea },
				{ widget = confirmText, area = confirmPopup:inner(popupArea) },
				{ widget = statusBar, area = statusArea },
			}
		end
	end))

	task.wait(0.05)
end

io.stdout:writeSync("\27[?1049l\27[?25h")
io.terminal.restoreMode()
