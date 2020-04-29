
-- Globals--

VoicePackLocked = false;
TestPlayRunning = false;
VoicePackDisabled    = false; -- is saved
VoiceDisableInCombat = false; -- is saved
VoicePackFirstUpdate = 1;
VoiceText = {};
VoiceIDs  = {};
local Original_ChatFrame_OnEvent = ChatFrame_OnEvent;

-- Constants --

VOICE_PACK_LIST_ENTRY_HEIGHT = 16;
VOICES_TO_DISPLAY = 18;


-- Print message in default chat frame --

function TMPrint(msg)
    local r = 0.50;
    local g = 0.50;
    local b = 1.00;

    if (not frame) then 
        frame = DEFAULT_CHAT_FRAME; 
    end if (frame) then
        frame:AddMessage(msg, r, g, b);
    end
end

VOICEPACK_SUBFRAMES = {"VoicePackList", "VoicePackSearch"};

function VoicePack_Main_ShowSubFrame(frameName)
    for index, value in pairs(VOICEPACK_SUBFRAMES) do
        if (value == frameName) then
            getglobal(value):Show()
        else
            getglobal(value):Hide();    
        end 
    end 
end


-- Initialize Addon --

function VoicePack_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED");
    
    this:RegisterEvent("CHAT_MSG_ADDON");
    this:RegisterEvent("CHAT_MSG_PARTY");
    this:RegisterEvent("CHAT_MSG_GUILD");
    this:RegisterEvent("CHAT_MSG_YELL");
    this:RegisterEvent("CHAT_MSG_RAID");
    
    this:RegisterEvent("VOICEPACKLIST_SHOW");
    this:RegisterEvent("VOICEPACKLIST_UPDATE");
    this:RegisterEvent("VOICEPACKSEARCH_SHOW");
    this:RegisterEvent("VOICEPACKSEARCH_UPDATE");
    
    this:RegisterEvent("PARTY_MEMBERS_CHANGED");
    this:RegisterEvent("PLAYER_GUILD_UPDATE");
    
    this:RegisterForDrag("LeftButton");
    
    PanelTemplates_SetNumTabs(this, 2);
    VoicePack_Main.selectedTab = 1;
    PanelTemplates_UpdateTabs(this);
    
    tinsert(UISpecialFrames, "VoicePack_Main");    
    
    SlashCmdList["VoicePackPLAYSOUND"] = VoicePack_playSound;
    SLASH_VoicePackPLAYSOUND1 = "/vpplay";
    SLASH_VoicePackPLAYSOUND2 = "/vplay";

    SlashCmdList["VoicePackVOICEPARTY"] = VoicePack_SendVoicePartyConsole;
    SLASH_VoicePackVOICEPARTY1 = "/vp";
    SLASH_VoicePackVOICEPARTY2 = "/voiceparty";

    SlashCmdList["VoicePackVOICEGUILD"] = VoicePack_SendVoiceGuildConsole;
    SLASH_VoicePackVOICEGUILD1 = "/vg";
    SLASH_VoicePackVOICEGUILD2 = "/voiceguild";

    SlashCmdList["VoicePackVOICERAID"] = VoicePack_SendVoiceRaidConsole;
    SLASH_VoicePackVOICERAID1 = "/vr";
    SLASH_VoicePackVOICERAID2 = "/voiceraid";

    SlashCmdList["VoicePackVOICEYELL"] = VoicePack_SendVoiceYellConsole;
    SLASH_VoicePackVOICEYELL1 = "/vy";
    SLASH_VoicePackVOICEYELL2 = "/voiceyell";

    SlashCmdList["VoicePackTOGGLE"] = VoicePack_Toggle;
    SLASH_VoicePackTOGGLE1 = "/voicepack";  
    
    SlashCmdList["VoicePackCOMBATDISABLE"] = VoicePack_ToggleCombatDisable;
    SLASH_VoicePackCOMBATDISABLE1 = "/voicecombat";
    SLASH_VoicePackCOMBATDISABLE2 = "/vc";

    SlashCmdList["VoicePackHELP"] = VoicePack_Help;
    SLASH_VoicePackHELP1 = "/vphelp";   
    SLASH_VoicePackHELP2 = "/vhelp";    
    
    TMPrint("FFFVoicePack loaded");
    
    VoicePackSearchButton:Enable();
    
    VoicePack_UpdateButtons();
