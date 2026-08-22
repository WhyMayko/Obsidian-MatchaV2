local GalaxObsidian = {}
GalaxObsidian.Repo = "https://raw.githubusercontent.com/WhyMayko/Obsidian-MatchaV2/refs/heads/main/"
local drawingMeta = setmetatable({}, { __mode = "k" })

-- Bootstrap
GalaxObsidian.Version = "1.0.0"

-- Public State
GalaxObsidian.ImageCache = GalaxObsidian.ImageCache or {}

GalaxObsidian.TransparencyTextureUrl =
    "https://raw.githubusercontent.com/WhyMayko/Obsidian-MatchaV2/refs/heads/main/assets/TransparencyTexture.png"
GalaxObsidian.SaturationTextureUrl =
    "https://raw.githubusercontent.com/WhyMayko/Obsidian-MatchaV2/refs/heads/main/assets/SaturationMap.png"
GalaxObsidian.LucideIconUrl =
    "https://raw.githubusercontent.com/WhyMayko/Obsidian-MatchaV2/refs/heads/main/assets/icons/lucide/"

GalaxObsidian.Options = {}
GalaxObsidian.Toggles = {}

GalaxObsidian.Unloaded = false
GalaxObsidian.UnloadCallbacks = {}

GalaxObsidian.NotifySide = "Right"
GalaxObsidian.CornerRadius = 4
GalaxObsidian.DPIScale = 100
GalaxObsidian.ShowToggleFrameInKeybinds = true
GalaxObsidian.Font = Drawing.Fonts.Monospace

local Theme

local TextManager = { TextChars = {} }
local measureProbe
local glyphWidths = {}
local keyNames = { [1] = "M1", [2] = "M2", [4] = "M3", [8] = "Back", [9] = "Tab", [13] = "Enter", [16] = "Shift", [17] = "Ctrl", [18] = "Alt", [27] = "Esc", [32] = "Space", [33] = "PageUp", [34] = "PageDown", [35] = "End", [36] = "Home", [37] = "Left", [38] = "Up", [39] = "Right", [40] = "Down", [45] = "Insert", [46] = "Delete" }
for key = 48, 57 do TextManager.TextChars[key] = string.char(key); keyNames[key] = string.char(key) end
for key = 65, 90 do TextManager.TextChars[key] = string.char(key + 32); keyNames[key] = string.char(key) end
local function glyphWidth(size)
    size = math.max(1, math.floor(tonumber(size) or 13))
    if glyphWidths[size] then return glyphWidths[size] end
    if not measureProbe then
        local ok, probe = pcall(Drawing.new, "Text")
        if ok then measureProbe = probe end
    end
    if measureProbe then
        measureProbe.Text = "M"
        measureProbe.Size = size
        measureProbe.Font = Drawing.Fonts.Monospace
        measureProbe.Position = Vector2.new(-10000, -10000)
        measureProbe.Visible = true
        local bounds = measureProbe.TextBounds
        if bounds and bounds.X and bounds.X > 0 then
            glyphWidths[size] = bounds.X
            return bounds.X
        end
    end
    glyphWidths[size] = size * 0.6
    return glyphWidths[size]
end
function TextManager:Measure(text, size, _, scale)
    size = scale and math.floor((size or 13) * scale + 0.5) or (size or 13)
    return #tostring(text or "") * glyphWidth(size)
