--@description Set all regions name to selected track name
--@author gaspard
--@version 1.0
--@changelog Initial release.
--@about This scripts sets project regions name to selected track name for selected items.

reaper.Undo_BeginBlock()

sel_item_count = reaper.CountSelectedMediaItems(0)
sel_track_count = reaper.CountSelectedTracks(0)
_, _, rgn_count = reaper.CountProjectMarkers(0)

if sel_item_count ~= 0 then
    if rgn_count ~= 0 then
        if sel_track_count ~= 0 and sel_track_count < 2 then
             _, name = reaper.GetSetMediaTrackInfo_String(reaper.GetSelectedTrack(0, 0), "P_NAME", "", false)
             
            for i = 0, sel_item_count - 1 do
                item = reaper.GetSelectedMediaItem(0, i)
                item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                
                _, regionidx = reaper.GetLastMarkerAndCurRegion(0, item_start)
                
                _, isrgn, pos, rgnend, _, rgnindex = reaper.EnumProjectMarkers2(0, regionidx)
                
                if name == "" then
                    reaper.SetProjectMarker4(0, rgnindex, isrgn, pos, rgnend, name, 0, 1)
                else
                    reaper.SetProjectMarker2(0, rgnindex, isrgn, pos, rgnend, name)
                end
            end
        else
            reaper.MB("Please select one track.", "Error in track selection", 0)
        end
    else
        reaper.MB("There are no regions in project.\nScript terminated.", "No region in project", 0)
    end
else
    reaper.MB("Please select at least one item.", "No item selected", 0)
end

reaper.Undo_EndBlock("Region name set to selected track", -1)