end

function ChatFrame_OnEvent(event)
    local handleEvent = (event == "CHAT_MSG_YELL")  or (event == "CHAT_MSG_GUILD") or
                        (event == "CHAT_MSG_PARTY") or (event == "CHAT_MSG_RAID");
                       
    if (handleEvent and (string.sub(arg1, 1, 11) == "[VoicePack]") and VoicePack_CurrentlyDisabled()) then
        return;
    end
    
    Original_ChatFrame_OnEvent(event);
end

function VoicePack_Help()
    TMPrint("/vphelp, vhelp:\t Display help");
    TMPrint("Use /vplay fff<ID> to play sound just for you (same as right-click in list)");
    TMPrint("Use /vp fff<ID> or /voiceparty fff<ID> to play sound in PartyChat (same as Send Party button)");
    TMPrint("Use /vg fff<ID> or /voiceguild fff<ID> to play sound in GuildChat (same as Send Guild button)");
    TMPrint("Use /vr fff<ID> or /voiceraid fff<ID> to play sound in RaidChat (same as Send Raid button)");
    TMPrint("Use /vy fff<ID> or /voiceyell fff<ID> to yell sound (same as Yell button)");
    TMPrint("Use /vc or /voicecombat to disable or enable the voicepack during combat");
    TMPrint("use /voicepack to toggle window on/off");
    TMPrint("You can even define a shortcut in the WoW keybindings menu to toggle window on/off.");
end


-- Send functions --
function VoicePack_Test()
    -- TMPrint(VoicePack);
    TMPrint(ListChannels());
end

function VoicePackDisableInCombat_OnClick(checkbutton)
    VoicePackDisableInCombat = checkbutton:GetChecked();

    VoicePack_UpdateButtons();

    local str = "enabled";
    
    if (VoicePackDisableInCombat) then str = "disabled" end;
    
    TMPrint("VoicePack is now " .. str .. " during combat");
end

-- Toggle combat disable --
function VoicePack_ToggleCombatDisable()
    VoiceDisableInCombat_OnClick(VoicePackDisableButton);
end

-- Send a voice pack to party --
function VoicePack_SendVoiceParty(Voice)
    local db = VoicePackData();

    if (Voice ~= nil) then
        if (VoicePack_Main.selectedTab == 1) then
            SendAddonMessage("FFFVoicePack", Voice, "PARTY");
            SendChatMessage("[VoicePack] " .. VoicePackList.selectedVoiceText, "PARTY");
        elseif (VoicePack_Main.selectedTab == 2) then
	    id = VoicePack_voiceIdToId(Voice);
            SendChatMessage("[VoicePack] " .. db[id], "PARTY");
            SendAddonMessage("FFFVoicePack", Voice, "PARTY");
        end
    end
end

-- Send a voice pack to Yell --
function VoicePack_SendVoiceYell(Voice)
    local db = VoicePackData();

    if (Voice ~= nil) then
        if (VoicePack_Main.selectedTab == 1) then
            SendChatMessage(Voice .. ": " .. VoicePackList.selectedVoiceText, "YELL");
        elseif (VoicePack_Main.selectedTab == 2) then
	    id = VoicePack_voiceIdToId(Voice);
            SendChatMessage(Voice .. ": " .. db[id], "YELL");
        end
    end
end


-- Send a voice pack to guild --
function VoicePack_SendVoiceGuild(Voice)
    local db = VoicePackData();

    if (Voice ~= nil) then
        if (VoicePack_Main.selectedTab == 1) then
          SendAddonMessage("FFFVoicePack", Voice, "GUILD");
          SendChatMessage("[VoicePack] " .. VoicePackList.selectedVoiceText, "GUILD");
        elseif (VoicePack_Main.selectedTab == 2) then
	    id = VoicePack_voiceIdToId(Voice);
          SendChatMessage("[VoicePack] " .. db[id], "GUILD");
          SendAddonMessage("FFFVoicePack", Voice, "GUILD");
        end
    end
