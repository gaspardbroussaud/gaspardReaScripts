-- @noindex
-- @description Set track of selected media items in region render matrix for respective regions
-- @author gaspard
-- @version 1.0
-- @about
--      Sets selected media items' track in region render matrix for their respective regions.

function trackToRRM()

    reaper.Undo_BeginBlock()
    
    selected_items_count = reaper.CountSelectedMediaItems(0)
    
    for i = 0, selected_items_count - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        
        if item ~= nil then
            item_startPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + 0.000001
            --item_midLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") // 2
            --item_midPos = item_startPos + item_midLength
            
            track = reaper.GetMediaItemTrack(item)
            
            _, regionidx = reaper.GetLastMarkerAndCurRegion(0, item_startPos)
            _, _, _, _, regionName, regionIndex = reaper.EnumProjectMarkers( regionidx )
            reaper.SetRegionRenderMatrix(0, regionIndex, track, 1)
        end
    end
  reaper.Undo_EndBlock("Set track of selected media items to region render matrix", -1)
  
end
  
reaper.PreventUIRefresh(1)

trackToRRM()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
