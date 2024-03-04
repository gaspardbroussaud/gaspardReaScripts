--@description Move cluster of items with space between
--@author gaspard
--@version 1.1
--@changelog
-- Added user input for interval between items in cluster.
--@about
-- Move clusters of selected items to align them with same inbetween space in seconds.

-- GET INPUTS FROM USER --
function inputDatas()
    defaultDatas = "10, 0"
    isNotCanceled, retvals_csv = reaper.GetUserInputs("Move clusters data", 2, "Seconds between clusters = ,Cluster interval between items = ", defaultDatas)
    if isNotCanceled == true then
        secondsVal, interVal = retvals_csv:match("(.+),(.+)")
        findClusterRegion()
    end
end

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
    
    clusterPosTab = {}
    clusterEndTab = {}
    clusterTab = {}
    clusterIndex = 0
    
    if interVal == 0 then
        interVal = 0.000001
    end
end

-- GET INFOS FOR CLUSTER START AND END POS --
function getClustersInfos(startCluster, endCluster)
    clusterPosTab[clusterIndex] = startCluster
    clusterEndTab[clusterIndex] = endCluster
    clusterIndex = clusterIndex + 1
end

-- CREATE REGION FOR CLUSTERS --
function getClusters()
    setupVariables()

    for i = 0, selected_items_count - 1 do
    
        cur_item = reaper.GetSelectedMediaItem(0, i)
        
        cur_item_start_pos = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION")
        cur_item_end_pos = cur_item_start_pos + reaper.GetMediaItemInfo_Value(cur_item, "D_LENGTH")
        
        if prev_item_end_pos + interVal < cur_item_start_pos then
        
            getClustersInfos(first_item_start_pos, prev_item_end_pos)
            
            first_item_start_pos = cur_item_start_pos
            first_item = cur_item
        end
            
        if i == selected_items_count - 1 then
            if prev_item_end_pos > cur_item_end_pos then
                last_item_end_pos = prev_item_end_pos
            else
                last_item_end_pos = cur_item_end_pos
            end
            
            getClustersInfos(first_item_start_pos, last_item_end_pos)
            
        end
        
        if prev_item_end_pos > cur_item_end_pos then
            --nothing
        else
            prev_item_end_pos = cur_item_end_pos
        end
    end
    
end

-- MOVE CLUSTERS FUNCTION --
function getClusterItemsData(clusterIdx)
    clusterItemsTab = {}
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.Main_OnCommand(40635, 0) -- Unselect time selection
    reaper.GetSet_LoopTimeRange2(0, true, false, clusterPosTab[clusterIdx], clusterEndTab[clusterIdx], false)
    reaper.Main_OnCommand(40717, 0) -- Select all items in time selection
    
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local itemCluster = reaper.GetSelectedMediaItem(0, i)
        clusterItemsTab[i] = itemCluster
    end
    
    clusterTab[clusterIdx] = clusterItemsTab
end

-- MOVE ITEMS IN CLUSTERS --
function moveClusters(moveIdx)
    clusterItemsTab = clusterTab[moveIdx]
    
    for i in pairs(clusterItemsTab) do
        local itemCluster = clusterTab[moveIdx][i]
        local itemClusterPos = reaper.GetMediaItemInfo_Value(itemCluster, "D_POSITION")
        local inbetweenSpace = clusterPosTab[moveIdx] - prevClusterEnd
        
        if inbetweenSpace == tonumber(secondsVal) then
            newitemClusterPos = itemClusterPos
        elseif inbetweenSpace < tonumber(secondsVal) then
            newitemClusterPos = itemClusterPos - inbetweenSpace + secondsVal
        else
            newitemClusterPos = itemClusterPos - inbetweenSpace + secondsVal
        end
        
        reaper.SetMediaItemInfo_Value(itemCluster, "D_POSITION", newitemClusterPos)
        reaper.SetMediaItemSelected(itemCluster, true)
    end
    reaper.Main_OnCommand(40635, 0) -- Unselect time selection
    reaper.Main_OnCommand(40290, 0) -- Set time selection to selected items
    _, prevClusterEnd = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
end

-- MOVE CLUSTERS LOOP --
function moveClustersLoop()
    for i in ipairs(clusterPosTab) do
        getClusterItemsData(i)
    end

    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.Main_OnCommand(40635, 0) -- Unselect time selection
    
    prevClusterEnd = clusterEndTab[0]
    
    for i in ipairs(clusterPosTab) do
        moveClusters(i)
    end
    
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.Main_OnCommand(40635, 0) -- Unselect time selection
end

-- MAIN --
function findClusterRegion()
    if reaper.CountSelectedMediaItems(0) > 0 then
        
        reaper.Undo_BeginBlock() -- Start of undo block
        
        reaper.Main_OnCommand(40001, 0) -- Create new track
    
        createNoteItems()
    
        getClusters()
    
        reaper.Main_OnCommand(40005, 0) -- Delete created track
        
        reaper.Main_OnCommand(40289, 0) -- Unselect all items
        
        moveClustersLoop()
        
        reaper.Undo_EndBlock("Move clusters of selected items", -1) -- End of undo block
    end
end

-- MAIN FUNCTION --
function main()
    selected_items_count = reaper.CountSelectedMediaItems(0)
    if selected_items_count ~= 0 then
        inputDatas()
    else
        reaper.ShowMessageBox("Please select at least one item", "No items selected", 0)
    end
end

-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.ClearConsole()
msg = reaper.ShowConsoleMsg
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
