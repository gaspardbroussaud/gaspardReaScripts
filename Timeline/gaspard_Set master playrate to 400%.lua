--@description Set master playrate to 400%
--@author gaspard
--@version 1.0
--@about Set master playrate to 400%

reaper.Undo_BeginBlock()
local info = debug.getinfo(1,'S');
local val = string.match(info.source, "%d+")

reaper.CSurf_OnPlayRateChange( val / 100 )
reaper.Undo_EndBlock( "Set master playrate to " .. val .. "%", -1 )
