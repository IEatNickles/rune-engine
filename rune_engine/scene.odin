package rune_engine

Scene :: struct {
	name:      string,
	ecs_world: ^EcsWorld,
}

scene_create :: proc(name: string) -> ^Scene {
	scene := new(Scene)
	scene.name = name
	scene.ecs_world = create_world()
	return scene
}
