local AddonName, Addon = ...;

Addon.__Events__ = {}
Addon.Events  = {}

Addon.EventFrame = CreateFrame("frame")

VoicePackLocked = false;
ActiveTab = 1
ActiveVoiceId = -1
VoicePackDisabled    = false; -- is saved
VoiceDisableInCombat = false; -- is saved
VoicePackFirstUpdate = 1;
VoiceText = {};
VoiceIDs  = {};

VOICE_PACK_LIST_ENTRY_HEIGHT = 16;
VOICES_TO_DISPLAY = 18;
DEBUG_MODE = false;

function Addon.InitConfig()
end

function Addon:Log(message)
    if (not message) then
        message = "<nil>"
    end

    print("|cffff001eFFF VoicePack: " .. message)
end

function Addon:RegisterEvent(Event, Handler)
    Addon:Log("RegisterEvent: " .. Event)
    self.EventFrame:RegisterEvent(Event)
    self.__Events__[Event] = Handler
end

function Addon:UnregisterEvent(Event)
    self.EventFrame:UnregisterEvent(Event)
    self.__Events__[Event] = nil
end

function Addon:RegisterEventTable(EventTable)
    for i,v in pairs(EventTable) do
        self:RegisterEvent(i, v)
    end
end

function Addon:UnregisterEventTable(EventTable)
    for i,v in pairs(EventTable) do
        self:UnregisterEvent(i, v)
    end
end

function HandleChatMessageSound(msg)
    if (string.sub(msg, 1, 4) == "#fff") then
        id = string.sub(msg, 2, 7);
        Addon:PlaySound(id);
    end
end

function Addon.__Events__:CHAT_MSG_PARTY(msg)
    HandleChatMessageSound(msg);
end

function Addon.__Events__:CHAT_MSG_PARTY_LEADER(msg)
    HandleChatMessageSound(msg);
end

function Addon.__Events__:CHAT_MSG_GUILD(msg)
    HandleChatMessageSound(msg);
end

function Addon.__Events__:CHAT_MSG_YELL(msg)
    HandleChatMessageSound(msg);
end

function Addon.__Events__:CHAT_MSG_RAID(msg)
    HandleChatMessageSound(msg);
end

function Addon.__Events__:CHAT_MSG_RAID_LEADER(msg)
    HandleChatMessageSound(msg);
end

function Addon.__Events__:CHAT_MSG_SAY(msg)
    HandleChatMessageSound(msg);
end

function Addon.__Events__:GROUP_ROSTER_UPDATE()
    Addon:UpdateButtons();
end

function Addon.__Events__:PLAYER_GUILD_UPDATE()
    Addon:UpdateButtons();
end

Addon:RegisterEventTable(Addon.__Events__);
Addon.EventFrame:SetScript("OnEvent", function(self, event, ...)
    if DEBUG_MODE then
        Addon:Log("EVT ".. event);
    end

    Addon.__Events__[event](self, ...);
end)


function Addon:Load()

    tinsert(UISpecialFrames, "VoicePack_Main");

    SLASH_VPPLAY1 = "/vplay";
    SLASH_VPPLAY2 = "/vpplay";
    SlashCmdList["VPPLAY"] = function(arg1) Addon:PlaySound(arg1) end;

    SLASH_VPPARTY1 = "/vp";
    SLASH_VPPARTY2 = "/voiceparty";
    SlashCmdList["VPPARTY"] = function(arg1) Addon:SendVoice(arg1, "PARTY") end;

    SLASH_VPGUILD1 = "/vg";
    SLASH_VPGUILD2 = "/voiceguild";
    SlashCmdList["VPGUILD"] = function(arg1) Addon:SendVoice(arg1, "GUILD") end;

    SLASH_VPRAID1 = "/vr";
    SLASH_VPRAID2 = "/voiceraid";
    SlashCmdList["VPRAID"] = function(arg1) Addon:SendVoice(arg1, "RAID") end;

    SLASH_VPCOMBAT1 = "/vc";
    SLASH_VPCOMBAT2 = "/voicecombat";
    SlashCmdList["VPCOMBAT"] = function(arg1) Addon:SetCombatEnable(not VoicePackDisableInCombat) end;

    SLASH_VPRAID1 = "/vy";
    SLASH_VPRAID2 = "/voicecombat";
    SlashCmdList["VPRAID"] = function(arg1) Addon:SendVoice(arg1, "YELL") end;

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
    self:Log("Use /vplay fff<ID> to play sound just for you (same as right-click in list)");
    self:Log("Use /vp fff<ID> or /voiceparty fff<ID> to play sound in PartyChat (same as Send Party button)");
    self:Log("Use /vg fff<ID> or /voiceguild fff<ID> to play sound in GuildChat (same as Send Guild button)");
    self:Log("Use /vr fff<ID> or /voiceraid fff<ID> to play sound in RaidChat (same as Send Raid button)");
    self:Log("Use /vy fff<ID> or /voiceyell fff<ID> to yell sound (same as Yell button)");
    self:Log("Use /vc or /voicecombat to disable or enable the voicepack during combat");
    self:Log("use /voicepack or /vpp to toggle window on/off");
end

function Addon:Toggle()
    local frame = getglobal("VoicePack_Main");

    if (frame:IsVisible()) then
        frame:Hide();
    else
        frame:Show();
    end
end

