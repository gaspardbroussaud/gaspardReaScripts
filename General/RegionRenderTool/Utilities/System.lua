-- @noindex
-- @description Region Render Tool functions
-- @author gaspard
-- @about All functions used in gaspard_Region Render Tool.lua script

-- SET GLOBAL VARIABLES
function System_SetVariables()
    track_count = 0
    tracks = {}
end

---comment
---@param track any
---@return any track
---@return integer depth
-- GET TOP PARENT TRACK
function System_GetTopParentTrack(track)
    local depth = 0
    while true do
        local parent = reaper.GetParentTrack(track)
        if parent then
            track = parent
            depth = depth + 1
        else
            return track, depth
        end
    end
end

-- GET PARENT TRACK MATCH FOR TRACK VISIBILITY
function System_GetParentTrackMatch(track, target)
    while true do
        local parent = reaper.GetParentTrack(track)
        if parent then
            if parent ~= target then
                track = parent
            else
                return true
            end
        else
            return false
        end
    end
end

-- TOGGLE BUTTON STATE IN REAPER
function System_SetButtonState(set)
    local _, _, sec, cmd, _, _, _ = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

-- WRITE SETTINGS IN FILE
function System_WriteSettingsFile(setting_select, setting_colapse)
    local file = io.open(settings_path, "w")
    if file then
        file:write(tostring(setting_select).."\n"..tostring(setting_colapse))
        file:close()
    end
end

-- READ SETTINGS IN FILE AT LAUNCH
function System_ReadSettingsFile()
    local setting_select = false
    local setting_collapse = false
    local file = io.open(settings_path, "r")
    if file then
        setting_select = file:read("l")
        setting_collapse = file:read("l")
        file:close()
        if setting_select == "true" then setting_select = true
        else setting_select = false end
        if setting_collapse == "true" then setting_collapse = true
        else setting_collapse = false end
    else
        setting_select = false
        setting_collapse = false
        System_WriteSettingsFile(setting_select, setting_collapse)
    end
    link_tcp_select = setting_select
    link_tcp_collapse = setting_collapse
end
