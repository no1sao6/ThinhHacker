--[[
	============================================================
	 THINHHACKER  |  BLOX FRUITS SCRIPT  (Tiếng Việt)
	 Phiên bản : 1.0.0
	 Kiểu      : Hub auto-farm giống Redz, menu tiếng Việt
	 Yêu cầu   : Executor có loadstring + writefile (Delta, Xeno,
	             Solara, Wave, Codex, Fluxus, AWP...)
	 Cách dùng : dán cả file này vào executor rồi Execute,
	             hoặc loadstring(game:HttpGet("link_raw"))()
	============================================================
	 MỞ FILE NÀY BẰNG NOTEPAD ĐỂ XEM / SỬA DANH SÁCH KEY
	============================================================
]]

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game:IsLoaded()

--==============================================================
-- 0. DỊCH VỤ
--==============================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local VirtualUser       = game:GetService("VirtualUser")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local cloneref = cloneref or function(o) return o end
local getgenv   = getgenv   or function() return _G end

-- dọn phiên bản cũ
if getgenv().ThinhHacker and getgenv().ThinhHacker.Destroy then
	pcall(getgenv().ThinhHacker.Destroy)
end
getgenv().ThinhHacker = { Loaded = true, Version = "1.0.0" }

--==============================================================
-- 1. HỆ THỐNG KEY KÍCH HOẠT
--==============================================================
-- >>> THÊM / SỬA KEY CỦA BẠN Ở ĐÂY <<<
--    ["KEY"] = { days = số ngày hiệu lực, note = ghi chú }
local KEY_LIST = {
	["THINH-VIP-2026"]   = { days = 365, note = "Key VIP 1 năm" },
	["THINH-1THANG"]     = { days = 30,  note = "Key 1 tháng" },
	["THINH-TEST"]       = { days = 1,   note = "Key test 1 ngày" },
	["THINHHACKER-FREE"] = { days = 7,   note = "Key free 7 ngày" },
}

local KEY_FILE = "ThinhHacker_key.txt"

local function getHWID()
	local ok, id = pcall(function() return gethwid() end)
	if ok and type(id) == "string" and #id > 4 then return id end
	ok, id = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
	if ok and type(id) == "string" and #id > 4 then return id end
	return "PC-" .. tostring(LocalPlayer.UserId)
end

local HWID = getHWID()

local function canFile()
	return type(writefile) == "function" and type(readfile) == "function"
end

local function saveKey(key, expire)
	if not canFile() then return end
	pcall(function()
		writefile(KEY_FILE, key .. "|" .. tostring(expire) .. "|" .. HWID)
	end)
end

local function loadSavedKey()
	if not canFile() then return nil end
	if type(isfile) == "function" and not isfile(KEY_FILE) then return nil end
	local ok, data = pcall(readfile, KEY_FILE)
	if not ok or not data then return nil end
	local key, expire, hwid = string.match(data, "^(.-)|(%-?%d+)|(.*)$")
	if not key or not expire then return nil end
	local info = KEY_LIST[key]
	if not info then return nil end
	if tonumber(expire) <= os.time() then return nil end
	if hwid ~= HWID then return nil end
	return key, tonumber(expire)
end

local function validateKey(input)
	local key = tostring(input or ""):gsub("%s", "")
	local info = KEY_LIST[key]
	if not info then return false, nil, "Key không hợp lệ hoặc đã bị xoá!" end
	local expire = os.time() + (info.days * 86400)
	return true, expire, info.note or ""
end

--==============================================================
-- 2. GIAO DIỆN NHẬP KEY
--==============================================================
local Theme = {
	Bg     = Color3.fromRGB(12, 12, 16),
	Panel  = Color3.fromRGB(20, 20, 27),
	Elem   = Color3.fromRGB(27, 27, 36),
	Hover  = Color3.fromRGB(36, 36, 48),
	Accent = Color3.fromRGB(0, 200, 255),
	Accent2= Color3.fromRGB(160, 60, 255),
	Text   = Color3.fromRGB(240, 240, 246),
	Sub    = Color3.fromRGB(145, 145, 162),
	Stroke = Color3.fromRGB(48, 48, 64),
	Ok     = Color3.fromRGB(0, 220, 130),
	Bad    = Color3.fromRGB(255, 70, 90),
}

local F      = Enum.Font.GothamMedium
local F_BOLD = Enum.Font.GothamBold

local function Create(class, props)
	local obj = Instance.new(class)
	if props then
		for k, v in next, props do
			if k ~= "Parent" then
				obj[k] = v
			end
		end
		if props.Parent then obj.Parent = props.Parent end
	end
	return obj
end

