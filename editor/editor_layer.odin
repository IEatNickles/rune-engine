package editor

import "core:encoding/json"
import "core:time"
import "core:log"
import "core:os"
import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:mem"
import "core:strings"

import "../rune_engine/"
// import "../rune_engine/rendering/"

import imgui "deps/odin-imgui"
import "deps/odin-imgui/imgui_impl_glfw"
import "deps/odin-imgui/imgui_impl_opengl3"

import gl "vendor:OpenGL"
import "vendor:glfw"
import "vendor:stb/image"

ENABLE_IMGUI_VIEWPORTS :: true

Log :: struct {
  level:   runtime.Logger_Level,
  time:    time.Time,
  message: string,
}

Texture_Asset :: struct {
  mip_level: int,
}

Model_Asset :: struct {
  mip_level: int,
}

Shader_Asset :: struct {
}

Material_Asset :: struct {
}

Asset :: struct {
  path:    string,
  type: union {
    Texture_Asset,
    Model_Asset,
    Shader_Asset,
    Material_Asset,
  },
}

Editor_Entity :: union {
  rune_engine.Entity,
  Asset,
}

editor: struct {
  active_scene:           ^rune_engine.Scene,
  viewport_aspect:        f32,
  show_imgui_demo_window: bool,
  fbt:                    rendering.Texture,
  depth_tex:              rendering.Texture,
  camera_pos:             [3]f32,
  camera_rot:             [2]f32,
  start_camera_rot:       [2]f32,
  selected_entity:        Editor_Entity,
  editing_rotation:       bool,
  current_euler_angles:   [3]f32,
  logs:                   [dynamic]Log,
  logger:                 log.Logger,
  project_directory:      string,

  input_dir: [3]f32,
}

console_logger_proc :: proc(
  data: rawptr,
  level: runtime.Logger_Level,
  text: string,
  options: runtime.Logger_Options,
  location := #caller_location) {
  // data := cast(^Editor_Layer)data
  append(&editor.logs, Log{level, time.now(), strings.clone(text)})
}

