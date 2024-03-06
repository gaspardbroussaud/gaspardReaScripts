--@description Set all regions name to custom name
--@author gaspard
--@version 1.0
--@changelog Initial release.
--@about This scripts sets project regions name to custom user input name for selected items.

-- GET INPUTS FROM USER --
function inputDatas()
    defaultDatas = ""
    isNotCanceled, customName = reaper.GetUserInputs("Custom name for regions", 1, "Custom name = ", defaultDatas)
end

-- SET NAME DATA TO REGIONS --
function setRegionName()
    for i = 0, sel_item_count - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        _, regionidx = reaper.GetLastMarkerAndCurRegion(0, item_start)
        
        _, isrgn, pos, rgnend, name, rgnindex = reaper.EnumProjectMarkers2(0, regionidx)
        
        if customName == "" then
            reaper.SetProjectMarker4(0, rgnindex, isrgn, pos, rgnend, customName, 0, 1)
        else
            reaper.SetProjectMarker2(0, rgnindex, isrgn, pos, rgnend, customName)
        end
    end
end

-- MAIN FUNCTION --
function main()
    sel_item_count = reaper.CountSelectedMediaItems(0)
    _, _, rgn_count = reaper.CountProjectMarkers(0)
    
    if sel_item_count ~= 0 then
        if rgn_count ~= 0 then
            inputDatas()
            if isNotCanceled then
                setRegionName()
            end
        else
            reaper.MB("There are no regions in project.\nScript end.", "No region in project", 0)
        end
    else
        reaper.MB("Please select at least one item.", "No item selected", 0)
    end
end

-- MAIN SCRIPT EXECUTION --
reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock("Region name set to parent track", -1)
