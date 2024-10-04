-- @noindex
-- @description Set selected tracks in region render matrix for selected media items regions
-- @author gaspard
-- @version 1.0
-- @changelog Initial release.
-- @about Set selected tracks in region render matrix for selected media items regions.

function main()
    for i = 0, sel_item_count - 1 do
        item_start = reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "D_POSITION") + 0.000001
        
        for j = 0, sel_track_count - 1 do
            _, regionidx = reaper.GetLastMarkerAndCurRegion(0, item_start)
            _, _, _, _, _, rgnidx = reaper.EnumProjectMarkers(regionidx)
            reaper.SetRegionRenderMatrix(0, rgnidx, reaper.GetSelectedTrack(0, j), 1)
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

sel_item_count = reaper.CountSelectedMediaItems(0)
sel_track_count = reaper.CountSelectedTracks(0)

if sel_item_count ~= 0 then
    if sel_track_count ~= 0 then
        main()
    else
        reaper.MB("Please select at least one track.", "No track selected", 0)
    end
else
    reaper.MB("Please select at least one item.", "No item selected", 0)
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Set selected tracks in region render matrix for selected media items regions", -1)