local function Corner(inst, r)
	Create("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = inst })
end

local function StrokeIt(inst, color, thick)
	Create("UIStroke", { Color = color or Theme.Stroke, Thickness = thick or 1, Parent = inst })
end

local function makeGui(name)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
	if not ok or not gui.Parent then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	return gui
end

--==============================================================
-- 3. UI LIBRARY (tự dựng, không phụ thuộc Rayfield)
--==============================================================
local Lib = {}

function Lib.newWindow(title, subtitle, destroyFn)
	local gui = makeGui("ThinhHacker_UI")

	local main = Create("Frame", {
		Parent = gui,
		Name = "Main",
		Size = UDim2.fromOffset(620, 440),
		Position = UDim2.new(0.5, -310, 0.5, -220),
		BackgroundColor3 = Theme.Bg,
		BorderSizePixel = 0,
		ClipsDescendants = false,
	})
	Corner(main, 12)
	StrokeIt(main, Color3.fromRGB(60, 60, 85), 1.5)

	-- thanh tiêu đề
	local topbar = Create("Frame", {
		Parent = main,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	Corner(topbar, 12)
	Create("Frame", {
		Parent = topbar, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
	})

	local gradTitle = Create("TextLabel", {
		Parent = topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(0, 300, 1, 0),
		Font = F_BOLD,
		Text = title,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 255, 255),
	})
	Create("UIGradient", {
		Parent = gradTitle,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 220, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 90, 255)),
		}),
	})

	Create("TextLabel", {
		Parent = topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 24),
		Size = UDim2.new(0, 300, 0, 14),
		Font = F,
		Text = subtitle or "",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Sub,
	})

	local closeBtn = Create("TextButton", {
		Parent = topbar,
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -36, 0, 9),
		BackgroundColor3 = Color3.fromRGB(45, 25, 30),
		Text = "✕",
		Font = F_BOLD,
		TextSize = 14,
		TextColor3 = Theme.Bad,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	})
	Corner(closeBtn, 7)

	local minBtn = Create("TextButton", {
		Parent = topbar,
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -68, 0, 9),
		BackgroundColor3 = Theme.Elem,
		Text = "—",
		Font = F_BOLD,
		TextSize = 13,
		TextColor3 = Theme.Sub,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	})
	Corner(minBtn, 7)

	-- kéo cửa sổ
	local dragging, dragInput, dragStart, startPos
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	-- sidebar
	local sidebar = Create("Frame", {
		Parent = main,
		Size = UDim2.new(0, 150, 1, -60),
		Position = UDim2.new(0, 10, 0, 52),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	})
	Corner(sidebar, 10)

	local tabList = Create("ScrollingFrame", {
		Parent = sidebar,
		Size = UDim2.new(1, -8, 1, -16),
		Position = UDim2.new(0, 4, 0, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})
	Create("UIListLayout", {
		Parent = tabList, Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	Create("UIPadding", { Parent = tabList, PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })

	-- vùng nội dung
	local contentHolder = Create("Frame", {
		Parent = main,
		Size = UDim2.new(1, -170, 1, -60),
		Position = UDim2.new(0, 160, 0, 52),
		BackgroundTransparency = 1,
	})

	local tabs, pages = {}, {}
	local selected

	local function selectTab(name)
		if selected == name then return end
		selected = name
		for n, page in next, pages do
			page.Visible = (n == name)
		end
		for n, btn in next, tabs do
			if n == name then
				TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Elem }):Play()
				btn.TextColor3 = Theme.Accent
			else
				TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Panel }):Play()
				btn.TextColor3 = Theme.Sub
			end
		end
	end

	local function tab(name, icon)
		local btn = Create("TextButton", {
			Parent = tabList,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.Panel,
			Text = (icon and (icon .. "  ") or "") .. name,
			Font = F,
			TextSize = 12,
			TextColor3 = Theme.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			BorderSizePixel = 0,
		})
		Corner(btn, 8)
		Create("UIPadding", { Parent = btn, PaddingLeft = UDim.new(0, 10) })

		local page = Create("ScrollingFrame", {
			Parent = contentHolder,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		})
		Create("UIListLayout", {
			Parent = page, Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
		Create("UIPadding", { Parent = page, PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) })

		tabs[name] = btn
		pages[name] = page
		btn.MouseButton1Click:Connect(function() selectTab(name) end)
		btn.MouseEnter:Connect(function()
			if selected ~= name then TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play() end
		end)
		btn.MouseLeave:Connect(function()
			if selected ~= name then TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Panel }):Play() end
		end)
		return page
	end

	local function minimize()
		main.Visible = not main.Visible
	end

	minBtn.MouseButton1Click:Connect(minimize)
	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
		if destroyFn then pcall(destroyFn) end
	end)

	-- phím tắt bật/tắt menu
	local toggleKey = Enum.KeyCode.RightShift
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == toggleKey then minimize() end
	end)

	return {
		Gui = gui,
		Main = main,
		Tab = tab,
		Select = selectTab,
		Destroy = function() gui:Destroy() end,
	}
end

--=========== COMPONENT ============
local function section(page, text)
	local holder = Create("Frame", {
		Parent = page,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
	})
	Create("TextLabel", {
		Parent = holder,
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = F_BOLD,
		Text = text,
		TextSize = 12,
		TextColor3 = Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	Create("Frame", {
		Parent = holder,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = Theme.Stroke,
		BorderSizePixel = 0,
	})
	return holder
end

local function toggle(page, text, default, callback)
	local row = Create("Frame", {
		Parent = page,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Theme.Elem,
		BorderSizePixel = 0,
	})
	Corner(row, 8)
	StrokeIt(row)

	Create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -70, 1, 0),
		Font = F,
		Text = text,
		TextSize = 12,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local knobBg = Create("Frame", {
		Parent = row,
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -50, 0.5, -10),
		BackgroundColor3 = Color3.fromRGB(50, 50, 64),
		BorderSizePixel = 0,
	})
	Corner(knobBg, 10)

	local knob = Create("Frame", {
		Parent = knobBg,
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 3, 0.5, -7),
		BackgroundColor3 = Color3.fromRGB(150, 150, 165),
		BorderSizePixel = 0,
	})
	Corner(knob, 7)

	local state = default and true or false
	local function render()
		if state then
			TweenService:Create(knobBg, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Accent }):Play()
			TweenService:Create(knob, TweenInfo.new(0.15), {
				Position = UDim2.new(0, 21, 0.5, -7),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			}):Play()
		else
			TweenService:Create(knobBg, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(50, 50, 64) }):Play()
			TweenService:Create(knob, TweenInfo.new(0.15), {
				Position = UDim2.new(0, 3, 0.5, -7),
				BackgroundColor3 = Color3.fromRGB(150, 150, 165),
			}):Play()
		end
	end
	render()

	local clickable = Create("TextButton", {
		Parent = row, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
	})
	clickable.MouseButton1Click:Connect(function()
		state = not state
		render()
		if callback then pcall(callback, state) end
	end)
	return {
		Set = function(v)
			state = v and true or false
			render()
		end,
		Get = function() return state end,
	}
end

local function button(page, text, callback, color)
	local btn = Create("TextButton", {
		Parent = page,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Theme.Elem,
		Font = F,
		Text = text,
		TextSize = 12,
		TextColor3 = color or Theme.Text,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	})
	Corner(btn, 8)
	StrokeIt(btn)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Elem }):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		if callback then
			local ok, err = pcall(callback)
			if not ok then warn("[ThinhHacker] " .. tostring(err)) end
		end
	end)
	return btn
end

