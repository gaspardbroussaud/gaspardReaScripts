--@description GaspaReaLauncher
--@author gaspard
--@version 1.2.0
--@changelog
--  - Projects already open are focused in their tab instead of being loaded again
--  - Launcher stays open when loading/creating a project is cancelled (and the empty tab is removed)
--  - Fix "Open in new tab" replacing the current project: it now always opens a new tab
--  - Double click / Enter (default style) reuse the current tab only if it is an unsaved and unmodified project
--  - Migrate to the ReaImGui 0.10 module API (ImGui.*)
--  - Fix REAPER freeze when the recent projects list contains duplicates (infinite loop)
--  - Fix Delete key removing projects while typing in the search bar, and asking once per listed project
--  - Fix Ctrl+A selecting projects while typing in the search bar, Ctrl+A now selects only filtered projects
--  - Fix search crashing with special characters ( ( % [ . etc.)
--  - Fix "Show in explorer" / "Relink" triggering several times while the mouse is held
--  - Fix right click popup imbalance (missing EndPopup)
--  - Fix "Default project opening style" not saved when changed
--  - Fix shift selection with a filtered list and selection counter going out of sync
--  - Fix crash when the script is not installed with ReaPack or when SWS / js_ReaScriptAPI are missing
--  - "Show in explorer" now selects the project file (SWS CF_LocateInExplorer)
--  - Enter opens selected projects, Escape clears selection (or closes with "Close on escape")
--  - Favorites are read once per refresh (faster list loading), no more file stat per project
--@about
--  # Gaspard Reaper Launcher
--  Reaper Launcher for projects.

--#region SCRIPT INIT -------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
local SCRIPT_VERSION = "1.2.0"
local window_name = "GASPARD REAPER LAUNCHER"

-- Dependencies check
local missing = {}
if not reaper.ImGui_GetBuiltinPath then missing[#missing + 1] = "ReaImGui (0.10 or newer)" end
if not reaper.BR_Win32_GetPrivateProfileString or not reaper.CF_ShellExecute then missing[#missing + 1] = "SWS extension" end
if not reaper.JS_Dialog_BrowseForOpenFiles then missing[#missing + 1] = "js_ReaScriptAPI" end
if #missing > 0 then
    reaper.MB("Missing dependencies:\n- " .. table.concat(missing, "\n- ") .. "\n\nInstall them with ReaPack.", window_name, 0)
    return
end

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require('imgui')('0.10')

local json_file_path = reaper.GetResourcePath() .. '/Scripts/Gaspard ReaScripts/JSON'
package.path = package.path .. ';' .. json_file_path .. '/?.lua'
local json_ok, gson = pcall(require, 'json_utilities_lib')
local json_version = "1.0.6"
if not json_ok or not gson.version or gson.version_less(gson.version, json_version) then
    reaper.MB('Please install/update gaspard "json_utilities_lib" to version ' .. json_version .. ' or higher.', "ERROR", 0)
    return
end

local libraries_path = reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/"
local style_ok, GUI_STYLE = pcall(dofile, libraries_path .. "GUI_STYLE.lua")
local sys_ok, GUI_SYS = pcall(dofile, libraries_path .. "GUI_SYS.lua")
if not style_ok or not sys_ok then
    reaper.MB("Missing dependency: GUI_STYLE.lua / GUI_SYS.lua\nExpected in:\n" .. libraries_path, "ERROR", 0)
    return
end
local keys_ok, KEYS = pcall(dofile, libraries_path .. "KEYBOARD.lua")
if not keys_ok or not reaper.JS_VKeys_GetState then KEYS = nil end
local shortcut = KEYS and KEYS.GetTableOfPressedKeys() or nil -- shortcut used to launch the script

-- Toggle button state in Reaper + version from ReaPack
local _, script_file, section_id, command_id = reaper.get_action_context()
local action_name = script_file:match('gaspard_(.-)%.lua$') or "GaspaReaLauncher"
local version = SCRIPT_VERSION
if reaper.ReaPack_GetOwner then
    local pkg = reaper.ReaPack_GetOwner(script_file)
    if pkg then
        local ok, _, _, _, _, _, _, pkg_version = pcall(reaper.ReaPack_GetEntryInfo, pkg)
        if ok and pkg_version and pkg_version ~= "" then version = tostring(pkg_version) end
        reaper.ReaPack_FreeEntry(pkg)
    end
end

local function SetButtonState(set)
    if section_id and command_id and command_id > 0 then
        reaper.SetToggleCommandState(section_id, command_id, set)
        reaper.RefreshToolbar2(section_id, command_id)
    end
end
SetButtonState(1)

-- Settings
local settings_path = script_file:match([[^(.*[\/])[^\/]-$]]) .. 'gaspard_' .. action_name .. '_settings.json'
local settings_version = "0.0.7"
local default_settings = {
    version = settings_version,
    order = {"close_on_open", "search_type", "default_open_style", "display_full_path", "close_on_escape", "show_path_hovered", "no_prompt_to_remove"},
    close_on_open = {
        value = true,
        name = "Close on project open",
        description = "Close launcher window on project open."
    },
    search_type = {
        value = "Newest",
        list = {"A-Z", "Z-A", "Newest", "Oldest", "Favorites_Down", "Favorites_Up"},
        name = "Search order type",
        description = "Search order alphabetically, by order, by date..."
    },
    default_open_style = {
        value = "new_tab",
        list = {"current_tab", "new_tab"},
        name = "Default project openning style",
        description = "Open project in current tab or in new tab as default behaviour."
    },
    display_full_path = {
        value = false,
        name = "Display full path",
        description = "Display full path in list view."
    },
    close_on_escape = {
        value = false,
        name = "Close on escape",
        description = "Close launcher on Escape key pressed."
    },
    show_path_hovered = {
        value = false,
        name = "Show path on hover",
        description = "Show full project path on hovered in list."
    },
    no_prompt_to_remove = {
        value = false,
        name = "Do not prompt to remove",
        description = "Do not ask before removing projects from list."
    }
}

Settings = gson.LoadJSON(settings_path, default_settings)
if type(Settings) ~= "table" or not Settings.version or settings_version ~= Settings.version then
    Settings = gson.CompleteUpdate(settings_path, type(Settings) == "table" and Settings or {}, default_settings, {})
end
-- Make sure list values are valid
for _, key in ipairs({"search_type", "default_open_style"}) do
    local valid = false
    for _, value in ipairs(default_settings[key].list) do
        if Settings[key].value == value then valid = true end
    end
    if not valid then Settings[key].value = default_settings[key].value end
end

local function SaveSettings()
    gson.SaveJSON(settings_path, Settings)
end
--#endregion

--#region GUI VARIABLES -----------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
local og_window_width, og_window_height = 1000, 500
local min_width, min_height = 510, 201
local max_width, max_height = 1920, 1080
local window_width, window_height = og_window_width, og_window_height
local window_x, window_y = 0, 0
local no_scrollbar_flags = ImGui.WindowFlags_NoScrollWithMouse | ImGui.WindowFlags_NoScrollbar
local window_flags = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoTitleBar | no_scrollbar_flags
local settings_flags = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoResize
    | ImGui.WindowFlags_TopMost | ImGui.WindowFlags_NoDecoration | ImGui.WindowFlags_AlwaysAutoResize

local topbar_height = 30
local font_size = 16
local icon_size = 22

local ctx = ImGui.CreateContext('gaspard_rea_launcher_ctx')
local arial_font = ImGui.CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC)
local italic_arial_font = ImGui.CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC, 0, ImGui.FontFlags_Italic)
local icon_font = ImGui.CreateFontFromFile(GUI_STYLE.FONTS.ICONS)
ImGui.Attach(ctx, arial_font)
ImGui.Attach(ctx, italic_arial_font)
ImGui.Attach(ctx, icon_font)

local open = true
local show_settings = false
local open_popup = nil          -- popup to open this frame ("topbar" / "project")
local popup_x, popup_y = 0, 0
local open_create = "create"     -- top bar popup mode ("create" / "open")
local context_targets = {}       -- projects targeted by the right click popup

local SORT_ICONS = {
    ["A-Z"] = "ALPHABETICAL_SORT_DOWN",
    ["Z-A"] = "ALPHABETICAL_SORT_UP",
    ["Newest"] = "NUM_SORT_DOWN",
    ["Oldest"] = "NUM_SORT_UP",
    ["Favorites_Up"] = "FAVORITE_SORT_UP",
    ["Favorites_Down"] = "FAVORITE_SORT_DOWN"
}
--#endregion

--#region SCRIPT ELEMENTS ---------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
local os_is_windows = reaper.GetOS():find("Win") ~= nil
local sep = os_is_windows and "\\" or "/"
local ini_file = reaper.get_ini_file()
local FAV_SECTION = "GRL_RecentFav"

local project_list = {}
local visible_projects = {}
local project_search = ""
local last_clicked = nil -- anchor project for shift selection
local need_sort = false

local function RecentKey(i) return string.format("recent%02d", i) end

--#region Favorites (stored in REAPER ExtState fav01, fav02...)
local favorites = {}

local function ReadFavorites()
    favorites = {}
    local i = 1
    while true do
        local path = reaper.GetExtState(FAV_SECTION, string.format("fav%02d", i))
        if path == "" then break end
        favorites[#favorites + 1] = path
        i = i + 1
    end
end

local function WriteFavorites()
    for i, path in ipairs(favorites) do
        reaper.SetExtState(FAV_SECTION, string.format("fav%02d", i), path, true)
    end
    -- Remove entries after the last favorite
    local i = #favorites + 1
    while reaper.GetExtState(FAV_SECTION, string.format("fav%02d", i)) ~= "" do
        reaper.DeleteExtState(FAV_SECTION, string.format("fav%02d", i), true)
        i = i + 1
    end
end

local function IsFavorite(path)
    for _, fav in ipairs(favorites) do
        if fav == path then return true end
    end
    return false
end

local function SetFavorite(path, value)
    for i = #favorites, 1, -1 do
        if favorites[i] == path then table.remove(favorites, i) end
    end
    if value then favorites[#favorites + 1] = path end
    WriteFavorites()
end

local function RenameFavorite(path, new_path)
    for i, fav in ipairs(favorites) do
        if fav == path then favorites[i] = new_path end
    end
    WriteFavorites()
end
--#endregion

local function SortByName(a, b)
    local la, lb = a.name:lower(), b.name:lower()
    if la == lb then return a.ini_line < b.ini_line end
    return la < lb
end

local function SortProjects()
    local sort_type = Settings.search_type.value
    if sort_type == "A-Z" then
        table.sort(project_list, SortByName)
    elseif sort_type == "Z-A" then
        table.sort(project_list, function(a, b) return SortByName(b, a) end)
    elseif sort_type == "Newest" then
        table.sort(project_list, function(a, b) return a.ini_line > b.ini_line end)
    elseif sort_type == "Oldest" then
        table.sort(project_list, function(a, b) return a.ini_line < b.ini_line end)
    elseif sort_type == "Favorites_Down" or sort_type == "Favorites_Up" then
        local favs_first = sort_type == "Favorites_Down"
        table.sort(project_list, function(a, b)
            if a.stared ~= b.stared then
                if favs_first then return a.stared end
                return b.stared
            end
            return SortByName(a, b)
        end)
    end
end

local function GetMaxRecent()
    local retval, value = reaper.BR_Win32_GetPrivateProfileString("REAPER", "maxrecent", "", ini_file)
    local max_recent = retval ~= 0 and tonumber(value) or nil
    return math.max(max_recent or 50, 1)
end

-- Remove empty lines in [Recent] section of reaper.ini (after removing entries)
local function CleanRecentProjects(max_recent)
    local paths, has_gap, found_empty = {}, false, false
    for i = 1, max_recent do
        local _, path = reaper.BR_Win32_GetPrivateProfileString("Recent", RecentKey(i), "", ini_file)
        if path ~= "" then
            if found_empty then has_gap = true end
            paths[#paths + 1] = path
        else
            found_empty = true
        end
    end
    if not has_gap then return end
    for i = 1, max_recent do
        reaper.BR_Win32_WritePrivateProfileString("Recent", RecentKey(i), paths[i] or "", ini_file)
    end
end

local function GetRecentProjects()
    local max_recent = GetMaxRecent()
    CleanRecentProjects(max_recent)
    ReadFavorites()

    local selected = {}
    for _, project in ipairs(project_list) do
        if project.selected then selected[project.path] = true end
    end

    project_list = {}
    local seen = {}
    for i = 1, max_recent do
        local _, path = reaper.BR_Win32_GetPrivateProfileString("Recent", RecentKey(i), "", ini_file)
        if path == "" then break end
        if not seen[path] then
            seen[path] = true
            local name = (path:match("([^\\/]+)$") or path):gsub("%.[rR][pP][pP]$", "")
            project_list[#project_list + 1] = {
                exists = reaper.file_exists(path),
                name = name,
                selected = selected[path] == true,
                path = path,
                stared = IsFavorite(path),
                ini_line = i
            }
        end
    end
    SortProjects()
    last_clicked = nil
end

-- Search: every word must be found (plain text, case insensitive)
local function SplitIntoWords(text)
    local words = {}
    for word in text:lower():gmatch("%S+") do words[#words + 1] = word end
    return words
end

local function MatchesAllWords(words, text)
    text = text:lower()
    for _, word in ipairs(words) do
        local s, e = text:find(word, 1, true)
        if not s then return false end
        text = text:sub(1, s - 1) .. text:sub(e + 1)
    end
    return true
end

local function DisplayName(project)
    return Settings.display_full_path.value and project.path or project.name
end

local function UpdateVisibleProjects()
    visible_projects = {}
    local words = SplitIntoWords(project_search)
    for _, project in ipairs(project_list) do
        if #words == 0 or MatchesAllWords(words, DisplayName(project)) then
            visible_projects[#visible_projects + 1] = project
        end
    end
end

local function GetSelectedProjects()
    local selected = {}
    for _, project in ipairs(project_list) do
        if project.selected then selected[#selected + 1] = project end
    end
    return selected
end

local function ClearSelection()
    for _, project in ipairs(project_list) do project.selected = false end
end

local function SelectAllVisible()
    for _, project in ipairs(visible_projects) do project.selected = true end
end

local function SelectRange(project_a, project_b)
    local ia, ib
    for i, project in ipairs(visible_projects) do
        if project == project_a then ia = i end
        if project == project_b then ib = i end
    end
    if not ia or not ib then return end
    for i = math.min(ia, ib), math.max(ia, ib) do visible_projects[i].selected = true end
end

-- Current tab is reused only if it is an unsaved (no file) project that was not modified.
-- Modified = needs saving, or has undo history (IsProjectDirty is always 0 when
-- "prompt to save" is disabled in preferences, undo history covers that case).
local function IsCurrentProjectEmpty()
    local proj, proj_path = reaper.EnumProjects(-1)
    if not proj then return true end
    if proj_path and proj_path ~= "" then return false end
    if reaper.IsProjectDirty(proj) ~= 0 then return false end
    if reaper.Undo_CanUndo2(proj) then return false end
    return true
end

-- Open projects, first one in the given style and the next ones in new tabs
-- Compare project paths (slashes and case on Windows)
local function NormalizePath(path)
    path = (path or ""):gsub("\\", "/")
    if os_is_windows then path = path:lower() end
    return path
end

local function CurrentProjectPath()
    local _, path = reaper.EnumProjects(-1)
    return path or ""
end

-- Snapshot of the current project, to know if "New project" was cancelled
local function CurrentProjectState()
    local proj, path = reaper.EnumProjects(-1)
    return {proj = proj, path = path or "", dirty = reaper.IsProjectDirty(proj), undo = reaper.Undo_CanUndo2(proj)}
end

-- Return the project tab where this file is already open (nil if not open)
local function FindOpenProject(path)
    local target = NormalizePath(path)
    local i = 0
    while true do
        local proj, proj_path = reaper.EnumProjects(i)
        if not proj then return nil end
        if proj_path and proj_path ~= "" and NormalizePath(proj_path) == target then return proj end
        i = i + 1
    end
end

-- Load a project file, returns false if loading was cancelled (save prompt cancelled...)
-- If the project is already open, its tab is focused instead.
local function LoadProject(path, new_tab)
    local open_proj = FindOpenProject(path)
    if open_proj then
        reaper.SelectProjectInstance(open_proj)
        return true
    end
    if new_tab then
        reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
    end
    reaper.Main_openProject(path)
    local loaded = NormalizePath(CurrentProjectPath()) == NormalizePath(path)
    if not loaded and new_tab then
        -- Remove the empty tab created for the cancelled load
        local proj, cur_path = reaper.EnumProjects(-1)
        if (cur_path or "") == "" and reaper.IsProjectDirty(proj) == 0 and not reaper.Undo_CanUndo2(proj) then
            reaper.Main_OnCommand(40860, 0) -- Close current project tab
        end
    end
    return loaded
end

local function CloseIfAsked()
    if Settings.close_on_open.value then open = false end
end

---@param force_style boolean|nil true when the user explicitly chose the tab (right click menu)
local function OpenProjects(projects, open_style, force_style)
    -- Default style only: reuse the current tab if it is an unmodified empty project
    if not force_style and IsCurrentProjectEmpty() then open_style = "current_tab" end
    local opened, cancelled, missing_paths = false, false, {}
    for _, project in ipairs(projects) do
        if project.exists then
            if LoadProject(project.path, open_style == "new_tab") then
                opened = true
                open_style = "new_tab"
            else
                cancelled = true
                break -- user cancelled: do not open the next projects
            end
        else
            missing_paths[#missing_paths + 1] = project.path
            project.selected = false
        end
    end
    if #missing_paths > 0 then
        reaper.MB("No file found at path:\n" .. table.concat(missing_paths, "\n"), "GASPARD REAPER LAUNCHER ERROR", 0)
    end
    -- Launcher stays open if a load was cancelled
    if opened and not cancelled then CloseIfAsked() end
end

local function NewProjectOpen(open_style)
    if open_style == "new_tab" then
        reaper.Main_OnCommand(40859, 0) -- New project tab (never prompts)
        CloseIfAsked()
        return
    end
    local before = CurrentProjectState()
    reaper.Main_OnCommand(40023, 0) -- New project (may prompt to save)
    local after = CurrentProjectState()
    local already_blank = before.path == "" and before.dirty == 0 and not before.undo
    local unchanged = after.proj == before.proj and after.path == before.path
        and after.dirty == before.dirty and after.undo == before.undo
    -- Cancelled (save prompt) = previous project still there unchanged
    if already_blank or not unchanged then CloseIfAsked() end
end

local function OpenProjectSelect(open_style)
    local retval, filepath = reaper.JS_Dialog_BrowseForOpenFiles("Select a project to open", "", "", "REAPER project (*.rpp)\0*.rpp\0\0", false)
    if retval and retval > 0 and filepath and filepath ~= "" then
        if LoadProject(filepath, open_style == "new_tab") then CloseIfAsked() end
    end
end

local function RemoveProjects(projects)
    if #projects == 0 then return end
    local msg_text = #projects > 1 and "ies" or "y"
    local confirmed = Settings.no_prompt_to_remove.value
    if not confirmed then
        confirmed = reaper.ShowMessageBox("The selected entr" .. msg_text .. " will be removed.", "REMOVE SELECTED ENTR" .. string.upper(msg_text), 1) == 1
    end
    if not confirmed then return end
    for _, project in ipairs(projects) do
        reaper.BR_Win32_WritePrivateProfileString("Recent", RecentKey(project.ini_line), "", ini_file)
        if project.stared then SetFavorite(project.path, false) end
    end
    GetRecentProjects()
end

local function ShowInExplorer(projects)
    for _, project in ipairs(projects) do
        if project.exists then
            if reaper.CF_LocateInExplorer then
                reaper.CF_LocateInExplorer(project.path)
            else
                reaper.CF_ShellExecute(project.path:match("^(.*)[/\\]"))
            end
        end
    end
end

local function GetLastExistingFolder(path)
    path = path:gsub("[/\\]", sep)
    while path ~= "" do
        if reaper.EnumerateFiles(path, 0) or reaper.EnumerateSubdirectories(path, 0) or os.rename(path, path) then
            return path .. sep
        end
        path = path:match("(.*)[/\\]") or ""
    end
    return ""
end

local function RelinkProject(project, new_path)
    reaper.BR_Win32_WritePrivateProfileString("Recent", RecentKey(project.ini_line), new_path, ini_file)
    if project.stared then RenameFavorite(project.path, new_path) end
end

local function RelinkProjects(projects)
    if #projects == 1 then
        local project = projects[1]
        local retval, selected_path = reaper.GetUserFileNameForRead(GetLastExistingFolder(project.path), "Select a REAPER project file", ".rpp")
        if retval and selected_path ~= "" then
            RelinkProject(project, selected_path)
            GetRecentProjects()
        end
        return
    end
    local retval, folder_path = reaper.JS_Dialog_BrowseForFolder("Select the projects' folder", GetLastExistingFolder(projects[1].path))
    if retval ~= 1 or not folder_path or folder_path == "" then return end
    local found_once = false
    for _, project in ipairs(projects) do
        if not project.exists then
            local candidates = {
                folder_path .. sep .. project.name .. ".rpp",
                folder_path .. sep .. project.name .. sep .. project.name .. ".rpp"
            }
            for _, candidate in ipairs(candidates) do
                if reaper.file_exists(candidate) then
                    RelinkProject(project, candidate)
                    found_once = true
                    break
                end
            end
        end
    end
    if found_once then GetRecentProjects() end
end
--#endregion

--#region GUI ELEMENTS ------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
local function OpenPopupAtMouse(name)
    popup_x, popup_y = ImGui.GetMousePos(ctx)
    open_popup = name
end

-- GUI Top Bar
local function TopBarDisplay()
    ImGui.BeginGroup(ctx)
    ImGui.Text(ctx, window_name)
    ImGui.SameLine(ctx)
    ImGui.PushFont(ctx, italic_arial_font, font_size * 0.75)
    ImGui.Text(ctx, "v" .. version)
    ImGui.PopFont(ctx)

    local menu = {
        {icon = 'QUIT', hint = 'Close', font = icon_font, size = icon_size, right_click = false},
        {icon = 'GEAR', hint = 'Settings', font = icon_font, size = icon_size, right_click = false},
        {icon = 'REFRESH_ARROW', hint = 'Refresh', font = icon_font, size = icon_size, right_click = false},
        {icon = 'IMPORT_FILE', hint = 'Open project (right click for options)', font = icon_font, size = icon_size, right_click = true},
        {icon = 'NEW_FILE', hint = 'New project (right click for options)', font = icon_font, size = icon_size, right_click = true},
    }
    local rv, button = GUI_SYS.IconButtonRight(ctx, menu, window_width)
    if rv then
        local right_click = ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right)
        if button == 'QUIT' then
            open = false
        elseif button == 'GEAR' then
            show_settings = not show_settings
            if not show_settings then SaveSettings() end
        elseif button == 'REFRESH_ARROW' then
            GetRecentProjects()
        elseif button == 'IMPORT_FILE' or button == 'NEW_FILE' then
            open_create = button == 'NEW_FILE' and "create" or "open"
            if right_click then
                OpenPopupAtMouse("popup_mouse_rc_topbar")
            elseif open_create == "create" then
                NewProjectOpen(Settings.default_open_style.value)
            else
                OpenProjectSelect(Settings.default_open_style.value)
            end
        end
    end
    ImGui.EndGroup(ctx)
end

local function TopBarPopup()
    ImGui.SetNextWindowPos(ctx, popup_x, popup_y, ImGui.Cond_Appearing)
    if ImGui.BeginPopup(ctx, "popup_mouse_rc_topbar") then
        local text = open_create == "create" and "Create" or "Open"
        for _, style in ipairs({"current_tab", "new_tab"}) do
            if ImGui.Selectable(ctx, text .. " in " .. style:gsub("_", " ")) then
                if open_create == "create" then NewProjectOpen(style) else OpenProjectSelect(style) end
            end
        end
        ImGui.EndPopup(ctx)
    end
end

-- Push all GUI style settings
local function Gui_PushTheme()
    for i = 1, #GUI_STYLE.VARS do
        ImGui.PushStyleVar(ctx, GUI_STYLE.VARS[i].var, GUI_STYLE.VARS[i].value)
    end
    for i = 1, #GUI_STYLE.COLORS do
        ImGui.PushStyleColor(ctx, GUI_STYLE.COLORS[i].col, GUI_STYLE.COLORS[i].value)
    end
end

-- Pop all GUI style settings
local function Gui_PopTheme()
    ImGui.PopStyleVar(ctx, #GUI_STYLE.VARS)
    ImGui.PopStyleColor(ctx, #GUI_STYLE.COLORS)
end

local function SearchBar()
    ImGui.Text(ctx, "Search:")
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, -1 - 65)
    _, project_search = ImGui.InputText(ctx, "##search_bar", project_search)
    ImGui.SameLine(ctx)

    ImGui.SetNextItemWidth(ctx, -1)
    ImGui.PushFont(ctx, icon_font, 20)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFFFFFFDF)
    if ImGui.BeginCombo(ctx, "##sort_search", GUI_STYLE.ICONS[SORT_ICONS[Settings.search_type.value]]) then
        for _, sort_type in ipairs(Settings.search_type.list) do
            if ImGui.Selectable(ctx, GUI_STYLE.ICONS[SORT_ICONS[sort_type]] .. "##" .. sort_type, sort_type == Settings.search_type.value) then
                Settings.search_type.value = sort_type
                SaveSettings()
                SortProjects()
            end
        end
        ImGui.EndCombo(ctx)
    end
    ImGui.PopStyleColor(ctx)
    ImGui.PopFont(ctx)
end

local function OnProjectClicked(project)
    local mods = ImGui.GetKeyMods(ctx)
    local ctrl = (mods & ImGui.Mod_Ctrl) ~= 0
    local shift = (mods & ImGui.Mod_Shift) ~= 0
    if shift and last_clicked then
        if not ctrl then ClearSelection() end
        SelectRange(last_clicked, project)
        return
    end
    if ctrl then
        project.selected = not project.selected
    else
        ClearSelection()
        project.selected = true
    end
    last_clicked = project
end

local function ProjectRow(i, project, draw_list)
    -- Favorite star
    local cx, cy = ImGui.GetCursorScreenPos(ctx)
    local button_size = 15
    if ImGui.InvisibleButton(ctx, "##star_" .. tostring(i), button_size, button_size) then
        project.stared = not project.stared
        SetFavorite(project.path, project.stared)
        need_sort = true
    end
    local hovered = ImGui.IsItemHovered(ctx)
    if hovered then
        local col_header = ImGui.GetStyleColor(ctx, ImGui.Col_HeaderHovered)
        local content_x = ImGui.GetContentRegionAvail(ctx)
        ImGui.DrawList_AddRectFilled(draw_list, cx, cy - 2, cx + content_x, cy + 21, col_header)
    end
    ImGui.SameLine(ctx)

    -- Selectable line
    local hovered_and_selected = hovered and project.selected
    if hovered_and_selected then ImGui.PushStyleColor(ctx, ImGui.Col_Header, 0x00000000) end
    if not project.exists then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFF0000A1) end
    local selectable_flags = ImGui.SelectableFlags_SpanAllColumns | ImGui.SelectableFlags_AllowDoubleClick
    if ImGui.Selectable(ctx, DisplayName(project) .. "##project_" .. tostring(i), project.selected, selectable_flags) then
        if ImGui.IsMouseDoubleClicked(ctx, ImGui.MouseButton_Left) then
            OpenProjects({project}, Settings.default_open_style.value)
        else
            OnProjectClicked(project)
        end
    end
    if not project.exists then ImGui.PopStyleColor(ctx, 1) end
    if hovered_and_selected then ImGui.PopStyleColor(ctx, 1) end

    local selectable_hovered = ImGui.IsItemHovered(ctx)
    if Settings.show_path_hovered.value and ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_Stationary) then
        if not project.exists then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFF0000FA) end
        ImGui.SetTooltip(ctx, project.path)
        if not project.exists then ImGui.PopStyleColor(ctx, 1) end
    end

    -- Right click: popup on selection (or only on this project if not selected)
    if selectable_hovered and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right) then
        if not project.selected then
            ClearSelection()
            project.selected = true
            last_clicked = project
        end
        context_targets = GetSelectedProjects()
        OpenPopupAtMouse("popup_mouse_right_clic")
    end

    local color = project.stared and 0xFFFFFFFF or hovered and 0xCCCCCCFF or selectable_hovered and 0xAAAAAAAA or 0x00000000
    ImGui.PushFont(ctx, icon_font, 16)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, color)
    ImGui.SetCursorScreenPos(ctx, cx + 2, cy + 2)
    ImGui.Text(ctx, GUI_STYLE.ICONS["FAVORITE"])
    ImGui.PopStyleColor(ctx)
    ImGui.PopFont(ctx)
end

local function ProjectPopup()
    ImGui.SetNextWindowPos(ctx, popup_x, popup_y, ImGui.Cond_Appearing)
    if not ImGui.BeginPopup(ctx, "popup_mouse_right_clic") then return end

    local targets = context_targets
    local any_exists, any_missing = false, false
    for _, project in ipairs(targets) do
        if project.exists then any_exists = true else any_missing = true end
    end

    if not any_exists then ImGui.BeginDisabled(ctx) end
    if ImGui.Selectable(ctx, "Open in current tab") then OpenProjects(targets, "current_tab", true) end
    if ImGui.Selectable(ctx, "Open in new tab") then OpenProjects(targets, "new_tab", true) end
    if ImGui.Selectable(ctx, "Show in " .. (os_is_windows and "explorer" or "finder")) then ShowInExplorer(targets) end
    if not any_exists then ImGui.EndDisabled(ctx) end

    if any_missing then
        if ImGui.Selectable(ctx, "Relink project path") then
            local missing_projects = {}
            for _, project in ipairs(targets) do
                if not project.exists then missing_projects[#missing_projects + 1] = project end
            end
            RelinkProjects(missing_projects)
        end
    end

    local msg_text = #targets > 1 and "ies" or "y"
    if ImGui.Selectable(ctx, "Remove entr" .. msg_text) then RemoveProjects(targets) end

    ImGui.EndPopup(ctx)
end

-- All GUI elements
local function ElementsDisplay()
    SearchBar()
    UpdateVisibleProjects()

    if ImGui.BeginListBox(ctx, "##project_listbox", -1, -1) then
        local draw_list = ImGui.GetWindowDrawList(ctx)
        for i, project in ipairs(visible_projects) do
            ProjectRow(i, project, draw_list)
        end
        ImGui.EndListBox(ctx)
    end

    -- Re-sort after drawing (never while iterating the list)
    if need_sort then
        SortProjects()
        need_sort = false
    end

    if open_popup then
        ImGui.OpenPopup(ctx, open_popup)
        open_popup = nil
    end
    TopBarPopup()
    ProjectPopup()
end

local function HandleShortcuts()
    if not ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows) then return end
    if ImGui.IsPopupOpen(ctx, "", ImGui.PopupFlags_AnyPopupId) then return end
    local typing = ImGui.IsAnyItemActive(ctx)
    local ctrl = (ImGui.GetKeyMods(ctx) & ImGui.Mod_Ctrl) ~= 0

    if not typing then
        if ctrl and ImGui.IsKeyPressed(ctx, ImGui.Key_A, false) then SelectAllVisible() end
        if ImGui.IsKeyPressed(ctx, ImGui.Key_Delete, false) then RemoveProjects(GetSelectedProjects()) end
    end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_Enter, false) or ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter, false) then
        local selected = GetSelectedProjects()
        if #selected == 0 and typing and #visible_projects == 1 then selected = {visible_projects[1]} end
        if #selected > 0 then OpenProjects(selected, Settings.default_open_style.value) end
    end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) then
        if Settings.close_on_escape.value then open = false
        elseif not typing then ClearSelection() end
    end
end

-- Settings panel
local function ElementsSettings()
    ImGui.SetNextWindowPos(ctx, window_x + window_width - 8, window_y + topbar_height + 5, ImGui.Cond_Always, 1, 0)
    local settings_visible = ImGui.Begin(ctx, "##settings_window", true, settings_flags)
    if not settings_visible then
        show_settings = false
        return
    end
    ImGui.Text(ctx, "SETTINGS")
    ImGui.Separator(ctx)

    local one_changed = false
    for _, key in ipairs(Settings.order) do
        local setting = Settings[key]
        if type(setting.value) == "boolean" then
            local changed
            changed, setting.value = ImGui.Checkbox(ctx, setting.name, setting.value)
            if changed then one_changed = true end
            ImGui.SetItemTooltip(ctx, setting.description)
        end
    end

    local function Display(value) return (value:sub(1, 1):upper() .. value:sub(2)):gsub("_", " ") end
    ImGui.SetNextItemWidth(ctx, 110)
    if ImGui.BeginCombo(ctx, Settings.default_open_style.name, Display(Settings.default_open_style.value)) then
        for _, style in ipairs(Settings.default_open_style.list) do
            if ImGui.Selectable(ctx, Display(style), style == Settings.default_open_style.value) then
                Settings.default_open_style.value = style
                one_changed = true
            end
        end
        ImGui.EndCombo(ctx)
    end
    ImGui.SetItemTooltip(ctx, Settings.default_open_style.description)

    if one_changed then SaveSettings() end
    ImGui.End(ctx)
end

-- Main loop
local function Gui_Loop()
    Gui_PushTheme()

    ImGui.SetNextWindowSize(ctx, window_width, window_height, ImGui.Cond_Once)
    ImGui.SetNextWindowSizeConstraints(ctx, min_width, min_height, max_width, max_height)
    ImGui.PushFont(ctx, arial_font, font_size)

    local visible
    visible, open = ImGui.Begin(ctx, window_name, true, window_flags)
    if visible then
        window_x, window_y = ImGui.GetWindowPos(ctx)
        window_width, window_height = ImGui.GetWindowSize(ctx)

        TopBarDisplay()
        ElementsDisplay()
        if show_settings then ElementsSettings() end
        HandleShortcuts()

        -- Same shortcut as the one used to launch the script closes it
        if Settings.close_on_escape.value and KEYS and KEYS.CheckShortcutPressed(shortcut) then open = false end

        ImGui.End(ctx)
    end

    ImGui.PopFont(ctx)
    Gui_PopTheme()

    if open then
        reaper.defer(Gui_Loop)
    end
end
--#endregion

GetRecentProjects()
reaper.defer(Gui_Loop)
reaper.atexit(function() SetButtonState(0) end)
