package opengl

import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"
import "vendor:stb/image"

import ".."

TextureParameters :: struct {
	filter:    TextureFilter,
	wrap_mode: TextureWrap,
}

bind_texture :: proc(texture: ^rendering.Texture, unit: u32 = 0) {
	gl.BindTextureUnit(unit, cast(u32)texture^)
}

TextureFilter :: enum i32 {
	Linear  = gl.LINEAR,
	Nearest = gl.NEAREST,
}

TextureWrap :: enum i32 {
	Repeat            = gl.REPEAT,
	ClampToEdge       = gl.CLAMP_TO_EDGE,
	ClampToBorder     = gl.CLAMP_TO_BORDER,
	MirroredRepeat    = gl.MIRRORED_REPEAT,
	MirrorClampToEdge = gl.MIRROR_CLAMP_TO_EDGE,
}
