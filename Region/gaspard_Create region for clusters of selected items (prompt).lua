--@description Create region for clusters of selected items (prompt)
--@author gaspard
--@version 2.2
--@changelog
--  + New Region Render Matrix setting to set tracks for created regions to render.
--@about
--  Creates a region for each cluster of selected media items (overlapping or touching items in timeline). Prompts the renaming choices.

-- USER VALUES --------------------------------------------------
maxSliderValue = 10 -- Maximum value available in slider
incrementSliderValue = 0.1 -- Value increment available in slider
-----------------------------------------------------------------

-- INITIALISATION --
local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please install 'Scythe library v3' from ReaPack, then run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end

loadfile(libPath .. "scythe.lua")()

-- VARIABLES --
main_win_w = 250
main_win_h = 380

bsw = 140
bpx = (main_win_w - bsw) / 2
bsh = 30

space = 40
posY = 140

-- Buttons in RRM Layer --
rrmY = (main_win_h - 250) / 2

-- MAIN WINDOW --
local GUI = require("gui.core")

-- WINDOW --
local window = GUI.createWindow({
  name = "User Inputs Window",
  w = main_win_w,
  h = main_win_h,
})

-- GUI ELEMENTS --
local mainLayer = GUI.createLayer({name = "MainLayer"})
local customTextLayer = GUI.createLayer({name = "CustomTextLayer"})
local rrmLayer = GUI.createLayer({name = "RRMLayer"})

-- Main Layer Elements --
mainLayer:addElements( GUI.createElements(
  {
    name = "checkbox_num_rrm",
    type = "Checklist",
    x = (main_win_w - 110) /2 - 10,
    y = 25,
    w = 110,
    h = 60,
    caption = "",
    options = {"Auto number", "Set Region Matrix"},
    pad = 7,
    frame = false
  },
  {
    name = "slider_interval",
    type = "Slider",
    x = (main_win_w - 110) /2,
    y = posY - space,
    w = 110,
    h = 30,
    caption = "",
    min = 0,
    max = maxSliderValue,
    inc = incrementSliderValue,
    defaults = 0,
    frame = false
  },
  {
    name = "btn_custom_text",
    type = "Button",
    x = bpx,
    y = posY,
    w = bsw,
    h = bsh,
    caption = "Use custom text",
    func = function () customTextWindow() end
  },
  {
    name = "btn_track_name",
    type = "Button",
    x = bpx,
    y = posY + space,
    w = bsw,
    h = bsh,
    caption = "Use track's name",
    func = function () getUserInputs(1) end
  },
  {
    name = "btn_parent_name",
    type = "Button",
    x = bpx,
    y = posY + space * 2,
    w = bsw,
    h = bsh,
    caption = "Use parent's name",
    func = function () getUserInputs(2) end
  },
  {
    name = "btn_top_parent_name",
    type = "Button",
    x = bpx,
    y = posY + space * 3,
    w = bsw,
    h = bsh,
    caption = "Use top parent's name",
    func = function () getUserInputs(3) end
  },
  {
    name = "btn_cancel_main",
    type = "Button",
    x = bpx,
    y = posY + space * 4 + 10,
    w = bsw,
    h = bsh,
    caption = "Cancel",
    func = function () cancelButton() end
  })
)

-- Custom Text Layer Elements --
customTextLayer:addElements( GUI.createElements(
  {
    name = "textBox",
    type = "TextBox",
    x = bpx,
    y = 30,
    w = bsw,
    h = bsh,
    caption = ""
  },
  {
    name = "btn_customText_print",
    type = "Button",
    x = bpx,
    y = 90,
    w = bsw,
    h = bsh,
    caption = "Set custom",
    func = function () getUserInputs(0) end
  },
  {
    name = "btn_customText_back",
    type = "Button",
    x = bpx,
    y = 130,
    w = bsw,
    h = bsh,
    caption = "Back",
    func = function () backFromCustom() end
  },
  {
    name = "btn_customText_cancel",
    type = "Button",
    x = bpx,
    y = 180,
    w = bsw,
    h = bsh,
    caption = "Cancel",
    func = function () cancelButton() end
  })
)

-- Region Render Matrix Layer Elements --
rrmLayer:addElements( GUI.createElements(
  {
    name = "btn_sel_track_rrm",
    type = "Button",
    x = bpx,
    y = rrmY,
    w = bsw,
    h = bsh,
    caption = "Set to selected track",
    func = function () setRegionRenderMatrix(0) end
  },
  {
    name = "btn_item_track_rrm",
    type = "Button",
    x = bpx,
    y = rrmY + 40,
    w = bsw,
    h = bsh,
    caption = "Set to item track",
    func = function () setRegionRenderMatrix(1) end
  },
  {
    name = "btn_parent_track_rrm",
    type = "Button",
    x = bpx,
    y = rrmY + 80,
    w = bsw,
    h = bsh,
    caption = "Set to parent track",
    func = function () setRegionRenderMatrix(2) end
  },
  {
    name = "btn_top_parent_track_rrm",
    type = "Button",
    x = bpx,
    y = rrmY + 120,
    w = bsw,
    h = bsh,
    caption = "Set to top parent track",
    func = function () setRegionRenderMatrix(3) end
  },
  {
    name = "btn_rrm_back",
    type = "Button",
    x = bpx,
    y = rrmY + 170,
    w = bsw,
    h = bsh,
    caption = "Back",
    func = function () backFromRRM() end
  },
  {
    name = "btn_rrm_cancel",
    type = "Button",
    x = bpx,
    y = rrmY + 220,
    w = bsw,
    h = bsh,
    caption = "Cancel",
    func = function () cancelButton() end
  })
)

