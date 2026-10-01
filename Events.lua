--------------------------------------------------------------------------------
-- Goofy Ahh Forever - Events.lua
-- Sounds for things that happen to you, and for what your target casts.
--------------------------------------------------------------------------------
local ADDON, ns = ...

ns.TRIGGERS = {
    { key = "death",    label = "You die" },
    { key = "lowhp",    label = "Health drops below 25%" },
    { key = "levelup",  label = "You level up" },
    { key = "epicloot", label = "You loot something epic" },
    { key = "whisper",  label = "A whisper arrives" },
    { key = "combat",   label = "Combat starts" },
}

local lowHealthArmed = true

--------------------------------------------------------------------------------
-- Firing a trigger
--------------------------------------------------------------------------------
function ns:FireTrigger(key)
    if not self.db.enabled then return end

    local entry = self.db.triggers[key]
    if not entry and self.db.autoAssign then
        local file = self:DrawSound()
        if file then
            self.db.triggers[key] = { sound = file }
            entry = self.db.triggers[key]
            self:Fire("ASSIGNMENTS_CHANGED")
        end
    end
    if not entry or entry.muted or not entry.sound then return end

    -- Triggers skip the chance roll: they fire rarely enough as it is, and a
    -- silent death is just confusing
    local now = GetTime()
    if (now - (self.lastAnySound or 0)) < (self.db.globalGap or 0) then return end
    self.lastAnySound = now
    self:Play(self:SoundToPlay(entry))
end

--------------------------------------------------------------------------------
-- What your target casts
--------------------------------------------------------------------------------
function ns:TargetCast(spellID)
    if not (self.db.enabled and self.db.targetCasts) then return end
    if not spellID then return end

    local entry = self.db.targetAssignments[spellID]
    if not entry and self.db.autoAssign then
        local file = self:DrawSound()
        if not file then return end
        local name, icon = self.SpellInfo(spellID)
        self.db.targetAssignments[spellID] = {
            spell = name or ("Spell " .. spellID), icon = icon, sound = file,
        }
        entry = self.db.targetAssignments[spellID]
        self:Fire("ASSIGNMENTS_CHANGED")
    end
    if not entry or entry.muted or not entry.sound then return end

    local now = GetTime()
    if (now - (self.lastAnySound or 0)) < (self.db.globalGap or 0) then return end
    local chance = self.db.chance or 100
    if chance < 100 and math.random(100) > chance then return end
    self.lastAnySound = now
    self:Play(self:SoundToPlay(entry))
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_DEAD" then
        ns:FireTrigger("death")

    elseif event == "PLAYER_LEVEL_UP" then
        ns:FireTrigger("levelup")

    elseif event == "PLAYER_REGEN_DISABLED" then
        ns:FireTrigger("combat")

    elseif event == "CHAT_MSG_WHISPER" then
        ns:FireTrigger("whisper")

    elseif event == "CHAT_MSG_LOOT" then
        local message = ...
        -- Epic items carry the purple colour code in the link
        if type(message) == "string" and message:find("|cffa335ee", 1, true) then
            ns:FireTrigger("epicloot")
        end

    elseif event == "UNIT_HEALTH" then
        local unit = ...
        if unit ~= "player" then return end
        local ok, current = pcall(UnitHealth, "player")
        local ok2, maximum = pcall(UnitHealthMax, "player")
        if not (ok and ok2) or ns.AnySecret(current, maximum) then return end
        if not maximum or maximum <= 0 then return end

        local fraction = current / maximum
        -- Re-arm only once you are comfortably back up, or it fires on every tick
        if fraction < 0.25 and lowHealthArmed then
            lowHealthArmed = false
            ns:FireTrigger("lowhp")
        elseif fraction > 0.35 then
            lowHealthArmed = true
        end

    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "target" then ns:TargetCast(spellID) end
    end
end)

function ns:EnableEvents()
    for _, event in ipairs({
        "PLAYER_DEAD", "PLAYER_LEVEL_UP", "PLAYER_REGEN_DISABLED",
        "CHAT_MSG_WHISPER", "CHAT_MSG_LOOT", "UNIT_HEALTH",
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED",
    }) do
        pcall(frame.RegisterEvent, frame, event)
    end
end
