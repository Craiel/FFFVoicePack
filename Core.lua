--[[
  FFFVoicePack
]]

---------------------------------------------------------
-- Addon declaration
FFFVoicePack = LibStub("AceAddon-3.0"):NewAddon("FFFVoicePack", "AceConsole-3.0", "AceEvent-3.0")
local FFFVoicePack = FFFVoicePack
local L = LibStub("AceLocale-3.0"):GetLocale("FFFVoicePack", false)
local FFFLDB = LibStub("LibDataBroker-1.1"):NewDataObject("FFFVoicePack", {
    type = "data source",
    text = "FFFVoicePack",
    icon = "Interface\\AddOns\\FFFVoicePack\\Images\\icon",
    OnClick = function() FFFVoicePack:ToggleWindow() end,
})

local k_DataPath = "Interface\\AddOns\\FFFVoicePack\\sounds\\";
local k_AudioFileSuffix = ".mp3";
local k_LastSoundPlayTime = 0;
local k_ForcedSoundDelay = 2;
local k_LastChatSendTime = 0;
local k_ForcedChatDelay = 2;

local options = {
    name = "FFFVoicePack",
    handler = FFFVoicePack,
    type = 'group',
    args = {
        enable = {
          name = "Enable",
          desc = "Enables / disables the addon",
          type = "toggle",
          set = function(info,val) FFFVoicePack.enabled = val end,
          get = function(info) return FFFVoicePack.enabled end
        },
        show = {
            name = "Show",
            desc = "Show the Window",
            type = "execute",
            func = function() FFFVoicePack:ShowFrame() end
        },
        close = {
            name = "Close",
            desc = "Close the Window",
            type = "execute",
            func = function() FFFVoicePack:CloseFrame() end
        },
        play = {
            name = "Play",
            desc = "Play the sound file",
            type = "input",
            set = function(info, val) FFFVoicePack:PlaySound(tonumber(val)) end
        },
        guild = {
            name = "Guild",
            desc = "Send the sound clip to guild channel",
            type = "input",
            set = function(info, val) FFFVoicePack:SendToGuild(tonumber(val)) end
        },
        party = {
            name = "Party",
            desc = "Send the sound clip to party channel",
            type = "input",
            set = function(info, val) FFFVoicePack:SendToParty(tonumber(val)) end
        },
        raid = {
            name = "Raid",
            desc = "Send the sound clip to raid channel",
            type = "input",
            set = function(info, val) FFFVoicePack:SendToRaid(tonumber(val)) end
        }
    },
}

---------------------------------------------------------
-- Std Methods
function FFFVoicePack:OnInitialize()
    FFFVoicePack:Print(L["Initializing..."])
    FFFVoicePack:RegisterChatCommand("vp", "SlashVPPFunc")
    LibStub("AceConfig-3.0"):RegisterOptionsTable("FFFVoicePack", options, {"vp"})

    -- Load data and build grouping
    FFFVoicePack.Data = FFFVoicePack:LoadData()
    FFFVoicePack.DataCount = 0
    FFFVoicePack.DataGroups = {}
    for id, text in pairs(FFFVoicePack.Data) do
        FFFVoicePack.DataCount = FFFVoicePack.DataCount + 1
        local entryGroup = string.sub(string.upper(text), 1, 1)
        local entryGroupVal = string.byte(entryGroup)
        if entryGroupVal < 65 or entryGroupVal > 90 then
            entryGroup = '#'
        end

        if FFFVoicePack.DataGroups[entryGroup] == nil then
            FFFVoicePack.DataGroups[entryGroup] = {}
        end

        FFFVoicePack.DataGroups[entryGroup][id] = text
    end

    FFFVoicePack:Print(FFFVoicePack.DataCount.. L[" Lines Loaded"])

    FFFVoicePack.Icon = FFFVoicePack:SetupDBIcon()
    FFFVoicePack:RegisterEvents()

    FFFVoicePack:Print(L["Done!"])
end

function FFFVoicePack:OnEnable()
    -- Called when the addon is enabled
end

function FFFVoicePack:OnDisable()
    -- Called when the addon is disabled