local function slider(page, text, min, max, default, callback)
	local row = Create("Frame", {
		Parent = page,
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.Elem,
		BorderSizePixel = 0,
	})
	Corner(row, 8)
	StrokeIt(row)

	Create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 4),
		Size = UDim2.new(1, -60, 0, 16),
		Font = F, Text = text, TextSize = 12,
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
	})

	local valLabel = Create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -60, 0, 4),
		Size = UDim2.new(0, 48, 0, 16),
		Font = F_BOLD, Text = tostring(default), TextSize = 12,
		TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right,
	})

	local bar = Create("Frame", {
		Parent = row,
		Size = UDim2.new(1, -24, 0, 5),
		Position = UDim2.new(0, 12, 0, 30),
		BackgroundColor3 = Color3.fromRGB(48, 48, 62),
		BorderSizePixel = 0,
	})
	Corner(bar, 3)

	local fill = Create("Frame", {
		Parent = bar,
		Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
	})
	Corner(fill, 3)

	local value = default
	local dragging = false

	local function setFromX(x)
		local abs = bar.AbsolutePosition.X
		local size = bar.AbsoluteSize.X
		if size <= 0 then return end
		local pct = math.clamp((x - abs) / size, 0, 1)
		value = math.floor(min + (max - min) * pct + 0.5)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		valLabel.Text = tostring(value)
		if callback then pcall(callback, value) end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return {
		Set = function(v)
			value = v
			valLabel.Text = tostring(v)
			fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
			if callback then pcall(callback, v) end
		end,
		Get = function() return value end,
	}
end

local function dropdown(page, text, options, default, callback)
	local holder = Create("Frame", {
		Parent = page,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.Elem,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	Corner(holder, 8)
	StrokeIt(holder)

	local head = Create("TextButton", {
		Parent = holder,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})
	Create("TextLabel", {
		Parent = head,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Font = F, Text = text, TextSize = 12,
		TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Left,
	})
	local cur = Create("TextLabel", {
		Parent = head,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 110, 0, 0),
		Size = UDim2.new(1, -150, 1, 0),
		Font = F_BOLD, Text = tostring(default or (options[1] or "")), TextSize = 12,
		TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right,
	})
	Create("TextLabel", {
		Parent = head,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -30, 0, 0),
		Size = UDim2.new(0, 24, 1, 0),
		Font = F_BOLD, Text = "▾", TextSize = 12,
		TextColor3 = Theme.Sub,
	})

	local list = Create("Frame", {
		Parent = holder,
		Position = UDim2.new(0, 0, 0, 34),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
	})
	Create("UIListLayout", { Parent = list, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder })
	Create("UIPadding", { Parent = list, PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) })

	local open = false
	local selected = default or options[1]

	for _, opt in ipairs(options) do
		local b = Create("TextButton", {
			Parent = list,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Color3.fromRGB(34, 34, 45),
			Font = F, Text = tostring(opt), TextSize = 11,
			TextColor3 = Theme.Text, AutoButtonColor = false, BorderSizePixel = 0,
		})
		Corner(b, 6)
		b.MouseButton1Click:Connect(function()
			selected = opt
			cur.Text = tostring(opt)
			open = false
			TweenService:Create(holder, TweenInfo.new(0.15), { Size = UDim2.new(1, 0, 0, 34) }):Play()
			if callback then pcall(callback, opt) end
		end)
	end

	head.MouseButton1Click:Connect(function()
		open = not open
		local h = open and (34 + (#options * 29) + 8) or 34
		TweenService:Create(holder, TweenInfo.new(0.18), { Size = UDim2.new(1, 0, 0, h) }):Play()
	end)

	return { Get = function() return selected end }
end

local function textbox(page, placeholder, callback)
	local box = Create("Frame", {
		Parent = page,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Theme.Elem,
		BorderSizePixel = 0,
	})
	Corner(box, 8)
	StrokeIt(box)
	local tb = Create("TextBox", {
		Parent = box,
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Font = F, Text = "", PlaceholderText = placeholder,
		PlaceholderColor3 = Theme.Sub,
		TextColor3 = Theme.Text, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	})
	tb.FocusLost:Connect(function(enter)
		if enter and callback then pcall(callback, tb.Text) end
	end)
	return tb
end

--==============================================================
-- 4. THÔNG BÁO
--==============================================================
local notifGui = makeGui("ThinhHacker_Notify")

local function notify(title, text, duration)
	duration = duration or 3
	local holder = Create("Frame", {
		Parent = notifGui,
		Size = UDim2.fromOffset(270, 58),
		Position = UDim2.new(1, 290, 0, 20),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	})
	Corner(holder, 10)
	StrokeIt(holder, Theme.Accent, 1)

	local bar = Create("Frame", {
		Parent = holder,
		Size = UDim2.new(0, 3, 1, -16),
		Position = UDim2.new(0, 8, 0, 8),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
	})
	Corner(bar, 2)

	Create("TextLabel", {
		Parent = holder,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 8),
		Size = UDim2.new(1, -26, 0, 16),
		Font = F_BOLD, Text = title, TextSize = 12,
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
	})
	Create("TextLabel", {
		Parent = holder,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 26),
		Size = UDim2.new(1, -26, 0, 24),
		Font = F, Text = text, TextSize = 11,
		TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	TweenService:Create(holder, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
		Position = UDim2.new(1, -285, 0, 20),
	}):Play()

	task.delay(duration, function()
		TweenService:Create(holder, TweenInfo.new(0.25), {
			Position = UDim2.new(1, 290, 0, 20),
		}):Play()
		task.wait(0.3)
		holder:Destroy()
	end)
end
getgenv().ThinhHacker.Notify = notify

--==============================================================
-- 5. MÀN HÌNH NHẬP KEY
--==============================================================
local function requestKey(onSuccess)
	local gui = makeGui("ThinhHacker_Key")

	local frame = Create("Frame", {
		Parent = gui,
		Size = UDim2.fromOffset(380, 250),
		Position = UDim2.new(0.5, -190, 0.5, -125),
		BackgroundColor3 = Theme.Bg,
		BorderSizePixel = 0,
	})
	Corner(frame, 14)
	StrokeIt(frame, Theme.Accent, 1.5)

	local head = Create("Frame", {
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	Corner(head, 14)
	Create("Frame", {
		Parent = head, Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14),
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
	})

	local title = Create("TextLabel", {
		Parent = head,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 12),
		Size = UDim2.new(1, 0, 0, 20),
		Font = F_BOLD, Text = "THINHHACKER", TextSize = 20,
		TextColor3 = Theme.Text,
	})
	Create("UIGradient", {
		Parent = title,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 220, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 90, 255)),
		}),
	})
	Create("TextLabel", {
		Parent = head,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 36),
		Size = UDim2.new(1, 0, 0, 16),
		Font = F, Text = "Nhập KEY KÍCH HOẠT để sử dụng menu", TextSize = 11,
		TextColor3 = Theme.Sub,
	})

	local box = Create("Frame", {
		Parent = frame,
		Size = UDim2.new(1, -40, 0, 38),
		Position = UDim2.new(0, 20, 0, 78),
		BackgroundColor3 = Theme.Elem,
		BorderSizePixel = 0,
	})
	Corner(box, 8)
	StrokeIt(box)

	local input = Create("TextBox", {
		Parent = box,
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Font = F_BOLD,
		PlaceholderText = "Dán key vào đây...",
		PlaceholderColor3 = Theme.Sub,
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	})

	local status = Create("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 122),
		Size = UDim2.new(1, -40, 0, 16),
		Font = F, Text = "", TextSize = 11,
		TextColor3 = Theme.Bad, TextXAlignment = Enum.TextXAlignment.Left,
	})

	local hwidLabel = Create("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 140),
		Size = UDim2.new(1, -40, 0, 14),
		Font = F, Text = "HWID: " .. string.sub(HWID, 1, 28), TextSize = 10,
		TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Left,
	})

	local activeBtn = Create("TextButton", {
		Parent = frame,
		Size = UDim2.new(1, -40, 0, 40),
		Position = UDim2.new(0, 20, 0, 168),
		BackgroundColor3 = Color3.fromRGB(0, 140, 190),
		Font = F_BOLD, Text = "KÍCH HOẠT", TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		AutoButtonColor = false, BorderSizePixel = 0,
	})
	Corner(activeBtn, 9)
	StrokeIt(activeBtn, Theme.Accent, 1)

	local closeK = Create("TextButton", {
		Parent = frame,
		Size = UDim2.new(0, 60, 0, 22),
		Position = UDim2.new(1, -74, 0, 12),
		BackgroundColor3 = Color3.fromRGB(45, 25, 30),
		Font = F, Text = "Đóng", TextSize = 11,
		TextColor3 = Theme.Bad, AutoButtonColor = false, BorderSizePixel = 0,
	})
	Corner(closeK, 6)

	closeK.MouseButton1Click:Connect(function() gui:Destroy() end)

	local function doActivate()
		local text = input.Text
		if text == nil or text == "" then
			status.TextColor3 = Theme.Bad
			status.Text = "Chưa nhập key kìa bạn!"
			return
		end
		local ok, expire, note = validateKey(text)
		if not ok then
			status.TextColor3 = Theme.Bad
			status.Text = tostring(note or "Key sai!")
			return
		end
		saveKey(text:gsub("%s", ""), expire)
		status.TextColor3 = Theme.Ok
		status.Text = "Kích hoạt thành công! Hạn: " .. os.date("%d/%m/%Y", expire)
		activeBtn.Text = "ĐANG VÀO..."
		task.wait(0.9)
		gui:Destroy()
		onSuccess(text:gsub("%s", ""), expire)
	end

	activeBtn.MouseButton1Click:Connect(doActivate)
	input.FocusLost:Connect(function(enter)
		if enter then doActivate() end
	end)

	return gui
