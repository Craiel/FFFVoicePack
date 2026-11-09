local _, ns = ...

local GetLocale = GetLocale

-- English text is the key; a missing translation falls back to it.
local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

if GetLocale() == "deDE" then
    L["Enabled"] = "Aktiviert"
    L["Play"] = "Abspielen"
    L["Click a line to select it, right-click to play it."] =
        "Zeile anklicken zum Auswählen, Rechtsklick zum Abspielen."
    L["Play the line for yourself."] = "Spielt die Zeile nur für dich ab."
    L["Send the line to %s chat. Everyone there with the addon hears it."] =
        "Sendet die Zeile in den %s-Chat. Alle dort mit dem Addon hören sie."
    L["Off: no line plays or is sent, including ones others send."] =
        "Aus: keine Zeile wird abgespielt oder gesendet, auch keine von anderen."
end
