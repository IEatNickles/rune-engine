package opengl

import "core:container/handle_map"
import ".."

import gl "vendor:OpenGL"

begin_pass :: proc(info: ^rendering.Pass_Info) {
  gl.BindFramebuffer(gl.FRAMEBUFFER, ctx.fbo)
  for att, i in info.color_attachments {
    if att.view != {} {
      tex_state := handle_map.get(&ctx.image_views, att.view)
      gl.FramebufferTexture(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0 + u32(i), tex_state.image, 0)
    }
    if att.load_action == .Clear {
      clear_color := att.clear_color
      gl.ClearBufferfv(gl.COLOR, i32(i), &clear_color[0])
    }
  }
  if info.depth_attachment.format != .Unknown {
    att := info.depth_attachment
    if att.texture != {} {
      tex_state := handle_map.get(&ctx.textures, att.texture)
      gl.FramebufferTexture(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, tex_state.id, 0)
    }
    if att.load_action == .Clear {
      clear_value := att.clear_value
      gl.ClearBufferfv(gl.DEPTH, 0, &clear_value)
    }
  }
}

end_pass :: proc() {
  gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}