end

--==============================================================
-- 6. HÀM HỖ TRỢ GAME
--==============================================================
local function getChar()
	local c = LocalPlayer.Character
	if c and c:FindFirstChild("HumanoidRootPart") then return c end
	return nil
end

local function getHRP()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart") or nil
end

local function getHum()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid") or nil
end

local function getLevel()
	local data = LocalPlayer:FindFirstChild("Data")
	if data then
		local lv = data:FindFirstChild("Level")
		if lv and lv.Value then return lv.Value end
	end
	local attr = LocalPlayer:GetAttribute("Level")
	if type(attr) == "number" then return attr end
	local ok, v = pcall(function()
		local txt = LocalPlayer.PlayerGui.Main.Level.LevelFrame.Text
		return tonumber(string.match(txt, "%d+"))
	end)
	if ok and v then return v end
	return 1
end

local function getEnemies()
	local out = {}
	local folder = Workspace:FindFirstChild("Enemies")
	if not folder then return out end
	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") then
			local hum = m:FindFirstChildOfClass("Humanoid")
			local root = m:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				table.insert(out, { model = m, hum = hum, root = root, name = m.Name })
			end
		end
	end
	return out
end

local function findNearestEnemy(range, nameFilter)
	local hrp = getHRP()
	if not hrp then return nil end
	local best, bestDist = nil, range or 5000
	for _, e in ipairs(getEnemies()) do
		if not nameFilter or e.name == nameFilter then
			local d = (e.root.Position - hrp.Position).Magnitude
			if d < bestDist then
				best, bestDist = e, d
			end
		end
	end
	return best
end

local function tpTo(cf)
	local char = getChar()
	if not char then return false end
	pcall(function() char:PivotTo(cf) end)
	return true
end

local function equipMelee()
	local char = getChar()
	if not char then return end
	for _, t in ipairs(char:GetChildren()) do
		if t:IsA("Tool") then return t end
	end
	local bp = LocalPlayer:FindFirstChild("Backpack")
	if bp then
		local hum = getHum()
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and hum then
				pcall(function() hum:EquipTool(t) end)
				return t
			end
		end
	end
end

local function attack(enemy)
	local char = getChar()
	if not char or not enemy or not enemy.root then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- đứng sát quái
	pcall(function()
		char:PivotTo(enemy.root.CFrame * CFrame.new(0, 0, 2.5))
	end)

	-- vũ khí cận chiến
	local tool = equipMelee()
	if tool then pcall(function() tool:Activate() end) end

	-- chạm (nếu executor hỗ trợ)
	if firetouchinterest then
		pcall(function()
			firetouchinterest(hrp, enemy.root, 0)
			firetouchinterest(hrp, enemy.root, 1)
		end)
	end

	-- click ảo
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton1(Vector2.new(0, 0))
	end)
