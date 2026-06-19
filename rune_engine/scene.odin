package rune_engine

import "vendor:glfw"
import "base:runtime"
import "core:fmt"
import "core:math/linalg"
import jph "deps/joltc-odin"

import "renderer"

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

current_camera: Scene_Shader_Data
Scene_Shader_Data :: struct #align(16) {
  projection: matrix[4,4]f32,
  view:       matrix[4,4]f32,
  world:      matrix[4,4]f32,
}

begin_scene :: proc(view, projection: matrix[4, 4]f32) {
  current_camera.view = view
  current_camera.projection = projection
}

depth_tex:  renderer.Texture
depth_view: renderer.Texture_View
draw_scene :: proc(self: ^Scene) {
  if depth_view == {} {
    w, h := glfw.GetFramebufferSize(application.window)
    depth_tex = renderer.device_create_texture(application.device, {
      dim = .D2,
      array_count = 1,
      extent = {u32(w), u32(h), 1},
      format = .D32_FLOAT_S8_UINT,
      mip_levels = 1,
      usage = {.Render_Attachment},
    })
    depth_view = renderer.device_create_texture_view(application.device, {
      texture = depth_tex,
      array_layer_count = 1,
      mip_level_count = 1,
      dim = .D2,
    })
  }
  cmd := renderer.device_begin_commands(application.device)
  surface_tex := renderer.surface_get_current_texture(application.surface)
  pass := renderer.command_buffer_begin_render_pass(cmd, {
    color_attachents = {
      {view = surface_tex.view, clear_value = {0.1, 0.1, 0.2, 1.0}, load_action = .Clear}
    },
    depth_stencil_attachment = renderer.Depth_Stencil_Attachment {
      view = depth_view,
      depth_ops = {clear_value = 1.0, load_action = .Clear, store_action = .Store},
    }
  })
	// renderer.render_pass_set_pipeline(pass, application.default_pipeline)
	// world: matrix[4, 4]f32

  // for cam_arch in query(self, has(CameraComponent), has(TransformComponent)) {
  //   cam_table := get_table(self, cam_arch, CameraComponent)
  //   cam_trf_table := get_table(self, cam_arch, TransformComponent)
  //   cam := cam_table[0]
  //   cam_trf := cam_trf_table[0]
  //   proj := linalg.matrix4_perspective(math.to_radians(cam.fov), cam.aspect, cam.near, cam.far)
  //   fw := linalg.mul(cam_trf.rotation, [3]f32{0, 0, 1})
  //   view := linalg.matrix4_look_at(cam_trf.position, cam_trf.position - fw, [3]f32{0, 1, 0})
  //   set_shader_mat4(application.default_shader, "scene.u_proj", &proj)
  //   set_shader_mat4(application.default_shader, "scene.u_view", &view)
    for mesh_arch in query(self, has(TransformComponent), has(MeshRendererComponent)) {
      mesh_table := get_table(self, mesh_arch, MeshRendererComponent)
      mesh_trf_table := get_table(self, mesh_arch, TransformComponent)
      for e2, i in mesh_arch.entities {
        mesh_trf := mesh_trf_table[i]
        current_camera.world = linalg.matrix4_from_trs(mesh_trf.position, mesh_trf.rotation, mesh_trf.scale)
        // set_shader_mat4(application.default_shader, "scene.u_world", &world)
        draw_mesh(pass, mesh_table[i].mesh, linalg.MATRIX4F32_IDENTITY)
      }
    }
  // }
  renderer.command_buffer_end_render_pass(cmd)
  renderer.device_submit_commands(application.device, cmd)
  renderer.surface_present(application.surface)
}
