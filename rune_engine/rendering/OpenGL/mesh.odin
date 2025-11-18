package opengl

import "core:fmt"
import "core:log"
import "vendor:cgltf"

import gl "vendor:OpenGL"

import ".."

Mesh :: struct {
	vao, ebo:                  u32,
	vbos:                      [5]u32,
	vertex_count, index_count: int,
	transform:                 matrix[4, 4]f32,
}

meshes: [dynamic]Mesh

create_mesh :: proc(
	positions, normals, texcoords, colors, tangents: []f32,
	indices: []u16,
	transform: matrix[4, 4]f32,
) -> rendering.Mesh {
	mesh: Mesh
	for i in 0 ..< len(mesh.vbos) {
		gl.CreateBuffers(1, &mesh.vbos[i])
	}
	gl.CreateBuffers(1, &mesh.ebo)
	gl.CreateVertexArrays(1, &mesh.vao)

	mesh.vertex_count = len(positions) / 3
	mesh.index_count = len(indices)

	gl.EnableVertexArrayAttrib(mesh.vao, 0)
	gl.EnableVertexArrayAttrib(mesh.vao, 1)
	gl.EnableVertexArrayAttrib(mesh.vao, 2)
	gl.EnableVertexArrayAttrib(mesh.vao, 3)
	gl.EnableVertexArrayAttrib(mesh.vao, 4)

	gl.VertexArrayAttribFormat(mesh.vao, 0, 3, gl.FLOAT, false, 0)
	gl.VertexArrayAttribFormat(mesh.vao, 1, 3, gl.FLOAT, false, 0)
	gl.VertexArrayAttribFormat(mesh.vao, 2, 2, gl.FLOAT, false, 0)
	gl.VertexArrayAttribFormat(mesh.vao, 3, 4, gl.FLOAT, false, 0)
	gl.VertexArrayAttribFormat(mesh.vao, 4, 4, gl.FLOAT, false, 0)

	gl.VertexArrayAttribBinding(mesh.vao, 0, 0)
	gl.VertexArrayAttribBinding(mesh.vao, 1, 1)
	gl.VertexArrayAttribBinding(mesh.vao, 2, 2)
	gl.VertexArrayAttribBinding(mesh.vao, 3, 3)
	gl.VertexArrayAttribBinding(mesh.vao, 4, 4)

	gl.VertexArrayVertexBuffer(mesh.vao, 0, mesh.vbos[0], 0, size_of(f32) * 3)
	gl.VertexArrayVertexBuffer(mesh.vao, 1, mesh.vbos[1], 0, size_of(f32) * 3)
	gl.VertexArrayVertexBuffer(mesh.vao, 2, mesh.vbos[2], 0, size_of(f32) * 2)
	gl.VertexArrayVertexBuffer(mesh.vao, 3, mesh.vbos[3], 0, size_of(f32) * 4)
	gl.VertexArrayVertexBuffer(mesh.vao, 4, mesh.vbos[4], 0, size_of(f32) * 4)
	gl.VertexArrayElementBuffer(mesh.vao, mesh.ebo)

	pos_size := size_of(f32) * len(positions)
	nrm_size := size_of(f32) * len(normals)
	tex_size := size_of(f32) * len(texcoords)
	col_size := size_of(f32) * len(colors)
	tan_size := size_of(f32) * len(tangents)
	idc_size := size_of(u16) * mesh.index_count

	if pos_size > 0 do gl.NamedBufferStorage(mesh.vbos[0], pos_size, raw_data(positions), 0)
	if nrm_size > 0 do gl.NamedBufferStorage(mesh.vbos[1], nrm_size, raw_data(normals), 0)
	if tex_size > 0 do gl.NamedBufferStorage(mesh.vbos[2], tex_size, raw_data(texcoords), 0)
	if col_size > 0 do gl.NamedBufferStorage(mesh.vbos[3], col_size, raw_data(colors), 0)
	if tan_size > 0 do gl.NamedBufferStorage(mesh.vbos[4], tan_size, raw_data(tangents), 0)
	if idc_size > 0 do gl.NamedBufferStorage(mesh.ebo, idc_size, raw_data(indices), 0)

	mesh.transform = transform

	append(&meshes, mesh)
	return cast(rendering.Mesh)(len(meshes) - 1)
}

destroy_mesh :: proc(mesh: rendering.Mesh) {
	mesh_data := meshes[mesh]
	gl.DeleteBuffers(1, &mesh_data.vbos[0])
	gl.DeleteBuffers(1, &mesh_data.vbos[1])
	gl.DeleteBuffers(1, &mesh_data.vbos[2])
	gl.DeleteBuffers(1, &mesh_data.vbos[3])
	gl.DeleteBuffers(1, &mesh_data.vbos[4])
	gl.DeleteBuffers(1, &mesh_data.ebo)
	gl.DeleteVertexArrays(1, &mesh_data.vao)
}

draw_mesh :: proc(mesh: rendering.Mesh) {
	mesh_data := meshes[mesh]
	gl.BindVertexArray(mesh_data.vao)
	gl.DrawElements(gl.TRIANGLES, i32(mesh_data.index_count), gl.UNSIGNED_SHORT, nil)
}