end

-- vòng lặp chung
local Loops = {}
local function setLoop(name, fn)
	if fn then Loops[name] = fn else Loops[name] = nil end
end

RunService.Heartbeat:Connect(function()
	for name, fn in next, Loops do
		local ok, err = pcall(fn)
		if not ok then
			Loops[name] = nil
			notify("Lỗi", name .. ": " .. tostring(err), 4)
		end
	end
end)

--==============================================================
-- 7. DỮ LIỆU NHIỆM VỤ / ĐẢO / BOSS
--==============================================================
local QUESTS = {
	{ lv = 1,    name = "Bandit" },
	{ lv = 5,    name = "Monkey" },
	{ lv = 10,   name = "Gorilla" },
	{ lv = 15,   name = "Pirate" },
	{ lv = 30,   name = "Brute" },
	{ lv = 35,   name = "Desert Bandit" },
	{ lv = 40,   name = "Desert Officer" },
	{ lv = 55,   name = "Snow Bandit" },
	{ lv = 60,   name = "Snowman" },
	{ lv = 75,   name = "Chief Petty Officer" },
	{ lv = 90,   name = "Sky Bandit" },
	{ lv = 105,  name = "Dark Master" },
	{ lv = 120,  name = "Prisoner" },
	{ lv = 125,  name = "Dangerous Prisoner" },
	{ lv = 150,  name = "Toga Warrior" },
	{ lv = 175,  name = "Gladiator" },
	{ lv = 190,  name = "Military Soldier" },
	{ lv = 200,  name = "Military Spy" },
	{ lv = 225,  name = "Fishman Warrior" },
	{ lv = 250,  name = "Fishman Commando" },
	{ lv = 275,  name = "God's Guard" },
	{ lv = 300,  name = "Shanda" },
	{ lv = 325,  name = "Royal Squad" },
	{ lv = 350,  name = "Royal Soldier" },
	{ lv = 375,  name = "Galley Pirate" },
	{ lv = 400,  name = "Galley Captain" },
	{ lv = 425,  name = "Raider" },
	{ lv = 450,  name = "Mercenary" },
	{ lv = 475,  name = "Advanced Raider" },
	{ lv = 500,  name = "Fighter" },
	{ lv = 525,  name = "Sky Fighter" },
	{ lv = 550,  name = "Reborn Skeleton" },
	{ lv = 575,  name = "Living Zombie" },
	{ lv = 600,  name = "Demonic Soul" },
	{ lv = 625,  name = "Posessed Mummy" },
	{ lv = 650,  name = "Snow Trooper" },
	{ lv = 675,  name = "Winter Warrior" },
	{ lv = 700,  name = "Cursed Skeleton" },
	{ lv = 725,  name = "Ancient Vessel" },
	{ lv = 750,  name = "Reanimated Skeleton" },
	{ lv = 775,  name = "Soul Reaper" },
	{ lv = 800,  name = "Haunted Pirate" },
	{ lv = 850,  name = "Pirate Millionaire" },
	{ lv = 900,  name = "Pistol Billionaire" },
	{ lv = 950,  name = "Dragon Crew Archer" },
	{ lv = 1000, name = "Dragon Crew Warrior" },
	{ lv = 1050, name = "Hydra Enforcer" },
	{ lv = 1100, name = "Stone Pirate" },
	{ lv = 1150, name = "Lab Assistant" },
	{ lv = 1200, name = "Fenrir" },
	{ lv = 1250, name = "Reborn Pirate" },
	{ lv = 1300, name = "Reborn Soldier" },
	{ lv = 1350, name = "Marine Captain" },
	{ lv = 1400, name = "Marine Lieutenant" },
	{ lv = 1450, name = "Marine Commander" },
	{ lv = 1500, name = "Titanic Pirate" },
}

local BOSSES = {
	"Don Swan", "Cursed Captain", "rip_indra True Form", "Greybeard",
	"The Strongest", "Fajita", "Kilo Admiral", "Ice Admiral",
	"Longma", "Kitsune", "Dough King", "Soul Reaper",
}

local ISLANDS = {
	"Starter Island", "Marine Fortress", "Jungle", "Desert", "Snow Island",
	"Marineford", "Sky Island", "Prison", "Colosseum", "Underwater City",
	"Kingdom of Rose", "Green Zone", "Graveyard", "Haunted Castle",
	"Snow Mountain", "Hot and Cold", "Cursed Ship", "Ice Castle",
	"Forgotten Island", "Port Town", "Hydra Island", "Great Tree",
	"Floating Turtle", "Haunted Castle", "Castle on the Sea",
	"Tiki Outpost", "Mansion", "Remote Island", "Sea of Treats",
}

--==============================================================
-- 8. CHỨC NĂNG
--==============================================================
local Flags = {}
local Settings = {
	farmRange = 300,
	tpOffset  = 3,
	speed     = 16,
	jump      = 50,
	flySpeed  = 60,
}

local function currentQuest()
	local lvl = getLevel()
	local pick = QUESTS[1]
	for _, q in ipairs(QUESTS) do
		if lvl >= q.lv then pick = q end
	end
	return pick
end

local function startQuest()
	local q = currentQuest()
	if not q then return end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local commF = remotes and remotes:FindFirstChild("CommF_")
	if not commF then return end
	pcall(function() commF:InvokeServer("StartQuest", q.name, q.lv) end)
end

local function isQuestActive()
	local ok, res = pcall(function()
		local q = LocalPlayer.PlayerGui.Main.Quest
		return q and q.Visible
	end)
	return ok and res
end

-- Auto Farm Level
local lastAttack, lastQuestTry = 0, 0
local function startAutoFarm()
	setLoop("AutoFarm", function()
		local hrp = getHRP()
		if not hrp then return end
		local now = os.clock()

		if Flags.AutoQuest and now - lastQuestTry > 1.5 then
			lastQuestTry = now
			if not isQuestActive() then
				startQuest()
				return
			end
		end

		-- giới hạn 10 lần/giây cho đỡ lag
		if now - lastAttack < 0.1 then return end
		lastAttack = now

		local target = findNearestEnemy(Settings.farmRange)
		if not target then
			target = findNearestEnemy(100000) -- không có gần -> tới quái gần nhất map
		end
		if target then attack(target) end
	end)
