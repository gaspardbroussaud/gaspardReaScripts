--@description Prompt to quit REAPER
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Prompt to quit REAPER

local val = reaper.ShowMessageBox('Do you want to quit REAPER?', 'QUIT REAPER', 1)
if val == 1 then
    reaper.Main_OnCommand(40004, 0)
end

