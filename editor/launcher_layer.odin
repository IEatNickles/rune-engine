package editor

import imgui "deps/odin-imgui"
import "deps/odin-imgui/imgui_impl_glfw"
import "deps/odin-imgui/imgui_impl_opengl3"

import "../rune_engine/"

LauncherLayer :: struct {}

launcher_on_attach :: proc(self: ^LauncherLayer) {
	window := rune_engine.get_window().handle

	imgui.CHECKVERSION()
	imgui.create_context()
	io := imgui.get_io()
	io.config_flags += {.Nav_Enable_Keyboard, .Nav_Enable_Gamepad}
	io.config_flags += {.Docking_Enable}

	when ENABLE_IMGUI_VIEWPORTS {
		io.config_flags += {.Viewports_Enable}
		style := imgui.get_style()
		style.window_rounding = 0
		style.colors[imgui.Col.Window_Bg].w = 1
	}

	imgui_style_colors_default()

	imgui_impl_glfw.init_for_open_gl(window, true)
	imgui_impl_opengl3.init("#version 410")
}

launcher_on_update :: proc(self: ^LauncherLayer) {
	imgui_impl_opengl3.new_frame()
	imgui_impl_glfw.new_frame()
	imgui.new_frame()

	imgui.render()
	imgui_impl_opengl3.render_draw_data(imgui.get_draw_data())

	when ENABLE_IMGUI_VIEWPORTS {
		backup_current_window := glfw.GetCurrentContext()
		imgui.update_platform_windows()
		imgui.render_platform_windows_default()
		glfw.MakeContextCurrent(backup_current_window)
	}
}

launcher_on_detach :: proc(self: ^LauncherLayer) {
	imgui_impl_opengl3.shutdown()
	imgui_impl_glfw.shutdown()
	imgui.destroy_context()
}