end

-- Auto Chest
local function startAutoChest()
	setLoop("AutoChest", function()
		local hrp = getHRP()
		if not hrp then return end
		local best, bestDist = nil, 99999
		for _, obj in ipairs(Workspace:GetChildren()) do
			if obj.Name == "Chest" then
				local part = obj:IsA("BasePart") and obj
					or obj:FindFirstChild("HumanoidRootPart")
					or obj:FindFirstChild("Handle")
					or obj:FindFirstChildWhichIsA("BasePart")
				if part then
					local d = (part.Position - hrp.Position).Magnitude
					if d < bestDist then best, bestDist = part, d end
				end
			end
		end
		if best then
			tpTo(CFrame.new(best.Position + Vector3.new(0, 3, 0)))
			local prompt = best:FindFirstChildOfClass("ProximityPrompt")
			if prompt and fireproximityprompt then
				pcall(fireproximityprompt, prompt)
			end
		end
	end)
end

-- Auto Fruit
local function startAutoFruit()
	setLoop("AutoFruit", function()
		local hrp = getHRP()
		if not hrp then return end
		for _, obj in ipairs(Workspace:GetChildren()) do
			if (obj:IsA("Tool") or obj:IsA("Model")) and string.find(obj.Name, "Fruit", 1, true) then
				local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
				if handle then
					tpTo(CFrame.new(handle.Position + Vector3.new(0, 2, 0)))
					local prompt = handle:FindFirstChildOfClass("ProximityPrompt")
					if prompt and fireproximityprompt then
						pcall(fireproximityprompt, prompt)
					end
				end
			end
		end
	end)
end

-- Auto Boss
local function startAutoBoss(bossName)
	setLoop("AutoBoss", function()
		local now = os.clock()
		if now - lastAttack < 0.1 then return end
		lastAttack = now
		local e = findNearestEnemy(100000, bossName)
		if e then attack(e) end
	end)
end

-- Auto Haki
local function startAutoHaki()
	setLoop("AutoHaki", function()
		local char = getChar()
		if not char then return end
		local bp = LocalPlayer:FindFirstChild("Backpack")
		if bp then
			for _, t in ipairs(bp:GetChildren()) do
				if t:IsA("Tool") and (string.find(t.Name, "Buso") or string.find(t.Name, "Haki")) then
					local hum = getHum()
					if hum then pcall(function() hum:EquipTool(t) end) end
					pcall(function() t:Activate() end)
					break
				end
			end
		end
	end)
end

-- Auto Skill
local function startAutoSkill()
	setLoop("AutoSkill", function()
		if not getChar() then return end
		local now = os.clock()
		if now - (Flags.lastSkill or 0) < 0.5 then return end
		Flags.lastSkill = now
		if type(keypress) == "function" and type(keyrelease) == "function" then
			for _, k in ipairs({ 0x5A, 0x58, 0x43, 0x56 }) do -- Z X C V
				pcall(keypress, k)
				pcall(keyrelease, k)
			end
		end
	end)
end

-- Noclip
local function setNoclip(state)
	if state then
		setLoop("Noclip", function()
			local char = getChar()
			if not char then return end
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end)
	else
		setLoop("Noclip", nil)
	end
end

-- Fly
local function setFly(state)
	if state then
		setLoop("Fly", function()
			local char = getChar()
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			if not hrp:FindFirstChild("TH_Fly") then
				local bv = Instance.new("BodyVelocity")
				bv.Name = "TH_Fly"
				bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
				bv.Parent = hrp
			end
			local bv = hrp.TH_Fly
			local dir = Vector3.new(0, 0, 0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + workspace.CurrentCamera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - workspace.CurrentCamera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - workspace.CurrentCamera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + workspace.CurrentCamera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
			bv.Velocity = dir.Magnitude > 0 and dir.Unit * Settings.flySpeed or Vector3.new(0, 0, 0)
		end)
	else
		setLoop("Fly", nil)
		local hrp = getHRP()
		if hrp and hrp:FindFirstChild("TH_Fly") then hrp.TH_Fly:Destroy() end
	end
end

-- ESP
local function clearESP()
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v.Name == "TH_ESP" then pcall(function() v:Destroy() end) end
		if v.Name == "TH_HL" and v:IsA("Highlight") then pcall(function() v:Destroy() end) end
	end
end

local function addESP(obj, root, color, label)
	if obj:FindFirstChild("TH_ESP") then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "TH_ESP"
	bb.Size = UDim2.fromOffset(200, 40)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Parent = obj

	local txt = Instance.new("TextLabel")
	txt.Parent = bb
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.TextColor3 = color
	txt.TextStrokeTransparency = 0
	txt.TextScaled = false
	txt.TextSize = 13
	txt.Font = F_BOLD
	txt.Text = label
end

local function setESPPlayers(state)
	if not state then
		clearESP()
		return
	end
	setLoop("ESPPlayers", function()
		local myRoot = getHRP()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				local hrp = p.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local dist = myRoot and math.floor((hrp.Position - myRoot.Position).Magnitude) or 0
					local node = p.Character:FindFirstChild("TH_ESP")
					if node then
						local lbl = node:FindFirstChildOfClass("TextLabel")
						if lbl then lbl.Text = p.Name .. " [" .. dist .. "m]" end
					else
						addESP(p.Character, hrp, Color3.fromRGB(0, 220, 255), p.Name .. " [" .. dist .. "m]")
					end
				end
			end
		end
	end)
end

local function setESPMobs(state)
	if not state then
		for _, m in ipairs(getEnemies()) do
			local n = m.model:FindFirstChild("TH_ESP")
			if n then n:Destroy() end
		end
		return
	end
	setLoop("ESPMobs", function()
		for _, m in ipairs(getEnemies()) do
			local node = m.model:FindFirstChild("TH_ESP")
			if not node then
				addESP(m.model, m.root, Color3.fromRGB(255, 80, 80),
					m.name .. " [" .. math.floor(m.hum.Health) .. "HP]")
			else
				local lbl = node:FindFirstChildOfClass("TextLabel")
				if lbl then lbl.Text = m.name .. " [" .. math.floor(m.hum.Health) .. "HP]" end
			end
		end
	end)
end

-- Full bright
local origLight = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	Ambient = Lighting.Ambient,
}

