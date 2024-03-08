--@description Mute track and hide in TCP and MCP
--@author gaspard
--@version 1.0
--@changelog Initial release.
--@about Mute and hide in TCP and MCP all selected tracks. Hide children from TCP and MCP if selected track is parent.

-- HIDE and MUTE TRACK --
function hideMute(track, mute)
    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", mute)
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 0)
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
end

-- MAIN FUNCTION --
function main()
    trackTab = {}
    
    for i = 0, sel_track_count - 1 do
        trackTab[i] = reaper.GetSelectedTrack(0, i)
    end
    
    reaper.Main_OnCommand(40297, 0) --Clear selection of all tracks
    
    for i = 0, #trackTab do
        if reaper.GetMediaTrackInfo_Value(trackTab[i], "I_FOLDERDEPTH") == 1 then
            reaper.SetTrackSelected(trackTab[i], true)
            
            -- Select only children of selected folders --
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN"), 0)
            
            reaper.SetTrackSelected(trackTab[i], false)
            
            local children_count = reaper.CountSelectedTracks(0)
            for i = 0, children_count - 1 do
                local child_track = reaper.GetSelectedTrack(0, i)
                hideMute(child_track, 0)
            end
            
            reaper.Main_OnCommand(40297, 0) --Clear selection of all tracks
            hideMute(trackTab[i], 1)
            
        else
            hideMute(trackTab[i], 1)
        end
    end
end

-- SETUP VARIABLES --
sel_track_count = reaper.CountSelectedTracks(0)

-- MAIN SCRIPT EXECUTION --
if sel_track_count ~= 0 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    main()
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Mute and hide TCP and MCP for selected tracks", -1)
else
    reaper.MB("Please select at least one track.", "No selected track", 0)
end