editor_layer_on_attach :: proc() {
  import_asset("./example_project/assets/doodoo.png", "doodoo", .Texture)

  window := rune_engine.get_window().handle

  imgui.CHECKVERSION()
  imgui.create_context()
  io := imgui.get_io()
  io.config_flags += {.Nav_Enable_Keyboard, .Nav_Enable_Gamepad}
  io.config_flags += {.Docking_Enable}

  when ENABLE_IMGUI_VIEWPORTS {
    io.config_flags += {.Viewports_Enable}
    style := imgui.get_style()
    style.window_rounding = 0
    style.colors[imgui.Col.Window_Bg].w = 1
  }

  imgui_style_colors_default()

  imgui_impl_glfw.init_for_open_gl(window, true)
  imgui_impl_opengl3.init("#version 410")

  w, h: i32
  data := image.load("assets/textures/doodoo.png", &w, &h, nil, 4)
  tex := rune_engine.create_texture(&{
    format = .RGBA8,
    size = { w, h, 1 },
    data = data,
    min_filter = .Linear,
    mag_filter = .Linear,
    wrap_mode_u = .Repeat,
    wrap_mode_v = .Repeat,
    wrap_mode_w = .Repeat,
  })
  rune_engine.bind_texture(tex)

  editor.active_scene = rune_engine.scene_create("Fart")
  monky := rune_engine.load_model_gltf("assets/models/moky.glb")
  e := rune_engine.create_entity(editor.active_scene)
  e2 := rune_engine.create_entity(editor.active_scene)
  e3 := rune_engine.create_entity(editor.active_scene)
  e4 := rune_engine.create_entity(editor.active_scene)
  rune_engine.add_component(
    editor.active_scene,
    e,
    rune_engine.TransformComponent {
      {0, 0, 1},
      linalg.quaternion_from_pitch_yaw_roll_f32(0, 0, 0),
      {1, 1, 1},
    },
  )
  rune_engine.add_component(
    editor.active_scene,
    e,
    rune_engine.CameraComponent{true, 110, 16.0 / 9.0, 0.1, 100.0},
  )
  rune_engine.add_component(
    editor.active_scene,
    e2,
    rune_engine.TransformComponent{{0, 0, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
  )
  rune_engine.add_component(
    editor.active_scene,
    e2,
    rune_engine.MeshRendererComponent{monky.meshes[0]},
  )
  rune_engine.add_component(
    editor.active_scene,
    e3,
    rune_engine.TransformComponent{{0, 3, 0}, linalg.QUATERNIONF32_IDENTITY, {1, 1, 1}},
  )
  rune_engine.add_component(
    editor.active_scene,
    e3,
    rune_engine.MeshRendererComponent{monky.meshes[0]},
  )
  rune_engine.add_component(
    editor.active_scene,
    e3,
    rune_engine.RigidBodyComponent {
      type = .Dynamic,
      is_trigger = false,
      shape = rune_engine.SphereShape{radius = 1.0},
    },
  )

  rune_engine.add_component(
    editor.active_scene,
    e4,
    rune_engine.TransformComponent {
      {0, -3, 0},
      linalg.quaternion_from_pitch_yaw_roll_f32(math.to_radians_f32(10), 0, 0),
      {1, 1, 1},
    },
  )
  rune_engine.add_component(
    editor.active_scene,
    e4,
    rune_engine.RigidBodyComponent {
      type = .Static,
      is_trigger = false,
      //shape = rune_engine.BoxShape{extents = {20, 0.3, 20}},
      shape = rune_engine.PlaneShape{normal = {0, 1, 0}},
    },
  )

  editor.viewport_aspect = 16.0 / 9.0
  editor.show_imgui_demo_window = false

  editor.fbt = rune_engine.create_texture(&{
    format = .RGBA8,
    size = { 1920, 1080, 1, },
    min_filter = .Linear,
    mag_filter = .Linear,
    wrap_mode_u = .Clamp_To_Edge,
    wrap_mode_v = .Clamp_To_Edge,
  })
  editor.depth_tex = rune_engine.create_texture(&{
    format = .Depth,
    size = { 1920, 1080, 1, },
    min_filter = .Linear,
    mag_filter = .Linear,
    wrap_mode_u = .Clamp_To_Edge,
    wrap_mode_v = .Clamp_To_Edge,
  })
  editor.camera_pos = {0, 0, 3}

  file_err: os.Error
  if file_err != nil {
    fmt.eprintln("Failed to open log file")
  }

  editor.logger = log.Logger{console_logger_proc, nil, .Debug, log.Default_Console_Logger_Opts}
  editor.project_directory = "./example_project/"
  populate_asset_database(editor.project_directory)

  filesytem_browser_init(editor.project_directory)
}

editor_layer_on_update :: proc() {
  context.logger = editor.logger
  imgui_impl_opengl3.new_frame()
  imgui_impl_glfw.new_frame()
  imgui.new_frame()

  // if rune_engine.key_pressed(.Escape) {
  //   rune_engine.close()
  // }

  if imgui.begin_main_menu_bar() {
    if imgui.begin_menu("File") {
      imgui.menu_item_bool_ptr("Show ImGUI Demo", nil, &editor.show_imgui_demo_window)
      if imgui.menu_item("Exit", "Ctrl-Q") {
        // rune_engine.transition_layer(
        //   Editor_Layer,
        //   LauncherLayer,
        //   launcher_on_attach,
        //   launcher_on_update,
        //   launcher_on_detach,
        // )
      }
      imgui.end_menu()
    }
    imgui.end_main_menu_bar()
  }

  imgui.dock_space_over_viewport()

  if editor.show_imgui_demo_window do imgui.show_demo_window()

  if imgui.begin("Viewport") {
    region := imgui.get_content_region_avail()
    size := imgui.Vec2{region.x, region.x / editor.viewport_aspect}
    if region.y < size.y {
      size.y = region.y
      size.x = size.y * editor.viewport_aspect
    }
    imgui.set_cursor_pos_x(
      region.x / 2 - size.x / 2 + (imgui.get_style().display_window_padding.x) / 2,
    )
    imgui.set_cursor_pos_y(
      region.y / 2 -
      size.y / 2 +
      (imgui.get_style().window_padding.y + imgui.get_style().display_window_padding.y),
    )
    rune_engine.begin_pass(&{
      color_attachments = { { format = .RGBA8, texture = editor.fbt, load_action = .Clear, clear_color = {0.2, 0.5, 0.8, 1} } },
      depth_attachment = { format = .Depth, texture = editor.depth_tex, load_action = .Clear, clear_value = 1.0, store_action = .Store }
    })
    gl.Viewport(0, 0, 1920, 1080)
    rune_engine.begin_scene(
      linalg.inverse(
        linalg.matrix4_from_trs_f32(
          editor.camera_pos,
          linalg.quaternion_from_euler_angles_f32(
            editor.camera_rot.x,
            editor.camera_rot.y,
            0,
            .YXZ,
          ),
          [3]f32{1, 1, 1},
        ),
      ),
      linalg.matrix4_perspective_f32(math.to_radians_f32(100), 16.0 / 9.0, 0.1, 100.0),
    )
    rune_engine.draw_scene(editor.active_scene)
    rune_engine.end_pass()
    // rune_engine.bind_framebuffer({})
    imgui.image({nil, rune_engine.get_texture_descriptor(editor.fbt)}, size, imgui.Vec2{0, 1}, imgui.Vec2{1, 0})
    if imgui.is_mouse_dragging(.Right) {
      rune_engine.set_cursor_state(.LockedAndHidden)
      drag := imgui.get_mouse_drag_delta(.Right)
      editor.camera_rot = editor.start_camera_rot - drag * 0.001
      r := linalg.quaternion_from_euler_angles_f32(
        editor.camera_rot.x,
        editor.camera_rot.y,
        0,
        .YXZ,
      )
      fw := -linalg.quaternion128_mul_vector3(r, [3]f32{0, 0, 1})
      rg := -linalg.quaternion128_mul_vector3(r, [3]f32{1, 0, 0})
      speed: f32 = 0.1
      editor.camera_pos +=
          (fw * editor.input_dir.z +
           rg * editor.input_dir.x +
           {0, editor.input_dir.y, 0}) * speed
    } else {
      rune_engine.set_cursor_state(.Visible)
      editor.start_camera_rot = editor.camera_rot
    }
  }
  imgui.end()

  // game: if imgui.begin("Game") {
  //   found_main_camera: bool
  //   view, proj: matrix[4, 4]f32
  //   look_for_main_camera: for a in rune_engine.query(
  //     editor.active_scene,
  //     rune_engine.has(rune_engine.CameraComponent),
  //   ) {
  //     cam_table := rune_engine.get_table(editor.active_scene, a, rune_engine.CameraComponent)
  //     trf_table := rune_engine.get_table(
  //       editor.active_scene,
  //       a,
  //       rune_engine.TransformComponent,
  //     )
  //     for e, i in a.entities {
  //       c := cam_table[i]
  //       if c.main {
  //         t := trf_table[i]
  //         view = linalg.inverse(
  //           linalg.matrix4_from_trs_f32(t.position, t.rotation, {1, 1, 1}),
  //         )
  //         proj = linalg.matrix4_perspective_f32(
  //           math.to_radians(c.fov),
  //           c.aspect,
  //           c.near,
  //           c.far,
  //         )
  //         found_main_camera = true
  //         break look_for_main_camera
  //       }
  //     }
  //   }
  //
  //   if !found_main_camera {
  //     imgui.text("No main camera")
  //     break game
  //   }
  //
  //   region := imgui.get_content_region_avail()
  //   size := imgui.Vec2{region.x, region.x / editor.viewport_aspect}
  //   if region.y < size.y {
  //     size.y = region.y
  //     size.x = size.y * editor.viewport_aspect
  //   }
  //   imgui.set_cursor_pos_x(
  //     region.x / 2 - size.x / 2 + (imgui.get_style().display_window_padding.x) / 2,
  //   )
  //   imgui.set_cursor_pos_y(
  //     region.y / 2 -
  //     size.y / 2 +
  //     (imgui.get_style().window_padding.y + imgui.get_style().display_window_padding.y),
  //   )
  //   rune_engine.bind_framebuffer(editor.fbo)
  //   gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
  //   gl.Viewport(0, 0, 1920, 1080)
  //   rune_engine.begin_scene(view, proj)
  //   rune_engine.draw_scene(editor.active_scene)
  //   rune_engine.bind_framebuffer({})
  //   imgui.image({nil, u64(editor.fbt.idx)}, size, imgui.Vec2{0, 1}, imgui.Vec2{1, 0})
  // }
  // imgui.end()

  imgui.begin("Scene")
  if editor.active_scene != nil {
    if imgui.tree_node_ex(
      cast(cstring)raw_data(editor.active_scene.name),
      {.Framed, .Default_Open, .Span_Full_Width},
    ) {
      for e in editor.active_scene.ecs_world.entity_index {
        if e in editor.active_scene.ecs_world.component_info do continue
        sb, err := strings.builder_make_none()
        fmt.sbprint(&sb, cast(u64)e)
        flags := imgui.Tree_Node_Flags{.Leaf, .Span_Full_Width}
        if e == editor.selected_entity do flags += {.Selected}
        if imgui.tree_node_ex(cast(cstring)raw_data(strings.to_string(sb)), flags) do imgui.tree_pop()
        if imgui.is_item_clicked(.Left) {
          editor.selected_entity = e
        }
      }
      imgui.tree_pop()
    }
  }
  imgui.end()

  filesytem_browser()

  imgui.begin("Inspector")
  if asset, ok := editor.selected_entity.(Asset); ok {
    @(static) selected: int
    @(static) types := []string {
      "R8",
      "RG8",
      "RGB8",
      "RGBA8",
      "R16",
      "RG16",
      "RGB16",
      "RGBA16",
    }
    imgui.text("%s", cstring(raw_data(asset.path)))
    if imgui.begin_combo("type", cstring(raw_data(types[selected]))) {
      for t, i in types {
        if imgui.menu_item(cstring(raw_data(t))) do selected = i
      }
      imgui.end_combo()
    }
  }
  if e, ok := editor.selected_entity.(rune_engine.Entity); ok {
    info := editor.active_scene.ecs_world.entity_index[e]
    arch := info.archetype
    for cid, component_type in arch.component_types {
      component_data := arch.tables[cid][info.row *
      component_type.size:info.row * component_type.size +
      component_type.size]
      named_type := component_type.variant.(runtime.Type_Info_Named)
      str := named_type.base.variant.(runtime.Type_Info_Struct)
      if imgui.tree_node(cstring(raw_data(named_type.name))) {
        for i in 0 ..< str.field_count {
          field_type_info := str.types[i]
          field_name := cstring(raw_data(str.names[i]))
          offset := cast(int)str.offsets[i]
          data := raw_data(component_data[offset:offset + field_type_info.size])
          #partial switch var in field_type_info.variant {
          case runtime.Type_Info_Boolean:
            imgui.checkbox(field_name, cast(^bool)data)
          case runtime.Type_Info_Float:
            imgui.drag_float(field_name, cast(^f32)data)
          case runtime.Type_Info_Integer:
            // NOTE: unsigned integers might not work.
            imgui.drag_int(field_name, cast(^i32)data)
          case runtime.Type_Info_Quaternion:
            imgui.drag_float3(field_name, &editor.current_euler_angles)
            if imgui.is_item_active() {
              euler := linalg.to_radians(editor.current_euler_angles)
              (cast(^quaternion128)data)^ = linalg.quaternion_from_euler_angles(
                euler.x,
                euler.y,
                euler.z,
                .XYZ,
              )
            } else if imgui.is_item_deactivated() {
              x, y, z := linalg.euler_angles_from_quaternion(
                (cast(^quaternion128)data)^,
                .XYZ,
              )
              editor.current_euler_angles = linalg.to_degrees([3]f32{x, y, z})
            }
          case runtime.Type_Info_Array:
            #partial switch type in var.elem.variant {
            case runtime.Type_Info_Float:
              if var.count <= 4 {
                if var.count == 2 do imgui.drag_float2(field_name, cast(^[2]f32)data)
                else if var.count == 3 do imgui.drag_float3(field_name, cast(^[3]f32)data)
                else if var.count == 4 do imgui.drag_float4(field_name, cast(^[4]f32)data)
              } else {
                if imgui.tree_node(field_name) {
                  for i in 0 ..< var.count {
                    imgui.drag_float(
                      fmt.caprint("##", i),
                      mem.ptr_offset(cast([^]f32)data, i),
                    )
                  }
                  imgui.tree_pop()
                }
              }
            case runtime.Type_Info_Integer:
              // NOTE: unsigned integers might not work.
              if var.count <= 4 {
                if var.count == 2 do imgui.drag_int2(field_name, cast(^[2]i32)data)
                else if var.count == 3 do imgui.drag_int3(field_name, cast(^[3]i32)data)
                else if var.count == 4 do imgui.drag_int4(field_name, cast(^[4]i32)data)
              } else {
                if imgui.tree_node(field_name) {
                  for i in 0 ..< var.count {
                    imgui.drag_int(
                      fmt.caprint("##", i),
                      mem.ptr_offset(cast([^]i32)data, i),
                    )
                  }
                  imgui.tree_pop()
                }
              }
            }
          }
        }
        imgui.tree_pop()
      }
    }

    if imgui.button("Add Component") {
      imgui.open_popup("ADD_COMPONENT")
    }
    if imgui.begin_popup("ADD_COMPONENT") {
      for cid, ctype in editor.active_scene.ecs_world.component_info {
        named := ctype.type_info.variant.(runtime.Type_Info_Named)
        imgui.menu_item(cstring(raw_data(named.name)))
      }
      imgui.end_popup()
    }
  }
  imgui.end()

  imgui.begin("Console")
  if imgui.button("debug") {
    log.debug("huh")
  }
  imgui.same_line()
  if imgui.button("info") {
    log.info("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
  }
  imgui.same_line()
  if imgui.button("warn") {
    log.warn("huh")
  }
  imgui.same_line()
  if imgui.button("error") {
    log.error("huh")
  }
  imgui.same_line()
  if imgui.button("fatal") {
    log.fatal("huh")
  }

  if imgui.button("Filter") {
    imgui.open_popup("log_filter")
  }

  if imgui.begin_popup("log_filter") {
    imgui.menu_item("debug")
    imgui.menu_item("info")
    imgui.menu_item("warn")
    imgui.menu_item_bool_ptr("error", "", nil)
    imgui.end_popup()
  }

  if imgui.begin_table("logs", 1, {.Row_Bg}) {
    #reverse for l in editor.logs {
      imgui.table_next_row()
      imgui.table_next_column()
      col: imgui.Vec4
      switch l.level {
      case .Debug:   col = {0.6, 0.6, 0.6, 1.0}
      case .Info:    col = {1.0, 1.0, 1.0, 1.0}
      case .Warning: col = {0.95, 0.9, 0.2, 1.0}
      case .Error:   col = {0.9, 0.1, 0.1, 1.0}
      case .Fatal:   col = {1.0, 1.0, 1.0, 1.0}
      }
      level_str: string
      switch l.level {
      case .Debug: level_str = "DEBUG"
      case .Info: level_str = "INFO "
      case .Warning: level_str = "WARN "
      case .Error: level_str = "ERROR"
      case .Fatal: level_str = "FATAL"
      }
      if l.level == .Fatal {
        pos := imgui.get_cursor_pos() + imgui.get_window_pos() + imgui.Vec2{0, -imgui.get_scroll_y()-imgui.get_style().cell_padding.y}
        width := imgui.get_content_region_avail().x
        height := imgui.get_font_size() + 2 * imgui.get_style().cell_padding.y
        imgui.draw_list_add_rect_filled(imgui.get_window_draw_list(), pos, pos + imgui.Vec2{width, height}, 0xFF0000FF)
      }
      imgui.text_colored(col, "[%s]", level_str)
      imgui.same_line()
      imgui.text_wrapped("'%s'", l.message)
    }
    imgui.end_table()
  }
  imgui.end()

  imgui.render()
  imgui_impl_opengl3.render_draw_data(imgui.get_draw_data())

  when ENABLE_IMGUI_VIEWPORTS {
    backup_current_window := glfw.GetCurrentContext()
    imgui.update_platform_windows()
    imgui.render_platform_windows_default()
    glfw.MakeContextCurrent(backup_current_window)
  }
}

