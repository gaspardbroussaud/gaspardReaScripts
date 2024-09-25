--@description Collapse and uncollapse on double click track in TCP via mouse modifiers
--@author gaspard
--@version 1.0.3
--@changelog Clean script.
--@about Set script to double click on track in TCP to cycle between collapsed and uncollapsed states for folder track

track, _, _ = reaper.BR_TrackAtMouseCursor() --Get track under cursor

if track ~= nil then
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then -- Check if track is parent folder
        track_collapse = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT")
        if track_collapse < 2 then
            reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 2) -- If is not collapsed and inbetween go to collapsed
        else
            reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 0) -- If is collapsed go to uncollapsed
        end
        
        reaper.SetTrackSelected(track, false) -- Unselect track
    end
end