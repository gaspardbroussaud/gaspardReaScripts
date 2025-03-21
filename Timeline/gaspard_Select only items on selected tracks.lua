-- @description Select only items on selected tracks
-- @author gaspard
-- @version 1.0
-- @about Select only items on selected tracks
-- @changelog Initial release

local item_list = {}

local sel_track_count = reaper.CountSelectedTracks(0)
if sel_track_count > 0 then
    for i = 0, sel_track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        local item_count = reaper.CountTrackMediaItems(track)
        if item_count > 0 then
            for j = 0, item_count - 1 do
                table.insert(item_list, reaper.GetTrackMediaItem(track, j))
            end
        end
    end
end

if #item_list > 0 then
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items

    for _, item in ipairs(item_list) do
        reaper.SetMediaItemSelected(item, true)
    end

    reaper.Undo_EndBlock("Inserted tracks using clipboard.", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end
