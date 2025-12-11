--@noindex
--@description Highlight key range on virtual MIDI keyboard
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Highlight key range on virtual MIDI keyboard.

local function SetButtonState(set)
    local _, _, sec, cmd, _, _, _ = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

-- VARIABLES
local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_TopMost()
    | reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoResize()
local prev_x = nil

-- FUNCTIONS
local function GetVMK()
    local h = reaper.JS_Window_Find("Virtual MIDI Keyboard", true)
    if not h then return nil end
    local _, l, t, r, b = reaper.JS_Window_GetClientRect(h)
    local x, y = reaper.JS_Window_ClientToScreen(h,0,0)
    return x, y, r-l, b-t
end

function KeyAsPos(note, vmk_w)
    local w = 0
    for n = 0, note-1 do
        local m = n % 12
        if m==0 or m==2 or m==4 or m==5 or m==7 or m==9 or m==11 then
            w = w + 1
        end
    end
    return w * (vmk_w / 75)  -- 75 white keys from 0–127
end


-- Loop function
local function Loop()
    local x, y, w, h = GetVMK()
    if x then
        local track_count = reaper.CountSelectedTracks(0)
        if track_count > 0 then
            local track = reaper.GetSelectedTrack(0, 0)
            local retval, key_range = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:OverlayKeyRangeVMK", "", false)
            if retval then
                local first, last = key_range:match("(%d+)%/(%d+)")
                local a = KeyAsPos(first, w)
                w = KeyAsPos(last + 1, w) - a
                x = x + a
            end
        end
        if not prev_x then
            ctx = reaper.ImGui_CreateContext('vmk_highlight_context')
            prev_x = x
        end
        reaper.ImGui_SetNextWindowSize(ctx, w, h)
        reaper.ImGui_SetNextWindowPos(ctx, x, y)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0xAA00AAAA)
        visible, open = reaper.ImGui_Begin(ctx, "OverlayKeyRangeVMK", true, window_flags)
        reaper.ImGui_End(ctx)
        reaper.ImGui_PopStyleColor(ctx, 1)
    else
        prev_x = x
    end
    reaper.defer(Loop)
end

-- Start loop
reaper.defer(Loop)
reaper.atexit(SetButtonState)
