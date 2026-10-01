--------------------------------------------------------------------------------
-- Goofy Ahh Forever - Minimap.lua
-- A button on the minimap edge, draggable around it. Written by hand rather
-- than pulling in a library for sixty lines of trigonometry.
--------------------------------------------------------------------------------
local ADDON, ns = ...

local button

local function Reposition()
    if not button then return end
    local angle = math.rad(ns.db.minimap.angle or 200)
    local radius = (Minimap:GetWidth() / 2) + 5
    button:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * radius, math.sin(angle) * radius)
end

local function OnDragUpdate(self)
    local centerX, centerY = Minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cursorX, cursorY = cursorX / scale, cursorY / scale
    ns.db.minimap.angle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
    Reposition()
end

local function Build()
    local b = CreateFrame("Button", "GoofyAhhForeverMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("AnyUp")
    b:RegisterForDrag("LeftButton")
    b:SetMovable(true)

    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", -1, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Horn_01")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.icon = icon

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    b:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", OnDragUpdate) end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    b:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            ns.db.enabled = not ns.db.enabled
            ns:Print("Sounds " .. (ns.db.enabled and "on" or "off"))
            ns:Fire("ASSIGNMENTS_CHANGED")
            self:UpdateLook()
        else
            ns:Toggle()
        end
    end)

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Goofy Ahh Forever", 1, 1, 1)
        GameTooltip:AddLine(ns.db.enabled and "Sounds are on" or "Sounds are off",
            ns.db.enabled and 0.4 or 1, ns.db.enabled and 1 or 0.4, 0.4)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left click: open the window", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right click: turn the sounds on or off", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag: move it around the minimap", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Greyed out while the sounds are off, so a glance tells you
    function b:UpdateLook()
        self.icon:SetDesaturated(not ns.db.enabled)
        self.icon:SetAlpha(ns.db.enabled and 1 or 0.5)
    end

    button = b
    Reposition()
    b:UpdateLook()
    b:SetShown(not ns.db.minimap.hide)
    return b
end

function ns:ToggleMinimapButton()
    self.db.minimap.hide = not self.db.minimap.hide
    if button then button:SetShown(not self.db.minimap.hide) end
    return not self.db.minimap.hide
end

ns:On("READY", function()
    Build()
end)

ns:On("ASSIGNMENTS_CHANGED", function()
    if button then button:UpdateLook() end
end)
