--@description Remove selected odd items in timeline order on multiple tracks
--@author gaspard
--@version 1.0
--@changelog Initial release.
--@about Remove selected odd items in timeline order on multiple tracks.

-- SORT VALUES FUNCTION --
function sort_on_values(t,...)
  local a = {...}
  table.sort(t, function (u,v)
    for i in pairs(a) do
      if u[a[i]] > v[a[i]] then return false end
      if u[a[i]] < v[a[i]] then return true end
    end
  end)
end

-- VARIABLE SETUP AT SCRIPT START --
function insertTabandSort()
    if interVal == 0 then interVal = 0.0000001 end
    
    -- Add selected items to table and sort by start position --
    sel_item_Tab = {}
        
    for i = 1, sel_item_count do
        local cur_item = reaper.GetSelectedMediaItem(0, i-1)
        sel_item_Tab[i] = { item = cur_item, item_start = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION") }
    end
        
    sort_on_values(sel_item_Tab, "item_start")
end

function setOneOutOfTwo()
    for i = 1, #sel_item_Tab do
        if i%2 == 0 then
            reaper.SetMediaItemSelected(sel_item_Tab[i].item, false)
        end
    end
end

-- MAIN FUNCTION --
function main()
    sel_item_count = reaper.CountSelectedMediaItems(0)
    
    if sel_item_count > 1 then
        insertTabandSort()
        setOneOutOfTwo()
    else
        reaper.MB("Please select more than one item.", "Not enough items selected", 0)
    end
end

-- SCRIPT EXECUTION --
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Remove selected even items in timeline order on multiple tracks", -1)

