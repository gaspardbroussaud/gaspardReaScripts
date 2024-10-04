--@noindex
--@description Create region for clusters of selected items (prompt)
--@author gaspard
--@version 2.5
--@changelog
--  ~ Complete GUI rework: now using ImGui
--@about
--  Creates a region for each cluster of selected media items (overlapping or touching items in timeline). Prompts the renaming choices.

scriptVersion = 'Version 2.5'

-- ImGui SETUP --
function GuiInit()
    ctx = reaper.ImGui_CreateContext('Region Tool')
    FONT = reaper.ImGui_CreateFont('sans-serif', 15)
    reaper.ImGui_Attach(ctx, FONT)
    winW, winH = 400, 350
    isClosed = false
    r_name = 0
end

-- INFO QUESTION MARK ELEMENT --
function helperTooltip(debug, hTtSameLine)
    reaper.ImGui_TextDisabled(ctx, '(?)')
    if hTtSameLine then reaper.ImGui_SameLine(ctx) end
    if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayShort()) and reaper.ImGui_BeginTooltip(ctx) then
        reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetFontSize(ctx) * 35.0)
        reaper.ImGui_Text(ctx, debug)
        reaper.ImGui_PopTextWrapPos(ctx)
        reaper.ImGui_EndTooltip(ctx)
    end
end

function GuiElements()
    winW, winH = reaper.ImGui_GetWindowSize(ctx)
    
    -- Global settings and region render matrix options --
    if reaper.ImGui_BeginTable(ctx, 'GuiTableRRM', 2) then
        reaper.ImGui_TableNextRow(ctx)
        -- First column --
        reaper.ImGui_TableSetColumnIndex(ctx, 0)
        
        reaper.ImGui_Text(ctx, 'Settings')
        
        rv_an, cb_an = reaper.ImGui_Checkbox(ctx, 'Auto Number', cb_an); reaper.ImGui_SameLine(ctx)
        helperTooltip('Add a suffix number for regions in timeline order and with name aware numbering', false)
        
        rv_fs, cb_fs = reaper.ImGui_Checkbox(ctx, 'Folder Sensitive', cb_fs); reaper.ImGui_SameLine(ctx)
        helperTooltip('Cluster detection will take into acount the folder hierarchy', false)
        
        reaper.ImGui_Dummy(ctx, 10, 6)
        reaper.ImGui_Text(ctx, 'Cluster intern space'); reaper.ImGui_SameLine(ctx)
        helperTooltip('Space between items in cluster for its detection (in seconds)', false)
        rv_slider, interVal = reaper.ImGui_SliderDouble(ctx, '##sliderInterCluster', interVal, 0, 10)
        
        -- Second column --
        reaper.ImGui_TableSetColumnIndex(ctx, 1)
        
        reaper.ImGui_Text(ctx, 'Region Render Matrix'); reaper.ImGui_SameLine(ctx)
        helperTooltip('Select a render matrix setting to apply for given items regions', false)
        
        rv_rrm_st, cb_rrm_st = reaper.ImGui_Checkbox(ctx, 'Selected track', cb_rrm_st)
        rv_rrm_it, cb_rrm_it = reaper.ImGui_Checkbox(ctx, 'Items track', cb_rrm_it)
        rv_rrm_pt, cb_rrm_pt = reaper.ImGui_Checkbox(ctx, 'Parent track', cb_rrm_pt)
        rv_rrm_tpt, cb_rrm_tpt = reaper.ImGui_Checkbox(ctx, 'Top Parent track', cb_rrm_tpt)
        
        reaper.ImGui_EndTable(ctx)
    end
    
    -- Space between setting options --
    reaper.ImGui_Dummy(ctx, 100, 30)
    
    -- Renaming settings --
    reaper.ImGui_Text(ctx, 'Renaming options'); reaper.ImGui_SameLine(ctx)
    helperTooltip('Enter text in textbox for "Custom name" option otherwise the regions name will be blank', false)
    
    if reaper.ImGui_BeginTable(ctx, 'GuiTableName', 2) then
        reaper.ImGui_TableNextRow(ctx)
        -- Custom name textbox input --
        reaper.ImGui_TableSetColumnIndex(ctx, 0)
        reaper.ImGui_Text(ctx, 'Custom Name:'); reaper.ImGui_SameLine(ctx)
        rv_text_custom, text_custom = reaper.ImGui_InputText(ctx, '##inputText', text_custom, reaper.ImGui_InputTextFlags_AutoSelectAll())
        
        -- Renaming option choice --
        reaper.ImGui_TableSetColumnIndex(ctx, 1)
        rv, r_name = reaper.ImGui_RadioButtonEx(ctx, 'Custom name', r_name, 0)
        rv, r_name = reaper.ImGui_RadioButtonEx(ctx, 'Selected track name', r_name, 1)
        rv, r_name = reaper.ImGui_RadioButtonEx(ctx, 'Items track name', r_name, 2)
        rv, r_name = reaper.ImGui_RadioButtonEx(ctx, 'Parent track name', r_name, 3)
        rv, r_name = reaper.ImGui_RadioButtonEx(ctx, 'Top Parent track name', r_name, 4)
        
        reaper.ImGui_EndTable(ctx)
    end
    
    reaper.ImGui_Dummy(ctx, 10, winH - 10 - 350)
    
    if reaper.ImGui_Button(ctx, 'Confirm') then
        ConfirmButton()
        isClosed = true
    end; reaper.ImGui_SameLine(ctx)
    helperTooltip('"Confirm" will apply values from selected settings and close the window', true)
    
    dummySize = winW - 75 - 100
    reaper.ImGui_Dummy(ctx, dummySize, 10); reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, scriptVersion)