end

-- Send a voice pack to raid --
function VoicePack_SendVoiceRaid(Voice)
    local db = VoicePackData();

    if (Voice ~= nil) then
        if (VoicePack_Main.selectedTab == 1) then
          SendAddonMessage("FFFVoicePack", Voice, "RAID");
          SendChatMessage("[VoicePack] " .. VoicePackList.selectedVoiceText, "RAID");
        elseif (VoicePack_Main.selectedTab == 2) then
	    id = VoicePack_voiceIdToId(Voice);
          SendChatMessage("[VoicePack] " .. db[id], "RAID");
          SendAddonMessage("FFFVoicePack", Voice, "RAID");
        end
    end
end

-- Send a voice pack to party --
function VoicePack_SendVoicePartyConsole(Voice)
    local id = VoicePack_voiceIdToId(Voice);
    local db = VoicePackData();

    if (id ~= -1 and Voice ~= nil) then
        if (id <= getn(db)) then
            SendAddonMessage("FFFVoicePack", Voice, "PARTY");
            SendChatMessage("[VoicePack] " .. VoicePackList.selectedVoiceText, "PARTY");
        else
            TMPrint("Invalid VoiceID: " .. id);
        end
    end
end

-- Send a voice pack to Yell --
function VoicePack_SendVoiceYellConsole(Voice)
    local id = VoicePack_voiceIdToId(Voice);
    local db = VoicePackData();
    
    if (id ~= -1 and Voice ~= nil) then
        if( id <= getn(db)) then
            SendChatMessage(Voice .. ": " .. db[id], "YELL");
        else
            TMPrint("Invalid VoiceID: " .. id);
        end
    end
end


-- Send a voice pack to guild --
function VoicePack_SendVoiceGuildConsole(Voice)
    local id = VoicePack_voiceIdToId(Voice);
    local db = VoicePackData();
    
    if (id ~= -1 and Voice ~= nil) then
        if (id <= getn(db)) then
            SendAddonMessage("FFFVoicePack", Voice, "GUILD");
            SendChatMessage("[VoicePack] " .. VoicePackList.selectedVoiceText, "GUILD");
        else
            TMPrint("Invalid VoiceID: " .. id);
        end
    end
end

-- Send a voice pack to raid --
function VoicePack_SendVoiceRaidConsole(Voice)
    local id = VoicePack_voiceIdToId(Voice);
    local db = VoicePackData();
    
    if (id ~= -1 and Voice ~= nil) then
        if (id <= getn(db)) then
            SendAddonMessage("FFFVoicePack", Voice, "RAID");
            SendChatMessage("[VoicePack] " .. VoicePackList.selectedVoiceText, "RAID");
        else
            TMPrint("Invalid VoiceID: " .. id);
        end
    end
end

-- Wandelt den String VoiceId in id um zum dereferenzieren des Arrays ("fff034" -> <int>34)
function VoicePack_voiceIdToId(VoiceId)
    local isFFF = strfind(VoiceId, "fff%d%d%d", 0);
    local id = 0;
    
    if (strlen(VoiceId) <=6 ) then
        if (isFFF == 1) then      
            if (strfind(VoiceId, "fff00", 0)) then
                id = strsub(VoiceId, 6, 6);
            
            elseif(strfind(VoiceId, "fff0",0)) then
                id = strsub(VoiceId, 5, 6);
            
            elseif(strfind(VoiceId, "fff", 0)) then
                id = strsub(VoiceId, 4, 6);
            
            else
                TMPrint("Invalid VoiceID.")
            end     
        else
            TMPrint("Parameter for voice IDs should match fff<ID> with <ID> being an integer.");
            id = -1;
        end
    else
        TMPrint("Invalid VoiceID: " .. VoiceId);
        id = -1;
    end
    
    id = tonumber(id);
    return id;
end

