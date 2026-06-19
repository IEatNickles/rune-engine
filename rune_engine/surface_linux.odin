#+build linux
package rune_engine

import "vendor:glfw"
import "renderer"

get_surface_desc :: proc(window: glfw.WindowHandle) -> renderer.Surface_Desc {
  if glfw.GetPlatform() == glfw.PLATFORM_X11 {
    return {
      source = renderer.Surface_Source_Xlib {
        display = glfw.GetX11Display(),
        window = u64(glfw.GetX11Window(window)),
      }
    }
  } else if glfw.GetPlatform() == glfw.PLATFORM_WAYLAND {
    return {
      source = renderer.Surface_Source_Wayland {
        display = glfw.GetWaylandDisplay(),
        surface = glfw.GetWaylandWindow(window),
      }
    }
  }
  unreachable()
}
