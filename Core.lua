local AddonName, Addon = ...;

local VoicePackDisabled    = false; -- is saved
local VoiceDisableInCombat = false; -- is saved
local VoiceData = VoicePackData();
local VoiceCount = getn(VoiceData);
local DataPath = "Interface\\AddOns\\FFFVoicePack\\data\\";
local AudioFileSuffix = ".mp3";

DEBUG_MODE = false;

Addon.ActiveVoiceId = -1

function Addon.InitConfig()
end

function Addon:Log(message)
    if (not message) then
        message = "<nil>"
    end

    print("|cffff001eFFF VoicePack: " .. message)
end

function Addon:Load()

    tinsert(UISpecialFrames, "VoicePack_Main");

    SLASH_VPPLAY1 = "/vplay";
    SLASH_VPPLAY2 = "/vpplay";
    SlashCmdList["VPPLAY"] = function(arg1)
        local index = tonumber(arg1);
        if not Addon:IsValidIndex(index) then return end;

        local id = Addon:GetIdFromIndex(index);
        Addon:PlaySound(id);
    end;

    SLASH_VPPARTY1 = "/vp";
    SLASH_VPPARTY2 = "/voiceparty";
    SlashCmdList["VPPARTY"] = function(arg1)
        local index = tonumber(arg1);
        if not Addon:IsValidIndex(index) then return end;

        Addon.ActiveVoiceId = index;
        Addon:SendVoice("PARTY");
    end;

    SLASH_VPGUILD1 = "/vg";
    SLASH_VPGUILD2 = "/voiceguild";
    SlashCmdList["VPGUILD"] = function(arg1)
        local index = tonumber(arg1);
        if not Addon:IsValidIndex(index) then return end;

        Addon.ActiveVoiceId = index;
        Addon:SendVoice("GUILD");
    end;

    SLASH_VPRAID1 = "/vr";
    SLASH_VPRAID2 = "/voiceraid";
    SlashCmdList["VPRAID"] = function(arg1)
        local index = tonumber(arg1);
        if not Addon:IsValidIndex(index) then return end;

        Addon.ActiveVoiceId = index;
        Addon:SendVoice("RAID");
    end;

    SLASH_VPCOMBAT1 = "/vc";
    SLASH_VPCOMBAT2 = "/voicecombat";
    SlashCmdList["VPCOMBAT"] = function() Addon:SetCombatEnable(not VoicePackDisableInCombat) end;

    SLASH_VPYELL1 = "/vy";
    SLASH_VPYELL2 = "/voiceyell";
    SlashCmdList["VPYELL"] = function(arg1)
        local index = tonumber(arg1);
        if not Addon:IsValidIndex(index) then return end;

        Addon.ActiveVoiceId = index;
        Addon:SendVoice("YELL");
    end;

    SLASH_VPSAY1 = "/vs";
    SLASH_VPSAY2 = "/voicesay";
    SlashCmdList["VPSAY"] = function(arg1)
        local index = tonumber(arg1);
        if not Addon:IsValidIndex(index) then return end;

        Addon.ActiveVoiceId = index;
        Addon:SendVoice("SAY");
    end;

    SLASH_VPTOGGLE1 = "/voicepack";
    SLASH_VPTOGGLE2 = "/vpp";
    SlashCmdList["VPTOGGLE"] = function() Addon:Toggle() end;

    SLASH_VPHELP1 = "/vphelp";
    SLASH_VPHELP2 = "/vphelp";
    SlashCmdList["VPHELP"] = function() Addon:Help() end;

    Addon:Log("Loaded");

    self:UpdateButtons();
end

function Addon:SetEnabled(enabled)
    VoicePackDisabled = enabled;

    self:UpdateButtons();
    self:Update();

    local str = "enabled";

    if (VoicePackDisabled) then str = "disabled" end;

    self:Log("VoicePack is now " .. str);
end

function Addon:SetCombatEnable(enabled)
    VoicePackDisableInCombat = enabled;

    self:UpdateButtons();

    local str = "enabled";

    if (VoicePackDisableInCombat) then str = "disabled" end;

    self:Log("VoicePack is now " .. str .. " during combat");
end

function Addon:Help()
    self:Log("/vphelp, vhelp:\t Display help");
    self:Log("Use /vplay <ID> to play sound just for you (same as right-click in list)");
    self:Log("Use /vp <ID> or /voiceparty <ID> to play sound in PartyChat (same as Send Party button)");
    self:Log("Use /vg <ID> or /voiceguild <ID> to play sound in GuildChat (same as Send Guild button)");
    self:Log("Use /vr <ID> or /voiceraid <ID> to play sound in RaidChat (same as Send Raid button)");
    self:Log("Use /vy <ID> or /voiceyell <ID> to yell sound (same as Yell button)");
    self:Log("Use /vc or /voicecombat to disable or enable the voicepack during combat");
    self:Log("use /voicepack or /vpp to toggle window on/off");
end

function Addon:IDStringToId(idString)
    local isFFF = strfind(idString, "fff%d%d%d", 0);
    local id = 0;

    if (strlen(idString) <=6 ) then
        if (isFFF == 1) then
            if (strfind(idString, "fff00", 0)) then
                id = strsub(idString, 6, 6);

            elseif(strfind(idString, "fff0",0)) then
                id = strsub(idString, 5, 6);

            elseif(strfind(idString, "fff", 0)) then
                id = strsub(idString, 4, 6);

            else
                TMPrint("Invalid idString.")
            end
        else
            TMPrint("Parameter for id IDs should match fff<ID> with <ID> being an integer.");
            id = -1;
        end
    else
        TMPrint("Invalid VoiceID: " .. VoiceId);
        id = -1;
    end

    id = tonumber(id);
    return id;
end

function Addon:IsDisabled()
    return VoicePackDisabled or (VoiceDisableInCombat and UnitAffectingCombat("player") and GetNumGroupMembers() > 0);
end

function Addon:PlaySound(voice)
    if (not self:IsDisabled()) then
        success = PlaySoundFile(DataPath .. voice .. AudioFileSuffix);
        if (not success) then
            self:Log("Could not play sound file.");
        end
    else
        self:Log("Play of " .. voice .. " Failed, is Disabled")
    end
end

function Addon:GetIdFromIndex(index)
    -- TMPrint(index);

    if (index < 10) then
        return "fff00" .. index;
    elseif(index < 100) then
        return "fff0" .. index;
    else
        return "fff" .. index;
    end
end

function Addon:IsValidIndex(index)
    return index ~= nil and index >= 0 and index <= VoiceCount;
end

function Addon:SendVoice(channel)
    local id = self.ActiveVoiceId;

    if self:IsValidIndex(id) then
        if DEBUG_MODE then
            self:Log("Sending Voice: " .. id)
        end

        if( id <= VoiceCount) then
            SendChatMessage("#" .. self:GetIdFromIndex(id) .. ": " .. VoiceData[id], channel);
        else
            self:Log("Invalid VoiceID: " .. id);
        end
    else
        self.ActiveVoiceId = -1;
    end
end