editor_on_event :: proc(ev: rune_engine.Event) {
  #partial switch ev in ev {
  case (rune_engine.Key_Event):
    #partial switch ev.key {
    case .Escape: rune_engine.close()
    case .W: editor.input_dir.z = 0.0 if ev.action == .Release else 1.0
    case .S: editor.input_dir.z = 0.0 if ev.action == .Release else -1.0
    case .A: editor.input_dir.x = 0.0 if ev.action == .Release else 1.0
    case .D: editor.input_dir.x = 0.0 if ev.action == .Release else -1.0
    case .Space: editor.input_dir.y = 0.0 if ev.action == .Release else 1.0
    case .LeftShift: editor.input_dir.y = 0.0 if ev.action == .Release else -1.0
    }
  }
}

editor_layer_on_detach :: proc() {
  fs_browser_destroy()
  imgui_impl_opengl3.shutdown()
  imgui_impl_glfw.shutdown()
  imgui.destroy_context()
}

Asset_File :: struct {
  version: int,
  name:    string,
  path:    string,
  type:    Asset_Type,
  data: union {
    Texture_Asset,
    Model_Asset,
    Shader_Asset,
    Material_Asset,
  },
}

Asset_Create_Info :: struct {
  version: int,
  path:    string,
  data: Asset_Create_Info_Union,
}