function VoicePack_CurrentlyDisabled()
    return VoicePackDisabled or (VoiceDisableInCombat and UnitAffectingCombat("player") and GetNumRaidMembers() > 0);
end


-- sender == nil implies channel == nil! --
function VoicePack_playSound(Voice, sender, channel)
    if (not VoicePack_CurrentlyDisabled()) then
        local desc = "";
        local SoundHandle;
        local db = VoicePackData();

        TestPlayRunning = true;
        SoundHandle = PlaySoundFile("Interface\\AddOns\\FFFVoicePack\\FFFVoices\\" .. getFileName(Voice .. "_01"));

        if (SoundHandle ~= 1) then
            TMPrint("Could not play sound file.");
        end

        -- wait(1);
        TestPlayRunning = false;
    end
end


-- Not in use yet --
function VoicePack_stopSound ()
    StopSoundFile();
end

-- Wait a num of seconds, not in use yet --
function wait(i)
    local time = GetTime();
    local deltaTime = GetTime() + i;
    
    while (time < deltaTime) do
        time = GetTime();
    end
end

function VoicePack_UpdateButtons()
    if (VoicePackDisabled) then
        VoicePackSendGuildButton:Disable();
        VoicePackSendPartyButton:Disable();
        VoicePackYellButton:Disable();
        VoicePackRaidButton:Disable();
        VoicePackSearchSendGuildButton:Disable();
        VoicePackSearchSendPartyButton:Disable();
        VoicePackSearchYellButton:Disable();
        VoicePackSearchRaidButton:Disable();
        
        return;
    end

    VoicePackSendGuildButton:Enable();
    VoicePackSendPartyButton:Enable();
    VoicePackYellButton:Enable();
    VoicePackRaidButton:Enable();
    VoicePackSearchSendGuildButton:Enable();
    VoicePackSearchSendPartyButton:Enable();
    VoicePackSearchYellButton:Enable();
    VoicePackSearchRaidButton:Enable();
    

    if (not IsInGuild()) then
        VoicePackSendGuildButton:Disable();
        VoicePackSearchSendGuildButton:Disable();
    end

    if (GetNumRaidMembers() == 0) then
        VoicePackRaidButton:Disable();
        VoicePackSearchRaidButton:Disable();
    end

    if (GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0) then
        VoicePackSendPartyButton:Disable();
        VoicePackSearchSendPartyButton:Disable();
    end
end

-- Event listener --
function VoicePack_OnEvent(event)
    local VoiceName;
    

    if (event == "PARTY_MEMBERS_CHANGED" or event == "PLAYER_GUILD_UPDATE") then
        VoicePack_UpdateButtons();
        return;
    end
    
    
    if (arg1 == "VOICEPACKLIST_SHOW") then
        VoicePackList_Update();
        VoicePack_Update();
    elseif (arg1 == "VOICEPACKLIST_UPDATE") then
        VoicePackList_Update();
    elseif (arg1 == "VOICEPACKSEARCH_SHOW") then
        VoicePackSearch_Update();
        VoicePack_Update();
    elseif (arg1 == "VOICEPACKSEARCH_UPDATE") then
        VoicePackSearch_Update();
    end
    
    if (event == "CHAT_MSG_YELL") then
        if (string.sub(arg1, 1, 3) == "fff") then
            VoiceName = string.sub(arg1, 1, 6);
            VoicePack_playSound(VoiceName, arg2, "YELL");
        end
    end
    
    if (event == "CHAT_MSG_ADDON" and arg1 == "FFFVoicePack") then
        VoiceName = string.sub(arg2, 1, 6);
        VoicePack_playSound(VoiceName, arg4, arg3);
    end
end


-- Get filename from voiceId
function getFileName(Voice)
    return Voice .. ".mp3";
end


-- Interface functions --
function VoicePack_Toggle()
    local frame = getglobal("VoicePack_Main");
    
    if (frame:IsVisible()) then
        frame:Hide();
    else    
        frame:Show();
    end
end 


