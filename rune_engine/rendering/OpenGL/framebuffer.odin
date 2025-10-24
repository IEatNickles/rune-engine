package opengl

import gl "vendor:OpenGL"

Framebuffer :: distinct u32

create_framebuffer :: proc() -> Framebuffer {
	fbo: u32
	gl.CreateFramebuffers(1, &fbo)
	return cast(Framebuffer)fbo
}