Asset_Create_Info_Union :: union {
  Texture_Asset_Create_Info,
  Shader_Asset_Create_Info,
  Material_Asset_Create_Info,
  Mesh_Asset_Create_Info,
  Model_Asset_Create_Info,
}

Texture_Asset_Create_Info :: struct {
  mipmap_levels: i32
}
Shader_Asset_Create_Info :: struct {
}
Material_Asset_Create_Info :: struct {
}
Mesh_Asset_Create_Info :: struct {
}
Model_Asset_Create_Info :: struct {
}

// asset_infos: [Asset_Type]map[string]Asset_Create_Info

Asset_Import_Error :: union #shared_nil {
  json.Marshal_Error,
  os.Error,
}

ASSET_VERSION := [Asset_Type]int {
  .Texture  = 0,
  .Shader   = 0,
  .Material = 0,
  .Mesh     = 0,
  .Model    = 0,
}

Asset_Database_Error :: union {
  os.Error,
  json.Error,
}

populate_asset_database :: proc(path: string) -> Asset_Database_Error {
  if !os.is_dir(path) do return nil
  dir, _ := os.open(path)
  defer os.close(dir)
  defer free_all(context.temp_allocator)
  it := os.read_directory_iterator_create(dir)
  for i in os.read_directory_iterator(&it) {
    if i.type == .Directory{
      populate_asset_database(i.fullpath)
    } else if i.name == ".assets" {
      data := os.read_entire_file(i.fullpath, context.temp_allocator) or_return
      j := (json.parse(data) or_return).(json.Object)
      if entry, ok := j["textures"].(json.Object);  ok do populate_asset_type(entry, .Texture)
      if entry, ok := j["shaders"].(json.Object);   ok do populate_asset_type(entry, .Shader)
      if entry, ok := j["materials"].(json.Object); ok do populate_asset_type(entry, .Material)
      if entry, ok := j["meshes"].(json.Object);    ok do populate_asset_type(entry, .Mesh)
      if entry, ok := j["models"].(json.Object);    ok do populate_asset_type(entry, .Model)
    }
  }
  return nil
}

