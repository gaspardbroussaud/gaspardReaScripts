--@description Set all regions numbering with name aware
--@author gaspard
--@version 1.0
--@changelog
--  Initial release.
--@about
--  Sets the sufix number for region name withe name awareness. If name1_01 exists, another region name1 would be name1_02.
--  Regardless of the number of region between them.

-- INITIALISATION --
function setupVariables()
    _, _, num_regions = reaper.CountProjectMarkers(0)
    
    posTab = {}
    rgnendTab = {}
    nameTab = {}
    indexTab = {}
    colorTab = {}
    numNameTab = {}
end

function getRegionsName()
    local i = 0
    while i < num_regions do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
        if isrgn then
            posTab[i] = pos
            rgnendTab[i] = rgnend
            nameTab[i] = name
            indexTab[i] = markrgnindexnumber
            colorTab[i] = color
        end
        i = i + 1
    end
end

function checkForNameInTab(cur_name, tabIndex)
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
    while i < num_regions do
        pos = posTab[i]
        rgnend = rgnendTab[i]
        name = nameTab[i]
        new_name = checkForNameInTab(name, i)
        indexToSet = indexTab[i]
        color = colorTab[i]
        reaper.SetProjectMarkerByIndex(0, i, true, pos, rgnend, indexToSet, new_name, color)
        i = i + 1
    end
end

function clearTabs()
    posTab = {}
    rgnendTab = {}
    nameTab = {}
    indexTab = {}
    colorTab = {}
    numNameTab = {}
end

-- MAIN FUNCTION --
function main()
    setupVariables()
    getRegionsName()
    SetRegionsName()
    clearTabs()
end

-- SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Region number changed with sufix", 1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
