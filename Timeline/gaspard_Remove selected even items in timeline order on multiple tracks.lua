--@description Remove selected even items in timeline order on multiple tracks
--@author gaspard
--@version 1.0.1
--@changelog Update script nomenclature and cleanup
--@about Remove selected even items in timeline order on multiple tracks.

-- SORT VALUES FUNCTION --
function SortOnValues(t,...)
  local a = {...}
  table.sort(t, function (u,v)
    for i in pairs(a) do
      if u[a[i]] > v[a[i]] then return false end
      if u[a[i]] < v[a[i]] then return true end
    end
  end)
end

-- VARIABLE SETUP AT SCRIPT START --
function InsertTabandSort()
    -- Add selected items to table and sort by start position --
    local sel_item_Tab = {}

    for i = 1, sel_item_count do
        local cur_item = reaper.GetSelectedMediaItem(0, i-1)
        sel_item_Tab[i] = { item = cur_item, item_start = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION") }
    end

    SortOnValues(sel_item_Tab, "item_start")
end

function SetOneOutOfTwo()
    for i = 1, #sel_item_Tab do
        if i%2 == 0 then
            --nothing
        else
            reaper.SetMediaItemSelected(sel_item_Tab[i].item, false)
        end
    end
end

-- MAIN FUNCTION --
function Main()
    local sel_item_count = reaper.CountSelectedMediaItems(0)

    if sel_item_count > 1 then
        InsertTabandSort()
        SetOneOutOfTwo()
    else
        reaper.MB("Please select more than one item.", "Message Box", 0)
    end
end

-- SCRIPT EXECUTION --
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Remove selected even items in timeline order on multiple tracks", -1)

