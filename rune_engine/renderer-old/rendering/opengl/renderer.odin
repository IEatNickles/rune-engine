package opengl

import hm "core:container/handle_map"
import "core:fmt"
import "base:runtime"

import gl "vendor:OpenGL"

import ".."

ctx: struct {
  pipelines:   hm.Dynamic_Handle_Map(Pipeline_State, rendering.Pipeline),
  shaders:     hm.Dynamic_Handle_Map(Shader_State, rendering.Shader),
  textures:    hm.Dynamic_Handle_Map(Texture_State, rendering.Texture),
  buffers:     hm.Dynamic_Handle_Map(Buffer_State, rendering.Buffer),
  images:      hm.Dynamic_Handle_Map(Image_State, rendering.Image),
  image_views: hm.Dynamic_Handle_Map(Image_View_State, rendering.Image_View),

  current_pipeline: rendering.Pipeline,

  fbo: u32,
  vao: u32,

  features: rendering.Renderer_Feature_Flags,
}

create_context :: proc(/* features: rendering.Renderer_Feature_Flags */ info: ^rendering.GL_Renderer_Create_Info) {
  gl.Enable(gl.CULL_FACE)
  gl.Enable(gl.DEPTH_TEST)
  when ODIN_DEBUG {
    // if .OpenGL_Debug_Output in features {
      gl.Enable(gl.DEBUG_OUTPUT)
      gl.DebugMessageCallback(debug_callback, nil)
    // }
  }

  gl.GenFramebuffers(1, &ctx.fbo)
  gl.GenVertexArrays(1, &ctx.vao)

  // ctx.features = features
}

destroy_context :: proc() {
  gl.DeleteFramebuffers(1, &ctx.fbo)
  gl.DeleteVertexArrays(1, &ctx.vao)
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
