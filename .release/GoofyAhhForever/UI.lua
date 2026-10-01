--------------------------------------------------------------------------------
-- Goofy Ahh Forever - UI.lua
-- One window: your ability/sound pairs, a button to add more, and a test click.
--------------------------------------------------------------------------------
local ADDON, ns = ...

local FONT = "Fonts\\FRIZQT__.TTF"
local BACKDROP = BackdropTemplateMixin and "BackdropTemplate" or nil
local ROW_HEIGHT = 34

local window, rows = nil, {}

local function TryCreate(frameType, name, parent, templates)
    for _, template in ipairs(templates) do
        local ok, frame = pcall(CreateFrame, frameType, name, parent, template)
        if ok and frame then return frame end
    end
    return nil
end

local function Button(parent, text, width, onClick)
    local b = TryCreate("Button", nil, parent, { "UIPanelButtonTemplate" })
        or CreateFrame("Button", nil, parent)
    b:SetSize(width or 80, 22)
    if b.SetText then b:SetText(text) end
    b:SetScript("OnClick", onClick)
    return b
end

local sliderCount = 0

local function Slider(parent, label, minV, maxV, step, get, set, suffix)
    sliderCount = sliderCount + 1
    local sl = TryCreate("Slider", "GoofyAhhForeverSlider" .. sliderCount, parent,
        { "OptionsSliderTemplate", "UISliderTemplateWithLabels" })
    if not sl then
        sl = CreateFrame("Slider", "GoofyAhhForeverSlider" .. sliderCount, parent)
        sl:SetOrientation("HORIZONTAL")
        sl:SetHeight(17)
        sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    end
    sl:SetWidth(180)
    sl:SetMinMaxValues(minV, maxV)
    sl:SetValueStep(step)
    if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end

    local name = sl:GetName()
    if name then
        if _G[name .. "Low"] then _G[name .. "Low"]:SetText("") end
        if _G[name .. "High"] then _G[name .. "High"]:SetText("") end
        if _G[name .. "Text"] then _G[name .. "Text"]:SetText("") end
    end

    sl.caption = sl:CreateFontString(nil, "ARTWORK")
    sl.caption:SetFont(FONT, 11, "")
    sl.caption:SetPoint("BOTTOMLEFT", sl, "TOPLEFT", 0, 2)
    sl.caption:SetTextColor(1, 1, 1)

    local function caption(value)
        sl.caption:SetText(("%s: %s%s"):format(label, value, suffix or ""))
    end

    sl:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        caption(value)
        set(value)
    end)
    sl.Refresh = function()
        local v = get()
        sl:SetValue(v)
        caption(v)
    end
    return sl
end

local function Label(parent, text, size, r, g, b)
    local fs = parent:CreateFontString(nil, "ARTWORK")
    fs:SetFont(FONT, size or 12, "")
    fs:SetText(text)
    fs:SetTextColor(r or 1, g or 1, b or 1)
    return fs
end

--------------------------------------------------------------------------------
-- Rows
--------------------------------------------------------------------------------
local function EntryFor(item)
    if item.kind == "trigger" then return ns.db.triggers[item.key] end
    if item.kind == "target" then return ns.db.targetAssignments[item.key] end
    return ns.db.assignments[item.key]
end

