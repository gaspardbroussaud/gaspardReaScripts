--@description Display selected items count in message box
--@author gaspard
--@version 1.0
--@changelog
--    Initial release
--@about
--    Display selected items count in message box.

reaper.MB("Number of selected items: "..tostring(reaper.CountSelectedMediaItems(0)), "Selected items", 0)
