-- @description Test ImGui
-- @author gaspard
-- @version 1.0
-- @about
--   This is a test of ImGui.

function GuiInit()
    ctx = reaper.ImGui_CreateContext('Item Sequencer') -- Add VERSION TODO
    FONT = reaper.ImGui_CreateFont('sans-serif', 15) -- Create the fonts you need
    reaper.ImGui_Attach(ctx, FONT)-- Attach the fonts you need
end

function loop()

    local window_flags = reaper.ImGui_WindowFlags_MenuBar() 
    reaper.ImGui_SetNextWindowSize(ctx, 250, 300, reaper.ImGui_Cond_Once())-- Set the size of the windows.  Use in the 4th argument reaper.ImGui_Cond_FirstUseEver() to just apply at the first user run, so ImGUI remembers user resize s2
    reaper.ImGui_PushFont(ctx, FONT) -- Says you want to start using a specific font

    local visible, open  = reaper.ImGui_Begin(ctx, 'Testing ImGui', true, window_flags)

    if visible then
        --------
        --YOUR GUI HERE
        --------
        reaper.ImGui_End(ctx)
    end 


    reaper.ImGui_PopFont(ctx) -- Pop Font

    if open then
        reaper.defer(loop)
    else
        reaper.ImGui_DestroyContext(ctx)
    end
end

GuiInit()
loop()
