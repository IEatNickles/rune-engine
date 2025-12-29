package rune_engine

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import jph "deps/joltc-odin"

Scene :: struct {
	name:      string,
	ecs_world: ^EcsWorld,
	physics:   struct {
		system:         ^jph.PhysicsSystem,
		body_interface: ^jph.BodyInterface,
		job_system:     ^jph.JobSystem,
		broad_phase:    ^jph.BroadPhaseQuery,
		narrow_phase:   ^jph.NarrowPhaseQuery,
	},
}

BROAD_PHASE_LAYER_MOVING: jph.BroadPhaseLayer : 0
BROAD_PHASE_LAYER_NON_MOVING: jph.BroadPhaseLayer : 1
BROAD_PHASE_LAYER_DEBRIS: jph.BroadPhaseLayer : 2
BROAD_PHASE_LAYER_TRIGGER: jph.BroadPhaseLayer : 3
NUM_BROAD_PHASE_LAYERS :: 4

OBJECT_LAYER_MOVING: jph.ObjectLayer : 0
OBJECT_LAYER_NON_MOVING: jph.ObjectLayer : 1
OBJECT_LAYER_DEBRIS: jph.ObjectLayer : 2
OBJECT_LAYER_TRIGGER: jph.ObjectLayer : 3
NUM_OBJECT_LAYERS :: 4

scene_create :: proc(name: string) -> ^Scene {
	scene := new(Scene)
	scene.name = name
	scene.ecs_world = create_world()

	assert(jph.Init(), "Failed to initialize Jolt")
	jph.TraceFunc(proc "c" (msg: cstring) {
		context = runtime.default_context()
		fmt.println(msg)
	})

	scene.physics.job_system = jph.JobSystemThreadPool_Create(nil)

	object_layer_pair_filter := jph.ObjectLayerPairFilterTable_Create(NUM_OBJECT_LAYERS)
	jph.ObjectLayerPairFilterTable_EnableCollision(
		object_layer_pair_filter,
		OBJECT_LAYER_NON_MOVING,
		OBJECT_LAYER_MOVING,
	)
	jph.ObjectLayerPairFilterTable_EnableCollision(
		object_layer_pair_filter,
		OBJECT_LAYER_NON_MOVING,
		OBJECT_LAYER_DEBRIS,
	)
	jph.ObjectLayerPairFilterTable_EnableCollision(
		object_layer_pair_filter,
		OBJECT_LAYER_MOVING,
		OBJECT_LAYER_MOVING,
	)
	jph.ObjectLayerPairFilterTable_EnableCollision(
		object_layer_pair_filter,
		OBJECT_LAYER_MOVING,
		OBJECT_LAYER_TRIGGER,
	)

	broad_phase_layer_interface := jph.BroadPhaseLayerInterfaceTable_Create(
		NUM_OBJECT_LAYERS,
		NUM_BROAD_PHASE_LAYERS,
	)
	jph.BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(
		broad_phase_layer_interface,
		OBJECT_LAYER_NON_MOVING,
		BROAD_PHASE_LAYER_NON_MOVING,
	)
	jph.BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(
		broad_phase_layer_interface,
		OBJECT_LAYER_MOVING,
		BROAD_PHASE_LAYER_MOVING,
	)
	jph.BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(
		broad_phase_layer_interface,
		OBJECT_LAYER_DEBRIS,
		BROAD_PHASE_LAYER_DEBRIS,
	)
	jph.BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(
		broad_phase_layer_interface,
		OBJECT_LAYER_TRIGGER,
		BROAD_PHASE_LAYER_TRIGGER,
	)

	object_vs_broad_phase_layer_filter := jph.ObjectVsBroadPhaseLayerFilterTable_Create(
		broad_phase_layer_interface,
		NUM_BROAD_PHASE_LAYERS,
		object_layer_pair_filter,
		NUM_OBJECT_LAYERS,
	)

	settings := jph.PhysicsSystemSettings {
		maxBodies                     = 10240,
		maxBodyPairs                  = 65536,
		maxContactConstraints         = 10240,
		broadPhaseLayerInterface      = broad_phase_layer_interface,
		objectLayerPairFilter         = object_layer_pair_filter,
		objectVsBroadPhaseLayerFilter = object_vs_broad_phase_layer_filter,
	}
	scene.physics.system = jph.PhysicsSystem_Create(&settings)
	scene.physics.body_interface = jph.PhysicsSystem_GetBodyInterface(scene.physics.system)
	scene.physics.broad_phase = jph.PhysicsSystem_GetBroadPhaseQuery(scene.physics.system)
	scene.physics.narrow_phase = jph.PhysicsSystem_GetNarrowPhaseQuery(scene.physics.system)

	return scene
}

