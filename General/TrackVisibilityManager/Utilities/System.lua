-- @noindex
-- @description Track Visibility Manager functions
-- @author gaspard
-- @about All functions used in gaspard_Track Visibility Manager.lua script

local System = {}

local SCRIPT_EXT = "gaspard_TrackVisibilityManager"
local P_EXT_WAS_MUTED = "P_EXT:" .. SCRIPT_EXT .. ":WasMuted"
local CMD_UNSELECT_ALL_TRACKS = 40297
local CMD_LOCK_TRACKS = 41312
local CMD_UNLOCK_TRACKS = 41313
local CMD_UNMUTE_ALL = 40339
local CMD_UNSOLO_ALL = 40340
local POLL_INTERVAL = 0.25 -- seconds between automatic refreshes

System.tracks = {}      -- 1-based list of track datas
System.rows = {}        -- indexes of tracks displayed in GUI (not inside a collapsed folder)
System.any_solo = false

local gui_collapsed = {} -- GUI collapse state per track (used when collapse is not linked to TCP)
local project = nil
local project_path = nil
local state_count = -1
local last_refresh = 0
local dirty = true

--#region Settings
local SETTINGS_VERSION = "1.4.1"

local function DefaultSettings()
    return {
        version = SETTINGS_VERSION,
        order = {"link_tcp_select", "link_tcp_collapse", "link_tcp_mute", "show_mute_buttons", "link_tcp_solo", "show_solo_buttons", "F_commandID"},
        link_tcp_select = {
            value = false,
            name = "Link TCP selection",
            description = "Links TCP tracks selection states with tool GUI and reverse."
        },
        link_tcp_collapse = {
            value = false,
            name = "Link TCP collapse",
            description = "Links TCP tracks collapsed states with tool GUI and reverse."
        },
        link_tcp_mute = {
            value = true,
            name = "Link TCP Mute",
            description = "Links TCP tracks mute states with tool GUI and reverse."
        },
        show_mute_buttons = {
            value = true,
            name = "Show Mute buttons",
            description = 'Show mute buttons in GUI to interact.\nNeed "Link TCP mute" to work.'
        },
        link_tcp_solo = {
            value = true,
            name = "Link TCP Solo",
            description = 'Links TCP tracks solo states with tool GUI and reverse.\nNeed "Link TCP mute" to work.'
        },
        show_solo_buttons = {
            value = true,
            name = "Show Solo buttons",
            description = 'Show solo buttons in GUI to interact.\nNeed "Link TCP solo" to work.'
        },
        F_commandID = {
            value = "",
            name = "F key Command ID",
            description = 'Set a custom command ID for "F" key shortcut while in GUI focus.\nNumeric (40001) or named (_SWS_...) IDs.'
        }
    }
end

-- Load settings from file, keeping user values and adding new settings
function System.InitSettings()
    local defaults = DefaultSettings()
    local loaded = gson.LoadJSON(settings_path, defaults)
    Settings = defaults
    -- Settings files written by 1.4.0 had mute/solo disabled by default: use the new defaults for them
    local reset_keys = {}
    if type(loaded) == "table" and loaded.version == "1.4.0" then
        reset_keys = {link_tcp_mute = true, show_mute_buttons = true, link_tcp_solo = true, show_solo_buttons = true}
    end
    if type(loaded) == "table" then
        for _, key in ipairs(defaults.order) do
            local entry = not reset_keys[key] and loaded[key] or nil
            if type(entry) == "table" and type(entry.value) == type(defaults[key].value) then
                Settings[key].value = entry.value
            end
        end
    end
    System.ApplySettingsDependencies()
    if type(loaded) ~= "table" or loaded.version ~= SETTINGS_VERSION then
        gson.SaveJSON(settings_path, Settings)
    end
end

-- Keep settings coherent (solo needs mute link, buttons need their link)
function System.ApplySettingsDependencies(changed_key)
    local s = Settings
    if changed_key == "show_mute_buttons" and s.show_mute_buttons.value then s.link_tcp_mute.value = true end
    if changed_key == "link_tcp_solo" and s.link_tcp_solo.value then s.link_tcp_mute.value = true end
    if changed_key == "show_solo_buttons" and s.show_solo_buttons.value then
        s.link_tcp_mute.value = true
        s.link_tcp_solo.value = true
    end
    if not s.link_tcp_mute.value then
        s.show_mute_buttons.value = false
        s.link_tcp_solo.value = false
    end
    if not s.link_tcp_solo.value then s.show_solo_buttons.value = false end
    dirty = true
end

function System.SaveSettings()
    gson.SaveJSON(settings_path, Settings)
end
--#endregion

--#region Track datas
function System.MarkDirty()
    dirty = true
end

