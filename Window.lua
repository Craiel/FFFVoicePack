local addonName, ns = ...

local L, Voice = ns.L, ns.Voice

local WIDTH, HEIGHT = 560, 580
local ROW_HEIGHT = 20
local CODE_WIDTH = 56
local BUTTON_WIDTH = 74
local SEND_CHANNELS = { "PARTY", "RAID", "GUILD" }

local Window = {}
ns.Window = Window

local frame, sendButtons, playButton
local selected
local allEntries = {}

local function BuildEntries()
    for id in pairs(ns.Lines) do
        allEntries[#allEntries + 1] = { id = id, search = ns.Lines[id]:lower() }
    end
    table.sort(allEntries, function(a, b) return a.id < b.id end)
end

local function UpdateRow(row)
    row.Selected:SetShown(row:GetElementData().id == selected)
end

local function UpdateControls()
    playButton:SetEnabled(selected ~= nil and Voice.IsEnabled())
    for channel, button in pairs(sendButtons) do
        button:SetEnabled(selected ~= nil and Voice.CanSend(channel))
    end
    if selected then
        frame.Status:SetText("|cffd2af00" .. Voice.Code(selected) .. "|r  " .. ns.Lines[selected])
    else
        frame.Status:SetText(L["Click a line to select it, right-click to play it."])
    end
    frame.ScrollBox:ForEachFrame(UpdateRow)
end

local function Select(id)
    selected = id
    UpdateControls()
end

local function OnRowClick(row, mouseButton)
    local id = row:GetElementData().id
    Select(id)
    if mouseButton == "RightButton" then
        Voice.Play(id)
    end
end

local function InitRow(row, entry)
    if not row.Text then
        row:SetHeight(ROW_HEIGHT)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", OnRowClick)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.Selected = row:CreateTexture(nil, "BACKGROUND")
        row.Selected:SetAllPoints()
        row.Selected:SetColorTexture(0.82, 0.69, 0, 0.2)
        row.Code = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.Code:SetPoint("LEFT", 6, 0)
        row.Code:SetWidth(CODE_WIDTH)
        row.Code:SetJustifyH("LEFT")
        row.Text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.Text:SetPoint("LEFT", row.Code, "RIGHT", 4, 0)
        row.Text:SetPoint("RIGHT", -6, 0)
        row.Text:SetJustifyH("LEFT")
        row.Text:SetWordWrap(false)
    end
    row.Code:SetText(Voice.Code(entry.id))
    row.Text:SetText(ns.Lines[entry.id])
    UpdateRow(row)
end

local function Filter()
    local filter = frame.Search:GetText():lower()
    local entries = {}
    for _, entry in ipairs(allEntries) do
        if filter == "" or entry.search:find(filter, 1, true) then
            entries[#entries + 1] = entry
        end
    end
    frame.ScrollBox:SetDataProvider(CreateDataProvider(entries))
end

local function AddButton(label, tooltip, onClick)
    local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button:SetSize(BUTTON_WIDTH, 22)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    button:SetMotionScriptsWhileDisabled(true)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

local function Build()
    BuildEntries()

    -- The flat portrait frame Forever's own bag windows use, so this one sits in with them.
    frame = CreateFrame("Frame", "FFFVoicePackFrame", UIParent, "PortraitFrameFlatTemplate")
    frame:SetPortraitToAsset(C_AddOns.GetAddOnMetadata(addonName, "IconTexture"))
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetTitle(C_AddOns.GetAddOnMetadata(addonName, "Title"))
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:HookScript("OnShow", UpdateControls)
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_GUILD_UPDATE")
    frame:SetScript("OnEvent", UpdateControls)
    frame:Hide()
    table.insert(UISpecialFrames, frame:GetName())

    frame.Search = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    frame.Search:SetSize(150, 20)
    frame.Search:SetPoint("TOPLEFT", 66, -32)

    sendButtons = {}
    local anchor
    for i = #SEND_CHANNELS, 1, -1 do
        local channel = SEND_CHANNELS[i]
        local button = AddButton(_G[channel],
            L["Send the line to %s chat. Everyone there with the addon hears it."]:format(_G[channel]),
            function() Voice.Send(selected, channel) end)
        if anchor then
            button:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
        else
            button:SetPoint("TOPRIGHT", -10, -31)
        end
        sendButtons[channel] = button
        anchor = button
    end
    playButton = AddButton(L["Play"], L["Play the line for yourself."], function() Voice.Play(selected) end)
    playButton:SetPoint("RIGHT", anchor, "LEFT", -12, 0)

    frame.ScrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    frame.ScrollBox:SetPoint("TOPLEFT", 10, -64)
    frame.ScrollBox:SetPoint("BOTTOMRIGHT", -26, 32)
    frame.ScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.ScrollBar:SetPoint("TOPLEFT", frame.ScrollBox, "TOPRIGHT", 6, -2)
    frame.ScrollBar:SetPoint("BOTTOMLEFT", frame.ScrollBox, "BOTTOMRIGHT", 6, 2)
    local view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("Button", InitRow)
    view:SetElementExtent(ROW_HEIGHT)
    ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view)

    local enabled = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    enabled:SetSize(22, 22)
    enabled:SetPoint("BOTTOMLEFT", 8, 6)
    enabled.Text:SetText(L["Enabled"])
    enabled.Text:SetFontObject("GameFontHighlightSmall")
    enabled:SetChecked(Voice.IsEnabled())
    enabled:SetScript("OnClick", function(self)
        Voice.SetEnabled(self:GetChecked())
        UpdateControls()
    end)
    enabled:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["Off: no line plays or is sent, including ones others send."], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    enabled:SetScript("OnLeave", GameTooltip_Hide)

    frame.Status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Status:SetPoint("LEFT", enabled.Text, "RIGHT", 16, 0)
    frame.Status:SetPoint("RIGHT", -12, 0)
    frame.Status:SetJustifyH("LEFT")
    frame.Status:SetWordWrap(false)

    frame.Search:HookScript("OnTextChanged", Filter)
    Filter()
end

function Window.Toggle()
    if not frame then
        Build()
    end
    frame:SetShown(not frame:IsShown())
end