end

---------------------------------------------------------
-- Setup Methods
function FFFVoicePack:SetupDBIcon()
    local icon = LibStub("LibDBIcon-1.0")
    icon:Register("FFFLDB", FFFLDB, savedVarTable)
    icon:Show("FFFLDB")
    return icon
end

function FFFVoicePack:RegisterEvents()
    local AceEvent = LibStub("AceEvent-3.0")
    AceEvent:RegisterEvent("CHAT_MSG_SAY", function(evt, msg) FFFVoicePack:HandleChatMsg(evt, msg) end);
    AceEvent:RegisterEvent("CHAT_MSG_PARTY", function(evt, msg) FFFVoicePack:HandleChatMsg(evt, msg) end);
    AceEvent:RegisterEvent("CHAT_MSG_PARTY_LEADER", function(evt, msg) FFFVoicePack:HandleChatMsg(evt, msg) end);
    AceEvent:RegisterEvent("CHAT_MSG_GUILD", function(evt, msg) FFFVoicePack:HandleChatMsg(evt, msg) end);
    AceEvent:RegisterEvent("CHAT_MSG_YELL", function(evt, msg) FFFVoicePack:HandleChatMsg(evt, msg) end);
    AceEvent:RegisterEvent("CHAT_MSG_RAID", function(evt, msg) FFFVoicePack:HandleChatMsg(evt, msg) end);
    AceEvent:RegisterEvent("CHAT_MSG_RAID_LEADER", function(evt, msg) FFFVoicePack:HandleChatMsg(evt, msg) end);
end
---------------------------------------------------------
-- Slash Commands
function FFFVoicePack:SlashVPPFunc(input)
    FFFVoicePack:ToggleWindow(true)
end

---------------------------------------------------------
-- Sound handling
function FFFVoicePack:PlaySound(id)
    if id == nil or FFFVoicePack:CanPlaySound() == false then
        return
    end

    local file = k_DataPath .. FFFVoicePack:GetVoiceString(id) .. k_AudioFileSuffix;
    success = PlaySoundFile(file);
    k_LastSoundPlayTime = GetTime()
end

function FFFVoicePack:CanPlaySound()
    if FFFVoicePack.enabled == false then
        return false
    end

    local currentTime = GetTime()
    local timePassed = currentTime - k_LastSoundPlayTime
    return timePassed >= k_ForcedSoundDelay
end

---------------------------------------------------------
-- Chat handling
function FFFVoicePack:HandleChatMsg(evt, msg)
    if (string.sub(msg, 1, 4) == "#fff") then
        local id = string.sub(msg, 5, 7);
        while string.sub(id, 1, 1) == '0' do
            id = string.sub(id, 2, string.len(id))
        end

        FFFVoicePack:PlaySound(tonumber(id));
    end
end

function FFFVoicePack:SendToGuild(id)
    FFFVoicePack:SendToChannel(id, "GUILD")
end

function FFFVoicePack:SendToParty(id)
    FFFVoicePack:SendToChannel(id, "PARTY")
end

function FFFVoicePack:SendToRaid(id)
    FFFVoicePack:SendToChannel(id, "RAID")
end

function FFFVoicePack:SendToChannel(id, channel)
    if id == nil or FFFVoicePack:CanSendTochat() == false then
        return
    end

    local voiceText = FFFVoicePack.Data[id]
    if voiceText == nil then
        return
    end

    SendChatMessage("#" .. FFFVoicePack:GetVoiceString(id) .. ": " .. voiceText, channel);
    k_LastChatSendTime = GetTime()
end

function FFFVoicePack:CanSendTochat()
    if FFFVoicePack.enabled == false then
        return false
    end

    local currentTime = GetTime()
    local timePassed = currentTime - k_LastChatSendTime
    return timePassed >= k_ForcedChatDelay
end

---------------------------------------------------------
-- Utilities
function FFFVoicePack:GetVoiceString(id)
    if id < 10 then
        return 'fff00'..id
    end

    if id < 100 then
        return 'fff0'..id
    end

    return 'fff'..id
end