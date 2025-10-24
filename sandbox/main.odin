package sandbox

import "../rune_engine/"
import "../rune_engine/rendering/"
import "core:math"
import "core:math/linalg"

import gl "vendor:OpenGL"

import "core:fmt"

MeshRenderer :: struct {
	model: rune_engine.Model,
}

TransformComponent :: struct {
	position: [3]f32,
	rotation: quaternion128,
	scale:    [3]f32,
}

CameraComponent :: struct {
	fov:       f32,
	aspect:    f32,
	near, far: f32,
}

debug_callback :: proc "c" (source, type, id, severity, length, message, userparam: i32) {
}

main :: proc() {
	rune_engine.init("Rune Engine Demo")
	defer rune_engine.terminate()

	rune_engine.set_clear_color({55 / 255.0, 180 / 255.0, 180 / 255.0, 1.0})
	rune_engine.set_cursor_state(.LockedAndHidden)

	frame_messure_time: f32
	frame_count: u64

	scene := rune_engine.scene_create("New Scene")
	rune_engine.load_scene(scene)

	monky := rune_engine.load_model_gltf("assets/models/moky.glb")
	defer rune_engine.destroy_model(&monky)

	e := rune_engine.create_entity()
	e2 := rune_engine.create_entity()
	e3 := rune_engine.create_entity()
	rune_engine.add_component(
		e,
		TransformComponent {
			{0, 0, 3},
			linalg.quaternion_from_pitch_yaw_roll_f32(0, 0, 0),
			{1, 1, 1},
		},
	)
	rune_engine.add_component(e, CameraComponent{110, 16.0 / 9.0, 0.1, 100.0})
	rune_engine.add_component(
		e2,
		TransformComponent{{0, 0, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
	)
	rune_engine.add_component(e2, MeshRenderer{monky})
	rune_engine.add_component(
		e3,
		TransformComponent{{0, 3, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
	)
	rune_engine.add_component(e3, MeshRenderer{monky})

	prog := rune_engine.load_shader("assets/shaders/test.vs", "assets/shaders/test.fs")

	rune_engine.bind_shader(&prog)

	tex := rune_engine.load_texture("assets/textures/doodoo.png")
	rune_engine.bind_texture(&tex)

	world := linalg.MATRIX4F32_IDENTITY
	view := linalg.MATRIX4F32_IDENTITY
	proj := linalg.MATRIX4F32_IDENTITY

	cam_rot: [2]f32

	for rune_engine.is_running() {
		rune_engine.frame_start()

		if rune_engine.key_pressed(.Escape) {
			rune_engine.close()
		}

		{
			cam_trf := rune_engine.get_component(e, TransformComponent)
			fw := linalg.quaternion128_mul_vector3(cam_trf.rotation, [3]f32{0, 0, 1})
			rg := linalg.quaternion128_mul_vector3(cam_trf.rotation, [3]f32{1, 0, 0})
			speed: f32 = 0.1
			if rune_engine.key_down(.W) {
				cam_trf.position -= fw * speed
			}
			if rune_engine.key_down(.S) {
				cam_trf.position += fw * speed
			}
			if rune_engine.key_down(.A) {
				cam_trf.position -= rg * speed
			}
			if rune_engine.key_down(.D) {
				cam_trf.position += rg * speed
			}
			if rune_engine.key_down(.Space) {
				cam_trf.position += {0, speed, 0}
			}
			if rune_engine.key_down(.LeftShift) {
				cam_trf.position -= {0, speed, 0}
			}

			cam_rot -= rune_engine.get_mouse_delta() * 0.4
			cam_rot.y = math.clamp(cam_rot.y, -90, 90)
			cam_trf.rotation = linalg.quaternion_from_pitch_yaw_roll(
				math.to_radians(cam_rot.y),
				math.to_radians(cam_rot.x),
				0,
			)
		}

		for cam_arch in rune_engine.query(
			rune_engine.has(TransformComponent),
			rune_engine.has(CameraComponent),
		) {
			cam_table := rune_engine.get_table(cam_arch, CameraComponent)
			cam_trf_table := rune_engine.get_table(cam_arch, TransformComponent)
			for e, i in cam_arch.entities {
				transform := &cam_trf_table[i]
				view = linalg.inverse(
					linalg.matrix4_translate(transform.position) *
					linalg.matrix4_from_quaternion(transform.rotation),
				)
				proj = linalg.matrix4_perspective_f32(
					math.to_radians_f32(cam_table[i].fov),
					cam_table[i].aspect,
					cam_table[i].near,
					cam_table[i].far,
				)

				rune_engine.set_shader_mat4(&prog, "u_view", &view)
				rune_engine.set_shader_mat4(&prog, "u_proj", &proj)

				for mesh_arch in rune_engine.query(
					rune_engine.has(TransformComponent),
					rune_engine.has(MeshRenderer),
				) {
					mesh_table := rune_engine.get_table(mesh_arch, MeshRenderer)
					mesh_trf_table := rune_engine.get_table(mesh_arch, TransformComponent)
					for e2, i in mesh_arch.entities {
						mesh_trf := mesh_trf_table[i]
						world = linalg.matrix4_from_trs(
							mesh_trf.position,
							mesh_trf.rotation,
							mesh_trf.scale,
						)
						rune_engine.set_shader_mat4(&prog, "u_world", &world)
						rune_engine.draw_model(&monky)
					}
				}
			}
		}

		for mesh_arch in rune_engine.query(
			rune_engine.has(TransformComponent),
			rune_engine.has(MeshRenderer),
		) {
			mesh_trf_table := rune_engine.get_table(mesh_arch, TransformComponent)
			for e, i in mesh_arch.entities {
				dir: f32 = 1 if i & 1 == 0 else -1
				mesh_trf_table[i].rotation = linalg.quaternion_from_pitch_yaw_roll(
					0,
					rune_engine.get_time() * dir,
					0,
				)
			}
		}

		rune_engine.frame_end()
	}
}
