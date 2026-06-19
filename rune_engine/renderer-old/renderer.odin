package renderer

import "core:log"

/*
import "rendering/d3d11"
import "rendering/d3d12"
import "rendering/metal"
*/
import "rendering/opengl"
import "rendering/vulkan"

import "rendering"

RenderApiType :: enum {
	OpenGL,
  Vulkan,
	D3D11,
	D3D12,
	Metal,
}

Renderer :: struct {
  ctx: rawptr,
  create_pipeline:    Create_Pipeline_Proc,
  destroy_pipeline:   Destroy_Pipeline_Proc,
  create_shader:      Create_Shader_Proc,
  destroy_shader:     Destroy_Shader_Proc,
  create_texture:     Create_Texture_Proc,
  destroy_texture:    Destroy_Texture_Proc,
  create_buffer:      Create_Buffer_Proc,
  destroy_buffer:     Destroy_Buffer_Proc,
  create_image:       Create_Image_Proc,
  destroy_image:      Destroy_Image_Proc,
  create_image_view:  Create_Image_View_Proc,
  destroy_image_view: Destroy_Image_View_Proc,
  create_bindings:    Create_Bindings_Proc,
  destroy_bindings:   Destroy_Bindings_Proc,

  bind_pipeline:       Bind_Pipeline_Proc,
  bind_vertex_buffers: Bind_Vertex_Buffers_Proc,
  bind_index_buffer:   Bind_Index_Buffer_Proc,
  draw:                Draw_Proc,

  shader_set_push_constants: Shader_Set_Push_Constants_Proc,
  get_texture_descriptor:    Get_Texture_Descriptor_Proc,

  begin_pass: Begin_Pass_Proc,
  end_pass:   End_Pass_Proc,

  get_render_target: Get_Render_Target_Proc,
  submit: Submit_Proc,
  present: Present_Proc,
}

create_renderer_gl :: proc(info: ^GL_Renderer_Create_Info) -> Renderer {
  opengl.create_context(info)
  return Renderer {
    create_pipeline           = auto_cast opengl.create_pipeline,
    destroy_pipeline          = auto_cast opengl.destroy_pipeline,
    create_shader             = auto_cast opengl.create_shader,
    destroy_shader            = auto_cast opengl.destroy_shader,
    create_texture            = auto_cast opengl.create_texture,
    destroy_texture           = auto_cast opengl.destroy_texture,
    create_buffer             = auto_cast opengl.create_buffer,
    destroy_buffer            = auto_cast opengl.destroy_buffer,
    bind_pipeline             = auto_cast opengl.bind_pipeline,
    bind_vertex_buffers       = auto_cast opengl.bind_vertex_buffers,
    bind_index_buffer         = auto_cast opengl.bind_index_buffer,
    draw                      = auto_cast opengl.draw,
    shader_set_push_constants = auto_cast opengl.shader_set_push_constants,
    get_texture_descriptor    = auto_cast opengl.get_texture_descriptor,
    begin_pass                = auto_cast opengl.begin_pass,
    end_pass                  = auto_cast opengl.end_pass,
  }
}

create_renderer_vk :: proc(info: ^Vk_Renderer_Create_Info) -> Renderer {
  vulkan.create_context(info)
  return Renderer {
    create_pipeline           = auto_cast vulkan.create_pipeline,
    destroy_pipeline          = auto_cast vulkan.destroy_pipeline,
    create_shader             = auto_cast vulkan.create_shader,
    destroy_shader            = auto_cast vulkan.destroy_shader,
    create_texture            = auto_cast vulkan.create_texture,
    destroy_texture           = auto_cast vulkan.destroy_texture,
    create_buffer             = auto_cast vulkan.create_buffer,
    destroy_buffer            = auto_cast vulkan.destroy_buffer,
    create_image              = auto_cast vulkan.create_image,
    destroy_image             = auto_cast vulkan.destroy_image,
    create_image_view         = auto_cast vulkan.create_image_view,
    destroy_image_view        = auto_cast vulkan.destroy_image_view,
    create_bindings           = auto_cast vulkan.create_bindings,
    destroy_bindings          = auto_cast vulkan.destroy_bindings,
    bind_pipeline             = auto_cast vulkan.bind_pipeline,
    bind_vertex_buffers       = auto_cast vulkan.bind_vertex_buffers,
    bind_index_buffer         = auto_cast vulkan.bind_index_buffer,
    draw                      = auto_cast vulkan.draw,
    shader_set_push_constants = auto_cast vulkan.shader_set_push_constants,
    get_texture_descriptor    = auto_cast vulkan.get_texture_descriptor,
    begin_pass                = auto_cast vulkan.begin_pass,
    end_pass                  = auto_cast vulkan.end_pass,
    submit                    = auto_cast vulkan.submit,
  }
}

