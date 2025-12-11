--@description Add stretch markers at start and end of selected items takes and set slope
--@author gaspard
--@version 1.0.0
--@changelog Script creation
--@about Add stretch markers at start and end of selected items takes and set slope.

local item_count = reaper.CountSelectedMediaItems(0)
if item_count < 1 then return end

local retval, retvals_csv = reaper.GetUserInputs('Set Take Slope', 1, 'Slope (+-4) or 5+ for random', '0')
if not retval then return end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local slope_in
if type(tonumber(retvals_csv)) == "number" then
    slope_in = tonumber(retvals_csv)
else
    slope_in = 0
end

reaper.Main_OnCommand(40796, 0) -- Clear take preserve pitch

for i = 1, item_count do
    local item = reaper.GetSelectedMediaItem(0, i - 1)
    local take = reaper.GetActiveTake(item)
    local itemLength = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
    reaper.DeleteTakeStretchMarkers(take, 0, reaper.GetTakeNumStretchMarkers(take))
    local idx = reaper.SetTakeStretchMarker(take, -1, 0)
    reaper.SetTakeStretchMarker(take, -1, itemLength * playrate)
    local slope = slope_in
    if slope > 4 then
        slope = math.random() * math.min(4, (slope - 4)) / 4
        if math.random() > 0.5 then slope = slope * -1 end
    else
        slope = slope * 0.2499
    end
    reaper.SetTakeStretchMarkerSlope(take, idx, slope)
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Add stretch markers at start and end of selected items takes and set slope", -1)
