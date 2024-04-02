--@description Delete items under Xms and rename with text list
--@author VincentDcs, gaspard
--@version 1.0
--@changelog Initial release.
--@about Delete items under 100ms in project (default, see script to change value in USER VALUES) and rename visible items with text list input.

-- BEGIN USER VALUES ----------------------------------------------------
-- Will delete only items under 100ms. --
deleteLength = 0.1 -- Change this value with: number_in_ms/1000 -> 100ms/1000 = 0.1
-- END USER VALUES ------------------------------------------------------

-- BEGIN GUI ELEMENTS ---------------------------------------------------
function guiDraw()
    local ImGui = {}
    for name, func in pairs(reaper) do
      name = name:match('^ImGui_(.+)$')
      if name then ImGui[name] = func end
    end
    
    local ctx = reaper.ImGui_CreateContext("ContextWindow")
    local sans_serif = reaper.ImGui_CreateFont("sans-serif", 13)
    reaper.ImGui_Attach(ctx, sans_serif)
    ImGui.SetConfigVar(ctx, reaper.ImGui_ConfigVar_ViewportsNoDecoration(), 0)
    wWidth, wHeight = 500, 800
    
    click_count, textInputs = 0, ""
    
    textWinWidth, textWinHeight = wWidth - 100, wHeight - 100
    
    local function myWindow()
        local rv
        cur_wWidth, cur_wHeight = reaper.ImGui_GetWindowSize(ctx)
        textWinWidth, textWinHeight = cur_wWidth - 15, cur_wHeight - 40
        rv, textInputs = reaper.ImGui_InputTextMultiline(ctx, " ", textInputs, textWinWidth, textWinHeight, ImGui.InputTextFlags_CharsNoBlank(), nil)
      
        if reaper.ImGui_Button(ctx, "Confirm") then
            viaRgn = false
            if textInputs ~= "\n" and textInputs ~= "" then
                main()
            end
        end
    end
    
    local function loop()
        reaper.ImGui_PushFont(ctx, sans_serif)
        reaper.ImGui_SetNextWindowSize(ctx, wWidth, wHeight, reaper.ImGui_Cond_FirstUseEver())
        
        local visible, open = reaper.ImGui_Begin(ctx, "Input window", true)
        
        if visible then
            myWindow()
            reaper.ImGui_End(ctx)
        end
        
        reaper.ImGui_PopFont(ctx)
        
        if open then
            reaper.defer(loop)
        end
    end
    
    reaper.defer(loop)
end
-- END GUI ELEMENTS -----------------------------------------------------

-- REMOVE ITEMS WITH LENGTH UNDER 100ms --
function removeItems()
    itemTab = {}
    
    for i = 1, reaper.CountMediaItems(0) do
        itemTab[i] = reaper.GetMediaItem(0, i-1)
    end
    
    for i = 1, #itemTab do
        --reaper.SetMediaItemSelected(itemTab[i], true)
        
        if reaper.GetMediaItemInfo_Value(itemTab[i], "D_LENGTH") < deleteLength then
            reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(itemTab[i]), itemTab[i])
        end
    end
end

-- GET ALL ITEMS ON VISIBLE TRACKS IN TIMELINE --
function getVisibleItems()
    itemTab = {}
    
    for i = 1, reaper.CountMediaItems(0) do
        if reaper.GetMediaTrackInfo_Value(reaper.GetMediaItemTrack(reaper.GetMediaItem(0, i-1)), "B_SHOWINTCP") == 1 then
            itemTab[#itemTab + 1] = reaper.GetMediaItem(0, i-1)
        end
    end
end

-- GET TEXT INPUT IN TABLE LINE BY LINE --
function getTextList()
    textTab = {}
    
    local function magiclines(s)
        if s:sub(-1)~="\n" then s=s.."\n" end
        return s:gmatch("(.-)\n")
    end
    
    for line in magiclines(textInputs) do
        table.insert(textTab, line)
    end
end

-- APPLY NAME FROM LIST TO ITEM --
function applyName()
    for i = 1, #textTab do
        if i <= #itemTab then
            local item = itemTab[i]
            local take = reaper.GetActiveTake(item)
            
            if viaRgn then
                local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                
                reaper.AddProjectMarker(0, true, itemStart, itemEnd, textTab[i], -1)
            else
                reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", textTab[i], true)
            end
        end
    end
end

-- CHECK FOR VALIDITY OF INPUTS --
function validityCheck()
    if #textTab == #itemTab then
        applyName()
    else
        OK = reaper.MB("There are "..tostring(#textTab).." text inputs and "..tostring(#itemTab).." items in project.\nIf this is not an error, select OK, else select CANCEL.\nItems under "..tostring(math.ceil(deleteLength*1000)).."ms have been deleted.", "Warning", 1)
        if OK == 1 then
            applyName()
        else
            --nothing
        end
    end
end

-- MAIN FUNCTION --
function main()
    getTextList()
    validityCheck()
end

-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

removeItems()
getVisibleItems()

if #itemTab ~= 0 then
    guiDraw()
else
    reaper.MB("There are no visible items in current project.\nItems under "..tostring(math.ceil(deleteLength*1000)).."ms have been deleted.", "Error", 0)
end

reaper.Undo_EndBlock("Delete items under Xms and rename with text list", -1)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
