package rune_engine

import "core:encoding/json"
import gl "vendor:OpenGL"
import "vendor:glfw"

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:os"

import "renderer"
import "input"

// LayerProcs :: struct {
//  on_attach: proc(data: rawptr),
//  on_update: proc(data: rawptr),
//  on_detach: proc(data: rawptr),
// }
// Layer :: struct {
//  procs: LayerProcs,
//  data:  rawptr,
// }

@(private)
glfw_context := runtime.default_context()
@(private)
application: struct {
  window:         Window,
  running:        bool,
  // input:          struct {
  //  keys:               input.KeyCode_BitSet,
  //  prev_keys:          input.KeyCode_BitSet,
  //  mouse_buttons:      input.MouseButton_BitSet,
  //  prev_mouse_buttons: input.MouseButton_BitSet,
  //  mouse_position:     [2]f32,
  //  mouse_delta:        [2]f32,
  //  scroll:             f32,
  //  horizontal_scroll:  f32,
  // },
  time:           f32,
  delta_time:     f32,
  logger:         log.Logger,

  default_shader:    renderer.Shader,
  default_pipeline:  renderer.Pipeline,
  rendering_backend: renderer.RenderApiType,
  renderer:          renderer.Renderer,

  init_proc:   proc(),
  update_proc: proc(),
  event_proc:  proc(_: Event),
  quit_proc:   proc(),
}

// PushLayer :: struct {
//  type:  typeid,
//  procs: LayerProcs,
// }

App_Info :: struct {
  window: struct {
    title:  string,
    width:  u32,
    height: u32,
  },
  init_proc:   proc(),
  update_proc: proc(),
  event_proc:  proc(_: Event),
  quit_proc:   proc(),
  rendering_backend: renderer.RenderApiType,
}

init :: proc(info: App_Info) {
  application.init_proc = info.init_proc
  application.update_proc = info.update_proc
  application.event_proc = info.event_proc
  application.quit_proc = info.quit_proc
  application.rendering_backend = info.rendering_backend

  log_file, err := os.open("log/log.txt", { .Write, .Append, .Create })
  if err != .Exist {
    fmt.println(os.error_string(err))
  }
  application.logger = log.create_file_logger(log_file)
  context.logger = application.logger
  log.info("logger created")

  application.window = window_create(info.window.width, info.window.height, info.window.title, application.rendering_backend)
  application.renderer = renderer.create_renderer(application.rendering_backend)

  glfw.SetKeyCallback(application.window.handle, proc "c" (_: glfw.WindowHandle, key, scancode, action, mods: i32) {
    if application.event_proc == nil do return
    context = glfw_context
    ev: Key_Event
    ev.key = input.GLFW_KEY_TO_ENGINE_KEY[key]
    ev.action = auto_cast action
    if mods & glfw.MOD_SHIFT != 0     do ev.mods |= { .Shift }
    if mods & glfw.MOD_CONTROL != 0   do ev.mods |= { .Control }
    if mods & glfw.MOD_ALT != 0       do ev.mods |= { .Alt }
    if mods & glfw.MOD_SUPER != 0     do ev.mods |= { .Super }
    if mods & glfw.MOD_CAPS_LOCK != 0 do ev.mods |= { .CapsLock }
    if mods & glfw.MOD_NUM_LOCK != 0  do ev.mods |= { .NumLock }
    application.event_proc(ev)
  })
  glfw.SetMouseButtonCallback(application.window.handle, proc "c" (_: glfw.WindowHandle, button, action, mods: i32) {
    if application.event_proc == nil do return
    context = glfw_context
    ev: Mouse_Button_Event
    ev.button = auto_cast button
    ev.action = auto_cast action
    application.event_proc(ev)
  })
  glfw.SetCursorPosCallback(application.window.handle, proc "c" (_: glfw.WindowHandle, xpos, ypos: f64) {
    if application.event_proc == nil do return
    context = glfw_context
    @(static) prev_pos: [2]f32
    ev: Mouse_Pos_Event
    ev.position = { f32(xpos), f32(ypos) }
    ev.delta = ev.position - prev_pos
    prev_pos = ev.position
    application.event_proc(ev)
  })
  glfw.SetScrollCallback(application.window.handle, proc "c" (_: glfw.WindowHandle, xoffset, yoffset: f64) {
    if application.event_proc == nil do return
    context = glfw_context
    ev: Scroll_Event
    ev.horizontal = f32(xoffset)
    ev.vertical = f32(yoffset)
    application.event_proc(ev)
  })
  glfw.SetCharCallback(application.window.handle, proc "c" (_: glfw.WindowHandle, codepoint: rune) {
    if application.event_proc == nil do return
    context = glfw_context
    ev: Text_Event
    ev.codepoint = codepoint
    application.event_proc(ev)
  })
  glfw.SetCursorEnterCallback(application.window.handle, proc "c" (_: glfw.WindowHandle, entered: i32) {
    if application.event_proc == nil do return
    context = glfw_context
    ev: Mouse_Enter_Event
    ev.entered = bool(entered)
    application.event_proc(ev)
  })

  vs_blocks: renderer.Shader_Reflection_Data
  json.unmarshal_string(vs_uniform_blocks, &vs_blocks)
  fs_blocks: renderer.Shader_Reflection_Data
  json.unmarshal_string(fs_uniform_blocks, &fs_blocks)

  application.running = true
  // application.default_shader = load_shader("assets/shaders/test.glsl")
  application.default_shader = application.renderer.create_shader(application.renderer.ctx, &{
    vs_func = {
      spirv_code = vs_spirv[:],
      glsl_code = vs_glsl[:],
      hlsl_code = vs_hlsl[:],
      msl_code = vs_msl[:],
      reflection_data = vs_blocks,
    },
    fs_func = {
      spirv_code = fs_spirv[:],
      glsl_code = fs_glsl[:],
      hlsl_code = fs_hlsl[:],
      msl_code = fs_msl[:],
      reflection_data = fs_blocks,
    },
  })
  application.default_pipeline = application.renderer.create_pipeline(application.renderer.ctx, &{
    vertex_layout = {
      {format = .RGB32F,  location = 0},
      {format = .RGB32F,  location = 1},
      {format = .RG32F,   location = 2},
      {format = .RGBA32F, location = 3},
      {format = .RGBA32F, location = 4}
    },
    shader = application.default_shader,
  })
}

