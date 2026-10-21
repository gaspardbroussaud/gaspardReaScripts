--@description Get userdata from GUID
--@author gaspard
--@version 1.0.3
--@changelog
--  - GaspaReaLauncher GUI style (icon top bar, floating settings panel)
--@about
--  - Get any REAPER userdata from GUID input if found.

-- gaspard libraries: GUI style and GUI system (icon buttons)
GUI_STYLE = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_STYLE.lua")
GUI_SYS = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_SYS.lua")

-- Toggle button state in Reaper
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    action_name = string.match(name, "gaspard_(.-)%.lua")
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

-- Get script version with ReaPack (fallback: @version of this file)
function GetScriptVersion()
    local script_path = select(2, reaper.get_action_context())
    if reaper.ReaPack_GetOwner then
        local pkg = reaper.ReaPack_GetOwner(script_path)
        if pkg then
            local pkg_version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
            reaper.ReaPack_FreeEntry(pkg)
            if pkg_version ~= "" and pkg_version ~= "nil" then return pkg_version end
        end
    end
    local file = io.open(script_path, "r")
    if file then
        local header = file:read(1024) or ""
        file:close()
        local file_version = header:match("@version%s+([%w%.]+)")
        if file_version then return file_version end
    end
    return "1.0.0"
end

-- Init system variables
function InitSystemVariables()
    local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
    package.path = package.path .. ";" .. json_file_path .. "/?.lua"
    gson = require("json_utilities_lib")

    settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/gaspard_'..action_name..'_settings.json'
    Settings = {
    }
    Settings = gson.LoadJSON(settings_path, Settings)
end

-- All initial variable for script and GUI
function InitialVariables()
    --InitSystemVariables()

    -- Get script version with Reapack (fallback: file @version)
    version = GetScriptVersion()

    -- All script variables
    og_window_width = 320
    og_window_height = 300
    min_width, min_height = 320, 200
    window_width = og_window_width
    window_height = og_window_height
    window_x, window_y = 0, 0
    topbar_height = 30
    font_size = 16
    icon_size = 22
    small_font_size = font_size * 0.75
    window_name = "DEBUG GUID TO USERDATA"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    settings_one_changed = false
    showing_GUID = true
    guid_list = {}
end

-- Split a text string into lines
function SplitIntoLines(text)
    local lines = {}
    for line in text:gmatch("([^\n]*)\n?") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    if #lines == 0 then lines = nil end
    return lines
end

function FindUserdataFromGUID(tab)
    if not tab then return nil end

    local list = {}
    for i, element in ipairs(tab) do
        element = string.gsub(element, "{", "")
        element = string.gsub(element, "}", "")
        element = "{"..element.."}"
        local id = nil

        local take = reaper.GetMediaItemTakeByGUID(0, element)
        if take then
            id = take
            _, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
            table.insert(list, {type = "Take", display = name, id = id, sel = false})
            goto continue
        end

        local item = reaper.BR_GetMediaItemByGUID(0, element)
        if item then
            id = item
            _, name = reaper.GetSetMediaItemTakeInfo_String(reaper.GetTake(item, 0), "P_NAME", "", false)
            table.insert(list, {type = "Item", display = name, id = id, sel = false})
            goto continue
        end

        local track = reaper.BR_GetMediaTrackByGUID(0, element)
        if track then
            id = track
            _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
            table.insert(list, {type = "Track", display = name, id = id, sel = false})
            goto continue
        end

        local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
        for j = 0, num_markers + num_regions - 1 do
            local _, isrgn, _, _, name, _ = reaper.EnumProjectMarkers2(0, j)
            local _, markrgn_id = reaper.GetSetProjectInfo_String(0, "MARKER_GUID:"..j, "", false)
            if markrgn_id == element then
                id = markrgn_id
                if isrgn then cur_type = "Region"
                else cur_type = "Marker" end
                table.insert(list, {type = cur_type, display = name, id = id, sel = false})
                break
            end
        end

        ::continue::
    end

    return list
end

function SelectUserdata(userdata)
    if not userdata then return end

    if userdata.type == "Take" then
        local item = reaper.GetMediaItemTake_Item(userdata.id)
        reaper.SetMediaItemSelected(item, true)
    elseif userdata.type == "Item" then
        reaper.SetMediaItemSelected(userdata.id, true)
    elseif userdata.type == "Track" then
        reaper.SetTrackSelected(userdata.id, true)
    elseif userdata.type == "Marker" or "Region" then
        local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
        for j = 0, num_markers + num_regions - 1 do
            local _, _, pos, _, _, _ = reaper.EnumProjectMarkers2(0, j)
            local _, markrgn_id = reaper.GetSetProjectInfo_String(0, "MARKER_GUID:"..j, "", false)
            if markrgn_id == userdata.id then
                reaper.SetEditCurPos(pos, true, true)
            end
        end
    end
end

-- GUI Initialize function
function Gui_Init()
    InitialVariables()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC)
    italic_font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC, 0, reaper.ImGui_FontFlags_Italic())
    icon_font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ICONS)
    reaper.ImGui_Attach(ctx, font)
    reaper.ImGui_Attach(ctx, italic_font)
    reaper.ImGui_Attach(ctx, icon_font)
