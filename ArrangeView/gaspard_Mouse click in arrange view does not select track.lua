--@description Mouse click in arrange view does not select track
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Mouse click in arrange view does not select track

local function SetButtonState(set)
    local _, _, sec, cmd, _, _, _ = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

local track_sel_mouse = reaper.SNM_GetIntConfigVar("trackselonmouse", 0)
local tselm

local function Loop()
    reaper.defer(Loop)
end

local function Exit()
    tselm = track_sel_mouse | (track_sel_mouse | 1)
    reaper.SNM_SetIntConfigVar("trackselonmouse", tselm)
    SetButtonState(0)
end

if track_sel_mouse == 0 then
    --tselm = track_sel_mouse | (track_sel_mouse | 1)
    --reaper.SNM_SetIntConfigVar("trackselonmouse", tselm)
else
    tselm = track_sel_mouse &~ (track_sel_mouse  &1)
    reaper.SNM_SetIntConfigVar("trackselonmouse", tselm)
    reaper.defer(Loop)
end

reaper.atexit(Exit)