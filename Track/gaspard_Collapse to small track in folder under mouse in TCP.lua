--@description Collapse to small track in folder under mouse in TCP
--@author gaspard
--@version 1.0
--@changelog Initial release.
--@about Set track under mouse as small collapsed state if it is a folder track.

track, _, _ = reaper.BR_TrackAtMouseCursor() --Get track under cursor

if track ~= nil then -- Check if track exist
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") ~= 2 then -- Check if track is parent folder
        track_collapse = reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 1)
    end
end
