-- @description Minimize selected tracks and lock height
-- @author gaspard
-- @version 1.0.1
-- @about Minimize selected tracks and lock height
-- @changelog Updated minimized height to 25 by default (can be modified in script file)

local min_height = 25 -- CHANGE THIS VALUE TO DESIRED MIN HEIGHT (default REAPER min track height is 25)

local sel_track_count = reaper.CountSelectedTracks(0)
if sel_track_count > 0 then
    -- Get all seleceted tracks
    local tracks = {}
    for i = 0, sel_track_count - 1 do
        table.insert(tracks, reaper.GetSelectedTrack(0, i))
    end

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    -- Set height and lock
    for _, track in ipairs(tracks) do
        local locked = reaper.GetMediaTrackInfo_Value(track, "B_HEIGHTLOCK")
        if locked == 1 then
            reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 0)
            local height = reaper.GetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE")
            for j = 0, reaper.CountTracks(0) - 1 do
                local cur_height = reaper.GetMediaTrackInfo_Value(reaper.GetTrack(0, j), "I_TCPH")
                if cur_height > height then
                    height = cur_height
                    break
                end
            end
            reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", height)
        else
            reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", min_height)
            reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 1)
        end
    end

    reaper.Undo_EndBlock("Minimize selected tracks and lock height.", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.TrackList_AdjustWindows(true)
end
