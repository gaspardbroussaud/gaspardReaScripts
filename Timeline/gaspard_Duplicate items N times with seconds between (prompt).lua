-- @description Duplicate items N times with seconds between (prompt)
-- @author gaspard
-- @version 1.0
-- @about
--      Duplicates selection of items N times with X seconds between copies.

-- GET INPUTS FROM WINDOW PROMPT --
function inputsWindow()
    defaultDatas = "1,1"
    isNotCanceled, retvals_csv = reaper.GetUserInputs("Duplicate items data", 2, "Number of copies = ,Seconds between copies = ", defaultDatas)
    if isNotCanceled == true then
        Nval = math.tointeger(string.match(retvals_csv, "%d"))
        temp = string.match(retvals_csv, ",%d")
        temp = string.sub(temp, 2)
        secondsVal = math.tointeger(temp)
    end
end

-- GET ITEM INFOS : Start Position, Length, End Position --
function getItemInfos(item)
    item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    item_end = item_start + item_length
    return item_start, item_length, item_end
end

-- EXECUTION FUNCTION --
function duplicateItems()
    first_item = reaper.GetSelectedMediaItem(0, 0)
    first_item_start, first_item_length, last_item_end = getItemInfos(first_item)
    
    for i=0, reaper.CountSelectedMediaItems(0)-1 do
        cur_item = reaper.GetSelectedMediaItem(0, i)
        cur_item_start, cur_item_length, cur_item_end = getItemInfos(cur_item)
        if cur_item_start < first_item_start then
            first_item_start = cur_item_start
        elseif cur_item_end > last_item_end then
            last_item_end = cur_item_end
        end
    end
    
    cluster_length = last_item_end - first_item_start
    
    duplication_start_pos = first_item_start + cluster_length + secondsVal
end

-- GET LENGTH OF SELECTED ITEMS --
function getClusterLength()
    first_item = reaper.GetSelectedMediaItem(0, 0)
    first_item_start, first_item_length, first_item_end = getItemInfos(first_item)

    
    for i=0, reaper.GetSelectedMediaItem(0)-1 do
        
    end
end

-- MAIN FUNCTION --
function main()
    selected_items = reaper.CountSelectedMediaItems(0)
    if selected_items ~= 0 then
        inputsWindow()
        if isNotCanceled == true then
            duplicateItems()
        end
    end
end


-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Duplicated item N times with seconds between", 0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
