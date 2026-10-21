--@noindex
--@description Complete renamer functions
--@author gaspard
--@about All functions used in gaspard_Complete renamer.lua script

local System = {}

local SCRIPT_EXT = 'gaspard_CompleteRenamer'
local P_EXT_SELECTED = "P_EXT:" .. SCRIPT_EXT .. ":Selected"
local P_EXT_STATE = "P_EXT:" .. SCRIPT_EXT .. ":State"
local ORDER = {"items", "tracks", "markers", "regions"}
local DISPLAY = {items = "Items", tracks = "Tracks", markers = "Markers", regions = "Regions"}

-- New ProjectMarker API (recent REAPER 7 versions). Legacy API is used as fallback.
local HAS_MARKER_API = reaper.GetNumRegionsOrMarkers ~= nil
    and reaper.GetRegionOrMarker ~= nil
    and reaper.GetSetRegionOrMarkerInfo_String ~= nil
    and reaper.GetRegionOrMarkerInfo_Value ~= nil
    and reaper.SetRegionOrMarkerInfo_Value ~= nil

local project_path = ""
local project_state_count = -1
local data_dirty = true
local preview_dirty = true
local ruleset_signature = nil
local selection_touched = false
local last_selection_sync = 0
local SELECTION_SYNC_INTERVAL = 0.1 -- seconds

System.project = reaper.EnumProjects(-1)
System.focus_main_window = false
System.Shift = false
System.Ctrl = false
System.ruleset = {}
System.presets = {}
System.one_renamed = false
System.last_selected_area = "userdata"
System.marker_selection_supported = HAS_MARKER_API

System.global_datas = {order = ORDER}
for _, key in ipairs(ORDER) do
    System.global_datas[key] = {display = DISPLAY[key], show = false, state = true, data = {}}
end

--#region Settings
local SETTINGS_VERSION = "1.0.2"

local function DefaultSettings()
    return {
        version = SETTINGS_VERSION,
        order = {"alphabetical_order", "link_selection", "tree_start_open", "clean_rpp"},
        alphabetical_order = {
            value = false,
            name = "Alphabetical order",
            description = "Sort userdata alphabetically.\nEach data type separated."
        },
        link_selection = {
            value = false,
            name = "Link selection",
            description = HAS_MARKER_API
                and "Link data selection between project and GUI.\n(Items, tracks, markers and regions)"
                or "Link data selection between project and GUI.\n(Items and tracks. Update REAPER for markers/regions)"
        },
        tree_start_open = {
            value = false,
            name = "Trees open on start",
            description = "Trees for userdata types start opened on script launch."
        },
        clean_rpp = {
            value = false,
            name = "Clean project file",
            description = "Clean project file (.rpp) on exit tool.\nSelection data between session is lost."
        }
    }
end

-- Init Settings from file (user values are kept when settings format changes)
function System.InitSettings()
    local defaults = DefaultSettings()
    local loaded = gson.LoadJSON(settings_path, defaults)
    Settings = defaults
    if type(loaded) == "table" then
        for _, key in ipairs(defaults.order) do
            if type(loaded[key]) == "table" and type(loaded[key].value) == "boolean" then
                Settings[key].value = loaded[key].value
            end
        end
    end
    if type(loaded) ~= "table" or loaded.version ~= SETTINGS_VERSION then
        gson.SaveJSON(settings_path, Settings)
    end
end

function System.SaveSettings()
    gson.SaveJSON(settings_path, Settings)
    data_dirty = true
end
--#endregion

--#region Utilities
function System.TableCopy(origin)
    if type(origin) ~= 'table' then return origin end
    local copy = {}
    for key, value in next, origin, nil do
        copy[System.TableCopy(key)] = System.TableCopy(value)
    end
    return setmetatable(copy, getmetatable(origin))
end

-- Reposition an item to another index in a given table
function System.RepositionInTable(table_update, from_index, to_index)
    if not from_index or not to_index or from_index == to_index then return table_update end
    if from_index < 1 or from_index > #table_update or to_index < 1 or to_index > #table_update then return table_update end
    local item = table.remove(table_update, from_index)
    table.insert(table_update, to_index, item)
    return table_update
end

