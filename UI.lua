local AddonName, Addon = ...;

local VoiceData = VoicePackData();
local VoiceCount = getn(VoiceData);
local ActiveTextFilter = nil;

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

function Addon:OnEntryClick(entryId, button)
    self.ActiveVoiceId = -1;

    idString = getglobal("VoicePackListButton" .. entryId .. "VoiceId"):GetText();

    if DEBUG_MODE then
        self:Log("EC: " .. entryId .. " -- " .. idString);
    end

    id = self:IDStringToId(idString);
    if (id == -1) then
        return;
    end

    if button == "RightButton" then
        self:PlaySound(idString, nil, nil);
        return;
    end

    if (DEBUG_MODE == true) then
        self:PlaySound(idString, nil, nil);
    end

    VoicePackList.selectedWho = getglobal("VoicePackListButton" .. entryId).whoIndex;
    self.ActiveVoiceId = id;
    self:Update();
end

function Addon:Update()
    local button;

    local offset = FauxScrollFrame_GetOffset(VoicePackListScrollFrame);

    local voiceId, shortDesc;

    local FilteredVoiceText = {};
    local FilteredVoices = {};
    local FilteredVoiceIndex = 0;
    for i = 1, VoiceCount, 1 do
        local text = VoiceData[i];
        local isFiltered = false;
        if ActiveTextFilter ~= nil then
            if (string.find(strlower(text), ActiveTextFilter) == nil) then
                isFiltered = true;
            end
        end

        if not isFiltered then
            FilteredVoices[FilteredVoiceIndex] = i;
            FilteredVoiceText[FilteredVoiceIndex] = text;
            FilteredVoiceIndex = FilteredVoiceIndex + 1;
        end
    end

    local FilteredVoiceCount = FilteredVoiceIndex;
    for i = 1, VoicesToDisplay, 1 do
        local voiceIndex = offset + i - 1;

        button = getglobal("VoicePackListButton" .. i);
        button:Hide();

        if voiceIndex < FilteredVoiceCount then
            voiceId = self:GetIdFromIndex(FilteredVoices[voiceIndex]);
            shortDesc = FilteredVoiceText[voiceIndex];

            getglobal("VoicePackListButton" .. i .. "VoiceId"):SetText(voiceId);
            getglobal("VoicePackListButton" .. i .. "ShortDesc"):SetText(shortDesc);

            -- Highlight the correct who
            if (self.ActiveVoiceId == FilteredVoices[voiceIndex]) then
                button:LockHighlight();
            else
                button:UnlockHighlight();
            end

            button:Show();
        end
    end

    self:UpdateButtons();

    -- ScrollFrame update
    FauxScrollFrame_Update(VoicePackListScrollFrame, FilteredVoiceCount, VoicesToDisplay, VOICE_PACK_LIST_ENTRY_HEIGHT );

    ShowUIPanel(VoicePack_Main);
end

function Addon:SetFilterText(text)
    if text ~= nil and strtrim(text) == "" then text = nil end

    if text ~= nil then
        text = strlower(text);
    end

    ActiveTextFilter = text;
    self:Update();
end

function VPSendVoice(channel)
    Addon:SendVoice(channel)
end

function VPEntryOnClick(self, button)
    Addon:OnEntryClick(self:GetID(), button);
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

function VPSetFilter(text)
    Addon:SetFilterText(text);
end

function ListColumn_SetWidth(width, frame)
    if (not frame) then
        frame = self;
    end

    frame:SetWidth(width);
    getglobal(frame:GetName() .. "Middle"):SetWidth(width - 9);
end