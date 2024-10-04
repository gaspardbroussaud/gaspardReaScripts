-- @noindex
-- @description Set parent track in region render matrix for selected media items regions
-- @author gaspard
-- @version 1.0
-- @about
--      Sets the parent track of the selected media items track in region render matrix for media items region.

function trackToParentRRM()

    reaper.Undo_BeginBlock()
    
    selected_items_count = reaper.CountSelectedMediaItems(0)
    
    for i = 0, selected_items_count - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        
        if item ~= nil then
            item_startPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + 0.000001
            
            track = reaper.GetMediaItemTrack(item)
            
            parentTrack = reaper.GetParentTrack(track)
            
            _, regionidx = reaper.GetLastMarkerAndCurRegion(0, item_startPos)
            _, _, _, _, _, regionIndex = reaper.EnumProjectMarkers(regionidx)
            if parentTrack == nil then
                masterTrack = reaper.GetMasterTrack(0)
                reaper.SetRegionRenderMatrix(0, regionIndex, masterTrack, 1)
            else
                reaper.SetRegionRenderMatrix(0, regionIndex, parentTrack, 1)
            end
        end
    end
  reaper.Undo_EndBlock("Set Parent Track of Selected Media items' Track to Region Render Matrix", -1)
  
end
  
reaper.PreventUIRefresh(1)

trackToParentRRM()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
