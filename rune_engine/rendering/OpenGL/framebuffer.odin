package opengl

import "core:fmt"
import gl "vendor:OpenGL"

import rendering "../"

create_framebuffer :: proc() -> rendering.Framebuffer {
	fbo: u32
	gl.CreateFramebuffers(1, &fbo)
	return cast(rendering.Framebuffer)fbo
}

framebuffer_attach_texture :: proc(fb: ^rendering.Framebuffer) -> rendering.Texture {
	texture: u32
	gl.CreateTextures(gl.TEXTURE_2D, 1, &texture)
	gl.TextureParameteri(texture, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TextureParameteri(texture, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.TextureStorage2D(texture, 1, gl.RGB8, 1920, 1080)

	depth_texture: u32
	gl.CreateTextures(gl.TEXTURE_2D, 1, &depth_texture)
	gl.TextureParameteri(depth_texture, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TextureParameteri(depth_texture, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.TextureStorage2D(depth_texture, 1, gl.DEPTH24_STENCIL8, 1920, 1080)

	gl.NamedFramebufferTexture(cast(u32)fb^, gl.COLOR_ATTACHMENT0, texture, 0)
	gl.NamedFramebufferTexture(cast(u32)fb^, gl.DEPTH_STENCIL_ATTACHMENT, depth_texture, 0)

	if gl.CheckNamedFramebufferStatus(cast(u32)fb^, gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE {
		fmt.println("Framebuffer is incomplete")
	}
	return cast(rendering.Texture)texture
}

bind_framebuffer :: proc(fb: ^rendering.Framebuffer) {
	if fb == nil {
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		return
	}
	gl.BindFramebuffer(gl.FRAMEBUFFER, cast(u32)fb^)
}
