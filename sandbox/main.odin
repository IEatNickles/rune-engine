package sandbox

import "../rune_engine/"
import "../rune_engine/rendering/"
import "base:runtime"
import "core:encoding/json"
import "core:math"
import "core:math/linalg"
import "core:reflect"
import "core:strings"

import gl "vendor:OpenGL"

import "core:fmt"

GameLayer :: struct {
	e:       rune_engine.Entity,
	cam_rot: [2]f32,
	monky:   rune_engine.Model,
}

debug_callback :: proc "c" (source, type, id, severity, length, message, userparam: i32) {
}

main :: proc() {
	// info := runtime.type_info_base(type_info_of(GayLayer)).variant.(reflect.Type_Info_Struct)
	// name := reflect.struct_tag_get(reflect.Struct_Tag(info.tags[0]), "field")
	// fmt.println(name)

	rune_engine.init("Rune Engine Demo")
	defer rune_engine.terminate()

	rune_engine.set_clear_color({55 / 255.0, 180 / 255.0, 180 / 255.0, 1.0})
	rune_engine.set_cursor_state(.LockedAndHidden)

	scene := rune_engine.scene_create("New Scene")
	rune_engine.load_scene(scene)

	gler := GameLayer{}
	rune_engine.push_layer(&gler, game_layer_on_attach, game_layer_on_update, game_layer_on_detach)

	// prog := rune_engine.load_shader("assets/shaders/test.vs", "assets/shaders/test.fs")
	// rune_engine.bind_shader(&prog)

	tex := rune_engine.load_texture("assets/textures/doodoo.png")
	rune_engine.bind_texture(tex)

	rune_engine.scene_start(scene)
	for rune_engine.is_running() {
		rune_engine.frame_start()

		rune_engine.frame_end()
		rune_engine.scene_update(scene)
	}
}

game_layer_on_attach :: proc(self: ^GameLayer) {
	self.monky = rune_engine.load_model_gltf("assets/models/moky.glb")
	// defer rune_engine.destroy_model(&monky)

	self.e = rune_engine.create_entity()
	e2 := rune_engine.create_entity()
	e3 := rune_engine.create_entity()
	e4 := rune_engine.create_entity()
	rune_engine.add_component(
		self.e,
		rune_engine.TransformComponent {
			{0, 0, 3},
			linalg.quaternion_from_pitch_yaw_roll_f32(0, 0, 0),
			{1, 1, 1},
		},
	)
	rune_engine.add_component(self.e, rune_engine.CameraComponent{110, 16.0 / 9.0, 0.1, 100.0})
	rune_engine.add_component(
		e2,
		rune_engine.TransformComponent{{0, 0, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
	)
	rune_engine.add_component(e2, rune_engine.MeshRendererComponent{self.monky.meshes[0]})
	rune_engine.add_component(
		e3,
		rune_engine.TransformComponent{{0, 3, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
	)
	rune_engine.add_component(e3, rune_engine.MeshRendererComponent{self.monky.meshes[0]})
	rune_engine.add_component(
		e3,
		rune_engine.RigidBodyComponent {
			type = .Dynamic,
			is_trigger = false,
			shape = rune_engine.SphereShape{radius = 1.0},
		},
	)

	rune_engine.add_component(
		e4,
		rune_engine.TransformComponent {
			{0, -3, 0},
			linalg.quaternion_from_pitch_yaw_roll_f32(math.to_radians_f32(10), 0, 0),
			{1, 1, 1},
		},
	)
	rune_engine.add_component(
		e4,
		rune_engine.RigidBodyComponent {
			type = .Static,
			is_trigger = false,
			//shape = rune_engine.BoxShape{extents = {20, 0.3, 20}},
			shape = rune_engine.PlaneShape{normal = {0, 1, 0}},
		},
	)
}

game_layer_on_update :: proc(self: ^GameLayer) {
	if rune_engine.key_pressed(.Escape) {
		rune_engine.close()
	}

	{
		cam_trf := rune_engine.get_component(self.e, rune_engine.TransformComponent)
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

		self.cam_rot -= rune_engine.get_mouse_delta() * 0.4
		self.cam_rot.y = math.clamp(self.cam_rot.y, -90, 90)
		cam_trf.rotation = linalg.quaternion_from_pitch_yaw_roll(
			math.to_radians(self.cam_rot.y),
			math.to_radians(self.cam_rot.x),
			0,
		)}
}

game_layer_on_detach :: proc(self: ^GameLayer) {
	rune_engine.destroy_model(&self.monky)
}
