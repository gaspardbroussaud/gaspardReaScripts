--@description Set all regions numbering with name aware
--@author gaspard
--@version 1.2.2
--@changelog
--  Fix _Suffix deleted when renumbering
--@about
--  Sets the suffix number for region name withe name awareness. If name1_01 exists, another region name1 would be name1_02.
--  Regardless of the number of region between them.

-- INITIALISATION --
function InitTabs()
    isrgnTab = {}
    posTab = {}
    rgnendTab = {}
    nameTab = {}
    indexTab = {}
    colorTab = {}
    numNameTab = {}
end

-- SETS ALL VARIABLES FOR SCRIPT --
function SetupVariables()
    markrgn_count, _, _ = reaper.CountProjectMarkers(0)
    InitTabs()
end

-- GETS THE REGIONS INFORMATIONS AND ADDS THEM IN CORRESPONDING TABS --
function GetRegionsName()
    local i = 0
    while i < markrgn_count do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
        
        isrgnTab[i] = isrgn
        posTab[i] = pos
        rgnendTab[i] = rgnend
        nameTab[i] = name
        indexTab[i] = markrgnindexnumber
        colorTab[i] = color

        i = i + 1
    end
end

-- CHECK FOR NUMBERING IN REGION --
function DeleteNumbers()
    for i in pairs(nameTab) do
        if isrgnTab[i] then
            if nameTab[i]:match("(_%d*%.?%d+)") ~= nil and i ~= tabIndex then
                nameTab[i] = nameTab[i]:gsub("", "")
            end
        end
    end
end

-- CHECK IF REGION NAME IS UNIQUE AND SETS NUMBERING --
function CheckForNameInTab(cur_name, tabIndex)
    for i in pairs(nameTab) do
        if i ~= tabIndex and cur_name == nameTab[i] then
            if numNameTab[cur_name] == nil then
                numNameTab[cur_name] = 0
            end
            numNameTab[cur_name] = numNameTab[cur_name] + 1
            if numNameTab[cur_name] < 10 then
                return cur_name.."_0"..tostring(numNameTab[cur_name])
            else
                return cur_name.."_"..tostring(numNameTab[cur_name])
            end
        end
    end
    
    return cur_name
end

function SetRegionsName()
    local i = 0
    while i < markrgn_count do
        if isrgnTab[i] then
            pos = posTab[i]
            rgnend = rgnendTab[i]
            name = nameTab[i]
            new_name = CheckForNameInTab(name, i)
            indexToSet = indexTab[i]
            color = colorTab[i]
            reaper.SetProjectMarkerByIndex(0, i, true, pos, rgnend, indexToSet, new_name, color)
        end
        
        i = i + 1
    end
end

-- MAIN FUNCTION --
function main()
    SetupVariables()
    if num_regions ~= 0 then
        GetRegionsName()
        DeleteNumbers()
        SetRegionsName()
        InitTabs() -- Called to clean the tabs after use.
    end
end

-- SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Region number changed with sufix", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()