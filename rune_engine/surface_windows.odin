#+build windows
package rune_engine

import "vendor:glfw"
import "renderer"
import win32 "core:sys/windows"

get_surface_desc :: proc(window: glfw.WindowHandle) -> renderer.Surface_Desc {
  return {
    source = renderer.Surface_Source_Win32 {
      instance = win32.GetModuleHandleW(nil),
      hwnd     = glfw.GetWin32Window(window),
    }
  }
}
