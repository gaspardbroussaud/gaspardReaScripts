--@description Hide and show tracks in TCP and MCP
--@author gaspard
--@version 1.0.1
--@changelog
--  - Update nomenclature
--@about
--  #### Hide and show tracks in track manager.
--
--  How to use:
--  - To hide, select tracks in Track Control Panel and launch script.
--  - To show, select tracks in Track Manager window and launch script.
--
--  Only works with "Miror track selection" enabled in Track Manager window settings via right click.

-- LOCK OR UNLOCK TRACK --
function SetTrackLock(track, lockState)
    reaper.SetTrackSelected(track, true)

    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", lockState)

    lockState = math.abs(lockState - 1)
    reaper.Main_OnCommand(41312 + lockState, 0) -- Lock or unlock selected track

    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 0)

    reaper.SetTrackSelected(track, false)
end

-- SET TRACK STATE --
function SetTrackVisibility(track)
    if reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 0 then
        reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
        reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
        SetTrackLock(track, 0)
    elseif reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 1 then
        SetTrackLock(track, 1)
        reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
        reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 0)
    end
end

-- GET SELECTED TRACKS IN TABLE --
function GetSelectedTracks()
    local trackTab = {}
    local sel_track_count = reaper.CountSelectedTracks(0)

    for i = 0, sel_track_count - 1 do
        trackTab[i] = reaper.GetSelectedTrack(0, i)
    end

    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks

    for i = 0, #trackTab do
        SetTrackVisibility(trackTab[i])
    end
end

-- MAIN SCRIPT --
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local sel_track_count = reaper.CountSelectedTracks(0)

if sel_track_count ~= 0 then
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN2"), 0) -- Select all child tracks of selected tracks
    GetSelectedTracks()
else
    reaper.MB("Please select at least one track.", "No tracks selected", 0)
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Tracked hidden or shown", -1)
