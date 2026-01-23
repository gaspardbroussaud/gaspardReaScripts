--@description Set selected item to -inf dB
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Set selected item to -inf dB.

local item_count = reaper.CountSelectedMediaItems(0)
if item_count == 0 then return end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    reaper.SetMediaItemInfo_Value(item, "D_VOL", 0)
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Set selected item to -inf dB", -1)
