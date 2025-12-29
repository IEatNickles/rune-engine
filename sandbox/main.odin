package sandbox

import "../rune_engine/"
import "../rune_engine/rendering/"
import "base:runtime"
import "core:math"
import "core:math/linalg"
import "core:mem"
import "core:os/os2"
import "core:reflect"

import gl "vendor:OpenGL"

import "core:fmt"

import "core:encoding/base64"
import "core:encoding/cbor"
import "core:encoding/hex"
import "core:encoding/json"

GameLayer :: struct {
	e:       rune_engine.Entity,
	cam_rot: [2]f32,
	monky:   rune_engine.Model,
	scene:   ^rune_engine.Scene,
}

main :: proc() {
	// info := runtime.type_info_base(type_info_of(GayLayer)).variant.(reflect.Type_Info_Struct)
	// name := reflect.struct_tag_get(reflect.Struct_Tag(info.tags[0]), "field")
	// fmt.println(name)

	j, e := json.parse(#load("./fart.json", []byte))

	cbor_data, e2 := cbor.from_json(j)

	cbor_file, err := os2.create("fart.cbor")
	os2.write(cbor_file, transmute([]byte)cbor_data)

	j, e2 = cbor.to_json(cbor_data)
	d, e3 := json.marshal(j, json.Marshal_Options{pretty = true, spaces = 2, use_spaces = true})
	fmt.println(string(d))

	rune_engine.init("Rune Engine Demo")
	defer rune_engine.terminate()

	rune_engine.push_layer(
		GameLayer,
		game_layer_on_attach,
		game_layer_on_update,
		game_layer_on_detach,
	)

	rune_engine.run()
}

game_layer_on_attach :: proc(self: ^GameLayer) {
	p := rune_engine.create_project("Fart", "/home/jdw/dev/rune-engine/sandbox")

	self.scene = rune_engine.scene_create("New Scene")
	rune_engine.set_clear_color({55 / 255.0, 180 / 255.0, 180 / 255.0, 1.0})
	rune_engine.set_cursor_state(.LockedAndHidden)

	self.monky = rune_engine.load_model_gltf("assets/models/moky.glb")
	// defer rune_engine.destroy_model(&monky)

	tex := rune_engine.load_texture("assets/textures/doodoo.png")
	rune_engine.bind_texture(tex)

	self.e = rune_engine.create_entity(self.scene)
	e2 := rune_engine.create_entity(self.scene)
	e3 := rune_engine.create_entity(self.scene)
	e4 := rune_engine.create_entity(self.scene)
	rune_engine.add_component(
		self.scene,
		self.e,
		rune_engine.TransformComponent {
			{0, 0, 3},
			linalg.quaternion_from_pitch_yaw_roll_f32(0, 0, 0),
			{1, 1, 1},
		},
	)
	rune_engine.add_component(
		self.scene,
		self.e,
		rune_engine.CameraComponent{110, 16.0 / 9.0, 0.1, 100.0},
	)
	rune_engine.add_component(
		self.scene,
		e2,
		rune_engine.TransformComponent{{0, 0, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
	)
	rune_engine.add_component(
		self.scene,
		e2,
		rune_engine.MeshRendererComponent{self.monky.meshes[0]},
	)
	rune_engine.add_component(
		self.scene,
		e3,
		rune_engine.TransformComponent{{0, 3, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
	)
	rune_engine.add_component(
		self.scene,
		e3,
		rune_engine.MeshRendererComponent{self.monky.meshes[0]},
	)
	rune_engine.add_component(
		self.scene,
		e3,
		rune_engine.RigidBodyComponent {
			type = .Dynamic,
			is_trigger = false,
			shape = rune_engine.SphereShape{radius = 1.0},
		},
	)

	rune_engine.add_component(
		self.scene,
		e4,
		rune_engine.TransformComponent {
			{0, -3, 0},
			linalg.quaternion_from_pitch_yaw_roll_f32(math.to_radians_f32(10), 0, 0),
			{1, 1, 1},
		},
	)
	rune_engine.add_component(
		self.scene,
		e4,
		rune_engine.RigidBodyComponent {
			type = .Static,
			is_trigger = false,
			//shape = rune_engine.BoxShape{extents = {20, 0.3, 20}},
			shape = rune_engine.PlaneShape{normal = {0, 1, 0}},
		},
	)

	rune_engine.start_scene(self.scene)
}

game_layer_on_update :: proc(self: ^GameLayer) {
	if rune_engine.key_pressed(.Escape) {
		rune_engine.close()
	}

	{
		cam_trf := rune_engine.get_component(self.scene, self.e, rune_engine.TransformComponent)
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
		)
	}

	rune_engine.update_scene(self.scene)
	rune_engine.draw_scene(self.scene)
}

game_layer_on_detach :: proc(self: ^GameLayer) {
	rune_engine.destroy_model(&self.monky)
}
