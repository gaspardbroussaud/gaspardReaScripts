--@description Display selected items count in console
--@author gaspard
--@version 1.0
--@changelog
--    Initial release
--@about
--    Clear console then display selected items count in console.

reaper.ClearConsole()
reaper.ShowConsoleMsg("Number of selected items: "..tostring(reaper.CountSelectedMediaItems(0)))
