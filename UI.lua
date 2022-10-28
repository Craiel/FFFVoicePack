local AceGUI = LibStub("AceGUI-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("FFFVoicePack", false)

local k_VersionString = "2.0"
local m_FrameActive = false
local m_Frame = nil
local m_SelectedEntry = nil
local k_ChatbuttonWidth = 100
local m_FilterText = ""
local m_ActiveContainer = nil
local m_ActiveGroup = nil
local m_ResultLimit = 100
local k_MinFilterLength = 2

function FFFVoicePack:ShowFrame()
    if m_FrameActive == true then
        return
    end

    m_Frame = AceGUI:Create("Frame")
    m_Frame:SetTitle(L["FFFVoicePack"].." "..k_VersionString)
    m_Frame:SetStatusText(L["- No Line Selected -"])
    m_Frame:SetCallback("OnClose", function(widget) FFFVoicePack:CloseFrame() end)
    m_Frame:SetLayout("Flow")

    local buttonGroup = AceGUI:Create("SimpleGroup")
    buttonGroup:SetFullWidth(true)
    buttonGroup:SetHeight(50)
    buttonGroup:SetLayout("Flow")

    local playButton = AceGUI:Create("Button")
    playButton:SetText(L["Play"])
    playButton:SetWidth(k_ChatbuttonWidth)
    playButton:SetCallback("OnClick", function() FFFVoicePack:PlaySound(m_SelectedEntry) end)
    buttonGroup:AddChild(playButton)

    local guildButton = AceGUI:Create("Button")
    guildButton:SetText(L["Guild"])
    guildButton:SetWidth(k_ChatbuttonWidth)
    guildButton:SetCallback("OnClick", function() FFFVoicePack:SendToGuild(m_SelectedEntry) end)
    buttonGroup:AddChild(guildButton)

    local partyButton = AceGUI:Create("Button")
    partyButton:SetText(L["Party"])
    partyButton:SetWidth(k_ChatbuttonWidth)
    partyButton:SetCallback("OnClick", function() FFFVoicePack:SendToParty(m_SelectedEntry) end)
    buttonGroup:AddChild(partyButton)

    local raidButton = AceGUI:Create("Button")
    raidButton:SetText(L["Raid"])
    raidButton:SetWidth(k_ChatbuttonWidth)
    raidButton:SetCallback("OnClick", function() FFFVoicePack:SendToRaid(m_SelectedEntry) end)
    buttonGroup:AddChild(raidButton)

    local searchLabel = AceGUI:Create("Label")
    searchLabel:SetText(L[" Find:"])
    searchLabel:SetWidth(50)
    buttonGroup:AddChild(searchLabel)

    local filterText = AceGUI:Create("EditBox")
    filterText:SetWidth(k_ChatbuttonWidth * 2)
    filterText:SetCallback("OnEnterPressed", function(container, evt, text) FFFVoicePack:SetFilterText(text) end)
    buttonGroup:AddChild(filterText)

    m_Frame:AddChild(buttonGroup)

    tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetTitle(L["Voice Lines"])
    tabGroup:SetFullWidth(true)
    tabGroup:SetFullHeight(true)
    tabGroup:SetLayout("Fill")

    local tabs = {}
    local tabNumber = 1
    local sortedTabLabels = {}
    for k in pairs(FFFVoicePack.DataGroups) do table.insert(sortedTabLabels, k) end
    table.sort(sortedTabLabels)
    for _, groupId in ipairs(sortedTabLabels) do
        table.insert(tabs, {text=groupId, value=groupId})
        tabNumber = tabNumber + 1
    end

    tabGroup:SetCallback("OnGroupSelected", function(container, event, group) FFFVoicePack:SelectTabGroup(container, group) end)
    tabGroup:SelectTab("A")
    tabGroup:SetTabs(tabs)

    m_Frame:AddChild(tabGroup)

    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);

    m_FrameActive = true
end

function FFFVoicePack:SetFilterText(text)
    m_FilterText = text
    if string.len(m_FilterText) >= k_MinFilterLength then
        FFFVoicePack:DrawVoiceLines(FFFVoicePack.Data, m_FilterText, true)
    else
        -- Re-select the tab group to draw it's entries
        FFFVoicePack:SelectTabGroup(m_ActiveContainer, m_ActiveGroup)
    end
end

function FFFVoicePack:SelectTabGroup(container, groupId)
    if container == nil or groupId == nil then
        return
    end

    m_ActiveContainer = container
    m_ActiveGroup = groupId
    FFFVoicePack:DrawVoiceLines(FFFVoicePack.DataGroups[groupId], "", false)
end

function FFFVoicePack:DrawVoiceLines(data, filter, considerResultLimit)
    if m_ActiveContainer == nil or data == nil then
        return
    end

    m_ActiveContainer:ReleaseChildren()

    local scrollcontainer = AceGUI:Create("SimpleGroup")
    scrollcontainer:SetFullWidth(true)
    scrollcontainer:SetFullHeight(true)
    scrollcontainer:SetLayout("Fill")

    m_ActiveContainer:AddChild(scrollcontainer)

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    scrollcontainer:AddChild(scroll)

    local filterIsSet = string.len(filter) >= k_MinFilterLength
    local results = 0
    for id, text in pairs(data) do
        if filterIsSet == false or string.find(string.lower(text), string.lower(filter)) ~= nil then

            local entryGroup = AceGUI:Create("SimpleGroup")
            entryGroup:SetFullWidth(true)
            entryGroup:SetLayout("Flow")

            local idLabel = AceGUI:Create("InteractiveLabel")
            idLabel:SetText("  "..FFFVoicePack:GetVoiceString(id))
            idLabel:SetWidth(80)
            idLabel:SetColor(210, 175, 0)
            idLabel:SetCallback("OnClick", function(button) FFFVoicePack:SelectEntry(id) end)
            entryGroup:AddChild(idLabel)

            local textLabel = AceGUI:Create("InteractiveLabel")
            textLabel:SetText(text)
            textLabel:SetWidth(400)
            textLabel:SetFullWidth(false)
            textLabel:SetCallback("OnClick", function(button, evt, args)
                if args == "RightButton" then
                    FFFVoicePack:PlaySound(id)
                end

                FFFVoicePack:SelectEntry(id)
            end)
            entryGroup:AddChild(textLabel)

            scroll:AddChild(entryGroup)
            results = results + 1
            if results >= m_ResultLimit and considerResultLimit == true then
                break
            end

        end
    end
end

function FFFVoicePack:SelectEntry(id)
    m_SelectedEntry = id
    local entryText = FFFVoicePack.Data[id]
    m_Frame:SetStatusText(FFFVoicePack:GetVoiceString(id)..": "..entryText)
end

function FFFVoicePack:CloseFrame()
    if m_FrameActive == false or m_Frame == nil then
        return
    end

    m_FrameActive = false
    AceGUI:Release(m_Frame)
    m_Frame = nil
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
end

function FFFVoicePack:ToggleWindow(show)
    if show == true then
        FFFVoicePack:ShowFrame()
    end

    if m_FrameActive == true then
        FFFVoicePack:CloseFrame()
    else
        FFFVoicePack:ShowFrame()
    end
end