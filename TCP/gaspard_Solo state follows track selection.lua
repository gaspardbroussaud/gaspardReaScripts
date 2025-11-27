--@description Solo state follows track selection
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Solo state follows track selection

-- Restoring solos
local function RestoreSolo()
    reaper.ShowConsoleMsg("\nEND")
    reaper.Main_OnCommand(40340, 0) -- Unsolo all tracks
end

-- Toggle button state in Reaper
local function SetButtonState(set)
    if set ~= 1 then
        RestoreSolo()
    end
    local _, _, sec, cmd, _, _, _ = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

-- Main loop
local function Loop()
    local track_count = reaper.CountTracks(0)

    reaper.PreventUIRefresh(1)
    for i = 1, track_count do
        local track = reaper.GetTrack(0, i - 1)
        local solo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO") == 1

        if reaper.IsTrackSelected(track) then
            if solo == false then
                reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 1)
            end
        else
            if solo == true then
                reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 0)
            end
        end
    end
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()

    reaper.defer(Loop)
end

reaper.defer(Loop)

reaper.atexit(SetButtonState)
