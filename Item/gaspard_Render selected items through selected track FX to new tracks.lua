--@description Render selected items through selected track FX to new tracks
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about
--  ### Render selected items through selected track FX to new tracks
--  - Select items (on one or several tracks) and select the track whose FX chain is used to render.
--  - For each track holding selected items, a new track is created right below it with the rendered items.
--  - Mono items are rendered mono, stereo items stereo, multichannel items keep their channel count.
--  - Original items and the selected track FX chain are left untouched.

local script_name = "Render selected items through selected track FX"

local CMD_APPLY_TRACK_FX = 40209 -- Item: Apply track/take FX to items
local CMD_APPLY_TRACK_FX_MONO = 40361 -- Item: Apply track/take FX to items (mono output)
local CMD_APPLY_TRACK_FX_MULTI = 41993 -- Item: Apply track/take FX to items (multichannel output)
local CMD_CROP_TO_ACTIVE_TAKE = 40131 -- Take: Crop to active take in items

-- Checks --------------------------------------------------------------
local sel_item_count = reaper.CountSelectedMediaItems(0)
if sel_item_count < 1 then
    reaper.MB("Please select at least one item.", script_name, 0)
    return
end

if reaper.CountSelectedTracks(0) ~= 1 then
    reaper.MB("Please select one track (its FX chain is used to render the items).", script_name, 0)
    return
end

local fx_track = reaper.GetSelectedTrack(0, 0)
local fx_count = reaper.TrackFX_GetCount(fx_track)
if fx_count < 1 then
    reaper.MB("The selected track has no FX.", script_name, 0)
    return
end
if reaper.GetMediaTrackInfo_Value(fx_track, "I_FXEN") == 0 then
    reaper.MB("The selected track FX chain is bypassed.", script_name, 0)
    return
end
local fx_track_nchan = math.floor(reaper.GetMediaTrackInfo_Value(fx_track, "I_NCHAN"))

