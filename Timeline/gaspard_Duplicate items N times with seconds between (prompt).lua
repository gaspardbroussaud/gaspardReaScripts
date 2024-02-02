-- @description Duplicate items N times with seconds between (prompt)
-- @author gaspard
-- @version 1.0
-- @about
--      Duplicates selection of items N times with X seconds between copies.

-- GET INPUTS FROM WINDOW PROMPT --
function inputsWindow()
    defaultDatas = "1,1"
    isNotCanceled, retvals_csv = reaper.GetUserInputs("Duplicate items data", 2, "Number of copies = ,Seconds between copies = ", defaultDatas)
    if isNotCanceled == true then
        Nval = math.tointeger(string.match(retvals_csv, "%d"))
        temp = string.match(retvals_csv, ",%d")
        temp = string.sub(temp, 2)
        secondsVal = math.tointeger(temp)
    end
end

-- EXECUTION FUNCTION --
function duplicateItems()
    reaper.ShowMessageBox("Duplicate", "Duplicate", 0)
end

-- MAIN FUNCTION --
function main()
    selected_items = reaper.CountSelectedMediaItems(0)
    if selected_items ~= 0 then
        inputsWindow()
        if isNotCanceled == true then
            duplicateItems()
        end
    end
end


-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Duplicated item N times with seconds between", 0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
