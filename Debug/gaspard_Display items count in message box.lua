-- @description Display items count in message box
-- @author gaspard
-- @version 1.0
-- @changelog
--	• Initial release
-- @about Display items count in message box.

reaper.MB("Number of items in project: "..tostring(reaper.CountMediaItems(0)), "Selected items", 0)
