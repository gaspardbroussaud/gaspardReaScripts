--@description Show control ID of top level window under mouse
--@author gaspard
--@version 1.0.0
--@changelog Initial release
--@about Show control ID of top level window under mouse

-- Get Control ID under mouse (top-level window)
function Main()
  id = reaper.JS_Window_GetLong(reaper.JS_Window_FromPoint(reaper.GetMousePosition()), "ID")
  reaper.ClearConsole()
  reaper.ShowConsoleMsg(tostring(id) .. "\n")
  reaper.defer(Main)
end

Main()
