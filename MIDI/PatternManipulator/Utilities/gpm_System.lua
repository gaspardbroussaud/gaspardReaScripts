--@noindex

local gpmsys = {}

-- Samples variables
gpmsys_samples = require("Utilities/gpm_Sys_Samples")

function gpmsys.Init()
    gpmsys_samples.CheckForSampleTracks()
end

return gpmsys