local function AcquireRow(index, parent)
    if rows[index] then return rows[index] end

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(410, ROW_HEIGHT)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(26, 26)
    row.icon:SetPoint("LEFT", 4, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.tag = Label(row, "", 9, 0.6, 0.6, 0.7)
    row.tag:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 4, -2)

    row.spell = Label(row, "", 12)
    row.spell:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 4, -2)
    row.spell:SetWidth(150)
    row.spell:SetJustifyH("LEFT")

    -- Clicking the sound name walks through the list: no dropdown needed
    row.sound = Button(row, "", 140, function(self)
        local list = ns:SoundList()
        if #list == 0 then
            ns:Print("No sounds installed yet. Drop files in the Sounds folder.")
            return
        end
        local entry, index = EntryFor(self.item), 0
        for i, sound in ipairs(list) do
            if entry and sound.file == entry.sound then index = i end
        end
        local nextSound = list[(index % #list) + 1]
        ns:SetSound(self.item, nextSound.file)
        ns:Play(nextSound.file)
    end)
    row.sound:SetPoint("LEFT", 200, 0)

    row.test = Button(row, "Test", 46, function(self)
        local entry = EntryFor(self.item)
        if entry and entry.sound and not ns:Play(entry.sound) then
            ns:Print("That file did not play. Is it a valid ogg or mp3?")
        end
    end)
    row.test:SetPoint("LEFT", 344, 0)

    row.remove = Button(row, "X", 24, function(self)
        ns:ToggleMute(self.item)
    end)
    row.remove:SetPoint("LEFT", 394, 0)

    rows[index] = row
    return row
end

local function BuildList()
    local list = {}

    for spellID, entry in pairs(ns.db.assignments) do
        list[#list + 1] = { kind = "spell", key = spellID, label = entry.spell, icon = entry.icon, order = 1 }
    end
    for spellID, entry in pairs(ns.db.targetAssignments) do
        list[#list + 1] = { kind = "target", key = spellID, label = entry.spell, icon = entry.icon, order = 2 }
    end
    for _, trigger in ipairs(ns.TRIGGERS) do
        if ns.db.triggers[trigger.key] then
            list[#list + 1] = { kind = "trigger", key = trigger.key, label = trigger.label,
                icon = "Interface\\Icons\\INV_Misc_Bell_01", order = 3 }
        end
    end

    table.sort(list, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        return (a.label or "") < (b.label or "")
    end)
    return list
end

local TAGS = { spell = "", target = "your target casts it", trigger = "when it happens" }

local function Refresh()
    if not window then return end

    local list = BuildList()
    for _, row in ipairs(rows) do row:Hide() end

    for index, item in ipairs(list) do
        local entry = EntryFor(item)
        local row = AcquireRow(index, window.content)
        row:SetPoint("TOPLEFT", window.content, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.spell:SetText(item.label or "?")
        row.tag:SetText(TAGS[item.kind] or "")
        row.sound.item, row.test.item, row.remove.item = item, item, item
        row.sound:SetText(entry and entry.sound and ns:SoundName(entry.sound) or "pick a sound")
        if entry and entry.muted then
            row.spell:SetTextColor(0.5, 0.5, 0.5)
            row.remove:SetText("off")
        else
            row.spell:SetTextColor(1, 1, 1)
            row.remove:SetText("X")
        end
        row:Show()
    end

    window.content:SetHeight(math.max(1, #list * ROW_HEIGHT))
    window.empty:SetShown(#list == 0)
    local usable, total = #ns:UsableSounds(), #ns:SoundList()
    if usable == total then
        window.sounds:SetText(("%d sound names, none ruled out yet"):format(total))
    else
        window.sounds:SetText(("%d of %d names have a file behind them"):format(usable, total))
    end
    window.enabled:SetText(ns.db.enabled and "Sounds: on" or "Sounds: off")
    window.auto:SetText(ns.db.autoAssign and "Auto assign: on" or "Auto assign: off")
    window.target:SetText(ns.db.targetCasts and "Target casts: on" or "Target casts: off")
    window.mode:SetText(ns.db.mode == "random" and "Mode: random" or "Mode: one each")
    -- In random mode the per-row sound is not what will play, so say so
    local random = ns.db.mode == "random"
    for _, row in ipairs(rows) do
        row.sound:SetAlpha(random and 0.4 or 1)
        row.sound:SetEnabled(not random)
    end
    window.chance.Refresh()
    window.gap.Refresh()
    window.globalGap.Refresh()
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------
local function Build()
    local f = CreateFrame("Frame", "GoofyAhhForeverWindow", UIParent, BACKDROP)
    window = f
    f:SetSize(470, 490)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    -- The dialog backdrop texture renders see-through on this client, so the
    -- window gets its own solid background underneath it
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 6, -6)
    bg:SetPoint("BOTTOMRIGHT", -6, 6)
    bg:SetColorTexture(0.04, 0.04, 0.05, 0.95)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end
    tinsert(UISpecialFrames, "GoofyAhhForeverWindow")

    local close = TryCreate("Button", nil, f, { "UIPanelCloseButton" })
    if close then close:SetPoint("TOPRIGHT", -6, -6) end

    local title = Label(f, "Goofy Ahh Forever", 16, 1, 0.82, 0)
    title:SetPoint("TOPLEFT", 20, -18)

    f.sounds = Label(f, "", 11, 0.7, 0.7, 0.7)
    f.sounds:SetPoint("TOPLEFT", 20, -40)

    -- Scrolled: the list grows every time you use a new ability
    local scroll = TryCreate("ScrollFrame", "GoofyAhhForeverScroll", f, { "UIPanelScrollFrameTemplate" })
        or CreateFrame("ScrollFrame", "GoofyAhhForeverScroll", f)
    scroll:SetPoint("TOPLEFT", 16, -64)
    scroll:SetPoint("BOTTOMRIGHT", -36, 172)

    f.content = CreateFrame("Frame", nil, scroll)
    f.content:SetSize(410, 1)
    scroll:SetScrollChild(f.content)

    f.empty = Label(f, "Nothing here yet.\n\nJust play: every ability you use picks up a sound\nby itself, and shows up here for you to change.", 12, 0.8, 0.8, 0.8)
    f.empty:SetPoint("TOPLEFT", scroll, "TOPLEFT", 10, -40)
    f.empty:SetJustifyH("LEFT")

    f.chance = Slider(f, "Chance", 5, 100, 5,
        function() return ns.db.chance end,
        function(v) ns.db.chance = v end, "%")
    f.chance:SetPoint("TOPLEFT", 26, -341)

    f.gap = Slider(f, "Gap per ability", 0, 10, 1,
        function() return ns.db.minGap end,
        function(v) ns.db.minGap = v end, "s")
    f.gap:SetPoint("TOPLEFT", 250, -341)

    f.globalGap = Slider(f, "Gap between any sounds", 0, 10, 1,
        function() return ns.db.globalGap end,
        function(v) ns.db.globalGap = v end, "s")
    f.globalGap:SetPoint("TOPLEFT", 26, -386)

    local enabled = Button(f, "", 110, function()
        ns.db.enabled = not ns.db.enabled
        Refresh()
    end)
    enabled:SetPoint("BOTTOMLEFT", 20, 48)
    f.enabled = enabled

    local auto = Button(f, "", 130, function()
        ns.db.autoAssign = not ns.db.autoAssign
        Refresh()
    end)
    auto:SetPoint("BOTTOMLEFT", 140, 48)
    f.auto = auto

    local mode = Button(f, "", 150, function()
        ns.db.mode = (ns.db.mode == "random") and "fixed" or "random"
        Refresh()
    end)
    mode:SetPoint("BOTTOMLEFT", 196, 20)
    f.mode = mode

    local target = Button(f, "", 150, function()
        ns.db.targetCasts = not ns.db.targetCasts
        Refresh()
    end)
    target:SetPoint("BOTTOMLEFT", 282, 48)
    f.target = target

    local reroll = Button(f, "Reroll all", 90, function()
        ns:RerollAll()
    end)
    reroll:SetPoint("BOTTOMLEFT", 20, 20)

    local clear = Button(f, "Clear", 70, function()
        ns:ForgetAll()
    end)
    clear:SetPoint("BOTTOMLEFT", 118, 20)

    f:SetScript("OnShow", Refresh)

    ns:On("ASSIGNMENTS_CHANGED", Refresh)
end

function ns:Toggle()
    if not window then Build() end
    if window:IsShown() then window:Hide() else window:Show() end
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Keybinds (the names below are what the game's key binding screen shows)
--------------------------------------------------------------------------------
BINDING_HEADER_GOOFYAHHFOREVER = "Goofy Ahh Forever"
BINDING_NAME_GOOFYAHHFOREVER_TOGGLE = "Turn the sounds on or off"
BINDING_NAME_GOOFYAHHFOREVER_WINDOW = "Open the window"

function GoofyAhhForever_ToggleSounds()
    ns.db.enabled = not ns.db.enabled
    ns:Print("Sounds " .. (ns.db.enabled and "on" or "off"))
    ns:Fire("ASSIGNMENTS_CHANGED")
end

function GoofyAhhForever_ToggleWindow()
    ns:Toggle()
end

SLASH_GOOFY1 = "/goofy"
SLASH_GOOFY2 = "/gaf"
SlashCmdList["GOOFY"] = function(input)
    input = (input or ""):trim():lower()
    if input == "" then
        ns:Toggle()
    elseif input == "on" or input == "off" then
        ns.db.enabled = (input == "on")
        ns:Print("Sounds " .. (ns.db.enabled and "on" or "off"))
    elseif input == "random" or input == "fixed" then
        ns.db.mode = input
        ns:Print(input == "random" and "A random sound every time." or "One sound per ability.")
    elseif input == "target" then
        ns.db.targetCasts = not ns.db.targetCasts
        ns:Print("Target casts: " .. (ns.db.targetCasts and "on" or "off"))
    elseif input == "minimap" then
        local shown = ns:ToggleMinimapButton()
        ns:Print("Minimap button " .. (shown and "shown" or "hidden"))
    elseif input:match("^chance") then
        local value = tonumber(input:match("(%d+)"))
        if value then
            ns.db.chance = math.max(5, math.min(100, value))
            ns:Print(("Chance: %d%%"):format(ns.db.chance))
        else
            ns:Print(("Chance is %d%%. Use /goofy chance 30"):format(ns.db.chance or 100))
        end
    elseif input == "reroll" then
        ns:RerollAll()
        ns:Print("Sounds shuffled again.")
    elseif input == "rescan" then
        ns:ForgetMissing()
        ns:Print("Forgot which files were missing. Added some? They will be picked up now.")
    elseif input == "list" then
        ns:Print("Sound names it looks for in the Sounds folder:")
        for _, entry in ipairs(ns:SoundList()) do
            ns:Print(("  %-18s %s%s"):format(entry.name, entry.file,
                ns.db.missing[entry.file] and "   (no file)" or ""))
        end
    else
        ns:Print("Commands: /goofy (window), on, off, chance <n>, random, fixed, target, rescan, minimap, reroll, list")
    end
end

ns:On("READY", function()
    Build()
    local count = 0
    for _ in pairs(ns.db.assignments) do count = count + 1 end
    ns:Print(("loaded, %d abilities set up. Type |cffffd100/goofy|r."):format(count))
end)


