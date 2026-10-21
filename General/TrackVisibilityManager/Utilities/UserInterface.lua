-- @noindex
-- @description Track Visibility Manager interface
-- @author gaspard
-- @about Complete user interface used in gaspard_Track Visibility Manager.lua script

local Gui = {}

--#region Style
local FONT_SIZE = 16
local ICON_SIZE = 22
local TOPBAR_HEIGHT = 30
local PANEL_FLAGS = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoResize
    | ImGui.WindowFlags_TopMost | ImGui.WindowFlags_NoDecoration | ImGui.WindowFlags_AlwaysAutoResize

local COLORS = {
    mute = {0xAA0000FF, 0xCC0000FF, 0x880000FF},
    mute_light = {0x360036FF, 0xCC0000FF, 0x880000FF},
    solo = {0xAAAA00FF, 0xCCCC00FF, 0x888800FF},
    solo_light = {0x363600FF, 0xCCCC00FF, 0x888800FF},
    muted_text = 0xEFB7B7CC,
}
--#endregion

--#region Variables
local ctx, font, small_font, icon_font
local gui_W, gui_H = 550, 350
local MIN_W, MIN_H = 400, 200
local window_width, window_height = gui_W, gui_H
local window_x, window_y = 0, 0
local ROW_HEIGHT = 21
local last_clicked = nil
local show_settings = false
local settings_changed = false
local open = true
local clipper = nil
--#endregion

-- Push all GUI style settings (gaspard GUI_STYLE library)
local function PushTheme()
    for i = 1, #GUI_STYLE.VARS do
        ImGui.PushStyleVar(ctx, GUI_STYLE.VARS[i].var, GUI_STYLE.VARS[i].value)
    end
    for i = 1, #GUI_STYLE.COLORS do
        ImGui.PushStyleColor(ctx, GUI_STYLE.COLORS[i].col, GUI_STYLE.COLORS[i].value)
    end
end

-- Pop all GUI style settings
local function PopTheme()
    if #GUI_STYLE.VARS > 0 then ImGui.PopStyleVar(ctx, #GUI_STYLE.VARS) end
    if #GUI_STYLE.COLORS > 0 then ImGui.PopStyleColor(ctx, #GUI_STYLE.COLORS) end
end

local function PushButtonColors(colors)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, colors[1])
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, colors[2])
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, colors[3])
end

local function CenterNextItem(item_width)
    local x = ImGui.GetContentRegionAvail(ctx)
    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + math.max(0, (x - item_width) * 0.5))
end

local function SaveSettingsIfChanged()
    if settings_changed then
        System.SaveSettings()
        settings_changed = false
    end
end

--#region Shortcuts
local function HandleShortcuts()
    if not ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows) then return end
    if ImGui.IsAnyItemActive(ctx) then return end -- typing in an input text

    local ctrl = (ImGui.GetKeyMods(ctx) & ImGui.Mod_Ctrl) ~= 0
    if ImGui.IsKeyPressed(ctx, ImGui.Key_F, false) and not ctrl then
        System.RunCustomCommand()
    end
    if ctrl and ImGui.IsKeyPressed(ctx, ImGui.Key_A, false) then
        System.SelectAll()
    end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) then
        System.ClearSelection()
        last_clicked = nil
    end
end
--#endregion

--#region Top bar
-- GUI Top Bar (GaspaReaLauncher style)
local function TopBar()
    ImGui.BeginGroup(ctx)
    ImGui.Text(ctx, window_name)
    ImGui.SameLine(ctx)
    ImGui.PushFont(ctx, small_font, FONT_SIZE * 0.75)
    ImGui.Text(ctx, "v" .. tostring(version))
    ImGui.PopFont(ctx)

    local menu = {
        {icon = 'QUIT', hint = 'Close', font = icon_font, size = ICON_SIZE, right_click = false},
        {icon = 'GEAR', hint = 'Settings', font = icon_font, size = ICON_SIZE, right_click = false},
        {icon = 'REFRESH_ARROW', hint = 'Refresh tracks', font = icon_font, size = ICON_SIZE, right_click = false},
    }
    local rv, button = GUI_SYS.IconButtonRight(ctx, menu, window_width)
    if rv then
        if button == 'QUIT' then
            open = false
        elseif button == 'GEAR' then
            show_settings = not show_settings
            if not show_settings then SaveSettingsIfChanged() end
        elseif button == 'REFRESH_ARROW' then
            System.MarkDirty()
        end
    end
    ImGui.EndGroup(ctx)
end
--#endregion