function VoicePackListColumn_SetWidth(width, frame)
    if (not frame) then
        frame = this;
    end
    
    frame:SetWidth(width);
    getglobal(frame:GetName() .. "Middle"):SetWidth(width - 9);
end

function VoicePackSearchColumn_SetWidth(width, frame)
    if (not frame) then
        frame = this;
    end
    
    frame:SetWidth(width);
    getglobal(frame:GetName() .. "Middle"):SetWidth(width - 9);
end


function VoicePackVoiceList()
    local voiceList = VoicePackData();
    local fileHandle = nil;
    local fileName = "Interface\AddOns\FFFVoicePack\FFFVoices\FFFVoiceListeTest.txt";
    local length = getn(voiceList);
    
    for voiceId, shortDesc in ipairs(voiceList) do 
        TMPrint(VoicePackGetIdFromIndex(voiceId) .. ":  " .. shortDesc);
    end
    
    -- TMPrint(length);
    -- return voiceList;
end


function VoicePackGetIdFromIndex(index)
    -- TMPrint(index);
    
    if (index < 10) then
        return "fff00" .. index;
    elseif(index < 100) then
        return "fff0" .. index;
    else
        return "fff" .. index;
    end
end

-- Updates the VoicePackListFrame
function VoicePackList_Update()
    
    --local name, guild, level, race, class, zone, group;
    local button;
    
    local whoOffset = FauxScrollFrame_GetOffset(VoicePackListScrollFrame);
    local whoIndex;
    
    -- unsre Locals
    local voiceId, shortDesc;
    local voiceList = VoicePackData();
    local numVoices = getn(voiceList);

    for i = 1, VOICES_TO_DISPLAY, 1 do
        whoIndex = whoOffset + i;
        button = getglobal("VoicePackListButton" .. i);
        button.whoIndex = whoIndex;

        
        voiceId = VoicePackGetIdFromIndex(whoIndex);
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

    VoicePack_UpdateButtons();
    
    
    -- ScrollFrame update
    FauxScrollFrame_Update(VoicePackListScrollFrame, numVoices, VOICES_TO_DISPLAY, VOICE_PACK_LIST_ENTRY_HEIGHT );

    ShowUIPanel(VoicePack_Main);
end


function VoicePackDisable_OnClick(checkbutton)
    VoicePackDisabled = checkbutton:GetChecked();
    
    VoicePack_UpdateButtons();
    VoicePackList_Update();
    
    local str = "enabled";
    
    if (VoicePackDisabled) then str = "disabled" end;
    
    TMPrint("VoicePack is now " .. str);
end


function VoicePackDisable_OnEvent()
    return VoicePackDisabled;                       
end


function VoicePackListEntryButton_OnClick(button)
    if (VoicePack_Main.selectedTab == 1) then
        if(TestPlayRunning == false and button == "RightButton") then            
            VoicePack_playSound(getglobal("VoicePackListButton" .. this:GetID() .. "VoiceId"):GetText(), nil, nil);           
        end
        
        VoicePackList.selectedWho = getglobal("VoicePackListButton" .. this:GetID()).whoIndex;
        VoicePackList.selectedVoiceName = getglobal("VoicePackListButton" .. this:GetID() .. "VoiceId"):GetText();
        VoicePackList.selectedVoiceText = getglobal("VoicePackListButton" .. this:GetID() .. "ShortDesc"):GetText();
        VoicePackList_Update();
        
    elseif (VoicePack_Main.selectedTab == 2) then
        if(TestPlayRunning == false and button == "RightButton") then            
            VoicePack_playSound(getglobal("VoicePackSearchButton" .. this:GetID() .. "VoiceId"):GetText(), nil, nil);         
        end
        
        VoicePackSearch.selectedWho = getglobal("VoicePackSearchButton" .. this:GetID()).whoIndex;
        VoicePackSearch.selectedVoiceName = getglobal("VoicePackSearchButton" .. this:GetID() .. "VoiceId"):GetText();
        VoicePackSearch.selectedVoiceText = getglobal("VoicePackSearchButton" .. this:GetID() .. "ShortDesc"):GetText();
        VoicePackSearch_Update();
    end
