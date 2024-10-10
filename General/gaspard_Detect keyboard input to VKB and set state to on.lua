-- @description Detect keyboard input to VKB and set state to on
-- @author gaspard
-- @version 1.0.0
-- @changelog • Initial release
-- @about Get "Virtual MIDI keyboard: Send all input to VKB" command state and set to 1 if 0.

-- ID 40637 = Virtual MIDI keyboard: Send all input to VKB
if reaper.GetToggleCommandState(40637) < 1 then reaper.Main_OnCommand(40637, 0) end

