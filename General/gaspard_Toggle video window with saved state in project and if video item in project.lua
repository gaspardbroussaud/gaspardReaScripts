--@description Toggle video window with saved state in project and if video item in project
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Toggle video window with saved state in project and if video item in project.

local function SetButtonState(set)
    local _, _, sec, cmd, _, _, _ = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

local function HasVideoItem()
    for i = 0, reaper.CountMediaItems(0)-1 do
        local item = reaper.GetMediaItem(0, i)
        if item then
            local take = reaper.GetActiveTake(item)
            if take then
                local src = reaper.GetMediaItemTake_Source(take)
                local t = reaper.GetMediaSourceType(src, ""):upper()
                if t == "VIDEO" or t == "VIDEOEFFECT" then
                    return true
                end
            end
        end
    end
    return false
end

local project = nil

local function Loop()
    cur_project = reaper.GetProjectPathEx(0)
    if cur_project ~= project then
        local is_show = reaper.GetProjExtState(0, "VideoWindowDisplay", "is_show") == 1
        if is_show and HasVideoItem() then
            -- Show video window
            if reaper.GetToggleCommandState(50125) == 0 then
                reaper.Main_OnCommand(50125, 0)
            end
        else
            -- Hide video window
            if reaper.GetToggleCommandState(50125) == 1 then
                reaper.Main_OnCommand(50125, 0)
            end
        end
        project = cur_project
    end
    reaper.defer(Loop)
end

reaper.defer(Loop)

reaper.atexit(SetButtonState)