function mainWindow()
    -- Declare GUI --
    window:addLayers(mainLayer)
    window:addLayers(customTextLayer)
    window:addLayers(rrmLayer)
    customTextLayer:hide()
    rrmLayer:hide()
    window:open()
    -- Draw GUI --
    GUI.Main()
end

-- BUTTONS FUNCTIONS --
function customTextWindow()
    mainLayer:hide()
    customTextLayer:show()
end

function backFromCustom()
    mainLayer:show()
    customTextLayer:hide()
end

function backFromRRM()
    mainLayer:show()
    rrmLayer:hide()
end

function cancelButton()
    window:close()
end

-- Choice: 0 = custom, 1 = track, 2 = parent track, 3 = top parent track --
function getUserInputs(tempChoice)
    choice = tempChoice
    
    -- Get value for checkbox Auto Number --
    autoNumber = GUI.Val("checkbox_num_rrm")[1]
    
    -- Get Region Matrix Set --
    setRRM = GUI.Val("checkbox_num_rrm")[2]
    
    -- Get value for slider --
    interVal = GUI.Val("slider_interval")
    
    -- Get value for input text --
    if choice == 0 then
        rgnName = GUI.Val("textBox")
    else
        rgnName = ""
    end
    
    createClusters()
    
    if GUI.Val("checkbox_num_rrm")[2] == true then
        mainLayer:hide()
        customTextLayer:hide()
        rrmLayer:show()
    else
        window:close()
    end
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

-- ITEM CHECK POSITIONS FOR CLUSTERS --
function checkItemsPositions()
    prev_start = sel_item_Tab[1].item_start
    prev_end = sel_item_Tab[1].item_start + reaper.GetMediaItemInfo_Value(sel_item_Tab[1].item, "D_LENGTH")
    first_start = prev_start
    first_end = prev_end
    
    for i = 1, #sel_item_Tab do
    
        local cur_item = sel_item_Tab[i].item
        local cur_start = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION")
        local cur_end = cur_start + reaper.GetMediaItemInfo_Value(cur_item, "D_LENGTH")
        
        if prev_end + interVal < cur_start then
            
            reaper.AddProjectMarker(0, true, first_start, prev_end, rgnName, -1)
            
            first_start = cur_start
        end
        
        if i == #sel_item_Tab then
        
            if prev_end > cur_end then
                last_end = prev_end
            else
                last_end = cur_end
            end
            
            reaper.AddProjectMarker(0, true, first_start, last_end, rgnName, -1)
        end
        
        if prev_end > cur_end then
            --nothing
        else
            prev_start = cur_start
            prev_end = cur_end
        end
    end
end

-- CLUSTER REGION --
function createClusters()
    reaper.Undo_BeginBlock()
    setupVariables()
    checkItemsPositions()
    
    -- Apply region name with choice in input --
    if choice ~= 0 then
        if choice == 1 then
            setRegionParentName("track")
        elseif choice == 2 then
            setRegionParentName("parent track")
        elseif choice == 3 then
            setRegionParentName("top parent track")
        end
    end
    
    -- Apply auto numbering via reascript --
    if autoNumber then setRegionNumbering() end
    
    -- Unselect all items --
    for i = 1, #sel_item_Tab do
        reaper.SetMediaItemSelected(sel_item_Tab[i].item, false)
    end
    
    reaper.Undo_EndBlock("Create region for selected clusters of items", -1)
end

-------------------------------------------------------------------------------------------
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
  reaper.MB("Script: "..searchfilename.."\nPlease install via ReaPack.", "Error script not found", 0)
  return ""
end

function setRegionParentName(stringScript)
    if stringScript == "track" or stringScript == "parent track" or stringScript == "top parent track" then
        path_command = "Gaspard ReaScripts/Region/gaspard_Set all regions name to "..stringScript.." name.lua"
        reaper.Main_OnCommand(reaper.NamedCommandLookup(GetActionCommandIDByFilename(path_command, 0)), 0)
    end
end

function setRegionNumbering()
    path_command = "Gaspard ReaScripts/Region/gaspard_Set all regions numbering with name aware.lua"
    reaper.Main_OnCommand(reaper.NamedCommandLookup(GetActionCommandIDByFilename(path_command, 0)), 0)
end

function setRegionRenderMatrix(rrm)
    if rrm == 0 then -- Selected track
        path_command = "Gaspard ReaScripts/Render region matrix/gaspard_Set selected tracks in region render matrix for selected media items regions.lua"
    elseif rrm == 1 then -- Item track
        path_command = "Gaspard ReaScripts/Render region matrix/gaspard_Set track of selected media items in region render matrix for respective regions.lua"
    elseif rrm == 2 then -- Parent track
        path_command = "Gaspard ReaScripts/Render region matrix/gaspard_Set parent track of selected media items in region render matrix for respective regions.lua"
    elseif rrm == 3 then -- Top parent track
        path_command = "Gaspard ReaScripts/Render region matrix/gaspard_Set top parent track in region render matrix for selected media items regions.lua"
    end
    
    -- Select all items from Table --
    for i = 1, #sel_item_Tab do
        reaper.SetMediaItemSelected(sel_item_Tab[i].item, true)
    end
    
    reaper.Main_OnCommand(reaper.NamedCommandLookup(GetActionCommandIDByFilename(path_command, 0)), 0)
    
    -- Unselect all items --
    for i = 1, #sel_item_Tab do
        reaper.SetMediaItemSelected(sel_item_Tab[i].item, false)
    end
    
    window:close()
end
-------------------------------------------------------------------------------------------

-- MAIN FUNCTION --
function main()
    reaper.ClearConsole()
    
    sel_item_count = reaper.CountSelectedMediaItems(0)
    
    if sel_item_count ~= 0 then
        mainWindow()
    else
        reaper.MB("Please select at least one item.", "No item selected", 0)
    end
end

-- SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
