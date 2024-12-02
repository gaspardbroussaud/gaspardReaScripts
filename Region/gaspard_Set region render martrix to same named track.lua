-- @description Set region render martrix to same named track
-- @author gaspard
-- @version 1.0.0
-- @changelog
--  - New script
-- @about
--  - Set region's render matrix track to track with same name

-- USER SETTINGS ----------
local region_naming_parent_casacde = false
---------------------------

----------------------------------------------------------------

---comment
---@param track any
---@return string name
-- GET TOP PARENT TRACK
function GetConcatenatedParentNames(track)
    local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    if region_naming_parent_casacde then
        while true do
            local parent = reaper.GetParentTrack(track)
            if parent then
                track = parent
                local _, parent_name = reaper.GetSetMediaTrackInfo_String(parent, "P_NAME", "", false)
                name = parent_name.."_"..name
            else
                return name
            end
        end
    else
        return name
    end
end

-- GET ALL TRACKS AND CONCANETATED PARENTS NAMES IN TABLE
function GetTracks()
    local track_count = reaper.CountTracks(0)
    if track_count > 0 then
        local tracks = {}
        for i = 0, track_count - 1 do
            local cur_track = reaper.GetTrack(0, i)
            local track_name = GetConcatenatedParentNames(cur_track)
            tracks[i] = { track = cur_track, name = track_name }
        end
        return tracks
    end
    return nil
end

-- SET RENDER REGION MATRIX WITH TRACKS INFOS
function SetRenderMatrixTracks()
    local _, _, num_regions = reaper.CountProjectMarkers(0)
    if num_regions > 0 then
        local tracks = GetTracks()
        if tracks then
            local missing = {}
            for i = 0, num_regions - 1 do
                local _, isrgn, _, _, name, index = reaper.EnumProjectMarkers2(0, i)
                if isrgn then
                    table.insert(missing, { name = name, index = index })
                    for j = 0, #tracks do
                        if tracks[j].name == name then
                            reaper.SetRegionRenderMatrix(0, index, tracks[j].track, 1)
                            table.remove(missing, #missing)
                            break
                        end
                    end
                end
            end
            if #missing > 0 then
                local error_message = ""
                for i = 1, #missing do
                    error_message = error_message.." - "..tostring(missing[i].name).."; index: "..tostring(missing[i].index).."\n"
                end
                reaper.ShowMessageBox("There are errors in region/track links.\nRegions affected:\n"..error_message, "ERROR", 0)
            end
        else
            reaper.ShowMessageBox("There are no tracks in current project.", "MESSAGE", 0)
        end
    else
        reaper.ShowMessageBox("There are no regions in current project.", "MESSAGE", 0)
    end
end

-- MAIN SCRIPT EXECUTION
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(-1)

SetRenderMatrixTracks()

reaper.PreventUIRefresh(1)
reaper.Undo_EndBlock("Set region render martrix to same name track", -1)
reaper.UpdateArrange()