populate_asset_type :: proc(entry: json.Object, type: Asset_Type) {
  assets := &asset_infos[type]
  for name, a in entry {
    a := a.(json.Object)
    version, version_ok := a["version"].(json.Float)
    if !version_ok { log.warn("asset entry does not contain a version, skipping"); continue }
    path, path_ok := a["path"].(json.String)
    if !path_ok { log.warn("asset entry does not contain a path, skipping"); continue }
    data_entry, has_data := a["data"]
    data: Asset_Create_Info_Union
    if has_data {
      data_entry, data_ok := data_entry.(json.Object)
      if !data_ok { log.error("asset contains data field, but it is not an object"); return }
      data = parse_asset(data_entry, type)
    }
    assets[name] = { int(version), path, data }
  }
}

parse_asset :: proc(entry: json.Object, type: Asset_Type) -> Asset_Create_Info_Union {
  switch type {
  case .Texture:  return Texture_Asset_Create_Info{}
  case .Shader:   return Shader_Asset_Create_Info{}
  case .Material: return Material_Asset_Create_Info{}
  case .Mesh:     return Mesh_Asset_Create_Info{}
  case .Model:    return Model_Asset_Create_Info{}
  }
  unreachable()
}

import_asset :: proc(path: string, name: string, type: Asset_Type) -> Asset_Import_Error {
  j: json.Object
  asset: Asset_File
  asset.version = ASSET_VERSION[type]
  asset.path = path
  asset.name = name
  asset.type = type
  asset.data = Model_Asset{8}
  str := json.marshal(asset) or_return

  asset_path := strings.concatenate({path, ".asset"})
  file := os.create(asset_path) or_return
  defer os.close(file)
  os.write(file, str)
  return nil
}

