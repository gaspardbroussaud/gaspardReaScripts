--@description Select tracks of selected items
--@author gaspard
--@version 1.0
--@changelog Initial release.
--@about Select tracks of selected items and unselect all other tracks.

-- Unselect all tracks --
reaper.Main_OnCommand(40297, 0)

-- Select tracks of selected items --
if reaper.CountSelectedMediaItems(0) ~= 0 then
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItemTrack(item)
        if not reaper.IsTrackSelected(track) then
            reaper.SetTrackSelected(track, true)
        end
    end
end
