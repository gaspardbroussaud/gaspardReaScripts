--@description Toggle video window saving state in project
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Toggle video window saving state in project.

reaper.Main_OnCommand(50125, 0) -- Show/hide video window

if reaper.GetToggleCommandState(50125) == 1 then
    reaper.SetProjExtState(0, "VideoWindowDisplay", "is_show", tostring(1))
else
    reaper.SetProjExtState(0, "VideoWindowDisplay", "is_show", "")
end
