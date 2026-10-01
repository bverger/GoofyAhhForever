--------------------------------------------------------------------------------
-- Goofy Ahh Forever - Core.lua
-- Watches what you cast and plays the sound you attached to it.
--------------------------------------------------------------------------------
local ADDON, ns = ...

ns.version = "0.1.0"

local SOUND_PATH = "Interface\\AddOns\\GoofyAhhForever\\Sounds\\"

local defaults = {
    enabled = true,
    autoAssign = true,       -- a new ability gets a sound on its own
    mode = "fixed",          -- "fixed": one sound per ability. "random": a new one every time
    channel = "Master",      -- Master ignores the in-game sliders
    chance = 100,            -- percent of casts that actually make a noise
    minGap = 0.5,            -- seconds between two plays of the same spell
    globalGap = 0,           -- seconds between any two sounds
    assignments = {},        -- [spellID] = { spell, icon, sound, muted }
    targetAssignments = {},  -- the same, for what your target casts
    triggers = {},           -- [key] = { sound, muted }
    targetCasts = false,     -- off by default: it is a lot of noise
    bag = {},                -- shuffled sounds left to hand out
    missing = {},            -- files the game could not play, learned as we go
    minimap = { angle = 200, hide = false },
}

local lastPlayed = {}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
function ns:Print(...)
    print("|cffffd200Goofy Ahh Forever|r: " .. strjoin(" ", tostringall(...)))
end

local function CopyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            CopyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

-- This client answers some queries with values that cannot be inspected
function ns.AnySecret(...)
    if _G.hasanysecretvalues then
        local ok, secret = pcall(hasanysecretvalues, ...)
        return ok and secret
    end
    if not _G.issecretvalue then return false end
    for i = 1, select("#", ...) do
        if issecretvalue((select(i, ...))) then return true end
    end
    return false
end

function ns.SpellInfo(id)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(id)
        if info then return info.name, info.iconID or info.originalIconID end
    elseif _G.GetSpellInfo then
        local name, _, icon = _G.GetSpellInfo(id)
        return name, icon
    end
end

--------------------------------------------------------------------------------
-- Sounds
--------------------------------------------------------------------------------
function ns:SoundList()
    return ns.SOUNDS or {}
end

