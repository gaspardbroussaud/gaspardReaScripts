--@description Collapse to small track in folder under mouse in TCP
--@author gaspard
--@version 1.1
--@changelog +On and off behaviour.
--@about Set track under mouse as small collapsed state if it is a folder track.

track, _, _ = reaper.BR_TrackAtMouseCursor() --Get track under cursor

if track ~= nil then
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") ~= 2 then -- Check if track is parent folder
        track_collapse = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT")
        if track_collapse == 0 or track_collapse == 2 then
            reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 1) -- If is not collapsed and inbetween go to collapsed
        elseif track_collapse == 1 then
            reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 0) -- If is collapsed go to uncollapsed
        else
            reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 0) -- If other change to collapsed (to prevent error)
        end
    end
end