local function setFullBright(state)
	if state then
		Lighting.Brightness = 2
		Lighting.ClockTime = 12
		Lighting.FogEnd = 100000
		Lighting.Ambient = Color3.fromRGB(200, 200, 200)
	else
		Lighting.Brightness = origLight.Brightness
		Lighting.ClockTime = origLight.ClockTime
		Lighting.FogEnd = origLight.FogEnd
		Lighting.Ambient = origLight.Ambient
	end
end

-- Teleport tới địa danh theo tên
local function tpToName(keyword)
	local hrp = getHRP()
	if not hrp then return false end
	local kw = string.lower(keyword)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local n = string.lower(obj.Name)
			if string.find(n, kw, 1, true) then
				tpTo(CFrame.new(obj.Position + Vector3.new(0, 5, 0)))
				return true
			end
		end
	end
	return false
end

-- Server hop
local function hopServer()
	local ok, res = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(
			"https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
		))
	end)
	if ok and res and res.data then
		local list = {}
		for _, s in ipairs(res.data) do
			if s.playing < s.maxPlayers and s.id ~= game.JobId then
				table.insert(list, s.id)
			end
		end
		if #list > 0 then
			local id = list[math.random(1, #list)]
			pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LocalPlayer) end)
			return true
		end
	end
	return false
end

