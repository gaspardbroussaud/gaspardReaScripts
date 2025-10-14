--@description Rename region with render track name
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Rename region using render track name (settings can be edited in gaspard_Master settings)

local markrgncount, _, num_regions = reaper.CountProjectMarkers(0)
if num_regions < 1 then return end

local settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/Region/gaspard_Region generation and render matrix tool_settings.json"
if not reaper.file_exists(settings_path) then return end

-- Get Settings -------------------
local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
package.path = package.path .. ";" .. json_file_path .. "/?.lua"
local gson = require("json_utilities_lib")
local version_less = function(v1,v2)
    local a,b={},{}
    for n in v1:gmatch("%d+") do table.insert(a,tonumber(n)) end
    for n in v2:gmatch("%d+") do table.insert(b,tonumber(n)) end
    for i=1,math.max(#a,#b) do local n1,n2=a[i] or 0,b[i] or 0 if n1~=n2 then return n1<n2 end end
    return false
end
if not gson.version or version_less(gson.version, "1.0.4") then
    reaper.MB('Please update gaspard "json_utilities_lib" to version 1.0.4 or higher.', "ERROR", 0)
    return
end

Settings = gson.LoadJSON(settings_path, {"none"})

function GetConcatenatedParentNames(track)
    local _, name = reaper.GetTrackName(track)
    if Settings.exclude_character.value and Settings.exclude_character.value ~= "" then
        name = name:match("^(.-)" .. Settings.exclude_character.value:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")) or name
    end
    while true do
        local parent = reaper.GetParentTrack(track)
        if parent then
            track = parent
            local _, parent_name = reaper.GetTrackName(parent)
            if Settings.exclude_character.value and Settings.exclude_character.value ~= "" then
                parent_name = parent_name:match("^(.-)" .. Settings.exclude_character.value:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")) or parent_name
            end

            if parent_name ~= "" then
                name = parent_name.."_"..name
            end
        else
            return name
        end
    end
end

function GetRegionNaming(track)
    local track_name = ""
    if Settings.region_naming_parent_cascade.value then
        reaper.ShowConsoleMsg("\nTRUE")
        track_name = GetConcatenatedParentNames(track)
    else
        reaper.ShowConsoleMsg("\nFALSE")
        _, track_name = reaper.GetTrackName(track)
        if Settings.exclude_character.value and Settings.exclude_character.value ~= "" then
            track_name = track_name:match("^(.-)" .. Settings.exclude_character.value:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")) or track_name
        end
        if track_name == "" then
            track_name = "Track "..tostring(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")):sub(1, -3)
        end
    end
    return track_name
end

local master_track = reaper.GetMasterTrack(0)
for i = 1, markrgncount do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i - 1)
    if retval and isrgn then
        local track = reaper.EnumRegionRenderMatrix(0, markrgnindexnumber, 0)
        if track ~= master_track then
            local track_name = GetRegionNaming(track)
            reaper.SetProjectMarker(markrgnindexnumber, isrgn, pos, rgnend, track_name)
        end
    end
end
