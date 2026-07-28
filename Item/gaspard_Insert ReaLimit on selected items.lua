--@description Insert ReaLimit on selected items
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Insert ReaLimit on selected items.

local sel_item_count = reaper.CountSelectedMediaItems(0)

if sel_item_count < 1 then return end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local sel_items = {}

for i = 1, sel_item_count do
    sel_items[i] = reaper.GetSelectedMediaItem(0, i - 1)
end

for _, item in ipairs(sel_items) do
    reaper.TakeFX_AddByName(reaper.GetMediaItemTake(item, 0), "ReaLimit", -1)
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Add ReaLimit to selected items", -1)
reaper.UpdateArrange()
