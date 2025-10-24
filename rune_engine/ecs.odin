// This is just a wrapper around [YggECS](https://github.com/NateTheGreatt/YggECS)

package rune_engine

import ygg "deps/YggECS/src"

Entity :: ygg.EntityID
EcsWorld :: ygg.World

create_world :: ygg.create_world
delete_world :: ygg.delete_world
create_entity :: proc() -> Entity {
	return ygg.add_entity(application.current_scene.ecs_world)
}
add_component :: proc(entity: Entity, component: $T) {
	ygg.add_component(application.current_scene.ecs_world, entity, component)
}
remove_component :: proc(entity: Entity, component: $T) {
	ygg.remove_component(application.current_scene.ecs_world, entity, component)
}
get_component :: proc(entity: Entity, $Component: typeid) -> ^Component {
	return ygg.get_component(application.current_scene.ecs_world, entity, Component)
}
has_component :: proc(entity: Entity, $Component: typeid) -> bool {
	return ygg.has_component(application.current_scene.ecs_world, entity, Component)
}
query :: proc(terms: ..ygg.Term) -> []^ygg.Archetype {
	return ygg.query(application.current_scene.ecs_world, ..terms)
}
get_table :: proc(archetype: ^ygg.Archetype, $Component: typeid) -> []Component {
	return ygg.get_table(application.current_scene.ecs_world, archetype, Component)
}
destroy_entity :: proc(entity: Entity) {
	ygg.remove_entity(application.current_scene.ecs_world, entity)
}
has :: ygg.has
not :: ygg.not
