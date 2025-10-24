// NOTE: There is probably a much much MUCH better way to do this,
//  but, oh well, what's the worst that could happen :)

package rune_engine

import "core:log"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "rendering/DirectX11"
import "rendering/DirectX12"
import "rendering/Metal"
import "rendering/OpenGL"
import "rendering/Vulkan"

import "rendering"

RenderApiType :: enum {
	OpenGL,
	DirectX11,
	DirectX12,
	Vulkan,
	Metal,
}

render_api: RenderApiType

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

load_texture :: proc(path: string) -> rendering.Texture {
	switch render_api {
	case .OpenGL:
		return OpenGL.load_texture(path)
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

bind_texture :: proc(texture: ^rendering.Texture, unit: u32 = 0) {
	switch render_api {
	case .OpenGL:
		OpenGL.bind_texture(texture, unit)
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