function Addon:UpdateButtons()
    if (VoicePackDisabled) then
        VoicePackSendGuildButton:Disable();
        VoicePackSendPartyButton:Disable();
        VoicePackYellButton:Disable();
        VoicePackRaidButton:Disable();

        return;
    end

    VoicePackSendGuildButton:Enable();
    VoicePackSendPartyButton:Enable();
    VoicePackYellButton:Enable();
    VoicePackRaidButton:Enable();

    if (not IsInGuild()) then
        VoicePackSendGuildButton:Disable();
    end

    if (not IsInRaid()) then
        VoicePackRaidButton:Disable();
    end

    if (GetNumGroupMembers() == 0) then
        VoicePackSendPartyButton:Disable();
    end
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

function Addon:OnEntryClick(entryId)
    ActiveVoiceId = -1;

    if (ActiveTab == 1) then

        idString = getglobal("VoicePackListButton" .. entryId .. "VoiceId"):GetText();

        if DEBUG_MODE then
            self:Log("EC: " .. entryId .. " -- " .. idString);
        end

        id = self:IDStringToId(idString);
        if (id == -1) then
            return;
        end

        if(DEBUG_MODE == true) then
            self:PlaySound(idString, nil, nil);
        end

        VoicePackList.selectedWho = getglobal("VoicePackListButton" .. entryId).whoIndex;
        ActiveVoiceId = id;
        self:Update();
    end
end

function Addon:IsDisabled()
    return VoicePackDisabled or (VoiceDisableInCombat and UnitAffectingCombat("player") and GetNumGroupMembers() > 0);
end

function Addon:PlaySound(voice)
    if (not self:IsDisabled()) then
        local desc = "";
        local SoundHandle;
        local db = VoicePackData();

        success = PlaySoundFile("Interface\\AddOns\\FFFVoicePack\\FFFVoices\\" .. voice .. "_01.mp3");
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

function Addon:Update()
    --local name, guild, level, race, class, zone, group;
    local button;

    local whoOffset = FauxScrollFrame_GetOffset(VoicePackListScrollFrame);
    local whoIndex;

    -- unsere Locals
    local voiceId, shortDesc;
    local voiceList = VoicePackData();
    local numVoices = getn(voiceList);

    for i = 1, VOICES_TO_DISPLAY, 1 do
        whoIndex = whoOffset + i;
        button = getglobal("VoicePackListButton" .. i);
        button.whoIndex = whoIndex;

        voiceId = self:GetIdFromIndex(whoIndex);
        shortDesc = voiceList[whoIndex];

        getglobal("VoicePackListButton" .. i .. "VoiceId"):SetText(voiceId);
        getglobal("VoicePackListButton" .. i .. "ShortDesc"):SetText(shortDesc);

        -- Highlight the correct who
        if (VoicePackList.selectedWho == whoIndex) then
            button:LockHighlight();
        else
            button:UnlockHighlight();
        end

        if (whoIndex > numVoices) then
            button:Hide();
        else
            button:Show();
        end
    end

    self:UpdateButtons();

    -- ScrollFrame update
    FauxScrollFrame_Update(VoicePackListScrollFrame, numVoices, VOICES_TO_DISPLAY, VOICE_PACK_LIST_ENTRY_HEIGHT );

    ShowUIPanel(VoicePack_Main);
end

function Addon:SendVoice(channel)
    local db = VoicePackData();

    if (ActiveVoiceId ~= -1 and ActiveVoiceId ~= nil) then
        if DEBUG_MODE then
            self:Log("Sending Voice: " .. ActiveVoiceId)
        end

        if( ActiveVoiceId <= getn(db)) then
            SendChatMessage("#" .. self:GetIdFromIndex(ActiveVoiceId) .. ": " .. db[ActiveVoiceId], channel);
        else
            self:Log("Invalid VoiceID: " .. id);
        end
    end
end

function Addon:HandleEvent(event)
    self:Log("EVT: " .. event);

    if(self:IsDisabled()) then
        return;
    end

    self:Log("EVT: " .. event);

    local VoiceName;

    if (event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE") then
        self:UpdateButtons();
        return;
    end

    if (event == "CHAT_MSG_YELL") or (event == "CHAT_MSG_GUILD") or (event == "CHAT_MSG_PARTY") or (event == "CHAT_MSG_RAID") then
        self:Log("CHAT_EVT: " .. event .. " -- " .. arg1)
        if (string.sub(arg1, 1, 4) == "#fff") then
            id = string.sub(arg1, 2, 7);
            self:PlaySound(id);
        end
    end

    if (event == "CHAT_MSG_ADDON" and arg1 == "FFFVoicePack") then
        VoiceName = string.sub(arg2, 1, 6);
        VoicePack_playSound(VoiceName, arg4, arg3);
    end
end

function VPSendVoice(channel)
    Addon:SendVoice(channel)
end

function VPEntryOnClick(button)
    Addon:OnEntryClick(button:GetID());
end

function VPOnLoad()
    Addon:Load();
end

function VPOnUpdate()
    Addon:Update();
end

function VPOnDisableEvent()
    return VoicePackDisabled;
end

function VPToggleDisable(checkbox)
    Addon:SetEnabled(checkbox:GetChecked());
end

function VPToggleCombatDisable(checkbox)
    Addon:SetCombatEnable(checkbox:GetChecked())
end

function ListColumn_SetWidth(width, frame)
    if (not frame) then
        frame = self;
    end

    frame:SetWidth(width);
    getglobal(frame:GetName() .. "Middle"):SetWidth(width - 9);
end

