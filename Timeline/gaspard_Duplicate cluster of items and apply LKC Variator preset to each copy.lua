--@description Duplicate items N times with X seconds between and apply LKC Variator preset
--@author gaspard
--@version 1.2
--@changelog
--    Added Variator formula check.
--@about
--    Duplicates selection of items N times with X seconds between copies and applies selected LKC Variator preset.

-- GET INPUTS FROM WINDOW PROMPT --
function inputsWindow()
    defaultDatas = "1,1,0"
    isNotCanceled, retvals_csv = reaper.GetUserInputs("Duplicate items data", 3, "Number of copies = ,Seconds between copies = ,Variator formula (0 to 5) = ", defaultDatas)
    if isNotCanceled then
        tempNval,tempSecondsVal,tempVariatorFormula = retvals_csv:match("(.+),(.+),(.+)")
        Nval = math.tointeger(tempNval)
        secondsVal = math.tointeger(tempSecondsVal)
        variatorFormula = math.tointeger(tempVariatorFormula)
    end
end

-- SELECT VARIATOR PRESET WITH DATAS --
function selectVariator()
    if variatorFormula == 1 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_RS2a48ba5fc0b182579659d16911dfe40cad1f52b2"), 0)
    elseif variatorFormula == 2 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_RS46d75140b8c4f43b0b7ccb06abed363654050c88"), 0)
    elseif variatorFormula == 3 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_RS3586c97d03f557827627f83f3169523a1556b3cd"), 0)
    elseif variatorFormula == 4 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_RS56be0ed8723605d9f0b5d98e7daf55f65ce03963"), 0)
    elseif variatorFormula == 5 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_RS7448400b4bce7db85bdbcc3a3f27846b55ea6f43"), 0)
    end
end

-- TIMER --
function runloop()
  local newtime=os.time()
  if newtime-lasttime >= timeChoice then
    lasttime=newtime
    applyVariator()
    if stopScriptLoop == true then
        reaper.ShowConsoleMsg("\nStopped at: "..tostring(loopNB))
    end
    if loopNB == #regionTab + 1 then
        reaper.Main_OnCommand(40289, 0) -- Unselect all items
        reaper.Main_OnCommand(40635, 0) -- Clear time selection
        deleteRegion()
        return
    end
  end
  reaper.defer(runloop)
end

-- CREATE TABLE OF SELECTED ITEMS --
function tableOfItems()
    itemTab = {}
    
    for i = 0, sel_item_count - 1 do
        itemTab[i] = reaper.GetSelectedMediaItem(0, i)
    end
    
    regionTab = {}
end

-- GET ALL DATAS FROM SELECTED ITEMS --
function originalDatas()
    
    original_start = 0
    original_end = 0
    
    for i in pairs(itemTab) do
        cur_item_start = reaper.GetMediaItemInfo_Value(itemTab[i], "D_POSITION")
        cur_item_length = reaper.GetMediaItemInfo_Value(itemTab[i], "D_LENGTH")
        cur_item_end = cur_item_start + cur_item_length
        
        if cur_item_start < original_start or original_start == 0 then
            original_start = cur_item_start
        end
        if cur_item_end > original_end then
            original_end = cur_item_end
        end
    end
    
    original_length = original_end - original_start
    nudge_length = 0
    
    reaper.Main_OnCommand(40290, 0) -- Set time selection to selected items
end

-- DUPLICATE SELECTED ITEMS --
function duplicateItems()
    --Nudge items with duplication then apply Variator
    if Nval ~= 0 then
        for i = 0, Nval - 1 do
            reaper.Main_OnCommand(40289, 0) -- Unselect all items
            reaper.Main_OnCommand(40717, 0) -- Select all items in time selection
            
            nudge_length = original_length + secondsVal + nudge_length
            reaper.ApplyNudge(0, 0, 5, 1, nudge_length, 0, 1)
            
            -- Create region for new cluster --
            if variatorFormula ~= 0 and variatorFormula < 6 then
                region_start = original_start + nudge_length
                region_end = region_start + original_length
                region_index = reaper.AddProjectMarker(0, true, region_start, region_end, "Variator_"..tostring(i), -1)
            end
            
            regionTab[i] = region_index
        end
    end
end

-- DELETE CREATED REGIONS --
function deleteRegion(regionidx)
    local retval, isrgn, pos, rgnend, name, regionidx, _ = reaper.EnumProjectMarkers3(0,regionTab[0])
    reaper.DeleteProjectMarker(0, regionTab[0], true)
    
    for i in ipairs(regionTab) do
        local retval, isrgn, pos, rgnend, name, regionidx, _ = reaper.EnumProjectMarkers3(0,regionTab[i])
        reaper.DeleteProjectMarker(0, regionTab[i], true)
    end
end

-- VARIATOR ON INDEX 0 --
function applyVariatorIndex0()
    local retval, isrgn, pos, rgnend, name, regionidx, _ = reaper.EnumProjectMarkers3(0,regionTab[0]-1)
    
    reaper.GetSet_LoopTimeRange(true, true, pos, rgnend, false) --isSet, isLoop, start, end, allowautoseek
    
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.Main_OnCommand(40717, 0) -- Select all items in time selection
     
    selectVariator()
end

-- USE DATAS TO DUPLICATE --
function applyVariator()
    local retval, isrgn, pos, rgnend, name, regionidx, _ = reaper.EnumProjectMarkers3(0,regionTab[loopNB])
    
    reaper.GetSet_LoopTimeRange(true, true, pos, rgnend, false) --isSet, isLoop, start, end, allowautoseek
    
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.Main_OnCommand(40717, 0) -- Select all items in time selection
     
    selectVariator()
    
    loopNB = loopNB + 1
end

-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

reaper.ClearConsole()

sel_item_count = reaper.CountSelectedMediaItems(0)

if sel_item_count ~= 0 then
    inputsWindow()
    if isNotCanceled then
        if variatorFormula < 6 then
            tableOfItems()
            originalDatas()
            duplicateItems()
            if variatorFormula ~= 0 and variatorFormula < 6 then
                applyVariatorIndex0()
                lasttime = os.time()
                timeChoice = 1
                loopNB = 0
                runloop()
            end
            reaper.Main_OnCommand(40289, 0) -- Unselect all items
            reaper.Main_OnCommand(40635, 0) -- Clear time selection
        else
            reaper.MB("Error selecting Variator Formula.\nPlease select a number between 0 and 5.", "Variator formula error", 0)
        end
    end
else
    reaper.MB("Please select at least one item", "No item selected", 0)
end

reaper.Undo_EndBlock("Duplicated item N times with seconds between", 0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()