-- Functions -----------------------------------------------------------
-- Group selected items by track (items without take are ignored), tracks sorted top to bottom
local function GetSelectedItemsByTrack()
    local groups, tracks = {}, {}
    for i = 0, sel_item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if reaper.GetActiveTake(item) then
            local track = reaper.GetMediaItemTrack(item)
            if not groups[track] then
                groups[track] = {}
                tracks[#tracks + 1] = track
            end
            table.insert(groups[track], item)
        end
    end
    table.sort(tracks, function(a, b)
        return reaper.GetMediaTrackInfo_Value(a, "IP_TRACKNUMBER") < reaper.GetMediaTrackInfo_Value(b, "IP_TRACKNUMBER")
    end)
    return tracks, groups
end

-- Insert a new track right below source track (stays in the same folder)
-- Returns the new track and the folder depth moved from the source track (0 if none)
local function InsertTrackBelow(source_track)
    local index = math.floor(reaper.GetMediaTrackInfo_Value(source_track, "IP_TRACKNUMBER")) -- 1-based = index of next track
    reaper.InsertTrackInProject(0, index, 0)
    local new_track = reaper.GetTrack(0, index)

    -- If source track closes a folder, move the folder end to the new track
    local folder_depth = reaper.GetMediaTrackInfo_Value(source_track, "I_FOLDERDEPTH")
    local moved_depth = 0
    if folder_depth < 0 then
        reaper.SetMediaTrackInfo_Value(new_track, "I_FOLDERDEPTH", folder_depth)
        reaper.SetMediaTrackInfo_Value(source_track, "I_FOLDERDEPTH", 0)
        moved_depth = folder_depth
    end

    local _, source_name = reaper.GetSetMediaTrackInfo_String(source_track, "P_NAME", "", false)
    local _, fx_track_name = reaper.GetSetMediaTrackInfo_String(fx_track, "P_NAME", "", false)
    if source_name == "" then source_name = "Track " .. math.floor(reaper.GetMediaTrackInfo_Value(source_track, "IP_TRACKNUMBER")) end
    if fx_track_name == "" then fx_track_name = "Track " .. math.floor(reaper.GetMediaTrackInfo_Value(fx_track, "IP_TRACKNUMBER")) end
    reaper.GetSetMediaTrackInfo_String(new_track, "P_NAME", source_name .. " (" .. fx_track_name .. " render)", true)
    reaper.SetTrackColor(new_track, reaper.GetTrackColor(source_track))
    return new_track, moved_depth
end

-- Number of channels the item plays (take channel mode taken into account), 2 for MIDI items
local function GetItemChannels(item)
    local take = reaper.GetActiveTake(item)
    if not take or reaper.TakeIsMIDI(take) then return 2 end
    -- I_CHANMODE: 0 normal, 1 reverse stereo, 2 downmix, 3 left, 4 right, 5-66 single channel, 67+ stereo channel pair
    local chan_mode = math.floor(reaper.GetMediaItemTakeInfo_Value(take, "I_CHANMODE"))
    if chan_mode >= 2 and chan_mode <= 66 then return 1 end
    if chan_mode >= 67 then return 2 end
    local source = reaper.GetMediaItemTake_Source(take)
    if not source then return 2 end
    return math.max(1, reaper.GetMediaSourceNumChannels(source))
end

-- Copy the selected track FX chain to a track (each FX keeps its own bypass/offline state)
local function CopyFXChain(dest_track)
    for fx = 0, fx_count - 1 do
        reaper.TrackFX_CopyToTrack(fx_track, fx, dest_track, fx, false)
    end
end

local function RemoveFXChain(track)
    for fx = reaper.TrackFX_GetCount(track) - 1, 0, -1 do
        reaper.TrackFX_Delete(track, fx)
    end
end

-- Duplicate an item on another track (new GUIDs, no group, unlocked: the copy is independent)
local function CopyItemToTrack(item, dest_track)
    local _, chunk = reaper.GetItemStateChunk(item, "", false)
    chunk = chunk:gsub("{%x+%-%x+%-%x+%-%x+%-%x+}", function() return reaper.genGuid("") end)
    local new_item = reaper.AddMediaItemToTrack(dest_track)
    reaper.SetItemStateChunk(new_item, chunk, false)
    reaper.SetMediaItemInfo_Value(new_item, "I_GROUPID", 0)
    reaper.SetMediaItemInfo_Value(new_item, "C_LOCK", 0)
    return new_item
end

-- Main ----------------------------------------------------------------
local source_tracks, items_by_track = GetSelectedItemsByTrack()
if #source_tracks == 0 then
    reaper.MB("The selected items have no take to render.", script_name, 0)
    return
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- Create render tracks bottom to top so track indexes stay valid
local new_items = {}
local render_tracks = {}
for i = #source_tracks, 1, -1 do
    local source_track = source_tracks[i]
    local render_track, moved_depth = InsertTrackBelow(source_track)
    CopyFXChain(render_track)
    render_tracks[#render_tracks + 1] = {track = render_track, source_track = source_track, moved_depth = moved_depth}
    for _, item in ipairs(items_by_track[source_track]) do
        local new_item = CopyItemToTrack(item, render_track)
        new_items[#new_items + 1] = {
            item = new_item,
            track = render_track,
            channels = GetItemChannels(item),
            take_count = reaper.CountTakes(new_item)
        }
    end
end

-- Render: apply track FX on the copies only, output matching the item channels.
-- Track channel count is set for each pass (multichannel output uses the track channel count).
local function ApplyFX(command, filter, track_nchan)
    reaper.SelectAllMediaItems(0, false)
    local any = false
    for _, new_item in ipairs(new_items) do
        if filter(new_item.channels) then
            reaper.SetMediaItemSelected(new_item.item, true)
            any = true
        end
    end
    if not any then return end
    for _, render in ipairs(render_tracks) do
        reaper.SetMediaTrackInfo_Value(render.track, "I_NCHAN", math.max(fx_track_nchan, track_nchan))
    end
    reaper.Main_OnCommand(command, 0)
end

ApplyFX(CMD_APPLY_TRACK_FX_MONO, function(channels) return channels == 1 end, 2)
ApplyFX(CMD_APPLY_TRACK_FX, function(channels) return channels == 2 end, 2)
local multi_counts, seen = {}, {}
for _, new_item in ipairs(new_items) do
    if new_item.channels > 2 and not seen[new_item.channels] then
        seen[new_item.channels] = true
        multi_counts[#multi_counts + 1] = new_item.channels
    end
end
for _, count in ipairs(multi_counts) do
    ApplyFX(CMD_APPLY_TRACK_FX_MULTI, function(channels) return channels == count end, count + count % 2)
end

-- Keep only the rendered take, remove copies that could not be rendered (no new take)
reaper.SelectAllMediaItems(0, false)
local failed = 0
for _, new_item in ipairs(new_items) do
    if reaper.CountTakes(new_item.item) > new_item.take_count then
        reaper.SetMediaItemSelected(new_item.item, true)
    else
        reaper.DeleteTrackMediaItem(new_item.track, new_item.item)
        failed = failed + 1
    end
end
reaper.Main_OnCommand(CMD_CROP_TO_ACTIVE_TAKE, 0)

-- Remove the copied FX so the rendered items are not processed twice.
-- Render tracks left empty are deleted (folder end given back to the source track).
for _, render in ipairs(render_tracks) do
    RemoveFXChain(render.track)
    reaper.SetMediaTrackInfo_Value(render.track, "I_NCHAN", 2)
    if reaper.CountTrackMediaItems(render.track) == 0 then
        -- Folder end back to the source track before deleting (render track set to depth 0 first
        -- so REAPER does not carry its folder end over to the source track a second time)
        reaper.SetMediaTrackInfo_Value(render.track, "I_FOLDERDEPTH", 0)
        if render.moved_depth < 0 then
            reaper.SetMediaTrackInfo_Value(render.source_track, "I_FOLDERDEPTH", render.moved_depth)
        end
        reaper.DeleteTrack(render.track)
    else
        -- Keep enough channels for multichannel rendered items
        local nchan = 2
        for _, new_item in ipairs(new_items) do
            if new_item.track == render.track and reaper.ValidatePtr2(0, new_item.item, "MediaItem*") then
                nchan = math.max(nchan, new_item.channels + new_item.channels % 2)
            end
        end
        reaper.SetMediaTrackInfo_Value(render.track, "I_NCHAN", nchan)
    end
end

-- Keep the selected track selected, rendered items selected
reaper.SetOnlyTrackSelected(fx_track)

reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()
reaper.Undo_EndBlock(script_name, -1)

if failed > 0 then
    reaper.MB(failed .. " item(s) could not be rendered and were not added.", script_name, 0)
end