-- Names we have not already proven to be missing
function ns:UsableSounds()
    local list = {}
    for _, entry in ipairs(self:SoundList()) do
        if not self.db.missing[entry.file] then list[#list + 1] = entry end
    end
    return list
end

function ns:ForgetMissing()
    self.db.missing = {}
    self.db.bag = {}
    self:Fire("ASSIGNMENTS_CHANGED")
end

function ns:SoundName(file)
    for _, entry in ipairs(self:SoundList()) do
        if entry.file == file then return entry.name end
    end
    return file
end

-- PlaySoundFile reports whether the file could be played at all, so a name
-- with no file behind it is noticed once and then skipped forever. That is what
-- lets the addon ship with a list of names and no audio.
function ns:Play(file)
    if not file then return false end
    local ok, played = pcall(PlaySoundFile, SOUND_PATH .. file, self.db.channel)
    local worked = ok and played ~= false
    if not worked then
        self.db.missing[file] = true
    elseif self.db.missing[file] then
        self.db.missing[file] = nil
    end
    return worked
end

--------------------------------------------------------------------------------
-- Handing out sounds
--
-- Drawn from a shuffled bag rather than at random: with five sounds and random
-- picks you get the same one three times in a row and it feels broken.
--------------------------------------------------------------------------------
function ns:DrawSound()
    local list = self:SoundList()
    if #list == 0 then return nil end

    if #self.db.bag == 0 then
        local pool = {}
        for _, entry in ipairs(list) do
            if not self.db.missing[entry.file] then pool[#pool + 1] = entry.file end
        end
        if #pool == 0 then return nil end
        for i = #pool, 2, -1 do
            local j = math.random(i)
            pool[i], pool[j] = pool[j], pool[i]
        end
        self.db.bag = pool
    end

    return table.remove(self.db.bag)
end

function ns:RerollAll()
    self.db.bag = {}
    for _, group in ipairs({ self.db.assignments, self.db.targetAssignments, self.db.triggers }) do
        for _, entry in pairs(group) do
            if not entry.muted then entry.sound = self:DrawSound() end
        end
    end
    self:Fire("ASSIGNMENTS_CHANGED")
end

-- What should actually play for an entry, honouring the mode
function ns:SoundToPlay(entry)
    if self.db.mode == "random" then return self:DrawSound() end
    return entry and entry.sound
end

--------------------------------------------------------------------------------
-- Assignments
--------------------------------------------------------------------------------
function ns:Assign(spellID, file)
    if not spellID then return end
    local name, icon = self.SpellInfo(spellID)
    self.db.assignments[spellID] = {
        spell = name or ("Spell " .. spellID),
        icon = icon,
        sound = file,
    }
    self:Fire("ASSIGNMENTS_CHANGED")
end

-- One place to write a sound, whichever of the three lists the row came from
function ns:SetSound(item, file)
    local group = (item.kind == "trigger" and self.db.triggers)
        or (item.kind == "target" and self.db.targetAssignments)
        or self.db.assignments
    group[item.key] = group[item.key] or {}
    group[item.key].sound = file
    self:Fire("ASSIGNMENTS_CHANGED")
end

-- Muting rather than deleting: with auto assign on, a deleted entry would just
-- come back with a new sound the next time you use the ability.
function ns:ToggleMute(item)
    local group = (item.kind == "trigger" and self.db.triggers)
        or (item.kind == "target" and self.db.targetAssignments)
        or self.db.assignments
    local entry = group[item.key]
    if not entry then return end
    entry.muted = not entry.muted
    self:Fire("ASSIGNMENTS_CHANGED")
end

function ns:Forget(spellID)
    self.db.assignments[spellID] = nil
    self:Fire("ASSIGNMENTS_CHANGED")
end

function ns:ForgetAll()
    self.db.assignments = {}
    self.db.targetAssignments = {}
    self.db.triggers = {}
    self.db.bag = {}
    self:Fire("ASSIGNMENTS_CHANGED")
end

--------------------------------------------------------------------------------
-- Tiny callback registry, same idea as the totem addon
--------------------------------------------------------------------------------
local callbacks = {}
function ns:On(event, fn)
    callbacks[event] = callbacks[event] or {}
    table.insert(callbacks[event], fn)
end
function ns:Fire(event, ...)
    for _, fn in ipairs(callbacks[event] or {}) do fn(...) end
end

--------------------------------------------------------------------------------
-- Capture mode: press add, then use the ability
--------------------------------------------------------------------------------
function ns:StartCapture(seconds)
    self.capturing = GetTime() + (seconds or 15)
    self:Fire("CAPTURE_CHANGED", true)
    self:Print("Use the ability now. Listening for " .. (seconds or 15) .. " seconds.")
end

function ns:StopCapture()
    self.capturing = nil
    self:Fire("CAPTURE_CHANGED", false)
end

function ns:IsCapturing()
    if not self.capturing then return false end
    if GetTime() > self.capturing then
        self:StopCapture()
        return false
    end
    return true
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= ADDON then return end
        GoofyAhhForeverDB = CopyDefaults(GoofyAhhForeverDB or {}, defaults)
        ns.db = GoofyAhhForeverDB
        self:UnregisterEvent("ADDON_LOADED")
        self:RegisterEvent("PLAYER_LOGIN")
        self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    elseif event == "PLAYER_LOGIN" then
        ns:EnableEvents()
        ns:Fire("READY")

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit ~= "player" or not spellID then return end

        if ns:IsCapturing() then
            ns:StopCapture()
            ns:Assign(spellID, nil)
            local spellName = ns.SpellInfo(spellID)
            ns:Print(("Captured %s. Now pick a sound for it."):format(spellName or spellID))
            return
        end

        if not ns.db.enabled then return end

        local entry = ns.db.assignments[spellID]
        if not entry and ns.db.autoAssign then
            -- First time you use it: give it a sound and let it rip
            local file = ns:DrawSound()
            if file then
                ns:Assign(spellID, file)
                entry = ns.db.assignments[spellID]
            end
        end
        if not entry or entry.muted or not entry.sound then return end

        local now = GetTime()
        if (now - (lastPlayed[spellID] or 0)) < (ns.db.minGap or 0) then return end
        if (now - (ns.lastAnySound or 0)) < (ns.db.globalGap or 0) then return end

        -- Rolled after the gaps so a skipped roll does not burn the cooldown:
        -- at 30% you want roughly one in three casts, not one in three windows
        local chance = ns.db.chance or 100
        if chance < 100 and math.random(100) > chance then return end

        lastPlayed[spellID] = now
        ns.lastAnySound = now
        ns:Play(ns:SoundToPlay(entry))
    end
end)
