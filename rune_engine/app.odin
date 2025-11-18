package rune_engine

import "base:runtime"
import "core:reflect"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:os"
import "rendering"

import "input"

LayerProcs :: struct {
	on_attach: proc(data: rawptr),
	on_update: proc(data: rawptr),
	on_detach: proc(data: rawptr),
}
Layer :: struct {
	procs: LayerProcs,
	data:  rawptr,
}

@(private)
application: struct {
	window:         Window,
	// events:        [dynamic]Event,
	running:        bool,
	input:          struct {
		keys:               input.KeyCode_BitSet,
		prev_keys:          input.KeyCode_BitSet,
		mouse_buttons:      input.MouseButton_BitSet,
		prev_mouse_buttons: input.MouseButton_BitSet,
		mouse_position:     [2]f32,
		mouse_delta:        [2]f32,
		scroll:             f32,
		horizontal_scroll:  f32,
	},
	time:           f32,
	delta_time:     f32,
	current_scene:  ^Scene,
	log_file:       os.Handle,
	default_shader: rendering.Shader,
	layer_stack:    map[typeid]Layer,
} = {}

debug_callback :: proc "c" (
	source, type, id, severity: u32,
	length: i32,
	message: cstring,
	userparam: rawptr,
) {
	context = runtime.default_context()
	severity_str: string
	switch severity {
	case gl.DEBUG_SEVERITY_LOW:
		severity_str = "LOW"
	case gl.DEBUG_SEVERITY_MEDIUM:
		severity_str = "MEDIUM"
	case gl.DEBUG_SEVERITY_HIGH:
		severity_str = "HIGH"
	case gl.DEBUG_SEVERITY_NOTIFICATION:
		severity_str = "NOTIFICATION"
	}

	fmt.printfln("{} [{}] {}", type, severity_str, message)
}

init :: proc(title: string) {
	err: os.Error
	application.log_file, err = os.open("log/log.txt", os.O_WRONLY | os.O_APPEND | os.O_CREATE)
	if err != .Exist {
		fmt.println(os.error_string(err))
	}
	context.logger = log.create_file_logger(application.log_file)

	application.window = window_create(1280, 720, title)
	glfw.MakeContextCurrent(application.window.handle)

	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	gl.Enable(gl.CULL_FACE)
	gl.Enable(gl.DEPTH_TEST)
	gl.Enable(gl.DEBUG_OUTPUT)
	gl.DebugMessageCallback(debug_callback, nil)

	setup_glfw_callbacks()
	application.running = true
	application.default_shader = load_shader("assets/shaders/test.vs", "assets/shaders/test.fs")
}

terminate :: proc() {
	for t in application.layer_stack {
		pop_layer(t)
	}

	glfw.Terminate()
	os.close(application.log_file)
}

load_scene :: proc(scene: ^Scene) {
	application.current_scene = scene
}

is_running :: proc() -> bool {
	return application.running
}

// @(private)
// poll_event :: proc(event: ^Event) -> bool {
// 	if len(application.events) <= 0 {
// 		return false
// 	}
// 	event^ = pop_front(&application.events)
// 	return true
// }

set_clear_color :: proc(color: [4]f32) {
	gl.ClearColor(color.r, color.g, color.b, color.a)
}

frame_start :: proc() {
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	application.input.prev_keys = application.input.keys
	application.input.prev_mouse_buttons = application.input.mouse_buttons

	glfw.PollEvents()

	for t, l in application.layer_stack {
		l.procs.on_update(l.data)
	}
	// event: Event
	// for poll_event(&event) {
	// 	switch e in event {
	// 	case KeyEvent:
	// 		if e.action == .Release {
	// 			application.input.keys -= {e.key}
	// 		} else {
	// 			application.input.keys += {e.key}
	// 		}
	// 	case MouseButtonEvent:
	// 		if e.action == .Release {
	// 			application.input.mouse_buttons -= {cast(input.MouseButton)e.button}
	// 		} else {
	// 			application.input.mouse_buttons += {cast(input.MouseButton)e.button}
	// 		}
	// 	case MousePosEvent:
	// 		application.input.mouse_delta += e.position - application.input.mouse_position
	// 		application.input.mouse_position = e.position
	// 	case ScrollEvent:
	// 		application.input.scroll = e.vertical
	// 		application.input.horizontal_scroll = e.horizontal
	// 	}
	// }
}

