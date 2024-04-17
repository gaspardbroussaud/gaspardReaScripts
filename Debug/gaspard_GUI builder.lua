--@description GUI builder
--@author gaspard
--@version 1.0
--@changelog WIP
--@about WIP GUI construction for another script

function GuiInit()
    ctx = reaper.ImGui_CreateContext('Region Tool')
    FONT = reaper.ImGui_CreateFont('sans-serif', 15)
    reaper.ImGui_Attach(ctx, FONT)
    winW, winH = 400, 350
    isClosed = false
    r_name = 0
end

function helperTooltip(debug)
    reaper.ImGui_TextDisabled(ctx, '(?)')
    if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayShort()) and reaper.ImGui_BeginTooltip(ctx) then
        reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetFontSize(ctx) * 35.0)
        reaper.ImGui_Text(ctx, debug)
        reaper.ImGui_PopTextWrapPos(ctx)
        reaper.ImGui_EndTooltip(ctx)
    end
end

function GuiElements()
    -- Global settings and region render matrix options --
    if reaper.ImGui_BeginTable(ctx, 'GuiTableRRM', 2) then
        reaper.ImGui_TableNextRow(ctx)
        -- First column --
        reaper.ImGui_TableSetColumnIndex(ctx, 0)
        
        reaper.ImGui_Text(ctx, 'Settings')
        
        rv_an, cb_an = reaper.ImGui_Checkbox(ctx, 'Auto Number', cb_an); reaper.ImGui_SameLine(ctx)
        helperTooltip('Add a suffix number for regions in timeline order and with name aware numbering')
        
        rv_fs, cb_fs = reaper.ImGui_Checkbox(ctx, 'Folder Sensitive', cb_fs); reaper.ImGui_SameLine(ctx)
        helperTooltip('Cluster detection will take into acount the folder hierarchy')
        
        reaper.ImGui_Text(ctx, 'Slider for cluster intern space')
        rv_slider, interCluster = reaper.ImGui_SliderDouble(ctx, '##sliderInterCluster', interCluster, 0, 10)
        
        -- Second column --
        reaper.ImGui_TableSetColumnIndex(ctx, 1)
        
        reaper.ImGui_Text(ctx, 'Region Render Matrix'); reaper.ImGui_SameLine(ctx)
        helperTooltip('Select a render matrix setting to apply for given items regions')
        
        rv_rrm_st, cb_rrm_st = reaper.ImGui_Checkbox(ctx, 'Selected track', cb_rrm_st)
        rv_rrm_it, cb_rrm_it = reaper.ImGui_Checkbox(ctx, 'Items track', cb_rrm_it)
        rv_rrm_pt, cb_rrm_pt = reaper.ImGui_Checkbox(ctx, 'Parent track', cb_rrm_pt)
        rv_rrm_tpt, cb_rrm_tpt = reaper.ImGui_Checkbox(ctx, 'Top Parent track', cb_rrm_tpt)
        
        reaper.ImGui_EndTable(ctx)
    end
    
    -- Space between setting options --
    reaper.ImGui_Dummy(ctx, 100, 30)
    
    -- Renaming settings --
    reaper.ImGui_Text(ctx, 'Renaming options'); reaper.ImGui_SameLine(ctx)
    helperTooltip('Enter text in textbox for "Custom name" option otherwise the regions name will be blank')
    
    if reaper.ImGui_BeginTable(ctx, 'GuiTableName', 2) then
        reaper.ImGui_TableNextRow(ctx)
        -- Custom name textbox input --
        reaper.ImGui_TableSetColumnIndex(ctx, 0)
        reaper.ImGui_Text(ctx, 'Custom Name:'); reaper.ImGui_SameLine(ctx)
        rv_text_custom, text_custom = reaper.ImGui_InputText(ctx, '##inputText', text_custom, reaper.ImGui_InputTextFlags_AutoSelectAll())
        
        -- Renaming option choice --
        reaper.ImGui_TableSetColumnIndex(ctx, 1)
        rv, r_name = reaper.ImGui_RadioButtonEx(ctx, 'Custom name', r_name, 0)
        rv, r_name = reaper.ImGui_RadioButtonEx(ctx, 'Selected track name', r_name, 1)
        rv, r_name = reaper.ImGui_RadioButtonEx(ctx, 'Items track name', r_name, 2)
        rv, r_name = reaper.ImGui_RadioButtonEx(ctx, 'Parent track name', r_name, 3)
        rv, r_name = reaper.ImGui_RadioButtonEx(ctx, 'Top Parent track name', r_name, 4)
        
        reaper.ImGui_EndTable(ctx)
    end
    
    if reaper.ImGui_Button(ctx, 'Confirm') then
        ConfirmButton()
        isClosed = true
    end; reaper.ImGui_SameLine(ctx)
    
    helperTooltip('"Confirm" will apply values from selected settings and close the window')
end

function GuiLoop()
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse()
    reaper.ImGui_SetNextWindowSize(ctx, winW, winH, reaper.ImGui_Cond_Once())
    reaper.ImGui_PushFont(ctx, FONT)
    reaper.ImGui_SetConfigVar(ctx, reaper.ImGui_ConfigVar_ViewportsNoDecoration(), 0)
    
    local visible, open = reaper.ImGui_Begin(ctx, 'Region Renaming Tool', true, window_flags)
    
    if visible then
        
        GuiElements()
        
        reaper.ImGui_End(ctx)
    end
    
    reaper.ImGui_PopFont(ctx)
    
    if open and not isClosed then
        reaper.defer(GuiLoop)
    else
        reaper.ImGui_DestroyContext(ctx)
    end
end

function main()
    GuiInit()
    GuiLoop()
end

function ConfirmButton()
    reaper.ShowConsoleMsg("Name choice: "..tostring(r_name))
    reaper.ShowConsoleMsg("\nRRM: "..tostring(cb_rrm_st).." | "..tostring(cb_rrm_it).." | "..tostring(cb_rrm_pt).." | "..tostring(cb_rrm_tpt))
    reaper.ShowConsoleMsg("\nSlider: "..tostring(interCluster))
end

-- MAIN CRIPT EXECUTION --
reaper.PreventUIRefresh(1)
--reaper.Undo_BeginBlock()
main()
--reaper.Undo_EndBlock('Region Renaming Tool used', -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