-- Read every track and compute derived states in one pass
local function ReadTracks()
    local tracks = {}
    local count = reaper.CountTracks(project)
    local link_collapse = Settings.link_tcp_collapse.value
    local link_select = Settings.link_tcp_select.value

    -- Keep GUI selection between refreshes when selection is not linked
    local previous_select = {}
    for _, t in ipairs(System.tracks) do previous_select[t.id] = t.select end

    local ancestors = {} -- ancestors[depth] = index of the last track seen at this depth
    local any_solo = false
    for i = 1, count do
        local track = reaper.GetTrack(project, i - 1)
        local depth = reaper.GetTrackDepth(track)
        local is_folder = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1
        local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        local mute = reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1
        local solo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO") > 0
        if solo then any_solo = true end

        local collapsed = false
        if is_folder then
            if link_collapse then collapsed = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") >= 2
            else collapsed = gui_collapsed[track] == true end
        end

        local parent = depth > 0 and tracks[ancestors[depth - 1]] or nil
        local t = {
            id = track,
            number = i,
            name = name ~= "" and name or ("Track " .. i),
            depth = depth,
            is_folder = is_folder,
            shown = reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 1,
            mute = mute,
            solo = solo,
            collapsed = collapsed,
            select = link_select and reaper.IsTrackSelected(track) or previous_select[track] == true,
            parent_mute = parent ~= nil and (parent.mute or parent.parent_mute),
            parent_solo = parent ~= nil and (parent.solo or parent.parent_solo),
            child_solo = false,
            hidden_by_collapse = parent ~= nil and (parent.collapsed or parent.hidden_by_collapse),
            last_child = i
        }
        tracks[i] = t
        ancestors[depth] = i

        -- Propagate to ancestors (soloed child makes parents audible, subtree range)
        for d = 0, depth - 1 do
            local ancestor = tracks[ancestors[d]]
            if ancestor then
                ancestor.last_child = i
                if solo then ancestor.child_solo = true end
            end
        end
    end

    local rows = {}
    for i, t in ipairs(tracks) do
        t.implied_solo = not t.solo and (t.parent_solo or t.child_solo)
        if not t.hidden_by_collapse then rows[#rows + 1] = i end
    end

    System.tracks = tracks
    System.rows = rows
    System.any_solo = any_solo
end

-- Called once per frame: refresh track datas when something changed
function System.Update()
    local proj, path = reaper.EnumProjects(-1)
    if proj ~= project or path ~= project_path then
        project, project_path = proj, path
        System.tracks = {}
        dirty = true
    end
    local count = reaper.GetProjectStateChangeCount(project)
    if count ~= state_count then
        state_count = count
        dirty = true
    end
    if #System.tracks ~= reaper.CountTracks(project) then dirty = true end

    local now = reaper.time_precise()
    if dirty or now - last_refresh > POLL_INTERVAL then
        ReadTracks()
        dirty = false
        last_refresh = now
    end
end

-- Return the track and all its children (if folder), without duplicates
local function ExpandWithChildren(indexes)
    local result, seen = {}, {}
    for _, index in ipairs(indexes) do
        local t = System.tracks[index]
        if t then
            for i = index, t.is_folder and t.last_child or index do
                if not seen[i] then
                    seen[i] = true
                    result[#result + 1] = System.tracks[i].id
                end
            end
        end
    end
    return result
end

function System.GetSelectedIndexes()
    local indexes = {}
    for i, t in ipairs(System.tracks) do
        if t.select then indexes[#indexes + 1] = i end
    end
    return indexes
end
--#endregion

--#region Selection
function System.SetTrackSelected(index, value)
    local t = System.tracks[index]
    if not t then return end
    t.select = value
    if Settings.link_tcp_select.value and reaper.ValidatePtr2(project, t.id, "MediaTrack*") then
        reaper.SetTrackSelected(t.id, value)
    end
end

function System.ClearSelection(except_index)
    for i in ipairs(System.tracks) do
        if i ~= except_index then System.SetTrackSelected(i, false) end
    end
end

function System.SelectAll()
    for i in ipairs(System.tracks) do System.SetTrackSelected(i, true) end
end

-- Select displayed rows between two track indexes
function System.SelectRange(index_a, index_b)
    local first, last = math.min(index_a, index_b), math.max(index_a, index_b)
    for _, i in ipairs(System.rows) do
        if i >= first and i <= last then System.SetTrackSelected(i, true) end
    end
end

-- Run an action on a given set of tracks, then restore the user selection
local function RunActionOnTracks(command, track_ids)
    if #track_ids == 0 then return end
    local saved = {}
    for i = 0, reaper.CountSelectedTracks(project) - 1 do
        saved[#saved + 1] = reaper.GetSelectedTrack(project, i)
    end
    reaper.Main_OnCommand(CMD_UNSELECT_ALL_TRACKS, 0)
    for _, track in ipairs(track_ids) do reaper.SetTrackSelected(track, true) end
    reaper.Main_OnCommand(command, 0)
    reaper.Main_OnCommand(CMD_UNSELECT_ALL_TRACKS, 0)
    for _, track in ipairs(saved) do
        -- Hidden tracks are not re-selected to avoid editing invisible tracks
        if reaper.ValidatePtr2(project, track, "MediaTrack*") and reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 1 then
            reaper.SetTrackSelected(track, true)
        end
    end
end
--#endregion

--#region Visibility
local function HideTrack(track)
    if reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 0 then return end
    local was_muted = reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1
    reaper.GetSetMediaTrackInfo_String(track, P_EXT_WAS_MUTED, was_muted and "1" or "", true)
    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 1)
    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 0)
end

local function RestoreMute(track)
    local _, was_muted = reaper.GetSetMediaTrackInfo_String(track, P_EXT_WAS_MUTED, "", false)
    local mute = was_muted == "1"
    -- Compatibility with tracks hidden by v1.3.x (muted state stored as locked 1px height)
    if reaper.GetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE") == 1 and reaper.GetMediaTrackInfo_Value(track, "B_HEIGHTLOCK") == 1 then
        mute = true
        reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 0)
        reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 0)
    end
    reaper.GetSetMediaTrackInfo_String(track, P_EXT_WAS_MUTED, "", true)
    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", mute and 1 or 0)
