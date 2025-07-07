-- @noindex
-- @description Minimize selected tracks and lock height
-- @author gaspard
-- @version 1.1.0
-- @about Minimize selected tracks and lock height
-- @changelog Added order tracks to top as setting

local min_height = 25 -- CHANGE THIS VALUE TO DESIRED MIN HEIGHT (default REAPER min track height is 25)
local should_mute = true -- CHANGE THIS TO true OR false TO MUTE AND UNMUTE TRACKS
local order_to_top = true -- CHANGE THIS TO true OR false TO MOVE TRACKS TO TOP OF TCP

local sel_track_count = reaper.CountSelectedTracks(0)
if sel_track_count > 0 then
    -- Get all seleceted tracks
    local tracks = {}
    for i = 0, sel_track_count - 1 do
        local pos = #tracks < 1 and 1 or #tracks
        table.insert(tracks, pos, reaper.GetSelectedTrack(0, i))
    end

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    -- Set height and lock
    for i = 1, #tracks do
        local track = tracks[i]
        local locked = reaper.GetMediaTrackInfo_Value(track, "B_HEIGHTLOCK")
        reaper.SetOnlyTrackSelected(track)
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
            if should_mute then reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 0) end
            if order_to_top then
                local retval, index = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:TrackIndex:PreviousIndex", "", false)
                if not retval then index = 0 end
                local track_count = reaper.CountTracks(0)
                index = tonumber(index)
                if index > track_count then index = track_count end
                reaper.ReorderSelectedTracks(index, 0)
                reaper.GetSetMediaTrackInfo_String(track, "P_EXT:TrackIndex:PreviousIndex", "", true)
            end
        else
            reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", min_height)
            reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 1)
            if should_mute then reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 1) end
            if order_to_top then
                reaper.GetSetMediaTrackInfo_String(track, "P_EXT:TrackIndex:PreviousIndex", reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER"), true)
                reaper.ReorderSelectedTracks(0, 0)
            end
        end
    end

    for _, track in ipairs(tracks) do
        reaper.SetTrackSelected(track, true)
    end

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Minimize selected tracks and lock height.", -1)
    reaper.UpdateArrange()
    reaper.TrackList_AdjustWindows(true)
end
