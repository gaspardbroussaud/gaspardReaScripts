--@noindex

local window_tabs = {}

tab_sampler = require("Utilities/gpm_DisplayTabSampler")
tab_patterns = require("Utilities/gpm_DisplayTabPatterns")
tab_settings = require("Utilities/gpm_DisplayTabSettings")

function window_tabs.Show()
    local child_width = reaper.ImGui_GetContentRegionAvail(ctx) - (global_spacing * 2) --(og_window_width - 20) / 2 -- = a default width of 200 with og_window_width at 850
    local child_height = (window_height - topbar_height - small_font_size - 30)
    if reaper.ImGui_BeginChild(ctx, "child_tabs", child_width, child_height, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then

        if reaper.ImGui_BeginTabBar(ctx, "tab_controls") then
            if reaper.ImGui_BeginTabItem(ctx, "Sampler") then
                tab_sampler.Show()
                reaper.ImGui_EndTabItem(ctx)
            end
            if reaper.ImGui_BeginTabItem(ctx, "Patterns") then
                tab_patterns.Show()
                reaper.ImGui_EndTabItem(ctx)
            end
            if reaper.ImGui_BeginTabItem(ctx, "Settings") then
                tab_settings.Show()
                reaper.ImGui_EndTabItem(ctx)
            end
            reaper.ImGui_EndTabBar(ctx)
        end

        reaper.ImGui_EndChild(ctx)
    end
end

return window_tabs
