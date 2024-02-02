-- @description Rename track with selected media item name on it
-- @author gaspard
-- @version 1.0
-- @about
--    Renames the track of the selected media item with it's name (or last item's name if multiple selected).

-- Begin undo-block
reaper.Undo_BeginBlock2(0)

-- Print function
function print(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

-- Loop through all selected items
for i = 0, reaper.CountSelectedMediaItems()-1 do
  
  -- Get item
  item = reaper.GetSelectedMediaItem(0, i)
  
  -- Get active take of item
  active_take = reaper.GetActiveTake(item)
    
  -- Get track
  track = reaper.GetMediaItem_Track(item)
  
  -- Get take name
  retval, take_name = reaper.GetSetMediaItemTakeInfo_String(active_take, 'P_NAME', "", false)
  
  -- Apply new name
  reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', take_name, true)
end

-- End undo-block
reaper.Undo_EndBlock2(0,"Script: Set selected items active takes name to track name",-1)
