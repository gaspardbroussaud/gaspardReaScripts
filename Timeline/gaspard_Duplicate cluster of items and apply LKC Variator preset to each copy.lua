--@description Duplicate items N times with X seconds between and apply LKC Variator preset
--@author gaspard
--@version 1.5
--@changelog
--    Fix the script to work only on selected items.
--@about
--    Duplicates selection of items N times with X seconds between copies and applies selected LKC Variator preset.

-- GET INPUTS FROM WINDOW PROMPT --
function inputsWindow()
    defaultDatas = "1,1,0"
    isNotCanceled, retvals_csv = reaper.GetUserInputs("Duplicate items data", 3, "Number of copies = ,Seconds between copies = ,Variator formula (0 to 5) = ", defaultDatas)
    if isNotCanceled then
        tempNval,secondsVal,tempVariatorFormula = retvals_csv:match("(.+),(.+),(.+)")
        Nval = math.tointeger(tempNval)
        variatorFormula = math.tointeger(tempVariatorFormula)
    end
end

-- GET RELATIVE ACTION COMMAND ID FOR USER --
function GetActionCommandIDByFilename(searchfilename, searchsection)
  -- returns the action-command-id for a given scriptfilename installed in Reaper
  -- keep in mind: some scripts are stored in subfolders, like Cockos/lyrics.lua
  --               in that case, you need to give the full path to avoid possible
  --               confusion between files with the same filenames but in different
  --               subfolders.
  --               Scripts that are simply in the Scripts-folder, not within a 
  --               subfolder of Scripts can be accessed just by their filename
  --
  -- Parameters:
  --            string searchfilename - the filename, whose action-command-id you want to have
  --            integer section - the section, in which the file is stored
  --                                0 = Main, 
  --                                100 = Main (alt recording), 
  --                                32060 = MIDI Editor, 
  --                                32061 = MIDI Event List Editor, 
  --                                32062 = MIDI Inline Editor,
  --                                32063 = Media Explorer.
  -- Returnvalue:
  --            string AID - the actioncommand-id of the scriptfile; "", if no such file is installed
  for k in io.lines(reaper.GetResourcePath().."/reaper-kb.ini") do
    if k:sub(1,3)=="SCR" then
      local section, aid, desc, filename=k:match("SCR .- (.-) (.-) (\".-\") (.*)")
      local filename=string.gsub(filename, "\"", "") 
      if filename==searchfilename and tonumber(section)==searchsection then
        return "_"..aid
      end
    end
  end
  return ""
end

-- SET VARIATOR COMMAND ID --
function variatorCommandId()
    ActionCommandID = {}
    for i = 1, 5 do
        ActionCommandID[i] = GetActionCommandIDByFilename("LKC-Variator/GameAudio/LKC - Variator - Mutate using formula "..i..".lua", 0)
    end
end

-- SELECT VARIATOR PRESET WITH DATAS --
function selectVariator()
    reaper.Main_OnCommand(reaper.NamedCommandLookup(ActionCommandID[variatorFormula]), 0)
end

-- SELECT TRACKS OF SELECTED ITEMS ONLY --
function selectTracksOfItems()
    reaper.Main_OnCommand(reaper.NamedCommandLookup(GetActionCommandIDByFilename("Gaspard ReaScripts/Track/gaspard_Select tracks of selected items.lua", 0)), 0)
end

-- TIMER --
function runloop()
  local newtime=os.time()
  if newtime-lasttime >= timeChoice then
    lasttime=newtime
    applyVariator()
    
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
    
    selectTracksOfItems()
    reaper.Main_OnCommand(40290, 0) -- Set time selection to selected items
end

-- DUPLICATE SELECTED ITEMS --
function duplicateItems()
    --Nudge items with duplication then apply Variator
    if Nval ~= 0 then
        for i = 0, Nval - 1 do
            reaper.Main_OnCommand(40289, 0) -- Unselect all items
            reaper.Main_OnCommand(40718, 0) -- Select all items in time selection on selected tracks
            
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
    reaper.Main_OnCommand(40718, 0) -- Select all items in time selection on selected tracks
     
    selectVariator()
end

-- USE DATAS TO DUPLICATE --
function applyVariator()
    local retval, isrgn, pos, rgnend, name, regionidx, _ = reaper.EnumProjectMarkers3(0,regionTab[loopNB])
    
    reaper.GetSet_LoopTimeRange(true, true, pos, rgnend, false) --isSet, isLoop, start, end, allowautoseek
    
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.Main_OnCommand(40718, 0) -- Select all items in time selection on selected tracks
     
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
        if tostring(variatorFormula) ~= "nil" then
            if variatorFormula < 6 then
                if tostring(Nval) ~= "nil" then
                    variatorCommandId()
                    tableOfItems()
                    originalDatas()
                    duplicateItems()
                    if variatorFormula ~= 0 then
                        applyVariatorIndex0()
                        lasttime = os.time()
                        timeChoice = 1
                        loopNB = 0
                        runloop()
                    end
                    reaper.Main_OnCommand(40289, 0) -- Unselect all items
                    reaper.Main_OnCommand(40635, 0) -- Clear time selection
                    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
                else
                    reaper.MB("Error. Please enter a whole number for copies input", "Error decimal number entered", 0)
                end
            else
                reaper.MB("Error selecting Variator Formula.\nPlease select a whole number between 0 and 5.", "Variator formula error", 0)
            end
        else
            reaper.MB("Error selecting Variator Formula.\nPlease select a whole number between 0 and 5.", "Variator formula error", 0)
        end
    end
else
    reaper.MB("Please select at least one item", "No item selected", 0)
end

reaper.Undo_EndBlock("Duplicated item N times with seconds between", 0)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
