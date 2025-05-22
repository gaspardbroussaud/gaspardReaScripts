--@description Set time selection from first selected item start to input length
--@author gaspard
--@version 1.0
--@changelog
--    Initial release.  
--@about
--    Set time selection from first selected item start to input length.

-- GET USER INPUTS
local function InputDatas()
    local default_datas = "1"
    local retval, retvals_csv = reaper.GetUserInputs("DATA INPUT", 1, "Time selection length (s) = ", default_datas)
    if not retval then return nil end
    local input_length = retvals_csv:match("(.+)")
    return input_length
end

-- SCRIPT EXECUTION
local length = InputDatas()
if length then
    if reaper.CountSelectedMediaItems(0) > 0 then
        local start = reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, 0), "D_POSITION")

        -- Set time selection start and end positions
        reaper.GetSet_LoopTimeRange(true, true, start, start + length, true)

        -- Set playhead/edit cursor to time selection start
        reaper.SetEditCurPos(start, true, true)
    end
end