--==============================================================
-- 9. KHỞI ĐỘNG MENU CHÍNH
--==============================================================
local function buildMenu(usedKey, expire)
	local win = Lib.newWindow("THINHHACKER", "Blox Fruits • " .. os.date("%d/%m/%Y", expire) .. " • Key: " .. string.sub(usedKey, 1, 6) .. "***",
		function()
			getgenv().ThinhHacker.Loaded = false
			Loops = {}
			pcall(clearESP)
			pcall(setFullBright, false)
			local hrp = getHRP()
			if hrp and hrp:FindFirstChild("TH_Fly") then hrp.TH_Fly:Destroy() end
		end)

	getgenv().ThinhHacker.Destroy = function()
		Loops = {}
		pcall(clearESP)
		win.Destroy()
	end

	--========================= FARM =========================
	local farm = win.Tab("Farm", "🌾")
	win.Select("Farm")

	section(farm, "AUTO FARM")
	toggle(farm, "Auto Farm Level (tự nhận nhiệm vụ)", false, function(s)
		Flags.AutoFarm = s
		if s then startAutoFarm() else setLoop("AutoFarm", nil) end
	end)
	toggle(farm, "Tự động nhận nhiệm vụ", true, function(s) Flags.AutoQuest = s end)
	toggle(farm, "Auto Farm Rương (Chest)", false, function(s)
		if s then startAutoChest() else setLoop("AutoChest", nil) end
	end)
	toggle(farm, "Auto Farm Trái Ác Quỷ", false, function(s)
		if s then startAutoFruit() else setLoop("AutoFruit", nil) end
	end)
	toggle(farm, "Auto Bật Haki", false, function(s)
		if s then startAutoHaki() else setLoop("AutoHaki", nil) end
	end)
	toggle(farm, "Auto Dùng Chiêu (Z X C V)", false, function(s)
		if s then startAutoSkill() else setLoop("AutoSkill", nil) end
	end)

	section(farm, "AUTO BOSS")
	local bossPick = dropdown(farm, "Chọn Boss", BOSSES, "Don Swan", function(v) Flags.BossName = v end)
	Flags.BossName = "Don Swan"
	toggle(farm, "Auto Farm Boss", false, function(s)
		if s then
			startAutoBoss(Flags.BossName or "Don Swan")
		else
			setLoop("AutoBoss", nil)
		end
	end)

	section(farm, "CÀI ĐẶT FARM")
	slider(farm, "Phạm vi tìm quái", 50, 1000, 300, function(v) Settings.farmRange = v end)

	--========================= NHÂN VẬT =========================
	local chr = win.Tab("Nhân vật", "⚔️")
	section(chr, "DI CHUYỂN")
	local spd = slider(chr, "Tốc độ chạy", 16, 300, 16, function(v)
		Settings.speed = v
		local hum = getHum()
		if hum then hum.WalkSpeed = v end
	end)
	slider(chr, "Độ cao nhảy", 50, 300, 50, function(v)
		Settings.jump = v
		local hum = getHum()
		if hum then hum.JumpPower = v end
	end)

	section(chr, "HACK NHÂN VẬT")
	toggle(chr, "Bay (W A S D + Space)", false, function(s) setFly(s) end)
	toggle(chr, "Xuyên vật thể (Noclip)", false, function(s) setNoclip(s) end)
	slider(chr, "Tốc độ bay", 20, 250, 60, function(v) Settings.flySpeed = v end)

	Flags.KeepStats = true
	setLoop("KeepStats", function()
		local hum = getHum()
		if not hum then return end
		if Flags.KeepStats then
			if math.abs(hum.WalkSpeed - Settings.speed) > 0.5 then hum.WalkSpeed = Settings.speed end
			if math.abs(hum.JumpPower - Settings.jump) > 0.5 then hum.JumpPower = Settings.jump end
		end
	end)
	toggle(chr, "Giữ tốc độ/nhảy sau khi hồi sinh", true, function(s) Flags.KeepStats = s end)

	button(chr, "Hồi tốc độ mặc định", function()
		local hum = getHum()
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
			spd.Set(16)
		end
	end)

	--========================= TELEPORT =========================
	local tp = win.Tab("Dịch chuyển", "🗺️")
	section(tp, "ĐI TỚI ĐẢO")
	local islandPick = dropdown(tp, "Chọn đảo", ISLANDS, "Starter Island")
	button(tp, "Dịch chuyển tới đảo đã chọn", function()
		local name = islandPick.Get()
		if tpToName(name) then
			notify("ThinhHacker", "Đã tới: " .. tostring(name))
		else
			notify("ThinhHacker", "Không tìm thấy đảo: " .. tostring(name))
		end
	end)

	section(tp, "ĐI TỚI BOSS / QUÁI")
	local bossTP = dropdown(tp, "Chọn Boss", BOSSES, "Don Swan")
	button(tp, "Dịch chuyển tới Boss", function()
		local e = findNearestEnemy(100000, bossTP.Get())
		if e then
			tpTo(e.root.CFrame * CFrame.new(0, 0, 5))
			notify("ThinhHacker", "Đã tới: " .. bossTP.Get())
		else
			notify("ThinhHacker", "Boss chưa xuất hiện trên map này")
		end
	end)

	section(tp, "TIỆN ÍCH")
	button(tp, "Về điểm hồi sinh (Spawn)", function()
		local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
		if spawn then
			tpTo(CFrame.new(spawn.Position + Vector3.new(0, 5, 0)))
			notify("ThinhHacker", "Đã về điểm hồi sinh")
		else
			local char = getChar()
			if char and LocalPlayer.RespawnLocation then
				tpTo(CFrame.new(LocalPlayer.RespawnLocation.Position + Vector3.new(0, 5, 0)))
			else
				notify("ThinhHacker", "Không tìm thấy điểm hồi sinh")
			end
		end
	end)
	button(tp, "Dịch chuyển tới chuột (nhìn vào chỗ cần tới)", function()
		local mouse = LocalPlayer:GetMouse()
		if mouse and mouse.Hit then
			tpTo(mouse.Hit + Vector3.new(0, 3, 0))
		end
	end)

	--========================= HIỂN THỊ =========================
	local vis = win.Tab("Hiển thị", "👁️")
	section(vis, "ESP")
	toggle(vis, "ESP Người chơi (tên + khoảng cách)", false, function(s) setESPPlayers(s) end)
	toggle(vis, "ESP Quái (máu)", false, function(s) setESPMobs(s) end)

	section(vis, "ÁNH SÁNG")
	toggle(vis, "Full Bright (nhìn rõ mọi nơi)", false, function(s) setFullBright(s) end)
	button(vis, "Xoá sương mù", function()
		for _, v in ipairs(Lighting:GetChildren()) do
			if v:IsA("Atmosphere") then
				pcall(function() v:Destroy() end)
			end
		end
		Lighting.FogEnd = 100000
		notify("ThinhHacker", "Đã xoá sương mù")
	end)

	--========================= SERVER =========================
	local srv = win.Tab("Server", "🌐")
	section(srv, "SERVER")
	button(srv, "Đổi server (Hop)", function()
		notify("ThinhHacker", "Đang tìm server mới...")
		if not hopServer() then
			notify("ThinhHacker", "Không tìm được server, thử lại sau")
		end
	end)
	button(srv, "Vào lại server hiện tại", function()
		pcall(function()
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end)
	end)

	local info = Create("TextLabel", {
		Parent = srv,
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = Theme.Elem,
		Font = F,
		Text = "",
		TextSize = 11,
		TextColor3 = Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BorderSizePixel = 0,
	})
	Corner(info, 8)
	Create("UIPadding", { Parent = info, PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 8) })
	info.Text = "  Người chơi: " .. #Players:GetPlayers() ..
		"  |  Server: " .. string.sub(game.JobId, 1, 8) ..
		"  |  Ping: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. "ms"

	--========================= CÀI ĐẶT =========================
	local set = win.Tab("Cài đặt", "⚙️")
	section(set, "HIỆU NĂNG")
	button(set, "Mở khoá FPS (lên 240)", function()
		if setfpscap then
			setfpscap(240)
			notify("ThinhHacker", "Đã mở khoá FPS")
		else
			notify("ThinhHacker", "Executor không hỗ trợ")
		end
	end)

	section(set, "CẤU HÌNH")
	button(set, "Lưu cấu hình", function()
		if type(writefile) ~= "function" then
			notify("ThinhHacker", "Executor không hỗ trợ lưu file")
			return
		end
		local data = {
			farmRange = Settings.farmRange,
			flySpeed  = Settings.flySpeed,
			speed     = Settings.speed,
			jump      = Settings.jump,
		}
		pcall(function() writefile("ThinhHacker_config.json", HttpService:JSONEncode(data)) end)
		notify("ThinhHacker", "Đã lưu cấu hình")
	end)
	button(set, "Tải cấu hình", function()
		if type(readfile) ~= "function" then return end
		local ok, raw = pcall(readfile, "ThinhHacker_config.json")
		if not ok or not raw then
			notify("ThinhHacker", "Chưa có cấu hình đã lưu")
			return
		end
		local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if ok2 and data then
			Settings.farmRange = data.farmRange or Settings.farmRange
			Settings.flySpeed  = data.flySpeed or Settings.flySpeed
			Settings.speed     = data.speed or Settings.speed
			Settings.jump      = data.jump or Settings.jump
			notify("ThinhHacker", "Đã tải cấu hình")
		end
	end)

	section(set, "THÔNG TIN")
	button(set, "Tắt toàn bộ chức năng", function()
		Flags.AutoFarm = false
		Flags.AutoQuest = false
		Loops = {}
		setFly(false)
		setNoclip(false)
		clearESP()
		setFullBright(false)
		local hum = getHum()
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
		end
		notify("ThinhHacker", "Đã tắt hết chức năng")
	end)
	button(set, "Đóng menu (RightShift để mở lại)", function()
		win.Main.Visible = false
	end)

	section(set, "PHÍM TẮT")
	local help = Create("TextLabel", {
		Parent = set,
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.Elem,
		Font = F, Text = "  RightShift : ẩn / hiện menu\n  Nút — trên thanh tiêu đề : thu nhỏ",
		TextSize = 11, TextColor3 = Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true, BorderSizePixel = 0,
	})
	Corner(help, 8)

	notify("ThinhHacker", "Đã kích hoạt! Chúc bạn chơi vui 🎮", 4)
end

--==============================================================
-- 10. LUỒNG KHỞI CHẠY
--==============================================================
local savedKey, savedExpire = loadSavedKey()
if savedKey and savedExpire then
	buildMenu(savedKey, savedExpire)
else
	requestKey(function(key, expire)
		buildMenu(key, expire)
	end)
end
