package sandbox

import "../engine/"

import "core:fmt"

Fart :: struct {
	poop: int,
	pee:  f32,
}

Shart :: struct {
	diarea: bool,
}

main :: proc() {
	engine.init()
	defer engine.terminate()

	engine.set_clear_color({0.3, 0.8, 0.4, 1.0})

	frame_messure_time: f32
	frame_count: u64

	scene := engine.scene_create("New Scene")
	engine.load_scene(scene)

	e := engine.create_entity()
	e2 := engine.create_entity()
	e3 := engine.create_entity()
	e4 := engine.create_entity()
	engine.add_component(e, Fart{10, 3.14})
	engine.add_component(e2, Fart{67, 2.7})
	engine.add_component(e2, Shart{true})
	engine.add_component(e4, Shart{false})

	for arch in engine.query(engine.has(Fart), engine.has(Shart)) {
		farts := engine.get_table(arch, Fart)
		sharts := engine.get_table(arch, Shart)
		for e, i in arch.entities {
			fmt.println("\tFart: ", farts[i])
			fmt.println("\tShart: ", sharts[i])
		}
	}
	engine.destroy_entity(e2)

	for engine.is_running() {
		engine.frame_start()

		if engine.key_pressed(.Escape) {
			engine.close()
		}

		// frame_count += 1
		// if engine.get_time() - frame_messure_time >= 0.5 {
		// 	fmt.println("FPS:", cast(f32)frame_count / (engine.get_time() - frame_messure_time))
		// 	frame_messure_time = engine.get_time()
		// 	frame_count = 0
		// }

		engine.frame_end()
	}
}
