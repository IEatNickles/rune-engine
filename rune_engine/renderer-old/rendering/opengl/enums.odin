package opengl

import gl "vendor:OpenGL"

import ".."

gl_wrap :: proc(wrap: rendering.Wrap_Mode) -> i32 {
  switch wrap {
  case .Clamp_To_Edge:   return gl.CLAMP_TO_EDGE
  case .Clamp_To_Border: return gl.CLAMP_TO_BORDER
  case .Repeat:          return gl.REPEAT
  }
  unreachable()
}
