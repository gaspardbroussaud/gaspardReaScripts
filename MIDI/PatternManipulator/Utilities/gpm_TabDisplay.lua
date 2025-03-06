--@noindex

local window_tabs = {}

function window_tabs.Show()
    local child_width = (og_window_width - 20) / 2 -- = a default width of 200 with og_window_width at 850
    local child_height = (window_height - topbar_height - small_font_size - 30)
    if reaper.ImGui_BeginChild(ctx, "child_tabs", child_width, child_height, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then

        if reaper.ImGui_BeginTabBar(ctx, "tab_controls") then
            if reaper.ImGui_BeginTabItem(ctx, "Sampler") then
                reaper.ImGui_Text(ctx, "Main sampler tab with params.")
                reaper.ImGui_EndTabItem(ctx)
            end
            if reaper.ImGui_BeginTabItem(ctx, "Patterns") then
                reaper.ImGui_Text(ctx, "Pattern related stuff.")
                reaper.ImGui_EndTabItem(ctx)
            end
            if reaper.ImGui_BeginTabItem(ctx, "Settings") then
                reaper.ImGui_Text(ctx, "Welcome to settings.")
                reaper.ImGui_EndTabItem(ctx)
            end
            reaper.ImGui_EndTabBar(ctx)
        end

        reaper.ImGui_EndChild(ctx)
    end
end

return window_tabs
