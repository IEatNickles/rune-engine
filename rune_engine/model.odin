package rune_engine

import "core:fmt"
import "core:log"
import "vendor:cgltf"

import "renderer"

Mesh :: struct {
  vertex_buffers: [5]renderer.Buffer,
  index_buffer:   renderer.Buffer,
  transform:      matrix[4,4]f32,
  index_count:    int,
}

Model :: struct {
	meshes: []Mesh,
}

load_model_gltf :: proc(path: string) -> Model {
	cpath := cast(cstring)raw_data(path)
	options: cgltf.options

	data: ^cgltf.data
	res: cgltf.result
	data, res = cgltf.parse_file(options, cpath)
	if res != .success {
		log.error(res)
	}

	res = cgltf.load_buffers(options, data, cpath)
	if res != .success {
		log.error(res)
	}

	meshes: [dynamic]Mesh
	for node in data.nodes {
		vertex_count: uint
		index_count: uint
		for primitive in node.mesh.primitives {
			if primitive.indices != nil && primitive.indices.buffer_view != nil {
				index_count += primitive.indices.count
				for att in primitive.attributes {
					if att.type == .position {
						vertex_count += att.data.count
					}
				}
			}
		}
		positions: [dynamic]f32
		reserve(&positions, vertex_count * 3)
		normals: [dynamic]f32
		reserve(&normals, vertex_count * 3)
		texcoords: [dynamic]f32
		reserve(&texcoords, vertex_count * 2)
		colors: [dynamic]f32
		reserve(&colors, vertex_count * 4)
		tangents: [dynamic]f32
		reserve(&tangents, vertex_count * 4)
		indices: [dynamic]u16
		reserve(&indices, index_count)
		transform_raw := node.matrix_
		mat := matrix[4, 4]f32{
			transform_raw[0], transform_raw[1], transform_raw[2], transform_raw[3],
			transform_raw[4], transform_raw[5], transform_raw[6], transform_raw[7],
			transform_raw[8], transform_raw[9], transform_raw[10], transform_raw[11],
			transform_raw[12], transform_raw[13], transform_raw[14], transform_raw[15],
		}
		for primitive in node.mesh.primitives {
			if primitive.indices != nil && primitive.indices.buffer_view != nil {
				index_buf := make([]u16, primitive.indices.count)
				if unpacked_count := cgltf.accessor_unpack_indices(
					primitive.indices,
					raw_data(index_buf),
					size_of(u16),
					primitive.indices.count,
				); unpacked_count < primitive.indices.count {
					log.error("Error unpacking indices of mesh")
				}
				for i in index_buf {
					append(&indices, i)
				}
				for att in primitive.attributes {
					switch att.type {
					case .position:
						buf := make([]f32, att.data.count * 3)
						if unpacked_positions := cgltf.accessor_unpack_floats(
							att.data,
							raw_data(buf),
							att.data.count * 3,
						); unpacked_positions < att.data.count {
							log.error("Error unpacking positions of mesh")
						}
						for v in buf {
							append(&positions, v)
						}
					case .normal:
						buf := make([]f32, att.data.count * 3)
						if unpacked_normals := cgltf.accessor_unpack_floats(
							att.data,
							raw_data(buf),
							att.data.count * 3,
						); unpacked_normals < att.data.count {
							log.error("Error unpacking normals of mesh")
						}
						for v in buf {
							append(&normals, v)
						}
					case .texcoord:
						buf := make([]f32, att.data.count * 2)
						if unpacked_texcoords := cgltf.accessor_unpack_floats(
							att.data,
							raw_data(buf),
							att.data.count * 2,
						); unpacked_texcoords < att.data.count {
							log.error("Error unpacking texcoords of mesh")
						}
						for v in buf {
							append(&texcoords, v)
						}
					case .color:
						buf := make([]f32, att.data.count * 4)
						if unpacked_colors := cgltf.accessor_unpack_floats(
							att.data,
							raw_data(buf),
							att.data.count * 3,
						); unpacked_colors < att.data.count {
							log.error("Error unpacking colors of mesh")
						}
						for v in buf {
							append(&colors, v)
						}
					case .tangent:
						buf := make([]f32, att.data.count * 4)
						if unpacked_tangents := cgltf.accessor_unpack_floats(
							att.data,
							raw_data(buf),
							att.data.count * 3,
						); unpacked_tangents < att.data.count {
							log.error("Error unpacking tangents of mesh")
						}
						for v in buf {
							append(&tangents, v)
						}

					// TODO
					case .joints:
					case .weights:

					case .custom:
					case .invalid:
					}
				}
			}
		}
		mesh := create_mesh(
			positions[:],
			normals[:],
			texcoords[:],
			colors[:],
			tangents[:],
			indices[:],
			mat,
		)
		append(&meshes, mesh)
	}

	return Model{meshes[:]}
}

destroy_model :: proc(model: ^Model) {
  for m in model.meshes {
    renderer.destroy_buffer(&application.renderer, m.vertex_buffers[0])
    renderer.destroy_buffer(&application.renderer, m.vertex_buffers[1])
    renderer.destroy_buffer(&application.renderer, m.vertex_buffers[2])
    renderer.destroy_buffer(&application.renderer, m.vertex_buffers[3])
    renderer.destroy_buffer(&application.renderer, m.vertex_buffers[4])
    renderer.destroy_buffer(&application.renderer, m.index_buffer)
  }
}

draw_model :: proc(model: ^Model) {
  for m in model.meshes {
    draw_mesh(m)
  }
}

create_mesh :: proc(
	positions, normals, texcoords, colors, tangents: []f32,
	indices: []u16,
	transform: matrix[4, 4]f32,
) -> (mesh: Mesh) {
  mesh.vertex_buffers[0] = renderer.create_buffer(&application.renderer, &{
    usage = { .Vertex_Buffer },
    data = raw_data(positions),
    size = len(positions) * size_of(f32),
  })
  mesh.vertex_buffers[1] = renderer.create_buffer(&application.renderer, &{
    usage = { .Vertex_Buffer },
    data = raw_data(normals),
    size = len(normals) * size_of(f32),
  })
  mesh.vertex_buffers[2] = renderer.create_buffer(&application.renderer, &{
    usage = { .Vertex_Buffer },
    data = raw_data(texcoords),
    size = len(texcoords) * size_of(f32),
  })
  mesh.vertex_buffers[3] = renderer.create_buffer(&application.renderer, &{
    usage = { .Vertex_Buffer },
    data = raw_data(colors),
    size = len(colors) * size_of(f32),
  })
  mesh.vertex_buffers[4] = renderer.create_buffer(&application.renderer, &{
    usage = { .Vertex_Buffer },
    data = raw_data(tangents),
    size = len(tangents) * size_of(f32),
  })
  mesh.index_buffer = renderer.create_buffer(&application.renderer, &{
    usage = { .Index_Buffer },
    data = raw_data(indices),
    size = len(indices) * size_of(u16),
  })
  mesh.transform = transform
  mesh.index_count = len(indices)
	return
}

draw_mesh :: proc(mesh: Mesh) {
  vbs := mesh.vertex_buffers
  renderer.bind_vertex_buffers(&application.renderer, vbs[:])
  renderer.bind_index_buffer(&application.renderer, mesh.index_buffer)
  renderer.draw(&application.renderer, mesh.index_count)
}
