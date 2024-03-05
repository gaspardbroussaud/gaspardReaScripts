--@description Set all regions name to top parent track name
--@author gaspard
--@version 1.1
--@changelog Fix to clear name if empty.
--@about This scripts sets project regions name to top parent track names for selected items.

-- GET TOP PARENT TRACK --
local function getTopParentTrack(track)
  while true do
    local parent = reaper.GetParentTrack(track)
    if parent then
      track = parent
    else
      return track
    end
  end
end

reaper.Undo_BeginBlock()

sel_item_count = reaper.CountSelectedMediaItems(0)

if sel_item_count ~= nil then
    for i = 0, sel_item_count - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
        item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        _, regionidx = reaper.GetLastMarkerAndCurRegion(0, item_start)
        
        _, isrgn, pos, rgnend, name, rgnindex = reaper.EnumProjectMarkers2(0, regionidx)
        
        _, name = reaper.GetSetMediaTrackInfo_String(getTopParentTrack(reaper.GetMediaItemTrack(item)), "P_NAME", "", false)
        
        if name == "" then
            reaper.SetProjectMarker4(0, rgnindex, isrgn, pos, rgnend, name, 0, 1)
        else
            reaper.SetProjectMarker2(0, rgnindex, isrgn, pos, rgnend, name)
        end
    end
end

reaper.Undo_EndBlock("Region name set to parent track", -1)
