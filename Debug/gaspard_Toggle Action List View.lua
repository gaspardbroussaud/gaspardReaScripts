--@description Toggle Action List View
--@author Edgemeal
--@version 1.0.0
--@link Forum Thread https://forum.cockos.com/showpost.php?p=2137164&postcount=19
--@changelog Initial release
--@about Toggle Action List View

function Main()
  local found = false
  local arr = reaper.new_array({}, 100)
  local title = reaper.JS_Localize("Actions", "common")
  reaper.JS_Window_ArrayFind(title, true, arr)
  local adr = arr.table() 
  for j = 1, #adr do
    local hwnd = reaper.JS_Window_HandleFromAddress(adr[j])
    if reaper.JS_Window_FindChildByID(hwnd, 1323) then -- verify window, must also have control ID#.
      reaper.JS_Window_Destroy(hwnd) -- close action list
      found = true
      break
    end 
  end 
  if not found then reaper.ShowActionList() end -- show action list
end

if not reaper.APIExists('JS_Localize') then
  reaper.MB("js_ReaScriptAPI extension is required for this script.", "Missing API", 0)
else
  Main()
end
reaper.defer(function () end)
