package engine

import "base:runtime"
import gl "vendor:OpenGL"
import "vendor:glfw"

import "core:fmt"

import "input"

@(private)
application: struct {
	window:        Window,
	events:        [dynamic]Event,
	running:       bool,
	input:         struct {
		keys:               input.KeyCode_BitSet,
		prev_keys:          input.KeyCode_BitSet,
		mouse_buttons:      input.MouseButton_BitSet,
		prev_mouse_buttons: input.MouseButton_BitSet,
		mouse_position:     [2]f32,
		mouse_delta:        [2]f32,
		scroll:             f32,
		horizontal_scroll:  f32,
	},
	time:          f32,
	delta_time:    f32,
	current_scene: ^Scene,
} = {}

init :: proc() {
	application.window = window_create(1280, 720, "The Title of This Window")
	glfw.MakeContextCurrent(application.window.handle)

	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	glfw.SetKeyCallback(
		application.window.handle,
		proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
			context = runtime.default_context()
			append(
				&application.events,
				KeyEvent {
					input.GLFW_KEY_TO_ENGINE_KEY[key],
					cast(input.Action)action,
					scancode,
					transmute(input.Modifiers)cast(u8)mods,
				},
			)
		},
	)
	glfw.SetMouseButtonCallback(
		application.window.handle,
		proc "c" (window: glfw.WindowHandle, button, scancode, action: i32) {
			context = runtime.default_context()
			append(
				&application.events,
				MouseButtonEvent{cast(input.MouseButton)button, cast(input.Action)action},
			)
		},
	)
	glfw.SetCursorPosCallback(
		application.window.handle,
		proc "c" (window: glfw.WindowHandle, x, y: f64) {
			context = runtime.default_context()
			append(&application.events, MousePosEvent{{cast(f32)x, cast(f32)y}})
		},
	)
	glfw.SetScrollCallback(
		application.window.handle,
		proc "c" (window: glfw.WindowHandle, x, y: f64) {
			context = runtime.default_context()
			append(&application.events, ScrollEvent{cast(f32)y, cast(f32)x})
		},
	)
	application.running = true
}

load_scene :: proc(scene: ^Scene) {
	application.current_scene = scene
}

is_running :: proc() -> bool {
	return application.running
}

@(private)
poll_event :: proc(event: ^Event) -> bool {
	if len(application.events) <= 0 {
		return false
	}
	event^ = pop(&application.events)
	return true
}

set_clear_color :: proc(color: [4]f32) {
	gl.ClearColor(color.r, color.g, color.b, color.a)
}

frame_start :: proc() {
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	application.input.prev_keys = application.input.keys
	application.input.prev_mouse_buttons = application.input.mouse_buttons

	glfw.PollEvents()
	event: Event
	for poll_event(&event) {
		switch e in event {
		case KeyEvent:
			if e.action == .Release {
				application.input.keys -= {cast(input.KeyCode)e.key}
			} else {
				application.input.keys += {cast(input.KeyCode)e.key}
			}
		case MouseButtonEvent:
			if e.action == .Release {
				application.input.mouse_buttons -= {cast(input.MouseButton)e.button}
			} else {
				application.input.mouse_buttons += {cast(input.MouseButton)e.button}
			}
		case MousePosEvent:
			application.input.mouse_delta += e.position - application.input.mouse_position
			application.input.mouse_position = e.position
		case ScrollEvent:
			application.input.scroll = e.vertical
			application.input.horizontal_scroll = e.horizontal
		}
	}
}

frame_end :: proc() {
	glfw.SwapBuffers(application.window.handle)
	application.input.mouse_delta = 0
	application.delta_time = cast(f32)glfw.GetTime() - application.time
	application.time = cast(f32)glfw.GetTime()
	application.input.scroll = 0
	application.input.horizontal_scroll = 0
}

close :: proc() {
	glfw.SetWindowShouldClose(application.window.handle, true)
	application.running = false
}

terminate :: proc() {
	glfw.Terminate()
}

get_time :: proc() -> f32 {
	return cast(f32)glfw.GetTime()
}

get_delta_time :: proc() -> f32 {
	return cast(f32)glfw.GetTime() - application.time
}
