package editor

import "../rune_engine/"
import "../rune_engine/rendering/"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:strconv"
import "core:strconv/decimal"
import "core:strings"

import imgui "deps/odin-imgui"
import "deps/odin-imgui/imgui_impl_glfw"
import "deps/odin-imgui/imgui_impl_opengl3"

import gl "vendor:OpenGL"
import "vendor:glfw"

ENABLE_IMGUI_VIEWPORTS :: false

EditorLayer :: struct {
	active_scene:           ^rune_engine.Scene,
	viewport_aspect:        f32,
	show_imgui_demo_window: bool,
	poopy:                  u32,
	fbo:                    rendering.Framebuffer,
	fbt:                    rendering.Texture,
	camera_pos:             [3]f32,
	camera_rot:             [2]f32,
	start_camera_rot:       [2]f32,
}

editor_layer_on_attach :: proc(self: ^EditorLayer) {
	rune_engine.set_clear_color({0.2, 0.5, 0.8, 1})

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

	tex := rune_engine.load_texture("assets/textures/doodoo.png")
	rune_engine.bind_texture(tex)

	self.active_scene = rune_engine.scene_create("Fart")
	monky := rune_engine.load_model_gltf("assets/models/moky.glb")
	e := rune_engine.create_entity(self.active_scene)
	e2 := rune_engine.create_entity(self.active_scene)
	e3 := rune_engine.create_entity(self.active_scene)
	e4 := rune_engine.create_entity(self.active_scene)
	rune_engine.add_component(
		self.active_scene,
		e,
		rune_engine.TransformComponent {
			{0, 0, 3},
			linalg.quaternion_from_pitch_yaw_roll_f32(0, 0, 0),
			{1, 1, 1},
		},
	)
	rune_engine.add_component(
		self.active_scene,
		e,
		rune_engine.CameraComponent{110, 16.0 / 9.0, 0.1, 100.0},
	)
	rune_engine.add_component(
		self.active_scene,
		e2,
		rune_engine.TransformComponent{{0, 0, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
	)
	rune_engine.add_component(
		self.active_scene,
		e2,
		rune_engine.MeshRendererComponent{monky.meshes[0]},
	)
	rune_engine.add_component(
		self.active_scene,
		e3,
		rune_engine.TransformComponent{{0, 3, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
	)
	rune_engine.add_component(
		self.active_scene,
		e3,
		rune_engine.MeshRendererComponent{monky.meshes[0]},
	)
	rune_engine.add_component(
		self.active_scene,
		e3,
		rune_engine.RigidBodyComponent {
			type = .Dynamic,
			is_trigger = false,
			shape = rune_engine.SphereShape{radius = 1.0},
		},
	)

	rune_engine.add_component(
		self.active_scene,
		e4,
		rune_engine.TransformComponent {
			{0, -3, 0},
			linalg.quaternion_from_pitch_yaw_roll_f32(math.to_radians_f32(10), 0, 0),
			{1, 1, 1},
		},
	)
	rune_engine.add_component(
		self.active_scene,
		e4,
		rune_engine.RigidBodyComponent {
			type = .Static,
			is_trigger = false,
			//shape = rune_engine.BoxShape{extents = {20, 0.3, 20}},
			shape = rune_engine.PlaneShape{normal = {0, 1, 0}},
		},
	)

	self.viewport_aspect = 16.0 / 9.0
	self.show_imgui_demo_window = false

	t := rune_engine.load_texture("assets/textures/doodoo.png")
	self.poopy = cast(u32)t

	self.fbo = rune_engine.create_framebuffer()
	self.fbt = rune_engine.framebuffer_attach_texture(&self.fbo)
	self.camera_pos = {0, 0, 3}
}

editor_layer_on_update :: proc(self: ^EditorLayer) {
	imgui_impl_opengl3.new_frame()
	imgui_impl_glfw.new_frame()
	imgui.new_frame()

	if rune_engine.key_pressed(.Escape) {
		rune_engine.close()
	}

	if imgui.begin_main_menu_bar() {
		if imgui.begin_menu("File") {
			imgui.menu_item_bool_ptr("Show ImGUI Demo", nil, &self.show_imgui_demo_window)
			if imgui.menu_item("Exit", "Ctrl-Q") {
				rune_engine.transition_layer(
					EditorLayer,
					LauncherLayer,
					launcher_on_attach,
					launcher_on_update,
					launcher_on_detach,
				)
			}
			imgui.end_menu()
		}
		imgui.end_main_menu_bar()
	}

	imgui.dock_space_over_viewport()

	if self.show_imgui_demo_window do imgui.show_demo_window()

	imgui.begin("Viewport")
	region := imgui.get_content_region_avail()
	size := imgui.Vec2{region.x, region.x / self.viewport_aspect}
	if region.y < size.y {
		size.y = region.y
		size.x = size.y * self.viewport_aspect
	}
	imgui.set_cursor_pos_x(
		region.x / 2 - size.x / 2 + (imgui.get_style().display_window_padding.x) / 2,
	)
	imgui.set_cursor_pos_y(
		region.y / 2 -
		size.y / 2 +
		(imgui.get_style().window_padding.y + imgui.get_style().display_window_padding.y),
	)
	rune_engine.bind_framebuffer(&self.fbo)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	gl.Viewport(0, 0, 1920, 1080)
	rune_engine.begin_scene(
		linalg.matrix4_from_trs_f32(
			self.camera_pos,
			linalg.quaternion_from_euler_angles_f32(self.camera_rot.x, self.camera_rot.y, 0, .YXZ),
			[3]f32{1, 1, 1},
		),
		linalg.matrix4_perspective_f32(math.to_radians_f32(100), 16.0 / 9.0, 0.1, 100.0),
	)
	rune_engine.draw_scene(self.active_scene)
	rune_engine.bind_framebuffer(nil)
	imgui.image({nil, u64(self.fbt)}, size, imgui.Vec2{0, 1}, imgui.Vec2{1, 0})
	if imgui.is_mouse_dragging(.Right) {
		rune_engine.set_cursor_state(.LockedAndHidden)
		drag := imgui.get_mouse_drag_delta(.Right)
		self.camera_rot = self.start_camera_rot - drag * 0.01
	} else {
		rune_engine.set_cursor_state(.Visible)
		self.start_camera_rot = self.camera_rot
	}
	imgui.end()

	imgui.begin("Scene")
	if self.active_scene != nil {
		if imgui.tree_node_ex(
			cast(cstring)raw_data(self.active_scene.name),
			{.Framed, .Default_Open, .Span_Full_Width},
		) {
			for e in self.active_scene.ecs_world.entity_index {
				if e in self.active_scene.ecs_world.component_info do continue
				sb, err := strings.builder_make_none()
				fmt.sbprint(&sb, cast(u64)e)
				if imgui.tree_node_ex(cast(cstring)raw_data(strings.to_string(sb)), imgui.Tree_Node_Flags{.Leaf, .Span_Full_Width}) do imgui.tree_pop()
			}
			imgui.tree_pop()
		}
	}
	imgui.end()

	imgui.begin("Assets")
	imgui.end()

	imgui.begin("Inspector")
	imgui.end()

	imgui.begin("Console")
	imgui.end()

	imgui.render()
	imgui_impl_opengl3.render_draw_data(imgui.get_draw_data())

	when ENABLE_IMGUI_VIEWPORTS {
		backup_current_window := glfw.GetCurrentContext()
		imgui.update_platform_windows()
		imgui.render_platform_windows_default()
		glfw.MakeContextCurrent(backup_current_window)
	}
}

editor_layer_on_detach :: proc(self: ^EditorLayer) {
	imgui_impl_opengl3.shutdown()
	imgui_impl_glfw.shutdown()
	imgui.destroy_context()
}

imgui_style_colors_default :: proc() {
	imgui.get_style().window_menu_button_position = .Right
	imgui.get_style().alpha = 1.0
	imgui.get_style().disabled_alpha = 0.6
	imgui.get_style().window_padding = {8, 8}
	imgui.get_style().window_rounding = 0
	imgui.get_style().window_border_size = 1
	imgui.get_style().window_border_hover_padding = 4
	imgui.get_style().window_min_size = {1, 1}
	imgui.get_style().window_title_align = {0, 0.5}
	imgui.get_style().window_menu_button_position = .Right
	imgui.get_style().child_rounding = 0
	imgui.get_style().child_border_size = 1
	imgui.get_style().popup_rounding = 0
	imgui.get_style().popup_border_size = 1
	imgui.get_style().frame_padding = {4, 3}
	imgui.get_style().frame_rounding = 0
	imgui.get_style().frame_border_size = 0
	imgui.get_style().item_spacing = {8, 4}
	imgui.get_style().item_inner_spacing = {4, 4}
	imgui.get_style().cell_padding = {4, 2}
	imgui.get_style().touch_extra_padding = {0, 0}
	imgui.get_style().indent_spacing = 21
	imgui.get_style().columns_min_spacing = 0
	imgui.get_style().scrollbar_size = 14
	imgui.get_style().scrollbar_rounding = 8
	imgui.get_style().grab_min_size = 12
	imgui.get_style().grab_rounding = 0
	imgui.get_style().log_slider_deadzone = 4
	imgui.get_style().image_border_size = 0
	imgui.get_style().tab_rounding = 4
	imgui.get_style().tab_border_size = 0
	imgui.get_style().tab_close_button_min_width_selected = -1
	imgui.get_style().tab_close_button_min_width_unselected = 0
	imgui.get_style().tab_bar_border_size = 1
	imgui.get_style().tab_bar_overline_size = 0
	imgui.get_style().table_angled_headers_angle = 35
	imgui.get_style().table_angled_headers_text_align = {0.5, 0}
	imgui.get_style().color_button_position = .Right
	imgui.get_style().button_text_align = {0.5, 0.5}
	imgui.get_style().selectable_text_align = {0, 0}
	imgui.get_style().separator_text_border_size = 3
	imgui.get_style().separator_text_align = {0, 0.5}
	imgui.get_style().separator_text_padding = {20, 0}
	imgui.get_style().display_window_padding = {19, 19}
	imgui.get_style().display_safe_area_padding = {3, 3}
	imgui.get_style().docking_separator_size = 2
	imgui.get_style().mouse_cursor_scale = 1
	imgui.get_style().anti_aliased_lines = true
	imgui.get_style().anti_aliased_lines_use_tex = true
	imgui.get_style().anti_aliased_fill = true
	imgui.get_style().curve_tessellation_tol = 1.25
	imgui.get_style().circle_tessellation_max_error = 0.3
	imgui.get_style().hover_stationary_delay = 0.5
	imgui.get_style().hover_delay_short = 0.25
	imgui.get_style().hover_delay_normal = 0.5
	imgui.get_style().hover_flags_for_tooltip_mouse = {.Delay_Short, .Stationary}
	imgui.get_style().hover_flags_for_tooltip_nav = {.Delay_Normal, .No_Shared_Delay}
	imgui.get_style().tree_lines_rounding = 0
	imgui.get_style().tree_lines_flags = {.Draw_Lines_To_Nodes}
	imgui.get_style().tree_lines_size = 2

	colors := &imgui.get_style().colors
	colors[imgui.Col.Text] = imgui.Vec4{1.00, 1.00, 1.00, 1.00}
	colors[imgui.Col.Text_Disabled] = imgui.Vec4{0.50, 0.50, 0.50, 1.00}
	colors[imgui.Col.Window_Bg] = imgui.Vec4{0.09, 0.15, 0.21, 1.00}
	colors[imgui.Col.Child_Bg] = imgui.Vec4{0.00, 0.00, 0.00, 0.00}
	colors[imgui.Col.Popup_Bg] = imgui.Vec4{0.16, 0.16, 0.28, 0.94}
	colors[imgui.Col.Border] = imgui.Vec4{0.43, 0.43, 0.50, 0.50}
	colors[imgui.Col.Border_Shadow] = imgui.Vec4{0.00, 0.00, 0.00, 0.00}
	colors[imgui.Col.Frame_Bg] = imgui.Vec4{0.39, 0.43, 0.49, 0.54}
	colors[imgui.Col.Frame_Bg_Hovered] = imgui.Vec4{0.64, 0.80, 0.99, 0.40}
	colors[imgui.Col.Frame_Bg_Active] = imgui.Vec4{0.86, 0.92, 1.00, 0.67}
	colors[imgui.Col.Title_Bg] = imgui.Vec4{0.18, 0.27, 0.40, 1.00}
	colors[imgui.Col.Title_Bg_Active] = imgui.Vec4{0.16, 0.29, 0.48, 1.00}
	colors[imgui.Col.Title_Bg_Collapsed] = imgui.Vec4{0.00, 0.00, 0.00, 0.51}
	colors[imgui.Col.Menu_Bar_Bg] = imgui.Vec4{0.19, 0.40, 0.60, 1.00}
	colors[imgui.Col.Scrollbar_Bg] = imgui.Vec4{0.04, 0.08, 0.10, 0.53}
	colors[imgui.Col.Scrollbar_Grab] = imgui.Vec4{0.31, 0.31, 0.31, 1.00}
	colors[imgui.Col.Scrollbar_Grab_Hovered] = imgui.Vec4{0.41, 0.41, 0.41, 1.00}
	colors[imgui.Col.Scrollbar_Grab_Active] = imgui.Vec4{0.51, 0.51, 0.51, 1.00}
	colors[imgui.Col.Check_Mark] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
	colors[imgui.Col.Slider_Grab] = imgui.Vec4{0.24, 0.52, 0.88, 1.00}
	colors[imgui.Col.Slider_Grab_Active] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
	colors[imgui.Col.Button] = imgui.Vec4{0.59, 0.61, 0.64, 0.40}
	colors[imgui.Col.Button_Hovered] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
	colors[imgui.Col.Button_Active] = imgui.Vec4{0.06, 0.53, 0.98, 1.00}
	colors[imgui.Col.Header] = imgui.Vec4{0.72, 0.85, 1.00, 0.31}
	colors[imgui.Col.Header_Hovered] = imgui.Vec4{0.26, 0.59, 0.98, 0.80}
	colors[imgui.Col.Header_Active] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
	colors[imgui.Col.Separator] = imgui.Vec4{0.43, 0.43, 0.50, 0.50}
	colors[imgui.Col.Separator_Hovered] = imgui.Vec4{0.10, 0.40, 0.75, 0.78}
	colors[imgui.Col.Separator_Active] = imgui.Vec4{0.10, 0.40, 0.75, 1.00}
	colors[imgui.Col.Resize_Grip] = imgui.Vec4{0.26, 0.59, 0.98, 0.20}
	colors[imgui.Col.Resize_Grip_Hovered] = imgui.Vec4{0.26, 0.59, 0.98, 0.67}
	colors[imgui.Col.Resize_Grip_Active] = imgui.Vec4{0.26, 0.59, 0.98, 0.95}
	colors[imgui.Col.Tab_Hovered] = imgui.Vec4{0.61, 0.62, 0.64, 0.80}
	colors[imgui.Col.Tab] = imgui.Vec4{0.46, 0.50, 0.56, 0.86}
	colors[imgui.Col.Tab_Selected] = imgui.Vec4{0.64, 0.67, 0.70, 1.00}
	colors[imgui.Col.Tab_Selected_Overline] = imgui.Vec4{0.71, 0.76, 0.81, 1.00}
	colors[imgui.Col.Tab_Dimmed] = imgui.Vec4{0.38, 0.40, 0.43, 0.97}
	colors[imgui.Col.Tab_Dimmed_Selected] = imgui.Vec4{0.34, 0.38, 0.44, 1.00}
	colors[imgui.Col.Tab_Dimmed_Selected_Overline] = imgui.Vec4{0.50, 0.50, 0.50, 0.00}
	colors[imgui.Col.Docking_Preview] = imgui.Vec4{0.73, 0.75, 0.77, 0.70}
	colors[imgui.Col.Docking_Empty_Bg] = imgui.Vec4{0.20, 0.20, 0.20, 1.00}
	colors[imgui.Col.Plot_Lines] = imgui.Vec4{0.61, 0.61, 0.61, 1.00}
	colors[imgui.Col.Plot_Lines_Hovered] = imgui.Vec4{1.00, 0.43, 0.35, 1.00}
	colors[imgui.Col.Plot_Histogram] = imgui.Vec4{0.90, 0.70, 0.00, 1.00}
	colors[imgui.Col.Plot_Histogram_Hovered] = imgui.Vec4{1.00, 0.60, 0.00, 1.00}
	colors[imgui.Col.Table_Header_Bg] = imgui.Vec4{0.19, 0.19, 0.20, 1.00}
	colors[imgui.Col.Table_Border_Strong] = imgui.Vec4{0.31, 0.31, 0.35, 1.00}
	colors[imgui.Col.Table_Border_Light] = imgui.Vec4{0.23, 0.23, 0.25, 1.00}
	colors[imgui.Col.Table_Row_Bg] = imgui.Vec4{0.00, 0.00, 0.00, 0.00}
	colors[imgui.Col.Table_Row_Bg_Alt] = imgui.Vec4{1.00, 1.00, 1.00, 0.06}
	colors[imgui.Col.Text_Link] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
	colors[imgui.Col.Text_Selected_Bg] = imgui.Vec4{0.26, 0.59, 0.98, 0.35}
	colors[imgui.Col.Drag_Drop_Target] = imgui.Vec4{1.00, 1.00, 0.00, 0.90}
	colors[imgui.Col.Nav_Cursor] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
	colors[imgui.Col.Nav_Windowing_Highlight] = imgui.Vec4{1.00, 1.00, 1.00, 0.70}
	colors[imgui.Col.Nav_Windowing_Dim_Bg] = imgui.Vec4{0.80, 0.80, 0.80, 0.20}
	colors[imgui.Col.Modal_Window_Dim_Bg] = imgui.Vec4{0.80, 0.80, 0.80, 0.35}
}
