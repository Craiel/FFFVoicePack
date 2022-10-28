local AddonName, Addon = ...

Addon.__Events__ = {}
Addon.Events  = {}

--[[ ----------------------------------------------------------------------------------
                Event Functions
-------------------------------------------------------------------------------------]]
function Addon:RegisterEvent(Event, Handler)
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

--[[ ----------------------------------------------------------------------------------
                Permanent Events
-------------------------------------------------------------------------------------]]
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