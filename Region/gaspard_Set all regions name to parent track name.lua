--@description Set all regions name to parent track name
--@author gaspard
--@version 1.1.1
--@changelog
-- · Fix error in item selection detection.
-- · Fix error if there are no regions in project.
--@about This scripts sets project regions name to parent track names for selected items.

reaper.Undo_BeginBlock()

sel_item_count = reaper.CountSelectedMediaItems(0)
_, _, rgn_count = reaper.CountProjectMarkers(0)

if sel_item_count ~= 0 then
    if rgn_count ~= 0 then
        for i = 0, sel_item_count - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
            item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            _, regionidx = reaper.GetLastMarkerAndCurRegion(0, item_start)
            
            _, isrgn, pos, rgnend, name, rgnindex = reaper.EnumProjectMarkers2(0, regionidx)
            
            _, name = reaper.GetSetMediaTrackInfo_String(reaper.GetParentTrack(reaper.GetMediaItemTrack(item)), "P_NAME", "", false)
            
            if name == "" then
                reaper.SetProjectMarker4(0, rgnindex, isrgn, pos, rgnend, name, 0, 1)
            else
                reaper.SetProjectMarker2(0, rgnindex, isrgn, pos, rgnend, name)
            end
        end
    else
        reaper.MB("There are no regions in project.\nScript end.", "No region in project", 0)
    end
else
    reaper.MB("Please select at least one item.", "No item selected", 0)
end

reaper.Undo_EndBlock("Region name set to parent track", -1)