end

-- Hide or show tracks (and their children for folders)
---@param indexes table Track indexes in System.tracks
---@param shown boolean
function System.SetTracksShown(indexes, shown)
    local track_ids = ExpandWithChildren(indexes)
    if #track_ids == 0 then return end

    reaper.Undo_BeginBlock2(project)
    reaper.PreventUIRefresh(1)

    if shown then
        -- Only hidden tracks are touched (visible children keep their mute/lock state)
        local to_show = {}
        for _, track in ipairs(track_ids) do
            if reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 0 then to_show[#to_show + 1] = track end
        end
        -- Same order as hiding, reversed: show -> unlock -> restore mute (a locked track keeps its mute)
        for _, track in ipairs(to_show) do
            reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
            reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
        end
        RunActionOnTracks(CMD_UNLOCK_TRACKS, to_show)
        for _, track in ipairs(to_show) do RestoreMute(track) end
    else
        local to_hide = {}
        for _, track in ipairs(track_ids) do
            if reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 1 then
                HideTrack(track)
                to_hide[#to_hide + 1] = track
            end
        end
        RunActionOnTracks(CMD_LOCK_TRACKS, to_hide)
        for _, track in ipairs(to_hide) do
            reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
            reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 0)
        end
    end

    reaper.TrackList_AdjustWindows(false)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(project, shown and "Tracks shown via Track Visibility Manager" or "Tracks hidden via Track Visibility Manager", -1)
    dirty = true
end
--#endregion

--#region Collapse
function System.ToggleCollapse(index)
    local t = System.tracks[index]
    if not t or not t.is_folder then return end
    local collapsed = not t.collapsed
    gui_collapsed[t.id] = collapsed
    if Settings.link_tcp_collapse.value then
        reaper.Undo_BeginBlock2(project)
        reaper.SetMediaTrackInfo_Value(t.id, "I_FOLDERCOMPACT", collapsed and 2 or 0)
        reaper.TrackList_AdjustWindows(false)
        reaper.Undo_EndBlock2(project, "Folder collapsed/expanded via Track Visibility Manager", 1)
    end
    dirty = true
end
--#endregion

--#region Mute / Solo
local function ApplyToIndexes(index, apply)
    local t = System.tracks[index]
    if not t then return end
    local targets = t.select and System.GetSelectedIndexes() or {index}
    reaper.Undo_BeginBlock2(project)
    for _, i in ipairs(targets) do apply(System.tracks[i].id) end
    reaper.Undo_EndBlock2(project, "Track mute/solo via Track Visibility Manager", 1)
    dirty = true
end

function System.ToggleMute(index)
    local value = System.tracks[index].mute and 0 or 1
    ApplyToIndexes(index, function(track) reaper.SetMediaTrackInfo_Value(track, "B_MUTE", value) end)
end

function System.ToggleSolo(index)
    local value = System.tracks[index].solo and 0 or 1
    ApplyToIndexes(index, function(track) reaper.SetMediaTrackInfo_Value(track, "I_SOLO", value) end)
end

function System.UnmuteAll()
    reaper.Main_OnCommand(CMD_UNMUTE_ALL, 0)
    dirty = true
end

function System.UnsoloAll()
    reaper.Main_OnCommand(CMD_UNSOLO_ALL, 0)
    dirty = true
end
--#endregion

--#region Custom command
function System.RunCustomCommand()
    local value = tostring(Settings.F_commandID.value or ""):match("^%s*(.-)%s*$")
    if value == "" then return end
    local command = tonumber(value) or reaper.NamedCommandLookup(value)
    if command and command > 0 then reaper.Main_OnCommand(command, 0) end
end
--#endregion

return System
