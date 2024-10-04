-- @noindex
-- @description Create region for each selected media item
-- @author gaspard
-- @version 1.0
-- @about
--   Creates a unique region for each selected media item. Region takes item's active take's name. Overlap possible.

-- CREATE REGION FOR EACH ITEM --
function createRegion()

    reaper.Undo_BeginBlock()
    
    selected_items_count = reaper.CountSelectedMediaItems(0)
    
    for i = 0, selected_items_count-1 do
        item = reaper.GetSelectedMediaItem(0, i)
        take = reaper.GetActiveTake(item)
        
        if item == 0 then
            reaper.ShowMessageBox("No items selected", "Error message", 0)
        end
        if item ~= nil then
            take_name = reaper.GetTakeName(take)
        
            local item_startPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local item_endPos = item_startPos + item_length
            
            local take_color = reaper.GetDisplayedMediaItemColor2( item, take )
            
            track =  reaper.GetMediaItemTrack( item )
            retval, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "test", false)
            
            regionID = reaper.AddProjectMarker2(0, true, item_startPos, item_endPos, take_name, -1, take_color)
            
            --reaper.SetRegionRenderMatrix(0, regionID, track, 1)
        end
    end
  reaper.Undo_EndBlock("Set Track of Selected Media items to Region Render Matrix", -1)
  
end

-- SCRIPT RUN --
reaper.PreventUIRefresh(1)

createRegion()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
