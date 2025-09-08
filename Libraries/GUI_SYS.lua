--@noindex
--@author gaspard
--@version 1.0
--@provides [nomain] .

-- TEMPLATE IN SCRIPT:
--package.path = package.path .. ';' .. reaper.GetResourcePath()..'/Scripts/Gaspard ReaScripts/Libraries' .. '/?.lua'
--local GUI_SYS = require('GUI_SYS')
local GUI_STYLE = dofile("C:/Users/Gaspard/Documents/gaspardReaScripts/Libraries/GUI_STYLE.lua")
--reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/Libraries/GUI_STYLE.lua")

local _gui_sys = {}

_gui_sys.IconButton = function(ctx, icon, right_click)
    local x, y = reaper.ImGui_GetCursorPos(ctx)
    local w = select(1, reaper.ImGui_CalcTextSize(ctx, icon)) + (reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding()) * 2)
    local clicked = reaper.ImGui_InvisibleButton(ctx, '##menuBtn' .. icon, w, reaper.ImGui_GetTextLineHeightWithSpacing(ctx))
    if right_click then
        clicked = clicked and clicked or reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseClicked(ctx, reaper.ImGui_MouseButton_Right()) or false
    end
    if reaper.ImGui_IsItemHovered(ctx) and not reaper.ImGui_IsItemActive(ctx) then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), reaper.ImGui_GetStyleColor(ctx, reaper.ImGui_Col_ButtonHovered()))
    elseif reaper.ImGui_IsItemActive(ctx) then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), reaper.ImGui_GetStyleColor(ctx, reaper.ImGui_Col_ButtonActive()))
    else
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), reaper.ImGui_GetStyleColor(ctx, reaper.ImGui_Col_Button()))
    end
    reaper.ImGui_SetCursorPos(ctx, x + reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding()),
        y + select(2, reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())))
    reaper.ImGui_Text(ctx, icon)
    reaper.ImGui_PopStyleColor(ctx, 1)
    reaper.ImGui_SetCursorPos(ctx, x + w, y)
    return clicked
end

_gui_sys.IconButtonRight = function(ctx, buttons, window_width)
    local windowEnd = window_width - reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding())
    -- - ((reaper.ImGui_GetScrollMaxY(ctx) > 0) and reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarSize()) or 0)
    reaper.ImGui_SameLine(ctx, windowEnd)
    local clicked = nil
    local prevX = reaper.ImGui_GetCursorPosX(ctx) - reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())
    for _, button in ipairs(buttons) do
        local w = select(1, reaper.ImGui_CalcTextSize(ctx, GUI_STYLE[button.icon])) + (reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding()) * 2)
        local x = prevX - w - (reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing()) * 3)
        prevX = x
        reaper.ImGui_SetCursorPosX(ctx, x)
        if _gui_sys.IconButton(ctx, GUI_STYLE.ICONS[button.icon], button.right_click) then clicked = button.icon end
    end
    return clicked ~= nil, clicked
end

return _gui_sys
