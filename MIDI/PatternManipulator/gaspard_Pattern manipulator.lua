--@description Pattern Manipulator
--@author gaspard
--@version 0.0.5b
--@provides
--    [nomain] Utilities/*.lua
--@changelog
--  - ADSR:
--    - Sliders
--    - Display on waveform
--  - Sample offset start and end:
--    - Sliders
--    - Display on waveform
--  - Note and PianoRoll System:
--    - Note names displayed in MIDI inputs track's PianoRoll
--    - Fix numerous crashes
--    - Upgrade note selection system
--  - Other:
--    - Fix numerous crashes
--    - Add Escape key quit app window
--    - Update GUI elements
--@about
--  # Pattern manipulator
--  Set racks of samples to manipulate using midi patterns.
--  ### Sampler
--  * The sampler stores and displays sample files dragged and dropped from explorer/finder.
--  * Available: name, color, waveform display, midi note, ADSR, play, mute, solo (and more to come).
--  * You can drop multiple files at once to import.
--  * To replace a sample file in an existing slot: select slot and drop new file on waveform.
--  * You can reorder the list using both tracks in Reaper TCP and in GUI.
--  ### Patterns
--  * The patterns is a visual display of midi files gathered from a folder path (in settings).
--  * You can drag and drop from the list into a Reaper track to insert the pattern at mouse cursor position.
--  * Pattern paths can be added or removed from the settings tab (and force rescanned).

local function FindKey(key)
  local symbol_map = {
    ["&"] = "Ampersand",
    ["'"] = "Apostrophe",
    ["*"] = "Asterisk",
    ["\\"] = "Backslash",
    [":"] = "Colon",
    [","] = "Comma",
    ["$"] = "Dollar",
    ["="] = "Equal",
    [">"] = "Greater",
    ["`"] = "Grave",
    ["#"] = "Hash",
    ["["] = "LeftBracket",
    ["{"] = "LeftBrace",
    ["("] = "LeftParen",
    ["<"] = "Less",
    ["-"] = "Minus",
    ["!"] = "Exclam",
    ["%"] = "Percent",
    ["|"] = "Pipe",
    [")"] = "RightParen",
    ["]"] = "RightBracket",
    ["}"] = "RightBrace",
    [";"] = "Semicolon",
    ["/"] = "Slash",
    [" "] = "Space",
    ["."] = "Period",
    ["+"] = "Plus",
    ['"'] = "Quote",
    ["?"] = "Question",
    ["^"] = "Caret",
    ["@"] = "At",
    ["_"] = "Underscore",
    ["~"] = "Tilde"
  }

  local num = tonumber(key)
  --reaper.ShowConsoleMsg(tostring(num).."\n")
  --reaper.ShowConsoleMsg(tostring("ImGui_Key_"..key).."\n")
  if num then
    local text_num = tostring(num)
    imgui_key = reaper["ImGui_Key_"..text_num]()
  elseif symbol_map[key] then
    reaper.ShowConsoleMsg(tostring(symbol_map[key]).."\n")
    --reaper.ImGui_Key_DownArrow()
    imgui_key = reaper["ImGui_Key_".."Space"]()
  else
    imgui_key = reaper["ImGui_Key_".."Q"]()
  end
  return imgui_key
end

-- Toggle button state in Reaper
function SetButtonState(set)
    local is_new, name, sec, cmd = reaper.get_action_context() --[cmd], rel, res, val, context
    --[[if is_new then
      shortcut_list = {}
      local shortcut_count = reaper.CountActionShortcuts(sec, cmd)
      for i = 1, shortcut_count do
        local retval, key = reaper.GetActionShortcutDesc(sec, cmd, i - 1)
        if retval then
          shortcut_list[i] = FindKey(key)
        end
      end
    end]]

    if set == 1 then
      action_name = string.match(name, 'gaspard_(.-)%.lua')
      -- Get version from ReaPack
      local pkg = reaper.ReaPack_GetOwner(name)
      version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
      reaper.ReaPack_FreeEntry(pkg)
      shortcut_activated = true
    end
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

-- Load Utilities
dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.9.3.2') -- current version at the time of writing the script

script_path = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]
package.path = package.path..';'..script_path .. '?.lua' -- GET DIRECTORY FOR REQUIRE
gpmsys = require('Utilities/gpm_System')
gpmgui = require('Utilities/gpm_DisplayWindow')

local json_file_path = reaper.GetResourcePath()..'/Scripts/Gaspard ReaScripts/JSON'
package.path = package.path .. ';' .. json_file_path .. '/?.lua'
gson = require('json_utilities_lib')

settings_path = script_path..'Utilities/gaspard_'..action_name..'_settings.json'

gpmsys.Init()

reaper.defer(gpmgui.Loop)
reaper.atexit(SetButtonState)
