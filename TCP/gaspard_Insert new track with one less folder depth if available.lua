-- @description Insert new track with one less folder depth if available
-- @author gaspard
-- @version 1.0
-- @about
--   # Insert new track with one less folder depth if available
-- @changelog
--   # Initial release

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  if reaper.CountSelectedTracks( 0 ) > 0 then
    -- Get selected track
    local sel_track = reaper.GetSelectedTrack(0,0)
    local sel_track_idx = reaper.GetMediaTrackInfo_Value( sel_track, "IP_TRACKNUMBER" )
    
    local folder_depth = reaper.GetMediaTrackInfo_Value( sel_track, "I_FOLDERDEPTH" )
    if sel_track_idx > 1 then
      parent_track = reaper.GetParentTrack(sel_track)
      if parent_track then
          parent_track_idx = reaper.GetMediaTrackInfo_Value( parent_track, "IP_TRACKNUMBER" )
      end
    end
    
    -- dbg(tostring("Selected track folder depth: " .. folder_depth))
    -- dbg(tostring("Previous track folder depth: " .. folder_depth_prev_track))
     
    -- Last track in folder/nested folder
    if folder_depth < 0 and parent_track then
    
       -- Insert new track above selected
       reaper.InsertTrackAtIndex( parent_track_idx - 1, true )
       local new_track = reaper.GetTrack(0, parent_track_idx - 1 )
       
       -- Move new track below originally selected track
       reaper.SetOnlyTrackSelected( parent_track )
       reaper.ReorderSelectedTracks( parent_track_idx - 1, 0 )
       
       -- Select new track
       reaper.SetOnlyTrackSelected( new_track )
       
    end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Deliver messages and add new line in console
function dbg(dbg)
  reaper.ShowConsoleMsg(dbg .. "\n")
end

-- Deliver messages using message box
function msg(msg)
  reaper.MB(msg, script_name, 0)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
