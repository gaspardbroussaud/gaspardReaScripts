-- @noindex
-- @description Get clusters of selected items with text items on new track
-- @author gaspard
-- @version 1.0
-- @changelog
--  Initial release.
-- @about
--  Template for item cluster detection.  
--  Creates text items of selected items on new track for cluster identification.
--  Copy and add script in lines 104 and 117 (if script in template state) to do something on clusters.

-- CREATE TEXT ITEMS -- Credit to X-Raym
function CreateTextItem(track, position, length, parentTrackName)

  local item = reaper.AddMediaItemToTrack(track)

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
  reaper.GetSetMediaItemInfo_String(item, "P_NOTES", parentTrackName, true)
  
  return item

end

-- TABLE INIT -- Credit to X-Raym
local setSelectedMediaItem = {}

-- CREATE NOTE ITEMS -- Credit to X-Raym
function createNoteItems()

  selected_tracks_count = reaper.CountSelectedTracks(0)

  if selected_tracks_count > 0 then

    -- DEFINE TRACK DESTINATION
    selected_track = reaper.GetSelectedTrack(0,0)

    -- COUNT SELECTED ITEMS
    selected_items_count = reaper.CountSelectedMediaItems(0)

    if selected_items_count > 0 then

      -- SAVE TAKES SELECTION
      for j = 0, selected_items_count-1  do
        setSelectedMediaItem[j] = reaper.GetSelectedMediaItem(0, j)
      end

      -- LOOP THROUGH TAKE SELECTION
      for i = 0, selected_items_count-1  do
        -- GET ITEMS AND TAKES AND PARENT TRACK
        item = setSelectedMediaItem[i] -- Get selected item i
        item_track = reaper.GetMediaItemTrack(item)
        item_parent_track = reaper.GetParentTrack(item_track)
        if item_parent_track ~= nil then
            if isTopParentName then
                track_top_parent = getTopParentTrack(item_parent_track)
            else
                track_top_parent = item_parent_track
            end
            _, item_parent_track_name = reaper.GetSetMediaTrackInfo_String(track_top_parent, "P_NAME", "", false)
        else
            item_parent_track_name = "MasterTrack"
        end

        -- TIMES
        item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        item_duration = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        -- ACTION
        CreateTextItem(selected_track, item_start, item_duration, item_parent_track_name)

      end -- ENDLOOP through selected items
      reaper.Main_OnCommand(40421, 0) -- Create text items on first selected track from selected items notes
    else -- no selected item
      reaper.ShowMessageBox("Select at least one item","Please",0)
    end -- if select item
  else -- no selected track
    reaper.ShowMessageBox("The script met an error when trying to access created track for note items","Error",0)
  end -- if selected track
end

-- SETUP ALL VARIABLES FOR CLUSTERS --
function setupVariables()
    
    first_item = reaper.GetSelectedMediaItem(0, 0)
    
    first_item_start_pos = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
    
    prev_item_end_pos = first_item_start_pos
end

-- CREATE REGION FOR CLUSTERS --
function createGroupsRegion()
    setupVariables()

    for i = 0, selected_items_count - 1 do
    
        cur_item = reaper.GetSelectedMediaItem(0, i)
        
        cur_item_start_pos = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION")
        cur_item_end_pos = cur_item_start_pos + reaper.GetMediaItemInfo_Value(cur_item, "D_LENGTH")
        
        if prev_item_end_pos + 0.0000001 < cur_item_start_pos then
        
            -- A cluster is detected : YOUR SCRIPT HERE
            
            first_item_start_pos = cur_item_start_pos
            first_item = cur_item
        end
            
        if i == selected_items_count - 1 then
            if prev_item_end_pos > cur_item_end_pos then
                last_item_end_pos = prev_item_end_pos
            else
                last_item_end_pos = cur_item_end_pos
            end
            
            -- A cluster is detected : YOUR SCRIPT HERE
            
        end
        
        if prev_item_end_pos > cur_item_end_pos then
            --nothing
        else
            prev_item_end_pos = cur_item_end_pos
        end
    end
    
end

-- MAIN --
function createClusterRegion()
    if reaper.CountSelectedMediaItems(0) > 0 then
        
        reaper.Undo_BeginBlock() -- Start of undo block
        
        reaper.Main_OnCommand(40001, 0) -- Create new track
    
        createNoteItems()
    
        createGroupsRegion()
    
        reaper.Main_OnCommand(40005, 0) -- Delete created track
        
        reaper.Undo_EndBlock("Create region for selected clusters of items", -1) -- End of undo block
    end
end

-- MAIN FUNCTION --
function main()
    selected_items_count = reaper.CountSelectedMediaItems(0)
    if selected_items_count ~= 0 then
        createClusterRegion()
    else
        reaper.ShowMessageBox("Please select at least one item", "No items selected", 0)
    end
end

-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.ClearConsole()
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