create_renderer :: proc(backend: RenderApiType, features: Feature_Flags) -> Renderer {
	switch backend {
	case .OpenGL:
    // opengl.create_context(features)
    return Renderer {
      create_pipeline           = auto_cast opengl.create_pipeline,
      destroy_pipeline          = auto_cast opengl.destroy_pipeline,
      create_shader             = auto_cast opengl.create_shader,
      destroy_shader            = auto_cast opengl.destroy_shader,
      create_texture            = auto_cast opengl.create_texture,
      destroy_texture           = auto_cast opengl.destroy_texture,
      create_buffer             = auto_cast opengl.create_buffer,
      destroy_buffer            = auto_cast opengl.destroy_buffer,
      bind_pipeline             = auto_cast opengl.bind_pipeline,
      bind_vertex_buffers       = auto_cast opengl.bind_vertex_buffers,
      bind_index_buffer         = auto_cast opengl.bind_index_buffer,
      draw                      = auto_cast opengl.draw,
      shader_set_push_constants = auto_cast opengl.shader_set_push_constants,
      get_texture_descriptor    = auto_cast opengl.get_texture_descriptor,
      begin_pass                = auto_cast opengl.begin_pass,
      end_pass                  = auto_cast opengl.end_pass,
    }
  case .Vulkan:
    // vulkan.create_context(features)
    return {
      create_pipeline           = auto_cast vulkan.create_pipeline,
      destroy_pipeline          = auto_cast vulkan.destroy_pipeline,
      create_shader             = auto_cast vulkan.create_shader,
      destroy_shader            = auto_cast vulkan.destroy_shader,
      create_texture            = auto_cast vulkan.create_texture,
      destroy_texture           = auto_cast vulkan.destroy_texture,
      create_buffer             = auto_cast vulkan.create_buffer,
      destroy_buffer            = auto_cast vulkan.destroy_buffer,
      bind_pipeline             = auto_cast vulkan.bind_pipeline,
      bind_vertex_buffers       = auto_cast vulkan.bind_vertex_buffers,
      bind_index_buffer         = auto_cast vulkan.bind_index_buffer,
      draw                      = auto_cast vulkan.draw,
      shader_set_push_constants = auto_cast vulkan.shader_set_push_constants,
      get_texture_descriptor    = auto_cast vulkan.get_texture_descriptor,
      begin_pass                = auto_cast vulkan.begin_pass,
      end_pass                  = auto_cast vulkan.end_pass,
  }
	case .D3D11: log.panic("D3D11 is not supported")
	case .D3D12: log.panic("D3D12 is not supported")
	case .Metal: log.panic("Metal is not supported")
	}
  return {}
}