terminate :: proc() {
  renderer.destroy_shader(&application.renderer, application.default_shader)

  glfw.Terminate()
  log.destroy_file_logger(application.logger)
}

is_running :: proc() -> bool {
  return application.running
}

run :: proc() {
  if application.init_proc != nil do application.init_proc()

  context.logger = application.logger
  for is_running() {
    frame_start()
    if application.update_proc != nil do application.update_proc()
    frame_end()
  }

  if application.quit_proc != nil do application.quit_proc()
}

set_clear_color :: proc(color: [4]f32) {
  gl.ClearColor(color.r, color.g, color.b, color.a)
}

frame_start :: proc() {
  gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

  // application.input.prev_keys = application.input.keys
  // application.input.prev_mouse_buttons = application.input.mouse_buttons

  glfw.PollEvents()
}

frame_end :: proc() {
  glfw.SwapBuffers(application.window.handle)
  // application.input.mouse_delta = 0
  application.delta_time = cast(f32)glfw.GetTime() - application.time
  application.time = cast(f32)glfw.GetTime()
  // application.input.scroll = 0
  // application.input.horizontal_scroll = 0
}

close :: proc() {
  glfw.SetWindowShouldClose(application.window.handle, true)
  application.running = false
}

get_time :: proc() -> f32 {
  return cast(f32)glfw.GetTime()
}

get_delta_time :: proc() -> f32 {
  return cast(f32)glfw.GetTime() - application.time
}

get_window :: proc() -> Window {
  return application.window
}

setup_glfw_callbacks :: proc() {
  // glfw.SetKeyCallback(
  //  application.window.handle,
  //  proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
  //    if action == glfw.REPEAT {
  //      return
  //    }
  //    context = runtime.default_context()
  //    if action == glfw.RELEASE {
  //      application.input.keys -= {input.GLFW_KEY_TO_ENGINE_KEY[key]}
  //    } else {
  //      application.input.keys += {input.GLFW_KEY_TO_ENGINE_KEY[key]}
  //    }
  //    // append(
  //    //  &application.events,
  //    //  KeyEvent {
  //    //    input.GLFW_KEY_TO_ENGINE_KEY[key],
  //    //    cast(input.Action)action,
  //    //    scancode,
  //    //    transmute(input.Modifiers)cast(u8)mods,
  //    //  },
  //    // )
  //  },
  // )
  // glfw.SetMouseButtonCallback(
  //  application.window.handle,
  //  proc "c" (window: glfw.WindowHandle, button, scancode, action: i32) {
  //    if action == glfw.REPEAT {
  //      return
  //    }
  //    context = runtime.default_context()
  //    if action == glfw.RELEASE {
  //      application.input.mouse_buttons -= {cast(input.MouseButton)button}
  //    } else {
  //      application.input.mouse_buttons += {cast(input.MouseButton)button}
  //    }
  //    // append(
  //    //  &application.events,
  //    //  MouseButtonEvent{cast(input.MouseButton)button, cast(input.Action)action},
  //    // )
  //  },
  // )
  // glfw.SetCursorPosCallback(
  //  application.window.handle,
  //  proc "c" (window: glfw.WindowHandle, x, y: f64) {
  //    context = runtime.default_context()
  //    pos := [2]f32{cast(f32)x, cast(f32)y}
  //    application.input.mouse_delta += pos - application.input.mouse_position
  //    application.input.mouse_position = pos
  //    // append(&application.events, MousePosEvent{{cast(f32)x, cast(f32)y}})
  //  },
  // )
  // glfw.SetScrollCallback(
  //  application.window.handle,
  //  proc "c" (window: glfw.WindowHandle, x, y: f64) {
  //    context = runtime.default_context()
  //    application.input.scroll = cast(f32)y
  //    application.input.horizontal_scroll = cast(f32)x
  //    // append(&application.events, ScrollEvent{cast(f32)y, cast(f32)x})
  //  },
  // )
}
