package sandbox

import "../rune_engine/"

import "vendor:stb/image"

import "core:math"
import "core:math/linalg"

vert_src := #load("assets/shaders/default.vert.spv", []u32)
frag_src := #load("assets/shaders/default.frag.spv", []u32)

Input_Map :: enum {
  W, A, S, D,
  Space,
  Shift,
}

sandbox: struct {
  e:         rune_engine.Entity,
  input_dir: [3]f32,
  cam_rot:   [2]f32,
  monky:     rune_engine.Model,
  scene:     ^rune_engine.Scene,
  input_map: [Input_Map]bool,
}

main :: proc() {
  rune_engine.init({
    init_proc = game_layer_on_attach,
    update_proc = game_layer_on_update,
    quit_proc = game_layer_on_detach,
    event_proc = proc(ev: rune_engine.Event) {
      #partial switch ev in ev {
        case (rune_engine.Key_Event):
          #partial switch ev.key {
          case .Escape: rune_engine.close()
          case .W: sandbox.input_map[.W] = ev.action != .Release
          case .S: sandbox.input_map[.S] = ev.action != .Release
          case .A: sandbox.input_map[.A] = ev.action != .Release
          case .D: sandbox.input_map[.D] = ev.action != .Release
          case .Space: sandbox.input_map[.Space] = ev.action != .Release
          case .LeftShift: sandbox.input_map[.Shift] = ev.action != .Release
          }
          sandbox.input_dir = {}
          if sandbox.input_map[.W] do sandbox.input_dir.z += 1.0
          if sandbox.input_map[.S] do sandbox.input_dir.z -= 1.0
          if sandbox.input_map[.A] do sandbox.input_dir.x += 1.0
          if sandbox.input_map[.D] do sandbox.input_dir.x -= 1.0
          if sandbox.input_map[.Space] do sandbox.input_dir.y += 1.0
          if sandbox.input_map[.Shift] do sandbox.input_dir.y -= 1.0
        case (rune_engine.Mouse_Pos_Event):
          sandbox.cam_rot -= ev.delta * 0.1
          sandbox.cam_rot.y = math.clamp(sandbox.cam_rot.y, -90, 90)
      }
    },
    window = {
      "Rune Engine Demo",
      1280, 720,
    },
    rendering_backend = .Vulkan,
  })
  defer rune_engine.terminate()

  rune_engine.run()
}

