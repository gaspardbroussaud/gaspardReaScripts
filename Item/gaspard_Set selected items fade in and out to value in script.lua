--@description Set selected items fade in and out to value in script
--@author gaspard
--@version 1.0.3
--@changelog
--  - Fix typo in settings variables
--@about
--  - Sets fade in and out to specified values in script for each selected items

-- Init system variables
function InitSystemVariables()
    local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
    package.path = package.path .. ";" .. json_file_path .. "/?.lua"
    gson = require("json_utilities_lib")
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    local action_name = string.match(name, "gaspard_(.-)%.lua")

    settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/gaspard_'..action_name..'_settings.json'
    Settings = {
        order = {"fade_in_len", "fade_out_len"},
        fade_in_len = {
            value = 100,
            min = 0,
            name = "Fade in length",
            description = 'Fade in length for selected items in milliseconds.'
        },
        fade_out_len = {
            value = 100,
            min = 0,
            name = "Fade out length",
            description = 'Fade out length for selected items in milliseconds.'
        }
    }
    Settings = gson.LoadJSON(settings_path, Settings)
end

-- SCRIPT FUNCTIONS --
function Main()
    -- Check for selected items in project --
    local sel_item_count = reaper.CountSelectedMediaItems(0)
    if sel_item_count ~= 0 then
        InitSystemVariables()
        -- Apply to all selected items --
        for i = 0, sel_item_count - 1 do
            item = reaper.GetSelectedMediaItem(0, i)
            reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", 1) -- Set selected item fade in to type 2
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", Settings.fade_in_len.value/1000)
            reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", 1) -- Set selected item fade out to type 2
            reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", Settings.fade_out_len.value/1000)
        end
    end
end

-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Set selected items fade in and out to value in script", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
