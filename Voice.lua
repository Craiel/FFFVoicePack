local addonName, ns = ...
-- luacheck: globals FFFVoicePackDB

local GetTime, PlaySoundFile, issecretvalue = GetTime, PlaySoundFile, issecretvalue
local IsInGroup, IsInRaid, IsInGuild = IsInGroup, IsInRaid, IsInGuild
local format, tonumber = string.format, tonumber

-- Chat format other players' copies listen for: "#fff001: <text>". Keep it stable.
local CHAT_PATTERN = "^#fff(%d%d%d)"
local SOUND_PATH = "Interface\\AddOns\\" .. addonName .. "\\sounds\\%s.mp3"
local PLAY_DELAY = 2
local SEND_DELAY = 2
local CHAT_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_GUILD",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
}
local CHANNEL_OPEN = {
    PARTY = function() return IsInGroup() end,
    RAID = function() return IsInRaid() end,
    GUILD = IsInGuild,
}

local Voice = {}
ns.Voice = Voice

local lastPlay, lastSend = 0, 0

function Voice.Code(id)
    return format("fff%03d", id)
end

function Voice.IsEnabled()
    return FFFVoicePackDB.enabled
end

function Voice.SetEnabled(enabled)
    FFFVoicePackDB.enabled = enabled
end

function Voice.Play(id)
    if not ns.Lines[id] or not FFFVoicePackDB.enabled then
        return
    end
    local now = GetTime()
    if now - lastPlay < PLAY_DELAY then
        return
    end
    lastPlay = now
    PlaySoundFile(format(SOUND_PATH, Voice.Code(id)))
end

function Voice.CanSend(channel)
    return FFFVoicePackDB.enabled and CHANNEL_OPEN[channel]() and not C_ChatInfo.InChatMessagingLockdown()
end

-- The sender hears the line too: the game echoes the message back as a chat event.
function Voice.Send(id, channel)
    local text = ns.Lines[id]
    if not text or not Voice.CanSend(channel) then
        return
    end
    local now = GetTime()
    if now - lastSend < SEND_DELAY then
        return
    end
    lastSend = now
    C_ChatInfo.SendChatMessage("#" .. Voice.Code(id) .. ": " .. text, channel)
end

local function OnChatMessage(_, _, message)
    -- Chat text can be secret during encounters; it cannot be read then.
    if issecretvalue(message) then
        return
    end
    local id = message:match(CHAT_PATTERN)
    if id then
        Voice.Play(tonumber(id))
    end
end

local function OnLoaded()
    -- Data saved by the Ace3 versions of the addon has no "enabled" field and is dropped.
    if type(FFFVoicePackDB) ~= "table" or FFFVoicePackDB.enabled == nil then
        FFFVoicePackDB = { enabled = true }
    end
    local listener = CreateFrame("Frame")
    for _, event in ipairs(CHAT_EVENTS) do
        listener:RegisterEvent(event)
    end
    listener:SetScript("OnEvent", OnChatMessage)
end

EventUtil.ContinueOnAddOnLoaded(addonName, OnLoaded)
