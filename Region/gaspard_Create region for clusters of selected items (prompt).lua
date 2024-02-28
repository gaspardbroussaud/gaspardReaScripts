--@description Create region for clusters of selected items (prompt)
--@author gaspard
--@version 1.5
--@changelog
--  Added first parent and top parent options.
--@about
--  Creates a region for each cluster of selected media items (overlapping or touching items in timeline).
--  Prompts the renaming choices.

-- INITIALISATION --
local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please install 'Scythe library v3' from ReaPack, then run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end

loadfile(libPath .. "scythe.lua")()

-- VARIABLES --
main_win_w = 250
main_win_h = 300

bsw = 140
bpx = (main_win_w - bsw) / 2

bsh = 30

-- MAIN WINDOW --
local GUI = require("gui.core")
local Window = require("gui.window")
local Listbox = require("gui.elements.Listbox")

-- WINDOW --
local window = GUI.createWindow({
  name = "Main Window",
  w = main_win_w,
  h = main_win_h,
})

-- GUI ELEMENTS --
local mainLayer = GUI.createLayer({name = "MainLayer"})
local customTextLayer = GUI.createLayer({name = "CustomTextLayer"})

-- Main Layer Elements --
mainLayer:addElements( GUI.createElements(
  {
    name = "btn_custom_text",
    type = "Button",
    x = bpx,
    y = 90,
    w = bsw,
    h = bsh,
    caption = "Use custom text",
    func = function () customTextWindow() end
  },
  {
    name = "btn_parent_name",
    type = "Button",
    x = bpx,
    y = 130,
    w = bsw,
    h = bsh,
    caption = "Use parent's name",
    func = function () setParent(false) end
  },
  {
    name = "btn_top_parent_name",
    type = "Button",
    x = bpx,
    y = 170,
    w = bsw,
    h = bsh,
    caption = "Use top parent's name",
    func = function () setParent(true) end
  },
  {
    name = "btn_cancel_main",
    type = "Button",
    x = bpx,
    y = 220,
    w = bsw,
    h = bsh,
    caption = "Cancel",
    func = function () cancelButton() end
  },
  {
    name = "checkbox_auto_number",
    type = "Checklist",
    x = (main_win_w - 110) /2,
    y = 30,
    w = 110,
    h = 30,
    caption = "",
    options = {"Auto number"},
    frame = false
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
    func = function () setCustom() end
  },
  {
    name = "btn_customText_back",
    type = "Button",
    x = bpx,
    y = 130,
    w = bsw,
    h = bsh,
    caption = "Back",
    func = function () backToMain() end
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

function mainWindow()
    -- Declare GUI --
    window:addLayers(mainLayer)
    window:addLayers(customTextLayer)
    customTextLayer:hide()
    window:open()
    -- Draw GUI --
    GUI.Main()
end

-- BUTTONS FUNCTIONS --
function customTextWindow()
    mainLayer:hide()
    customTextLayer:show()
end

function backToMain()
    mainLayer:show()
    customTextLayer:hide()
end

function cancelButton()
    window:close()
end

function setCustom()
    -- Get value for checkbox Auto Number --
    valCheckBox = GUI.Val("checkbox_auto_number")
    autoNumber = valCheckBox[1]
    
    -- Get value for input text --
    textInput = GUI.Val("textBox")
    
    -- Function script --
    applyChoice(0) -- 0 = Custom name
    window:close()
end

function setParent(tempBool)
    -- Get value for checkbox Auto Number --
    valCheckBox = GUI.Val("checkbox_auto_number")
    autoNumber = valCheckBox[1]
    
    -- Get value for input text --
    textInput = ""
    
    -- Function script --
    isTopParentName = tempBool
    applyChoice(1) -- 1 = Parent track name
    window:close()
end

--------------------------------------------------------------------------------------------------------------------

-- GET TOP PARENT TRACK --
local function getTopParentTrack(track)
  while true do
    local parent = reaper.GetParentTrack(track)
    if parent then
      track = parent
    else
      return track
    end
  end
end

-- CREATE TEXT ITEMS -- Credit to X-Raym
function CreateTextItem(track, position, length, parentTrackName)

  local item = reaper.AddMediaItemToTrack(track)

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
  reaper.GetSetMediaItemInfo_String(item, "P_NOTES", parentTrackName, true)
  
  return item

end

-- TABLE INIT -- Credit to X-Raym
local setSelectedMediaItem = {}

-- CREATE NOTE ITEMS -- Credit to X-Raym
function createNoteItems()

  selected_tracks_count = reaper.CountSelectedTracks(0)

  if selected_tracks_count > 0 then

    -- DEFINE TRACK DESTINATION
    selected_track = reaper.GetSelectedTrack(0,0)

    -- COUNT SELECTED ITEMS
    selected_items_count = reaper.CountSelectedMediaItems(0)

    if selected_items_count > 0 then

      -- SAVE TAKES SELECTION
      for j = 0, selected_items_count-1  do
        setSelectedMediaItem[j] = reaper.GetSelectedMediaItem(0, j)
      end

      -- LOOP THROUGH TAKE SELECTION
      for i = 0, selected_items_count-1  do
        -- GET ITEMS AND TAKES AND PARENT TRACK
        item = setSelectedMediaItem[i] -- Get selected item i
        item_track = reaper.GetMediaItemTrack(item)
        item_parent_track = reaper.GetParentTrack(item_track)
        if item_parent_track ~= nil then
            if isTopParentName then
                track_top_parent = getTopParentTrack(item_parent_track)
            else
                track_top_parent = item_parent_track
            end
            _, item_parent_track_name = reaper.GetSetMediaTrackInfo_String(track_top_parent, "P_NAME", "", false)
        else
            item_parent_track_name = "MasterTrack"
        end

        -- TIMES
        item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        item_duration = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        -- ACTION
        CreateTextItem(selected_track, item_start, item_duration, item_parent_track_name)

      end -- ENDLOOP through selected items
      reaper.Main_OnCommand(40421, 0)
      -- Create text items on first selected track from selected items notes
    else -- no selected item
      reaper.ShowMessageBox("Select at least one item","Please",0)
    end -- if select item
  else -- no selected track
    reaper.ShowMessageBox("The script met an error when trying to access created track for note items","Error",0)
  end -- if selected track
end

-- SETUP ALL VARIABLES FOR CLUSTERS --
function setupVariables()
    
    first_item = reaper.GetSelectedMediaItem(0, 0)
    
    first_item_start_pos = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
    
    prev_item_end_pos = first_item_start_pos
    
    regionNumber = 1
end

-- CREATE REGION FOR CLUSTERS --
function createGroupsRegion()
    setupVariables()

    for i = 0, selected_items_count - 1 do
    
        cur_item = reaper.GetSelectedMediaItem(0, i)
        
        cur_item_start_pos = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION")
        cur_item_end_pos = cur_item_start_pos + reaper.GetMediaItemInfo_Value(cur_item, "D_LENGTH")
        
        if prev_item_end_pos + 0.0000001 < cur_item_start_pos then
            inputsToName()
            reaper.AddProjectMarker(0, true, first_item_start_pos, prev_item_end_pos, rgnName, -1)
            first_item_start_pos = cur_item_start_pos
            first_item = cur_item
        end
            
        if i == selected_items_count - 1 then
            if prev_item_end_pos > cur_item_end_pos then
                last_item_end_pos = prev_item_end_pos
            else
                last_item_end_pos = cur_item_end_pos
            end
            
            inputsToName()
            reaper.AddProjectMarker(0, true, first_item_start_pos, last_item_end_pos, rgnName, -1)
        end
        
        if prev_item_end_pos > cur_item_end_pos then
            --nothing
        else
            prev_item_end_pos = cur_item_end_pos
        end
    end
    
end

-- Get inputs to region name --
function inputsToName()
    if choice == 0 then
        -- Empty because textInput is already set with custom text
    elseif choice == 1 then
        _, textInput = reaper.GetSetMediaItemInfo_String(first_item, "P_NOTES", "", false)
    end
    
    if autoNumber then
        rgnNumText = tostring(regionNumber)
        if regionNumber < 10 then
            rgnName = textInput.."_".."0"..rgnNumText
        else
            rgnName = textInput.."_"..rgnNumText
        end
        
        regionNumber = regionNumber + 1
    else
        rgnName = textInput
    end
end

-- MAIN --
function createClusterRegion()
    if reaper.CountSelectedMediaItems(0) > 0 then
        
        reaper.Undo_BeginBlock() -- Start of undo block
        
        reaper.Main_OnCommand(40001, 0) -- Create new track
    
        createNoteItems()
    
        createGroupsRegion()
    
        reaper.Main_OnCommand(40005, 0) -- Delete created track
        
        reaper.Undo_EndBlock("Create region for selected clusters of items", -1) -- End of undo block
    end
end

function applyChoice(temp_choice)
    choice = temp_choice
    createClusterRegion()
end

-- MAIN FUNCTION --
function main()
    selected_items_count = reaper.CountSelectedMediaItems(0)
    if selected_items_count ~= 0 then
        mainWindow()
    else
        reaper.ShowMessageBox("Please select at least one item", "No items selected", 0)
    end
end

-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.ClearConsole()
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()