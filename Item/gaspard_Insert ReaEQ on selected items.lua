--@description Insert ReaEQ on selected items
--@author gaspard
--@version 1.0.2
--@changelog Fix insert
--@about Insert ReaEQ on selected items.

local sel_item_count = reaper.CountSelectedMediaItems(0)

if sel_item_count < 1 then return end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local sel_items = {}

for i = 1, sel_item_count do
    sel_items[i] = reaper.GetSelectedMediaItem(0, i - 1)
end

for i, item in ipairs(sel_items) do
    local take = reaper.GetMediaItemTake(item, 0)

    local fx_index = reaper.TakeFX_AddByName(take, "ReaEQ", -1)

    if i < 2 then
        reaper.TakeFX_SetOpen(take, fx_index, true)
    end
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Add ReaEQ to selected items", -1)
reaper.UpdateArrange()
