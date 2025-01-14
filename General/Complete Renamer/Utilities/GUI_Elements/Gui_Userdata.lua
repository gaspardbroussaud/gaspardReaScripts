-- @noindex
-- @description Complete renamer user interface gui userdata
-- @author gaspard
-- @about User interface userdata window used in gaspard_Complete renamer.lua script

local userdata_window = {}

-- GUI Userdatas
function userdata_window.ShowVisuals()
    reaper.ImGui_Text(ctx, "USERDATA")
end

return userdata_window