end

function GuiLoop()
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse()
    reaper.ImGui_SetNextWindowSize(ctx, winW, winH, reaper.ImGui_Cond_Once())
    reaper.ImGui_PushFont(ctx, FONT)
    reaper.ImGui_SetConfigVar(ctx, reaper.ImGui_ConfigVar_ViewportsNoDecoration(), 0)
    
    local visible, open = reaper.ImGui_Begin(ctx, 'Region Renaming Tool', true, window_flags)
    
    if visible then
        
        GuiElements()
        
        reaper.ImGui_End(ctx)
    end
    
    reaper.ImGui_PopFont(ctx)
    
    if open and not isClosed then
        reaper.defer(GuiLoop)
    end
end

function GuiDraw()
    GuiInit()
    GuiLoop()
end

function ConfirmButton()
    createClusters()
    
    --[[reaper.ClearConsole()
    
    if cb_an then
        reaper.ShowConsoleMsg('AUTO NUMBER: engaged\n')
    end
    
    if cb_fs then
        reaper.ShowConsoleMsg('\nFOLDER SENSITIVE: engaged\n')
    end
    
    reaper.ShowConsoleMsg("\nSLIDER VALUE: "..tostring(interVal)..'\n')
    
    if r_name == 0 then
        nameChoice = 'Custom name\nText: "'..text_custom..'"'
    elseif r_name == 1 then
        nameChoice = 'Selected track name'
    elseif r_name == 2 then
        nameChoice = 'Item track name'
    elseif r_name == 3 then
        nameChoice = 'Parent track name'
    elseif r_name == 4 then
        nameChoice = 'Top parent track name'
    end
    reaper.ShowConsoleMsg('\nNAME CHOICE: '..nameChoice..'\n')
    
    if cb_rrm_st or cb_rrm_it or cb_rrm_pt or cb_rrm_tpt then
        reaper.ShowConsoleMsg("\nRRM CHOICE: ")
    end
    if cb_rrm_st then
        reaper.ShowConsoleMsg('\nSelected track')
    end
    if cb_rrm_it then
        reaper.ShowConsoleMsg('\nItem track')
    end
    if cb_rrm_pt then
        reaper.ShowConsoleMsg('\nParent track')
    end
    if cb_rrm_tpt then
        reaper.ShowConsoleMsg('\nTop parent track')
    end]]--
