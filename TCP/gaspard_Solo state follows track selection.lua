--@description Solo state follows track selection
--@author gaspard
--@version 1.0.1
--@changelog Restore solo states when exiting
--@about Solo state follows track selection

local restore_list = {}
local solo_type = 2 -- Solo in place == 2 ; Solo (ignore routing) == 1

-- Restoring solos
local function RestoreSolo()
    reaper.Main_OnCommand(40340, 0) -- Unsolo all tracks
    for i, element in ipairs(restore_list) do
        local track = reaper.BR_GetMediaTrackByGUID(0, element.GUID)
        if track then
            reaper.SetMediaTrackInfo_Value(track, "I_SOLO", element.solo_type)
        end
    end
end

-- Toggle button state in Reaper
local function SetButtonState(set)
    if set ~= 1 then RestoreSolo() end
    local _, _, sec, cmd, _, _, _ = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

-- Main loop
local function Loop()
    local track_count = reaper.CountTracks(0)

    reaper.PreventUIRefresh(1)
    for i = 1, track_count do
        local track = reaper.GetTrack(0, i - 1)
        local solo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO") == solo_type

        if reaper.IsTrackSelected(track) then
            if solo == false then
                reaper.SetMediaTrackInfo_Value(track, "I_SOLO", solo_type)
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

-- Execution
SetButtonState(1)

local track_count = reaper.CountTracks(0)
for i = 1, track_count do
    local track = reaper.GetTrack(0, i - 1)
    local solo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
    if solo > 0 then
        restore_list[#restore_list+1] = {GUID = reaper.GetTrackGUID(track), solo_type = solo}
    end
end

reaper.defer(Loop)

reaper.atexit(SetButtonState)