end
function TextManager:Fit(text, maxWidth, size, _, scale)
    text = tostring(text or "")
    if not maxWidth or maxWidth <= 0 then return "" end
    size = scale and math.floor((size or 13) * scale + 0.5) or (size or 13)
    local width = glyphWidth(size)
    if #text * width <= maxWidth then return text end
    local suffix = "..."
    local count = math.max(0, math.floor(maxWidth / width) - #suffix)
    return text:sub(1, count) .. suffix
end
function TextManager:KeyName(key)
    local number = tonumber(key)
    if not number then return tostring(key or "None") end
    if number >= 112 and number <= 135 then return "F" .. tostring(number - 111) end
    return keyNames[number] or string.format("0x%02X", number)
end
function TextManager:FormatKeybind(key, label, mode)
    local text = "[" .. self:KeyName(key) .. "]"
    if label and label ~= "" then text = text .. " " .. tostring(label) end
    if mode and mode ~= "" then text = text .. " (" .. tostring(mode) .. ")" end
    return text
end
function TextManager:RenderInput(window, value, placeholder, x, y, width, options)
    options = options or {}
    local empty = value == nil or value == ""
    local text = empty and tostring(placeholder or "") or tostring(value)
    local size = options.Size or 13
    local fitted = self:Fit(text, width, size, nil, window:GetScale())
    local color = options.Disabled and options.DisabledColor or (empty and options.PlaceholderColor or options.Color)
    local textWidth = self:Measure(fitted, size, nil, window:GetScale())
    local align = tostring(options.Align or options.align or "Left"):lower()
    local tx = align == "right" and x + width - textWidth or (align == "center" or align == "centre") and x + (width - textWidth) / 2 or x
    window:_text(fitted, tx, y, color, size, Drawing.Fonts.Monospace, false, options.Outline ~= false, options.ZIndex or 1)
    if options.Focused and not options.Disabled and math.floor(tick() * 2) % 2 == 0 then
        local caretX = tx + math.min(width, textWidth + 2)
        local caretH = math.floor(size * window:GetScale() + 0.5)
        window:_line(caretX, y + 1, caretX, y + caretH + 1, color, 1, (options.ZIndex or 1) + 1)
    end
    return fitted
end

local AnimationManager = {}

AnimationManager.Version = "0.1.0"
AnimationManager.DefaultSpeed = 14

local function now()
	if type(tick) == "function" then
		return tick()
	end
	return os.clock()
end

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function colorComponents(color)
	return color.R or color.r or 0, color.G or color.g or 0, color.B or color.b or 0
end

local function valueKind(value)
	if type(value) == "number" then
		return "number"
	end
	if typeof then
		local kind = typeof(value)
		if kind == "Color3" or kind == "Vector2" or kind == "Vector3" then
			return kind
		end
	end
	if type(value) == "table" then
		if value.R or value.r then
			return "Color3"
		end
		if value.X and value.Y and value.Z then
			return "Vector3"
		end
		if value.X and value.Y then
			return "Vector2"
		end
	end
	return type(value)
end

function AnimationManager:Lerp(fromValue, toValue, alpha)
	alpha = clamp(alpha or 0, 0, 1)
	local kind = valueKind(toValue)

	if kind == "number" then
		return fromValue + (toValue - fromValue) * alpha
	end

	if kind == "Color3" and Color3 ~= nil and Color3.new then
		local fr, fg, fb = colorComponents(fromValue)
		local tr, tg, tb = colorComponents(toValue)
		return Color3.new(fr + (tr - fr) * alpha, fg + (tg - fg) * alpha, fb + (tb - fb) * alpha)
	end

	if kind == "Vector2" and Vector2 ~= nil and Vector2.new then
		return Vector2.new(fromValue.X + (toValue.X - fromValue.X) * alpha, fromValue.Y + (toValue.Y - fromValue.Y) * alpha)
	end

	if kind == "Vector3" and Vector3 ~= nil and Vector3.new then
		return Vector3.new(fromValue.X + (toValue.X - fromValue.X) * alpha, fromValue.Y + (toValue.Y - fromValue.Y) * alpha, fromValue.Z + (toValue.Z - fromValue.Z) * alpha)
	end

	return toValue
end

function AnimationManager:Approach(owner, key, target, speed)
	if owner == nil or key == nil then
		return target
	end

	owner._animations = owner._animations or {}
	key = tostring(key)

	local timeNow = now()
	local kind = valueKind(target)
	local state = owner._animations[key]

	if not state or state.kind ~= kind then
		state = {
			kind = kind,
			value = target,
			target = target,
			time = timeNow,
		}
		owner._animations[key] = state
		return target
	end

	local dt = clamp(timeNow - (state.time or timeNow), 0, 0.1)
	state.time = timeNow
	state.target = target

	local alpha = 1 - math.exp(-(speed or self.DefaultSpeed) * dt)
	state.value = self:Lerp(state.value, target, alpha)
	return state.value
end

AnimationManager.Tween = AnimationManager.Approach

function AnimationManager:Color(owner, key, target, speed)
	return self:Approach(owner, key, target, speed)
end

function AnimationManager:Number(owner, key, target, speed)
	return self:Approach(owner, key, target, speed)
end

function AnimationManager:Vector2(owner, key, target, speed)
	return self:Approach(owner, key, target, speed)
end

function AnimationManager:Vector3(owner, key, target, speed)
	return self:Approach(owner, key, target, speed)
end

function AnimationManager:Reset(owner, key)
	if not owner or not owner._animations then
		return
	end
	if key == nil then
		owner._animations = {}
	else
		owner._animations[tostring(key)] = nil
	end
end

local DialogManager = {}

function DialogManager:SetLibrary(library)
	self.Library = library
	self.TextManager = library and library.TextManager
end

function DialogManager:Dialog(options)
	options = options or {}
	local Library = self.Library
	local win = Library and Library.ActiveWindow
	if not win then
		error("DialogManager: no active window", 2)
	end

	local dialog = {
		id = options.Index or options.Id or options.id,
		title = options.Title or options.title or "Dialog",
		message = options.Description or options.Message or options.message or "",
		buttons = options.Buttons or options.buttons or {},
		width = options.Width or options.width or 320,
		closable = options.Closable ~= false,
		closed = false,
		onClose = options.OnClose or options.onClose,
		z = 200,
	}

	if #dialog.buttons == 0 then
		dialog.buttons = { { Text = "OK", Callback = function() end, Primary = true } }
	end
	for index, button in ipairs(dialog.buttons) do
		button.Id = button.Id or button.Index or button.Text or tostring(index)
		button.Order = tonumber(button.Order) or index
	end

	win.Dialogs = win.Dialogs or {}
	win.Dialogs[#win.Dialogs + 1] = dialog

	function dialog:Destroy()
		self.closed = true
	end

	function dialog:SetTitle(text)
		self.title = text or ""
	end

	function dialog:SetMessage(text)
		self.message = text or ""
	end

	function dialog:SetDescription(text)
		self.message = text or ""
	end

	function dialog:AddFooterButton(id, info)
		info = type(info) == "table" and info or { Text = tostring(info or id) }
		local button = {
			Id = tostring(id),
			Text = info.Text or tostring(id),
			Callback = info.Callback or info.Func,
			Primary = info.Primary == true,
			Risky = info.Risky == true,
			Disabled = info.Disabled == true,
			Close = info.Close ~= false,
			Order = tonumber(info.Order) or (#self.buttons + 1),
		}
		self.buttons[#self.buttons + 1] = button
		return button
	end

	function dialog:RemoveFooterButton(id)
		for index = #self.buttons, 1, -1 do
			if tostring(self.buttons[index].Id) == tostring(id) then
				table.remove(self.buttons, index)
				return true
			end
		end
		return false
	end

	function dialog:SetButtonDisabled(id, state)
		for _, button in ipairs(self.buttons) do
			if tostring(button.Id) == tostring(id) then
				button.Disabled = state == true
				return true
			end
		end
		return false
	end

	function dialog:SetButtonOrder(id, order)
		order = tonumber(order)
		assert(order, "Dialog button order must be a number!")
		for _, button in ipairs(self.buttons) do
			if tostring(button.Id) == tostring(id) then
				button.Order = order
				return true
			end
		end
		return false
	end

	function dialog:Dismiss()
		self:Destroy()
	end

	return dialog
end

function DialogManager:RenderDialogs(window)
	if not window.Dialogs or #window.Dialogs == 0 then
		return nil
	end

	local TM = self.TextManager
	if not TM then
		error("DialogManager: TextManager not set (call SetLibrary first)", 2)
	end
	local scale = window:GetScale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local z = 200

	for i = #window.Dialogs, 1, -1 do
		local dialog = window.Dialogs[i]
		if dialog.closed then
			if dialog.onClose then
				local ok, err = pcall(dialog.onClose)
				if not ok then error("DialogManager onClose: " .. tostring(err), 2) end
			end
			table.remove(window.Dialogs, i)
		end
	end

	for _, dialog in ipairs(window.Dialogs) do
		table.sort(dialog.buttons, function(left, right)
			return (left.Order or 0) < (right.Order or 0)
		end)
		local dw = math.floor(dialog.width * scale)
		local dh = math.floor(math.max(120, 80 + #dialog.buttons * 10) * scale)
		local dx = math.floor((vp.X - dw) / 2)
		local dy = math.floor((vp.Y - dh) / 2)
		local backdropColor = window:_anim(dialog, "dialog.backdrop", Color3.new(0, 0, 0), 14)
		local panelColor = window:_anim(dialog, "dialog.panel", window.Theme.Background, 14)
		local panelOutline = window:_anim(dialog, "dialog.outline", window.Theme.Outline, 14)

		window:_square(0, 0, vp.X, vp.Y, backdropColor, true, 0.6, 0, z)
		window:_square(dx, dy, dw, dh, panelColor, true, 1, 8, z + 1)
		window:_square(dx, dy, dw, dh, panelOutline, false, 1, 8, z + 2)

		local pad = math.floor(12 * scale)
		local titleY = dy + pad
		window:_text(
			TM:Fit(dialog.title, dw - pad * 2, 18, window.Theme.Font, scale),
			dx + pad, titleY,
			window.Theme.Text, 18,
			Drawing.Fonts.Monospace, false, false, z + 3
		)

		window:_line(dx + pad, titleY + math.floor(22 * scale), dx + dw - pad, titleY + math.floor(22 * scale), window.Theme.Outline, 1, z + 3)

		local msgY = titleY + math.floor(30 * scale)
		local msg = TM:Fit(dialog.message, dw - pad * 2, 14, window.Theme.Font, scale)
		window:_text(msg, dx + pad, msgY, window.Theme.Muted, 14, Drawing.Fonts.Monospace, false, false, z + 3)

		local btnY = dy + dh - math.floor(36 * scale)
		local btnGap = math.floor(8 * scale)
		local btnH = math.floor(28 * scale)
		local btnWidths = {}
		local totalBtnW = 0

		for i, btn in ipairs(dialog.buttons) do
			local bw = math.max(math.floor(60 * scale), math.floor(TM:Measure(btn.Text or "OK", 14, window.Theme.Font, scale) + math.floor(24 * scale)))
			btnWidths[i] = bw
			totalBtnW = totalBtnW + bw + (i > 1 and btnGap or 0)
		end

		local btnStartX = dx + math.floor((dw - totalBtnW) / 2)
		window:_releaseInteraction(nil, true)
		for i, btn in ipairs(dialog.buttons) do
			local bx = btnStartX
			for j = 1, i - 1 do
				bx = bx + btnWidths[j] + btnGap
			end
			local bw = btnWidths[i]
			local primary = btn.Primary == true
			local btnColor = btn.Risky and Color3.fromRGB(210, 50, 65) or (primary and window.Theme.Accent or window.Theme.Surface)
			local hovered = window:_over(bx, btnY, bw, btnH)
			if btn.Disabled then
				btnColor = window.Theme.Main
			elseif hovered then
				btnColor = primary and window.Theme.Accent or window.Theme.Surface2
			end
			local outlineColor = btn.Disabled and window.Theme.SoftOutline or (hovered and window.Theme.Outline2 or window.Theme.Outline)
			local textColor = btn.Disabled and window.Theme.DimText or (primary and Color3.new(1, 1, 1) or (hovered and window.Theme.Text or window.Theme.Muted))
			local animatedButton = window:_anim(btn, "dialog.button", btnColor, 18)
			local animatedOutline = window:_anim(btn, "dialog.outline", outlineColor, 18)
			local animatedText = window:_anim(btn, "dialog.text", textColor, 18)

			window:_square(bx, btnY, bw, btnH, animatedButton, true, 1, 5, z + 4)
			window:_square(bx, btnY, bw, btnH, animatedOutline, false, 1, 5, z + 5)
			window:_text(
				TM:Fit(btn.Text or "OK", bw - math.floor(12 * scale), 14, window.Theme.Font, scale),
				bx + math.floor(bw / 2), btnY + math.floor(6 * scale),
				animatedText,
				14, Drawing.Fonts.Monospace, true, false, z + 6
			)

			if not btn.Disabled and hovered and window:_click(bx, btnY, bw, btnH, dialog) then
				if btn.Callback then
					local ok, err = pcall(btn.Callback, dialog)
					if not ok then error("DialogManager btn.Callback: " .. tostring(err), 2) end
				end
				if btn.Close ~= false then
					dialog:Destroy()
				end
				window.Mouse1Clicked = false
			end
		end
	end
end

local NotificationManager = {}

local slideTime = 0.3
local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function NotificationManager:SetLibrary(library)
	self.Library = library
	self.TextManager = library and library.TextManager
end

function NotificationManager:Notify(message, title, duration)
	local Library = self.Library
	local win = Library and Library.ActiveWindow
	if not win then
		error("NotificationManager: no active window", 2)
	end

	if type(message) == "table" then
		local info = message
		title = info.Title or info.title or title
		duration = info.Time or info.Duration or info.duration or duration
		message = info.Description or info.Text or info.Message or info.description or ""
	end
	if type(title) == "number" and duration == nil then
		duration = title
		title = nil
	end

	local life = duration or 3
	local notif = {
		message = message or "",
		title = title,
		created = tick(),
		duration = life,
		expires = tick() + life,
		onClick = nil,
		onDismiss = nil,
		closed = false,
	}

	notif.destroy = function()
		notif.closed = true
	end

	notif.setTitle = function(text)
		notif.title = text or ""
	end

	notif.setMessage = function(text)
		notif.message = text or ""
	end

	notif.onClick = function(cb)
		notif._onClick = cb
		return notif
	end

	notif.onDismiss = function(cb)
		notif._onDismiss = cb
		return notif
	end

	win.Notifications = win.Notifications or {}
	win.Notifications[#win.Notifications + 1] = notif
	return notif
end

function NotificationManager:Progress(title, message, duration)
	local notif = self:Notify(message, title, duration or 5)
	notif.progress = 0
	notif.setProgress = function(value)
		notif.progress = clamp(value, 0, 1)
	end
	return notif
end

function NotificationManager:RenderNotifications(window)
	if not window.Notifications or #window.Notifications == 0 then
		return nil
	end

	local TM = self.TextManager
	local scale = window:GetScale()
	local now = tick()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local margin = math.floor(10 * scale)
	local startY = margin
	local stackY = 0
	local notifW = math.floor(280 * scale)
	local side = window.NotifySide or "Right"

	for i = #window.Notifications, 1, -1 do
		local notif = window.Notifications[i]
		if notif.closed or now >= notif.expires + slideTime then
			if notif.closed and notif._onDismiss then
				local ok, err = pcall(notif._onDismiss)
				if not ok then error("NotificationManager _onDismiss: " .. tostring(err), 2) end
			end
			table.remove(window.Notifications, i)
		end
	end

	for i, notif in ipairs(window.Notifications) do
		local textSize = 14
		local scaledTextSize = math.floor(textSize * scale + 0.5)
		local pad = math.floor(10 * scale)
		local lineH = math.floor(15 * scale)
		local fullText = notif.title and notif.title ~= "" and (notif.title .. "\n" .. notif.message)
			or notif.message
		local msgWidth = notifW - pad * 2
		local lines = {}
		local maxLines = 6

		local function pushLine(line)
			if #lines >= maxLines then return end
			lines[#lines + 1] = line
		end

		for rawLine in (fullText .. "\n"):gmatch("(.-)\n") do
			if rawLine == "" then
				pushLine("")
			else
				local current = ""
				for word in rawLine:gmatch("%S+") do
					local nextLine = current == "" and word or (current .. " " .. word)
					if TM:Measure(nextLine, scaledTextSize, window.Theme.Font) <= msgWidth then
						current = nextLine
					else
						if current ~= "" then
							pushLine(current)
							current = word
						else
							pushLine(word)
							current = ""
						end
					end
				end
				if current ~= "" and #lines < maxLines then
					pushLine(current)
				end
			end
		end

		local widestW = 0
		for _, line in ipairs(lines) do
			local lw = TM:Measure(line, scaledTextSize, window.Theme.Font)
			if lw > widestW then
				widestW = lw
			end
		end
		local currentNotifW = math.max(math.floor(60 * scale), math.min(notifW, math.floor(widestW + pad * 2 + math.floor(10 * scale))))
		local notifH = pad * 2 + (#lines * lineH) + math.floor(7 * scale)

		local finalX = side == "Left" and margin or (vp.X - currentNotifW - margin)
		local hiddenX = side == "Left" and (-currentNotifW - math.floor(8 * scale)) or (vp.X + math.floor(8 * scale))
		local enter = clamp((now - notif.created) / slideTime, 0, 1)
		local leave = now > notif.expires and (1 - clamp((now - notif.expires) / slideTime, 0, 1)) or 1
		local slide = math.min(enter, leave)
		slide = 1 - ((1 - slide) * (1 - slide))
		local x = hiddenX + (finalX - hiddenX) * slide
		local y = startY + stackY
		local safeDuration = math.max(notif.duration, 0.001)
		local remaining = clamp((notif.expires - now) / safeDuration, 0, 1)

		local over = window:_over(x, y, currentNotifW, notifH)
		if over and not window.BlockClicks and window.Mouse1Clicked then
			if notif._onClick then
				local ok, err = pcall(notif._onClick)
				if not ok then error("NotificationManager _onClick: " .. tostring(err), 2) end
				notif._onDismiss = nil
			end
		end

		window:_square(x, y, currentNotifW, notifH, window.Theme.Background, true, 1, 7, 140)
		window:_square(x, y, currentNotifW, notifH, window.Theme.SoftOutline, false, 1, 7, 141)
		for lineIndex, line in ipairs(lines) do
			window:_text(
				line,
				x + pad,
				y + pad + (lineIndex - 1) * lineH,
				lineIndex == 1 and window.Theme.Text or window.Theme.Muted,
				textSize,
				Drawing.Fonts.Monospace,
				false,
				false,
				143
			)
		end
		window:_square(x + math.floor(8 * scale), y + notifH - math.floor(6 * scale), currentNotifW - math.floor(16 * scale), math.floor(2 * scale), window.Theme.Main, true, 1, 1, 142)
		window:_square(x + math.floor(8 * scale), y + notifH - math.floor(6 * scale), (currentNotifW - math.floor(16 * scale)) * remaining, math.floor(2 * scale), window.Accent, true, 1, 1, 144)
		stackY = stackY + notifH + math.floor(10 * scale)
	end
end

local IconAssets = _G.Galax and _G.Galax.Assets
assert(type(IconAssets) == "table", "Library.lua requires Loader.lua to load icon assets!")
local IconAliases = {
    chevron = "chevron-down",
    chevrondown = "chevron-down",
    chevronup = "chevron-up",
    drag = "move",
    resize = "move-diagonal-2",
}
local IconData = {
    check = IconAssets["assets/icons/check.png"],
    ["chevron-down"] = IconAssets["assets/icons/chevron-down.png"],
    ["chevron-up"] = IconAssets["assets/icons/chevron-up.png"],
    key = IconAssets["assets/icons/key.png"],
    move = IconAssets["assets/icons/move.png"],
    ["move-diagonal-2"] = IconAssets["assets/icons/move-diagonal-2.png"],
    search = IconAssets["assets/icons/search.png"],
    settings = IconAssets["assets/icons/settings.png"],
    user = IconAssets["assets/icons/user.png"],
}

GalaxObsidian.TextManager = TextManager
GalaxObsidian.AnimationManager = AnimationManager
GalaxObsidian.DialogManager = DialogManager
GalaxObsidian.NotificationManager = NotificationManager

-- Runtime Compatibility
if not Color3.fromRGB then
    Color3.fromRGB = function(r, g, b)
        return Color3.new(r / 255, g / 255, b / 255)
    end
end

if not Color3.fromHSV then
    Color3.fromHSV = function(h, s, v)
        local r, g, b
        if s == 0 then
            r, g, b = v, v, v
        else
            local i = math.floor(h * 6)
            local f = h * 6 - i
            local p = v * (1 - s)
            local q = v * (1 - s * f)
            local t = v * (1 - s * (1 - f))
            if i % 6 == 0 then
                r, g, b = v, t, p
            elseif i % 6 == 1 then
                r, g, b = q, v, p
            elseif i % 6 == 2 then
                r, g, b = p, v, t
            elseif i % 6 == 3 then
                r, g, b = p, q, v
            elseif i % 6 == 4 then
                r, g, b = t, p, v
            else
                r, g, b = v, p, q
            end
        end
        return Color3.new(r, g, b)
    end
end

-- Shared Utilities
local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end
local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return
    end
    local ok, result = pcall(callback, ...)
    if ok then
        return result
    end
    error("safeCall: " .. tostring(result), 2)
end

local function rgbToHsv(color)
    local r, g, b
    local colorType = type(color)
    if colorType == "table" or typeof(color) == "Color3" then
        r, g, b = color.R, color.G, color.B
    end
    if r == nil and (colorType == "table" or typeof(color) == "Color3") then
        r, g, b = color.r, color.g, color.b
    end
    if r == nil then
        local str = tostring(color)
        r, g, b = str:match("([%d%.]+)%D+([%d%.]+)%D+([%d%.]+)")
    end
    if r == nil then
        r, g, b = 0, 0, 0
    end
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if math.max(r, g, b) > 1 then
        r, g, b = r / 255, g / 255, b / 255
    end
    local maxValue = math.max(r, g, b)
    local minValue = math.min(r, g, b)
    local delta = maxValue - minValue
    local hue = 0
    if delta > 0 then
        if maxValue == r then
            hue = ((g - b) / delta) % 6
        elseif maxValue == g then
            hue = ((b - r) / delta) + 2
        else
            hue = ((r - g) / delta) + 4
        end
        hue = hue / 6
    end
    local saturation = 0
    if maxValue > 0 then
        saturation = delta / maxValue
    end
    return hue, saturation, maxValue
end

local function roundNumber(value, decimals)
    decimals = tonumber(decimals) or 0
    if decimals <= 0 then
        return math.floor(value + 0.5)
    end
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

local function formatNumber(value, decimals)
    if decimals == false then
        return tostring(value)
    end
    decimals = tonumber(decimals) or 0
    value = roundNumber(value, decimals)
    if decimals <= 0 then
        return tostring(math.floor(value + 0.5))
    end
    return tostring(value)
end
local function _scaled(x, s) return math.floor(x * s + 0.5) end
local function _yOfs(s) return s > 1 and -math.floor((s - 1) * 3) or 0 end
local function _isToggle(w) return w.type == "toggle" or w.type == "checkbox" end
local function _fire(w, ...) safeCall(w.callback, ...); safeCall(w.changed, ...) end
local function setDrawingValue(object, meta, key, value)
    if key == "Color" then
        local r, g, b = value.R, value.G, value.B
        if meta.colorR ~= r or meta.colorG ~= g or meta.colorB ~= b then
            object.Color = value
            meta.colorR, meta.colorG, meta.colorB = r, g, b
        end
        return
    end
    if meta[key] ~= value then
        object[key] = value
        meta[key] = value
    end
end
local function setDrawingPosition(object, meta, x, y)
    if meta.positionX ~= x or meta.positionY ~= y then
        object.Position = Vector2.new(x, y)
        meta.positionX, meta.positionY = x, y
    end
end
local function setDrawingSize(object, meta, x, y)
    if meta.sizeX ~= x or meta.sizeY ~= y then
        object.Size = Vector2.new(x, y)
        meta.sizeX, meta.sizeY = x, y
    end
end
local function setDrawingLine(object, meta, x1, y1, x2, y2)
    if meta.fromX ~= x1 or meta.fromY ~= y1 then
        object.From = Vector2.new(x1, y1)
        meta.fromX, meta.fromY = x1, y1
    end
    if meta.toX ~= x2 or meta.toY ~= y2 then
        object.To = Vector2.new(x2, y2)
        meta.toX, meta.toY = x2, y2
    end
end

local function makeHandle(widget)
    local handle = {}
    handle.Widget = widget
    handle.__index = handle

    function handle:Get()
        if _isToggle(widget) then
            return widget.value == true
        elseif widget.type == "slider" then
            return widget.value
        elseif widget.type == "dropdown" then
            return widget.value
        elseif widget.type == "multidropdown" then
            local result = {}

            for _, v in ipairs(widget.options) do
                if widget.selected[v] then
                    result[#result + 1] = v
                end
            end
            return result
        elseif widget.type == "colorpicker" then
            return widget.value, widget.transparency
        elseif widget.type == "keybind" then
            return widget.value
        elseif widget.type == "textbox" or widget.type == "keybox" then
            return widget.value
        elseif widget.type == "label" then
            return widget.text
        end
        return widget.value
    end
    function handle:GetState()
        if widget.type == "keybind" then
            return widget._state == true
        end
        return widget.value == true
    end

    function handle:Set(value)
        if _isToggle(widget) then
            widget.value = value == true
            _fire(widget, widget.value)
        elseif widget.type == "slider" then
            local v = tonumber(value)
            assert(v, "Slider value must be a number!")
            v = clamp(v, widget.min, widget.max)
            if widget.rounding ~= false then v = roundNumber(v, widget.rounding) end
            widget.value = v
            _fire(widget, widget.value)
        elseif widget.type == "dropdown" then
            widget.value = value
            _fire(widget, widget.value)
        elseif widget.type == "multidropdown" then
            widget.selected = {}

            if value then
                for _, v in ipairs(value) do
                    widget.selected[v] = true
                end
            end
            _fire(widget, widget.selected)
        elseif widget.type == "textbox" or widget.type == "keybox" then
            widget.value = tostring(value or "")
            _fire(widget, widget.value)
        elseif widget.type == "keybind" then
            if type(value) == "table" then
                widget.value = value[1] or value.Key or value.key or widget.value
                widget.mode = value[2] or value.Mode or value.mode or widget.mode
                widget.modifiers = value.Modifiers or value.modifiers
            else
                widget.value = value
            end
            safeCall(widget.changed, widget.value, widget.modifiers)
        end
    end
    function handle:SetValue(value)
        return handle:Set(value)
    end
    function handle:SetValueRGB(color, transparency)
        if widget.type == "colorpicker" then
            widget.value = color
            widget.transparency = widget.transparencyEnabled and (transparency or 0) or 0
            widget.hue, widget.sat, widget.vib = rgbToHsv(color)
            _fire(widget, widget.value, widget.transparency)
        end
    end

    function handle:OnChanged(cb)
        widget.changed = cb
    end
    function handle:OnClick(cb)
        if widget.type == "keybind" then
            if widget.callback then
                local old = widget.callback
                widget.callback = function(v)
                    old(v)
                    if type(cb) == "function" then cb(v) end
                end
            else
                widget.callback = cb
            end
        else
            widget.callback = cb
        end
    end
    function handle:SetText(text)
        widget.label = tostring(text or "")
        widget.text = tostring(text or "")
    end
    function handle:SetVisible(visible)
        widget.visible = visible == true
    end
    function handle:Destroy()
        widget.destroyed = true
        widget.visible = false
        if widget.id then
            GalaxObsidian.Options[widget.id] = nil
            GalaxObsidian.Toggles[widget.id] = nil
        end
    end
    function handle:SetDisabled(disabled)
        widget.disabled = disabled == true
    end
    function handle:SetTooltip(tooltip)
        widget.tooltip = tooltip and tostring(tooltip) or nil
    end
    function handle:SetKey(key)
        widget.keybind = key
    end
    function handle:SetPlaceholder(text)
        widget.placeholder = tostring(text or "")
    end
    function handle:GetId()
        return widget.id
    end

    function handle:SetMin(value)
        if widget.type == "slider" then
            value = tonumber(value)
            assert(value and value < widget.max, "Slider minimum must be lower than maximum!")
            widget.min = value
            if widget.value < value then handle:Set(value) end
        end
    end
    function handle:SetMax(value)
        if widget.type == "slider" then
            value = tonumber(value)
            assert(value and value > widget.min, "Slider maximum must be greater than minimum!")
            widget.max = value
            if widget.value > value then handle:Set(value) end
        end
    end
    function handle:SetPrefix(value)
        if widget.type == "slider" then
            widget.prefix = tostring(value or "")
        end
    end
    function handle:SetSuffix(value)
        if widget.type == "slider" then
            widget.suffix = tostring(value or "")
        end
    end
    function handle:SetCompact(value)
        if widget.type == "slider" then widget.compact = value == true end
    end
    function handle:SetHideMax(value)
        if widget.type == "slider" then widget.hideMax = value == true end
    end
    function handle:Refresh(newOptions, newDefault)
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            widget.options = newOptions or {}

            if newDefault ~= nil then
                if widget.type == "multidropdown" then
                    local sel = {}
                    if type(newDefault) == "table" then
                        for _, v in ipairs(newDefault) do sel[v] = true end
                    else
                        sel[newDefault] = true
                    end
                    widget.selected = sel
                else
                    widget.value = newDefault
                end
            end
        end
    end
    function handle:SetValues(values)
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            widget.options = values or {}
        end
    end
    function handle:AddValues(values)
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            for _, v in ipairs(values or {}) do
                widget.options[#widget.options + 1] = v
            end
        end
    end
    function handle:SetDisabledValues(values)
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            widget.disabledValues = values or {}
        end
    end
    function handle:AddDisabledValues(values)
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            for _, value in ipairs(values or {}) do
                widget.disabledValues[#widget.disabledValues + 1] = value
            end
        end
    end
    function handle:SetValueImages(values)
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            widget.valueImages = values or {}
        end
    end
    function handle:AddValueImages(values)
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            for value, image in pairs(values or {}) do
                widget.valueImages[value] = image
            end
        end
    end
    function handle:SetDragSelect(state)
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            widget.dragSelect = state == true
        end
    end
    function handle:AddOption(value)
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            widget.options[#widget.options + 1] = value
        end
    end
    function handle:RemoveOption(value)
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            for i = #widget.options, 1, -1 do
                if widget.options[i] == value then
                    table.remove(widget.options, i)
                    if widget.type == "multidropdown" then
                        widget.selected[value] = nil
                    elseif widget.value == value then
                        widget.value = #widget.options > 0 and widget.options[1] or nil
                    end
                    break
                end
            end
        end
    end
    function handle:GetActiveValues(countOnly)
        if widget.type == "multidropdown" then
            local result = {}

            for _, v in ipairs(widget.options) do
                if widget.selected[v] then
                    result[#result + 1] = v
                end
            end
            return countOnly and #result or result
        end
        if widget.value == nil or widget.value == "" then
            return countOnly and 0 or {}
        end
        return countOnly and 1 or { widget.value }
    end
    function handle:Select(value)
        if widget.type == "dropdown" then
            widget.value = value
            _fire(widget, widget.value)
        elseif widget.type == "multidropdown" then
            widget.selected[value] = true
            _fire(widget, widget.selected)
        end
    end
    function handle:Deselect(value)
        if widget.type == "multidropdown" then
            widget.selected[value] = nil
            _fire(widget, widget.selected)
        elseif widget.type == "dropdown" and widget.allowNull then
            widget.value = nil
            _fire(widget, widget.value)
        end
    end
    function handle:GetOptions()
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            local copy = {}

            for _, v in ipairs(widget.options) do
                copy[#copy + 1] = v
            end
            return copy
        end
        return {}
    end
    function handle:Clear()
        if widget.type == "dropdown" or widget.type == "multidropdown" then
            widget.options = {}
            if widget.type == "multidropdown" then
                widget.selected = {}
            else
                widget.value = nil
            end
        end
    end
    function handle:Reset()
        if widget._default ~= nil then
            if widget.type == "multidropdown" then
                local sel = {}
                if type(widget._default) == "table" then
                    for _, v in ipairs(widget._default) do sel[v] = true end
                else
                    sel[widget._default] = true
                end
                widget.selected = sel
                _fire(widget, widget.selected)
            else
                widget.value = widget._default
                _fire(widget, widget.value)
            end
        end
    end

    setmetatable(handle, {
        __index = function(t, k)
            if k == "Value" then
                return t:Get()
            end
            if k == "Transparency" and widget.type == "colorpicker" then
                return widget.transparency
            end
            if k == "Modifiers" then
                return widget.modifiers
            end
            if k == "Mode" then
                return widget.mode
            end
            return rawget(t, k)
        end,
        __newindex = function(t, k, v)
            if k == "Value" then
                return t:Set(v)
            end
            if k == "Mode" then
                widget.mode = v
                return
            end
            rawset(t, k, v)
        end,
    })
    return handle
end

function GalaxObsidian:OnUnload(callback)
    self.UnloadCallbacks[#self.UnloadCallbacks + 1] = callback
end
function GalaxObsidian:Unload()
    self.Unloaded = true
    for _, cb in ipairs(self.UnloadCallbacks) do
        local ok, err = pcall(cb)
        if not ok then error("Unload callback: " .. tostring(err), 2) end
    end
    if self.ActiveWindow then
        self.ActiveWindow:Destroy()
        self.ActiveWindow = nil
    end
    self.Options = {}
    self.Toggles = {}
end
local function estimateTextWidth(text, size, font)
    local scale = GalaxObsidian.ActiveWindow and GalaxObsidian.ActiveWindow:GetScale() or 1.0
    return TextManager:Measure(text, size or GalaxObsidian.FontSize or 14, font or Theme.Font, scale)
end
local function fitTextToWidth(text, maxWidth, size, font)
    local scale = GalaxObsidian.ActiveWindow and GalaxObsidian.ActiveWindow:GetScale() or 1.0
    return TextManager:Fit(text, maxWidth, size or GalaxObsidian.FontSize or 14, font or Theme.Font, scale)
end

function GalaxObsidian:SetNotifySide(side)
    self.NotifySide = tostring(side) == "Left" and "Left" or "Right"
    if self.ActiveWindow then
        self.ActiveWindow.NotifySide = self.NotifySide
    end
end
function GalaxObsidian:SetDPIScale(percent)
    percent = tonumber(percent) or 100
    percent = math.floor(clamp(percent, 50, 200) + 0.5)
    self.DPIScale = percent
    if self.ActiveWindow and self.ActiveWindow.SetDPIScale then
        self.ActiveWindow:SetDPIScale(percent)
    end
end

Theme = {
    Background = Color3.fromRGB(17, 17, 17),
    Topbar = Color3.fromRGB(13, 13, 13),
    Sidebar = Color3.fromRGB(15, 15, 15),
    Bottombar = Color3.fromRGB(23, 23, 23),
    BottombarBorder = Color3.fromRGB(50, 50, 50),
    FooterText = Color3.fromRGB(185, 185, 185),
    Main = Color3.fromRGB(25, 25, 25),
    Surface = Color3.fromRGB(25, 25, 25),
    Surface2 = Color3.fromRGB(33, 33, 33),
    Outline = Color3.fromRGB(40, 40, 40),
    Outline2 = Color3.fromRGB(50, 50, 50),
    SoftOutline = Color3.fromRGB(40, 40, 40),
    DimText = Color3.fromRGB(76, 76, 76),
    PopupHover = Color3.fromRGB(25, 25, 25),
    Accent = Color3.fromRGB(125, 85, 255),
    Text = Color3.fromRGB(255, 255, 255),
    Muted = Color3.fromRGB(130, 130, 130),
    Dark = Color3.fromRGB(0, 0, 0),
    Red = Color3.fromRGB(255, 50, 50),
    Font = GalaxObsidian.Font,
}

local ChromeOffsets = {}
local TextOffsets = {}
do
    local bg = Theme.Background
    for _, field in ipairs({ "Topbar", "Sidebar", "Bottombar", "BottombarBorder", "Main", "Surface", "Surface2", "Outline", "Outline2", "SoftOutline", "PopupHover" }) do
        local val = Theme[field]
        if val and bg then
            ChromeOffsets[field] = {
                R = val.R - bg.R,
                G = val.G - bg.G,
                B = val.B - bg.B,
            }
        end
    end
    local text = Theme.Text
    for _, field in ipairs({ "DimText", "FooterText", "Muted" }) do
        local val = Theme[field]
        if val and text then
            TextOffsets[field] = {
                R = val.R - text.R,
                G = val.G - text.G,
                B = val.B - text.B,
            }
        end
    end
end

local function dependencyVisible(widget)
    local box = widget and widget.dependencyBox
    if not box then return true end
    for _, dependency in ipairs(box.dependencies or {}) do
        local source = dependency[1]
        local expected = dependency[2]
        local value = source and source.Get and source:Get() or source and source.Value
        if value ~= expected then return false end
    end
    return true
end

local function applyChromeOffsets(base, skip)
    for field, offset in pairs(ChromeOffsets) do
        if not (skip and skip[field]) then
            Theme[field] = Color3.new(
                clamp(base.R + offset.R, 0, 1),
                clamp(base.G + offset.G, 0, 1),
                clamp(base.B + offset.B, 0, 1)
            )
        end
    end
end

local function applyTextOffsets(base, skip)
    for field, offset in pairs(TextOffsets) do
        if not (skip and skip[field]) then
            Theme[field] = Color3.new(
                clamp(base.R + offset.R, 0, 1),
                clamp(base.G + offset.G, 0, 1),
                clamp(base.B + offset.B, 0, 1)
            )
        end
    end
end

function GalaxObsidian:AddDraggableLabel(text)
    local win = self.ActiveWindow
    if not win then
        error("AddDraggableLabel: no active window", 2)
    end
    return win:AddDraggableLabel(text)
end

function GalaxObsidian:AddDraggableButton(...)
    local win = self.ActiveWindow
    assert(win, "AddDraggableButton requires an active window!")
    return win:AddDraggableButton(...)
end

function GalaxObsidian:AddDraggableMenu(...)
    local win = self.ActiveWindow
    assert(win, "AddDraggableMenu requires an active window!")
    return win:AddDraggableMenu(...)
end

local TextChars = TextManager.TextChars
local function keyName(key)
    return TextManager:KeyName(key)
end
local KeyAliasMap = {
    MB1 = 1,
    M1 = 1,
    MOUSE1 = 1,
    MOUSEBUTTON1 = 1,
    MB2 = 2,
    M2 = 2,
    MOUSE2 = 2,
    MOUSEBUTTON2 = 2,
    MB3 = 4,
    M3 = 4,
    MOUSE3 = 4,
    MOUSEBUTTON3 = 4,
    MB4 = 5,
    M4 = 5,
    MOUSE4 = 5,
    MOUSEBUTTON4 = 5,
    MB5 = 6,
    M5 = 6,
    MOUSE5 = 6,
    MOUSEBUTTON5 = 6,
}
local function keyCodeFromName(key)
    if key == nil or key == false or key == "" or key == "None" then
        return nil
    end
    if type(key) == "number" then
        return key
    end
    local text = tostring(key)
    local numberKey = tonumber(text)
    if numberKey then
        return numberKey
    end
    local upper = text:upper():gsub("%s+", "")
    if KeyAliasMap[upper] then
        return KeyAliasMap[upper]
    end
    if upper:match("^F%d+$") then
        local n = tonumber(upper:sub(2))
        if n and n >= 1 and n <= 24 then
            return 111 + n
        end
    end
    if #upper == 1 then
        local byte = string.byte(upper)
        if byte and byte >= 32 and byte <= 126 then
            return byte
        end
    end
    return key
end

local function isImageData(data)
    if type(data) ~= "string" or #data < 12 then
        return false
    end
    local b1, b2, b3, b4, b5, b6, b7, b8 = string.byte(data, 1, 8)
    if b1 == 137 and b2 == 80 and b3 == 78 and b4 == 71 and b5 == 13 and b6 == 10 and b7 == 26 and b8 == 10 then
        return true
    end
    if b1 == 255 and b2 == 216 and b3 == 255 then
        return true
    end
    if string.sub(data, 1, 4) == "RIFF" and string.sub(data, 9, 12) == "WEBP" then
        return true
    end
    return false
end

local function wrapTextLines(text, maxWidth, size, maxLines, font)
    text = tostring(text or "")
    local lines = {}
    maxLines = maxLines or 8

    local function push(line)
        if #lines >= maxLines then
            return nil
        end
        lines[#lines + 1] = line
    end
    for rawLine in (text .. "\n"):gmatch("(.-)\n") do
        if rawLine == "" then
            push("")
        else
            local current = ""
            for word in rawLine:gmatch("%S+") do
                local nextLine = current == "" and word or (current .. " " .. word)
                if estimateTextWidth(nextLine, size, font) <= maxWidth then
                    current = nextLine
                else
                    if current ~= "" then
                        push(current)
                        current = word
                    end
                    if estimateTextWidth(current, size, font) > maxWidth then
                        push(fitTextToWidth(current, maxWidth, size, font))
                        current = ""
                    end
                end
                if #lines >= maxLines then
                    break
                end
            end
            if current ~= "" and #lines < maxLines then
                push(current)
            end
        end
        if #lines >= maxLines then
            break
        end
    end
    if #lines == 0 then
        lines[1] = ""
    end
    return lines
end
local function widestLineWidth(lines, size, font)
    local width = 0
    for _, line in ipairs(lines) do
        width = math.max(width, estimateTextWidth(line, size, font))
    end
    return width
end

local function themeColor(value)
    if type(value) == "table" and value.R ~= nil then
        return value
    end
    if type(value) == "string" then
        local hex = value:gsub("#", "")
        if #hex == 6 or #hex == 8 then
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            if r and g and b then
                return Color3.fromRGB(r, g, b)
            end
        end
    end
    return value
end

local function colorToHexAlpha(color, alpha)
    local r = math.floor(clamp(color.R * 255 + 0.5, 0, 255))
    local g = math.floor(clamp(color.G * 255 + 0.5, 0, 255))
    local b = math.floor(clamp(color.B * 255 + 0.5, 0, 255))
    if alpha and alpha > 0 then
        local a = math.floor(clamp((1 - alpha) * 255 + 0.5, 0, 255))
        return string.format("#%02X%02X%02X%02X", r, g, b, a)
    end
    return string.format("#%02X%02X%02X", r, g, b)
end

local function robloxThumbnailUrl(assetId)
    return string.format(
        "https://thumbnails.roblox.com/v1/assets?assetIds=%s&size=150x150&format=Png&isCircular=false",
        tostring(assetId)
    )
end
local function imageUrl(value)
    if value == nil or value == "" then
        return nil
    end
    if type(value) == "number" then
        return robloxThumbnailUrl(value)
    end
    if type(value) == "string" and value:match("^%d+$") then
        return robloxThumbnailUrl(value)
    end
    return value
end
local function parsePngDimensions(data)
    if data and data:sub(2, 4) == "PNG" then
        local w = string.unpack(">I4", data:sub(17, 20))
        local h = string.unpack(">I4", data:sub(21, 24))
        if w > 0 and h > 0 then
            return w, h
        end
    end
    local ok, img = pcall(Drawing.new, "Image")
    if ok then
        img.Data = data
        local w, h = img.Size.X, img.Size.Y
        img:Remove()
        if w > 0 and h > 0 then
            return w, h
        end
    end
    return nil, nil
end
local function thumbnailImageUrl(data)
    if type(data) ~= "string" then
        return nil
    end
    local url = data:match('"imageUrl"%s*:%s*"(.-)"')
    if not url or url == "" then
        return nil
    end
    url = url:gsub("\\/", "/")
    return url
end

local function getMouse()
    local players = game:GetService("Players")
    if not players or not players.LocalPlayer then
        return nil
    end
    return players.LocalPlayer:GetMouse()
end

local DefaultKeybindModePopupModes = { "Always", "Toggle", "Hold", "Press" }

local function normalizeKeybindModePopupConfig(config, fallbackModes)
    if config == false then
        return false, {}
    end

    local modes = fallbackModes or DefaultKeybindModePopupModes
    local enabled = true

    if type(config) == "table" then
        if config.Enabled ~= nil then
            enabled = config.Enabled == true
        elseif config.Enabled == false then
            enabled = false
        end

        if #config > 0 then
            modes = config
        elseif type(config.Modes) == "table" then
            modes = config.Modes
        end
    elseif config == true or config == nil then
        enabled = true
    end

    local clean = {}
    local seen = {}

    for _, mode in ipairs(modes or {}) do
        mode = tostring(mode)
        if (mode == "Always" or mode == "Toggle" or mode == "Hold" or mode == "Press") and not seen[mode] then
            clean[#clean + 1] = mode
            seen[mode] = true
        end
    end

    if #clean == 0 then
        clean = { "Always", "Toggle", "Hold", "Press" }
    end

    return enabled ~= false, clean
end

local function resolveKeybindPopupConfig(popupConfig)
    if popupConfig == nil then
        return nil, nil
    end
    local enabled, modes = normalizeKeybindModePopupConfig(popupConfig)
    return enabled, modes
end

function GalaxObsidian:CreateWindow(options)
    options = options or {}
    local mouse = getMouse()
    if not mouse then
        error("CreateWindow: no LocalPlayer or mouse available", 2)
    end
    local optSize = options.Size
    local resolvedSize = Vector2.new(720, 600)
    if type(optSize) == "table" and optSize.X ~= nil then
        resolvedSize = optSize
    elseif type(optSize) == "table" and #optSize >= 2 then
        resolvedSize = Vector2.new(optSize[1], optSize[2])
    end
    local optMinSize = options.MinSize or options.MinimumSize
    local resolvedMinSize = Vector2.new(480, 360)
    if type(optMinSize) == "table" and optMinSize.X ~= nil then
        resolvedMinSize = optMinSize
    elseif type(optMinSize) == "table" and #optMinSize >= 2 then
        resolvedMinSize = Vector2.new(optMinSize[1], optMinSize[2])
    end
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize
    if viewport and viewport.X > 0 and viewport.Y > 0 then
        local maxX = viewport.X - 64
        local maxY = viewport.Y - 64
        resolvedMinSize = Vector2.new(math.min(resolvedMinSize.X, maxX), math.min(resolvedMinSize.Y, maxY))
        resolvedSize = Vector2.new(clamp(resolvedSize.X, resolvedMinSize.X, maxX), clamp(resolvedSize.Y, resolvedMinSize.Y, maxY))
    end

    local keybindMenuOptions = options.KeybindMenu or {}
    local initialDPIScale = tonumber(GalaxObsidian.DPIScale) or 100
    local initialScale = clamp(initialDPIScale / 100, 0.5, 2)
    local Window = {
        Title = options.Title or "",
        Footer = options.Footer or "",
        IconUrl = imageUrl(options.IconUrl or options.Icon or options.LogoUrl),
        IconData = options.IconData,
        IconReady = options.IconData ~= nil,
        IconSize = options.IconSize or 30,
        ImagesEnabled = options.EnableImages ~= false,
        TransparencyTextureData = GalaxObsidian.ImageCache[GalaxObsidian.TransparencyTextureUrl],
        SaturationTextureData = GalaxObsidian.ImageCache[GalaxObsidian.SaturationTextureUrl],
        LogicalSize = resolvedSize,
        Size = Vector2.new(
            math.max(math.floor(resolvedMinSize.X * initialScale + 0.5), math.floor(resolvedSize.X * initialScale + 0.5)),
            math.max(math.floor(resolvedMinSize.Y * initialScale + 0.5), math.floor(resolvedSize.Y * initialScale + 0.5))
        ),
        MinSize = resolvedMinSize,
        DPIScale = initialDPIScale,
        Resizable = options.Resizable ~= false,
        MenuKey = options.MenuKey or 0x70,
        Position = Vector2.new(options.X or 180, options.Y or 130),
        Accent = options.Accent or Theme.Accent,
        SearchPlaceholder = options.SearchPlaceholder or "Search",
        SearchText = "",
        SearchFocused = false,
        ShowSearch = options.ShowSearch ~= false,
        ShowKeybindMenu = options.ShowKeybindMenu == true,
        KeybindMenuX = options.KeybindMenuX or keybindMenuOptions.X,
        KeybindMenuY = options.KeybindMenuY or keybindMenuOptions.Y,
        KeybindMenuWidth = options.KeybindMenuWidth or keybindMenuOptions.Width,
        NotifySide = options.NotifySide or "Right",
        SidebarWidth = tonumber(options.SidebarWidth) or 200,
        Compact = options.Compact == true,
        AnimationsEnabled = options.Animations ~= false,
        Open = options.StartMinimized ~= true,
        Running = true,
        Tabs = {},
        ActiveTab = nil,
        TabScroll = {},
        ScrollTarget = nil,
        ScrollDragOffset = 0,
        Notifications = {},
        Pool = { Square = {}, Text = {}, Line = {}, Circle = {}, Image = {} },
        Index = { Square = 0, Text = 0, Line = 0, Circle = 0, Image = 0 },
        HighWater = { Square = 0, Text = 0, Line = 0, Circle = 0, Image = 0 },
        Theme = Theme,

        PrevKeys = {},
        PrevMouse1 = false,
        PrevMouse2 = false,
        HoldKey = nil,
        HoldStarted = 0,
        HoldLastRepeat = 0,
        Mouse1Clicked = false,
        Mouse1Held = false,
        Mouse2Clicked = false,
        Mouse2Held = false,
        PrevMouse3 = false,
        PrevMouse4 = false,
        PrevMouse5 = false,
        DragOffset = nil,
        ResizeOffset = nil,
        SliderTarget = nil,
        DropdownTarget = nil,
        ColorPickerTarget = nil,
        ColorPickerDrag = nil,
        KeyListenTarget = nil,
        KeyListenStarted = 0,
        KeybindModeTarget = nil,
        KeybindModePopup = nil,
        TextTarget = nil,
        DropdownSearch = nil,
        TooltipText = nil,
        _focus = nil,
        KeybindMenuDrag = nil,
        DraggableLabels = {},
        DraggableButtons = {},
        DraggableMenus = {},
        _iconRequests = {},
        LastRobloxInputBlocked = nil,
        BlockClicks = false,
        _lastActivity = tick(),
        _lastMouseX = mouse.X,
        _lastMouseY = mouse.Y,
        _cornerRadius = GalaxObsidian.CornerRadius or 0,
        Options = GalaxObsidian.Options,
        Toggles = GalaxObsidian.Toggles,
    }

    GalaxObsidian.ActiveWindow = Window
    local ImageLoading = {}
    local function RequestImage(url, callback)
        if not url or url == "" then
            return nil
        end
        local cached = GalaxObsidian.ImageCache[url]
        if cached then
            if type(callback) == "function" then
                task.spawn(function()
                    local ok, err = pcall(callback, cached)
                    if not ok then error("RequestImage callback: " .. tostring(err), 2) end
                end)
            end
            return cached
        end
        if ImageLoading[url] then
            if type(callback) == "function" then
                ImageLoading[url][#ImageLoading[url] + 1] = callback
            end
            return nil
        end
        ImageLoading[url] = {}

        if type(callback) == "function" then
            ImageLoading[url][#ImageLoading[url] + 1] = callback
        end
        task.spawn(function()
            local ok, data = pcall(function()
                return game:HttpGet(url)
            end)
            if ok and not isImageData(data) then
                local resolvedUrl = thumbnailImageUrl(data)
                if resolvedUrl then
                    ok, data = pcall(function()
                        return game:HttpGet(resolvedUrl)
                    end)
                    if ok and isImageData(data) then
                        GalaxObsidian.ImageCache[resolvedUrl] = data
                    end
                end
            end
            if ok and isImageData(data) then
                GalaxObsidian.ImageCache[url] = data
                for _, cb in ipairs(ImageLoading[url]) do
                    local ok, err = pcall(cb, data)
                    if not ok then error("ImageLoading callback: " .. tostring(err), 2) end
                end
            end
            ImageLoading[url] = nil
        end)
        return nil
    end
    Window._requestImage = RequestImage
    if Window.ImagesEnabled and Window.IconUrl and not Window.IconReady then
        RequestImage(Window.IconUrl, function(data)
            Window.IconData = data
            Window.IconNativeW, Window.IconNativeH = parsePngDimensions(data)
            Window.IconReady = true
        end)
    end
    if Window.ImagesEnabled and not Window.TransparencyTextureData then
        RequestImage(GalaxObsidian.TransparencyTextureUrl, function(data)
            Window.TransparencyTextureData = data
        end)
    end
    if Window.ImagesEnabled and not Window.SaturationTextureData then
        RequestImage(GalaxObsidian.SaturationTextureUrl, function(data)
            Window.SaturationTextureData = data
        end)
    end

    Window.MaxPoolSize = Window.MaxPoolSize or {
        Square = 4000,
        Text = 2000,
        Line = 1000,
        Circle = 1000,
        Image = 500,
    }
    function Window:_resetPool()
        self.Index.Square = 0
        self.Index.Text = 0
        self.Index.Line = 0
        self.Index.Circle = 0
        self.Index.Image = 0
    end
    function Window:_hideUnused()
        for kind, list in pairs(self.Pool) do
            for i = self.Index[kind] + 1, self.HighWater[kind] do
                local object = list[i]
                if object and object.Visible then
                    object.Visible = false
                end
            end
            self.HighWater[kind] = self.Index[kind]
        end
    end

    function Window:_shiftWindowVisible(dx, dy)
        if dx == 0 and dy == 0 then return end
        for kind, list in pairs(self.Pool) do
            for i = 1, self.HighWater[kind] do
                local object = list[i]
                local meta = object and drawingMeta[object]
                if object and object.Visible and meta and meta.mainWindow then
                    if kind == "Line" then
                        meta.fromX, meta.fromY = meta.fromX + dx, meta.fromY + dy
                        meta.toX, meta.toY = meta.toX + dx, meta.toY + dy
                        object.From = Vector2.new(meta.fromX, meta.fromY)
                        object.To = Vector2.new(meta.toX, meta.toY)
                    else
                        meta.positionX, meta.positionY = meta.positionX + dx, meta.positionY + dy
                        object.Position = Vector2.new(meta.positionX, meta.positionY)
                    end
                end
            end
        end
    end

    function Window:_get(kind)
        self.Index[kind] = self.Index[kind] + 1
        local max = self.MaxPoolSize[kind] or 9999
        if self.Index[kind] > max then
            self.Index[kind] = 1
        end
        local object = self.Pool[kind][self.Index[kind]]
        if not object then
            object = Drawing.new(kind)
            self.Pool[kind][self.Index[kind]] = object
        end
        local meta = drawingMeta[object]
        if not meta then
            meta = {}
            drawingMeta[object] = meta
        end
        meta.mainWindow = self._renderingMainWindow == true
        if not object.Visible then
            object.Visible = true
        end
        self.HighWater[kind] = math.max(self.HighWater[kind], self.Index[kind])
        return object
    end

    function Window:_clipAllowsBox(y, h)
        if not self._clipTop or not self._clipBottom then
            return true
        end
        if not y or not h then
            return true
        end
        return y >= self._clipTop and y + h <= self._clipBottom
    end
    function Window:_clipAllowsLine(y1, y2)
        if not self._clipTop or not self._clipBottom then
            return true
        end
        local top = math.min(y1 or 0, y2 or 0)
        local bottom = math.max(y1 or 0, y2 or 0)
        return top >= self._clipTop and bottom <= self._clipBottom
    end

    function Window:_square(x, y, w, h, color, filled, transparency, corner, z)
        if not w or not h or w <= 0 or h <= 0 then
            return nil
        end
        if not self:_clipAllowsBox(y, h) then
            return nil
        end
        local object = self:_get("Square")
        local meta = drawingMeta[object]
        setDrawingPosition(object, meta, x, y)
        setDrawingSize(object, meta, w, h)
        if color then
            setDrawingValue(object, meta, "Color", color)
        end
        setDrawingValue(object, meta, "Filled", filled ~= false)
        setDrawingValue(object, meta, "Corner", corner or 0)
        setDrawingValue(object, meta, "Transparency", transparency or 1)
        setDrawingValue(object, meta, "ZIndex", z or 1)
        return object
    end
    function Window:_text(text, x, y, color, size, font, center, outline, z)
        local content = tostring(text or "")
        local scale = self:GetScale()
        local textSize = math.floor((size or GalaxObsidian.FontSize or 14) * scale + 0.5)
        if not self:_clipAllowsBox(y, textSize) then
            return nil
        end
        local object = self:_get("Text")
        local meta = drawingMeta[object]
        local resolvedFont = GalaxObsidian.Font
        setDrawingValue(object, meta, "Text", content)
        setDrawingValue(object, meta, "Size", textSize)
        setDrawingValue(object, meta, "Font", resolvedFont)
        local textX = x
        if center == true then
            local textWidth = TextManager:Measure(content, size or GalaxObsidian.FontSize or 14, resolvedFont, scale)
            textX = x - textWidth / 2
        end
        local yOffset = scale > 1 and -math.floor((scale - 1) * 3) or 0
        setDrawingPosition(object, meta, math.floor(textX + 0.5), math.floor(y + yOffset + 0.5))
        if color then
            setDrawingValue(object, meta, "Color", color)
        end
        setDrawingValue(object, meta, "Center", false)
        setDrawingValue(object, meta, "Outline", outline == true)
        setDrawingValue(object, meta, "Transparency", 1)
        setDrawingValue(object, meta, "ZIndex", z or 5)
        return object
    end

    function Window:_line(x1, y1, x2, y2, color, thickness, z)
        if not self:_clipAllowsLine(y1, y2) then
            return nil
        end
        local object = self:_get("Line")
        local meta = drawingMeta[object]
        setDrawingLine(object, meta, x1, y1, x2, y2)
        if color then
            setDrawingValue(object, meta, "Color", color)
        end
        setDrawingValue(object, meta, "Thickness", thickness or 1)
        setDrawingValue(object, meta, "Transparency", 1)
        setDrawingValue(object, meta, "ZIndex", z or 4)
        return object
    end
    function Window:_circle(x, y, radius, color, filled, thickness, z)
        radius = radius or 0
        if not self:_clipAllowsBox(y - radius, radius * 2) then
            return nil
        end
        local object = self:_get("Circle")
        local meta = drawingMeta[object]
        setDrawingPosition(object, meta, x, y)
        setDrawingValue(object, meta, "Radius", radius)
        if color then
            setDrawingValue(object, meta, "Color", color)
        else
            setDrawingValue(object, meta, "Color", Theme.Accent)
        end
        setDrawingValue(object, meta, "Filled", filled ~= false)
        setDrawingValue(object, meta, "Thickness", thickness or 1)
        setDrawingValue(object, meta, "NumSides", 24)
        setDrawingValue(object, meta, "Transparency", 1)
        setDrawingValue(object, meta, "ZIndex", z or 5)
        return object
    end

    function Window:_image(data, x, y, w, h, rounding, z, transparency)
        if self.ImagesEnabled ~= true then
            return nil
        end
        if not data or data == "" or w <= 0 or h <= 0 then
            return nil
        end
        if not self:_clipAllowsBox(y, h) then
            return nil
        end
        if not isImageData(data) then
            return nil
        end
        local object = self:_get("Image")
        local meta = drawingMeta[object]
        setDrawingValue(object, meta, "Data", data)
        setDrawingPosition(object, meta, x, y)
        setDrawingSize(object, meta, w, h)
        setDrawingValue(object, meta, "Rounding", rounding or 0)
        setDrawingValue(object, meta, "Transparency", transparency or 1)
        setDrawingValue(object, meta, "ZIndex", z or 6)
        return object
    end


    function Window:_over(x, y, w, h)
        return mouse.X >= x and mouse.X <= x + w and mouse.Y >= y and mouse.Y <= y + h
    end
    function Window:_clampToViewport(x, y, w, h, margin, screenOnly)
        margin = margin or 6
        if not screenOnly and self.Open and self.Position and self.Size then
            local minX = self.Position.X + margin
            local minY = self.Position.Y + margin
            local maxX = self.Position.X + self.Size.X - w - margin
            local maxY = self.Position.Y + self.Size.Y - h - margin
            if maxX < minX then
                maxX = minX
            end
            if maxY < minY then
                maxY = minY
            end
            return clamp(x, minX, maxX), clamp(y, minY, maxY)
        end
        local camera = workspace.CurrentCamera
        if not camera or not camera.ViewportSize then
            return x, y
        end
        local viewport = camera.ViewportSize
        local maxX = viewport.X - w - margin
        local maxY = viewport.Y - h - margin
        if maxX < margin then
            maxX = margin
        end
        if maxY < margin then
            maxY = margin
        end
        return clamp(x, margin, maxX), clamp(y, margin, maxY)
    end
    function Window:_placeNearMouse(w, h, offsetX, offsetY, margin, screenOnly)
        local scale = self:GetScale()
        margin = margin or math.floor(6 * scale)
        offsetX = offsetX or math.floor(12 * scale)
        offsetY = offsetY or math.floor(14 * scale)
        local x = mouse.X + offsetX
        local y = mouse.Y + offsetY
        local boundX, boundY = nil, nil
        if not screenOnly and self.Open and self.Position and self.Size then
            boundX = self.Position.X + self.Size.X
            boundY = self.Position.Y + self.Size.Y
        else
            local camera = workspace.CurrentCamera
            if camera and camera.ViewportSize then
                boundX = camera.ViewportSize.X
                boundY = camera.ViewportSize.Y
            end
        end
        if boundX and x + w > boundX - margin then
            x = mouse.X - w - math.floor(10 * scale)
        end
        if boundY and y + h > boundY - margin then
            y = mouse.Y - h - math.floor(10 * scale)
        end
        return self:_clampToViewport(x, y, w, h, margin, screenOnly)
    end

    function Window:MouseFocus(owner)
        if owner == nil then
            return self._focus
        end
        if owner == false then
            if self._focus then
                self._focus = nil
                self.Mouse1Clicked = false
            end
            return nil
        end
        if self.DropdownTarget and owner ~= self.DropdownTarget then
            return false
        end
        if self.ColorPickerTarget and owner ~= self.ColorPickerTarget then
            return false
        end
        if self.KeybindModeTarget and owner ~= self.KeybindModeTarget then
            return false
        end
        if self._focus and self._focus ~= owner then
            return false
        end
        self._focus = owner
        self.Mouse1Clicked = false
        return true
    end
    function Window:_hover(x, y, w, h, owner)
        if not self:_clipAllowsBox(y, h) then
            return false
        end
        return (not self._focus or self._focus == owner) and self:_over(x, y, w, h)
    end
    function Window:_tooltip(widget, x, y, w, h, owner)
        if self:_hotInteraction() then
            return nil
        end
        if widget and self:_hover(x, y, w, h, owner) then
            local tip = widget.disabled and widget.disabledTooltip or widget.tooltip
            if tip then
                self.TooltipText = tip
            end
        end
    end

    function Window:_click(x, y, w, h, owner)
        if not self.Mouse1Clicked or self.BlockClicks then
            return false
        end
        local scale = self:GetScale()
        local dropdown = self.DropdownTarget
        local popup = dropdown and dropdown.popup
        if dropdown and dropdown ~= owner and popup then
            local popupH = popup.h or (math.floor(4 * scale) + math.min(#dropdown.options, dropdown.maxVisible or 6) * math.floor(21 * scale))
            if self:_over(popup.x, popup.y - math.floor(22 * scale), popup.w, popupH + math.floor(22 * scale)) then
                return false
            end
        end
        local picker = self.ColorPickerTarget
        local pickerPopup = picker and picker.popup
        if picker and picker ~= owner and pickerPopup then
            if self:_over(pickerPopup.x, pickerPopup.y - math.floor(22 * scale), pickerPopup.w, pickerPopup.h + math.floor(22 * scale)) then
                return false
            end
        end
        return self:_hover(x, y, w, h, owner)
    end
    function Window:_focusClick(x, y, w, h, owner)
        if not self:_clipAllowsBox(y, h) then
            return false
        end
        local scale = self:GetScale()
        local dropdown = self.DropdownTarget
        local popup = dropdown and dropdown.popup
        if dropdown and dropdown ~= owner and popup then
            local popupH = popup.h or (math.floor(4 * scale) + math.min(#dropdown.options, dropdown.maxVisible or 6) * math.floor(21 * scale))
            if self:_over(popup.x, popup.y - math.floor(22 * scale), popup.w, popupH + math.floor(22 * scale)) then
                return false
            end
        end
        local picker = self.ColorPickerTarget
        local pickerPopup = picker and picker.popup
        if picker and picker ~= owner and pickerPopup then
            if self:_over(pickerPopup.x, pickerPopup.y - math.floor(22 * scale), pickerPopup.w, pickerPopup.h + math.floor(22 * scale)) then
                return false
            end
        end
        return self.Mouse1Clicked and not self.BlockClicks and (not self._focus or self._focus == owner) and self:_over(x, y, w, h)
    end
    function Window:_clickFor(owner, x, y, w, h)
        return self:_click(x, y, w, h, owner)
    end

    function Window:_consumeOutsideFloatingClick()
        if not self.Mouse1Clicked then
            return false
        end
        local scale = self:GetScale()
        local dropdown = self.DropdownTarget
        local dropdownPopup = dropdown and dropdown.popup
        if dropdown and dropdownPopup then
            local popupH = dropdownPopup.h or (math.floor(4 * scale) + math.min(#dropdown.options, dropdown.maxVisible or 6) * math.floor(21 * scale))
            local insideDropdown = self:_over(dropdownPopup.x, dropdownPopup.y - math.floor(22 * scale), dropdownPopup.w, popupH + math.floor(22 * scale))
            if not insideDropdown then
                dropdown._searchText = ""
                self.DropdownTarget = nil
                self.DropdownSearch = nil
                self:_releaseInteraction(dropdown)
                self.Mouse1Clicked = false
                return true
            end
            return false
        end
        local picker = self.ColorPickerTarget
        local pickerPopup = picker and picker.popup
        if picker and pickerPopup then
            local insidePicker = self:_over(pickerPopup.x, pickerPopup.y - math.floor(22 * scale), pickerPopup.w, pickerPopup.h + math.floor(22 * scale))
            if not insidePicker then
                self.ColorPickerTarget = nil
                self.ColorPickerDrag = nil
                self:_releaseInteraction(picker)
                self.Mouse1Clicked = false
                return true
            end
            return false
        end
        if self.TextTarget and self.TextTarget.hitbox then
            local hitbox = self.TextTarget.hitbox
            if not self:_over(hitbox.x, hitbox.y, hitbox.w, hitbox.h) then
                local target = self.TextTarget
                self.TextTarget = nil
                self:_releaseInteraction(target)
                self.Mouse1Clicked = false
                return true
            end
        end
        if self.SearchFocused and self.SearchHitbox then
            local hitbox = self.SearchHitbox
            if not self:_over(hitbox.x, hitbox.y, hitbox.w, hitbox.h) then
                self.SearchFocused = false
                self:_releaseInteraction("Search")
                self.Mouse1Clicked = false
                return true
            end
        end
        return false
    end
    function Window:_updateInputBlock()
        local shouldBlock = self.Open == true
        if shouldBlock == self.LastRobloxInputBlocked then
            return nil
        end
        setrobloxinput(not shouldBlock)
        task.spawn(function()
            task.wait(0.1)
            pcall(mouse1click)
        end)
        self.Mouse1Clicked = false
        self.Mouse1Held = false
        self.LastRobloxInputBlocked = shouldBlock
    end

    function Window:_drawIcon(name, x, y, size, active, z)
        name = tostring(name or ""):lower()
        size = size or 14
        name = IconAliases[name] or name
        local data = IconData[name]
        if not data and name:match("^[%w%-]+$") then
            local url = GalaxObsidian.LucideIconUrl .. name .. ".png"
            if not self._iconRequests[name] then
                self._iconRequests[name] = true
                RequestImage(url, function(downloaded)
                    IconData[name] = downloaded
                    self._iconRequests[name] = nil
                end)
            end
            return false
        end
        if not data then return false end
        return self:_image(data, math.floor(x - size / 2), math.floor(y - size / 2), size, size, 0, z, active == true and 0.8 or 0.6) ~= nil
    end
    function Window:_anim(owner, key, target, speed)
        if self.AnimationsEnabled == false then
            AnimationManager:Reset(owner or self, key)
            return target
        end
        return AnimationManager:Approach(owner or self, key, target, speed or 14)
    end
    function Window:_hotInteraction()
        return self.DragOffset ~= nil or self.ResizeOffset ~= nil or self.ScrollTarget ~= nil
    end
    function Window:_animOrSnap(owner, key, target, speed, snap)
        if self.AnimationsEnabled == false then
            AnimationManager:Reset(owner or self, key)
            return target
        end
        if snap or self:_hotInteraction() then
            AnimationManager:Reset(owner or self, key)
            return target
        end
        return self:_anim(owner, key, target, speed)
    end
    function Window:_openKeybindModePopup(widget, x, y, w)
        if not widget or widget.disabled == true then
            return nil
        end
        local popupEnabled = widget.popupEnabled
        if popupEnabled == nil then
            popupEnabled = true
        end
        if not popupEnabled then
            return nil
        end
        local modes = widget.popupModes or DefaultKeybindModePopupModes
        if #modes <= 0 then
            return nil
        end
        local scale = self:GetScale()
        self:_closeFloating("keybindMode")
        self.KeybindModeTarget = widget
        self.KeybindModePopup = { x = x, y = y + math.floor(23 * scale), w = math.max(math.floor(82 * scale), w), h = math.floor(6 * scale) + #modes * math.floor(20 * scale), z = 135 }
        self:_claimInteraction(widget)
        self.Mouse2Clicked = false
    end
    function Window:_keyPressed(key)
        key = keyCodeFromName(key)
        if key == nil then
            return false
        end
        local current = iskeypressed(key) == true
        local previous = self.PrevKeys[key] == true
        self.PrevKeys[key] = current
        return current and not previous
    end
    function Window:_updateInput()
        local moved = mouse.X ~= self._lastMouseX or mouse.Y ~= self._lastMouseY
        self._lastMouseX = mouse.X
        self._lastMouseY = mouse.Y
        local down = ismouse1pressed() == true
        self.Mouse1Clicked = down and not self.PrevMouse1
        self.Mouse1Held = down
        self.PrevMouse1 = down
        local down2 = type(ismouse2pressed) == "function" and ismouse2pressed() == true or false
        self.Mouse2Clicked = down2 and not self.PrevMouse2
        self.Mouse2Held = down2
        self.PrevMouse2 = down2
        local down3 = type(ismouse3pressed) == "function" and ismouse3pressed() == true
            or type(iskeypressed) == "function" and iskeypressed(4) == true
        self.Mouse3Clicked = down3 and not self.PrevMouse3
        self.Mouse3Held = down3
        self.PrevMouse3 = down3
        local down4 = type(ismouse4pressed) == "function" and ismouse4pressed() == true
            or type(iskeypressed) == "function" and iskeypressed(5) == true
        self.Mouse4Clicked = down4 and not self.PrevMouse4
        self.Mouse4Held = down4
        self.PrevMouse4 = down4
        local down5 = type(ismouse5pressed) == "function" and ismouse5pressed() == true
            or type(iskeypressed) == "function" and iskeypressed(6) == true
        self.Mouse5Clicked = down5 and not self.PrevMouse5
        self.Mouse5Held = down5
        self.PrevMouse5 = down5
        if moved or down or down2 or down3 or down4 or down5 or self.DragOffset or self.ResizeOffset or self.ScrollTarget then
            self._lastActivity = tick()
        end
    end

    function Window:_readListenKey()
        if self.Mouse3Clicked then
            return 4
        end
        if self.Mouse4Clicked then
            return 5
        end
        if self.Mouse5Clicked then
            return 6
        end
        for key = 7, 255 do
            if self:_keyPressed(key) then
                return key
            end
        end
        return nil
    end
    function Window:_readTextInput()
        if self:_keyPressed(0x08) then
            return "backspace"
        end
        if self:_keyPressed(0x0D) then
            return "enter"
        end
        if self:_keyPressed(0x20) then
            return " "
        end
        if type(iskeypressed) == "function" and iskeypressed(0x11) and self:_keyPressed(0x5A) then
            return "clear"
        end
        for key, char in pairs(TextChars) do
            if self:_keyPressed(key) then
                if iskeypressed(0x10) or iskeypressed(0xA1) then
                    return string.upper(char)
                end
                return char
            end
        end
        return nil
    end
    function Window:_renderTextInputValue(value, placeholder, x, y, w, size, focused, disabled, z, outline, align)
        return TextManager:RenderInput(
            self,
            value,
            placeholder,
            x,
            y,
            w,
            {
                Size = size,
                Font = Theme.Font,
                Focused = focused and not self:_hotInteraction(),
                Disabled = disabled,
                Color = Theme.Text,
                PlaceholderColor = Theme.Muted,
                DisabledColor = Theme.DimText,
                Outline = outline ~= false,
                Align = align,
                ZIndex = z,
            }
        )
    end
    function Window:_readBackspaceRepeat()
        local down = iskeypressed(0x08) == true
        if not down then
            if self.HoldKey == 0x08 then
                self.HoldKey = nil
                self.HoldStarted = 0
                self.HoldLastRepeat = 0
            end
            return false
        end
        local now = tick()
        if self.HoldKey ~= 0x08 then
            self.HoldKey = 0x08
            self.HoldStarted = now
            self.HoldLastRepeat = now
            return false
        end
        if now - self.HoldStarted >= 0.35 and now - self.HoldLastRepeat >= 0.1 then
            self.HoldLastRepeat = now
            return true
        end
        return false
    end

    function Window:_setAllVisible(visible)
        for _, list in pairs(self.Pool) do
            for _, object in ipairs(list) do
                object.Visible = visible
            end
        end
    end
    function Window:_clearInteraction()
        if self.DropdownTarget then
            self.DropdownTarget._searchText = ""
        end
        self.DropdownTarget = nil
        self.ColorPickerTarget = nil
        self.ColorPickerDrag = nil
        self.KeyListenTarget = nil
        self.KeyListenStarted = 0
        self.KeybindModeTarget = nil
        self.KeybindModePopup = nil
        self.TextTarget = nil
        self.TooltipText = nil
        self.SearchFocused = false
        self.DropdownSearch = nil
        self.SliderTarget = nil
        self.HoldKey = nil
        self.HoldStarted = 0
        self.HoldLastRepeat = 0
        self._focus = nil
        self.DragOffset = nil
        self.ResizeOffset = nil
        self.KeybindMenuDrag = nil
        self.BlockClicks = false
    end
    function Window:_claimInteraction(owner)
        self:MouseFocus(owner)
    end
    function Window:_releaseInteraction(owner, keepClick)
        if owner == nil or self._focus == owner then
            self._focus = nil
            if keepClick ~= true then
                self.Mouse1Clicked = false
            end
        end
    end

    function Window:_clearKeybind(widget)
        if not widget then
            return nil
        end
        if _isToggle(widget) then
            widget.keybind = nil
            widget.value = false
            _fire(widget, false)
        else
            widget.value = nil
            widget._state = false
            widget._prevHeld = false
            safeCall(widget.changed, nil)
            safeCall(widget.callback, false)
            if widget.parent and _isToggle(widget.parent) then
                widget.parent.value = false
                _fire(widget.parent, false)
            end
        end
        widget._keybindCleared = true
        widget.listening = false
        if self.KeyListenTarget == widget then
            self.KeyListenTarget = nil
            self.KeyListenStarted = 0
        end
        self:_releaseInteraction(widget)
    end

    function Window:_handleKeybindHoldClear(widget)
        if
            widget
            and widget.listening == true
            and self.KeyListenTarget == widget
            and self.Mouse1Held
            and tick() - self.KeyListenStarted >= 1
        then
            self:_clearKeybind(widget)
            return true
        end
        return false
    end

    function Window:_syncToggleKeypickerAddons(toggleWidget)
        for _, addon in ipairs(toggleWidget.addons or {}) do
            if addon.type == "keybind" and addon.syncToggleState then
                addon._state = toggleWidget.value == true
            end
        end
    end

    function Window:_startListening(target)
        target.listening = true
        target._keybindCleared = false
        self.KeyListenTarget = target
        self.KeyListenStarted = tick()
        self.BlockClicks = true
        self:_claimInteraction(target)
    end

    function Window:_flipWidget(w)
        w.value = not w.value
        self:_syncToggleKeypickerAddons(w)
        _fire(w, w.value)
    end

    function Window:_closeFloating(except)
        if except ~= "dropdown" then
            local old = self.DropdownTarget
            if old then
                old._searchText = ""
            end
            self.DropdownTarget = nil
            self.DropdownSearch = nil
            if old then
                self:_releaseInteraction(old)
            end
        end
        if except ~= "colorpicker" then
            local old = self.ColorPickerTarget
            self.ColorPickerTarget = nil
            self.ColorPickerDrag = nil
            if old then
                self:_releaseInteraction(old)
            end
        end
        if except ~= "textbox" then
            local old = self.TextTarget
            self.TextTarget = nil
            if old then
                self:_releaseInteraction(old)
            end
        end
        if except ~= "search" then
            self.SearchFocused = false
        end
        if except ~= "keybindMode" then
            if self.KeybindModeTarget then
                self:_releaseInteraction(self.KeybindModeTarget)
            end
            self.KeybindModeTarget = nil
            self.KeybindModePopup = nil
        end
    end

    function Window:SetCornerRadius(radius)
        self._cornerRadius = math.min(10, math.max(0, math.floor(radius or 0)))
        GalaxObsidian.CornerRadius = self._cornerRadius
    end
    function Window:_setOpen(state)
        self.Open = state == true
        self:_clearInteraction()
        self:_updateInputBlock()
    end

    function Window:_handleGlobalInput()
        if self.KeyListenTarget then
            local key = self:_readListenKey()
            if key then
                if _isToggle(self.KeyListenTarget) then
                    self.KeyListenTarget.keybind = key
                else
                    self.KeyListenTarget.value = key
                    safeCall(self.KeyListenTarget.changed, key)
                end
                self.KeyListenTarget._keybindCleared = false
                self.KeyListenTarget.listening = false
                self.KeyListenTarget = nil
                self.KeyListenStarted = 0
                self:_releaseInteraction()
            elseif self.Mouse1Clicked and tick() - self.KeyListenStarted > 0.1 then
                self.KeyListenTarget.listening = false
                self.KeyListenTarget = nil
                self.KeyListenStarted = 0
                self:_releaseInteraction()
            end
            return nil
        end
        if self:_keyPressed(self.MenuKey) then
            self:_setOpen(not self.Open)
        end
        if self.SearchFocused then
            local char = self:_readTextInput()
            if char == "backspace" or self:_readBackspaceRepeat() then
                self.SearchText = string.sub(self.SearchText, 1, math.max(0, #self.SearchText - 1))
            elseif char == "clear" then
                self.SearchText = ""
            elseif char == "enter" then
                self.SearchFocused = false
                self:_releaseInteraction("Search", true)
            elseif char then
                self.SearchText = self.SearchText .. char
            end
            return nil
        end
        if self.DropdownSearch then
            local char = self:_readTextInput()
            if char == "backspace" or self:_readBackspaceRepeat() then
                self.DropdownSearch._searchText = string.sub(
                    self.DropdownSearch._searchText or "",
                    1,
                    math.max(0, #(self.DropdownSearch._searchText or "") - 1)
                )
                self.DropdownSearch._dropdownScroll = 0
            elseif char == "clear" then
                self.DropdownSearch._searchText = ""
                self.DropdownSearch._dropdownScroll = 0
            elseif char == "enter" then
                local widget = self.DropdownSearch
                self.DropdownSearch = nil
                self:_releaseInteraction(widget)
            elseif char then
                self.DropdownSearch._searchText = (self.DropdownSearch._searchText or "") .. char
                self.DropdownSearch._dropdownScroll = 0
            end
            return nil
        end
        if self.TextTarget then
            local char = self:_readTextInput()
            local target = self.TextTarget
            if char == "backspace" or self:_readBackspaceRepeat() then
                target.value = string.sub(target.value, 1, math.max(0, #target.value - 1))
                if target.type ~= "keybox" and not target.finished then
                    _fire(target, target.value)
                end
            elseif char == "clear" then
                target.value = ""
                if target.type ~= "keybox" and not target.finished then
                    _fire(target, target.value)
                end
            elseif char == "enter" then
                _fire(target, target.value)
                self.TextTarget = nil
                self:_releaseInteraction(target, true)
            elseif char then
                if target.numeric then
                    if char:match("^[%d%-]$") then
                        target.value = target.value .. char
                    elseif char == "." and not target.value:find("%.") then
                        target.value = target.value .. char
                    end
                else
                    target.value = target.value .. char
                end
                if target.type ~= "keybox" and not target.finished then
                    _fire(target, target.value)
                end
            end
        end
        self:_processHotkeys()
    end
    function Window:_processHotkeys()
        if self.SearchFocused or self.TextTarget or self.KeyListenTarget or self.DropdownSearch then
            return nil
        end
        if self.DropdownTarget or self.ColorPickerTarget or self.KeybindModeTarget then
            return nil
        end
        if #self.Tabs <= 0 then
            return nil
        end
        local function processWidget(widget)
            if widget.type == "sectiontabs" then
                local active = widget.tabs[widget.active or 1]
                if active then
                    for _, child in ipairs(active.widgets) do
                        processWidget(child)
                    end
                end
                return nil
            end
            if widget.type == "label" then
                local addons = widget.addons or {}
                for _, addon in ipairs(addons) do
                    if addon.type == "keybind" then
                        processWidget(addon)
                    end
                end
                return nil
            end
            if
                (_isToggle(widget))
                and widget.keybind
                and widget.disabled ~= true
                and widget.listening ~= true
            then
                if self:_keyPressed(widget.keybind) then
                    self:_flipWidget(widget)
                end
            end
            if _isToggle(widget) then
                local addons = widget.addons or {}
                for _, addon in ipairs(addons) do
                    if addon.type == "keybind" then
                        processWidget(addon)
                    end
                end
            end
            if
                widget.type == "keybind"
                and widget.value
                and widget.disabled ~= true
                and widget.listening ~= true
            then
                local resolvedKey = keyCodeFromName(widget.value)
                local keyHeld
                if resolvedKey == 4 then
                    keyHeld = type(ismouse3pressed) == "function" and ismouse3pressed() == true
                        or type(iskeypressed) == "function" and iskeypressed(4) == true
                elseif resolvedKey == 5 then
                    keyHeld = type(ismouse4pressed) == "function" and ismouse4pressed() == true
                        or type(iskeypressed) == "function" and iskeypressed(5) == true
                elseif resolvedKey == 6 then
                    keyHeld = type(ismouse5pressed) == "function" and ismouse5pressed() == true
                        or type(iskeypressed) == "function" and iskeypressed(6) == true
                else
                    keyHeld = resolvedKey ~= nil and iskeypressed(resolvedKey) == true
                end
                local wasHeld = widget._prevHeld == true
                local mode = tostring(widget.mode or "Hold")
                if mode == "Hold" then
                    if widget._state ~= keyHeld then
                        widget._state = keyHeld
                        safeCall(widget.callback, keyHeld)
                    end
                elseif mode == "Toggle" then
                    if keyHeld and not wasHeld then
                        widget._state = not widget._state
                        if widget.parent and _isToggle(widget.parent) then
                            widget.parent.value = widget._state
                            self:_syncToggleKeypickerAddons(widget.parent)
                            _fire(widget.parent, widget.parent.value)
                        else
                            safeCall(widget.callback, widget._state)
                        end
                    end
                elseif mode == "Always" then
                    widget._state = true
                    if widget.parent and _isToggle(widget.parent) then
                        if widget.parent.value ~= true then
                            widget.parent.value = true
                            self:_syncToggleKeypickerAddons(widget.parent)
                            _fire(widget.parent, true)
                        end
                    else
                        safeCall(widget.callback, true)
                    end
                    keyHeld = true
                elseif mode == "Press" then
                    if keyHeld and not wasHeld then
                        widget._state = true
                        safeCall(widget.callback, true)
                        widget._state = false
                    end
                end
                widget._prevHeld = keyHeld
            end
        end
        for _, tab in ipairs(self.Tabs) do
            for _, section in ipairs(tab.Sections or {}) do
                for _, widget in ipairs(section.widgets or {}) do
                    processWidget(widget)
                end
            end
        end
    end

    local function makeColorPickerAddon(name, info)
        info = info or {}
        local default = info.Default or Color3.new(1, 1, 1)
        local hue, sat, vib = rgbToHsv(default)
        return {
            type = "colorpicker",
            isAddon = true,
            id = name,
            label = info.Text or info.Label or info.Title or tostring(name or "Color"),
            title = info.Title,
            value = default,
            hue = hue,
            sat = sat,
            vib = vib,
            transparency = info.Transparency or 0,
            transparencyEnabled = info.Transparency ~= nil,
            callback = info.Callback,
            changed = info.Changed,
            tooltip = info.Tooltip,
            disabled = info.Disabled == true,
            visible = info.Visible ~= false,
            popup = nil,
        }
    end

    local function makeKeybindAddon(name, info, parent)
        info = info or {}
        local addon = {
            type = "keybind",
            isAddon = true,
            id = name,
            label = info.Text or info.Label or tostring(name or "Keybind"),
            value = info.Default,
            mode = info.Mode or "Hold",
            syncToggleState = info.SyncToggleState == true,
            callback = info.Callback,
            changed = info.Changed or info.ChangedCallback,
            tooltip = info.Tooltip,
            disabled = info.Disabled == true,
            visible = info.Visible ~= false,
            _state = false,
            _prevHeld = false,
            popup = nil,
            parent = parent,
        }
        if info.Popup ~= nil then
            local enabled, modes = resolveKeybindPopupConfig(info.Popup)
            addon.popupEnabled = enabled
            addon.popupModes = modes
        end
        return addon
    end

    local function makeAddKeyPickerClosure(widget, keybindGetters)
        return function(_, name, info)
            info = info or {}
            if info.Mode == "Press" then
                assert(widget.type == "label", "KeyPicker with mode 'Press' can only be applied on Labels.")
                info.SyncToggleState = false
                info.Modes = { "Press" }
            end
            widget.addons = widget.addons or {}
            local addon = makeKeybindAddon(name, info, widget)
            addon.mode = info.Mode or "Toggle"
            if _isToggle(widget) then
                addon.callback = function(v)
                    if type(v) == "boolean" then widget.value = v else widget.value = not widget.value end
                    _fire(widget, widget.value)
                end
            end
            widget.addons[#widget.addons + 1] = addon
            if keybindGetters then
                return Window:_widgetHandle(addon, {
                    Get = function()
                        return addon.value
                    end,
                    SetValue = function(_, val, mode)
                        if type(val) == "table" then
                            addon.value = val[1] or val.Key or val.key or addon.value
                            addon.mode = val[2] or val.Mode or val.mode or addon.mode
                            addon.modifiers = val.Modifiers or val.modifiers
                        else
                            addon.value = val
                            addon.mode = mode or addon.mode
                        end
                        safeCall(addon.changed, addon.value, addon.modifiers)
                    end,
                    OnChanged = function(_, cb)
                        addon.changed = cb
                    end,
                    OnClick = function(_, cb)
                        if addon.callback then
                            local old = addon.callback
                            addon.callback = function(v)
                                old(v)
                                cb(v)
                            end
                        else
                            addon.callback = cb
                        end
                    end,
                })
            else
                return Window:_widgetHandle(addon)
            end
        end
    end

    local function makeAddColorPickerClosure(widget, colorpickerGetters)
        return function(_, name, info)
            widget.addons = widget.addons or {}
            local addon = makeColorPickerAddon(name, info)
            widget.addons[#widget.addons + 1] = addon
            if colorpickerGetters then
                return Window:_widgetHandle(addon, {
                    Get = function()
                        return addon.value, addon.transparency
                    end,
                    SetValueRGB = function(_, color, transparency)
                        addon.value = color
                        addon.transparency = addon.transparencyEnabled and (transparency or 0) or 0
                        addon.hue, addon.sat, addon.vib = rgbToHsv(color)
                        _fire(addon, addon.value, addon.transparency)
                    end,
                })
            else
                return Window:_widgetHandle(addon)
            end
        end
    end

    function Window:_widgetHandle(widget, getters)
        local handle = makeHandle(widget)
        if getters then
            for k, v in pairs(getters) do
                handle[k] = v
            end
        end
        do
            local TypeMap = {
                toggle = "Toggle",
                checkbox = "Toggle",
                slider = "Slider",
                dropdown = "Dropdown",
                multidropdown = "Dropdown",
                colorpicker = "ColorPicker",
                keybind = "KeyPicker",
                keybox = "Input",
                textbox = "Input",
            }
            handle.Type = TypeMap[widget.type] or widget.type:sub(1, 1):upper() .. widget.type:sub(2)
        end
        handle.AddColorPicker = makeAddColorPickerClosure(widget, false)
        handle.AddKeyPicker = makeAddKeyPickerClosure(widget, false)
        if widget.id then
            if _isToggle(widget) then
                self.Toggles[widget.id] = handle
            else
                self.Options[widget.id] = handle
            end
        end
        return handle
    end

    function Window:_matchesSearch(widget, section)
        if widget.visible == false or not dependencyVisible(widget) then
            return false
        end
        local search = string.lower(self.SearchText or "")
        if search == "" then
            return true
        end
        if section and section.Name then
            local sectionName = string.lower(section.Name)
            if sectionName:sub(1, 2) ~= "__" and string.find(sectionName, search, 1, true) then
                return true
            end
        end
        local text = tostring(widget.label or widget.text or "")
        if widget.type == "colorpair" then
            text = tostring(
                (widget.left and widget.left.label or "") .. " " .. (widget.right and widget.right.label or "")
            )
        elseif widget.type == "buttonpair" then
            text = tostring(
                (widget.left and widget.left.label or "") .. " " .. (widget.right and widget.right.label or "")
            )
        elseif widget.type == "sectiontabs" then
            text = ""
            for _, tab in ipairs(widget.tabs) do
                text = text .. " " .. tostring(tab.name or "")
                for _, child in ipairs(tab.widgets) do
                    text = text .. " " .. tostring(child.label or child.text or "")
                end
            end
        end
        return string.find(string.lower(text), search, 1, true) ~= nil
    end

    function Window:_widgetHeight(widget)
        if widget.visible == false or not dependencyVisible(widget) then
            return 0
        end
        local scale = self:GetScale()
        local base = 30
        if widget.type == "divider" then
            base = 6 + (widget.marginTop or 0) + (widget.marginBottom or 0)
        elseif widget.type == "colorpicker" then
            base = 26
        elseif widget.type == "colorpair" then
            base = 26
        elseif widget.type == "buttonpair" then
            base = 21
        elseif widget.type == "sectiontabs" then
            base = 40
            local height = math.floor(base * scale + 0.5)
            local active = widget.tabs[widget.active or 1]
            if active then
                for _, child in ipairs(active.widgets) do
                    if child.visible ~= false then
                        height = height + self:_widgetHeight(child)
                    end
                end
            end
            return height
        elseif widget.type == "label" then
            local textSize = widget.size or 14
            if widget.doesWrap ~= false then
                local labelWidth = widget._calcWidth or math.floor(200 * scale)
                local lines = wrapTextLines(widget.text or "", labelWidth, textSize, 8, Theme.Font)
                base = math.max(18, #lines * textSize + 4)
            else
                base = math.max(18, textSize + 4)
            end
        elseif widget.type == "slider" then
            base = widget.compact and 15 or 33
        elseif widget.type == "image" then
            base = widget.height or 120
        elseif _isToggle(widget) then
            base = 18
        elseif widget.type == "dropdown" or widget.type == "multidropdown" then
            base = 39
        elseif widget.type == "textbox" then
            base = 39
        elseif widget.type == "keybox" or widget.type == "keybind" then
            base = 24
        elseif widget.type == "button" then
            base = 21
        end
        return math.floor(base * scale + 0.5)
    end
    function Window:_sectionHeight(section)
        local scale = self:GetScale()
        local height = math.floor(49 * scale)
        if section.Name and section.Name:sub(1, 2) == "__" then
            height = math.floor(14 * scale)
        end
        local count = 0
        for _, widget in ipairs(section.widgets) do
            if self:_matchesSearch(widget, section) then
                height = height + self:_widgetHeight(widget)
                count = count + 1
            end
        end
        if count > 1 then
            height = height + (count - 1) * math.floor(8 * scale)
        end
        return height
    end

    function Window:_sectionVisible(section)
        for _, widget in ipairs(section.widgets) do
            if self:_matchesSearch(widget, section) then
                return true
            end
        end
        return string.lower(self.SearchText or "") == ""
    end

    function Window:_renderKeybindButton(widget, x, y, w, h, label, ts, z, pfx, bg, ol)
        self:_handleKeybindHoldClear(widget)
        local sc = self:GetScale()
        self:_square(x, y, w, h, self:_anim(widget, pfx.."key.bg", bg, 16), true, 1, 2, z + 1)
        self:_square(x, y, w, h, self:_anim(widget, pfx.."key.outline", widget.listening and self.Accent or ol, 16), false, 1, 2, z + 2)
        local txt = self:_anim(widget, pfx.."key.text", Theme.Text, 16)
        self:_text(fitTextToWidth(label, w - math.floor(10 * sc), ts, Theme.Font), x + math.floor(w / 2), y + math.floor(h / 2) - math.floor(_scaled(ts, sc) / 2) - _yOfs(sc), txt, ts, Theme.Font, true, true, z + 3)
        if widget.disabled ~= true and self:_click(x, y, w, h) then self:_startListening(widget) end
    end

    function Window:_renderAddonKeybind(addon, ax, y, aw, asz, ts, z, fc)
        local l = addon.listening and "..." or (addon.value and keyName(addon.value) or "?")
        self:_handleKeybindHoldClear(addon)
        local sc = self:GetScale()
        self:_square(ax, y, aw, asz, Theme.Surface, true, 1, 2, z + 1)
        self:_square(ax, y, aw, asz, addon.listening and self.Accent or Theme.Outline, false, 1, 2, z + 2)
        self:_text(fitTextToWidth(l, aw - math.floor(10 * sc), ts, Theme.Font), ax + math.floor(aw / 2), y + math.floor(asz / 2) - math.floor(_scaled(ts, sc) / 2) - _yOfs(sc), Theme.Text, ts, Theme.Font, true, true, z + 3)
        if addon.disabled ~= true and self.Mouse2Clicked and (not fc or not self._focus or self._focus == addon) and self:_over(ax, y, aw, asz) then
            self:_openKeybindModePopup(addon, ax, y, aw)
        end
        if addon.disabled ~= true and self:_click(ax, y, aw, asz) then
            self:_startListening(addon)
        end
    end

    function Window:_renderCheckbox(widget, x, y, w, z)
        local scale = self:GetScale()
        local boxX = x
        local disabled = widget.disabled == true
        local keyLabel = (widget._hasKeyPicker or widget.listening or widget._keybindCleared)
            and (widget.listening and "..." or (widget.keybind and keyName(widget.keybind) or "?"))
            or nil
        local keyTextSize = 14
        local keyH = math.floor(18 * scale)
        local keyW = keyLabel and math.max(math.floor(40 * scale), math.floor(estimateTextWidth(keyLabel, keyTextSize, Theme.Font) + math.floor(26 * scale))) or 0
        local keyX = keyLabel and (x + w - keyW) or nil
        local labelMaxW = keyLabel and (w - keyW - math.floor(34 * scale)) or (w - math.floor(26 * scale))
        local overBox = not disabled and self:_hover(x, y, w, math.floor(18 * scale), widget)
        local checkBoxBg = self:_anim(widget, "checkbox.bg", overBox and Theme.Surface2 or Theme.Main, 16)
        local checkBoxOutline = self:_anim(
            widget,
            "checkbox.outline",
            widget.value and Theme.Outline2 or (overBox and Theme.Outline2 or Theme.Outline),
            16
        )
        local checkText = self:_anim(widget, "checkbox.text", widget.value and Theme.Text or Theme.Muted or Theme.DimText, 16)
        self:_tooltip(widget, x, y, w, math.floor(21 * scale), widget)
        local boxY = y + math.floor(2 * scale)
        local boxSize = math.floor(14 * scale)
        self:_square(boxX, boxY, boxSize, boxSize, checkBoxBg, true, disabled and 0.55 or 1, 2, z + 1)
        self:_square(boxX, boxY, boxSize, boxSize, checkBoxOutline, false, disabled and 0.55 or 1, 2, z + 2)
        if widget.value then
            self:_drawIcon("check", boxX + math.floor(7 * scale), y + math.floor(9 * scale), math.floor(12 * scale), true, z + 4)
        end
        self:_text(
            fitTextToWidth(widget.label, labelMaxW, 14, Theme.Font),
            x + math.floor(21 * scale),
            y + math.floor(2 * scale),
            checkText,
            14,
            Drawing.Fonts.Monospace,
            false,
            true,
            z + 2
        )
        if keyLabel then
            local ok = self:_hover(keyX, y, keyW, keyH, widget)
            self:_renderKeybindButton(widget, keyX, y, keyW, keyH, keyLabel, keyTextSize, z, "checkbox.",
                ok and Theme.Surface2 or Theme.Surface,
                ok and Theme.Outline2 or Theme.Outline)
        end
        if not disabled and self:_click(x, y, w, math.floor(18 * scale)) then
            self:_flipWidget(widget)
        end
    end

    function Window:_renderToggle(widget, x, y, w, z)
        local disabled = widget.disabled == true
        local scale = self:GetScale()
        local switchW = math.floor(32 * scale)
        local switchH = math.floor(18 * scale)
        local switchX = x + w - switchW
        local switchY = y + math.floor(0 * scale)
        local keyLabel = (widget._hasKeyPicker or widget.listening or widget._keybindCleared)
            and (widget.listening and "..." or (widget.keybind and keyName(widget.keybind) or "?"))
            or nil
        local keyTextSize = 14
        local keyH = math.floor(18 * scale)
        local keyW = keyLabel and math.max(math.floor(40 * scale), math.floor(estimateTextWidth(keyLabel, keyTextSize, Theme.Font) + math.floor(26 * scale))) or 0
        local addons = widget.addons or {}
        local addonSize = math.floor(18 * scale)
        local addonGap = math.floor(4 * scale)
        local addonCount = 0
        local addonTotalW = 0
        local addonWidths = {}
        for i, a in ipairs(addons) do
            if a.visible ~= false then
                local aw = addonSize
                if a.type == "keybind" then
                    local kLabel = a.listening and "..." or (a.value and keyName(a.value) or "?")
                    local textW = estimateTextWidth(kLabel, keyTextSize, Theme.Font)
                    aw = math.max(addonSize, textW + math.floor(12 * scale))
                end
                addonWidths[i] = aw
                addonTotalW = addonTotalW + aw
                addonCount = addonCount + 1
            end
        end
        local addonAreaW = addonCount > 0 and (addonTotalW + (addonCount - 1) * addonGap + math.floor(4 * scale)) or 0
        local addonStartX = switchX - addonAreaW - math.floor(6 * scale)
        local keyX = addonStartX - keyW - math.floor(6 * scale)
        local toggleText = self:_anim(widget, "toggle.text", widget.value and Theme.Text or Theme.Muted or Theme.DimText, 16)
        self:_tooltip(widget, x, y, w, math.floor(21 * scale), widget)
        self:_text(
            fitTextToWidth(widget.label, w - switchW - keyW - addonAreaW - math.floor(18 * scale), 14, Theme.Font),
            x,
            y + math.floor(2 * scale),
            toggleText,
            14,
            Drawing.Fonts.Monospace,
            false,
            true,
            z + 2
        )
        if keyLabel then
            self:_renderKeybindButton(widget, keyX, y, keyW, keyH, keyLabel, keyTextSize, z, "toggle.",
                Theme.Surface, Theme.Outline)
        end
        if addonCount > 0 and addonStartX then
            local ax = addonStartX
            for i, addon in ipairs(addons) do
                if addon.visible ~= false then
                    local aw = addonWidths[i] or addonSize
                    if addon.type == "keybind" then
                        self:_renderAddonKeybind(addon, ax, y, aw, addonSize, keyTextSize, z, false)
                    else
                        self:_renderColorSwatch(addon, ax, y + math.floor(0 * scale), addonSize, z + 1)
                    end
                    ax = ax + aw + addonGap
                end
            end
        end
        local thumbR = math.floor(switchH / 2) - math.floor(2 * scale)
        local targetTrack = widget.value and self.Accent or Theme.Surface
        local targetBorder = widget.value and self.Accent or Theme.Outline
        local targetThumb = Color3.fromRGB(255, 255, 255)
        local thumbMinX = switchX + thumbR + math.floor(3 * scale)
        local thumbMaxX = switchX + switchW - thumbR - math.floor(3 * scale)
        local thumbProgress =
            self:_animOrSnap(widget, "toggle.thumbProgress", widget.value and 1 or 0, 18, self:_hotInteraction())
        local thumbX = thumbMinX + (thumbMaxX - thumbMinX) * thumbProgress
        local trackColor = self:_anim(widget, "toggle.track", targetTrack, 16)
        local borderColor = self:_anim(widget, "toggle.border", targetBorder, 16)
        local thumbColor = self:_anim(widget, "toggle.thumbColor", targetThumb, 16)
        self:_square(switchX, switchY, switchW, switchH, trackColor, true, disabled and 0.55 or 1, switchH, z + 1)
        self:_square(switchX, switchY, switchW, switchH, borderColor, false, disabled and 0.55 or 1, switchH, z + 2)
        self:_circle(thumbX, switchY + switchH / 2, thumbR, thumbColor, true, 1, z + 3)
        if not disabled and self:_focusClick(x, y, w, math.floor(21 * scale), widget) then
            self:_flipWidget(widget)
            self:_releaseInteraction(widget)
        end
    end

    function Window:_renderSlider(widget, x, y, w, z)
        local disabled = widget.disabled == true
        local compact = widget.compact == true
        local currentText = formatNumber(widget.value, widget.rounding)
        local maxText = formatNumber(widget.max or 0, widget.rounding)
        if widget.formatDisplayValue then
            local custom = widget.formatDisplayValue(widget, widget.value)
            if custom ~= nil then
                currentText = tostring(custom)
                maxText = ""
            end
        end
        local prefix = tostring(widget.prefix or "")
        local suffix = tostring(widget.suffix or "")
        local currentDisplay = prefix .. currentText .. suffix
        local maxDisplay = prefix .. maxText .. suffix
        local valueText
        if widget.formatDisplayValue and maxText == "" then
            valueText = currentText
        elseif compact then
            valueText = tostring(widget.label or "Slider") .. ": " .. currentDisplay
        elseif widget.hideMax then
            valueText = currentDisplay
        else
            valueText = currentDisplay .. "/" .. maxDisplay
        end
        local scale = self:GetScale()
        if not compact then
            self:_tooltip(widget, x, y, w, math.floor(33 * scale), widget)
            local sliderLabelText =
                self:_anim(widget, "slider.label.text", disabled and Theme.DimText or Theme.Text, 16)
            self:_text(
                fitTextToWidth(widget.label, w, 14, Theme.Font),
                x,
                y + math.floor(2 * scale),
                sliderLabelText,
                14,
                Drawing.Fonts.Monospace,
                false,
                true,
                z + 2
            )
        end
        local labelH = compact and 0 or math.floor(18 * scale)
        local barH = math.floor(15 * scale)
        local barX, barY, barW = x, y + labelH, w
        if compact then
            barY = y
        end
        local percent = 0
        if widget.max ~= widget.min then
            percent = clamp((widget.value - widget.min) / (widget.max - widget.min), 0, 1)
        end
        local fillW
        if self:_hotInteraction() or self._scaleChanged then
            AnimationManager:Reset(widget, "slider.fill")
            fillW = math.floor(barW * percent + 0.5)
        else
            fillW = math.floor(self:_anim(widget, "slider.fill", barW * percent, 18) + 0.5)
        end
        local sliderFillColor = self:_anim(widget, "slider.fillColor", disabled and Theme.Outline2 or self.Accent, 16)
        self:_square(barX, barY, barW, barH, Theme.Main, true, disabled and 0.45 or 1, 3, z + 1)
        self:_square(barX, barY, barW, barH, Theme.Outline, false, disabled and 0.45 or 1, 3, z + 2)
        if fillW > 0 then
            self:_square(barX, barY, fillW, barH, sliderFillColor, true, 1, 3, z + 3)
        end
        local centeredValueW = estimateTextWidth(valueText, 14, Theme.Font)
        local scaledValTextSize = math.floor(14 * scale + 0.5)
        local sliderValueText = self:_anim(widget, "slider.value.text", disabled and Theme.DimText or Theme.Text, 16)
        local sliderInput = widget._input
        local inputFocused = sliderInput and self.TextTarget == sliderInput
        if inputFocused then
            sliderInput.hitbox = { x = barX, y = barY, w = barW, h = barH }
            self:_renderTextInputValue(sliderInput.value, "", barX + math.floor(6 * scale), barY + math.floor((barH - scaledValTextSize) / 2), barW - math.floor(12 * scale), 14, true, false, z + 4, true, "center")
        else
            self:_text(valueText, barX + math.floor((barW - centeredValueW) / 2), barY + math.floor((barH - scaledValTextSize) / 2), sliderValueText, 14, Drawing.Fonts.Monospace, false, true, z + 4)
        end
        if not disabled and widget.allowRightClickInput and self.Mouse2Clicked and self:_over(barX, barY, barW, barH) then
            local input = widget._input or { type = "sliderinput", numeric = true, finished = true }
            input.value = formatNumber(widget.value, widget.rounding)
            input.callback = function(value)
                local numeric = tonumber(value)
                if numeric then
                    numeric = clamp(numeric, widget.min, widget.max)
                    if widget.rounding ~= false then numeric = roundNumber(numeric, widget.rounding) end
                    if widget.value ~= numeric then widget.value = numeric; _fire(widget, widget.value) end
                end
            end
            widget._input = input
            self.TextTarget = input
            self:_closeFloating("textbox")
            self:_claimInteraction(input)
            self.Mouse2Clicked = false
        end
        if not disabled and self:_click(barX, barY - math.floor(4 * scale), barW, barH + math.floor(8 * scale)) then
            self.SliderTarget = widget
            self:_claimInteraction(widget)
        end
        if self.SliderTarget == widget and self.Mouse1Held then
            local nextPercent = clamp((mouse.X - barX) / barW, 0, 1)
            local nextValue = widget.min + (widget.max - widget.min) * nextPercent
            if widget.rounding ~= false then
                nextValue = roundNumber(nextValue, widget.rounding)
            end
            if widget.integer then
                nextValue = math.floor(nextValue)
            end
            if widget.value ~= nextValue then
                widget.value = nextValue
                _fire(widget, widget.value)
            end
        elseif self.SliderTarget == widget then
            self.SliderTarget = nil
            self:_releaseInteraction(widget)
        end
    end

    function Window:_renderDropdown(widget, x, y, w, z, multi)
        local disabled = widget.disabled == true
        local searchable = widget.searchable == true
        local isOpen = self.DropdownTarget == widget
        local searchActive = isOpen and searchable and self.DropdownSearch == widget
        local display = widget.value
        if multi then
            local list = {}

            for _, option in ipairs(widget.options) do
                if widget.selected[option] then
                    list[#list + 1] = option
                end
            end
            display = #list > 0 and table.concat(list, ", ") or "---"
        elseif display == nil or display == "" then
            display = widget.placeholder or "---"
        end
        if widget.formatDisplayValue and not multi then
            local formatted = widget.formatDisplayValue(display)
            if formatted ~= nil then
                display = formatted
            end
        end
        local searchText = widget._searchText or ""
        local showSearchText = searchable and isOpen
        local buttonDisplay = showSearchText and searchText or display
        local buttonPlaceholder = showSearchText and "Search..." or ""
        local dropdownBg = self:_anim(widget, "dropdown.bg", Theme.Surface, 16)
        local dropdownOutline =
            self:_anim(widget, "dropdown.outline", Theme.Outline, 16)
        local dropdownLabel = self:_anim(widget, "dropdown.label.text", disabled and Theme.Muted or Theme.Text, 16)
        local scale = self:GetScale()
        local boxY = y + math.floor(18 * scale)
        local boxH = math.floor(21 * scale)
        local textY = y + math.floor(22 * scale)
        local iconY = y + math.floor(29 * scale)
        local popupY = y + math.floor(39 * scale)
        self:_tooltip(widget, x, y, w, math.floor(39 * scale), widget)
        self:_text(
            fitTextToWidth(widget.label, w, 14, Theme.Font),
            x,
            y + math.floor(2 * scale),
            dropdownLabel,
            14,
            Drawing.Fonts.Monospace,
            false,
            true,
            z + 2
        )
        self:_square(x, boxY, w, boxH, dropdownBg, true, 1, 3, z + 1)
        self:_square(x, boxY, w, boxH, dropdownOutline, false, disabled and 0.45 or 1, 3, z + 2)
        self:_renderTextInputValue(
            buttonDisplay,
            buttonPlaceholder,
            x + math.floor(7 * scale),
            textY,
            w - math.floor(42 * scale),
            14,
            searchActive,
            disabled,
            z + 3,
            true
        )
        self:_drawIcon(isOpen and "chevron-up" or "chevron-down", x + w - math.floor(14 * scale), iconY, math.floor(14 * scale), isOpen, z + 3)
        widget.popup = { x = x, y = popupY, w = w, z = 120, multi = multi }

        if not disabled and self:_focusClick(x, boxY, w, boxH, widget) then
            if self.DropdownTarget == widget then
                if searchable then
                    self.DropdownSearch = widget
                    self:_claimInteraction(widget)
                else
                    self.DropdownTarget = nil
                    self.DropdownSearch = nil
                    self:_releaseInteraction(widget)
                end
            else
                self:_closeFloating("dropdown")
                self.DropdownTarget = widget
                widget._dropdownScroll = 0
                widget._searchText = ""
                self.DropdownSearch = nil
                self:_claimInteraction(widget)
            end
        end
    end

    function Window:_renderKeybind(widget, x, y, w, z)
        local disabled = widget.disabled == true
        local label = widget.listening and "..." or (widget.value and keyName(widget.value) or "?")
        local scale = self:GetScale()
        local keyTextSize = 14
        local scaledKeyTextSize = math.floor(keyTextSize * scale + 0.5)
        local keyH = math.floor(18 * scale)
        local keyBtnY = y + math.floor(3 * scale)
        local keyW = math.max(math.floor(40 * scale), math.floor(estimateTextWidth(label, keyTextSize, Theme.Font) + math.floor(26 * scale)))
        local keyX = x + w - keyW
        local overKey = not disabled and self:_hover(keyX, keyBtnY, keyW, keyH, widget)
        local keyBg = self:_anim(widget, "keybind.bg", overKey and Theme.Surface2 or Theme.Surface, 16)
        local keyOutline = self:_anim(
            widget,
            "keybind.outline",
            widget.listening and self.Accent or (overKey and Theme.Outline2 or Theme.Outline),
            16
        )
        self:_tooltip(widget, x, y, w, math.floor(24 * scale), widget)
        local labelTextSize = 14
        local scaledLabelTextSize = math.floor(labelTextSize * scale + 0.5)
        local widgetH = math.floor(24 * scale)
        local yOfs = _yOfs(scale)
        self:_text(
            fitTextToWidth(widget.label, w - keyW - math.floor(10 * scale), labelTextSize, Theme.Font),
            x,
            y + math.floor(widgetH / 2) - math.floor(scaledLabelTextSize / 2) - yOfs,
            Theme.Text,
            labelTextSize,
            Theme.Font,
            false,
            true,
            z + 2
        )
        self:_square(keyX, keyBtnY, keyW, keyH, keyBg, true, 1, 2, z + 1)
        self:_square(keyX, keyBtnY, keyW, keyH, keyOutline, false, 1, 2, z + 2)
        self:_text(
            fitTextToWidth(label, keyW - math.floor(10 * scale), keyTextSize, Theme.Font),
            keyX + math.floor(6 * scale),
            keyBtnY + math.floor(keyH / 2) - math.floor(scaledKeyTextSize / 2) - yOfs,
            Theme.Text,
            keyTextSize,
            Theme.Font,
            false,
            true,
            z + 3
        )
        self:_handleKeybindHoldClear(widget)
        if not disabled and self.Mouse2Clicked and self:_hover(keyX, keyBtnY, keyW, keyH, widget) then
            self:_openKeybindModePopup(widget, keyX, keyBtnY, keyW)
        end
        if not disabled and self:_click(keyX, keyBtnY, keyW, keyH) then
            self:_startListening(widget)
        end
    end

    function Window:_renderTextbox(widget, x, y, w, z)
        local scale = self:GetScale()
        local boxY = y + math.floor(18 * scale)
        local boxH = math.floor(21 * scale)
        local textY = y + math.floor(22 * scale)
        local focused = self.TextTarget == widget
        local disabled = widget.disabled == true
        widget.hitbox = { x = x, y = boxY, w = w, h = boxH }
        local overBox = not disabled and self:_hover(x, boxY, w, boxH, widget)
        local boxBg = self:_anim(widget, "textbox.bg", overBox and Theme.Surface2 or Theme.Surface, 16)
        local boxOutline = self:_anim(
            widget,
            "textbox.outline",
            focused and self.Accent or (overBox and Theme.Outline2 or Theme.Outline),
            16
        )
        self:_tooltip(widget, x, y, w, math.floor(39 * scale), widget)
        self:_text(
            fitTextToWidth(widget.label or widget.text or "", w, 14, Theme.Font),
            x,
            y + math.floor(2 * scale),
            Theme.Text,
            14,
            Drawing.Fonts.Monospace,
            false,
            true,
            z + 2
        )
        self:_square(x, boxY, w, boxH, boxBg, true, 1, 3, z + 1)
        self:_square(x, boxY, w, boxH, boxOutline, false, disabled and 0.45 or 1, 3, z + 2)
        self:_renderTextInputValue(
            widget.value,
            widget.placeholder,
            x + math.floor(7 * scale),
            textY,
            w - math.floor(14 * scale),
            14,
            focused,
            disabled,
            z + 3,
            true
        )
        if not disabled and self:_focusClick(x, boxY, w, boxH, widget) then
            if not focused then
                if widget.clearTextOnFocus then
                    widget.value = ""
                end
            end
            self.TextTarget = widget
            self:_closeFloating("textbox")
            self:_claimInteraction(widget)
            if widget.finished then
                self.Mouse1Clicked = false
            end
        elseif self.Mouse1Clicked and not self.BlockClicks and not self:_over(x, boxY, w, boxH) and focused then
            self.TextTarget = nil
            self:_releaseInteraction(widget, true)
        end
    end

    function Window:_renderKeyBox(widget, x, y, w, z)
        local scale = self:GetScale()
        local buttonW = math.floor(68 * scale)
        local gap = math.floor(8 * scale)
        local boxW = w - buttonW - gap
        local boxH = math.floor(18 * scale)
        local boxY = y + math.floor(3 * scale)
        local keyboxTextSize = 14
        local scaledKeyboxTextSize = math.floor(keyboxTextSize * scale + 0.5)
        local yOfs = _yOfs(scale)
        local textY = boxY + math.floor((boxH - scaledKeyboxTextSize) / 2) - yOfs
        local focused = self.TextTarget == widget
        widget.hitbox = { x = x, y = boxY, w = boxW, h = boxH }
        self:_square(x, boxY, boxW, boxH, Theme.Surface, true, 1, 3, z + 1)
        self:_square(x, boxY, boxW, boxH, focused and self.Accent or Theme.Outline, false, 1, 3, z + 2)
        self:_renderTextInputValue(
            widget.value,
            widget.placeholder,
            x + math.floor(7 * scale),
            textY,
            boxW - math.floor(14 * scale),
            keyboxTextSize,
            focused,
            false,
            z + 3,
            true
        )
        local bx = x + boxW + gap
        local over = self:_hover(bx, boxY, buttonW, boxH, widget)
        self:_square(bx, boxY, buttonW, boxH, over and Theme.Surface2 or Theme.Surface, true, 1, 3, z + 1)
        self:_square(bx, boxY, buttonW, boxH, over and Theme.Outline2 or Theme.Outline, false, 1, 3, z + 2)
        self:_text(
            fitTextToWidth("Execute", buttonW - math.floor(10 * scale), keyboxTextSize, Theme.Font),
            bx + buttonW / 2,
            textY,
            Theme.Text,
            keyboxTextSize,
            Drawing.Fonts.Monospace,
            true,
            true,
            z + 3
        )
        if self:_focusClick(x, boxY, boxW, boxH, widget) then
            self.TextTarget = widget
            self:_closeFloating("textbox")
            self:_claimInteraction(widget)
        elseif self:_click(bx, boxY, buttonW, boxH, widget) then
            safeCall(widget.executeCallback, widget.value)
            self:_releaseInteraction(widget)
        elseif self.Mouse1Clicked and focused and not self:_over(x, boxY, boxW, boxH) then
            self.TextTarget = nil
            self:_releaseInteraction(widget, true)
        end
    end

    function Window:_renderColorSwatch(widget, swatchX, swatchY, swatchSize, z)
        local disabled = widget.disabled == true
        local scale = self:GetScale()
        if widget.transparencyEnabled and self.TransparencyTextureData then
            self:_image(self.TransparencyTextureData, swatchX, swatchY, swatchSize, swatchSize, 3, z + 1)
        else
            self:_square(
                swatchX,
                swatchY,
                swatchSize,
                swatchSize,
                Theme.Background,
                true,
                disabled and 0.55 or 1,
                3,
                z + 1
            )
        end
        local swatchAlpha = widget.transparencyEnabled and (1 - clamp(widget.transparency or 0, 0, 1)) or 1
        local swatchColor = widget.value
        local swatchOutline = Theme.Outline
        self:_square(
            swatchX,
            swatchY,
            swatchSize,
            swatchSize,
            swatchColor,
            true,
            disabled and 0.55 or swatchAlpha,
            3,
            z + 2
        )
        self:_square(swatchX, swatchY, swatchSize, swatchSize, swatchOutline, false, disabled and 0.55 or 1, 3, z + 3)
        local popupPad = math.floor(6 * scale)
        local popupTitleH = widget.title and math.floor(16 * scale) or 0
        local popupMapSize = math.floor(200 * scale)
        local popupValueH = math.floor(20 * scale)
        local popupH = popupPad + popupTitleH + popupMapSize + math.floor(8 * scale) + popupValueH + popupPad
        widget.popup = {
            x = swatchX - (widget.transparencyEnabled and math.floor(238 * scale) or math.floor(216 * scale)),
            y = swatchY + swatchSize + math.floor(3 * scale),
            w = widget.transparencyEnabled and math.floor(256 * scale) or math.floor(234 * scale),
            h = popupH,
            z = 125,
        }

        if not disabled and self:_focusClick(swatchX, swatchY, swatchSize, swatchSize, widget) then
            local close = self.ColorPickerTarget == widget
            self.ColorPickerTarget = close and nil or widget
            self:_closeFloating("colorpicker")
            if close then
                self:_releaseInteraction(widget)
            else
                widget.hue, widget.sat, widget.vib = rgbToHsv(widget.value or Color3.new(1, 1, 1))
                self:_claimInteraction(widget)
            end
        end
	end

    function Window:_renderColorPicker(widget, x, y, w, z)
        local disabled = widget.disabled == true
        local scale = self:GetScale()
        local swatchSize = math.floor(18 * scale)
        local swatchX = x + w - swatchSize
        local swatchY = y + math.floor(4 * scale)
        self:_tooltip(widget, x, y, w, math.floor(26 * scale), widget)
        self:_text(
            fitTextToWidth(widget.label or widget.title or "ColorPicker", w - math.floor(30 * scale), 14, Theme.Font),
            x,
            y + math.floor(6 * scale),
            disabled and Theme.Muted or Theme.Text,
            14,
            Drawing.Fonts.Monospace,
            false,
            true,
            z + 2
        )
        self:_renderColorSwatch(widget, swatchX, swatchY, swatchSize, z)
    end

    function Window:_renderButtonWidget(widget, x, y, w, z)
        local scale = self:GetScale()
        local disabled = widget.disabled == true
        local btnH = math.floor(21 * scale)
        local btnY = y + math.floor(0 * scale)
        local btnTextSize = 14
        local scaledBtnTextSize = math.floor(btnTextSize * scale + 0.5)
        local yOfs = _yOfs(scale)
        local btnTextY = btnY + math.floor((btnH - scaledBtnTextSize) / 2) - yOfs
        local over = not disabled and self:_hover(x, btnY, w, btnH, widget)
        local buttonBg = self:_anim(
            widget,
            "button.bg",
            disabled and Theme.Background or Theme.Surface,
            16
        )
        local buttonOutline = self:_anim(
            widget,
            "button.outline",
            disabled and Theme.SoftOutline or Theme.Outline,
            16
        )
        local buttonText =
            self:_anim(widget, "button.text", disabled and Theme.DimText or (over and Theme.Text or Theme.Muted), 16)
        self:_tooltip(widget, x, btnY, w, btnH, widget)
        self:_square(x, btnY, w, btnH, buttonBg, true, 1, 3, z + 1)
        self:_square(x, btnY, w, btnH, buttonOutline, false, 1, 3, z + 2)
        if widget._doubleConfirm and widget._confirmPending then
            self:_text(
                fitTextToWidth("Are you sure?", w - math.floor(12 * scale), btnTextSize, Theme.Font),
                x + w / 2,
                btnTextY,
                self.Accent,
                btnTextSize,
                Drawing.Fonts.Monospace,
                true,
                true,
                z + 3
            )
            if not disabled and self:_click(x, btnY, w, btnH, widget) then
                widget._confirmPending = false
                self.Mouse1Clicked = false
                safeCall(widget.callback)
            end
        else
            self:_text(
                fitTextToWidth(widget.label, w - math.floor(12 * scale), btnTextSize, Theme.Font),
                x + w / 2,
                btnTextY,
                buttonText,
                btnTextSize,
                Drawing.Fonts.Monospace,
                true,
                true,
                z + 3
            )
            if not disabled and self:_click(x, btnY, w, btnH, widget) then
                if widget._doubleConfirm then
                    widget._confirmPending = true
                    self.Mouse1Clicked = false
                else
                    safeCall(widget.callback)
                end
            end
        end
        if
            widget._doubleConfirm
            and widget._confirmPending
            and self.Mouse1Clicked
            and not self:_over(x, btnY, w, btnH)
        then
            widget._confirmPending = false
        end
    end

    function Window:_renderSectionTabs(widget, x, y, w, z)
        local scale = self:GetScale()
        local tabBarH = math.floor(28 * scale)
        local tabBarClickH = math.floor(25 * scale)
        local barY = y + 1
        local tabTextY = barY + math.floor(7 * scale)
        local count = math.max(1, #widget.tabs)
        local tabW = math.floor(w / count)
        for i, tab in ipairs(widget.tabs) do
            local tx = x + (i - 1) * tabW
            local tw = (i == count) and (w - tabW * (i - 1)) or tabW
            local active = (widget.active or 1) == i
            local over = self:_hover(tx, barY, tw, tabBarClickH, widget)
            local tabBg = self:_anim(
                widget,
                "sectiontab." .. tostring(i) .. ".bg",
                active and Theme.Surface or Theme.Sidebar,
                16
            )
            local tabText = self:_anim(
                widget,
                "sectiontab." .. tostring(i) .. ".text",
                active and Theme.Text or Theme.Muted,
                16
            )
            self:_square(tx, barY, tw, tabBarH, tabBg, true, 1, 3, z + 1)
            self:_text(
                fitTextToWidth(tab.name, tw - math.floor(12 * scale), 15, Theme.Font),
                tx + tw / 2,
                tabTextY,
                tabText,
                15,
                Drawing.Fonts.Monospace,
                true,
                true,
                z + 3
            )
            if self:_click(tx, barY, tw, tabBarClickH, widget) then
                widget.active = i
                self.Mouse1Clicked = false
            end
        end
        self:_square(x, barY, w, tabBarH, Theme.Outline, false, 1, 3, z + 2)
        local active = widget.tabs[widget.active or 1]
        if not active then
            return nil
        end
        local contentClipTop = barY + tabBarH
        local cy = y + math.floor(36 * scale)
        for _, child in ipairs(active.widgets) do
            if child.visible ~= false then
                local childH = self:_widgetHeight(child)
                self:_renderWidget(child, x, cy, w, z + 4, contentClipTop, self._clipBottom)
                cy = cy + childH
            end
        end
    end

    function Window:_renderWidget(widget, x, y, w, z, clipTop, clipBottom)
        local previousClipTop, previousClipBottom = self._clipTop, self._clipBottom
        if clipTop ~= nil or clipBottom ~= nil then
            self._clipTop = clipTop
            self._clipBottom = clipBottom
        end
        if widget.type == "divider" then
            local scale = self:GetScale()
            local marginTop = math.floor((widget.marginTop or 0) * scale)
            local lineHeight = math.max(2, math.floor(2 * scale))
            local lineY = y + marginTop + math.floor(2 * scale)
            local text = widget.text
            local function drawDividerLine(lineX, lineWidth)
                if lineWidth <= 0 then return nil end
                self:_square(lineX, lineY, lineWidth, lineHeight, Theme.Main, true, 1, 0, z + 1)
                self:_square(lineX, lineY, lineWidth, lineHeight, Theme.Outline, false, 1, 0, z + 2)
            end
            if text and text ~= "" then
                local textWidth = estimateTextWidth(text, 14, Theme.Font)
                local halfGap = math.floor(textWidth / 2 + 10 * scale)
                local centerX = x + w / 2
                drawDividerLine(x, centerX - halfGap - x)
                drawDividerLine(centerX + halfGap, x + w - centerX - halfGap)
                self:_text(text, centerX, lineY - math.floor(6 * scale) - _yOfs(scale), Theme.Muted, 14, Drawing.Fonts.Monospace, true, true, z + 3)
            else
                drawDividerLine(x, w)
            end
        elseif widget.type == "colorpicker" then
            self:_renderColorPicker(widget, x, y, w, z)
        elseif widget.type == "colorpair" then
            local scale = self:GetScale()
            local gap = math.floor(14 * scale)
            local itemW = math.floor((w - gap) / 2)
            self:_renderColorPicker(widget.left, x, y, itemW, z)
            self:_renderColorPicker(widget.right, x + itemW + gap, y, w - itemW - gap, z)
        elseif widget.type == "label" then
            local scale = self:GetScale()
            local addons = widget.addons or {}
            local addonSize = math.floor(18 * scale)
            local addonGap = math.floor(6 * scale)
            local addonTextSize = 14
            local addonCount = 0
            local addonTotalW = 0
            local addonWidths = {}
            for i, a in ipairs(addons) do
                if a.visible ~= false then
                    local aw = addonSize
                    if a.type == "keybind" then
                        local keyLabel = a.listening and "..." or (a.value and keyName(a.value) or "?")
                        local textW = estimateTextWidth(keyLabel, addonTextSize, Theme.Font)
                        aw = math.max(addonSize, textW + math.floor(12 * scale))
                    end
                    addonWidths[i] = aw
                    addonTotalW = addonTotalW + aw
                    addonCount = addonCount + 1
                end
            end
            local addonAreaW = addonCount > 0 and (addonTotalW + (addonCount - 1) * addonGap) or 0
            local addonStartX = addonCount > 0 and (x + w - addonAreaW) or nil
            local labelMaxW = addonCount > 0 and (addonStartX - x - math.floor(6 * scale)) or w
            local textSize = widget.size or 14
            local scaledLabelTextSize = math.floor(textSize * scale + 0.5)
            local yOfs = _yOfs(scale)
            local lineCount
            if widget.doesWrap ~= false then
                local lines = wrapTextLines(widget.text or "", math.max(math.floor(50 * scale), labelMaxW), textSize, 8, Theme.Font)
                lineCount = #lines
                for i, line in ipairs(lines) do
                    self:_text(
                        fitTextToWidth(line, labelMaxW, textSize, Theme.Font),
                        x,
                        y + math.floor(math.floor(18 * scale) / 2) - math.floor(scaledLabelTextSize / 2) - yOfs + (i - 1) * math.floor(textSize * scale),
                        Theme.Text,
                        textSize,
                        Drawing.Fonts.Monospace,
                        false,
                        true,
                        z + 2
                    )
                end
            else
                lineCount = 1
                self:_text(
                    fitTextToWidth(widget.text or "", labelMaxW, textSize, Theme.Font),
                    x, y + math.floor(math.floor(18 * scale) / 2) - math.floor(scaledLabelTextSize / 2) - yOfs,
                    Theme.Text, textSize,
                    Drawing.Fonts.Monospace, false, true, z + 2
                )
            end
            local labelTooltipH = math.floor(math.max(scaledLabelTextSize, lineCount * math.floor(textSize * scale)) + math.floor(4 * scale))
            self:_tooltip(widget, x, y, w, labelTooltipH, widget)
            if addonCount > 0 and addonStartX then
                local ax = addonStartX
                for i, addon in ipairs(addons) do
                    if addon.visible ~= false then
                        local aw = addonWidths[i] or addonSize
                        if addon.type == "keybind" then
                            self:_renderAddonKeybind(addon, ax, y, aw, addonSize, addonTextSize, z, true)
                        else
                            self:_renderColorSwatch(addon, ax, y, addonSize, z + 1)
                        end
                        ax = ax + aw + addonGap
                    end
                end
            end
        elseif widget.type == "button" then
            self:_renderButtonWidget(widget, x, y, w, z)
        elseif widget.type == "buttonpair" then
            local scale = self:GetScale()
            local gap = math.floor(8 * scale)
            local itemW = math.floor((w - gap) / 2)
            self:_renderButtonWidget(widget.left, x, y, itemW, z)
            self:_renderButtonWidget(widget.right, x + itemW + gap, y, w - itemW - gap, z)
        elseif widget.type == "sectiontabs" then
            self:_renderSectionTabs(widget, x, y, w, z)
        elseif widget.type == "checkbox" then
            self:_renderCheckbox(widget, x, y, w, z)
        elseif widget.type == "toggle" then
            self:_renderToggle(widget, x, y, w, z)
        elseif widget.type == "slider" then
            self:_renderSlider(widget, x, y, w, z)
        elseif widget.type == "image" then
            local scale = self:GetScale()
            local height = math.floor((widget.height or 120) * scale + 0.5)
            self:_image(widget.data, x, y, w, height, widget.rounding, z + 2, widget.transparency)
            self:_tooltip(widget, x, y, w, height, widget)
        elseif widget.type == "dropdown" then
            self:_renderDropdown(widget, x, y, w, z, false)
        elseif widget.type == "multidropdown" then
            self:_renderDropdown(widget, x, y, w, z, true)
        elseif widget.type == "keybind" then
            self:_renderKeybind(widget, x, y, w, z)
        elseif widget.type == "textbox" then
            self:_renderTextbox(widget, x, y, w, z)
        elseif widget.type == "keybox" then
            self:_renderKeyBox(widget, x, y, w, z)
        end
        self._clipTop, self._clipBottom = previousClipTop, previousClipBottom
    end

    function Window:_widgetContainsTarget(widget, target)
        if not widget or not target then
            return false
        end
        if widget == target then
            return true
        end
        for _, addon in ipairs(widget.addons or {}) do
            if addon == target then
                return true
            end
        end
        if widget.type == "colorpair" then
            return widget.left == target or widget.right == target
        end
        if widget.type == "buttonpair" then
            return widget.left == target or widget.right == target
        end
        if widget.type == "sectiontabs" then
            for _, tab in ipairs(widget.tabs or {}) do
                for _, child in ipairs(tab.widgets or {}) do
                    if self:_widgetContainsTarget(child, target) then
                        return true
                    end
                end
            end
        end
        return false
    end
    function Window:_closeClippedWidget(widget)
        local releaseTarget
        if self:_widgetContainsTarget(widget, self.DropdownTarget) then
            releaseTarget = self.DropdownTarget
            if releaseTarget then
                releaseTarget._searchText = ""
            end
            self.DropdownTarget = nil
            self.DropdownSearch = nil
        end
        if self:_widgetContainsTarget(widget, self.ColorPickerTarget) then
            releaseTarget = self.ColorPickerTarget
            self.ColorPickerTarget = nil
            self.ColorPickerDrag = nil
        end
        if self:_widgetContainsTarget(widget, self.SliderTarget) then
            releaseTarget = self.SliderTarget
            self.SliderTarget = nil
        end
        if self:_widgetContainsTarget(widget, self.TextTarget) then
            releaseTarget = self.TextTarget
            self.TextTarget = nil
        end
        if self:_widgetContainsTarget(widget, self.KeybindModeTarget) then
            releaseTarget = self.KeybindModeTarget
            self.KeybindModePopup = nil
            self.KeybindModeTarget = nil
        end
        if releaseTarget then
            self:_releaseInteraction(releaseTarget)
        end
    end

    function Window:_renderSections(tab, x, y, w, h, z, clipTopOverride, clipBottomOverride)
        if tab.IsKeyTab then
            local section = tab.Sections[1]
            if not section then
                return nil
            end
            local contentW = math.floor(w * 0.75)
            local sx = x + math.floor((w - contentW) / 2)
            local totalH = 0
            local visibleCount = 0
            local scale = self:GetScale()
            for _, widget in ipairs(section.widgets) do
                if widget.visible ~= false then
                    widget._calcWidth = contentW
                    totalH = totalH + self:_widgetHeight(widget)
                    visibleCount = visibleCount + 1
                end
            end
            if visibleCount > 1 then
                totalH = totalH + (visibleCount - 1) * math.floor(8 * scale)
            end
            local wy = y
                + math.floor((h - totalH) / 2)
                - (type(self.TabScroll[tab]) == "number" and self.TabScroll[tab] or 0)
            local clipTop = clipTopOverride or y
            local clipBottom = clipBottomOverride or (y + h)
            local widgetIdx = 0
            for _, widget in ipairs(section.widgets) do
                if widget.visible ~= false then
                    local wh = self:_widgetHeight(widget)
                    if wy < clipBottom and wy + wh > clipTop then
                        self:_renderWidget(widget, sx, wy, contentW, z + 5, clipTop, clipBottom)
                    else
                        self:_closeClippedWidget(widget)
                    end
                    widgetIdx = widgetIdx + 1
                    if widgetIdx < visibleCount then
                        wy = wy + wh + math.floor(8 * scale)
                    else
                        wy = wy + wh
                    end
                end
            end
            return nil
        end
        local scale = self:GetScale()
        local pad = math.floor(8 * scale)
        local columnGap = math.floor(6 * scale)
        local scrollTrackW = math.floor(8 * scale)
        local scrollGap = math.floor(6 * scale)
        local scrollSlot = scrollTrackW + scrollGap
        local columnW = math.floor((w - pad * 2 - columnGap) / 2)
        local leftY = y + pad
        local rightY = y + pad
        local layouts = {}
        tab._scrollOwners = tab._scrollOwners or { Left = {}, Right = {} }
        if type(self.TabScroll[tab]) ~= "table" then
            self.TabScroll[tab] = { Left = 0, Right = 0 }
        end
        local scrollState = self.TabScroll[tab]

        for index, section in ipairs(tab.Sections) do
            if self:_sectionVisible(section) then
                local side = section.side
                if not side then
                    side = (index % 2 == 0) and "Right" or "Left"
                end
                local sideName = side == "Right" and "Right" or "Left"
                local useRight = sideName == "Right"
                local sx = x + pad
                local sy = leftY
                if useRight then
                    sx = x + pad + columnW + columnGap
                    sy = rightY
                end
                local widgetW = columnW - math.floor(14 * scale)
                for _, widget in ipairs(section.widgets) do
                    widget._calcWidth = widgetW
                end
                local sh = self:_sectionHeight(section)
                layouts[#layouts + 1] = { section = section, side = sideName, x = sx, y = sy, w = columnW, h = sh }

                if useRight then
                    rightY = rightY + sh + math.floor(6 * scale)
                else
                    leftY = leftY + sh + math.floor(6 * scale)
                end
            end
        end
        local columnHeights = { Left = leftY - y, Right = rightY - y }
        local scrollMax = { Left = math.max(0, columnHeights.Left - h), Right = math.max(0, columnHeights.Right - h) }
        scrollState.Left = clamp(scrollState.Left or 0, 0, scrollMax.Left)
        scrollState.Right = clamp(scrollState.Right or 0, 0, scrollMax.Right)
        for _, layout in ipairs(layouts) do
            if (scrollMax[layout.side] or 0) > 0 then
                layout.w = math.max(40, columnW - scrollSlot)
            else
                layout.w = columnW
            end
        end
        local animScroll = {
            Left = self:_anim(tab, "scroll.Left", scrollState.Left, 22),
            Right = self:_anim(tab, "scroll.Right", scrollState.Right, 22),
        }

        local function renderColumnScroll(sideName, trackX)
            local maxScroll = scrollMax[sideName] or 0
            local totalH = columnHeights[sideName] or 0
            local owner = tab._scrollOwners[sideName]
            if maxScroll <= 0 then
                if self.ScrollTarget == owner then
                    self.ScrollTarget = nil
                    self:_releaseInteraction(owner)
                end
                return nil
            end
            local trackW = scrollTrackW
            local trackY = y + math.floor(8 * scale)
            local trackH = h - math.floor(16 * scale)
            local thumbH = math.max(math.floor(28 * scale), math.floor(trackH * (h / totalH)))
            local thumbRange = math.max(1, trackH - thumbH)
            local visualScroll = animScroll[sideName]
            local thumbY = trackY + math.floor((visualScroll / maxScroll) * thumbRange + 0.5)
            local thumbColor =
                self:_anim(owner, "columnScroll.thumb", self.ScrollTarget == owner and Theme.Muted or Theme.Outline, 18)
            self:_square(trackX, trackY, trackW, trackH, Theme.Background, true, 1, 5, z + 30)
            self:_square(trackX, trackY, trackW, trackH, Theme.Outline, false, 1, 5, z + 31)
            self:_square(trackX + 1, thumbY, trackW - 2, thumbH, thumbColor, true, 1, 5, z + 32)
            if self:_focusClick(trackX - 3, trackY, trackW + 6, trackH, owner) then
                self.ScrollTarget = owner
                self.ScrollDragOffset = clamp(mouse.Y - thumbY, 0, thumbH)
                self:_claimInteraction(owner)
                self.Mouse1Clicked = false
            end
            if self.ScrollTarget == owner and self.Mouse1Held then
                local ratio = clamp((mouse.Y - self.ScrollDragOffset - trackY) / thumbRange, 0, 1)
                scrollState[sideName] = ratio * maxScroll
            elseif self.ScrollTarget == owner then
                self.ScrollTarget = nil
                self:_releaseInteraction(owner)
            end
        end
        renderColumnScroll("Left", x + pad + columnW - scrollTrackW)
        renderColumnScroll("Right", x + pad + columnW + columnGap + columnW - scrollTrackW)
        local clipTop = clipTopOverride or y
        local clipBottom = clipBottomOverride or (y + h)
        for _, layout in ipairs(layouts) do
            local section = layout.section
            local sx = layout.x
            local sy = layout.y - (animScroll[layout.side] or 0)
            local sh = layout.h
            local sectionTop = math.max(sy, clipTop)
            local sectionBottom = math.min(sy + sh, clipBottom)
            local sectionVisibleH = sectionBottom - sectionTop
            if sectionVisibleH > 0 then
                layout.renderX = sx
                layout.renderY = sy
                layout.renderTop = sectionTop
                layout.renderBottom = sectionBottom
                layout.renderVisibleH = sectionVisibleH
                self:_square(sx, sectionTop, layout.w, sectionVisibleH, Theme.Sidebar, true, 1, 4, z + 1)
                self:_square(sx, sectionTop, layout.w, sectionVisibleH, Theme.Outline, false, 1, 4, z + 2)
            else
                layout.renderVisibleH = 0
                self:_closeClippedWidget(section)
            end
        end
        for _, layout in ipairs(layouts) do
            if (layout.renderVisibleH or 0) > 0 then
                local section = layout.section
                local sx = layout.renderX
                local sy = layout.renderY
                local sectionTop = layout.renderTop
                local sectionBottom = layout.renderBottom
                if section.Name and section.Name:sub(1, 2) ~= "__" and sy >= clipTop and sy + math.floor(34 * scale) <= clipBottom then
                    self:_line(sx, sy + math.floor(34 * scale), sx + layout.w, sy + math.floor(34 * scale), Theme.Outline, 1, z + 3)
                    self:_text(
                        fitTextToWidth(section.Name, layout.w - math.floor(24 * scale), 15, Theme.Font),
                        sx + math.floor(12 * scale),
                        sy + math.floor(10 * scale),
                        Theme.Text,
                        15,
                        Drawing.Fonts.Monospace,
                        false,
                        true,
                        z + 4
                    )
                end
                local headerH = (section.Name and section.Name:sub(1, 2) ~= "__") and math.floor(42 * scale) or math.floor(14 * scale)
                local gap = math.floor(8 * scale)
                local wy = sy + headerH
                local visibleCount = 0
                for _, w in ipairs(section.widgets) do
                    if self:_matchesSearch(w, section) then
                        visibleCount = visibleCount + 1
                    end
                end
                local widgetIdx = 0
                for _, widget in ipairs(section.widgets) do
                    if self:_matchesSearch(widget, section) then
                        local wh = self:_widgetHeight(widget)
                        if wy + wh <= sectionTop then
                            self:_closeClippedWidget(widget)
                        elseif wy < sectionBottom then
                            self:_renderWidget(widget, sx + math.floor(7 * scale), wy, layout.w - math.floor(14 * scale), z + 5, sectionTop, sectionBottom)
                        else
                            break
                        end
                        widgetIdx = widgetIdx + 1
                        if widgetIdx < visibleCount then
                            wy = wy + wh + gap
                        else
                            wy = wy + wh
                        end
                    end
                end
            end
        end
    end

    function Window:_renderDropdownPopup()
        local widget = self.DropdownTarget
        if not widget or not widget.popup then
            return nil
        end
        local info = widget.popup
        local disabled = widget.disabled == true
        local searchable = widget.searchable == true
        local searchText = (widget._searchText or ""):lower()
        local filteredOptions = {}

        if searchable and searchText ~= "" then
            for _, opt in ipairs(widget.options) do
                if tostring(opt):lower():find(searchText, 1, true) then
                    filteredOptions[#filteredOptions + 1] = opt
                end
            end
        else
            filteredOptions = widget.options
        end
        local dpiScale = math.max(1, (self.DPIScale or 100) / 100)
        local defaultMaxVisible = math.floor(6 * dpiScale + 0.5)
        local maxVisible = widget.maxVisible or defaultMaxVisible
        local totalCount = #filteredOptions
        local visibleCount = math.min(totalCount, maxVisible)
        local hasScroll = totalCount > maxVisible
        local scale = self:GetScale()
        local scrollBarW = hasScroll and math.floor(7 * scale) or 0
        local itemH = math.floor(21 * scale)
        local height = visibleCount * itemH + math.floor(4 * scale)
        info.h = height
        info.x, info.y = self:_clampToViewport(info.x, info.y, info.w, height, 6, true)
        widget._dropdownScroll = math.max(0, math.min(widget._dropdownScroll or 0, totalCount - visibleCount))
        local scrollOffset = widget._dropdownScroll
        local visualDropdownScroll = self:_anim(widget, "dropdown.scroll.offset", scrollOffset, 18)
        if hasScroll then
            local trackX = info.x + info.w - scrollBarW - math.floor(2 * scale)
            local trackY = info.y + math.floor(2 * scale)
            local trackH = height - 4
            local thumbH = math.max(16, math.floor(trackH * visibleCount / totalCount))
            local thumbRange = math.max(1, trackH - thumbH)
            local thumbY = trackY + math.floor((visualDropdownScroll / (totalCount - visibleCount)) * thumbRange + 0.5)
            local thumbColor = self:_anim(
                widget,
                "dropdown.scroll.thumb",
                self.ScrollTarget == widget and Theme.Muted or Theme.Outline,
                18
            )
            self:_square(trackX, trackY, scrollBarW, trackH, Theme.Background, true, 1, 3, info.z + 1)
            self:_square(trackX + 1, thumbY, scrollBarW - 2, thumbH, thumbColor, true, 1, 3, info.z + 2)
            if self:_clickFor(widget, trackX, trackY, scrollBarW, trackH) then
                self.ScrollTarget = widget
                self.ScrollDragOffset = clamp(mouse.Y - thumbY, 0, thumbH)
                self:_claimInteraction(widget)
                self.Mouse1Clicked = false
            end
            if self.ScrollTarget == widget and self.Mouse1Held then
                local ratio = clamp((mouse.Y - self.ScrollDragOffset - trackY) / thumbRange, 0, 1)
                widget._dropdownScroll = math.floor(ratio * (totalCount - visibleCount) + 0.5)
            elseif self.ScrollTarget == widget then
                self.ScrollTarget = nil
                self:_releaseInteraction(widget)
            end
        end
        self:_square(info.x, info.y, info.w, height, Theme.Background, true, 1, 3, info.z)
        self:_square(info.x, info.y, info.w, height, Theme.SoftOutline, false, 1, 3, info.z + 1)
        local listPad = math.floor(2 * scale)
        local listW = info.w - scrollBarW - (hasScroll and math.floor(2 * scale) or 0)
        local listStartY = info.y + math.floor(2 * scale)
        if not self.Mouse1Held then
            widget._dragVisited = nil
        end
        for i = 1, visibleCount do
            local optionIndex = i + scrollOffset
            local option = filteredOptions[optionIndex]
            if not option then
                break
            end
            local oy = listStartY + (i - 1) * itemH
            local selected = false
            if info.multi then
                selected = widget.selected[option] == true
            else
                selected = widget.value == option
            end
            local isDisabled = false
            for _, dv in ipairs(widget.disabledValues or {}) do
                if dv == option then
                    isDisabled = true
                    break
                end
            end
            local optionX = info.x + listPad
            local optionW = listW - listPad - 2
            local optionKey = "dropdown.option." .. tostring(optionIndex)
            local optionBg = self:_anim(widget, optionKey .. ".bg", selected and Theme.Surface2 or Theme.Background, 18)
            local optionText = self:_anim(
                widget,
                optionKey .. ".text",
                (selected and not isDisabled) and Theme.Text or (isDisabled and Theme.DimText or Theme.Muted),
                16
            )
            self:_square(optionX, oy, optionW, itemH, optionBg, true, 1, 0, info.z + 2)
            local optionImage = widget.valueImages and widget.valueImages[option]
            local optionTextX = info.x + math.floor(18 * scale)
            if optionImage then
                local iconX = info.x + math.floor(13 * scale)
                local iconY = oy + itemH / 2
                if isImageData(optionImage) then
                    self:_image(optionImage, iconX - math.floor(7 * scale), iconY - math.floor(7 * scale), math.floor(14 * scale), math.floor(14 * scale), 2, info.z + 6, isDisabled and 0.6 or 0.8)
                elseif tostring(optionImage):match("^https?://") then
                    widget._valueImageData = widget._valueImageData or {}
                    local resolved = widget._valueImageData[option]
                    if resolved then
                        self:_image(resolved, iconX - math.floor(7 * scale), iconY - math.floor(7 * scale), math.floor(14 * scale), math.floor(14 * scale), 2, info.z + 6, isDisabled and 0.6 or 0.8)
                    elseif not widget._valueImageLoading or not widget._valueImageLoading[option] then
                        widget._valueImageLoading = widget._valueImageLoading or {}
                        widget._valueImageLoading[option] = true
                        RequestImage(tostring(optionImage), function(data)
                            widget._valueImageData[option] = data
                            widget._valueImageLoading[option] = nil
                        end)
                    end
                else
                    self:_drawIcon(tostring(optionImage), iconX, iconY, math.floor(14 * scale), selected, info.z + 6)
                end
                optionTextX = info.x + math.floor(25 * scale)
            end
            self:_text(
                fitTextToWidth(option, listW - math.floor(25 * scale), 14, Theme.Font),
                optionTextX,
                oy + math.floor(5 * scale),
                optionText,
                14,
                Drawing.Fonts.Monospace,
                false,
                true,
                info.z + 6
            )
            local optionActivated = self:_clickFor(widget, optionX, oy, optionW, itemH)
            if widget.dragSelect and self.Mouse1Held and self:_over(optionX, oy, optionW, itemH) then
                widget._dragVisited = widget._dragVisited or {}
                if not widget._dragVisited[option] then
                    widget._dragVisited[option] = true
                    optionActivated = true
                end
            end
            if not disabled and not isDisabled and optionActivated then
                if info.multi then
                    local isSelected = widget.selected[option]
                    local selectedCount = 0
                    for _, v in pairs(widget.selected) do
                        if v then
                            selectedCount = selectedCount + 1
                        end
                    end
                    local minLimit = widget.min or 1
                    local maxLimit = widget.max or math.huge
                    if isSelected and selectedCount <= minLimit then
                    elseif not isSelected and selectedCount >= maxLimit then
                    else
                        widget.selected[option] = not isSelected
                        local list = {}

                        for _, item in ipairs(widget.options) do
                            if widget.selected[item] then
                                list[#list + 1] = item
                            end
                        end
                        _fire(widget, list)
                    end
                else
                    if selected and widget.allowNull == true then
                        widget.value = nil
                        _fire(widget, widget.value)
                    else
                        widget.value = option
                        _fire(widget, widget.value)
                    end
                end
                self.Mouse1Clicked = false
            end
        end
        if
            self.Mouse1Clicked
            and not self.BlockClicks
            and self._focus == widget
            and not self:_over(info.x, info.y - math.floor(22 * scale), info.w, height + math.floor(22 * scale))
        then
            widget._searchText = ""
            self.DropdownTarget = nil
            self.DropdownSearch = nil
            self:_releaseInteraction(widget)
        end
    end

    function Window:_renderColorPickerPopup()
        local widget = self.ColorPickerTarget
        if not widget or not widget.popup then
            return nil
        end
        if not self.ColorPickerDrag then
            widget.hue, widget.sat, widget.vib = rgbToHsv(widget.value or Color3.new(1, 1, 1))
        end
        local scale = self:GetScale()
        local info = widget.popup
        info.x, info.y = self:_clampToViewport(info.x, info.y, info.w, info.h, math.floor(6 * scale), true)
        local x, y, z = info.x, info.y, info.z
        local pad = math.floor(6 * scale)
        local titleH = widget.title and math.floor(16 * scale) or 0
        local svX = x + pad
        local svY = y + pad + titleH
        local svSize = math.floor(200 * scale)
        local hueX = svX + svSize + math.floor(6 * scale)
        local barW = math.floor(16 * scale)
        local alphaX = hueX + barW + math.floor(6 * scale)
        local infoY = svY + svSize + math.floor(8 * scale)
        self:_square(x, y, info.w, info.h, Theme.Background, true, 1, 4, z)
        self:_square(x, y, info.w, info.h, Theme.Outline, false, 1, 4, z + 1)
        if widget.title then
            local titleCenter = y + pad + math.floor(titleH / 2)
            local scaledTitleSize = math.floor(14 * scale)
            local yOfs = _yOfs(scale)
            self:_text(
                fitTextToWidth(widget.title, info.w - pad * 2, 14, Theme.Font),
                x + pad,
                titleCenter - math.floor(scaledTitleSize / 2) - yOfs,
                Theme.Text,
                14,
                Drawing.Fonts.Monospace,
                false,
                true,
                z + 2
            )
        end
        local framePad = math.floor(2 * scale)
        local mapX = svX + framePad
        local mapY = svY + framePad
        local mapSize = svSize - framePad * 2
        local hueInnerX = hueX + framePad
        local hueInnerY = svY + framePad
        local barInnerW = barW - framePad * 2
        local barInnerH = svSize - framePad * 2
        local alphaInnerX = alphaX + framePad
        if self.Mouse1Clicked then
            if self:_over(svX, svY, svSize, svSize) then
                self.ColorPickerDrag = "sv"
                self:_claimInteraction(widget)
            elseif self:_over(hueX, svY, barW, svSize) then
                self.ColorPickerDrag = "hue"
                self:_claimInteraction(widget)
            elseif widget.transparencyEnabled and self:_over(alphaX, svY, barW, svSize) then
                self.ColorPickerDrag = "alpha"
                self:_claimInteraction(widget)
            end
        end
        if not self.Mouse1Held then
            self.ColorPickerDrag = nil
        elseif self.ColorPickerDrag then
            local oldVal, oldAlpha = widget.value, widget.transparency
            if self.ColorPickerDrag == "sv" then
                widget.sat = clamp((mouse.X - mapX) / mapSize, 0, 1)
                widget.vib = clamp(1 - ((mouse.Y - mapY) / mapSize), 0, 1)
                widget.value = Color3.fromHSV(widget.hue or 0, widget.sat or 0, widget.vib or 0)
            elseif self.ColorPickerDrag == "hue" then
                widget.hue = clamp((mouse.Y - hueInnerY) / barInnerH, 0, 1)
                widget.value = Color3.fromHSV(widget.hue or 0, widget.sat or 0, widget.vib or 0)
            elseif self.ColorPickerDrag == "alpha" then
                widget.transparency = clamp((mouse.Y - hueInnerY) / barInnerH, 0, 1)
            end
            if widget.value ~= oldVal or widget.transparency ~= oldAlpha then
                _fire(widget, widget.value, widget.transparency)
            end
        end
        self:_square(svX, svY, svSize, svSize, Theme.Background, true, 1, 4, z + 2)
        
        self:_square(mapX, mapY, mapSize, mapSize, Color3.fromHSV(widget.hue or 0, 1, 1), true, 1, 0, z + 3)
        if self.SaturationTextureData then
            self:_image(self.SaturationTextureData, mapX, mapY, mapSize, mapSize, 0, z + 4)
        end

        self:_square(svX, svY, svSize, svSize, Theme.Background, false, 1, 4, z + 5)
        self:_square(svX - 1, svY - 1, svSize + 2, svSize + 2, Theme.Outline, false, 1, 4, z + 6)
        if not widget.sat or not widget.vib then
            widget.sat, widget.vib = 0, 0
        end
        self:_circle(mapX + widget.sat * mapSize, mapY + (1 - widget.vib) * mapSize, math.floor(4 * scale), Color3.fromRGB(255, 255, 255), true, 1, z + 7)
        self:_square(hueX, svY, barW, svSize, Theme.Background, true, 1, 3, z + 2)
        local hueSegments = 96
        for i = 0, hueSegments - 1 do
            local y0 = hueInnerY + math.floor(i * barInnerH / hueSegments)
            local y1 = hueInnerY + math.floor((i + 1) * barInnerH / hueSegments)
            local segH = math.max(1, y1 - y0)
            self:_square(hueInnerX, y0, barInnerW, segH, Color3.fromHSV(i / hueSegments, 1, 1), true, 1, 0, z + 3)
        end
        self:_square(hueX, svY, barW, svSize, Theme.Background, false, 1, 3, z + 4)
        self:_square(hueX - 1, svY - 1, barW + 2, svSize + 2, Theme.Outline, false, 1, 3, z + 5)
        local hueY = hueInnerY + (widget.hue or 0) * barInnerH
        self:_line(hueX - 1, hueY, hueX + barW + 1, hueY, Theme.Text, 1, z + 6)
        if widget.transparencyEnabled then
            self:_square(alphaX, svY, barW, svSize, Theme.Background, true, 1, 3, z + 2)
            if self.TransparencyTextureData then
                local tileSize = math.max(1, math.floor(barInnerW / 2))
                local totalH = barInnerH
                local fullRows = math.floor((totalH + tileSize - 1) / tileSize)
                for row = 0, fullRows - 1 do
                    local rowH = tileSize
                    local ty = hueInnerY + totalH - (row + 1) * tileSize
                    if ty < hueInnerY then
                        rowH = tileSize - (hueInnerY - ty)
                        ty = hueInnerY
                    end
                    for col = 0, 1 do
                        local tx = alphaInnerX + col * tileSize
                        local tw = math.min(tileSize, alphaInnerX + barInnerW - tx)
                        self:_image(self.TransparencyTextureData, tx, ty, tw, rowH, 0, z + 3)
                    end
                end
            end
            local alphaSegments = 96
            for i = 0, alphaSegments - 1 do
                local alpha = 1 - (i / (alphaSegments - 1))
                local y0 = hueInnerY + math.floor(i * barInnerH / alphaSegments)
                local y1 = hueInnerY + math.floor((i + 1) * barInnerH / alphaSegments)
                local segH = math.max(1, y1 - y0)
                self:_square(alphaInnerX, y0, barInnerW, segH, widget.value, true, alpha, 0, z + 4)
            end
            self:_square(alphaX, svY, barW, svSize, Theme.Background, false, 1, 3, z + 5)
            self:_square(alphaX - 1, svY - 1, barW + 2, svSize + 2, Theme.Outline, false, 1, 3, z + 6)
            local alphaY = hueInnerY + clamp(widget.transparency or 0, 0, 1) * barInnerH
            self:_line(alphaX - 1, alphaY, alphaX + barW + 1, alphaY, Theme.Text, 1, z + 7)
        end
        local boxH = math.floor(20 * scale)
        local boxW = (info.w - pad * 2 - math.floor(8 * scale)) / 2
        local boxTextSize = 14
        local scaledBoxTextSize = math.floor(boxTextSize * scale + 0.5)
        local yOfs = _yOfs(scale)
        local boxTextY = infoY + math.floor(boxH / 2) - math.floor(scaledBoxTextSize / 2) - yOfs
        local hexBoxX = x + pad
        local rgbBoxX = x + pad + boxW + math.floor(8 * scale)
        local hexCenterX = hexBoxX + boxW / 2
        local rgbCenterX = rgbBoxX + boxW / 2
        self:_square(hexBoxX, infoY, boxW, boxH, Theme.Main, true, 1, 3, z + 2)
        self:_square(hexBoxX, infoY, boxW, boxH, Theme.Outline, false, 1, 3, z + 3)
        local displayColor = Color3.fromHSV(widget.hue, widget.sat or 0, widget.vib or 0)
        local displayHex = colorToHexAlpha(
            displayColor,
            widget.transparencyEnabled and widget.transparency or nil
        )
        local displayRgb = table.concat(
            {
                math.floor(clamp(displayColor.R * 255 + 0.5, 0, 255)),
                math.floor(clamp(displayColor.G * 255 + 0.5, 0, 255)),
                math.floor(clamp(displayColor.B * 255 + 0.5, 0, 255)),
            },
            ", "
        )
        self:_text(
            fitTextToWidth(displayHex, boxW - math.floor(12 * scale), boxTextSize, Theme.Font),
            hexCenterX,
            boxTextY,
            Theme.Text,
            boxTextSize,
            Drawing.Fonts.Monospace,
            true,
            true,
            z + 4
        )
        self:_square(rgbBoxX, infoY, boxW, boxH, Theme.Main, true, 1, 3, z + 2)
        self:_square(rgbBoxX, infoY, boxW, boxH, Theme.Outline, false, 1, 3, z + 3)
        self:_text(
            fitTextToWidth(displayRgb, boxW - math.floor(12 * scale), boxTextSize, Theme.Font),
            rgbCenterX,
            boxTextY,
            Theme.Text,
            boxTextSize,
            Drawing.Fonts.Monospace,
            true,
            true,
            z + 4
        )
        if self.Mouse1Clicked and not self.BlockClicks and self._focus == widget and not self:_over(x, y - math.floor(22 * scale), info.w, info.h + math.floor(22 * scale)) then
            self.ColorPickerTarget = nil
            self.ColorPickerDrag = nil
            self:_releaseInteraction(widget)
        end
    end

    function Window:_collectKeybindRows()
        local rows = {}
        local function push(widget)
            if widget.visible == false or widget.popupEnabled == false then
                return nil
            end
            if widget.type == "keybind" and widget.value then
                local mode = tostring(widget.mode or "Hold")
                local active = mode == "Always"
                    or (widget.parent ~= nil and widget.parent.value == true)
                    or (widget.parent == nil and widget._state == true)
                rows[#rows + 1] = {
                    text = TextManager:FormatKeybind(widget.value, widget.label or "Keybind", mode),
                    toggle = (mode == "Toggle") and GalaxObsidian.ShowToggleFrameInKeybinds,
                    checked = mode == "Always" or active,
                    widget = widget,
                }
            elseif (_isToggle(widget)) and widget.keybind then
                rows[#rows + 1] = {
                    text = TextManager:FormatKeybind(widget.keybind, widget.label or "Toggle", "Toggle"),
                    toggle = true,
                    checked = widget.value == true,
                    widget = widget,
                }
            elseif widget.type == "sectiontabs" then
                local active = widget.tabs[widget.active or 1]
                if active then
                    for _, child in ipairs(active.widgets) do
                        push(child)
                    end
                end
            end
            for _, addon in ipairs(widget.addons or {}) do
                push(addon)
            end
        end
        for _, tab in ipairs(self.Tabs) do
            for _, section in ipairs(tab.Sections) do
                for _, widget in ipairs(section.widgets) do
                    push(widget)
                end
            end
        end
        return rows
    end
    function Window:_renderKeybindMenu()
        if not self.ShowKeybindMenu then
            return nil
        end
        local scale = self:GetScale()
        local rows = self:_collectKeybindRows()
        local rowH = math.floor(20 * scale)
        local logicalWidth = self.KeybindMenuWidth or 260
        local width = math.floor(logicalWidth * scale)
        local dragH = math.floor(32 * scale)
        local height = dragH + math.floor(12 * scale) + math.max(#rows, 1) * rowH
        if self.KeybindMenuX == nil then
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize
            self.KeybindMenuX = 10
            self.KeybindMenuY = viewport and math.floor((viewport.Y - height) / 2) or 120
        end
        local x, y = self.KeybindMenuX, self.KeybindMenuY
        x, y = self:_clampToViewport(x, y, width, height, 6, true)
        local overDrag = self:_over(x, y, width, dragH)
        if overDrag and self:_click(x, y, width, dragH) then
            self.KeybindMenuDrag = { offsetX = mouse.X - x, offsetY = mouse.Y - y }
            self.Mouse1Clicked = false
        end
        if self.KeybindMenuDrag and self.Mouse1Held then
            x = mouse.X - self.KeybindMenuDrag.offsetX
            y = mouse.Y - self.KeybindMenuDrag.offsetY
            x, y = self:_clampToViewport(x, y, width, height, 6, true)
            self.KeybindMenuX, self.KeybindMenuY = x, y
        elseif self.KeybindMenuDrag then
            self.KeybindMenuDrag = nil
        end
        self.KeybindMenuX, self.KeybindMenuY = x, y
        self:_square(x, y, width, height, Theme.Topbar, true, 1, 4, 0)
        self:_square(x, y, width, height, Theme.SoftOutline, false, 1, 4, 1)
        self:_text("Keybinds", x + math.floor(10 * scale), y + math.floor(10 * scale), Theme.Text, 14, Drawing.Fonts.Monospace, false, true, 2)
        self:_line(x + math.floor(4 * scale), y + dragH - math.floor(2 * scale), x + width - math.floor(4 * scale), y + dragH - math.floor(2 * scale), Theme.Outline, 1, 2)
        if #rows == 0 then
            self:_text(
                    "No keybinds",
                x + math.floor(10 * scale),
                y + dragH + math.floor(4 * scale),
                Theme.DimText,
                14,
                Drawing.Fonts.Monospace,
                false,
                true,
                2
            )
        else
            for i, row in ipairs(rows) do
                local ry = y + dragH + math.floor(4 * scale) + (i - 1) * rowH
                local textX = x + math.floor(10 * scale)
                if row.toggle then
                    local cbX = x + math.floor(10 * scale)
                    local cbSize = math.floor(12 * scale)
                    local cbY = ry + math.floor((rowH - cbSize) / 2)
                    local rowKey = "keybindMenu.checkbox." .. tostring(i)
                    local checkboxBg =
                        self:_anim(self, rowKey .. ".bg", row.checked and Theme.Surface or Theme.Main, 16)
                    local checkboxOutline =
                        self:_anim(self, rowKey .. ".outline", row.checked and Theme.Outline2 or Theme.Outline, 16)
                    self:_square(cbX, cbY, cbSize, cbSize, checkboxBg, true, 1, 2, 2)
                    self:_square(cbX, cbY, cbSize, cbSize, checkboxOutline, false, 1, 2, 3)
                    if row.checked then
                        self:_drawIcon("check", cbX + math.floor(cbSize / 2), cbY + math.floor(cbSize / 2), math.floor(10 * scale), true, 4)
                    end
                    if self:_click(cbX, cbY, cbSize, cbSize) then
                        local target = row.widget
                        if target and _isToggle(target) then
                            target.value = not target.value
                            _fire(target, target.value)
                        elseif target and target.type == "keybind" then
                            if target.parent and _isToggle(target.parent) then
                                if target.mode == "Always" then
                                    target.mode = "Toggle"
                                    target.parent.value = not target.parent.value
                                    _fire(target.parent, target.parent.value)
                                else
                                    target.parent.value = not target.parent.value
                                    _fire(target.parent, target.parent.value)
                                end
                            elseif target.mode == "Always" then
                                target.mode = "Toggle"
                                target._state = not target._state
                                safeCall(target.callback, target._state)
                            else
                                target._state = not target._state
                                safeCall(target.callback, target._state)
                            end
                        end
                        self.Mouse1Clicked = false
                    end
                    textX = x + math.floor(28 * scale)
                end
                local textColor = self:_anim(self, "keybindMenu.text." .. tostring(i), row.checked and Theme.Text or Theme.Muted, 16)
                local scaledRowTextSize = math.floor(14 * scale + 0.5)
                local yOfs = _yOfs(scale)
                self:_text(
                    fitTextToWidth(row.text, width - (textX - x) - math.floor(10 * scale), 14, Theme.Font),
                    textX,
                    ry + math.floor(rowH / 2) - math.floor(scaledRowTextSize / 2) - yOfs,
                    textColor,
                    14,
                    Drawing.Fonts.Monospace,
                    false,
                    true,
                    2
                )
                if row.widget and row.widget.type == "keybind" and self.Mouse2Clicked and self:_hover(x, ry, width, rowH, row.widget) then
                    self:_openKeybindModePopup(row.widget, mouse.X, mouse.Y - math.floor(23 * scale), math.floor(80 * scale))
                end
            end
        end
    end
    function Window:_renderKeybindModePopup()
        local popup = self.KeybindModePopup
        local target = self.KeybindModeTarget
        if not popup or not target or target.disabled == true then
            if target then
                self:_releaseInteraction(target)
            end
            self.KeybindModePopup = nil
            self.KeybindModeTarget = nil
            return nil
        end
        local popupEnabled = target.popupEnabled
        if popupEnabled == nil then
            popupEnabled = true
        end
        if not popupEnabled then
            self:_releaseInteraction(target)
            self.KeybindModePopup = nil
            self.KeybindModeTarget = nil
            return nil
        end
        local scale = self:GetScale()
        local x, y, w, h, z = popup.x, popup.y, popup.w, popup.h, popup.z or 135
        local rowH = math.floor(20 * scale)
        local modes = target.popupModes or DefaultKeybindModePopupModes
        if #modes <= 0 then
            self:_releaseInteraction(target)
            self.KeybindModePopup = nil
            self.KeybindModeTarget = nil
            return nil
        end
        h = math.floor(6 * scale) + #modes * rowH
        popup.h = h
        x, y = self:_clampToViewport(x, y, w, h, 4, true)
        popup.x, popup.y = x, y
        if (self.Mouse1Clicked or self.Mouse2Clicked) and not self.BlockClicks and not self:_over(x, y, w, h) then
            self:_releaseInteraction(target)
            self.KeybindModePopup = nil
            self.KeybindModeTarget = nil
            self.Mouse1Clicked = false
            self.Mouse2Clicked = false
            return nil
        end
        self:_square(x, y, w, h, Theme.Background, true, 1, 3, z)
        self:_square(x, y, w, h, Theme.Outline, false, 1, 3, z + 1)
        for i, mode in ipairs(modes) do
            local ry = y + math.floor(3 * scale) + (i - 1) * rowH
            local selected = tostring(target.mode or "Hold") == mode
            if selected then
                self:_square(x + math.floor(3 * scale), ry, w - math.floor(6 * scale), rowH - 1, Theme.Surface2, true, 1, 2, z + 1)
            end
            if selected then
                self:_drawIcon("check", x + math.floor(12 * scale), ry + math.floor(rowH / 2), math.floor(10 * scale), true, z + 3)
            end
            local scaledModeTextSize = math.floor(14 * scale + 0.5)
            local yOfs = _yOfs(scale)
            self:_text(mode, x + math.floor(22 * scale), ry + math.floor(rowH / 2) - math.floor(scaledModeTextSize / 2) - yOfs, selected and Theme.Text or Theme.Muted, 14, Drawing.Fonts.Monospace, false, true, z + 3)
            if self:_click(x + math.floor(3 * scale), ry, w - math.floor(6 * scale), rowH - 1, target) then
                target.mode = mode
                target._state = false
                _fire(target, false)
                self:_releaseInteraction(target)
                self.KeybindModePopup = nil
                self.KeybindModeTarget = nil
                self.Mouse1Clicked = false
                break
            end
        end
    end

    function Window:_renderDraggableLabels()
        local labels = self.DraggableLabels
        if not labels or #labels == 0 then return nil end
        local scale = self:GetScale()
        for _, label in ipairs(labels) do
            local text = label.text or ""
            if text ~= "" and label.visible ~= false and not label.destroyed then
                local px, py = label.px or 100, label.py or 100
                local tw = estimateTextWidth(tostring(text), 15, Drawing.Fonts.Monospace) + math.floor(24 * scale)
                local th = math.floor(28 * scale)
                local bgX = math.floor(px - tw / 2)
                local bgY = math.floor(py - th / 2)

                if label.dragging then
                    if self.Mouse1Held then
                        px = mouse.X - label.doffX
                        py = mouse.Y - label.doffY
                        label.px, label.py = px, py
                    else
                        label.dragging = false
                        self:_releaseInteraction(label)
                    end
                elseif self:_click(bgX, bgY, tw, th, label) then
                    label.dragging = true
                    label.doffX = mouse.X - px
                    label.doffY = mouse.Y - py
                    self:_claimInteraction(label)
                end

                self:_square(bgX, bgY, tw, th, Theme.Topbar, true, 1, 4, -3)
                self:_square(bgX, bgY, tw, th, Theme.SoftOutline, false, 1, 4, -2)
                local textSize = 14
                local scaledTextSize = math.floor(textSize * scale + 0.5)
                local yOfs = _yOfs(scale)
                self:_text(
                    tostring(text),
                    bgX + math.floor(10 * scale),
                    bgY + math.floor(th / 2) - math.floor(scaledTextSize / 2) - yOfs,
                    Theme.Text,
                    textSize,
                    Drawing.Fonts.Monospace,
                    false,
                    true,
                    -1
                )
            end
        end
    end

    function Window:_renderDraggableButtons()
        local scale = self:GetScale()
        for _, button in ipairs(self.DraggableButtons) do
            if button.visible ~= false and not button.destroyed then
                local text = tostring(button.text or "")
                local iconSpace = button.icon and math.floor(22 * scale) or 0
                local width = estimateTextWidth(text, 14, Drawing.Fonts.Monospace) + math.floor(24 * scale) + iconSpace
                local height = math.floor(30 * scale)
                local x = math.floor((button.px or 100) - width / 2)
                local y = math.floor((button.py or 140) - height / 2)
                if button.pressed then
                    if self.Mouse1Held then
                        local dx = mouse.X - button.pressX
                        local dy = mouse.Y - button.pressY
                        if math.abs(dx) + math.abs(dy) > 4 then button.moved = true end
                        if button.moved then
                            button.px = mouse.X - button.doffX
                            button.py = mouse.Y - button.doffY
                        end
                    else
                        button.pressed = false
                        self:_releaseInteraction(button)
                        if not button.moved and type(button.callback) == "function" then pcall(button.callback, button) end
                    end
                elseif self:_click(x, y, width, height, button) then
                    button.pressed = true
                    button.moved = false
                    button.pressX = mouse.X
                    button.pressY = mouse.Y
                    button.doffX = mouse.X - button.px
                    button.doffY = mouse.Y - button.py
                    self:_claimInteraction(button)
                end
                local active = button.pressed or self:_over(x, y, width, height)
                self:_square(x, y, width, height, active and Theme.Surface2 or Theme.Topbar, true, 1, 5, -3)
                self:_square(x, y, width, height, Theme.SoftOutline, false, 1, 5, -2)
                local textX = x + math.floor(12 * scale)
                if button.icon then
                    local iconX = button.iconPosition == "Right" and x + width - math.floor(14 * scale) or textX + math.floor(7 * scale)
                    self:_drawIcon(button.icon, iconX, y + height / 2, math.floor(14 * scale), active, -1)
                    if button.iconPosition ~= "Right" then textX = textX + iconSpace end
                end
                self:_text(text, textX, y + math.floor(7 * scale) - _yOfs(scale), Theme.Text, 14, Drawing.Fonts.Monospace, false, true, -1)
            end
        end
    end

    function Window:_renderDraggableMenus()
        local scale = self:GetScale()
        for _, menu in ipairs(self.DraggableMenus) do
            if menu.visible ~= false and not menu.destroyed then
                local width = math.floor((menu.width or 220) * scale)
                local rowHeight = math.floor(25 * scale)
                local headerHeight = math.floor(30 * scale)
                local height = headerHeight + math.floor(8 * scale) + #menu.items * rowHeight
                local x = math.floor(menu.x or 130)
                local y = math.floor(menu.y or 180)
                if menu.dragging then
                    if self.Mouse1Held then
                        menu.x = mouse.X - menu.doffX
                        menu.y = mouse.Y - menu.doffY
                    else
                        menu.dragging = false
                        self:_releaseInteraction(menu)
                    end
                elseif self:_click(x, y, width, headerHeight, menu) then
                    menu.dragging = true
                    menu.doffX = mouse.X - x
                    menu.doffY = mouse.Y - y
                    self:_claimInteraction(menu)
                end
                self:_square(x, y, width, height, Theme.Background, true, 1, 6, -4)
                self:_square(x, y, width, height, Theme.Outline, false, 1, 6, -3)
                self:_square(x, y, width, headerHeight, Theme.Topbar, true, 1, 6, -2)
                self:_text(tostring(menu.title or "Menu"), x + math.floor(10 * scale), y + math.floor(8 * scale) - _yOfs(scale), Theme.Text, 14, Drawing.Fonts.Monospace, false, true, -1)
                for index, item in ipairs(menu.items) do
                    if item.visible ~= false and not item.destroyed then
                        local rowY = y + headerHeight + math.floor(4 * scale) + (index - 1) * rowHeight
                        local hovered = self:_over(x + 4, rowY, width - 8, rowHeight)
                        if item.kind == "button" and hovered then
                            self:_square(x + 4, rowY, width - 8, rowHeight, Theme.PopupHover, true, 1, 3, -2)
                            if self:_click(x + 4, rowY, width - 8, rowHeight, item) and type(item.callback) == "function" then pcall(item.callback, item, menu) end
                        end
                        self:_text(tostring(item.text or ""), x + math.floor(10 * scale), rowY + math.floor(6 * scale) - _yOfs(scale), item.kind == "value" and Theme.Muted or Theme.Text, 13, Drawing.Fonts.Monospace, false, true, -1)
                    end
                end
            end
        end
    end

    function Window:_renderLoading()
        local loading = self.LoadingOverlay
        if not loading or loading.closed then return nil end
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        local scale = self:GetScale()
        local contentWidth = loading.contentWidth or loading.width or 450
        local sidebarWidth = loading.showSidebar and (loading.sidebarWidth or 250) or 0
        local targetWidth = (contentWidth + sidebarWidth) * scale
        local width = math.floor(self:_anim(loading, "width", targetWidth, 12))
        local height = math.floor((loading.height or 275) * scale)
        local x = math.floor((viewport.X - width) / 2)
        local y = math.floor((viewport.Y - height) / 2 + (loading.centerOffsetY or -30))
        local z = 180
        self:_square(0, 0, viewport.X, viewport.Y, Color3.new(0, 0, 0), true, 0.6, 0, z)
        self:_square(x, y, width, height, Theme.Background, true, 1, 8, z + 1)
        self:_square(x, y, width, height, Theme.Outline, false, 1, 8, z + 2)
        local mainWidth = math.min(width, math.floor(contentWidth * scale))
        local topHeight = math.floor(48 * scale)
        self:_line(x, y + topHeight, x + mainWidth, y + topHeight, Theme.Outline, 1, z + 3)
        local titleX = x + math.floor(12 * scale)
        local titleIconSize = math.floor(28 * scale)
        if loading.iconData then
            self:_image(loading.iconData, titleX, y + math.floor(10 * scale), titleIconSize, titleIconSize, 4, z + 4, 0.8)
            titleX = titleX + titleIconSize + math.floor(7 * scale)
        elseif self.IconData then
            self:_image(self.IconData, titleX, y + math.floor(10 * scale), titleIconSize, titleIconSize, 4, z + 4, 0.8)
            titleX = titleX + titleIconSize + math.floor(7 * scale)
        end
        self:_text(fitTextToWidth(loading.title, mainWidth - titleX + x - 12, 20, Theme.Font), titleX, y + math.floor(14 * scale) - _yOfs(scale), Theme.Text, 20, Drawing.Fonts.Monospace, false, false, z + 4)

        if loading.showSidebar and width > mainWidth + math.floor(20 * scale) then
            local sidebarX = x + mainWidth
            self:_line(sidebarX, y, sidebarX, y + height, Theme.Outline, 1, z + 3)
            local itemY = y + math.floor(15 * scale)
            for _, item in ipairs(loading.sidebarItems) do
                if item.visible ~= false then
                    if item.kind == "divider" then
                        self:_line(sidebarX + 12, itemY, x + width - 12, itemY, Theme.Outline, 1, z + 4)
                        itemY = itemY + math.floor(12 * scale)
                    else
                        local rowHeight = math.floor(27 * scale)
                        local hovered = item.kind == "button" and self:_over(sidebarX + 10, itemY, width - mainWidth - 20, rowHeight)
                        if hovered then self:_square(sidebarX + 10, itemY, width - mainWidth - 20, rowHeight, Theme.PopupHover, true, 1, 4, z + 3) end
                        self:_text(fitTextToWidth(item.text, width - mainWidth - math.floor(28 * scale), 14, Theme.Font), sidebarX + math.floor(14 * scale), itemY + math.floor(6 * scale) - _yOfs(scale), item.kind == "value" and Theme.Muted or Theme.Text, 14, Drawing.Fonts.Monospace, false, false, z + 4)
                        if hovered and self:_click(sidebarX + 10, itemY, width - mainWidth - 20, rowHeight, item) and type(item.callback) == "function" then pcall(item.callback, loading, item) end
                        itemY = itemY + rowHeight + math.floor(4 * scale)
                    end
                end
            end
        end

        if loading.isError then
            local pad = math.floor(15 * scale)
            self:_text("Error", x + pad, y + topHeight + pad, Theme.Red, 18, Drawing.Fonts.Monospace, false, false, z + 4)
            local errorLines = wrapTextLines(loading.errorMessage or "Unknown error", mainWidth - pad * 2, 14, 8, Theme.Font)
            for index, line in ipairs(errorLines) do
                self:_text(line, x + pad, y + topHeight + math.floor(43 * scale) + (index - 1) * math.floor(17 * scale), Theme.Muted, 14, Drawing.Fonts.Monospace, false, false, z + 4)
            end
            local buttons = loading.errorButtons or {}
            local buttonHeight = math.floor(27 * scale)
            local gap = math.floor(8 * scale)
            local totalWidth = 0
            local widths = {}
            for index, button in ipairs(buttons) do
                widths[index] = math.max(math.floor(64 * scale), estimateTextWidth(button.title, 14, Theme.Font) + math.floor(30 * scale))
                totalWidth = totalWidth + widths[index] + (index > 1 and gap or 0)
            end
            local buttonX = x + mainWidth - pad - totalWidth
            local buttonY = y + height - math.floor(42 * scale)
            if #buttons > 0 then self:_line(x + pad, buttonY - math.floor(7 * scale), x + mainWidth - pad, buttonY - math.floor(7 * scale), Theme.Outline, 1, z + 4) end
            for index, button in ipairs(buttons) do
                local buttonWidth = widths[index]
                local hovered = self:_over(buttonX, buttonY, buttonWidth, buttonHeight)
                local color = button.variant == "Destructive" and Theme.Red or (button.variant == "Primary" and Theme.Text or Theme.Surface)
                if hovered then color = button.variant == "Destructive" and Color3.fromRGB(235, 70, 85) or Theme.Surface2 end
                self:_square(buttonX, buttonY, buttonWidth, buttonHeight, color, true, 1, 5, z + 4)
                self:_square(buttonX, buttonY, buttonWidth, buttonHeight, Theme.Outline, false, 1, 5, z + 5)
                local textColor = button.variant == "Primary" and Theme.Background or Theme.Text
                self:_text(button.title, buttonX + buttonWidth / 2, buttonY + math.floor(6 * scale) - _yOfs(scale), textColor, 14, Drawing.Fonts.Monospace, true, false, z + 6)
                if hovered and self:_click(buttonX, buttonY, buttonWidth, buttonHeight, button) and type(button.callback) == "function" then pcall(button.callback, loading) end
                buttonX = buttonX + buttonWidth + gap
            end
            return nil
        end

        local centerX = x + mainWidth / 2
        local tweenTime = loading.loadingIconTweenTime or 1
        if loading.loadingIconData then
            local loadingIconSize = math.floor(62 * scale)
            local iconDrawing = self:_image(loading.loadingIconData, centerX - loadingIconSize / 2, y + topHeight + math.floor(25 * scale), loadingIconSize, loadingIconSize, 0, z + 4, 0.8)
            if iconDrawing and loading.loadingIconColor then iconDrawing.Color = loading.loadingIconColor end
        else
            local spinnerY = y + topHeight + math.floor(56 * scale)
            local segments = 16
            local radius = math.floor(27 * scale)
            local thickness = math.max(2, math.floor(3 * scale))
            local duration = tweenTime > 0 and tweenTime or 1
            local head = tweenTime > 0 and math.floor((tick() / duration) * segments) % segments or 0
            local baseColor = loading.loadingIconColor or Theme.Accent
            for index = 0, segments - 1 do
                local distance = (head - index) % segments
                if distance < 12 then
                    local strength = 1 - distance / 14
                    local color = Color3.new(baseColor.R * strength, baseColor.G * strength, baseColor.B * strength)
                    local angleA = index / segments * math.pi * 2 - math.pi / 2
                    local angleB = (index + 0.68) / segments * math.pi * 2 - math.pi / 2
                    self:_line(centerX + math.cos(angleA) * radius, spinnerY + math.sin(angleA) * radius, centerX + math.cos(angleB) * radius, spinnerY + math.sin(angleB) * radius, color, thickness, z + 4)
                end
            end
        end
        self:_text(fitTextToWidth(loading.message, mainWidth - 50, 18, Theme.Font), centerX, y + topHeight + math.floor(103 * scale) - _yOfs(scale), Theme.Text, 18, Drawing.Fonts.Monospace, true, false, z + 4)
        self:_text(fitTextToWidth(loading.description, mainWidth - 50, 14, Theme.Font), centerX, y + topHeight + math.floor(130 * scale) - _yOfs(scale), Theme.Muted, 14, Drawing.Fonts.Monospace, true, false, z + 4)
        local total = math.max(1, tonumber(loading.totalSteps) or 1)
        local current = clamp(tonumber(loading.currentStep) or 0, 0, total)
        local barW = math.floor(mainWidth * 0.7)
        local barX = x + math.floor((mainWidth - barW) / 2)
        local barY = y + height - math.floor(48 * scale)
        local barH = math.floor(15 * scale)
        self:_square(barX, barY, barW, barH, Theme.Main, true, 1, 4, z + 3)
        local progress = self:_anim(loading, "progress", current / total, 10)
        self:_square(barX, barY, math.floor(barW * progress), barH, Theme.Accent, true, 1, 4, z + 4)
        self:_text(tostring(current) .. "/" .. tostring(total), centerX, barY + math.floor(1 * scale) - _yOfs(scale), Theme.Text, 14, Drawing.Fonts.Monospace, true, true, z + 5)
    end

    function Window:_renderTooltip()
        local text = self.TooltipText
        if not text or text == "" or self.Mouse1Held then
            return nil
        end
        local scale = self:GetScale()
        local pad = math.floor(6 * scale)
        local maxTextW = math.floor(220 * scale)
        local lineH = math.floor(14 * scale)
        local textSize = math.floor(14 * scale + 0.5)
        local lines = wrapTextLines(text, maxTextW, 14, 8, Theme.Font)
        local w = math.floor(widestLineWidth(lines, 14, Theme.Font) + pad * 2 + math.floor(26 * scale))
        local h = pad * 2 + #lines * lineH
        local x, y = self:_placeNearMouse(w, h, math.floor(12 * scale), math.floor(14 * scale), 6, true)
        self:_square(x, y, w, h, Theme.Background, true, 1, 3, 145)
        self:_square(x, y, w, h, Theme.SoftOutline, false, 1, 3, 146)
        for i, line in ipairs(lines) do
            self:_text(
                fitTextToWidth(line, w - math.floor(10 * scale), 14, Drawing.Fonts.Monospace),
                x + math.floor(5 * scale),
                y + pad + (i - 1) * lineH + math.floor((lineH - textSize) / 2),
                Theme.Text,
                14,
                Drawing.Fonts.Monospace,
                false,
                false,
                147
            )
        end
    end

    function Window:GetScale()
        return math.max(0.5, (self.DPIScale or 100) / 100)
    end

    function Window:_windowLayout(x, y, w, h, scale)
        local sidebarW = math.floor((self.Compact and 72 or self.SidebarWidth or 200) * scale)
        local topH = math.floor(48 * scale)
        local bottomH = math.floor(20 * scale)
        local pad = math.floor(8 * scale)
        local searchH = topH - pad * 2
        local dragBox = searchH
        local dragMargin = pad
        local dragBoxX = x + w - dragMargin - dragBox
        local dragBoxY = y + pad
        local searchGap = pad
        local searchX = x + sidebarW + searchGap
        local searchY = y + pad
        local searchW = math.max(0, dragBoxX - searchGap - searchX)
        return {
            sidebarW = sidebarW,
            topH = topH,
            bottomH = bottomH,
            dragSize = math.floor(28 * scale),
            dragX = dragBoxX + dragBox / 2,
            dragY = dragBoxY + dragBox / 2,
            searchX = searchX,
            searchY = searchY,
            searchW = searchW,
            searchH = searchH,
            searchVisible = self.ShowSearch and searchW > 40,
        }
    end

    function Window:_render()
        self:_resetPool()
        self._renderingMainWindow = false
        self.BlockClicks = false
        self.TooltipText = nil
        if not self.Open then
            self:_renderKeybindMenu()
            self:_renderKeybindModePopup()
            self:_renderDraggableLabels()
            self:_renderDraggableButtons()
            self:_renderDraggableMenus()
            NotificationManager:RenderNotifications(self)
            self:_renderLoading()
            self:_renderTooltip()
            self:_hideUnused()
            return nil
        end
        self._renderingMainWindow = true
        local x, y = self.Position.X, self.Position.Y
        local w, h = self.Size.X, self.Size.Y
        local prevX, prevY = x, y
        local scale = self:GetScale()
        self._scaleChanged = self._lastScale ~= nil and self._lastScale ~= scale
        self._lastScale = scale
        local layout = self:_windowLayout(x, y, w, h, scale)
        local sidebarW = layout.sidebarW
        local topH = layout.topH
        local bottomH = layout.bottomH
        local dragSize = layout.dragSize
        local dragX = layout.dragX
        local dragY = layout.dragY
        local searchX = layout.searchX
        local searchY = layout.searchY
        local searchW = layout.searchW
        local searchH = layout.searchH
        local searchVisible = layout.searchVisible
        self.SearchHitbox = searchVisible and { x = searchX, y = searchY, w = searchW, h = searchH } or nil
        self:_consumeOutsideFloatingClick()
        local overSearch = searchVisible and self:_over(searchX, searchY, searchW, searchH)
        if self:_click(x, y, w, topH) and not overSearch then
            self.DragOffset = Vector2.new(mouse.X - x, mouse.Y - y)
            self:_claimInteraction("WindowDrag")
        end
        if self.DragOffset and self.Mouse1Held then
            self.Position = Vector2.new(mouse.X - self.DragOffset.X, mouse.Y - self.DragOffset.Y)
            x, y = self.Position.X, self.Position.Y
        elseif self.DragOffset then
            self.DragOffset = nil
            self:_releaseInteraction("WindowDrag")
        end
        if self.Resizable then
            local resizeHitW = math.floor(28 * scale)
            local resizeHitH = bottomH
            local resizeX = x + w - resizeHitW
            local resizeY = y + h - resizeHitH
            if self:_focusClick(resizeX, resizeY, resizeHitW, resizeHitH, "WindowResize") then
                self.ResizeOffset = Vector2.new(x + w - mouse.X, y + h - mouse.Y)
                self:_claimInteraction("WindowResize")
                self.Mouse1Clicked = false
            end
            if self.ResizeOffset and self.Mouse1Held then
                local minSizeX = math.floor((self.MinSize and self.MinSize.X or 480) * scale)
                local minSizeY = math.floor((self.MinSize and self.MinSize.Y or 360) * scale)
                local nextW = math.max(minSizeX, mouse.X - x + self.ResizeOffset.X)
                local nextH = math.max(minSizeY, mouse.Y - y + self.ResizeOffset.Y)
                self.Size = Vector2.new(math.floor(nextW + 0.5), math.floor(nextH + 0.5))
                local dpiScale = clamp((self.DPIScale or 100) / 100, 0.5, 2)
                self.LogicalSize = Vector2.new(self.Size.X / dpiScale, self.Size.Y / dpiScale)
                w, h = self.Size.X, self.Size.Y
            elseif self.ResizeOffset then
                self.ResizeOffset = nil
                self:_releaseInteraction("WindowResize")
            end
        end

        self:_shiftWindowVisible(x - prevX, y - prevY)

        layout = self:_windowLayout(x, y, w, h, scale)
        sidebarW = layout.sidebarW
        topH = layout.topH
        bottomH = layout.bottomH
        dragSize = layout.dragSize
        dragX = layout.dragX
        dragY = layout.dragY
        searchX = layout.searchX
        searchY = layout.searchY
        searchW = layout.searchW
        searchH = layout.searchH
        searchVisible = layout.searchVisible
        self.SearchHitbox = searchVisible and { x = searchX, y = searchY, w = searchW, h = searchH } or nil

        local windowCorner =
            math.min(20, math.max(0, math.floor(self._cornerRadius or GalaxObsidian.CornerRadius or 0)))
        self:_square(x - 1, y - 1, w + 2, h + 2, Theme.SoftOutline, true, 1, windowCorner, 1)
        self:_square(x, y, w, h, Theme.Background, true, 1, windowCorner, 2)
        self:_square(x, y, w, h, Theme.SoftOutline, false, 1, windowCorner, 3)
        self:_square(x, y + topH, sidebarW, h - topH - bottomH, Theme.Sidebar, true, 1, 0, 4)
        self:_square(
            x + sidebarW + 1,
            y + topH + 1,
            w - sidebarW - 2,
            h - topH - bottomH - 2,
            Theme.Background,
            true,
            1,
            0,
            4
        )
        local tabEntryH = math.floor(40 * scale)
        local tabY = y + topH
        for _, tab in ipairs(self.Tabs) do
            if self:_click(x, tabY, sidebarW, tabEntryH) then
                self.ActiveTab = tab
                self:_closeFloating()
            end
            tabY = tabY + tabEntryH
        end
        local chromeZ = 88
        self:_square(x, y, w, topH, Theme.Topbar, true, 1, windowCorner, chromeZ)
        self:_square(x, y + topH, sidebarW, h - topH - bottomH, Theme.Sidebar, true, 1, 0, chromeZ)
        self:_line(x, y + topH, x + w, y + topH, Theme.Outline, 1, chromeZ + 3)
        self:_line(x + sidebarW, y, x + sidebarW, y + h - bottomH - 1, Theme.Outline, 1, chromeZ + 1)
        self:_square(x, y + h - bottomH, w, bottomH, Theme.Bottombar, true, 1, windowCorner, chromeZ + 1)
        self:_line(x, y + h - bottomH, x + w, y + h - bottomH, Theme.BottombarBorder, 1, chromeZ + 2)
        local footerTextSize = 14
        local scaledFooterTextSize = math.floor(footerTextSize * scale + 0.5)
        local yOfs = _yOfs(scale)
        local footerText = fitTextToWidth(self.Footer or "", w - math.floor(10 * scale), footerTextSize, Drawing.Fonts.Monospace)
        local footerX = x + math.floor((w - estimateTextWidth(footerText, footerTextSize, Drawing.Fonts.Monospace)) / 2)
        self:_text(
            footerText,
            footerX,
                y + h - bottomH + math.floor((bottomH - scaledFooterTextSize) / 2) - yOfs,
            Theme.FooterText,
            footerTextSize,
            Drawing.Fonts.Monospace,
            false,
            true,
            chromeZ + 4
        )
        if self.Resizable then
            self:_drawIcon(
                "move-diagonal-2",
                x + w - math.floor(10 * scale),
                y + h - bottomH / 2,
                math.floor(14 * scale),
                self.ResizeOffset ~= nil,
                chromeZ + 5
            )
        end
        local chromeTitleSize = 20
        local scaledChromeTitleSize = math.floor(chromeTitleSize * scale + 0.5)
        local yOfs = _yOfs(scale)
        local iconMax = math.floor(30 * scale)
        local iconW, iconH = 0, 0
        if self.IconReady and self.IconData then
            local nativeW, nativeH = self.IconNativeW, self.IconNativeH
            local target = math.min(math.floor((self.IconSize or 30) * scale), iconMax)
            if nativeW and nativeH and nativeW > 0 and nativeH > 0 then
                local aspect = nativeW / nativeH
                if aspect >= 1 then
                    iconW = target
                    iconH = math.max(1, math.floor(iconW / aspect))
                else
                    iconH = target
                    iconW = math.max(1, math.floor(iconH * aspect))
                end
            else
                iconW, iconH = target, target
            end
        end
        local gap = iconW > 0 and math.floor(6 * scale) or 0
        local titleMaxW = math.max(0, sidebarW - math.floor(24 * scale) - iconW - gap)
        local chromeTitleText = self.Title ~= "" and fitTextToWidth(self.Title, titleMaxW, chromeTitleSize, Theme.Font) or ""
        local chromeTitleW = chromeTitleText ~= "" and estimateTextWidth(chromeTitleText, chromeTitleSize, Theme.Font) or 0
        if chromeTitleW <= 0 then
            gap = 0
        end
        local totalW = iconW + gap + chromeTitleW
        local startX = x + math.floor((sidebarW - totalW) / 2)
        if iconW > 0 then
            self:_image(self.IconData, startX, y + math.floor((topH - iconH) / 2), iconW, iconH, 0, chromeZ + 4)
            startX = startX + iconW + gap
        end
        if chromeTitleW > 0 then
            self:_text(
                chromeTitleText,
                startX,
                y + math.floor((topH - scaledChromeTitleSize) / 2) - yOfs,
                Theme.Text,
                chromeTitleSize,
                Drawing.Fonts.Monospace,
                false,
                true,
                chromeZ + 4
            )
        end
        if searchVisible then
            self:_square(searchX, searchY, searchW, searchH, Theme.Main, true, 1, 4, chromeZ + 3)
            self:_square(
                searchX,
                searchY,
                searchW,
                searchH,
                Theme.Outline,
                false,
                1,
                4,
                chromeZ + 4
            )
            self:_drawIcon("search", searchX + math.floor(16 * scale), searchY + searchH / 2, math.floor(16 * scale), self.SearchFocused or overSearch, chromeZ + 5)
            self:_renderTextInputValue(
                self.SearchText,
                self.SearchPlaceholder,
                searchX + math.floor(40 * scale),
                searchY + math.floor((searchH - math.floor(16 * scale)) / 2),
                searchW - math.floor(70 * scale),
                16,
                self.SearchFocused,
                false,
                chromeZ + 5,
                false,
                "Center"
            )
            if self:_focusClick(searchX, searchY, searchW, searchH, "Search") then
                self.SearchFocused = true
                self:_closeFloating("search")
                self:_claimInteraction("Search")
            end
        end
        if self.Mouse1Clicked and (not searchVisible or not self:_over(searchX, searchY, searchW, searchH)) then
            self.SearchFocused = false
            self:_releaseInteraction("Search", true)
        end
        self:_drawIcon("move", dragX, dragY, dragSize, self.DragOffset ~= nil, chromeZ + 5)
        local chromeTabY = y + topH
        for _, tab in ipairs(self.Tabs) do
            local active = tab == self.ActiveTab
            local over = self:_hover(x, chromeTabY, sidebarW, tabEntryH, tab)
            local sidebarBg = self:_animOrSnap(
                tab,
                "sidebar.bg",
                active and Theme.Surface or Theme.Sidebar,
                16
            )
            if active then
                self:_square(x, chromeTabY, sidebarW, tabEntryH, sidebarBg, true, 1, 0, chromeZ + 2)
            end
            local iconX = x + math.floor(18 * scale)
            local iconY = chromeTabY + math.floor(tabEntryH / 2)
            local tabColor = self:_animOrSnap(tab, "sidebar.text", (active or over) and Theme.Text or Theme.Muted, 16)
            self:_drawIcon(tab.Icon or tab.Name, iconX, iconY, math.floor(16 * scale), active or over, chromeZ + 4)
            self:_text(
                fitTextToWidth(tab.Name, sidebarW - math.floor(38 * scale), 16, Theme.Font),
                x + math.floor(38 * scale),
                chromeTabY + math.floor(12 * scale),
                tabColor,
                16,
                Drawing.Fonts.Monospace,
                false,
                true,
                chromeZ + 5
            )
            chromeTabY = chromeTabY + tabEntryH
        end
        if self.SidebarImageReady and self.SidebarImageData then
            local maxH = h - topH - bottomH

            local imgScale = tonumber(self.SidebarImageScale) or 1.0
            if imgScale <= 0 then imgScale = 1.0 end

            local nativeW = tonumber(self.SidebarImageNativeW)
            local nativeH = tonumber(self.SidebarImageNativeH)
            local aspectRatio = 1
            if nativeW and nativeW > 0 and nativeH and nativeH > 0 then
                aspectRatio = nativeW / nativeH
            end

            local imgW = math.floor(sidebarW * imgScale)
            local imgH = (aspectRatio > 0) and math.floor(imgW / aspectRatio) or imgW

            if imgH > maxH then
                imgH = maxH
                imgW = math.floor(imgH * aspectRatio)
            end

            local rawOX = tonumber(self.SidebarImageX)
            local rawOY = tonumber(self.SidebarImageY)
            local imgX, imgY
            if rawOX and rawOY and (rawOX ~= 0 or rawOY ~= 0) then
                imgX = x + rawOX
                imgY = y + topH + rawOY
            else
                imgX = x + math.floor((sidebarW - imgW) / 2)
                imgY = y + h - bottomH - imgH
            end
            self:_image(self.SidebarImageData, imgX, imgY, imgW, imgH, 0, chromeZ + 3)
        end
        if self.ActiveTab then
            self:_renderSections(self.ActiveTab, x + sidebarW, y + topH, w - sidebarW, h - topH - bottomH, 10, y, y + h)
        end
        self:_square(x, y, w, h, Theme.SoftOutline, false, 1, windowCorner, chromeZ + 7)
        self._renderingMainWindow = false
        self:_renderDropdownPopup()
        self:_renderColorPickerPopup()
        self:_renderKeybindMenu()
        self:_renderKeybindModePopup()
        self:_renderDraggableLabels()
        self:_renderDraggableButtons()
        self:_renderDraggableMenus()
        NotificationManager:RenderNotifications(self)
        self:_renderLoading()
        self:_renderTooltip()
        GalaxObsidian.DialogManager:RenderDialogs(self)
        self:_hideUnused()
    end

    function Window:Notify(message, title, duration)
        return NotificationManager:Notify(message, title, duration)
    end
    function Window:AddDialog(id, options)
        if type(id) == "table" then
            options = id
        else
            options = options or {}
            options.Index = options.Index or id
        end
        return DialogManager:Dialog(options)
    end
    function Window:AddDraggableLabel(text)
        local labels = self.DraggableLabels
        local entry = {
            text = tostring(text or ""),
            px = 100,
            py = 100,
            dragging = false,
            doffX = 0,
            doffY = 0,
            visible = true,
        }
        table.insert(labels, entry)
        function entry:SetText(value)
            self.text = tostring(value or "")
        end
        function entry:SetVisible(state)
            self.visible = state == true
        end
        function entry:Destroy()
            self.destroyed = true
            self.visible = false
        end
        return entry
    end
    function Window:AddDraggableButton(text, callback, excludeDpi, icon, iconPosition)
        local entry = {
            text = tostring(text or ""), callback = callback, px = 100, py = 140,
            visible = true, excludeDpi = excludeDpi == true, icon = icon,
            iconPosition = iconPosition == "Right" and "Right" or "Left",
        }
        table.insert(self.DraggableButtons, entry)
        function entry:SetText(value) self.text = tostring(value or "") end
        function entry:SetVisible(state) self.visible = state == true end
        function entry:Destroy() self.destroyed = true; self.visible = false end
        return entry
    end
    function Window:AddDraggableMenu(title, options)
        options = options or {}
        local menu = {
            title = tostring(title or "Menu"), x = tonumber(options.X) or 130,
            y = tonumber(options.Y) or 180, width = tonumber(options.Width) or 220,
            visible = true, items = {},
        }
        local container = {}
        table.insert(self.DraggableMenus, menu)
        function menu:SetTitle(value) self.title = tostring(value or "") end
        function menu:SetVisible(state) self.visible = state == true end
        function menu:SetWidth(value) self.width = math.max(120, tonumber(value) or self.width) end
        function menu:Destroy() self.destroyed = true; self.visible = false end
        local function addItem(kind, text, callback)
            local item = { kind = kind, text = tostring(text or ""), callback = callback, visible = true }
            table.insert(menu.items, item)
            function item:SetText(value) self.text = tostring(value or "") end
            function item:SetVisible(state) self.visible = state == true end
            function item:Destroy() self.destroyed = true; self.visible = false end
            return item
        end
        function container:AddLabel(text) return addItem("label", text) end
        function container:AddValue(text) return addItem("value", text) end
        function container:AddButton(text, callback) return addItem("button", text, callback) end
        return menu, container
    end

    function Window:GetMemoryUsage()
        local total = 0
        local byKind = {}
        for kind, list in pairs(self.Pool) do
            local count = #list
            byKind[kind] = count
            total = total + count
        end
        return total, byKind
    end
    function Window:SetVisible(state)
        self:_setOpen(state == true)
    end
    function Window:SetIconUrl(url)
        url = imageUrl(url)
        self.IconUrl = url
        self.IconReady = false
        self.IconData = nil
        self.IconNativeW, self.IconNativeH = nil, nil
        if not url or url == "" then
            return nil
        end
        RequestImage(url, function(data)
            self.IconData = data
            self.IconNativeW, self.IconNativeH = parsePngDimensions(data)
            self.IconReady = true
        end)
    end
    function Window:SetIconData(data)
        self.IconUrl = nil
        self.IconData = data
        self.IconReady = data ~= nil and data ~= ""
        self.IconNativeW, self.IconNativeH = parsePngDimensions(data)
    end
    function Window:SetSidebarImage(url, scale, imgX, imgY)
        local resolved = url and imageUrl(url) or nil
        if not resolved or resolved == "" then
            self.SidebarImage = nil
            self.SidebarImageData = nil
            self.SidebarImageReady = false
            self.SidebarImageNativeW = nil
            self.SidebarImageNativeH = nil
            return
        end
        self.SidebarImage = resolved
        self.SidebarImageScale = scale or 1.0
        self.SidebarImageX = imgX
        self.SidebarImageY = imgY
        self.SidebarImageReady = false
        self.SidebarImageData = nil
        self.SidebarImageNativeW = nil
        self.SidebarImageNativeH = nil
        RequestImage(resolved, function(data)
            self.SidebarImageData = data
            self.SidebarImageNativeW, self.SidebarImageNativeH = parsePngDimensions(data)
            self.SidebarImageReady = true
        end)
    end
    function Window:SetNotifySide(side)
        side = tostring(side or "Right")
        self.NotifySide = side == "Left" and "Left" or "Right"
    end
    function Window:ChangeTitle(title)
        self.Title = tostring(title or "")
    end
    function Window:SetFooter(footer)
        self.Footer = tostring(footer or "")
    end
    function Window:GetSidebarWidth()
        return self.Compact and 72 or self.SidebarWidth
    end
    function Window:SetSidebarWidth(width)
        width = tonumber(width)
        assert(width and width >= 72 and width <= 360, "Sidebar width must be between 72 and 360!")
        self.SidebarWidth = width
    end
    function Window:SetCompact(state)
        self.Compact = state == true
    end
    function Window:IsSidebarCompacted()
        return self.Compact == true
    end
    function Window:SetAnimations(state)
        self.AnimationsEnabled = state ~= false
    end
    function Window:SetKeybindMenuVisible(state)
        self.ShowKeybindMenu = state == true
        local toggle = self.Toggles["KeybindMenuOpen"]
        if toggle and toggle.Widget then
            toggle.Widget.value = self.ShowKeybindMenu
        end
    end
    function Window:SetKeybindMenuPosition(x, y)
        self.KeybindMenuX = x
        self.KeybindMenuY = y
    end
    function Window:SetKeybindMenuWidth(width)
        self.KeybindMenuWidth = width
    end
    function Window:SetDPIScale(percent)
        percent = tonumber(percent) or 100
        percent = math.floor(clamp(percent, 50, 200) + 0.5)
        local oldSize = self.Size or self.LogicalSize or Vector2.new(820, 600)
        local center = Vector2.new(self.Position.X + oldSize.X / 2, self.Position.Y + oldSize.Y / 2)
        local oldScale = clamp((self.DPIScale or 100) / 100, 0.5, 2)
        local logical = self.LogicalSize
        if not logical then
            logical = Vector2.new(oldSize.X / oldScale, oldSize.Y / oldScale)
        end
        local scale = clamp(percent / 100, 0.5, 2)
        local newSize = Vector2.new(
            math.max(math.floor((self.MinSize and self.MinSize.X or 480) * scale + 0.5), math.floor(logical.X * scale + 0.5)),
            math.max(math.floor((self.MinSize and self.MinSize.Y or 360) * scale + 0.5), math.floor(logical.Y * scale + 0.5))
        )

        self.DPIScale = percent
        self.LogicalSize = logical
        self.Size = newSize
        self.Position = Vector2.new(math.floor(center.X - newSize.X / 2 + 0.5), math.floor(center.Y - newSize.Y / 2 + 0.5))
        GalaxObsidian.DPIScale = percent
    end
    function Window:GetTheme()
        local copy = {}

        for key, value in pairs(Theme) do
            copy[key] = value
        end
        copy.Accent = self.Accent
        return copy
    end
    function Window:SetTheme(values)
        values = values or {}
        local background = themeColor(values.BackgroundColor)
        local main = themeColor(values.MainColor)
        local accent = themeColor(values.AccentColor)
        local outline = themeColor(values.OutlineColor)
        local outline2 = themeColor(values.Outline2)
        local surface2 = themeColor(values.Surface2)
        local muted = themeColor(values.Muted)
        local dimText = themeColor(values.DimText)
        local popupHover = themeColor(values.PopupHover)
        local font = themeColor(values.FontColor)
        local bottombar = themeColor(values.Bottombar)
        local bottombarBorder = themeColor(values.BottombarBorder)
        local footerText = themeColor(values.FooterText)
        local base = background
        if base then
            Theme.Background = base
        end

        -- Track which chrome fields were explicitly provided
        local explicit = {}

        if main then
            Theme.Main = main
            Theme.Surface = main
            explicit.Main = true
        end
        if accent then
            Theme.Accent = accent
            self.Accent = accent
        end
        if outline then
            Theme.Outline = outline
            Theme.SoftOutline = outline
            explicit.Outline = true
        end
        if outline2 then
            Theme.Outline2 = outline2
            explicit.Outline2 = true
        end
        if surface2 then
            Theme.Surface2 = surface2
            explicit.Surface2 = true
        end
        if muted then
            Theme.Muted = muted
            explicit.Muted = true
        end
        if dimText then
            Theme.DimText = dimText
            explicit.DimText = true
        end
        if popupHover then
            Theme.PopupHover = popupHover
            explicit.PopupHover = true
        end
        if font then
            Theme.Text = font
        end
        if bottombar then
            Theme.Bottombar = bottombar
            explicit.Bottombar = true
        end
        if bottombarBorder then
            Theme.BottombarBorder = bottombarBorder
            explicit.BottombarBorder = true
        end
        if footerText then
            Theme.FooterText = footerText
            explicit.FooterText = true
        end
        -- Apply chrome offsets only for fields NOT explicitly provided
        if base then
            applyChromeOffsets(base, explicit)
        end
        applyTextOffsets(Theme.Text, explicit)
    end

    function Window:Destroy()
        self.Running = false
        self:_setOpen(false)
        for _, list in pairs(self.Pool) do
            for _, object in ipairs(list) do
                local ok, err = pcall(function()
                    object:Remove()
                end)
                if not ok then error("Destroy pool cleanup: " .. tostring(err), 2) end
                drawingMeta[object] = nil
            end
        end
    end

    function Window:AddTab(name, icon)
        local tabName = name
        local tabIcon = icon
        if type(name) == "table" then
            tabName = name.Name or name.Title or name.Text
            tabIcon = name.Icon or name.IconName or tabIcon
        end
        local Tab = { Name = tabName or "Tab", Icon = tabIcon, Sections = {}, _Window = self }

        if not self.ActiveTab then
            self.ActiveTab = Tab
        end
        self.Tabs[#self.Tabs + 1] = Tab
        function Tab:Select()
            self._Window.ActiveTab = self
            self._Window:_closeFloating()
        end

        function Tab:AddSection(sectionName, side)
            if type(sectionName) == "table" then
                side = sectionName.Side or sectionName.side or side
                sectionName = sectionName.Name or sectionName.Text
            end
            local Section = { Name = sectionName or "Section", widgets = {}, side = side }
            self.Sections[#self.Sections + 1] = Section

            local function register(widget)
                if widget.visible == nil then
                    widget.visible = true
                end
                Section.widgets[#Section.widgets + 1] = widget
                return widget
            end
            local function infoArgs(label, info)
                if type(label) == "table" then
                    return label, label
                end
                if type(info) == "table" then
                    return label, info
                end
                return label, nil
            end
            local function setImageSource(widget, source)
                assert(source ~= nil and source ~= "", "Section:AddImage requires image data or URL!")
                if isImageData(source) then
                    widget.source = source
                    widget.data = source
                    widget.loading = false
                    return
                end
                local resolved = imageUrl(source)
                assert(type(resolved) == "string" and resolved ~= "", "Section:AddImage requires valid image data or URL!")
                widget.source = resolved
                widget.data = nil
                widget.loading = true
                RequestImage(resolved, function(data)
                    if widget.source == resolved and not widget.destroyed then
                        widget.data = data
                        widget.loading = false
                    end
                end)
            end

            function Section:AddLabel(text, doesWrap, idx)
                local _, info = infoArgs(text)
                local id = idx or (info and (info.Index or info.Idx)) or text
                local widget = register({
                    type = "label",
                    id = id,
                    text = info and (info.Text or info.Label) or text or "",
                    tooltip = info and info.Tooltip,
                    visible = not (info and info.Visible == false),
                    size = info and info.Size or 14,
                    doesWrap = info and info.DoesWrap ~= false,
                })
                local handle = Window:_widgetHandle(widget)
                return handle
            end

            function Section:AddImage(source, config)
                if type(source) == "table" then
                    config = source
                    source = config.Image or config.Url or config.Data
                end
                config = config or {}
                if type(source) == "string" and (config.Image or config.Url or config.Data) then
                    config.Index = config.Index or config.Idx or source
                    source = config.Image or config.Url or config.Data
                end
                source = source or config.Image or config.Url or config.Data
                local height = tonumber(config.Height) or 120
                assert(height > 0, "Section:AddImage Height must be greater than zero!")
                local widget = register({
                    type = "image",
                    id = config.Index or config.Idx,
                    label = config.Label or config.Text or "Image",
                    height = height,
                    rounding = math.max(0, tonumber(config.Rounding) or 0),
                    transparency = clamp(tonumber(config.Transparency) or 1, 0, 1),
                    tooltip = config.Tooltip,
                    visible = config.Visible ~= false,
                    destroyed = false,
                })
                setImageSource(widget, source)
                local handle = Window:_widgetHandle(widget)
                function handle:SetImage(value)
                    assert(not widget.destroyed, "Image widget was destroyed!")
                    setImageSource(widget, value)
                end
                function handle:SetHeight(value)
                    value = tonumber(value)
                    assert(value and value > 0, "Image height must be greater than zero!")
                    widget.height = value
                end
                function handle:SetRounding(value)
                    value = tonumber(value)
                    assert(value and value >= 0, "Image rounding must be zero or greater!")
                    widget.rounding = value
                end
                function handle:SetTransparency(value)
                    value = tonumber(value)
                    assert(value and value >= 0 and value <= 1, "Image transparency must be between zero and one!")
                    widget.transparency = value
                end
                function handle:Destroy()
                    if widget.destroyed then
                        return
                    end
                    widget.destroyed = true
                    widget.visible = false
                    for i = #Section.widgets, 1, -1 do
                        if Section.widgets[i] == widget then
                            table.remove(Section.widgets, i)
                            break
                        end
                    end
                    if widget.id and Window.Options[widget.id] == handle then
                        Window.Options[widget.id] = nil
                    end
                end
                return handle
            end

            function Section:AddButton(label, callback)
                local _, info = infoArgs(label, callback)
                local widget = register({
                    type = "button",
                    label = info and (info.Text or info.Label) or label or "Button",
                    callback = info and (info.Callback or info.Func) or callback,
                    tooltip = info and info.Tooltip,
                    disabled = info and info.Disabled == true,
                    visible = not (info and info.Visible == false),
                    _doubleConfirm = info and info.DoubleClick == true or nil,
                    _confirmPending = false,
                })
                local handle = Window:_widgetHandle(widget)
                handle.AddButton = function(_, subInfo)
                    subInfo = type(subInfo) == "table" and subInfo or { Text = tostring(subInfo or "Sub button") }
                    widget.visible = false
                    local origCb = subInfo.Callback or subInfo.Func
                    local rightWidget = {
                        type = "button",
                        label = subInfo.Text or subInfo.Label or "Sub button",
                        callback = origCb,
                        tooltip = subInfo.Tooltip,
                        disabled = subInfo.Disabled == true,
                        visible = subInfo.Visible ~= false,
                        _doubleConfirm = true,
                        _confirmPending = false,
                    }
                    register({ type = "buttonpair", left = widget, right = rightWidget, visible = true })
                    return Window:_widgetHandle(rightWidget)
                end
                return handle
            end

            function Section:AddButtonPair(left, right)
                local _, leftInfo = infoArgs(left)
                local _, rightInfo = infoArgs(right)
                leftInfo = leftInfo or {}
                rightInfo = rightInfo or {}
                local leftWidget = {
                    type = "button",
                    label = leftInfo.Text or leftInfo.Label or tostring(left or "Button"),
                    callback = leftInfo.Callback or leftInfo.Func,
                    tooltip = leftInfo.Tooltip,
                    disabled = leftInfo.Disabled == true,
                    visible = leftInfo.Visible ~= false,
                }
                local rightWidget = {
                    type = "button",
                    label = rightInfo.Text or rightInfo.Label or tostring(right or "Sub button"),
                    callback = rightInfo.Callback or rightInfo.Func,
                    tooltip = rightInfo.Tooltip,
                    disabled = rightInfo.Disabled == true,
                    visible = rightInfo.Visible ~= false,
                    _doubleConfirm = true,
                    _confirmPending = false,
                }
                register({ type = "buttonpair", left = leftWidget, right = rightWidget, visible = true })
                return Window:_widgetHandle(leftWidget), Window:_widgetHandle(rightWidget)
            end

            function Section:AddTabbox(tabNames)
                local widget = register({ type = "sectiontabs", tabs = {}, active = 1, visible = true })
                local Tabbox = { Widget = widget, Tabs = widget.tabs }
                local function addChild(tab, child)
                    if child.visible == nil then
                        child.visible = true
                    end
                    tab.widgets[#tab.widgets + 1] = child
                    return child
                end
                local function attachTabApi(tab)
                    function tab:AddLabel(text)
                        local _, info = infoArgs(text)
                        local child = addChild(
                            tab,
                            {
                                type = "label",
                                text = info and (info.Text or info.Label) or text or "",
                                tooltip = info and info.Tooltip,
                                visible = not (info and info.Visible == false),
                            }
                        )
                        return Window:_widgetHandle(child)
                    end
                    function tab:AddButton(label, callback)
                        local _, info = infoArgs(label, callback)
                        local child = addChild(
                            tab,
                            {
                                type = "button",
                                label = info and (info.Text or info.Label) or label or "Button",
                                callback = info and (info.Callback or info.Func) or callback,
                                tooltip = info and info.Tooltip,
                                disabled = info and info.Disabled == true,
                                visible = not (info and info.Visible == false),
                            }
                        )
                        return Window:_widgetHandle(child)
                    end
                    function tab:AddToggle(label, default, callback, keybind)
                        local _, info = infoArgs(label, default)
                        local child = addChild(
                            tab,
                            {
                                type = "toggle",
                                label = info and (info.Text or info.Label) or label or "Toggle",
                                value = info and info.Default == true or default == true,
                                _default = info and info.Default == true or default == true,
                                callback = info and info.Callback or callback,
                                changed = info and info.Changed or nil,
                                keybind = info and info.Keybind or keybind,
                                tooltip = info and info.Tooltip,
                                listening = false,
                                disabled = info and info.Disabled == true,
                                visible = not (info and info.Visible == false),
                            }
                        )
                        return Window:_widgetHandle(child, {
                            Get = function()
                                return child.value
                            end,
                            Set = function(_, value)
                                child.value = value == true
                                _fire(child, child.value)
                            end,
                            SetValue = function(selfHandle, value)
                                return selfHandle:Set(value)
                            end,
                            SetKey = function(_, key)
                                child.keybind = key
                            end,
                        })
                    end
                    tab.AddCheckbox = tab.AddToggle
                    return tab
                end
                function Tabbox:AddTab(name)
                    local tab =
                        attachTabApi({ name = tostring(name or ("Tab " .. tostring(#widget.tabs + 1))), widgets = {} })
                    widget.tabs[#widget.tabs + 1] = tab
                    return tab
                end
                function Tabbox:GetTab(index)
                    return widget.tabs[index]
                end
                function Tabbox:SetActive(index)
                    if widget.tabs[index] then
                        widget.active = index
                    end
                end
                if type(tabNames) == "table" then
                    for _, name in ipairs(tabNames) do
                        Tabbox:AddTab(name)
                    end
                elseif type(tabNames) == "string" then
                    Tabbox:AddTab(tabNames)
                end
                return Tabbox
            end
            Section.AddTabs = Section.AddTabbox
            Section.AddSubButton = Section.AddButtonPair

            function Section:AddToggle(label, default, callback, keybind)
                local _, info = infoArgs(label, default)
                local id = info and (info.Index or info.Idx) or label
                local widget = register({
                    type = "toggle",
                    id = id,
                    label = info and (info.Text or info.Label) or label or "Toggle",
                    value = info and info.Default == true or default == true,
                    _default = info and info.Default == true or default == true,
                    callback = info and info.Callback or callback,
                    changed = info and info.Changed or nil,
                    keybind = info and info.Keybind or keybind,
                    tooltip = info and info.Tooltip,
                    
                    listening = false,
                    disabled = info and info.Disabled == true,
                    visible = not (info and info.Visible == false),
                })
                local handle = Window:_widgetHandle(widget, {
                    Get = function()
                        return widget.value
                    end,
                    Set = function(_, value)
                        widget.value = value == true
                        Window:_syncToggleKeypickerAddons(widget)
                        _fire(widget, widget.value)
                    end,
                    SetKey = function(_, key)
                        widget.keybind = key
                    end,
                    OnChanged = function(_, cb)
                        widget.changed = cb
                    end,
                })
                handle.AddColorPicker = makeAddColorPickerClosure(widget, true)
                handle.AddKeyPicker = makeAddKeyPickerClosure(widget, true)
                return handle
            end

            function Section:AddCheckbox(label, default, callback, keybind)
                local _, info = infoArgs(label, default)
                local id = info and (info.Index or info.Idx) or label
                local widget = register({
                    type = "checkbox",
                    id = id,
                    label = info and (info.Text or info.Label) or label or "Checkbox",
                    value = info and info.Default == true or default == true,
                    _default = info and info.Default == true or default == true,
                    callback = info and info.Callback or callback,
                    changed = info and info.Changed or nil,
                    keybind = info and info.Keybind or keybind,
                    tooltip = info and info.Tooltip,
                    
                    listening = false,
                    disabled = info and info.Disabled == true,
                    visible = not (info and info.Visible == false),
                })
                local handle = Window:_widgetHandle(widget, {
                    Get = function()
                        return widget.value
                    end,
                    Set = function(_, value)
                        widget.value = value == true
                        Window:_syncToggleKeypickerAddons(widget)
                        _fire(widget, widget.value)
                    end,
                    SetKey = function(_, key)
                        widget.keybind = key
                    end,
                    OnChanged = function(_, cb)
                        widget.changed = cb
                    end,
                })
                handle.AddColorPicker = makeAddColorPickerClosure(widget, true)
                handle.AddKeyPicker = makeAddKeyPickerClosure(widget, true)
                return handle
            end

            function Section:AddSlider(label, config, callback)
                local _, info = infoArgs(label, config)
                if info then
                    config = info
                end
                config = config or {}
                local id = config.Index or config.Idx or label
                local minValue = config.Min or 0
                local maxValue = config.Max or 100
                local default = config.Default
                if default == nil then
                    default = minValue
                end
                local widget = register({
                    type = "slider",
                    id = id,
                    label = config.Text or config.Label or label or "Slider",
                    min = minValue,
                    max = maxValue,
                    value = clamp(default, minValue, maxValue),
                    _default = clamp(default, minValue, maxValue),
                    prefix = config.Prefix or "",
                    suffix = config.Suffix or "",
                    rounding = config.Round == false and false or (config.Rounding or config.Precision or 0),
                    integer = config.Integer == true,
                    compact = config.Compact == true,
                    hideMax = config.HideMax == true,
                    formatDisplayValue = config.FormatDisplayValue,
                    callback = config.Callback or callback,
                    changed = config.Changed,
                    tooltip = config.Tooltip,
                    disabledTooltip = config.DisabledTooltip,
                    allowRightClickInput = config.AllowRightClickInput == true,
                    disabled = config.Disabled == true,
                    visible = config.Visible ~= false,
                })
                return Window:_widgetHandle(widget)
            end
            local function listPlayers(excludeLocal)
                local players = game:GetService("Players")
                local result = {}

                for _, p in ipairs(players:GetPlayers()) do
                    if not (excludeLocal and p == players.LocalPlayer) then
                        result[#result + 1] = p.Name
                    end
                end
                table.sort(result)
                return result
            end
            local function listTeams()
                local result = {}
                local svc = game:GetService("Teams")
                if svc then
                    for _, t in ipairs(svc:GetChildren()) do
                        if t:IsA("Team") then
                            result[#result + 1] = t.Name
                        end
                    end
                    table.sort(result)
                end
                return result
            end
            local function specialDropdownValues(config)
                if config.SpecialType == "Player" then
                    return listPlayers(config.ExcludeLocalPlayer == true)
                end
                if config.SpecialType == "Team" then
                    return listTeams()
                end
                return nil
            end
            local function refreshSpecialDropdown(widget, config)
                local specialType = config.SpecialType
                if specialType ~= "Player" and specialType ~= "Team" then
                    return
                end
                local interval = specialType == "Player" and (tonumber(config.RefreshInterval) or 2) or 5
                interval = math.max(0.25, interval)
                task.spawn(function()
                    while Window.Running and not GalaxObsidian.Unloaded and not widget.destroyed do
                        task.wait(interval)
                        if Window.Running and not GalaxObsidian.Unloaded and not widget.destroyed then
                            widget.options = specialDropdownValues(config) or {}
                        end
                    end
                end)
            end

            function Section:AddDropdown(label, optionsList, default, config, callback)
                local info = nil
                if type(label) == "table" then
                    info = label
                elseif
                    type(optionsList) == "table"
                    and (
                        optionsList.Values ~= nil
                        or optionsList.Options ~= nil
                        or optionsList.Text ~= nil
                        or optionsList.Label ~= nil
                        or optionsList.Default ~= nil
                        or optionsList.Multi ~= nil
                    )
                then
                    info = optionsList
                end
                if info then
                    optionsList = info.Values or info.Options or {}
                    default = info.Default
                    config = info
                    callback = info.Callback
                end
                if type(config) == "function" then
                    callback = config
                    config = {}
                end
                config = config or {}

                local specialValues = specialDropdownValues(config)
                if specialValues then
                    optionsList = specialValues
                end
                if config.Multi == true then
                    return Section:AddMultiDropdown(label, optionsList, default, config, callback)
                end
                optionsList = optionsList or {}
                local searchable = config.Searchable == true
                local id = config.Index or config.Idx or label
                if type(default) == "number" and optionsList[default] then
                    default = optionsList[default]
                end
                local widget = register({
                    type = "dropdown",
                    id = id,
                    label = config.Text or config.Label or label or "Dropdown",
                    options = optionsList,
                    value = default,
                    _default = default,
                    allowNull = config.AllowNull == true,
                    placeholder = config.Placeholder or "---",
                    maxVisible = config.MaxVisible or config.MaxVisibleDropdownItems or 6,
                    callback = callback,
                    changed = config.Changed,
                    tooltip = config.Tooltip,
                    disabledTooltip = config.DisabledTooltip,
                    disabled = config.Disabled == true,
                    disabledValues = config.DisabledValues or {},
                    valueImages = config.ValueImages or {},
                    dragSelect = config.AllowDragSelect == true or config.DragSelect == true,
                    searchable = searchable,
                    _searchText = searchable and "" or nil,
                    specialType = config.SpecialType,
                    formatDisplayValue = config.FormatDisplayValue,
                    visible = config.Visible ~= false,
                    popup = nil,
                })
                refreshSpecialDropdown(widget, config)
                return Window:_widgetHandle(widget)
            end

            function Section:AddMultiDropdown(label, optionsList, default, config, callback)
                local info = nil
                if type(label) == "table" then
                    info = label
                elseif
                    type(optionsList) == "table"
                    and (
                        optionsList.Values ~= nil
                        or optionsList.Options ~= nil
                        or optionsList.Text ~= nil
                        or optionsList.Label ~= nil
                        or optionsList.Default ~= nil
                        or optionsList.Multi ~= nil
                    )
                then
                    info = optionsList
                end
                if info then
                    optionsList = info.Values or info.Options or {}
                    default = info.Default
                    config = info
                    callback = info.Callback
                end
                if type(config) == "function" then
                    callback = config
                    config = {}
                end
                config = config or {}
                local specialValues = specialDropdownValues(config)
                if specialValues then
                    optionsList = specialValues
                end
                optionsList = optionsList or {}
                local selected = {}

                if default then
                    if type(default) == "table" then
                        for _, value in ipairs(default) do
                            selected[value] = true
                        end
                    else
                        selected[default] = true
                    end
                end
                local searchable = config.Searchable == true
                local id = config.Index or config.Idx or label
                local widget = register({
                    type = "multidropdown",
                    id = id,
                    label = config.Text or config.Label or label or "MultiDropdown",
                    options = optionsList,
                    selected = selected,
                    _default = default,
                    min = config.Min or 1,
                    max = config.Max or math.huge,
                    maxVisible = config.MaxVisible or config.MaxVisibleDropdownItems or 6,
                    callback = callback,
                    changed = config.Changed,
                    tooltip = config.Tooltip,
                    disabled = config.Disabled == true,
                    disabledValues = config.DisabledValues or {},
                    valueImages = config.ValueImages or {},
                    dragSelect = config.AllowDragSelect == true or config.DragSelect == true,
                    searchable = searchable,
                    _searchText = searchable and "" or nil,
                    formatDisplayValue = config.FormatDisplayValue,
                    visible = config.Visible ~= false,
                    popup = nil,
                })
                refreshSpecialDropdown(widget, config)
                return Window:_widgetHandle(widget)
            end

            function Section:AddKeybind(label, default, callback)
                local _, info = infoArgs(label, default)
                local id = info and (info.Index or info.Idx) or label
                local widget = register({
                    type = "keybind",
                    id = id,
                    label = info and (info.Text or info.Label) or label or "Keybind",
                    value = info and (info.Default or "None") or default or 0,
                    mode = info and (info.Mode or info.ModeName) or "Hold",
                    callback = info and (info.Callback or info.Clicked) or callback,
                    changed = info and (info.Changed or info.ChangedCallback) or nil,
                    tooltip = info and info.Tooltip,
                    listening = false,
                    disabled = info and info.Disabled == true,
                    visible = not (info and info.Visible == false),
                    _state = false,
                    _prevHeld = false,
                })
                if info and info.Popup ~= nil then
                    local enabled, modes = resolveKeybindPopupConfig(info.Popup)
                    widget.popupEnabled = enabled
                    widget.popupModes = modes
                end
                return Window:_widgetHandle(widget, {
                    Get = function()
                        return widget.value
                    end,
                    Set = function(_, value)
                        if type(value) == "table" then
                            widget.value = value[1] or value.Key or value.key or widget.value
                            widget.mode = value[2] or value.Mode or value.mode or widget.mode
                            widget.modifiers = value.Modifiers or value.modifiers
                        else
                            widget.value = value
                        end
                        safeCall(widget.changed, widget.value, widget.modifiers)
                    end,
                    SetValue = function(selfHandle, value)
                        return selfHandle:Set(value)
                    end,
                    OnClick = function(_, cb)
                        widget.callback = cb
                    end,
                })
            end

            function Section:AddColorPicker(label, info)
                local _, config = infoArgs(label, info)
                config = config or {}
                local id = config.Index or config.Idx or label
                local default = config.Default or Color3.new(1, 1, 1)
                local hue, sat, vib = rgbToHsv(default)
                local widget = register({
                    type = "colorpicker",
                    id = id,
                    label = config.Text or config.Label or label or "ColorPicker",
                    title = config.Title,
                    value = default,
                    hue = hue,
                    sat = sat,
                    vib = vib,
                    transparency = config.Transparency or 0,
                    transparencyEnabled = config.Transparency ~= nil,
                    callback = config.Callback,
                    changed = config.Changed,
                    tooltip = config.Tooltip,
                    disabled = config.Disabled == true,
                    visible = config.Visible ~= false,
                    popup = nil,
                })
                local handle = Window:_widgetHandle(widget, {
                    Get = function()
                        return widget.value, widget.transparency
                    end,
                    SetHSVFromRGB = function(_, color)
                        widget.hue, widget.sat, widget.vib = rgbToHsv(color)
                    end,
                    SetValue = function(selfHandle, hsv, transparency)
                        if type(hsv) == "table" and hsv.R ~= nil then
                            return selfHandle:SetValueRGB(hsv, transparency)
                        end
                        local color = Color3.fromHSV(hsv[1] or 0, hsv[2] or 0, hsv[3] or 0)
                        widget.value = color
                        widget.transparency = widget.transparencyEnabled and (transparency or 0) or 0
                        widget.hue, widget.sat, widget.vib = rgbToHsv(color)
                        _fire(widget, widget.value, widget.transparency)
                    end,
                    SetValueRGB = function(_, color, transparency)
                        widget.value = color
                        widget.transparency = widget.transparencyEnabled and (transparency or 0) or 0
                        widget.hue, widget.sat, widget.vib = rgbToHsv(color)
                        _fire(widget, widget.value, widget.transparency)
                    end,
                })
                return handle
            end

            function Section:AddColorPickerPair(leftLabel, leftInfo, rightLabel, rightInfo)
                local function makeWidget(labelValue, infoValue)
                    local _, config = infoArgs(labelValue, infoValue)
                    config = config or {}
                    local default = config.Default or Color3.new(1, 1, 1)
                    local hue, sat, vib = rgbToHsv(default)
                    return {
                        type = "colorpicker",
                        id = config.Index or config.Idx or labelValue,
                        label = config.Text or config.Label or labelValue or "ColorPicker",
                        title = config.Title,
                        value = default,
                        hue = hue,
                        sat = sat,
                        vib = vib,
                        transparency = config.Transparency or 0,
                        transparencyEnabled = config.Transparency ~= nil,
                        callback = config.Callback,
                        changed = config.Changed,
                        tooltip = config.Tooltip,
                        disabled = config.Disabled == true,
                        visible = config.Visible ~= false,
                        popup = nil,
                    }
                end
                local leftWidget = makeWidget(leftLabel, leftInfo)
                local rightWidget = makeWidget(rightLabel, rightInfo)
                register({ type = "colorpair", left = leftWidget, right = rightWidget, visible = true })
                local function makeHandle(widget)
                    return Window:_widgetHandle(widget, {
                        Get = function()
                            return widget.value, widget.transparency
                        end,
                        SetHSVFromRGB = function(_, color)
                            widget.hue, widget.sat, widget.vib = rgbToHsv(color)
                        end,
                        SetValue = function(selfHandle, hsv, transparency)
                            if type(hsv) == "table" and hsv.R ~= nil then
                                return selfHandle:SetValueRGB(hsv, transparency)
                            end
                            local color = Color3.fromHSV(hsv[1] or 0, hsv[2] or 0, hsv[3] or 0)
                            widget.value = color
                            widget.transparency = widget.transparencyEnabled and (transparency or 0) or 0
                            widget.hue, widget.sat, widget.vib = rgbToHsv(color)
                            _fire(widget, widget.value, widget.transparency)
                        end,
                        SetValueRGB = function(_, color, transparency)
                            widget.value = color
                            widget.transparency = widget.transparencyEnabled and (transparency or 0) or 0
                            widget.hue, widget.sat, widget.vib = rgbToHsv(color)
                            _fire(widget, widget.value, widget.transparency)
                        end,
                    })
                end
                return makeHandle(leftWidget), makeHandle(rightWidget)
            end

            function Section:AddTextbox(label, default, callback, placeholder)
                local _, info = infoArgs(label, default)
                local id = info and (info.Index or info.Idx) or label
                local widget = register({
                    type = "textbox",
                    id = id,
                    label = info and (info.Text or info.Label) or label or "Textbox",
                    value = info and tostring(info.Default or "") or (default ~= nil and tostring(default) or ""),
                    _default = info and tostring(info.Default or "") or (default ~= nil and tostring(default) or ""),
                    callback = info and info.Callback or callback,
                    changed = info and info.Changed or nil,
                    tooltip = info and info.Tooltip,
                    placeholder = info and (info.Placeholder or "") or placeholder or "...",
                    numeric = info and info.Numeric == true,
                    finished = info and info.Finished == true,
                    clearTextOnFocus = info and info.ClearTextOnFocus ~= false,
                    disabled = info and info.Disabled == true,
                    visible = not (info and info.Visible == false),
                })
                return Window:_widgetHandle(widget)
            end

            Section.AddInput = Section.AddTextbox
            Section.AddKeyPicker = Section.AddKeybind
            Section.AddDivider = function(_, value)
                local info = type(value) == "table" and value or { Text = type(value) == "string" and value or nil }
                local margin = tonumber(info.Margin) or 0
                return Window:_widgetHandle(register({
                    type = "divider",
                    text = info.Text and tostring(info.Text) or nil,
                    marginTop = tonumber(info.MarginTop) or margin,
                    marginBottom = tonumber(info.MarginBottom) or margin,
                    visible = info.Visible ~= false,
                }))
            end
            local function dependencyBox()
                local box = { dependencies = {} }
                function box:SetupDependencies(dependencies)
                    self.dependencies = dependencies or {}
                    return self
                end
                return setmetatable(box, {
                    __index = function(_, key)
                        local method = Section[key]
                        if type(method) ~= "function" then return nil end
                        return function(_, ...)
                            local handle = method(Section, ...)
                            if handle and handle.Widget then
                                handle.Widget.dependencyBox = box
                            end
                            return handle
                        end
                    end,
                })
            end
            function Section:AddDependencyBox()
                return dependencyBox()
            end
            function Section:AddDependencyGroupbox()
                return dependencyBox()
            end
            return Section
        end

        Tab.AddGroupbox = Tab.AddSection
        function Tab:AddLeftGroupbox(name)
            return Tab:AddSection(name, "Left")
        end
        function Tab:AddRightGroupbox(name)
            return Tab:AddSection(name, "Right")
        end
        function Tab:AddLeftTabbox()
            local section = Tab:AddSection("__tabbox", "Left")
            return section:AddTabbox()
        end
        function Tab:AddRightTabbox()
            local section = Tab:AddSection("__tabbox", "Right")
            return section:AddTabbox()
        end

        function Tab:AddKeyBox(callback)
            local section = Tab.Sections[1] or Tab:AddSection("__keytab", "Left")
            local widget = {
                type = "keybox",
                value = "",
                placeholder = "Key",
                executeCallback = callback,
                visible = true,
            }
            section.widgets[#section.widgets + 1] = widget
            return Window:_widgetHandle(widget, {
                Get = function()
                    return widget.value
                end,
                Set = function(_, value)
                    widget.value = tostring(value or "")
                end,
                SetValue = function(selfHandle, value)
                    return selfHandle:Set(value)
                end,
            })
        end
        return Tab
    end

    function Window:SelectTab(nameOrTab)
        if type(nameOrTab) == "string" then
            for _, tab in ipairs(self.Tabs) do
                if tab.Name == nameOrTab then
                    tab:Select()
                    return
                end
            end
        elseif type(nameOrTab) == "table" then
            nameOrTab:Select()
        end
    end

    function Window:AddKeyTab(name, icon)
        local tab = self:AddTab(name or "Key System", icon or "key")
        tab.IsKeyTab = true
        local section = tab:AddSection("__keytab", "Left")
        function tab:AddLabel(text)
            local info = type(text) == "table" and text or nil
            local widget = {
                type = "label",
                text = info and (info.Text or info.Label) or tostring(text or ""),
                tooltip = info and info.Tooltip,
                visible = not (info and info.Visible == false),
            }
            section.widgets[#section.widgets + 1] = widget
            return Window:_widgetHandle(widget)
        end
        return tab
    end

    task.spawn(function()
        while Window.Running do
            local idleTime = tick() - Window._lastActivity
            task.wait(idleTime > 0.5 and 0.033 or 0.016)
            if isrbxactive() then
                Window:_updateInput()
                local ok, err = pcall(function()
                    Window:_render()
                end)
                if not ok then
                    if Window._lastRenderError ~= err then
                        warn("[GalaxObsidian] Render error: " .. tostring(err))
                        Window._lastRenderError = err
                    end
                else
                    Window._lastRenderError = nil
                end
                Window:_handleGlobalInput()
                Window:_updateInputBlock()
            else
                Window:_setAllVisible(false)
                Window:_updateInputBlock()
            end
        end
    end)
    DialogManager:SetLibrary(GalaxObsidian)
    NotificationManager:SetLibrary(GalaxObsidian)
    return Window
end

function GalaxObsidian:CreateLoading(options)
    options = options or {}
    local window = self.ActiveWindow
    assert(window, "CreateLoading requires an active window!")
    if self.ActiveLoading and not self.ActiveLoading.closed then return self.ActiveLoading end
    local loading = {
        title = tostring(options.Title or window.Title or "mspaint"),
        message = tostring(options.Message or "Loading..."),
        description = tostring(options.Description or "Please wait..."),
        currentStep = tonumber(options.CurrentStep) or 0,
        totalSteps = math.max(1, tonumber(options.TotalSteps) or 1),
        width = tonumber(options.WindowWidth or options.Width) or 450,
        height = tonumber(options.WindowHeight or options.Height) or 275,
        contentWidth = tonumber(options.ContentWidth) or 450,
        sidebarWidth = tonumber(options.SidebarWidth) or 250,
        centerOffsetY = tonumber(options.CenterOffsetY) or -30,
        showSidebar = options.ShowSidebar == true,
        loadingIcon = options.LoadingIcon,
        loadingIconColor = options.LoadingIconColor,
        loadingIconTweenTime = tonumber(options.LoadingIconTweenTime) or 1,
        sidebarItems = {},
        errorButtons = {},
        isError = false,
        closed = false,
        previousOpen = window.Open,
    }
    local sidebar = {}
    loading.Sidebar = sidebar
    local function addSidebarItem(kind, value, callback)
        local info = type(value) == "table" and value or { Text = value, Callback = callback }
        local item = { kind = kind, text = tostring(info.Text or info.Title or ""), callback = info.Callback or info.Func, visible = info.Visible ~= false }
        loading.sidebarItems[#loading.sidebarItems + 1] = item
        function item:SetText(text) self.text = tostring(text or "") end
        function item:SetVisible(state) self.visible = state == true end
        function item:Destroy() self.visible = false; self.destroyed = true end
        return item
    end
    function sidebar:AddLabel(value) return addSidebarItem("label", value) end
    function sidebar:AddValue(value) return addSidebarItem("value", value) end
    function sidebar:AddButton(value, callback) return addSidebarItem("button", value, callback) end
    function sidebar:AddDivider() return addSidebarItem("divider", "") end
    function loading:SetMessage(value) self.message = tostring(value or "") end
    function loading:SetDescription(value) self.description = tostring(value or "") end
    function loading:SetCurrentStep(value) self.currentStep = clamp(tonumber(value) or self.currentStep, 0, self.totalSteps) end
    function loading:SetTotalSteps(value) self.totalSteps = math.max(1, tonumber(value) or self.totalSteps) end
    function loading:SetWindowWidth(value) self.width = math.max(280, tonumber(value) or self.width) end
    function loading:SetWindowHeight(value) self.height = math.max(140, tonumber(value) or self.height) end
    function loading:SetContentWidth(value) self.contentWidth = math.max(280, tonumber(value) or self.contentWidth) end
    function loading:SetSidebarWidth(value) self.sidebarWidth = math.max(140, tonumber(value) or self.sidebarWidth) end
    function loading:SetCenterOffsetY(value)
        value = tonumber(value)
        assert(value, "Loading center offset must be a number!")
        self.centerOffsetY = value
    end
    function loading:SetLoadingIcon(value)
        self.loadingIcon = value and tostring(value) or nil
        self.loadingIconData = nil
        local resolved = imageUrl(value)
        if type(value) == "string" and value:match("^[%w%-]+$") and not value:match("^%d+$") then resolved = GalaxObsidian.LucideIconUrl .. value:lower() .. ".png" end
        if resolved then window:_requestImage(resolved, function(data) self.loadingIconData = data end) end
    end
    function loading:SetLoadingIconTweenTime(value) self.loadingIconTweenTime = math.max(0, tonumber(value) or self.loadingIconTweenTime) end
    function loading:SetLoadingIconColor(value) self.loadingIconColor = value end
    function loading:SetErrorMessage(value) self.errorMessage = tostring(value or "") end
    function loading:SetErrorButtons(buttons)
        assert(type(buttons) == "table", "Loading error buttons must be a table!")
        self.errorButtons = {}
        for id, info in pairs(buttons) do
            info = type(info) == "table" and info or { Title = tostring(info) }
            self.errorButtons[#self.errorButtons + 1] = {
                id = tostring(id), title = tostring(info.Title or info.Text or id),
                variant = info.Variant or "Secondary", callback = info.Callback or info.Func,
                order = tonumber(info.Order) or (#self.errorButtons + 1),
            }
        end
        table.sort(self.errorButtons, function(left, right) return left.order < right.order end)
    end
    function loading:ShowErrorPage(state) self.isError = state ~= false; if self.isError then self.showSidebar = false end end
    function loading:ShowSidebarPage(state) self.showSidebar = state ~= false; if self.showSidebar then self.isError = false end end
    function loading:Destroy()
        if self.closed then return nil end
        self.closed = true
        window.LoadingOverlay = nil
        GalaxObsidian.ActiveLoading = nil
        window:_setOpen(self.previousOpen ~= false)
    end
    loading.Continue = loading.Destroy
    window:_setOpen(false)
    window.LoadingOverlay = loading
    self.ActiveLoading = loading
    local titleIcon = imageUrl(options.Icon)
    if titleIcon then window:_requestImage(titleIcon, function(data) loading.iconData = data end) end
    local loadingIcon = imageUrl(options.LoadingIcon)
    if type(options.LoadingIcon) == "string" and options.LoadingIcon:match("^[%w%-]+$") and not options.LoadingIcon:match("^%d+$") then loadingIcon = GalaxObsidian.LucideIconUrl .. options.LoadingIcon:lower() .. ".png" end
    if loadingIcon then
        window:_requestImage(loadingIcon, function(data) loading.loadingIconData = data end)
    end
    return loading
end

function GalaxObsidian:Toggle(state)
    if not self.ActiveWindow then
        return nil
    end
    if state == nil then
        self.ActiveWindow:SetVisible(not self.ActiveWindow.Open)
    else
        self.ActiveWindow:SetVisible(state == true)
    end
end
function GalaxObsidian:Notify(message, title, duration)
    if not self.ActiveWindow then
        return nil
    end
    return self.ActiveWindow:Notify(message, title, duration)
end
_G.Galax = _G.Galax or {}
_G.Galax["Library.lua"] = GalaxObsidian

return GalaxObsidian

