package rune_engine

import "base:runtime"
import "core:container/queue"
import "core:math/bits"

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

// ComponentEntry :: struct {
// 	type:           typeid,
// 	data:           ^runtime.Raw_Dynamic_Array,
// 	entity_indices: map[Entity]uint,
// }
// 
// EcsWorld :: struct {
// 	entities:   struct {
// 		data:          [dynamic]Entity,
// 		current_id:    Entity,
// 		available_ids: queue.Queue(Entity),
// 	},
// 	components: map[typeid]ComponentEntry,
// }
// 
// ecs_create_entity :: proc(world: ^EcsWorld) -> Entity {
// 	entity: Entity
// 	if world.entities.available_ids.len > 0 {
// 		entity = queue.dequeue(&world.entities.available_ids)
// 		append_elem(&world.entities.data, entity)
// 	} else {
// 		entity = cast(Entity)world.entities.current_id
// 		world.entities.current_id += 1
// 		append_elem(&world.entities.data, entity)
// 	}
// 
// 	return entity
// }
// 
// ecs_destroy_entity :: proc(world: ^EcsWorld, entity: Entity) {
// 	found := false
// 	for e in world.entities.data {
// 		if e == entity {
// 			found = true
// 			break
// 		}
// 	}
// 	if !found {
// 		return
// 	}
// 	unordered_remove(&world.entities.data, entity)
// 	queue.enqueue(&world.entities.available_ids, entity)
// }
// 
// ecs_register_component :: proc(world: ^EcsWorld, $T: typeid) {
// 	if T in world.components {
// 		return
// 	}
// 	arr := new([dynamic]T)
// 	world.components[T] = {
// 		data = cast(^runtime.Raw_Dynamic_Array)arr,
// 		type = T,
// 	}
// 	arr^ = make_dynamic_array([dynamic]T)
// }
// 
// ecs_add_component :: proc(world: ^EcsWorld, entity: Entity, component: $T) {
// 	ecs_register_component(world, T)
// 	if entity in world.components[T].entity_indices {
// 		return
// 	}
// 	component_map := &world.components[T]
// 	map_insert(&component_map.entity_indices, entity, cast(uint)world.components[T].data.len)
// 	append_elem(cast(^[dynamic]T)world.components[T].data, component)
// }
// 
// ecs_remove_component :: proc(world: ^EcsWorld, entity: Entity, component: $T) {
// 	if entity not_in world.components[T].entity_indices {
// 		return
// 	}
// 	component_map := &world.components[T]
// 	delete_key(&component_map.entity_indices, entity)
// }
