--@description Add ReaLimit to selected tracks with ceiling at current peak volume
--@author gaspard
--@version 1.0
--@changelog Init
--@about
--  - Add ReaLimit to selected tracks with ceiling at current peak volume

local proj = select(2, reaper.EnumProjects(-1))
local selected_tracks_count = reaper.CountSelectedTracks(proj) or 0
if selected_tracks_count > 0 then
    local tracks = {}
    for i = 1, selected_tracks_count do
        tracks[i] = reaper.GetSelectedTrack(proj, i - 1)
    end
    if tracks then
        local ceiling_param = 1
        for _, track in ipairs(tracks) do
            local peak = ((reaper.Track_GetPeakHoldDB(track, 0, false) * 100) + 24) / 24
            if peak > 1 then
                local fx_index = reaper.TrackFX_AddByName(track, "VST: ReaLimit (Cockos)", false, 1)
                reaper.TrackFX_SetParam(track, fx_index, ceiling_param, 1 - (peak - 1))
                reaper.Track_GetPeakHoldDB(track, 0, true)
            end
        end
    end
end