end

--------------------------------------------------------------------------------------------------------------------

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
function setupVariables()
    if interVal == 0 then interVal = 0.0000001 end
    
    -- Add selected items to table and sort by start position --
    sel_item_Tab = {}
        
    for i = 1, sel_item_count do
        local cur_item = reaper.GetSelectedMediaItem(0, i-1)
        sel_item_Tab[i] = { item = cur_item, item_start = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION") }
    end
        
    sort_on_values(sel_item_Tab, "item_start")
end

-- SORT ITEMS IN FOLDER TABLES --
function sortItemsByFolders()
    folderTab = {}
    
    for i = 1, #sel_item_Tab do
        local itemTrack =  reaper.GetMediaItemTrack(sel_item_Tab[i].item)
        local parentTrack = reaper.GetParentTrack(itemTrack)
        
        -- Create parentTrack Tab for each parent track in folderTab --
        if parentTrack ~= nil and folderTab[parentTrack] == nil then
            folderTab[parentTrack] = {}
            table.insert(folderTab[parentTrack], sel_item_Tab[i].item)
        elseif parentTrack ~= nil and folderTab[parentTrack] ~= nil then
            table.insert(folderTab[parentTrack], sel_item_Tab[i].item)
        end
    end
end

-- CLUSTER DETECTION --
function clusterDetection(idx, tab, item)
    local cur_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local cur_end = cur_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        
    if prev_end + interVal < cur_start then
            
        reaper.AddProjectMarker(0, true, first_start, prev_end, text_custom, -1)
            
        first_start = cur_start
    end
        
    if idx == #tab then
        
        if prev_end > cur_end then
            last_end = prev_end
        else
            last_end = cur_end
        end
            
        reaper.AddProjectMarker(0, true, first_start, last_end, text_custom, -1)
    end
        
    if prev_end > cur_end then
        --nothing
    else
        prev_start = cur_start
        prev_end = cur_end
    end
end

-- ITEM CHECK POSITIONS FOR CLUSTERS Folder Sensitive --
function checkItemsPositionsFolder()
    for i in pairs(folderTab) do

        first_start = reaper.GetMediaItemInfo_Value(folderTab[i][1], "D_POSITION")
        prev_end = first_start + reaper.GetMediaItemInfo_Value(folderTab[i][1], "D_LENGTH")
        
        for j in ipairs(folderTab[i]) do
            clusterDetection(j, folderTab[i], folderTab[i][j])
        end
    end
end

-- ITEM CHECK POSITIONS FOR CLUSTERS Timeline --
function checkItemsPositionsTimeline()

    first_start = sel_item_Tab[1].item_start
    prev_end = sel_item_Tab[1].item_start + reaper.GetMediaItemInfo_Value(sel_item_Tab[1].item, "D_LENGTH")
    
    for i = 1, #sel_item_Tab do
        clusterDetection(i, sel_item_Tab, sel_item_Tab[i].item)
    end
end

-- CLUSTER REGION --
function createClusters()
    reaper.Undo_BeginBlock()
    setupVariables()
    if cb_fs then
        sortItemsByFolders()
        checkItemsPositionsFolder()
    else
        checkItemsPositionsTimeline()
    end
    
    -- Apply region name with choice in input --
    if r_name ~= 0 then
        if r_name == 1 then
            setRegionParentName("selected track")
        elseif r_name == 2 then
            setRegionParentName("track")
        elseif r_name == 3 then
            setRegionParentName("parent track")
        elseif r_name == 4 then
            setRegionParentName("top parent track")
        end
    end
    
    -- Apply auto numbering via reascript --
    if cb_an then setRegionNumbering() end
    
    -- Unselect all items --
    for i = 1, #sel_item_Tab do
        reaper.SetMediaItemSelected(sel_item_Tab[i].item, false)
    end
    
    reaper.Undo_EndBlock("Create region for selected clusters of items", -1)
end

function cleanUp()
    --remove all created regions if rename not successfull (WIP)
end

-------------------------------------------------------------------------------------------
function GetActionCommandIDByFilename(searchfilename, searchsection)
  -- returns the action-command-id for a given scriptfilename installed in Reaper
  -- Parameters: 0 = Main, 100 = Main(alt recording), 32060 = MIDI Editor, 32061 = MIDI Event List Editor, 32062 = MIDI Inline Editor, 32063 = Media Explorer
  -- Returnvalue: string AID - the actioncommand-id of the scriptfile; "", if no such file is installed
  for k in io.lines(reaper.GetResourcePath().."/reaper-kb.ini") do
    if k:sub(1,3)=="SCR" then
      local section, aid, desc, filename=k:match("SCR .- (.-) (.-) (\".-\") (.*)")
      local filename=string.gsub(filename, "\"", "") 
      if filename==searchfilename and tonumber(section)==searchsection then
        return "_"..aid
      end
    end
  end
  reaper.MB("Script: "..searchfilename.."\nPlease install via ReaPack.", "Error script not found", 0)
  cleanUp()
  return ""
end

function setRegionParentName(stringScript)
    if stringScript == "selected track" or stringScript == "track" or stringScript == "parent track" or stringScript == "top parent track" then
        path_command = "Gaspard ReaScripts/Region/gaspard_Set all regions name to "..stringScript.." name.lua"
        reaper.Main_OnCommand(reaper.NamedCommandLookup(GetActionCommandIDByFilename(path_command, 0)), 0)
    end
end

function setRegionNumbering()
    path_command = "Gaspard ReaScripts/Region/gaspard_Set all regions numbering with name aware.lua"
    reaper.Main_OnCommand(reaper.NamedCommandLookup(GetActionCommandIDByFilename(path_command, 0)), 0)
end

function setRegionRenderMatrix()
    reaper.Undo_BeginBlock()
    
    -- Select all items from Table --
    for i = 1, #sel_item_Tab do
        reaper.SetMediaItemSelected(sel_item_Tab[i].item, true)
    end
    
    -- Set RRM command paths --
    if cb_rrm_st then -- Selected track
        path_selected_track = "Gaspard ReaScripts/Render region matrix/gaspard_Set selected tracks in region render matrix for selected media items regions.lua"
        reaper.Main_OnCommand(reaper.NamedCommandLookup(GetActionCommandIDByFilename(path_selected_track, 0)), 0)
    end
    
    if cb_rrm_it then -- Item track
        path_item_track = "Gaspard ReaScripts/Render region matrix/gaspard_Set track of selected media items in region render matrix for respective regions.lua"
        reaper.Main_OnCommand(reaper.NamedCommandLookup(GetActionCommandIDByFilename(path_item_track, 0)), 0)
    end
    
    if cb_rrm_pt then -- Parent track
        path_parent_track = "Gaspard ReaScripts/Render region matrix/gaspard_Set parent track of selected media items in region render matrix for respective regions.lua"
        reaper.Main_OnCommand(reaper.NamedCommandLookup(GetActionCommandIDByFilename(path_parent_track, 0)), 0)
    end
    
    if cb_rrm_tpt then -- Top parent track
        path_top_parent_track = "Gaspard ReaScripts/Render region matrix/gaspard_Set top parent track in region render matrix for selected media items regions.lua"
        reaper.Main_OnCommand(reaper.NamedCommandLookup(GetActionCommandIDByFilename(path_top_parent_track, 0)), 0)
    end
    
    -- Unselect all items --
    for i = 1, #sel_item_Tab do
        reaper.SetMediaItemSelected(sel_item_Tab[i].item, false)
    end
    
    reaper.Undo_EndBlock("Set tracks in render region matrix for regions of selected items", -1)
end
-------------------------------------------------------------------------------------------

-- MAIN FUNCTION --
function main()

    sel_item_count = reaper.CountSelectedMediaItems(0)
    
    if sel_item_count ~= 0 then
        GuiDraw()
    else
        reaper.MB("Please select at least one item.", "No item selected", 0)
    end
end

-- SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