end

-- GUI Top Bar (GaspaReaLauncher style)
function Gui_TopBar()
    reaper.ImGui_BeginGroup(ctx)
    -- Name and version
    reaper.ImGui_Text(ctx, window_name)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushFont(ctx, italic_font, font_size * 0.75)
    reaper.ImGui_Text(ctx, "v" .. version)
    reaper.ImGui_PopFont(ctx)

    -- Icon buttons (right to left)
    local menu = {}
    table.insert(menu, {icon = 'QUIT', hint = 'Close', font = icon_font, size = icon_size, right_click = false})
    local rv, button = GUI_SYS.IconButtonRight(ctx, menu, window_width)
    if rv then
        if button == 'QUIT' then
            open = false
        end
    end
    reaper.ImGui_EndGroup(ctx)
end

-- Gui Elements GUID
function Gui_Elements_GUID()
    local child_main_x = window_width - 20
    local _, avail_y = reaper.ImGui_GetContentRegionAvail(ctx)
    local child_main_y = avail_y - 10
    reaper.ImGui_SetCursorPosX(ctx, 10)
    if reaper.ImGui_BeginChild(ctx, "child_main_elements_GUID", child_main_x, child_main_y, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        reaper.ImGui_Text(ctx, "GUIDs:")
        changed, guid_list_concat = reaper.ImGui_InputTextMultiline(ctx, "##multiline_guid_list", guid_list_concat, -1, -1 - 30)

        reaper.ImGui_SetCursorPosY(ctx, child_main_y - 22)
        local disabled = false
        if not guid_list_concat or guid_list_concat == "" then disabled = true end
        if disabled then reaper.ImGui_BeginDisabled(ctx) end
        if reaper.ImGui_Button(ctx, "GET USERDATA##button_get_userdata", 160) then
            guid_list = FindUserdataFromGUID(SplitIntoLines(guid_list_concat))
            showing_GUID = false
        end
        if disabled then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_EndChild(ctx)
    end

    reaper.ImGui_Dummy(ctx, 1, 1)
end

-- Gui Elements Userdata
function Gui_Elements_Userdata()
    local child_main_x = window_width - 20
    local _, avail_y = reaper.ImGui_GetContentRegionAvail(ctx)
    local child_main_y = avail_y - 10
    reaper.ImGui_SetCursorPosX(ctx, 10)
    if reaper.ImGui_BeginChild(ctx, "child_main_elements_userdata", child_main_x, child_main_y) then
        reaper.ImGui_Text(ctx, "Userdatas:")
        if reaper.ImGui_BeginListBox(ctx, "##listbox_guid_list", -1, -1 - 22 - 30) then
            if guid_list then
                for i, guid in ipairs(guid_list) do
                    retval, guid.sel = reaper.ImGui_Selectable(ctx, tostring(guid.type)..": "..tostring(guid.display).."##sel_"..tostring(i), guid.sel)
                    if retval then
                        for j, sub_guid in ipairs(guid_list) do
                            if j ~= i and sub_guid.sel then
                                sub_guid.sel = false
                            end
                        end
                        if guid.sel then
                            SelectUserdata(guid)
                            reaper.UpdateArrange()
                        end
                    end
                end
            end

            reaper.ImGui_EndListBox(ctx)
        end

        reaper.ImGui_SetCursorPosY(ctx, child_main_y - 22)
        if reaper.ImGui_Button(ctx, "BACK##button_back", 100) then
            guid_list = {}
            showing_GUID = true
        end

        reaper.ImGui_EndChild(ctx)
    end

    reaper.ImGui_Dummy(ctx, 1, 1)
end

-- GUI function for all elements
function Gui_Loop()
    Gui_PushTheme()
    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, min_width, min_height, math.huge, math.huge)
    -- Font
    reaper.ImGui_PushFont(ctx, font, font_size)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    current_time = reaper.ImGui_GetTime(ctx)

    if visible then
        -- Top bar elements
        Gui_TopBar()

        -- All Gui Elements
        if showing_GUID then
            Gui_Elements_GUID()
        else
            Gui_Elements_Userdata()
        end

        reaper.ImGui_End(ctx)
    end

    reaper.ImGui_PopFont(ctx)
    Gui_PopTheme()
    if open then
      reaper.defer(Gui_Loop)
    end
end

-- Push all GUI style settings
function Gui_PushTheme()
    for i = 1, #GUI_STYLE.VARS do
        reaper.ImGui_PushStyleVar(ctx, GUI_STYLE.VARS[i].var, GUI_STYLE.VARS[i].value)
    end
    for i = 1, #GUI_STYLE.COLORS do
        reaper.ImGui_PushStyleColor(ctx, GUI_STYLE.COLORS[i].col, GUI_STYLE.COLORS[i].value)
    end
end

-- Pop all GUI style settings
function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, #GUI_STYLE.VARS)
    reaper.ImGui_PopStyleColor(ctx, #GUI_STYLE.COLORS)
end

-- Main script execution
SetButtonState(1)
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)
