--@noindex
--@description Pattern generator
--@author gaspard
--@version 0.0.1b
--@changelog
--  - Add script
--@about
--  ### MIDI item
--  - Create MIDI item on new track with ReaSamplOmatic5000


function DrawTopBar()
    local function beginRightIconMenu(ctx, buttons)
        local windowEnd = app.gui.mainWindow.size[1] - ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding) -
            ((ImGui.GetScrollMaxY(app.gui.ctx) > 0) and ImGui.GetStyleVar(ctx, ImGui.StyleVar_ScrollbarSize) or 0)
        ImGui.SameLine(ctx, windowEnd)
        ImGui.PushFont(ctx, app.gui.st.fonts.icons_large)
        local clicked = nil
        local prevX = ImGui.GetCursorPosX(ctx) - ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)
        for i, btn in ipairs(buttons) do
            local w = select(1, ImGui.CalcTextSize(ctx, ICONS[(btn.icon):upper()])) +
                ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding) * 2
            local x = prevX - w - ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)
            prevX = x
            ImGui.SetCursorPosX(ctx, x)
            if app.iconButton(ctx, btn.icon, app.gui.st.col.buttons.topBarIcon) then clicked = btn.icon end
            app:setHoveredHint('main', btn.hint)
        end
        ImGui.PopFont(ctx)
        return clicked ~= nil, clicked
    end


    local ctx = app.gui.ctx
    ImGui.BeginGroup(ctx)
    ImGui.PushFont(ctx, app.gui.st.fonts.large_bold)
    app.gui:pushColors(app.gui.st.col.title)
    ImGui.AlignTextToFramePadding(ctx)
    ImGui.Text(ctx, app.scr.name)
    app:setHoveredHint('main', app.scr.name .. ' v' .. app.scr.version .. ' by ' .. app.scr.author)
    app.gui:popColors(app.gui.st.col.title)
    ImGui.PopFont(ctx)
    ImGui.PushFont(ctx, app.gui.st.fonts.large)
    ImGui.SameLine(ctx)
    if app.db.track and next(app.db.track) then
        ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing) * 2)
        local col = app.db.track.color
        if col ~= 0x000000ff then
            local x, y = ImGui.GetCursorScreenPos(ctx)
            local h = select(2, ImGui.CalcTextSize(ctx, app.db.track.name))
            local padding = { ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding) }
            h = h
            y = y + padding[2]
            rad = h / 4
            ImGui.DrawList_AddRectFilled(app.gui.draw_list, x - h / 4, y + h / 4, x + h / 4, y + h / (4 / 3), col, 2)
            ImGui.AlignTextToFramePadding(ctx)
            ImGui.SetCursorPosX(ctx,
                ImGui.GetCursorPosX(ctx) + rad + ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing) * 2)
        end
        ImGui.BeginDisabled(ctx)
        ImGui.Text(ctx, app.db.track.name)
        ImGui.EndDisabled(ctx)
    end
    local caption = app.db.track and app.db.track.name or ''
    ImGui.BeginDisabled(ctx)
    if app.page == APP_PAGE.SEARCH_SEND then
        caption = ('Add %s'):format(app.temp.addSendType == SEND_TYPE.SEND and 'send' or 'receive')
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, " | " .. caption)
    end
    ImGui.EndDisabled(ctx)
    local menu = {}
    if app.page == APP_PAGE.MIXER then
        table.insert(menu, { icon = 'close', hint = 'Close' })
        table.insert(menu, { icon = 'gear', hint = 'Settings' })
    elseif app.page == APP_PAGE.NO_TRACK then
        table.insert(menu, { icon = 'close', hint = 'Close' })
        table.insert(menu, { icon = 'gear', hint = 'Settings' })
    elseif app.page == APP_PAGE.SEARCH_SEND or app.page == APP_PAGE.SEARCH_FX then
        table.insert(menu, { icon = 'right', hint = 'Back' })
        table.insert(menu, { icon = 'gear', hint = 'Settings' })
    end
    if ImGui.IsWindowDocked(ctx) then
        table.insert(menu, { icon = 'undock', hint = 'Undock' })
    else
        table.insert(menu, { icon = 'dock_down', hint = 'Dock' })
    end
    table.insert(menu, { icon = 'money', hint = ('%s is free, but donations are welcome :)'):format(Scr.name) })
    local rv, btn = beginRightIconMenu(ctx, menu)
    ImGui.PopFont(ctx)
    ImGui.EndGroup(ctx)
    ImGui.Separator(ctx)
    if rv then
        if btn == 'close' then
            app.exit = true
        elseif btn == 'undock' then
            app.gui.mainWindow.dockTo = 0
        elseif btn == 'dock_down' then
            if app.settings.current.lastDockId then
                app.gui.mainWindow.dockTo = app.settings.current.lastDockId
            else
                app:msg(T.ERROR.NO_DOCK)
            end
        elseif btn == 'gear' then
            ImGui.OpenPopup(ctx, Scr.name .. ' Settings##settingsWindow')
        elseif btn == 'right' then
            app.setPage(APP_PAGE.MIXER)
        elseif btn == 'money' then
            OD_OpenLink(Scr.donation)
        end
    end
end
