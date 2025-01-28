--@noindex
--@description Pattern generator user interface gui drop zone
--@author gaspard
--@about User interface drop zone used in gaspard_Pattern generator.lua script

local drop_window = {}

function drop_window.Show()
    if reaper.ImGui_Button(ctx, "ADD TRACK", 100) then
        System.CreateObjectTracks()
    end
end

return drop_window
