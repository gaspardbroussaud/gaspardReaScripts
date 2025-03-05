--@noindex

local gpmsys_samples = {}

local function CreateParentTrack()
    -- Insert track at end of track list
    -- Set params in track extstates
end

local function GetParentTrack()
    -- Look for track GUID from project extstates
    -- if not track then return nil end
    -- return track
end

local function GetSampleTracks(parent_track)
    local list = {}
    -- Loop on all tracks
    -- Add tracks with extstate containing parent track GUID
    return list
end

function gpmsys_samples.CheckForSampleTracks()
    -- parent track = GetParentTrack()
    -- if not parent_track then parent_track = CreateParentTrack() end
    -- GetSampleTracks(parent_track)
end

return gpmsys_samples