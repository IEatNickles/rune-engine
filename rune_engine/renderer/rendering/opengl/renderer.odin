package opengl

import hm "core:container/handle_map"
import "core:fmt"
import "base:runtime"

import gl "vendor:OpenGL"

import ".."

Context :: struct {
  pipelines: hm.Dynamic_Handle_Map(Pipeline_State, rendering.Pipeline),
  shaders:   hm.Dynamic_Handle_Map(Shader_State, rendering.Shader),
  textures:  hm.Dynamic_Handle_Map(Texture_State, rendering.Texture),
  buffers:   hm.Dynamic_Handle_Map(Buffer_State, rendering.Buffer),

  current_pipeline: rendering.Pipeline,

  fbo: u32,
  vao: u32,
}

create_context :: proc() -> (ctx: ^Context) {
  ctx = new(Context)
  gl.Enable(gl.CULL_FACE)
  gl.Enable(gl.DEPTH_TEST)
  gl.Enable(gl.DEBUG_OUTPUT)
  gl.DebugMessageCallback(debug_callback, nil)

  gl.GenFramebuffers(1, &ctx.fbo)
  gl.GenVertexArrays(1, &ctx.vao)

  return
}

destroy_context :: proc(ctx: ^Context) {
}

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
    return
  // severity_str = "NOTIFICATION"
  }

  fmt.printfln("{} [{}] {}", type, severity_str, message)
}