// create_buffer :: proc(renderer: ^Renderer, info: ^rendering.Buffer_Create_Info) -> rendering.Buffer {
// 	switch render_api {
// 	case .OpenGL: return opengl.create_buffer(auto_cast renderer.ctx, info)
//   case .Vulkan: log.panic("Vulkan is not supported")
// 	case .D3D11:  log.panic("D3D11 is not supported")
// 	case .D3D12:  log.panic("D3D12 is not supported")
// 	case .Metal:  log.panic("Metal is not supported")
// 	}
// 	return {}
// }
//
// destroy_buffer :: proc(renderer: ^Renderer, buffer: rendering.Buffer) {
// 	switch render_api {
// 	case .OpenGL: opengl.destroy_buffer(auto_cast renderer.ctx, buffer)
//   case .Vulkan: log.panic("Vulkan is not supported")
// 	case .D3D11:  log.panic("D3D11 is not supported")
// 	case .D3D12:  log.panic("D3D12 is not supported")
// 	case .Metal:  log.panic("Metal is not supported")
// 	}
// }
//
// create_pipeline :: proc(renderer: ^Renderer, info: ^rendering.Pipeline_Create_Info) -> rendering.Pipeline {
// 	switch render_api {
// 	case .OpenGL: return opengl.create_pipeline(auto_cast renderer.ctx, info)
//   case .Vulkan: log.panic("Vulkan is not supported")
// 	case .D3D11:  log.panic("D3D11 is not supported")
// 	case .D3D12:  log.panic("D3D12 is not supported")
// 	case .Metal:  log.panic("Metal is not supported")
// 	}
// 	return {}
// }
//
// destroy_pipeline :: proc(renderer: ^Renderer, pipeline: rendering.Pipeline) {
// 	switch render_api {
// 	case .OpenGL: opengl.destroy_pipeline(auto_cast renderer.ctx, pipeline)
//   case .Vulkan: log.panic("Vulkan is not supported")
// 	case .D3D11:  log.panic("D3D11 is not supported")
// 	case .D3D12:  log.panic("D3D12 is not supported")
// 	case .Metal:  log.panic("Metal is not supported")
// 	}
// }
//
// bind_pipeline :: proc(renderer: ^Renderer, pipeline: rendering.Pipeline) {
// 	switch render_api {
// 	case .OpenGL: opengl.bind_pipeline(auto_cast renderer.ctx, pipeline)
//   case .Vulkan: log.panic("Vulkan is not supported")
// 	case .D3D11:  log.panic("D3D11 is not supported")
// 	case .D3D12:  log.panic("D3D12 is not supported")
// 	case .Metal:  log.panic("Metal is not supported")
// 	}
// }
//
// bind_vertex_buffers :: proc(renderer: ^Renderer, buffers: []Buffer) {
// 	switch render_api {
// 	case .OpenGL: opengl.bind_vertex_buffers(auto_cast renderer.ctx, buffers)
//   case .Vulkan: log.panic("Vulkan is not supported")
// 	case .D3D11:  log.panic("D3D11 is not supported")
// 	case .D3D12:  log.panic("D3D12 is not supported")
// 	case .Metal:  log.panic("Metal is not supported")
// 	}
// }
//
// bind_index_buffer :: proc(renderer: ^Renderer, buffer: Buffer) {
// 	switch render_api {
// 	case .OpenGL: opengl.bind_index_buffer(auto_cast renderer.ctx, buffer)
//   case .Vulkan: log.panic("Vulkan is not supported")
// 	case .D3D11:  log.panic("D3D11 is not supported")
// 	case .D3D12:  log.panic("D3D12 is not supported")
// 	case .Metal:  log.panic("Metal is not supported")
// 	}
// }
//
// draw :: proc(renderer: ^Renderer, element_count: int, first_element := 0, instance_count := 1, first_instance := 0) {
// 	switch render_api {
// 	case .OpenGL: opengl.draw(auto_cast renderer.ctx, element_count, first_element, instance_count, first_instance)
//   case .Vulkan: log.panic("Vulkan is not supported")
// 	case .D3D11:  log.panic("D3D11 is not supported")
// 	case .D3D12:  log.panic("D3D12 is not supported")
// 	case .Metal:  log.panic("Metal is not supported")
// 	}
// }
//
// create_shader :: proc(renderer: ^Renderer, info: ^rendering.Shader_Create_Info) -> rendering.Shader {
// 	switch render_api {
// 	case .OpenGL: return opengl.create_shader(auto_cast renderer.ctx, info)
//   case .Vulkan: return vulkan.create_shader(auto_cast renderer.ctx, info)
// 	case .D3D11:  log.panic("D3D11 is not supported")
// 	case .D3D12:  log.panic("D3D12 is not supported")
// 	case .Metal:  log.panic("Metal is not supported")
// 	}
// 	return {}
// }
//
// shader_set_push_constants :: proc(renderer: ^Renderer, shader: rendering.Shader, name: string, data: ^$T, offset := 0) {
//   shader_set_push_constants_raw(renderer, shader, name, data, size_of(T), offset)
// }
//
// shader_set_push_constants_raw :: proc(renderer: ^Renderer, shader: rendering.Shader, name: string, data: rawptr, size: int, offset: int) {
//   switch render_api {
//   case .OpenGL: opengl.shader_set_push_constants(auto_cast renderer.ctx, shader, name, data, size, offset)
//   case .Vulkan: panic("unsupported")
//   case .D3D11: panic("unsupported")
//   case .D3D12: panic("unsupported")
//   case .Metal: panic("unsupported")
//   }
// }
//
// destroy_shader :: proc(renderer: ^Renderer, shader: rendering.Shader) {
//   switch render_api {
//   case .OpenGL: opengl.destroy_shader(auto_cast renderer.ctx, shader)
//   case .Vulkan: vulkan.destroy_shader(auto_cast renderer.ctx, shader)
//   case .D3D11:
//   case .D3D12:
//   case .Metal:
//   }
// }
//
// create_texture :: proc(renderer: ^Renderer, info: ^rendering.Texture_Create_Info) -> rendering.Texture {
// 	switch render_api {
// 	case .OpenGL:
//     return opengl.create_texture(auto_cast renderer.ctx, info)
// 	case .D3D11:
// 		log.panic("D3D11 is not supported")
// 	case .D3D12:
// 		log.panic("D3D12 is not supported")
// 	case .Vulkan:
// 		log.panic("Vulkan is not supported")
// 	case .Metal:
// 		log.panic("Metal is not supported")
// 	}
// 	return {}
// }
//
// get_texture_descriptor :: proc(renderer: ^Renderer, texture: rendering.Texture) -> u64 {
// 	switch render_api {
// 	case .OpenGL:
//     return opengl.get_texture_descriptor(auto_cast renderer.ctx, texture)
// 	case .D3D11:
// 		log.panic("D3D11 is not supported")
// 	case .D3D12:
// 		log.panic("D3D12 is not supported")
// 	case .Vulkan:
// 		log.panic("Vulkan is not supported")
// 	case .Metal:
// 		log.panic("Metal is not supported")
// 	}
//   unreachable()
// }

