--@description Check once a day on launch
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Check once a day on launch

local section, key = "CHECK_ONCE_A_DAY", "DATE"

local date = os.date("%Y-%m-%d")

local last_date = reaper.GetExtState(section, key)
--last_date = last_date == nil and "" or last_date

if date ~= last_date then
    -- Sync Reapack extensions
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_REAPACK_SYNC"), 0)

    reaper.SetExtState(section, key, date, true)
end