-- Select from one item index to another regardless of direction
---@param tab table Table to go through
---@param one number Index of first object
---@param other number Index of last object
function System.SelectFromOneToTheOther(tab, one, other)
    local first, last = math.min(one, other), math.max(one, other)
    for i = math.max(1, first), math.min(#tab, last) do
        tab[i].selected = true
    end
end

-- Clear element.selected from a given table
function System.ClearTableSelection(tab)
    for _, element in ipairs(tab) do
        element.selected = false
    end
end

function System.MarkPreviewDirty()
    preview_dirty = true
end

function System.MarkDataDirty()
    data_dirty = true
end
--#endregion

--#region UTF-8 aware case conversion
local upper_map, lower_map = {}, {}
local function MapPair(up, low)
    local u, l = utf8.char(up), utf8.char(low)
    upper_map[l] = u
    lower_map[u] = l
end
for cp = 0xC0, 0xDE do if cp ~= 0xD7 then MapPair(cp, cp + 0x20) end end -- Latin-1 (À-Þ / à-þ)
MapPair(0x178, 0xFF)                                                       -- Ÿ / ÿ
for cp = 0x100, 0x12E, 2 do MapPair(cp, cp + 1) end                        -- Latin Extended-A
for cp = 0x132, 0x136, 2 do MapPair(cp, cp + 1) end
for cp = 0x139, 0x147, 2 do MapPair(cp, cp + 1) end
for cp = 0x14A, 0x176, 2 do MapPair(cp, cp + 1) end                        -- includes Œ / œ
for cp = 0x179, 0x17D, 2 do MapPair(cp, cp + 1) end
for cp = 0x391, 0x3A9 do if cp ~= 0x3A2 then MapPair(cp, cp + 0x20) end end -- Greek
for cp = 0x400, 0x40F do MapPair(cp, cp + 0x50) end                        -- Cyrillic
for cp = 0x410, 0x42F do MapPair(cp, cp + 0x20) end

local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"

local function CharUpper(c)
    if #c == 1 then return (c:gsub("%l", string.upper)) end
    return upper_map[c] or c
end

local function CharLower(c)
    if #c == 1 then return (c:gsub("%u", string.lower)) end
    return lower_map[c] or c
end

local function IsWordChar(c)
    if #c > 1 then return true end -- non ASCII characters are considered letters
    return c:match("%w") ~= nil
end

local function Upper(str) return (str:gsub(UTF8_CHAR, CharUpper)) end
local function Lower(str) return (str:gsub(UTF8_CHAR, CharLower)) end

local function CapitalizeWords(str)
    local in_word = false
    return (str:gsub(UTF8_CHAR, function(c)
        if IsWordChar(c) then
            local out = in_word and CharLower(c) or CharUpper(c)
            in_word = true
            return out
        end
        in_word = false
        return c
    end))
end

local function FirstLetterCapital(str)
    local done = false
    return (str:gsub(UTF8_CHAR, function(c)
        if not done and IsWordChar(c) then
            done = true
            return CharUpper(c)
        end
        return CharLower(c)
    end))
end
System.Upper, System.Lower, System.CapitalizeWords, System.FirstLetterCapital = Upper, Lower, CapitalizeWords, FirstLetterCapital
--#endregion

--#region Rules
System.CASE_OPTIONS = {
    {value = 0, key = "capitalize_every_word", display = "Capitalize Every Word"},
    {value = 1, key = "all_lower_case", display = "all lower case"},
    {value = 2, key = "all_upper_case", display = "ALL UPPER CASE"},
    {value = 3, key = "first_letter_capital", display = "First letter capital"},
}
local VALID_TYPES = {insert = true, replace = true, case = true}

-- Make sure a rule (from file, preset or popup) has every expected field
function System.NormalizeRule(rule)
    if type(rule) ~= "table" then return nil end
    local config = type(rule.config) == "table" and rule.config or {}
    local insert = type(config.insert) == "table" and config.insert or {}
    local replace = type(config.replace) == "table" and config.replace or {}
    local case = type(config.case) == "table" and config.case or {}
    local case_selected = math.tointeger(tonumber(case.selected)) or 0
    if case_selected < 0 or case_selected > 3 then case_selected = 0 end
    return {
        version = rule.version or "1.0",
        state = rule.state ~= false,
        selected = false,
        type_selected = VALID_TYPES[rule.type_selected] and rule.type_selected or "insert",
        config = {
            insert = {
                text = tostring(insert.text or ""),
                from_start = insert.from_start ~= false,
                from_end = insert.from_end == true
            },
            replace = {
                search_text = tostring(replace.search_text or ""),
                replace_text = tostring(replace.replace_text or "")
            },
            case = {
                selected = case_selected,
                capitalize_every_word = 0, all_lower_case = 1, all_upper_case = 2, first_letter_capital = 3
            }
        }
    }
end

local function NormalizeRuleset(set)
    local result = {}
    if type(set) ~= "table" then return result end
    for _, rule in ipairs(set) do
        local normalized = System.NormalizeRule(rule)
        if normalized then table.insert(result, normalized) end
    end
    return result
end

-- Add rule using default config
function System.LoadEmptyRule(default_rule, rule_path)
    local empty_rule = gson.LoadJSON(rule_path, default_rule)
    if type(empty_rule) ~= "table" or (empty_rule.version and empty_rule.version ~= default_rule.version) then
        gson.SaveJSON(rule_path, default_rule)
        empty_rule = default_rule
    end
    return System.NormalizeRule(empty_rule)
end

local function EscapeReplacement(str)
    return (str:gsub("%%", "%%%%"))
end

local function EscapePattern(str)
    return (str:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- Get replaced name using ruleset (returns the new name, may be equal to the original)
function System.GetReplacedName(name)
    for _, rule in ipairs(System.ruleset) do
        if rule.state then
            local config = rule.config
            if rule.type_selected == "insert" then
                local text = config.insert.text
                if text ~= "" then
                    if config.insert.from_start then name = text .. name end
                    if config.insert.from_end then name = name .. text end
                end
            elseif rule.type_selected == "replace" then
                local search = config.replace.search_text
                if search ~= "" and name:find(search, 1, true) then
                    name = name:gsub(EscapePattern(search), EscapeReplacement(config.replace.replace_text))
                end
            elseif rule.type_selected == "case" then
                local selected = config.case.selected
                if selected == 0 then name = CapitalizeWords(name)
                elseif selected == 1 then name = Lower(name)
                elseif selected == 2 then name = Upper(name)
                elseif selected == 3 then name = FirstLetterCapital(name)
                end
            end
        end
    end
    return name
end

-- Cheap serialization used to detect ruleset changes (selection is ignored)
local function Serialize(value, out)
    local t = type(value)
    if t == "table" then
        local keys = {}
        for k in pairs(value) do if k ~= "selected" then keys[#keys + 1] = tostring(k) end end
        table.sort(keys)
        out[#out + 1] = "{"
        for _, k in ipairs(keys) do
            local v = value[k]
            if v == nil then v = value[tonumber(k)] end
            out[#out + 1] = k .. "="
            Serialize(v, out)
            out[#out + 1] = ";"
        end
        out[#out + 1] = "}"
    else
        out[#out + 1] = tostring(value)
    end
end

local function RulesetSignature()
    local out = {}
    Serialize(System.ruleset, out)
    return table.concat(out)
end
--#endregion

--#region Presets
local function SanitizeFileName(filename)
    filename = filename:gsub('[<>:"/\\|?*%c]', ""):gsub("^%s+", ""):gsub("[%s%.]+$", "")
    return filename
end

function System.SavePreset(name, preset)
    name = SanitizeFileName(name:gsub("%.json$", ""))
    if name == "" then return false end
    reaper.RecursiveCreateDirectory(presets_path, 0)
    local to_save = {}
    for _, rule in ipairs(preset) do
        local copy = System.NormalizeRule(rule)
        if copy then
            copy.selected = nil
            table.insert(to_save, copy)
        end
    end
    gson.SaveJSON(presets_path .. "/" .. name .. ".json", to_save)
    return true
end

function System.RemovePreset(preset)
    if preset and preset.path then os.remove(preset.path) end
end

function System.ImportPresetReplaceRuleset(preset)
    if not preset or not preset.path then return end
    System.ruleset = NormalizeRuleset(gson.LoadJSON(preset.path))
end

function System.AddPresetToRuleset(preset)
    if not preset or not preset.path then return end
    for _, rule in ipairs(NormalizeRuleset(gson.LoadJSON(preset.path))) do
        table.insert(System.ruleset, rule)
    end
end

function System.ScanPresetFiles()
    local files = {}
    reaper.EnumerateFiles(presets_path, -1) -- invalidate REAPER directory cache
    local index = 0
    local file = reaper.EnumerateFiles(presets_path, index)
    while file do
        if file:lower():match("%.json$") then
            table.insert(files, {path = presets_path .. "/" .. file, name = file:gsub("%.[jJ][sS][oO][nN]$", ""), selected = false})
        end
        index = index + 1
        file = reaper.EnumerateFiles(presets_path, index)
    end
    table.sort(files, function(a, b) return a.name:lower() < b.name:lower() end)
    System.presets = files
end
--#endregion

--#region Project data access
local function ReadExtFlag(getter, object, key, default)
    local ok, value = getter(object, key, "", false)
    if ok and value ~= "" then return value == "true" end
    return default
end

-- Default values are stored as "" (removed) to keep the project file clean
local function WriteExtFlag(getter, object, key, value, default)
    getter(object, key, value == default and "" or tostring(value), true)
end

local function ReadProjFlag(proj, key, default)
    local _, value = reaper.GetProjExtState(proj, SCRIPT_EXT, key)
    if value and value ~= "" then return value == "true" end
    return default
end

local function WriteProjFlag(proj, key, value, default)
    reaper.SetProjExtState(proj, SCRIPT_EXT, key, value == default and "" or tostring(value))
end

local function GetMarkerByGUID(proj, guid)
    if not HAS_MARKER_API then return nil end
    return reaper.GetRegionOrMarker(proj, -1, guid)
end

local function GetItemName(item)
    local take = reaper.GetActiveTake(item)
    if take then
        local _, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        return name or ""
    end
    local _, notes = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
    return notes or ""
end

local function SortByName(tab)
    table.sort(tab, function(a, b)
        local la, lb = a.name:lower(), b.name:lower()
        if la == lb then return a.order < b.order end
        return la < lb
    end)
end

local function GetItemsFromProject(proj, linked)
    local items = {}
    for i = 0, reaper.CountMediaItems(proj) - 1 do
        local item = reaper.GetMediaItem(proj, i)
        local selected
        if linked then selected = reaper.IsMediaItemSelected(item)
        else selected = ReadExtFlag(reaper.GetSetMediaItemInfo_String, item, P_EXT_SELECTED, false) end
        items[#items + 1] = {
            id = item, order = i, name = GetItemName(item), selected = selected,
            state = ReadExtFlag(reaper.GetSetMediaItemInfo_String, item, P_EXT_STATE, true)
        }
    end
    return items
end

local function GetTracksFromProject(proj, linked)
    local tracks = {}
    for i = 0, reaper.CountTracks(proj) - 1 do
        local track = reaper.GetTrack(proj, i)
        local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        local selected
        if linked then selected = reaper.IsTrackSelected(track)
        else selected = ReadExtFlag(reaper.GetSetMediaTrackInfo_String, track, P_EXT_SELECTED, false) end
        tracks[#tracks + 1] = {
            id = track, order = i, name = name or "", selected = selected,
            state = ReadExtFlag(reaper.GetSetMediaTrackInfo_String, track, P_EXT_STATE, true)
        }
    end
    return tracks
end

local function GetMarkersRegionsFromProject(proj, linked)
    local markers, regions = {}, {}
    local function Add(i, guid, isrgn, name, number, uisel)
        local selected
        if linked and HAS_MARKER_API then selected = uisel
        else selected = ReadProjFlag(proj, guid .. "_Selected", false) end
        local entry = {
            id = guid, order = i, name = name or "", number = number, selected = selected,
            state = ReadProjFlag(proj, guid .. "_State", true)
        }
        table.insert(isrgn and regions or markers, entry)
    end

    if HAS_MARKER_API then
        for i = 0, reaper.GetNumRegionsOrMarkers(proj) - 1 do
            local marker = reaper.GetRegionOrMarker(proj, i, "")
            if marker then
                local _, guid = reaper.GetSetRegionOrMarkerInfo_String(proj, marker, "GUID", "", false)
                local _, name = reaper.GetSetRegionOrMarkerInfo_String(proj, marker, "P_NAME", "", false)
                Add(i, guid,
                    reaper.GetRegionOrMarkerInfo_Value(proj, marker, "B_ISREGION") == 1,
                    name,
                    math.floor(reaper.GetRegionOrMarkerInfo_Value(proj, marker, "I_NUMBER")),
                    reaper.GetRegionOrMarkerInfo_Value(proj, marker, "B_UISEL") == 1)
            end
        end
    else
        local _, marker_count, region_count = reaper.CountProjectMarkers(proj)
        for i = 0, marker_count + region_count - 1 do
            local _, guid = reaper.GetSetProjectInfo_String(proj, "MARKER_GUID:" .. i, "", false)
            local retval, isrgn, _, _, name, number = reaper.EnumProjectMarkers3(proj, i)
            if retval > 0 then Add(i, guid, isrgn, name, number, false) end
        end
    end
    return markers, regions
end

local function ReadCategoryStates(proj)
    for _, key in ipairs(ORDER) do
        System.global_datas[key].state = ReadProjFlag(proj, key .. "_State", true)
    end
end

-- Read all userdatas for all types from project (only called when the project changed)
function System.GetUserdatas()
    local proj = System.project
    local linked = Settings.link_selection.value
    local datas = System.global_datas
    datas.items.data = GetItemsFromProject(proj, linked)
    datas.tracks.data = GetTracksFromProject(proj, linked)
    datas.markers.data, datas.regions.data = GetMarkersRegionsFromProject(proj, linked)

    local global_index = 0
    for _, key in ipairs(ORDER) do
        local data = datas[key].data
        if Settings.alphabetical_order.value then SortByName(data) end
        for _, userdata in ipairs(data) do
            global_index = global_index + 1
            userdata.index = global_index
        end
    end
end

function System.IsEmpty()
    for _, key in ipairs(ORDER) do
        if #System.global_datas[key].data > 0 then return false end
    end
    return true
end

-- Recompute every replaced name preview (only when rules, states or data changed)
function System.ComputePreviews()
    local any = false
    for _, key in ipairs(ORDER) do
        local category = System.global_datas[key]
        for _, userdata in ipairs(category.data) do
            local replaced = System.GetReplacedName(userdata.name)
            userdata.preview = replaced ~= userdata.name and replaced or nil
            if userdata.preview and category.state and userdata.state then any = true end
        end
    end
    System.one_renamed = any
end

local function CanLinkSelection(key)
    if not Settings.link_selection.value then return false end
    return key == "items" or key == "tracks" or HAS_MARKER_API
end

-- Pull selection from the project (link selection mode)
local function SyncSelectionFromProject()
    local proj = System.project
    local datas = System.global_datas
    for _, userdata in ipairs(datas.items.data) do
        if reaper.ValidatePtr2(proj, userdata.id, "MediaItem*") then userdata.selected = reaper.IsMediaItemSelected(userdata.id) end
    end
    for _, userdata in ipairs(datas.tracks.data) do
        if reaper.ValidatePtr2(proj, userdata.id, "MediaTrack*") then userdata.selected = reaper.IsTrackSelected(userdata.id) end
    end
    if HAS_MARKER_API then
        for _, key in ipairs({"markers", "regions"}) do
            for _, userdata in ipairs(datas[key].data) do
                local marker = GetMarkerByGUID(proj, userdata.id)
                if marker then userdata.selected = reaper.GetRegionOrMarkerInfo_Value(proj, marker, "B_UISEL") == 1 end
            end
        end
    end
end

-- Called once per frame
function System.Update()
    local proj, path = reaper.EnumProjects(-1)
    if proj ~= System.project or path ~= project_path then
        System.project, project_path = proj, path
        data_dirty = true
    end

    local state_count = reaper.GetProjectStateChangeCount(proj)
    if state_count ~= project_state_count then
        project_state_count = state_count
        data_dirty = true
    end

    if data_dirty then
        ReadCategoryStates(proj)
        System.GetUserdatas()
        data_dirty = false
        preview_dirty = true
    elseif Settings.link_selection.value then
        local now = reaper.time_precise()
        if now - last_selection_sync > SELECTION_SYNC_INTERVAL then
            last_selection_sync = now
            SyncSelectionFromProject()
        end
    end

    local signature = RulesetSignature()
    if signature ~= ruleset_signature then
        ruleset_signature = signature
        preview_dirty = true
    end

    if preview_dirty then
        System.ComputePreviews()
        preview_dirty = false
    end
end
--#endregion

--#region Selection / state setters
function System.SetUserdataSelected(userdata, key, value)
    if userdata.selected == value and not CanLinkSelection(key) then return end
    userdata.selected = value
    local proj = System.project
    if CanLinkSelection(key) then
        if key == "items" then
            if reaper.ValidatePtr2(proj, userdata.id, "MediaItem*") then reaper.SetMediaItemSelected(userdata.id, value) end
        elseif key == "tracks" then
            if reaper.ValidatePtr2(proj, userdata.id, "MediaTrack*") then reaper.SetTrackSelected(userdata.id, value) end
        else
            local marker = GetMarkerByGUID(proj, userdata.id)
            if marker then reaper.SetRegionOrMarkerInfo_Value(proj, marker, "B_UISEL", value and 1 or 0) end
        end
        selection_touched = true
    else
        if key == "items" then
            if reaper.ValidatePtr2(proj, userdata.id, "MediaItem*") then
                WriteExtFlag(reaper.GetSetMediaItemInfo_String, userdata.id, P_EXT_SELECTED, value, false)
            end
        elseif key == "tracks" then
            if reaper.ValidatePtr2(proj, userdata.id, "MediaTrack*") then
                WriteExtFlag(reaper.GetSetMediaTrackInfo_String, userdata.id, P_EXT_SELECTED, value, false)
            end
        else
            WriteProjFlag(proj, userdata.id .. "_Selected", value, false)
        end
    end
end

function System.SetUserdataState(userdata, key, value)
    userdata.state = value
    local proj = System.project
    if key == "items" then
        if reaper.ValidatePtr2(proj, userdata.id, "MediaItem*") then
            WriteExtFlag(reaper.GetSetMediaItemInfo_String, userdata.id, P_EXT_STATE, value, true)
        end
    elseif key == "tracks" then
        if reaper.ValidatePtr2(proj, userdata.id, "MediaTrack*") then
            WriteExtFlag(reaper.GetSetMediaTrackInfo_String, userdata.id, P_EXT_STATE, value, true)
        end
    else
        WriteProjFlag(proj, userdata.id .. "_State", value, true)
    end
    preview_dirty = true
end

function System.SetCategoryState(key, value)
    System.global_datas[key].state = value
    WriteProjFlag(System.project, key .. "_State", value, true)
    preview_dirty = true
end

-- Apply state to every selected userdata
function System.SetSelectedUserdatasState(value)
    for _, key in ipairs(ORDER) do
        for _, userdata in ipairs(System.global_datas[key].data) do
            if userdata.selected then System.SetUserdataState(userdata, key, value) end
        end
    end
end

-- Refresh arrange/timeline after selection changes in link mode
function System.FlushSelection()
    if selection_touched then
        selection_touched = false
        reaper.UpdateArrange()
        reaper.UpdateTimeline()
    end
end

-- Select every userdata (shown trees only)
function System.SelectAllUserdata()
    for _, key in ipairs(ORDER) do
        local category = System.global_datas[key]
        if category.show then
            for _, userdata in ipairs(category.data) do
                System.SetUserdataSelected(userdata, key, true)
            end
        end
    end
    System.FlushSelection()
end

-- Clear data selection in GUI and project
function System.ClearUserdataSelection(except)
    for _, key in ipairs(ORDER) do
        for _, userdata in ipairs(System.global_datas[key].data) do
            if userdata ~= except then System.SetUserdataSelected(userdata, key, false) end
        end
    end
    System.FlushSelection()
end

-- Select userdatas between two global indexes (shown trees only)
function System.SelectUserdataRange(index_a, index_b)
    local first, last = math.min(index_a, index_b), math.max(index_a, index_b)
    for _, key in ipairs(ORDER) do
        local category = System.global_datas[key]
        if category.show then
            for _, userdata in ipairs(category.data) do
                if userdata.index >= first and userdata.index <= last then
                    System.SetUserdataSelected(userdata, key, true)
                end
            end
        end
    end
    System.FlushSelection()
end
--#endregion

--#region Shortcuts
-- Must be called inside main window (after ImGui.Begin)
function System.HandleShortcuts()
    local mods = ImGui.GetKeyMods(ctx)
    System.Ctrl = (mods & ImGui.Mod_Ctrl) ~= 0
    System.Shift = (mods & ImGui.Mod_Shift) ~= 0

    if not ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows) then return end
    if ImGui.IsAnyItemActive(ctx) then return end -- typing in an input text

    if System.Ctrl and ImGui.IsKeyPressed(ctx, ImGui.Key_A, false) then
        if #System.ruleset < 1 then System.last_selected_area = "userdata" end
        if System.IsEmpty() then System.last_selected_area = "rule" end
        if System.last_selected_area == "rule" then
            for _, rule in ipairs(System.ruleset) do rule.selected = true end
        else
            System.SelectAllUserdata()
        end
    end

    if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) then
        if System.last_selected_area == "rule" then
            System.ClearTableSelection(System.ruleset)
        else
            System.ClearUserdataSelection()
        end
    end
end
--#endregion

--#region Apply
local function RenameMarkerLegacy(proj, guid, name)
    local ok, index = reaper.GetSetProjectInfo_String(proj, "MARKER_INDEX_FROM_GUID:" .. guid, "", false)
    index = ok and tonumber(index)
    if not index or index < 0 then return false end
    local retval, isrgn, pos, rgnend, _, number, color = reaper.EnumProjectMarkers3(proj, index)
    if retval == 0 then return false end
    return reaper.SetProjectMarkerByIndex2(proj, index, isrgn, pos, rgnend, number, name, color, name == "" and 1 or 0)
end

local function RenameUserdata(proj, key, userdata, name)
    if key == "items" then
        if not reaper.ValidatePtr2(proj, userdata.id, "MediaItem*") then return false end
        local take = reaper.GetActiveTake(userdata.id)
        if take then
            reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
        else
            reaper.GetSetMediaItemInfo_String(userdata.id, "P_NOTES", name, true)
        end
        return true
    elseif key == "tracks" then
        if not reaper.ValidatePtr2(proj, userdata.id, "MediaTrack*") then return false end
        reaper.GetSetMediaTrackInfo_String(userdata.id, "P_NAME", name, true)
        return true
    else
        if HAS_MARKER_API then
            local marker = GetMarkerByGUID(proj, userdata.id)
            if not marker then return false end
            reaper.GetSetRegionOrMarkerInfo_String(proj, marker, "P_NAME", name, true)
            return true
        end
        return RenameMarkerLegacy(proj, userdata.id, name)
    end
end

-- Apply name replacement
function System.ApplyReplacedNames()
    local proj = System.project
    local count = 0
    local markers_changed = false

    reaper.Undo_BeginBlock2(proj)
    reaper.PreventUIRefresh(1)

    for _, key in ipairs(ORDER) do
        local category = System.global_datas[key]
        if category.state then
            for _, userdata in ipairs(category.data) do
                if userdata.state and userdata.preview then
                    if RenameUserdata(proj, key, userdata, userdata.preview) then
                        userdata.name = userdata.preview
                        userdata.preview = nil
                        count = count + 1
                        if key == "markers" or key == "regions" then markers_changed = true end
                    end
                end
            end
        end
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    if markers_changed then reaper.UpdateTimeline() end
    reaper.Undo_EndBlock2(proj, "Complete renamer: " .. count .. " element(s) renamed", -1)

    data_dirty = true
    return count
end
--#endregion

--#region Clean
-- Clean extstate from project .rpp file (all open projects, or only current one)
function System.CleanExtState(current_only)
    local function Clean(proj)
        for i = 0, reaper.CountMediaItems(proj) - 1 do
            local item = reaper.GetMediaItem(proj, i)
            reaper.GetSetMediaItemInfo_String(item, P_EXT_SELECTED, "", true)
            reaper.GetSetMediaItemInfo_String(item, P_EXT_STATE, "", true)
        end
        for i = 0, reaper.CountTracks(proj) - 1 do
            local track = reaper.GetTrack(proj, i)
            reaper.GetSetMediaTrackInfo_String(track, P_EXT_SELECTED, "", true)
            reaper.GetSetMediaTrackInfo_String(track, P_EXT_STATE, "", true)
        end
        -- Legacy storage (v1.0.x): one ext section per marker GUID
        local _, marker_count, region_count = reaper.CountProjectMarkers(proj)
        for i = 0, marker_count + region_count - 1 do
            local _, guid = reaper.GetSetProjectInfo_String(proj, "MARKER_GUID:" .. i, "", false)
            reaper.SetProjExtState(proj, guid, SCRIPT_EXT .. "_Selected", "")
            reaper.SetProjExtState(proj, guid, SCRIPT_EXT .. "_State", "")
        end
        -- Current storage: everything in the script section
        reaper.SetProjExtState(proj, SCRIPT_EXT, "", "")
    end

    if current_only then
        Clean(System.project)
        return
    end
    local index = 0
    local proj = reaper.EnumProjects(index)
    while proj do
        Clean(proj)
        index = index + 1
        proj = reaper.EnumProjects(index)
    end
end
--#endregion

return System