game_layer_on_attach :: proc() {
  p := rune_engine.create_project("Test", "/home/jdw/dev/rune-engine/sandbox")

  sandbox.scene = rune_engine.scene_create("New Scene")
  rune_engine.set_cursor_state(.LockedAndHidden)

  w, h: i32
  data := image.load("assets/textures/doodoo.png", &w, &h, nil, 4)
  tex := rune_engine.create_texture({
    format = .RGBA8_UNORM,
    extent = { u32(w), u32(h), 1 },
    array_count = 1,
    mip_levels = 1,
    type = .D2,
    usage = {.Texture_Binding},
  })
  rune_engine.texture_set_pixels(tex, data, {}, {u32(w), u32(h), 1})

  sandbox.monky = rune_engine.load_model_gltf("assets/models/moky.glb")
  sandbox.monky.meshes[0].material = rune_engine.create_material({
    vertex_shader = {code_type = .Spirv, code = vert_src},
    fragment_shader = {code_type = .Spirv, code = frag_src},
    textures = {tex},
  })

  sandbox.e = rune_engine.create_entity(sandbox.scene)
  e2 := rune_engine.create_entity(sandbox.scene)
  e3 := rune_engine.create_entity(sandbox.scene)
  e4 := rune_engine.create_entity(sandbox.scene)
  rune_engine.add_component(
    sandbox.scene,
    sandbox.e,
    rune_engine.TransformComponent {
      {0, 0, 3},
      linalg.quaternion_from_pitch_yaw_roll_f32(0, 0, 0),
      {1, 1, 1},
    },
  )
  rune_engine.add_component(
    sandbox.scene,
    sandbox.e,
    rune_engine.CameraComponent{true, 110, 16.0 / 9.0, 0.1, 100.0},
  )
  rune_engine.add_component(
    sandbox.scene,
    e2,
    rune_engine.TransformComponent{{0, 0, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
  )
  rune_engine.add_component(
    sandbox.scene,
    e2,
    rune_engine.MeshRendererComponent{sandbox.monky.meshes[0]},
  )
  rune_engine.add_component(
    sandbox.scene,
    e3,
    rune_engine.TransformComponent{{0, 3, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
  )
  rune_engine.add_component(
    sandbox.scene,
    e3,
    rune_engine.MeshRendererComponent{sandbox.monky.meshes[0]},
  )
  // rune_engine.add_component(
  //   sandbox.scene,
  //   e3,
  //   rune_engine.RigidBodyComponent {
  //     type = .Dynamic,
  //     is_trigger = false,
  //     shape = rune_engine.SphereShape{radius = 1.0},
  //   },
  // )

  rune_engine.add_component(
    sandbox.scene,
    e4,
    rune_engine.TransformComponent {
      {0, -3, 0},
      linalg.quaternion_from_pitch_yaw_roll_f32(math.to_radians_f32(10), 0, 0),
      {1, 1, 1},
    },
  )
  rune_engine.add_component(
    sandbox.scene,
    e4,
    rune_engine.RigidBodyComponent {
      type = .Static,
      is_trigger = false,
      //shape = rune_engine.BoxShape{extents = {20, 0.3, 20}},
      shape = rune_engine.PlaneShape{normal = {0, 1, 0}},
    },
  )

  rune_engine.start_scene(sandbox.scene)
}

game_layer_on_update :: proc() {
  cam_trf := rune_engine.get_component(sandbox.scene, sandbox.e, rune_engine.TransformComponent)
  cam_trf.rotation = linalg.quaternion_from_pitch_yaw_roll(
    math.to_radians(sandbox.cam_rot.y),
    math.to_radians(sandbox.cam_rot.x),
    0,
  )
  fw := -linalg.mul(cam_trf.rotation, [3]f32{0, 0, 1})
  rg := -linalg.mul(cam_trf.rotation, [3]f32{1, 0, 0})
  speed: f32 = 0.1
  cam_trf.position += (fw * sandbox.input_dir.z + rg * sandbox.input_dir.x) * speed + {0, speed * sandbox.input_dir.y, 0}
  cam := rune_engine.get_component(sandbox.scene, sandbox.e, rune_engine.CameraComponent)

  rune_engine.update_scene(sandbox.scene)
  // view := rune_engine.get_render_target()
  // rune_engine.begin_pass(&{
  //   swapchain = rune_engine.get_swapchain(),
  //   color_attachments = {
  //     {clear_color = {0.1, 0.3, 0.2, 1.0}, format = .BGRA8, load_action = .Clear}
  //   }
  // })
  for cam_arch in rune_engine.query(sandbox.scene, rune_engine.has(rune_engine.CameraComponent), rune_engine.has(rune_engine.TransformComponent)) {
    cam_table := rune_engine.get_table(sandbox.scene, cam_arch, rune_engine.CameraComponent)
    cam_trf_table := rune_engine.get_table(sandbox.scene, cam_arch, rune_engine.TransformComponent)
    cam := cam_table[0]
    cam_trf := cam_trf_table[0]
    proj := linalg.matrix4_perspective(math.to_radians(cam.fov), cam.aspect, cam.near, cam.far)
    fw := linalg.mul(cam_trf.rotation, [3]f32{0, 0, 1})
    view := linalg.matrix4_look_at(cam_trf.position, cam_trf.position - fw, [3]f32{0, 1, 0})
    rune_engine.begin_scene(view, proj)
    rune_engine.draw_scene(sandbox.scene)
  }
  // rune_engine.end_pass()
  // rune_engine.submit()
  // rune_engine.present()
}

game_layer_on_detach :: proc() {
}
