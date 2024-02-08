--@description ProTools marker go to
--@author gaspard
--@version 1.0
--@about
--    Adds the marker selection in timeline behavior from ProTools : suppr + marker number with numpad + suppr

-- MAIN FUNCTION : GET INPUT MARKER NUMBER -> GO TO MARKER --
function main()
    defaultDatas = ""
    isNotCanceled, retvals_csv = reaper.GetUserInputs("Marker index input", 1, "Marker index = ", defaultDatas)
    if isNotCanceled == true and retvals_csv ~= "" then
        marker_index = math.tointeger(retvals_csv)
        reaper.GoToMarker(0, marker_index, false)
    end
end

-- MAIN SCRIPT EXECUTION --
main()
