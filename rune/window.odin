package engine

import "core:mem"
import "core:strings"
import "vendor:glfw"

Window :: struct {
	handle: glfw.WindowHandle,
}

window_create :: proc(width, height: uint, title: string) -> Window {
	glfw.Init()
	handle := glfw.CreateWindow(
		cast(i32)width,
		cast(i32)height,
		strings.clone_to_cstring(title, context.temp_allocator),
		nil,
		nil,
	)

	free_all(context.temp_allocator)
	return Window{handle}
}
