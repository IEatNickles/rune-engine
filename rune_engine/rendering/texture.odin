package rendering

import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"
import "vendor:stb/image"

Texture :: distinct u32

TextureParameters :: struct {
	filter:    TextureFilter,
	wrap_mode: TextureWrap,
}

load_texture :: proc(path: string, params: TextureParameters = {.Linear, .Repeat}) -> Texture {
	texture: u32
	gl.CreateTextures(gl.TEXTURE_2D, 1, &texture)
	gl.TextureParameteri(texture, gl.TEXTURE_MIN_FILTER, cast(i32)params.filter)
	gl.TextureParameteri(texture, gl.TEXTURE_MAG_FILTER, cast(i32)params.filter)
	gl.TextureParameteri(texture, gl.TEXTURE_WRAP_S, cast(i32)params.wrap_mode)
	gl.TextureParameteri(texture, gl.TEXTURE_WRAP_T, cast(i32)params.wrap_mode)

	width, height, channels: i32
	image.set_flip_vertically_on_load(1)
	image_data := image.load(cast(cstring)raw_data(path), &width, &height, &channels, 0)
	if image_data == nil {
		log.error(image.failure_reason())
		return 0
	}

	format: u32
	internal_format: u32
	switch channels {
	case 4:
		format = gl.RGBA
		internal_format = gl.RGBA8
	case 3:
		format = gl.RGB
		internal_format = gl.RGB8
	case 2:
		format = gl.RG
		internal_format = gl.RG8
	case 1:
		format = gl.R
		internal_format = gl.R8
	}
	gl.TextureStorage2D(texture, 1, internal_format, width, height)
	gl.TextureSubImage2D(texture, 0, 0, 0, width, height, format, gl.UNSIGNED_BYTE, image_data)

	return cast(Texture)texture
}

bind_texture :: proc(texture: ^Texture, unit: u32 = 0) {
	gl.BindTextureUnit(unit, cast(u32)texture^)
}

TextureFilter :: enum {
	Linear  = gl.LINEAR,
	Nearest = gl.NEAREST,
}

TextureWrap :: enum {
	Repeat            = gl.REPEAT,
	ClampToEdge       = gl.CLAMP_TO_EDGE,
	ClampToBorder     = gl.CLAMP_TO_BORDER,
	MirroredRepeat    = gl.MIRRORED_REPEAT,
	MirrorClampToEdge = gl.MIRROR_CLAMP_TO_EDGE,
}
