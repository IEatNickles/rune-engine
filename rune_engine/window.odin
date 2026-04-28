package rune_engine

import "core:fmt"
import "base:runtime"
import "core:strings"

import "vendor:glfw"
import gl "vendor:OpenGL"
import vk "vendor:vulkan"

import "renderer"

OpenGL_Window :: struct {
}

Vulkan_Window :: struct {
  swapchain: vk.SwapchainKHR
}

Window :: struct {
	handle: glfw.WindowHandle,
  backend: union {
    OpenGL_Window,
    Vulkan_Window,
  }
}

window_create :: proc(width, height: u32, title: string, backend: renderer.RenderApiType) -> Window {
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
  case .D3D11:
  case .D3D12:
  case .Vulkan:
    glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
  case .Metal:
  }

	handle := glfw.CreateWindow(
		cast(i32)width,
		cast(i32)height,
		strings.clone_to_cstring(title, context.temp_allocator),
		nil,
		nil,
	)

  switch backend {
  case .OpenGL:
    glfw.MakeContextCurrent(handle)
    gl.load_up_to(4, 3, glfw.gl_set_proc_address)
  case .D3D11:
  case .D3D12:
  case .Vulkan:
  case .Metal:
  }

	free_all(context.temp_allocator)
	return Window{handle = handle}
}
