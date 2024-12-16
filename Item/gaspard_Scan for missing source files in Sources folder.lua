-- @description Scan for missing source files in Sources folder
-- @author gaspard
-- @version 1.0.3
-- @changelog
--  - Bugfix settings
-- @about Scan all items in current project and copy missing source file in Audio folder (can be edited to user Audio folder path and name)

-- Init system variables
function InitSystemVariables()
    local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
    package.path = package.path .. ";" .. json_file_path .. "/?.lua"
    gson = require("json_utilities_lib")
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    local action_name = string.match(name, "gaspard_(.-)%.lua")

    settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/gaspard_'..action_name..'_settings.json'
    Settings = {
        order = {"source_folder_name"},
        source_folder_name = {
            value = "Media",
            name = "Sources folder name",
            description = 'Set name for audio sources folder in project folder.\nDefault if empty is "Audio".'
        }
    }
    Settings = gson.LoadJSON(settings_path, Settings)
end

-- Save all selected items to restore after execution
function SaveSelectedItems(item_count)
    local item_selection = {}
    for i = 0, item_count - 1 do
        local item = reaper.GetMediaItem(0, i)
        local state = reaper.IsMediaItemSelected(item)
        item_selection[i] = state
        reaper.SetMediaItemSelected(item, false)
    end
    return item_selection
end

-- Restore item selection after execution
function RestoreItemSelection(item_count, item_selection)
    if item_count == reaper.CountMediaItems(0) then
        for i = 0, #item_selection do
            local item = reaper.GetMediaItem(0, i)
            reaper.SetMediaItemSelected(item, item_selection[i])
        end
    end
end

-- Select all offline items from errors
function SelectOfflineItems(item_count, error_msgs)
    if item_count == reaper.CountMediaItems(0) then
        -- Unselect all items
        for i = 0, item_count - 1 do
            local item = reaper.GetMediaItem(0, i)
            reaper.SetMediaItemSelected(item, false)
        end

        -- Select error items
        for i = 1, #error_msgs do
            local item = reaper.GetMediaItem(0, error_msgs[i].index)
            reaper.SetMediaItemSelected(item, true)
        end
    end
end

-- Get separator character from OS for path.
function GetSeperator()
    local separator = "\\"
    -- OS BASED SEPARATOR
    if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
        -- user_folder = buf --"C:\\Users\\[username]" -- need to be test
        separator = "\\"
    else
        -- user_folder = "/USERS/[username]" -- Mac OS. Not tested on Linux.
        separator = "/"
    end
    return separator
end

-- Get Source Directory path.
function GetSourceDirectory(separator, source_folder)
    local _, project_path = reaper.EnumProjects(-1, "")
    local project_sources_dir = ""
    if project_path ~= "" then
        local dir = project_path:match("(.*"..separator..")")
        project_sources_dir = dir..Settings.source_folder_name.value
    end
    return project_sources_dir
end

-- Go throug hall media items and check for source in source directory.
-- If not in source directory, copy file and reassign source to media item.
function ScanAllMediaItems(project_sources_dir, separator, item_count, item_selection)
    local error_msgs = {}
    for i = 0, item_count - 1 do
        local item = reaper.GetMediaItem(0, i)
        local take = reaper.GetMediaItemTake(item, 0)
        local item_source = reaper.GetMediaItemTake_Source(take)
        local item_source_path = reaper.GetMediaSourceFileName(item_source)
        if item_source_path ~= "" or nil then
            local item_source_dir = string.sub(item_source_path:match("(.*"..separator..")"), 1, -2)
            local source_name = string.sub(string.sub(item_source_path, string.len(item_source_dir) + 1), 2, -1)

            if item_source_dir ~= project_sources_dir then

                local old_file = io.open(item_source_path, "rb")
                if old_file ~= nil then
                    local source_file = old_file:read("*all")
                    old_file:close()

                    local source_extension = source_name:match("^.+(%..+)$")
                    source_name = string.gsub(source_name, source_extension, "")
                    local destination_path = project_sources_dir..separator..source_name.."-imported_source"..source_extension
                    local new_file = io.open(destination_path, "wb")

                    if new_file ~= nil then
                        new_file:write(source_file)
                        new_file:close()
                        reaper.BR_SetTakeSourceFromFile(take, destination_path, true)
                        reaper.SetMediaItemSelected(item, true)
                    else
                        reaper.BR_SetTakeSourceFromFile(take, destination_path, true)
                        reaper.SetMediaItemSelected(item, true)
                    end
                else
                    -- If there is no file in directory
                    local _, take_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
                    table.insert(error_msgs, {take_name = take_name, index = i})
                end
            end
        end
    end

    if #error_msgs > 0 then
        local error_msg_display = "Items with source file not found:"
        local loop_length = #error_msgs
        local above_10 = ""
        if #error_msgs > 10 then
            loop_length = 10
            above_10 = "There are "..tostring(#error_msgs).." errors. Displaying only 10.\n"
        end

        for i = 1, loop_length do
            error_msg_display = error_msg_display.."\n\n".." - Item "..tostring(error_msgs[i].index).." as source name: "..tostring(error_msgs[i].take_name)
        end

        local input = reaper.MB(error_msg_display.."\n\n"..above_10, "--------SELECT OFFLINE ITEMS ?--------", 4)
        if input == 6 then -- 6 = Yes, 7 = No
            SelectOfflineItems(item_count, error_msgs)
        else
            RestoreItemSelection(item_count, item_selection)
        end
    else
        RestoreItemSelection(item_count, item_selection)
    end
end

function Main()
    local item_count = reaper.CountMediaItems(0) -- Current project = 0
    if item_count ~= 0 then
        InitSystemVariables()
        local item_selection = SaveSelectedItems(item_count)
        local separator = GetSeperator()
        local project_sources_dir = GetSourceDirectory(separator, Settings.source_folder_name.value)
        if project_sources_dir ~= "" then
            ScanAllMediaItems(project_sources_dir, separator, item_count, item_selection)
            reaper.Main_OnCommand(40441, 0) -- Rebuild peaks for selected items
        end
    end
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Scan for missing source files in Sources folder", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
