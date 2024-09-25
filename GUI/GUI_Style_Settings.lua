-- @noindex

function GUI_Style_Var_Global()
	style_var_table = {}
	style_var_table[0] = { variable = reaper.ImGui_StyleVar_WindowRounding(), value = 6 }
	style_var_table[1] = { variable = reaper.ImGui_StyleVar_ChildRounding(), value = 6 }
	style_var_table[2] = { variable = reaper.ImGui_StyleVar_PopupRounding(), value = 6 }
	style_var_table[3] = { variable = reaper.ImGui_StyleVar_FrameRounding(), value = 6 }
	return style_var_table
end

function GUI_Style_Color_Global()
	style_color_table = {}
	style_color_table[0] = { variable = reaper.ImGui_Col_WindowBg(), value = 0x111111FF }
	return style_color_table
end
