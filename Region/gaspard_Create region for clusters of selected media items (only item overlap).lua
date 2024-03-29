-- @description Create region for clusters of selected media items (only item overlap)
-- @author gaspard
-- @version 1.1
-- @changelog
--    v1.1 Fix incorrect cluster when cur item end position inferior to previous item end position.
--    v1.0 Initial release.
-- @about
--    This scripts creates a region around each selected media items. If the regions overlap, they are
--    created as only one region.
--
--    It does so by creating a track on witch it duplicates and overlaps all selected items and checks
--    if they overlap. It merges the overlapping ones, creates a region around items and deletes track.
--


-- CREATE TEXT ITEMS --
function CreateTextItem(track, position, length)

  local item = reaper.AddMediaItemToTrack(track)

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
  
  return item

end


-- TABLE INIT --
local setSelectedMediaItem = {}

-- MAIN --
function createNoteItems()

  selected_tracks_count = reaper.CountSelectedTracks(0)

  if selected_tracks_count > 0 then

    -- DEFINE TRACK DESTINATION
    selected_track = reaper.GetSelectedTrack(0,0)

    -- COUNT SELECTED ITEMS
    selected_items_count = reaper.CountSelectedMediaItems(0)

    if selected_items_count > 0 then

      --reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

      -- SAVE TAKES SELECTION
      for j = 0, selected_items_count-1  do
        setSelectedMediaItem[j] = reaper.GetSelectedMediaItem(0, j)
      end

      -- LOOP THROUGH TAKE SELECTION
      for i = 0, selected_items_count-1  do
        -- GET ITEMS AND TAKES AND PARENT TRACK
        item = setSelectedMediaItem[i] -- Get selected item i

        -- TIMES
        item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        item_duration = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        -- ACTION
        CreateTextItem(selected_track, item_start, item_duration)

      end -- ENDLOOP through selected items
      reaper.Main_OnCommand(40421, 0)
      --reaper.Undo_EndBlock("Create text items on first selected track from selected items notes", -1) -- End of the undo block. Leave it at the bottom of your main function.
    else -- no selected item
      reaper.ShowMessageBox("Select at least one item","Please",0)
    end -- if select item
  else -- no selected track
    reaper.ShowMessageBox("The scriptmet an error when trying to acces created track for note items","Error",0)
  end -- if selected track
end

-- VARIABLE SETUP --
function setupVariables()
    
    selected_items_count = reaper.CountSelectedMediaItems(0)
    
    first_item = reaper.GetSelectedMediaItem(0, 0)
    
    first_item_start_pos = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
    
    prev_item_end_pos = first_item_start_pos
    
end

-- CREATE CLUSTER REGION --
function createGroupsRegion()

    setupVariables()
    
    for i = 0, selected_items_count - 1 do
    
        cur_item = reaper.GetSelectedMediaItem(0, i)
        
        cur_item_start_pos = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION")
        cur_item_end_pos = cur_item_start_pos + reaper.GetMediaItemInfo_Value(cur_item, "D_LENGTH")
        
        if prev_item_end_pos - 0.000001 < cur_item_start_pos and i ~= 0 then
            
            reaper.AddProjectMarker(0, true, first_item_start_pos, prev_item_end_pos, "", -1)
            first_item_start_pos = cur_item_start_pos
            --prev_item_end_pos = cur_item_start_pos + reaper.GetMediaItemInfo_Value(cur_item, "D_LENGTH")
            
        end
            
        if i == selected_items_count - 1 then
            if prev_item_end_pos > cur_item_end_pos then
                last_item_end_pos = prev_item_end_pos
            else
                last_item_end_pos = cur_item_end_pos
            end
            
            --reaper.AddProjectMarker(0, true, first_item_start_pos, prev_item_end_pos, "", -1)
            reaper.AddProjectMarker(0, true, first_item_start_pos, last_item_end_pos, "", -1)
        
        end
        
        if prev_item_end_pos > cur_item_end_pos then
            --nothing
        else
            prev_item_end_pos = cur_item_end_pos
        end
        
    end
    
end

-- MAIN EXECUTION --
function main()
    if reaper.CountSelectedMediaItems(0) > 0 then
        
        reaper.Undo_BeginBlock() -- Start of undo block
        
        reaper.Main_OnCommand(40001, 0) -- Create new track
    
        createNoteItems()
    
        createGroupsRegion()
    
        reaper.Main_OnCommand(40005, 0) -- Delete created track
        
        reaper.Undo_EndBlock("Create region for selected clusters of items", -1) -- End of undo block
    --else
        --reaper.ShowMessageBox("No item selected", "Item selection error", 0)
    end
end


-- SCRIPT START --
reaper.PreventUIRefresh(1)

main()

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)
-- SCRIPT END --


---------------------------------------------------------------------------------------------
--reaper.Main_OnCommand(40914, 0) -- Select first track as last touched