frame_end :: proc() {
	bind_shader(&application.default_shader)
	world, view, proj: matrix[4, 4]f32
	for cam_arch in query(has(TransformComponent), has(CameraComponent)) {
		cam_table := get_table(cam_arch, CameraComponent)
		cam_trf_table := get_table(cam_arch, TransformComponent)
		for e, i in cam_arch.entities {
			transform := &cam_trf_table[i]
			view = linalg.inverse(
				linalg.matrix4_translate(transform.position) *
				linalg.matrix4_from_quaternion(transform.rotation),
			)
			proj = linalg.matrix4_perspective_f32(
				math.to_radians_f32(cam_table[i].fov),
				cam_table[i].aspect,
				cam_table[i].near,
				cam_table[i].far,
			)

			set_shader_mat4(&application.default_shader, "u_view", &view)
			set_shader_mat4(&application.default_shader, "u_proj", &proj)

			for mesh_arch in query(has(TransformComponent), has(MeshRendererComponent)) {
				mesh_table := get_table(mesh_arch, MeshRendererComponent)
				mesh_trf_table := get_table(mesh_arch, TransformComponent)
				for e2, i in mesh_arch.entities {
					mesh_trf := mesh_trf_table[i]
					world = linalg.matrix4_from_trs(
						mesh_trf.position,
						mesh_trf.rotation,
						mesh_trf.scale,
					)
					set_shader_mat4(&application.default_shader, "u_world", &world)
					draw_mesh(mesh_table[i].mesh)
				}
			}
		}
	}

	glfw.SwapBuffers(application.window.handle)
	application.input.mouse_delta = 0
	application.delta_time = cast(f32)glfw.GetTime() - application.time
	application.time = cast(f32)glfw.GetTime()
	application.input.scroll = 0
	application.input.horizontal_scroll = 0
}

push_layer :: proc(
	layer: ^$T,
	on_attach: proc(_: ^T),
	on_update: proc(_: ^T),
	on_detach: proc(_: ^T),
) -> bool {
	if T in application.layer_stack {
		return false
	}
	layer := map_insert(
		&application.layer_stack,
		T,
		Layer {
			LayerProcs {
				cast(proc(_: rawptr))on_attach,
				cast(proc(_: rawptr))on_update,
				cast(proc(_: rawptr))on_detach,
			},
			cast(rawptr)layer,
		},
	)
	layer.procs.on_attach(layer.data)
	return true
}

pop_layer :: proc(T: typeid) -> bool {
	layer, ok := application.layer_stack[T]
	if !ok do return false
	if layer.procs.on_detach != nil do layer.procs.on_detach(layer.data)
	delete_key(&application.layer_stack, T)
	return true
}

// push_layer :: proc(layer_procs: LayerProcs, layer_data: ^$T) {
// 	layer := map_insert(&application.layer_stack, T, Layer{layer_procs, cast(rawptr)layer_data})
// 	layer.procs.on_attach(layer.user_data)
// }

close :: proc() {
	glfw.SetWindowShouldClose(application.window.handle, true)
	application.running = false
}

get_time :: proc() -> f32 {
	return cast(f32)glfw.GetTime()
}

get_delta_time :: proc() -> f32 {
	return cast(f32)glfw.GetTime() - application.time
}

setup_glfw_callbacks :: proc() {
	glfw.SetKeyCallback(
		application.window.handle,
		proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
			if action == glfw.REPEAT {
				return
			}
			context = runtime.default_context()
			if action == glfw.RELEASE {
				application.input.keys -= {input.GLFW_KEY_TO_ENGINE_KEY[key]}
			} else {
				application.input.keys += {input.GLFW_KEY_TO_ENGINE_KEY[key]}
			}
			// append(
			// 	&application.events,
			// 	KeyEvent {
			// 		input.GLFW_KEY_TO_ENGINE_KEY[key],
			// 		cast(input.Action)action,
			// 		scancode,
			// 		transmute(input.Modifiers)cast(u8)mods,
			// 	},
			// )
		},
	)
	glfw.SetMouseButtonCallback(
		application.window.handle,
		proc "c" (window: glfw.WindowHandle, button, scancode, action: i32) {
			if action == glfw.REPEAT {
				return
			}
			context = runtime.default_context()
			if action == glfw.RELEASE {
				application.input.mouse_buttons -= {cast(input.MouseButton)button}
			} else {
				application.input.mouse_buttons += {cast(input.MouseButton)button}
			}
			// append(
			// 	&application.events,
			// 	MouseButtonEvent{cast(input.MouseButton)button, cast(input.Action)action},
			// )
		},
	)
	glfw.SetCursorPosCallback(
		application.window.handle,
		proc "c" (window: glfw.WindowHandle, x, y: f64) {
			context = runtime.default_context()
			pos := [2]f32{cast(f32)x, cast(f32)y}
			application.input.mouse_delta += pos - application.input.mouse_position
			application.input.mouse_position = pos
			// append(&application.events, MousePosEvent{{cast(f32)x, cast(f32)y}})
		},
	)
	glfw.SetScrollCallback(
		application.window.handle,
		proc "c" (window: glfw.WindowHandle, x, y: f64) {
			context = runtime.default_context()
			application.input.scroll = cast(f32)y
			application.input.horizontal_scroll = cast(f32)x
			// append(&application.events, ScrollEvent{cast(f32)y, cast(f32)x})
		},
	)
}