--#region Tracks table
local function OnRowClicked(index)
    local mods = ImGui.GetKeyMods(ctx)
    local ctrl = (mods & ImGui.Mod_Ctrl) ~= 0
    local shift = (mods & ImGui.Mod_Shift) ~= 0
    local t = System.tracks[index]

    if shift and last_clicked then
        if not ctrl then System.ClearSelection() end
        System.SelectRange(last_clicked, index)
        return
    end
    if ctrl then
        System.SetTrackSelected(index, not t.select)
    else
        System.ClearSelection(index)
        System.SetTrackSelected(index, true)
    end
    last_clicked = index
end

local function MuteButton(index, t)
    ImGui.SameLine(ctx)
    local colors = nil
    if t.mute then colors = COLORS.mute
    elseif t.parent_mute or (System.any_solo and not t.solo and not t.implied_solo) then colors = COLORS.mute_light end
    if colors then PushButtonColors(colors) end
    if ImGui.Button(ctx, "M##mute_button") then
        if (ImGui.GetKeyMods(ctx) & ImGui.Mod_Ctrl) ~= 0 then System.UnmuteAll()
        else System.ToggleMute(index) end
    end
    if colors then ImGui.PopStyleColor(ctx, 3) end
end

local function SoloButton(index, t)
    ImGui.SameLine(ctx)
    local colors = nil
    if t.solo then colors = COLORS.solo
    elseif t.implied_solo and not t.mute and not t.parent_mute then colors = COLORS.solo_light end
    if colors then PushButtonColors(colors) end
    if ImGui.Button(ctx, "S##solo_button") then
        if (ImGui.GetKeyMods(ctx) & ImGui.Mod_Ctrl) ~= 0 then System.UnsoloAll()
        else System.ToggleSolo(index) end
    end
    if colors then ImGui.PopStyleColor(ctx, 3) end
end

local function DrawRow(index)
    local t = System.tracks[index]
    local show_mute = Settings.show_mute_buttons.value and Settings.link_tcp_mute.value
    local show_solo = Settings.show_solo_buttons.value and Settings.link_tcp_solo.value

    ImGui.TableNextRow(ctx)
    ImGui.PushID(ctx, index)

    -- Track number / selectable for multi edit
    ImGui.TableNextColumn(ctx)
    local number = tostring(t.number)
    CenterNextItem(ImGui.CalcTextSize(ctx, number))
    if Settings.link_tcp_select.value then t.select = reaper.IsTrackSelected(t.id) end
    local flags = ImGui.SelectableFlags_SpanAllColumns | ImGui.SelectableFlags_AllowOverlap
    if ImGui.Selectable(ctx, number .. "##selectable", t.select, flags, 0, ROW_HEIGHT) then
        OnRowClicked(index)
    end

    -- Visibility checkbox (+ mute / solo buttons)
    ImGui.TableNextColumn(ctx)
    if not show_mute and not show_solo then CenterNextItem(ROW_HEIGHT) end
    local changed, shown = ImGui.Checkbox(ctx, "##checkbox_visibility", t.shown)
    if changed then
        local targets = t.select and System.GetSelectedIndexes() or {index}
        System.SetTracksShown(targets, shown)
    end
    if show_mute then MuteButton(index, t) end
    if show_solo then SoloButton(index, t) end

    -- Folder arrow + track name
    ImGui.TableNextColumn(ctx)
    if t.is_folder then
        ImGui.Dummy(ctx, t.depth * 10, 1)
        ImGui.SameLine(ctx)
        if ImGui.ArrowButton(ctx, "arrow", t.collapsed and ImGui.Dir_Right or ImGui.Dir_Down) then
            System.ToggleCollapse(index)
        end
    else
        ImGui.Dummy(ctx, t.depth * 10 + 28, 1)
    end
    ImGui.SameLine(ctx)

    local muted_text = Settings.link_tcp_mute.value
        and (t.mute or t.parent_mute or (System.any_solo and not t.solo and not t.implied_solo))
    if muted_text then ImGui.PushStyleColor(ctx, ImGui.Col_Text, COLORS.muted_text) end
    ImGui.Text(ctx, t.name)
    if muted_text then ImGui.PopStyleColor(ctx, 1) end

    ImGui.PopID(ctx)
end

local function TableHeader()
    ImGui.TableNextRow(ctx, ImGui.TableRowFlags_Headers)
    ImGui.TableNextColumn(ctx)
    CenterNextItem(ImGui.CalcTextSize(ctx, "ID"))
    ImGui.Text(ctx, "ID")
    ImGui.TableNextColumn(ctx)
    if Settings.show_mute_buttons.value or Settings.show_solo_buttons.value then
        CenterNextItem(ImGui.CalcTextSize(ctx, "STATE"))
    end
    ImGui.Text(ctx, "STATE")
    ImGui.TableNextColumn(ctx)
    ImGui.Text(ctx, "TRACK NAME")
end

