--@description Prompt to quit REAPER
--@author gaspard
--@version 1.0.1
--@changelog Change prompt button's text
--@about Prompt to quit REAPER

local val = reaper.ShowMessageBox('Do you want to quit REAPER?', 'QUIT REAPER', 4)
if val == 6 then
    reaper.Main_OnCommand(40004, 0)
end

