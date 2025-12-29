// This is just a wrapper around [YggECS](https://github.com/NateTheGreatt/YggECS)

package rune_engine

import "core:fmt"
import ygg "deps/YggECS/src"

Entity :: ygg.EntityID
EcsWorld :: ygg.World

create_world :: ygg.create_world
delete_world :: ygg.delete_world
create_entity :: proc(self: ^Scene) -> Entity {
	e := ygg.add_entity(self.ecs_world)
	return e
}
add_component :: proc(self: ^Scene, entity: Entity, component: $T) {
	ygg.add_component(self.ecs_world, entity, component)
}
remove_component :: proc(self: ^Scene, entity: Entity, $T: typeid) {
	ygg.remove_component(self.ecs_world, entity, T)
}
get_component :: proc(self: ^Scene, entity: Entity, $Component: typeid) -> ^Component {
	return ygg.get_component(self.ecs_world, entity, Component)
}
has_component :: proc(self: ^Scene, entity: Entity, $Component: typeid) -> bool {
	return ygg.has_component(self.ecs_world, entity, Component)
}
query :: proc(self: ^Scene, terms: ..ygg.Term) -> []^ygg.Archetype {
	return ygg.query(self.ecs_world, ..terms)
}
get_table :: proc(self: ^Scene, archetype: ^ygg.Archetype, $Component: typeid) -> []Component {
	return ygg.get_table(self.ecs_world, archetype, Component)
}
destroy_entity :: proc(self: ^Scene, entity: Entity) {
	ygg.remove_entity(self.ecs_world, entity)
}
register_component :: proc(self: ^Scene, T: typeid) {
	ygg.register_component(self.ecs_world, T)
}
has :: ygg.has
not :: ygg.not
