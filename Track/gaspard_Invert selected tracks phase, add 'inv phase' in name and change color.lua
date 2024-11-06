--@description Invert selected tracks phase, add 'inv phase' in name and change color
--@author gaspard
--@version 1.0.0
--@changelog Initial release
--@about Invert selected tracks phase, add 'inv phase' in name and change color

-- USER VALUES -- Set to 'true' to enable or 'false' to disable -----------
local name_change = true -- Add 'inv phase' to track name
local color_change = true -- Change track color
---------------------------------------------------------------------------

-- MAIN FUNCTION EXECUTION
function Main()
    local track_count = reaper.CountSelectedTracks(0)
    if track_count > 0 then
        -- Get selected tracks in table
        local tracks = {}
        for i = 0, track_count - 1 do
            tracks[i] = reaper.GetSelectedTrack(0, i)
        end

        -- Manipulate table tracks
        for i = 0, #tracks do
            -- Invert phase
            reaper.SetMediaTrackInfo_Value(tracks[i], "B_PHASE", 1)

            -- Add 'inv phase' in name
            if name_change then
                local _, track_name = reaper.GetSetMediaTrackInfo_String(tracks[i], "P_NAME", "", false)
                track_name = tostring(track_name).." inv phase"
                _, _ = reaper.GetSetMediaTrackInfo_String(tracks[i], "P_NAME", track_name, true)
            end

            -- Change track color
            if color_change then
                reaper.SetTrackColor(tracks[i], 23302008) -- Color Green
            end
        end
    end
end

-- SCRIPT EXECUTION
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Invert selected tracks phase, add 'inv phase' in name and change color", -1)
