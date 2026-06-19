package opengl

import "core:container/handle_map"
import rendering "../"

import gl "vendor:OpenGL"

Buffer_State :: struct {
  handle: rendering.Buffer,
  id:     u32,
  target:   u32,
}

create_buffer :: proc(info: ^rendering.Buffer_Create_Info) -> rendering.Buffer {
  buffer: u32
  target:   u32
  if .Vertex_Buffer in info.usage {
    target = gl.ARRAY_BUFFER
  } else if .Index_Buffer in info.usage {
    target = gl.ELEMENT_ARRAY_BUFFER
  }
  gl.GenBuffers(1, &buffer)
  gl.BindBuffer(target, buffer)
  // TODO:
  //                                          this probably needs to change
  //                                          under certain circumstances
  //                                                 ||
  //                                                 \/
  gl.BufferData(target, info.size, info.data, gl.STATIC_DRAW)
  return handle_map.add(&ctx.buffers, Buffer_State{
    id = buffer,
    target = target,
  })
}

destroy_buffer :: proc(buffer: rendering.Buffer) {
  state := handle_map.get(&ctx.buffers, buffer)
  handle_map.remove(&ctx.buffers, buffer)
  gl.DeleteBuffers(1, &state.id)
}
