local _, ns = ...
-- luacheck: globals SLASH_FFFVOICEPACK1 FFFVoicePack_OnAddonCompartmentClick

local Voice, Window = ns.Voice, ns.Window
local tonumber = tonumber

local SEND_COMMANDS = { party = "PARTY", raid = "RAID", guild = "GUILD" }

-- /vp opens the window; /vp play|party|raid|guild <id> plays or sends a line directly (for macros).
SLASH_FFFVOICEPACK1 = "/vp"
SlashCmdList.FFFVOICEPACK = function(input)
    local command, id = input:lower():match("^(%a+)%s+(%d+)$")
    id = tonumber(id)
    if command == "play" then
        Voice.Play(id)
    elseif SEND_COMMANDS[command] then
        Voice.Send(id, SEND_COMMANDS[command])
    else
        Window.Toggle()
    end
end

function FFFVoicePack_OnAddonCompartmentClick()
    Window.Toggle()
end