end

-- Search after writing in the EditBox Search Frame
function VoicePackFrameEditBox_Search()
    local searchText = VoicePackFrameEditBox:GetText();
    local db = VoicePackData();
    local length = getn(db);
    local indexForResult = 1;
    local result = {};
    local voiceId, shortDesc, text;
    
    VoiceText = {};
    VoiceIDs = {};
    
    if (string.len(searchText) > 0) then
        for i = 1, length do 
            text = strlower(db[i]);
            searchText = strlower(searchText);

            if (string.find(text, searchText) ~= nil) then
                VoiceText[indexForResult] = db[i];
                VoiceIDs[indexForResult] = tonumber(i);
                indexForResult = indexForResult + 1;
            end
        end
    end
   
    if (getn(VoiceText) ~= 0) then
        VoicePackSearch.selectedWho = 0;
        VoicePackSearch.selectedVoiceName = 0;
    end
    
    -- VoicePackSearch_Update();
end

-- Updates the Search Frame after Search and scroll --
function VoicePackSearch_Update()
    VoicePackSearchButton:Enable();
    local length = getn(VoiceIDs);
    local button;
    local whoOffset = FauxScrollFrame_GetOffset(VoicePackSearchScrollFrame);
    local whoIndex = 0;
    local voiceId, shortDesc;
    local voiceList = VoicePackData();
    
    for i = 1, VOICES_TO_DISPLAY, 1 do
        whoIndex = whoOffset + i;
        button = getglobal("VoicePackSearchButton" .. i);
        button.whoIndex = whoIndex;
        
        if (whoIndex <= length) then
            voiceId = VoicePackGetIdFromIndex(VoiceIDs[whoIndex]);
            shortDesc = VoiceText[whoIndex];
        else
            voiceId = "";
            shortDesc = "";
        end 
        
        getglobal("VoicePackSearchButton" .. i .. "VoiceId"):SetText(voiceId);
        getglobal("VoicePackSearchButton" .. i .. "ShortDesc"):SetText(shortDesc);
        
        -- Highlight the correct who
        if (VoicePackSearch.selectedWho == whoIndex) then
            button:LockHighlight();
        else
            button:UnlockHighlight();
        end
        
        if (whoIndex > length) then
            button:Hide();
        else
            button:Show();
        end
    end
    
    VoicePack_UpdateButtons();
    
    -- ScrollFrame update
    FauxScrollFrame_Update(VoicePackSearchScrollFrame, length, VOICES_TO_DISPLAY, VOICE_PACK_LIST_ENTRY_HEIGHT);
    
    ShowUIPanel(VoicePack_Main);
end

function VoicePack_Update()
    -- TMPrint("Tab: "..VoicePack_Main.selectedTab);

    if (VoicePack_Main.selectedTab == 1) then
        VoicePackList_Update();
        VoicePack_Main_ShowSubFrame("VoicePackList");
        
    elseif (VoicePack_Main.selectedTab == 2) then
        VoicePackSearch_Update();
        VoicePack_Main_ShowSubFrame("VoicePackSearch");
    end
end

function VoicePack_OnShow()
    VoicePack_Update();
    UpdateMicroButtons();
    VoicePack_UpdateButtons();
end

function VoicePack_close()
    -- if ( VoicePack_Main:IsVisible() ) then
        HideUIPanel(VoicePack_Main);
    -- end
end

function ToggleVoicePack_Main(tab)
    if (not tab) then
        if (VoicePack_Main:IsVisible()) then
            HideUIPanel(VoicePack_Main);
        else
            ShowUIPanel(VoicePack_Main);
        end
    else
        if (tab == PanelTemplates_GetSelectedTab(VoicePack_Main) and VoicePack_Main:IsVisible()) then
            HideUIPanel(VoicePack_Main);
            return;
        end
        
        PanelTemplates_SetTab(VoicePack_Main, tab);
        if (VoicePack_Main:IsVisible()) then
            VoicePack_OnShow();
        else
            ShowUIPanel(VoicePack_Main);
        end
    end
end