local function TableTracks()
    local avail_x, avail_y = ImGui.GetContentRegionAvail(ctx)
    if ImGui.BeginChild(ctx, "child_scroll", avail_x, avail_y, ImGui.ChildFlags_None, ImGui.WindowFlags_NoScrollbar) then
        local table_flags = ImGui.TableFlags_SizingFixedFit | ImGui.TableFlags_Borders | ImGui.TableFlags_ScrollY
        if ImGui.BeginTable(ctx, "table_tracks", 3, table_flags) then
            ImGui.TableSetupScrollFreeze(ctx, 0, 1)
            TableHeader()

            if not ImGui.ValidatePtr(clipper, 'ImGui_ListClipper*') then
                clipper = ImGui.CreateListClipper(ctx)
            end
            local rows = System.rows
            ImGui.ListClipper_Begin(clipper, #rows)
            while ImGui.ListClipper_Step(clipper) do
                local display_start, display_end = ImGui.ListClipper_GetDisplayRange(clipper)
                for row = display_start + 1, display_end do
                    DrawRow(rows[row])
                end
            end
            ImGui.EndTable(ctx)
        end
        ImGui.EndChild(ctx)
    end
end
--#endregion

--#region Settings window
local SETTING_LABELS = {
    link_tcp_select = "Link track selection",
    link_tcp_collapse = "Link track collapse",
    link_tcp_mute = "Link track mute",
    show_mute_buttons = "Show mute buttons",
    link_tcp_solo = "Link track solo",
    show_solo_buttons = "Show solo buttons",
}

-- Settings panel (GaspaReaLauncher style: changes are saved immediately)
local function SettingsWindow()
    ImGui.SetNextWindowPos(ctx, window_x + window_width - 8, window_y + TOPBAR_HEIGHT + 5, ImGui.Cond_Always, 1, 0)
    local settings_visible = ImGui.Begin(ctx, '##settings_window', true, PANEL_FLAGS)
    if not settings_visible then
        show_settings = false
        return
    end

    ImGui.Text(ctx, "SETTINGS")
    ImGui.Separator(ctx)

    for _, key in ipairs(Settings.order) do
        local setting = Settings[key]
        if type(setting.value) == "boolean" then
            local changed, value = ImGui.Checkbox(ctx, (SETTING_LABELS[key] or setting.name) .. "##settings_" .. key, setting.value)
            ImGui.SetItemTooltip(ctx, setting.description)
            if changed then
                setting.value = value
                System.ApplySettingsDependencies(key)
                settings_changed = true
            end
        end
    end

    -- Custom command ID for F shortcut
    ImGui.SetNextItemWidth(ctx, 110)
    local changed, value = ImGui.InputText(ctx, "F key command ID##input_F_commandID", Settings.F_commandID.value)
    ImGui.SetItemTooltip(ctx, Settings.F_commandID.description)
    if changed then
        Settings.F_commandID.value = value
        settings_changed = true
    end

    -- Save on each change (text input saved when leaving the field)
    if settings_changed and not ImGui.IsAnyItemActive(ctx) then SaveSettingsIfChanged() end

    ImGui.End(ctx)
end
--#endregion

function Gui.Init()
    ctx = ImGui.CreateContext('track_visibility_manager')
    font = ImGui.CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC)
    small_font = ImGui.CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC, 0, ImGui.FontFlags_Italic)
    icon_font = ImGui.CreateFontFromFile(GUI_STYLE.FONTS.ICONS)
    ImGui.Attach(ctx, font)
    ImGui.Attach(ctx, small_font)
    ImGui.Attach(ctx, icon_font)
end

function Gui.Loop()
    System.Update()

    PushTheme()
    local window_flags = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoTitleBar | ImGui.WindowFlags_NoScrollWithMouse | ImGui.WindowFlags_NoScrollbar
    ImGui.SetNextWindowSize(ctx, gui_W, gui_H, ImGui.Cond_Once)
    ImGui.SetNextWindowSizeConstraints(ctx, MIN_W, MIN_H, math.huge, math.huge)
    ImGui.PushFont(ctx, font, FONT_SIZE)

    local visible
    visible, open = ImGui.Begin(ctx, window_name, true, window_flags)
    if visible then
        window_x, window_y = ImGui.GetWindowPos(ctx)
        window_width, window_height = ImGui.GetWindowSize(ctx)

        HandleShortcuts()
        TopBar()

        if show_settings then SettingsWindow() end

        if #System.tracks > 0 then
            TableTracks()
        else
            ImGui.Text(ctx, "Add tracks to begin.")
        end

        ImGui.End(ctx)
    end

    ImGui.PopFont(ctx)
    PopTheme()

    if open then
        reaper.defer(Gui.Loop)
    else
        SaveSettingsIfChanged()
    end
end

return Gui