Asset_Type :: enum {
  Texture,
  Shader,
  Material,
  Mesh,
  Model,
}

get_asset_type :: proc(extension: string) -> Asset_Type {
  switch extension {
  case ".png", ".jpg", ".jpeg", ".bmp", ".tga": return .Texture
  case ".obj", ".glb", ".gltf": return .Model
  case ".glsl", ".hlsl", ".spv", ".msl": return .Shader
  case ".mtl": return .Material
  case ".mesh": return .Mesh
  }
  return .Mesh
}

create_asset_from_file :: proc(path: string) -> (res: Asset, ok: bool) #optional_ok {
  if !os.is_file(path) do return
  info, err := os.stat(path, context.temp_allocator)
  if err != nil do return
  res.path = path
  switch os.ext(path) {
  case ".png", ".jpg", ".jpeg", ".bmp", ".tga":
    res.type = Texture_Asset{}
  case ".obj", ".glb", ".gltf":
    res.type = Model_Asset{}
  case ".glsl", ".hlsl", ".msl":
    res.type = Shader_Asset{}
  case ".mtl":
    res.type = Material_Asset{}
  }
  ok = true
  return
}

imgui_style_colors_default :: proc() {
  imgui.get_style().window_menu_button_position = .Right
  imgui.get_style().alpha = 1.0
  imgui.get_style().disabled_alpha = 0.6
  imgui.get_style().window_padding = {8, 8}
  imgui.get_style().window_rounding = 0
  imgui.get_style().window_border_size = 1
  imgui.get_style().window_border_hover_padding = 4
  imgui.get_style().window_min_size = {1, 1}
  imgui.get_style().window_title_align = {0, 0.5}
  imgui.get_style().window_menu_button_position = .Right
  imgui.get_style().child_rounding = 0
  imgui.get_style().child_border_size = 1
  imgui.get_style().popup_rounding = 0
  imgui.get_style().popup_border_size = 1
  imgui.get_style().frame_padding = {4, 3}
  imgui.get_style().frame_rounding = 0
  imgui.get_style().frame_border_size = 0
  imgui.get_style().item_spacing = {8, 4}
  imgui.get_style().item_inner_spacing = {4, 4}
  imgui.get_style().cell_padding = {4, 2}
  imgui.get_style().touch_extra_padding = {0, 0}
  imgui.get_style().indent_spacing = 21
  imgui.get_style().columns_min_spacing = 0
  imgui.get_style().scrollbar_size = 14
  imgui.get_style().scrollbar_rounding = 8
  imgui.get_style().grab_min_size = 12
  imgui.get_style().grab_rounding = 0
  imgui.get_style().log_slider_deadzone = 4
  imgui.get_style().image_border_size = 0
  imgui.get_style().tab_rounding = 4
  imgui.get_style().tab_border_size = 0
  imgui.get_style().tab_close_button_min_width_selected = -1
  imgui.get_style().tab_close_button_min_width_unselected = 0
  imgui.get_style().tab_bar_border_size = 1
  imgui.get_style().tab_bar_overline_size = 0
  imgui.get_style().table_angled_headers_angle = 35
  imgui.get_style().table_angled_headers_text_align = {0.5, 0}
  imgui.get_style().color_button_position = .Right
  imgui.get_style().button_text_align = {0.5, 0.5}
  imgui.get_style().selectable_text_align = {0, 0}
  imgui.get_style().separator_text_border_size = 3
  imgui.get_style().separator_text_align = {0, 0.5}
  imgui.get_style().separator_text_padding = {20, 0}
  imgui.get_style().display_window_padding = {19, 19}
  imgui.get_style().display_safe_area_padding = {3, 3}
  imgui.get_style().docking_separator_size = 2
  imgui.get_style().mouse_cursor_scale = 1
  imgui.get_style().anti_aliased_lines = true
  imgui.get_style().anti_aliased_lines_use_tex = true
  imgui.get_style().anti_aliased_fill = true
  imgui.get_style().curve_tessellation_tol = 1.25
  imgui.get_style().circle_tessellation_max_error = 0.3
  imgui.get_style().hover_stationary_delay = 0.5
  imgui.get_style().hover_delay_short = 0.25
  imgui.get_style().hover_delay_normal = 0.5
  imgui.get_style().hover_flags_for_tooltip_mouse = {.Delay_Short, .Stationary}
  imgui.get_style().hover_flags_for_tooltip_nav = {.Delay_Normal, .No_Shared_Delay}
  imgui.get_style().tree_lines_rounding = 0
  imgui.get_style().tree_lines_flags = {.Draw_Lines_To_Nodes}
  imgui.get_style().tree_lines_size = 2

  colors := &imgui.get_style().colors
  colors[imgui.Col.Text] = imgui.Vec4{1.00, 1.00, 1.00, 1.00}
  colors[imgui.Col.Text_Disabled] = imgui.Vec4{0.50, 0.50, 0.50, 1.00}
  colors[imgui.Col.Window_Bg] = imgui.Vec4{0.09, 0.15, 0.21, 1.00}
  colors[imgui.Col.Child_Bg] = imgui.Vec4{0.00, 0.00, 0.00, 0.00}
  colors[imgui.Col.Popup_Bg] = imgui.Vec4{0.16, 0.16, 0.28, 0.94}
  colors[imgui.Col.Border] = imgui.Vec4{0.43, 0.43, 0.50, 0.50}
  colors[imgui.Col.Border_Shadow] = imgui.Vec4{0.00, 0.00, 0.00, 0.00}
  colors[imgui.Col.Frame_Bg] = imgui.Vec4{0.39, 0.43, 0.49, 0.54}
  colors[imgui.Col.Frame_Bg_Hovered] = imgui.Vec4{0.64, 0.80, 0.99, 0.40}
  colors[imgui.Col.Frame_Bg_Active] = imgui.Vec4{0.86, 0.92, 1.00, 0.67}
  colors[imgui.Col.Title_Bg] = imgui.Vec4{0.18, 0.27, 0.40, 1.00}
  colors[imgui.Col.Title_Bg_Active] = imgui.Vec4{0.16, 0.29, 0.48, 1.00}
  colors[imgui.Col.Title_Bg_Collapsed] = imgui.Vec4{0.00, 0.00, 0.00, 0.51}
  colors[imgui.Col.Menu_Bar_Bg] = imgui.Vec4{0.19, 0.40, 0.60, 1.00}
  colors[imgui.Col.Scrollbar_Bg] = imgui.Vec4{0.04, 0.08, 0.10, 0.53}
  colors[imgui.Col.Scrollbar_Grab] = imgui.Vec4{0.31, 0.31, 0.31, 1.00}
  colors[imgui.Col.Scrollbar_Grab_Hovered] = imgui.Vec4{0.41, 0.41, 0.41, 1.00}
  colors[imgui.Col.Scrollbar_Grab_Active] = imgui.Vec4{0.51, 0.51, 0.51, 1.00}
  colors[imgui.Col.Check_Mark] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
  colors[imgui.Col.Slider_Grab] = imgui.Vec4{0.24, 0.52, 0.88, 1.00}
  colors[imgui.Col.Slider_Grab_Active] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
  colors[imgui.Col.Button] = imgui.Vec4{0.59, 0.61, 0.64, 0.40}
  colors[imgui.Col.Button_Hovered] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
  colors[imgui.Col.Button_Active] = imgui.Vec4{0.06, 0.53, 0.98, 1.00}
  colors[imgui.Col.Header] = imgui.Vec4{0.72, 0.85, 1.00, 0.31}
  colors[imgui.Col.Header_Hovered] = imgui.Vec4{0.26, 0.59, 0.98, 0.80}
  colors[imgui.Col.Header_Active] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
  colors[imgui.Col.Separator] = imgui.Vec4{0.43, 0.43, 0.50, 0.50}
  colors[imgui.Col.Separator_Hovered] = imgui.Vec4{0.10, 0.40, 0.75, 0.78}
  colors[imgui.Col.Separator_Active] = imgui.Vec4{0.10, 0.40, 0.75, 1.00}
  colors[imgui.Col.Resize_Grip] = imgui.Vec4{0.26, 0.59, 0.98, 0.20}
  colors[imgui.Col.Resize_Grip_Hovered] = imgui.Vec4{0.26, 0.59, 0.98, 0.67}
  colors[imgui.Col.Resize_Grip_Active] = imgui.Vec4{0.26, 0.59, 0.98, 0.95}
  colors[imgui.Col.Tab_Hovered] = imgui.Vec4{0.61, 0.62, 0.64, 0.80}
  colors[imgui.Col.Tab] = imgui.Vec4{0.46, 0.50, 0.56, 0.86}
  colors[imgui.Col.Tab_Selected] = imgui.Vec4{0.64, 0.67, 0.70, 1.00}
  colors[imgui.Col.Tab_Selected_Overline] = imgui.Vec4{0.71, 0.76, 0.81, 1.00}
  colors[imgui.Col.Tab_Dimmed] = imgui.Vec4{0.38, 0.40, 0.43, 0.97}
  colors[imgui.Col.Tab_Dimmed_Selected] = imgui.Vec4{0.34, 0.38, 0.44, 1.00}
  colors[imgui.Col.Tab_Dimmed_Selected_Overline] = imgui.Vec4{0.50, 0.50, 0.50, 0.00}
  colors[imgui.Col.Docking_Preview] = imgui.Vec4{0.73, 0.75, 0.77, 0.70}
  colors[imgui.Col.Docking_Empty_Bg] = imgui.Vec4{0.20, 0.20, 0.20, 1.00}
  colors[imgui.Col.Plot_Lines] = imgui.Vec4{0.61, 0.61, 0.61, 1.00}
  colors[imgui.Col.Plot_Lines_Hovered] = imgui.Vec4{1.00, 0.43, 0.35, 1.00}
  colors[imgui.Col.Plot_Histogram] = imgui.Vec4{0.90, 0.70, 0.00, 1.00}
  colors[imgui.Col.Plot_Histogram_Hovered] = imgui.Vec4{1.00, 0.60, 0.00, 1.00}
  colors[imgui.Col.Table_Header_Bg] = imgui.Vec4{0.19, 0.19, 0.20, 1.00}
  colors[imgui.Col.Table_Border_Strong] = imgui.Vec4{0.31, 0.31, 0.35, 1.00}
  colors[imgui.Col.Table_Border_Light] = imgui.Vec4{0.23, 0.23, 0.25, 1.00}
  colors[imgui.Col.Table_Row_Bg] = imgui.Vec4{0.00, 0.00, 0.00, 0.00}
  colors[imgui.Col.Table_Row_Bg_Alt] = imgui.Vec4{1.00, 1.00, 1.00, 0.06}
  colors[imgui.Col.Text_Link] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
  colors[imgui.Col.Text_Selected_Bg] = imgui.Vec4{0.26, 0.59, 0.98, 0.35}
  colors[imgui.Col.Drag_Drop_Target] = imgui.Vec4{1.00, 1.00, 0.00, 0.90}
  colors[imgui.Col.Nav_Cursor] = imgui.Vec4{0.26, 0.59, 0.98, 1.00}
  colors[imgui.Col.Nav_Windowing_Highlight] = imgui.Vec4{1.00, 1.00, 1.00, 0.70}
  colors[imgui.Col.Nav_Windowing_Dim_Bg] = imgui.Vec4{0.80, 0.80, 0.80, 0.20}
  colors[imgui.Col.Modal_Window_Dim_Bg] = imgui.Vec4{0.80, 0.80, 0.80, 0.35}
}
