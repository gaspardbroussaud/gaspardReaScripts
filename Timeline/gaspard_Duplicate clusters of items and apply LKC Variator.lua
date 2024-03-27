--@description Duplicate clusters of items and apply LKC Variator
--@author gaspard
--@version 1.1
--@changelog + Added a remaining clusters to process window for Variator.
--@about Prompt to duplicate clusters of selected items N times with X seconds between copies and apply an LKC Variator preset.

-- GET INPUTS FROM WINDOW PROMPT --
function inputsWindow()
    defaultDatas = "1,1,0"
    isNotCanceled, retvals_csv = reaper.GetUserInputs("Duplicate items data", 3, "Number of copies = ,Seconds between copies = ,Variator preset (0 to 5) = ", defaultDatas)
    if isNotCanceled then
        tempNval,secondsVal,tempVariatorPreset = retvals_csv:match("(.+),(.+),(.+)")
        Nval = math.tointeger(tempNval)
        variatorPreset = math.tointeger(tempVariatorPreset)
    end
end

-- GET RELATIVE ACTION COMMAND ID FOR USER --
function GetActionCommandIDByFilename(searchfilename, searchsection)
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

-- GET ALL DATAS FROM SELECTED ITEMS --
function originalDatas()
    itemTab = {}
    
    original_start = 0
    original_end = 0
    
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    
    for i = 0, sel_item_count - 1 do
        itemTab[i] = reaper.GetSelectedMediaItem(0, i)
        
        cur_item_start = reaper.GetMediaItemInfo_Value(itemTab[i], "D_POSITION")
        cur_item_end = cur_item_start + reaper.GetMediaItemInfo_Value(itemTab[i], "D_LENGTH")
        
        if cur_item_start < original_start or original_start == 0 then
            original_start = cur_item_start
            cluster_start_item = itemTab[i]
        end
        
        if cur_item_end > original_end then
            original_end = cur_item_end
            cluster_end_item = itemTab[i]
        end
        
        reaper.SetTrackSelected(reaper.GetMediaItemTrack(itemTab[i]), true)
    end
    
    original_length = original_end - original_start
end

-- DUPLICATE SELECTED ITEMS --
function duplicateItems()
    --Nudge items with duplication then apply Variator
    if Nval ~= 0 then
        clusterPosTab = {}
        
        for i = 0, Nval - 1 do
            nudge_length = original_length + secondsVal
            reaper.ApplyNudge(0, 0, 5, 1, nudge_length, 0, 1)
            
            cur_start = reaper.GetMediaItemInfo_Value(cluster_start_item, "D_POSITION")
            cur_end = reaper.GetMediaItemInfo_Value(cluster_end_item, "D_POSITION") + reaper.GetMediaItemInfo_Value(cluster_end_item, "D_LENGTH")
            
            clusterPosTab[i] = { startPos = cur_start, endPos = cur_end }
        end
    end
end

-- WAITING WINDOW --
function Show_Tooltip(text)
    local x, y = 500, 250
    reaper.TrackCtl_SetToolTip(text:gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end

-- APPLY VARIATOR --
function applyVariator()
    reaper.GetSet_LoopTimeRange(true, true, clusterPosTab[loopNB].startPos, clusterPosTab[loopNB].endPos, false)
    
    reaper.Main_OnCommand(40718, 0) -- Select all items in time selection on selected tracks
    
    ActionCommandID = GetActionCommandIDByFilename("LKC-Variator/GameAudio/LKC - Variator - Mutate using formula "..variatorPreset..".lua", 0)
    reaper.Main_OnCommand(reaper.NamedCommandLookup(ActionCommandID), 0)
    
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.Main_OnCommand(40635, 0) -- Clear time selection

    loopNB = loopNB + 1
end

-- CLEAN SELECTION AND OTHER PARTS --
function clean()
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.Main_OnCommand(40635, 0) -- Clear time selection
end

-- TIMER --
function runloop()
  local newtime=reaper.time_precise()
  if newtime-lasttime >= timeChoice then
    lasttime=newtime
    applyVariator()
    
    if loopNB == #clusterPosTab + 1 then
        clean()
        Show_Tooltip("")
        return
    else
        Show_Tooltip("\nRemaining clusters to process: "..tostring(#clusterPosTab - loopNB + 1).."\n")
    end
  end
  reaper.defer(runloop)
end

-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

sel_item_count = reaper.CountSelectedMediaItems(0)
if sel_item_count ~= 0 then
    inputsWindow()
    if isNotCanceled then
        if tostring(variatorPreset) ~= "nil" then
            if variatorPreset < 6 then
                if tostring(Nval) ~= "nil" then
                    originalDatas()
                    duplicateItems()
                    if variatorPreset ~= 0 then
                        lasttime = reaper.time_precise()
                        timeChoice = 0.75
                        loopNB = 0
                        runloop()
                    else
                        clean()
                    end
                else
                    reaper.MB("Error. Please enter a whole number for copies input.", "Error decimal number entered", 0)
                end
            else
                reaper.MB("Error selecting Variator preset.\nPlease select a whole number between 0 and 5.", "Variator preset error", 0)
            end
        else
            reaper.MB("Error selecting Variator preset.\nPlease select a whole number between 0 and 5.", "Variator preset error", 0)
        end
    end
else
    reaper.MB("Please select at least one item.", "No item selected", 0)
end

reaper.Undo_EndBlock("Duplicate clusters of items and apply LKC Variator", -1)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
