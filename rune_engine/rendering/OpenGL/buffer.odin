package opengl

import rendering "../"

import gl "vendor:OpenGL"

create_buffer :: proc {
	create_buffer_empty,
	create_buffer_with_data_slice,
	create_buffer_with_data_array,
}

create_buffer_empty :: proc() -> rendering.Buffer {
	buffer: u32
	gl.CreateBuffers(1, &buffer)

	return rendering.Buffer(buffer)
}

create_buffer_with_data_slice :: proc(data: []$T) -> rendering.Buffer {
	buffer: u32
	gl.CreateBuffers(1, &buffer)
	gl.NamedBufferStorage(buffer, len(data) * size_of(T), raw_data(data), 0)

	return rendering.Buffer(buffer)
}

create_buffer_with_data_array :: proc(data: [$N]$T) -> rendering.Buffer {
	buffer: u32
	gl.CreateBuffers(1, &buffer)
	gl.NamedBufferStorage(buffer, N * size_of(T), raw_data(data), 0)

	return rendering.Buffer(buffer)
}

create_uniform_buffer :: proc(size: u32) -> rendering.Buffer {
	buffer: u32
	gl.CreateBuffers(1, &buffer)
	gl.NamedBufferStorage(buffer, int(size), nil, gl.DYNAMIC_STORAGE_BIT)
	gl.BindBufferBase(gl.UNIFORM_BUFFER, 0, buffer)

	return rendering.Buffer(buffer)
}

buffer_set_sub_data :: proc(buffer: rendering.Buffer, offset: int, data: []$T) {
	gl.NamedBufferSubData(u32(buffer), offset, len(data) * size_of(T), raw_data(data))
}

buffer_set_sub_data_ptr :: proc(buffer: rendering.Buffer, offset: int, data: [^]$T, length: int) {
	gl.NamedBufferSubData(u32(buffer), offset, length * size_of(T), data)
}
