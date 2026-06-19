package rune_engine

import "core:fmt"
import "base:runtime"
import "core:strings"

import "vendor:glfw"

import "renderer"

Window :: struct {
	handle:    glfw.WindowHandle,
}

window_create :: proc(width, height: u32, title: string, backend: renderer.Backend) -> Window {
	glfw.Init()
  glfw.SetErrorCallback(proc "c" (error: i32, description: cstring) {
    context = runtime.default_context()
    err_str: string
    switch error {
    case glfw.NO_ERROR: err_str = "NO_ERROR"
    case glfw.NOT_INITIALIZED: err_str = "NOT_INITIALIZED"
    case glfw.NO_CURRENT_CONTEXT: err_str = "NO_CURRENT_CONTEXT"
    case glfw.INVALID_ENUM: err_str = "INVALID_ENUM"
    case glfw.INVALID_VALUE: err_str = "INVALID_VALUE"
    case glfw.OUT_OF_MEMORY: err_str = "OUT_OF_MEMORY"
    case glfw.API_UNAVAILABLE: err_str = "API_UNAVAILABLE"
    case glfw.VERSION_UNAVAILABLE: err_str = "VERSION_UNAVAILABLE"
    case glfw.PLATFORM_ERROR: err_str = "PLATFORM_ERROR"
    case glfw.FORMAT_UNAVAILABLE: err_str = "FORMAT_UNAVAILABLE"
    case glfw.NO_WINDOW_CONTEXT: err_str = "NO_WINDOW_CONTEXT"
    case glfw.CURSOR_UNAVAILABLE: err_str = "CURSOR_UNAVAILABLE"
    case glfw.FEATURE_UNAVAILABLE: err_str = "FEATURE_UNAVAILABLE"
    case glfw.FEATURE_UNIMPLEMENTED: err_str = "FEATURE_UNIMPLEMENTED"
    case glfw.PLATFORM_UNAVAILABLE: err_str = "PLATFORM_UNAVAILABLE"
    }
    fmt.printfln("GLFW error({}): {}", err_str, description)
  })

  glfw.WindowHint(glfw.RESIZABLE, false)
  switch backend {
  case .OpenGL:
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
  case .Vulkan:
    glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
  case .Metal: unimplemented()
  case .None: unimplemented()
  case .Direct3D11: unimplemented()
  case .Direct3D12: unimplemented()
  case .WebGL: unimplemented()
  case .WebGPU: unimplemented()
  }

  window: Window
	window.handle = glfw.CreateWindow(
		cast(i32)width,
		cast(i32)height,
		strings.clone_to_cstring(title, context.temp_allocator),
		nil,
		nil,
	)

  switch backend {
  case .OpenGL:
    glfw.MakeContextCurrent(window.handle)
    // glGetIntegerv: proc "c"(pname: u32, i: ^i32)
    // glfw.gl_set_proc_address(&glGetIntegerv, "glGetIntegerv")
    // major, minor: i32
    // glGetIntegerv(gl.MAJOR_VERSION, &major)
    // glGetIntegerv(gl.MAJOR_VERSION, &minor)
    // gl.load_up_to(int(major), int(minor), glfw.gl_set_proc_address)
    // version := int(major * 100 + minor * 10)
    // if version >= 430 do window.features += { .OpenGL_Debug_Output, .OpenGL_Compute_Shader }
    // if version >= 450 do window.features += { .OpenGL_DSA }
  case .Vulkan:
  case .Metal: unimplemented()
  case .None: unimplemented()
  case .Direct3D11: unimplemented()
  case .Direct3D12: unimplemented()
  case .WebGL: unimplemented()
  case .WebGPU: unimplemented()
  }

	free_all(context.temp_allocator)
	return window
}
