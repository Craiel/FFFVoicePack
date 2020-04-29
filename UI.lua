local AddonName, Addon = ...;

local VoiceData = VoicePackData();
local VoiceCount = getn(VoiceData);

local VoicesToDisplay = 18;

VOICE_PACK_LIST_ENTRY_HEIGHT = 16;

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
        VoicePackSayButton:Disable();
        VoicePackRaidButton:Disable();

        return;
    end

    VoicePackSendGuildButton:Enable();
    VoicePackSendPartyButton:Enable();
    VoicePackYellButton:Enable();
    VoicePackSayButton:Enable();
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

function Addon:OnEntryClick(entryId)
    self.ActiveVoiceId = -1;

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
    self.ActiveVoiceId = id;
    self:Update();
end

function Addon:Update()
    --local name, guild, level, race, class, zone, group;
    local button;

    local whoOffset = FauxScrollFrame_GetOffset(VoicePackListScrollFrame);
    local whoIndex;

    -- unsere Locals
    local voiceId, shortDesc;
    for i = 1, VoicesToDisplay, 1 do
        whoIndex = whoOffset + i;
        button = getglobal("VoicePackListButton" .. i);

        voiceId = self:GetIdFromIndex(whoIndex);
        shortDesc = VoiceData[whoIndex];

        getglobal("VoicePackListButton" .. i .. "VoiceId"):SetText(voiceId);
        getglobal("VoicePackListButton" .. i .. "ShortDesc"):SetText(shortDesc);

        -- Highlight the correct who
        if (self.ActiveVoiceId == whoIndex) then
            button:LockHighlight();
        else
            button:UnlockHighlight();
        end

        if (whoIndex > VoiceCount) then
            button:Hide();
        else
            button:Show();
        end
    end

    self:UpdateButtons();

    -- ScrollFrame update
    FauxScrollFrame_Update(VoicePackListScrollFrame, VoiceCount, VoicesToDisplay, VOICE_PACK_LIST_ENTRY_HEIGHT );

    ShowUIPanel(VoicePack_Main);
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