start_scene :: proc(self: ^Scene) {
	for arch in query(self, has(RigidBodyComponent), has(TransformComponent)) {
		transform_table := get_table(self, arch, TransformComponent)
		rigidbody_table := get_table(self, arch, RigidBodyComponent)
		for e, i in arch.entities {
			tr := transform_table[i]
			rb := &rigidbody_table[i]
			pos := tr.position

			shape: ^jph.Shape = nil
			switch &s in rb.shape {
			case BoxShape:
				pos += s.offset
				ext := s.extents
				shape = cast(^jph.Shape)jph.BoxShape_Create(&ext, jph.DEFAULT_CONVEX_RADIUS)
			case SphereShape:
				pos += s.offset
				shape = cast(^jph.Shape)jph.SphereShape_Create(s.radius)
			case CapsuleShape:
				pos += s.offset
				shape = cast(^jph.Shape)jph.CapsuleShape_Create(s.height * 0.5, s.radius)
			case PlaneShape:
				plane := jph.Plane{s.normal, linalg.dot(s.offset, s.normal)}
				shape = cast(^jph.Shape)jph.PlaneShape_Create(&plane, nil, 1000)
			case TriangleShape:
				shape =
				cast(^jph.Shape)jph.TriangleShape_Create(
					&s.a,
					&s.b,
					&s.c,
					jph.DEFAULT_CONVEX_RADIUS,
				)
			case MeshShape:
				shape =
				cast(^jph.Shape)jph.MeshShapeSettings_Create(
					raw_data(s.triangles),
					u32(len(s.triangles)),
				)
			case ConvexHullShape:
				shape =
				cast(^jph.Shape)jph.ConvexHullShapeSettings_Create(
					raw_data(s.points),
					u32(len(s.points)),
					jph.DEFAULT_CONVEX_RADIUS,
				)
			}
			if tr.scale != {1, 1, 1} {
				shape = cast(^jph.Shape)jph.ScaledShape_Create(shape, &tr.scale)
			}
			motion_type: jph.MotionType
			layer: jph.ObjectLayer
			is_trigger: bool
			switch rb.type {
			case .Static:
				motion_type = .Static
				layer = OBJECT_LAYER_NON_MOVING
			case .Dynamic:
				motion_type = .Dynamic
				layer = OBJECT_LAYER_MOVING
			case .Kinematic:
				motion_type = .Kinematic
				layer = OBJECT_LAYER_NON_MOVING
			}
			if rb.is_trigger {
				layer = OBJECT_LAYER_TRIGGER
				is_trigger = true
			}
			settings := jph.BodyCreationSettings_Create3(
				shape,
				&pos,
				&tr.rotation,
				motion_type,
				layer,
			)
			jph.BodyCreationSettings_SetIsSensor(settings, is_trigger)

			rb.body_id = jph.BodyInterface_CreateAndAddBody(
				self.physics.body_interface,
				settings,
				.Activate,
			)
		}
	}

	jph.PhysicsSystem_OptimizeBroadPhase(self.physics.system)
}

update_scene :: proc(self: ^Scene) {
	jph.PhysicsSystem_Update(self.physics.system, 0.0167, 1, self.physics.job_system)
	for arch in query(self, has(RigidBodyComponent), has(TransformComponent)) {
		transform_table := get_table(self, arch, TransformComponent)
		rigidbody_table := get_table(self, arch, RigidBodyComponent)
		for e, i in arch.entities {
			tr := &transform_table[i]
			rb := rigidbody_table[i]

			jph.BodyInterface_GetPositionAndRotation(
				self.physics.body_interface,
				rb.body_id,
				&tr.position,
				&tr.rotation,
			)
		}
	}
}

draw_scene :: proc(self: ^Scene) {
	bind_shader(&application.default_shader)
	world, view, proj: matrix[4, 4]f32
	// for cam_arch in query(self, has(TransformComponent), has(CameraComponent)) {
	// 	cam_table := get_table(self, cam_arch, CameraComponent)
	// 	cam_trf_table := get_table(self, cam_arch, TransformComponent)
	// 	for e, i in cam_arch.entities {
	// 		transform := &cam_trf_table[i]
	// 		view = linalg.inverse(
	// 			linalg.matrix4_translate(transform.position) *
	// 			linalg.matrix4_from_quaternion(transform.rotation),
	// 		)
	// 		proj = linalg.matrix4_perspective_f32(
	// 			math.to_radians_f32(cam_table[i].fov),
	// 			cam_table[i].aspect,
	// 			cam_table[i].near,
	// 			cam_table[i].far,
	// 		)

	// 		set_shader_mat4(&application.default_shader, "u_view", &view)
	// 		set_shader_mat4(&application.default_shader, "u_proj", &proj)

	for mesh_arch in query(self, has(TransformComponent), has(MeshRendererComponent)) {
		mesh_table := get_table(self, mesh_arch, MeshRendererComponent)
		mesh_trf_table := get_table(self, mesh_arch, TransformComponent)
		for e2, i in mesh_arch.entities {
			mesh_trf := mesh_trf_table[i]
			world = linalg.matrix4_from_trs(mesh_trf.position, mesh_trf.rotation, mesh_trf.scale)
			set_shader_mat4(&application.default_shader, "u_world", &world)
			draw_mesh(mesh_table[i].mesh)
		}
	}
	// 	}
	// }
}