// TODO:
//  remove this
bind_texture :: proc(renderer: ^Renderer, texture: rendering.Texture, unit: u32 = 0) {
	// switch render_api {
	// case .OpenGL:
    opengl.bind_texture(texture, unit)
	// case .D3D11:
	// 	log.panic("D3D11 is not supported")
	// case .D3D12:
	// 	log.panic("D3D12 is not supported")
	// case .Vulkan:
	// 	log.panic("Vulkan is not supported")
	// case .Metal:
	// 	log.panic("Metal is not supported")
	// }
}

// begin_pass :: proc(renderer: ^Renderer, info: ^rendering.Pass_Info) {
// 	switch render_api {
// 	case .OpenGL:
//     opengl.begin_pass(auto_cast renderer.ctx, info)
// 	case .D3D11:
// 		log.panic("D3D11 is not supported")
// 	case .D3D12:
// 		log.panic("D3D12 is not supported")
// 	case .Vulkan:
// 		log.panic("Vulkan is not supported")
// 	case .Metal:
// 		log.panic("Metal is not supported")
// 	}
// }
//
// end_pass :: proc(renderer: ^Renderer) {
// 	switch render_api {
// 	case .OpenGL:
//     opengl.end_pass(auto_cast renderer.ctx)
// 	case .D3D11:
// 		log.panic("D3D11 is not supported")
// 	case .D3D12:
// 		log.panic("D3D12 is not supported")
// 	case .Vulkan:
// 		log.panic("Vulkan is not supported")
// 	case .Metal:
// 		log.panic("Metal is not supported")
// 	}
// }
//
