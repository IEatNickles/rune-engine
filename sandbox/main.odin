package sandbox

import "../rune_engine/"
import "../rune_engine/rendering/"

import gl "vendor:OpenGL"

import "core:fmt"

Fart :: struct {
	poop: int,
	pee:  f32,
}

Shart :: struct {
	diarea: bool,
}

main :: proc() {
	rune_engine.init()
	defer rune_engine.terminate()

	rune_engine.set_clear_color({0.3, 0.8, 0.4, 1.0})

	frame_messure_time: f32
	frame_count: u64

	scene := rune_engine.scene_create("New Scene")
	rune_engine.load_scene(scene)

	e := rune_engine.create_entity()
	e2 := rune_engine.create_entity()
	e3 := rune_engine.create_entity()
	e4 := rune_engine.create_entity()
	rune_engine.add_component(e, Fart{10, 3.14})
	rune_engine.add_component(e2, Fart{67, 2.7})
	rune_engine.add_component(e2, Shart{true})
	rune_engine.add_component(e4, Shart{false})

	ok: bool
	err: string
	prog := rendering.create_shader()
	err, ok = rendering.shader_attach_from_file(&prog, "assets/shaders/test.vs", .Vertex)
	if !ok {
		fmt.println("Vertex shader error:\n", err)
	}
	err, ok = rendering.shader_attach_from_file(&prog, "assets/shaders/test.fs", .Fragment)
	if !ok {
		fmt.println("Fragment shader error:\n", err)
	}
	err, ok = rendering.link_shader(&prog)
	if !ok {
		fmt.println("Program error:\n", err)
	}

	vbo, ebo, vao := mesh_test()

	for arch in rune_engine.query(rune_engine.has(Fart), rune_engine.has(Shart)) {
		farts := rune_engine.get_table(arch, Fart)
		sharts := rune_engine.get_table(arch, Shart)
		for e, i in arch.entities {
			fmt.println("\tFart: ", farts[i])
			fmt.println("\tShart: ", sharts[i])
		}
	}
	rune_engine.destroy_entity(e2)

	rendering.bind_shader(&prog)

	tex := rendering.load_texture("assets/textures/doodoo.png")
	rendering.bind_texture(&tex)

	for rune_engine.is_running() {
		rune_engine.frame_start()

		if rune_engine.key_pressed(.Escape) {
			rune_engine.close()
		}

		gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
		gl.BindVertexArray(vao)

		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		// frame_count += 1
		// if rune_engine.get_time() - frame_messure_time >= 0.5 {
		// 	fmt.println("FPS:", cast(f32)frame_count / (rune_engine.get_time() - frame_messure_time))
		// 	frame_messure_time = rune_engine.get_time()
		// 	frame_count = 0
		// }

		rune_engine.frame_end()
	}
}

mesh_test :: proc() -> (vbo, ebo, vao: u32) {
	gl.CreateBuffers(1, &vbo)
	gl.CreateBuffers(1, &ebo)
	gl.CreateVertexArrays(1, &vao)

	Vertex :: struct {
		pos: [3]f32,
		nrm: [3]f32,
		tex: [2]f32,
	}
	VERTICES :: []Vertex {
		{{-0.5, -0.5, 0.0}, {0, 0, 1}, {0, 0}},
		{{-0.5, 0.5, 0.0}, {0, 0, 1}, {0, 1}},
		{{0.5, -0.5, 0.0}, {0, 0, 1}, {1, 0}},
	}
	INDICES :: []i32{0, 1, 2}

	gl.NamedBufferData(vbo, len(VERTICES) * size_of(Vertex), raw_data(VERTICES), gl.STATIC_DRAW)
	gl.NamedBufferData(ebo, len(INDICES) * size_of(i32), raw_data(INDICES), gl.STATIC_DRAW)
	gl.VertexArrayVertexBuffer(vao, 0, vbo, 0, size_of(Vertex))
	gl.VertexArrayElementBuffer(vao, ebo)

	gl.EnableVertexArrayAttrib(vao, 0)
	gl.EnableVertexArrayAttrib(vao, 1)
	gl.EnableVertexArrayAttrib(vao, 2)

	gl.VertexArrayAttribFormat(vao, 0, 3, gl.FLOAT, false, u32(offset_of(Vertex, pos)))
	gl.VertexArrayAttribFormat(vao, 1, 3, gl.FLOAT, false, u32(offset_of(Vertex, nrm)))
	gl.VertexArrayAttribFormat(vao, 2, 2, gl.FLOAT, false, u32(offset_of(Vertex, tex)))

	gl.VertexArrayAttribBinding(vao, 0, 0)
	gl.VertexArrayAttribBinding(vao, 1, 0)
	gl.VertexArrayAttribBinding(vao, 2, 0)

	return
}
