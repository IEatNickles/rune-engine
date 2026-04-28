package opengl

import "core:container/handle_map"

import gl "vendor:OpenGL"

import ".."

Pipeline_State :: struct {
  handle:        rendering.Pipeline,
  vertex_stride: int,
  vertex_layout: []rendering.Vertex_Attribute,
  shader:        rendering.Shader,
}

create_pipeline :: proc(ctx: ^Context, info: ^rendering.Pipeline_Create_Info) -> rendering.Pipeline {
  state := Pipeline_State{
    shader = info.shader,
  }
  state.vertex_layout = make([]rendering.Vertex_Attribute, len(info.vertex_layout))
  for att, i in info.vertex_layout {
    state.vertex_stride += rendering.color_format_size(att.format)
    state.vertex_layout[i] = info.vertex_layout[i]
  }
  return handle_map.add(&ctx.pipelines, state)
}

destroy_pipeline :: proc(ctx: ^Context, pipeline: rendering.Pipeline) {
  handle_map.remove(&ctx.pipelines, pipeline)
}

bind_pipeline :: proc(ctx: ^Context, pipeline: rendering.Pipeline) {
  ctx.current_pipeline = pipeline
  state := handle_map.get(&ctx.pipelines, pipeline)
  shader_state := handle_map.get(&ctx.shaders, state.shader)
  gl.UseProgram(shader_state.program_id)
}

bind_vertex_buffers :: proc(ctx: ^Context, buffers: []rendering.Buffer) {
  pip := handle_map.get(&ctx.pipelines, ctx.current_pipeline)
  assert(len(pip.vertex_layout) == len(buffers))

  gl.BindVertexArray(ctx.vao)
  for att, i in pip.vertex_layout {
    buf := handle_map.get(&ctx.buffers, buffers[i])
    gl.BindBuffer(gl.ARRAY_BUFFER, buf.id)
    gl.EnableVertexAttribArray(u32(att.location))
    gl.VertexAttribPointer(
      u32(att.location),
      i32(rendering.color_format_component_count(att.format)),
      u32(gl_get_texture_pixel_type(att.format)),
      false, i32(rendering.color_format_size(att.format)), 0)
  }
}

bind_index_buffer :: proc(ctx: ^Context, buffer: rendering.Buffer) {
  buf := handle_map.get(&ctx.buffers, buffer)
  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, buf.id)
}

// TODO:
//  add drawing without index buffer
draw :: proc(ctx: ^Context, element_count, first_element, instance_count, first_instance: int) {
  if instance_count > 1 {
    gl.DrawElementsInstancedBaseInstance(gl.TRIANGLES, i32(element_count), gl.UNSIGNED_SHORT, rawptr(uintptr(first_element)), i32(instance_count), u32(first_instance))
  } else {
    gl.DrawElements(gl.TRIANGLES, i32(element_count), gl.UNSIGNED_SHORT, rawptr(uintptr(first_element)))
  }
}
