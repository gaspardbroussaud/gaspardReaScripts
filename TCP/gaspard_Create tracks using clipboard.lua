-- @description Create tracks using clipboard
-- @author gaspard
-- @version 1.0
-- @about Create tracks using clipboard
-- @changelog Initial release

local list = {}
for line in reaper.CF_GetClipboard():gmatch("[^\r\n]+") do
    table.insert(list, line)
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

for _, line in ipairs(list) do
    local last = reaper.CountTracks(0)
    reaper.InsertTrackInProject(0, last, 0)
    reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, last), "P_NAME", line, true)
end

reaper.Undo_EndBlock("Inserted tracks using clipboard.", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
