// NOTE: There is probably a much much MUCH better way to do this,
//  but, oh well, what's the worst that could happen :)

package rune_engine

import "core:math/linalg"

import "core:fmt"
import "core:log"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "rendering/DirectX11"
import "rendering/DirectX12"
import "rendering/Metal"
import "rendering/OpenGL"
import "rendering/Vulkan"

import "rendering"

import "vendor:stb/image"

TextureParameters :: struct {
	filter:    TextureFilter,
	wrap_mode: TextureWrap,
}

RenderApiType :: enum {
	OpenGL,
	DirectX11,
	DirectX12,
	Vulkan,
	Metal,
}

render_api: RenderApiType

MaterialProperty :: union {
	u32,
	i32,
	f32,
	f64,
	[2]f32,
	[3]f32,
	[4]f32,
	[2]f64,
	[3]f64,
	[4]f64,
}
MaterialData :: struct {
	shader:     rendering.Shader,
	properties: map[string]MaterialProperty,
}
material_data :: map[rendering.Material]MaterialData

create_render_api :: proc(type: RenderApiType) {
	switch type {
	case .OpenGL:
		gl.load_up_to(4, 6, glfw.gl_set_proc_address)
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
	render_api = type
}

load_shader :: proc(vsh_path, fsh_path: string) -> rendering.Shader {
	switch render_api {
	case .OpenGL:
		return OpenGL.create_shader(vsh_path, fsh_path)
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
	return {}
}

bind_shader :: proc(prog: ^rendering.Shader) {
	switch render_api {
	case .OpenGL:
		OpenGL.bind_shader(prog)
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
}

create_material :: proc(shader: rendering.Shader) {
}

set_shader_mat4 :: proc(prog: ^rendering.Shader, name: string, value: ^matrix[4, 4]f32) {
	switch render_api {
	case .OpenGL:
		OpenGL.shader_uniform_mat4_f32(prog, name, value)
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
}

delete_shader :: proc(shader: ^rendering.Shader) {
	OpenGL.delete_shader(shader)
}

load_texture :: proc(
	path: string,
	params: TextureParameters = {.Linear, .Repeat},
) -> rendering.Texture {
	width, height, channels: i32
	image.set_flip_vertically_on_load(1)
	data := image.load(cast(cstring)raw_data(path), &width, &height, &channels, 0)
	if data == nil {
		fmt.println(image.failure_reason())
		return 0
	}

	texture: u32
	switch render_api {
	case .OpenGL:
		gl.CreateTextures(gl.TEXTURE_2D, 1, &texture)
		gl.TextureParameteri(texture, gl.TEXTURE_MIN_FILTER, cast(i32)params.filter)
		gl.TextureParameteri(texture, gl.TEXTURE_MAG_FILTER, cast(i32)params.filter)
		gl.TextureParameteri(texture, gl.TEXTURE_WRAP_S, cast(i32)params.wrap_mode)
		gl.TextureParameteri(texture, gl.TEXTURE_WRAP_T, cast(i32)params.wrap_mode)

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
		gl.TextureSubImage2D(texture, 0, 0, 0, width, height, format, gl.UNSIGNED_BYTE, data)
		return cast(rendering.Texture)texture
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
	return 0
}

bind_texture :: proc(texture: rendering.Texture, unit: u32 = 0) {
	switch render_api {
	case .OpenGL:
		gl.BindTextureUnit(unit, cast(u32)texture)
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
}

create_mesh :: proc(
	positions, normals, texcoords, colors, tangents: []f32,
	indices: []u16,
	transform: matrix[4, 4]f32,
) -> rendering.Mesh {
	switch render_api {
	case .OpenGL:
		return OpenGL.create_mesh(
			positions,
			normals,
			texcoords,
			colors,
			tangents,
			indices,
			transform,
		)
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
	return 0
}

destroy_model :: proc(model: ^Model) {
	switch render_api {
	case .OpenGL:
		for m in model.meshes {
			OpenGL.destroy_mesh(m)
		}
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
}

draw_model :: proc(model: ^Model) {
	switch render_api {
	case .OpenGL:
		for m in model.meshes {
			OpenGL.draw_mesh(m)
		}
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
}

draw_mesh :: proc(mesh: rendering.Mesh) {
	switch render_api {
	case .OpenGL:
		OpenGL.draw_mesh(mesh)
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
}

create_framebuffer :: proc() -> rendering.Framebuffer {
	switch render_api {
	case .OpenGL:
		return OpenGL.create_framebuffer()
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
	return {}
}

framebuffer_attach_texture :: proc(fb: ^rendering.Framebuffer) -> rendering.Texture {
	switch render_api {
	case .OpenGL:
		return OpenGL.framebuffer_attach_texture(fb)
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
	return {}
}

bind_framebuffer :: proc(fb: ^rendering.Framebuffer) {
	switch render_api {
	case .OpenGL:
		OpenGL.bind_framebuffer(fb)
	case .DirectX11:
		log.panic("DirectX11 is not supported")
	case .DirectX12:
		log.panic("DirectX12 is not supported")
	case .Vulkan:
		log.panic("Vulkan is not supported")
	case .Metal:
		log.panic("Metal is not supported")
	}
}

@(private)
render_data: struct {
	view_projection: matrix[4, 4]f32,
	ubo:             rendering.Buffer,
}

begin_scene :: proc(view, projection: matrix[4, 4]f32) {
	render_data.view_projection = projection * linalg.inverse(view)
	OpenGL.buffer_set_sub_data_ptr(render_data.ubo, 0, &render_data.view_projection, 1)
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
