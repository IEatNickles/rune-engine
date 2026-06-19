package rune_engine

import "renderer"

// begin_pass :: proc(info: ^renderer.Pass_Info) {
//   application.renderer.begin_pass(info)
// }
//
// end_pass :: proc() {
//   application.renderer.end_pass()
// }
//
// submit :: proc() {
//   application.renderer.submit()
// }

Material :: struct {
  pipeline:          renderer.Pipeline,
  bind_group_layout: renderer.Bind_Group_Layout,
  bind_group:        renderer.Bind_Group,
}
Material_Desc :: struct {
  vertex_shader:   renderer.Shader_Desc,
  fragment_shader: renderer.Shader_Desc,
  textures:        []Texture,
}

Texture :: struct {
  texture: renderer.Texture,
  view:    renderer.Texture_View,
  sampler: renderer.Sampler,
}

Texture_Type :: enum {
  D1,
  D2,
  D3,
  Cube,
  D2_Array,
  Cube_Array,
}

Format :: renderer.Format
Wrap   :: renderer.Wrap
Filter :: renderer.Filter

Texture_Desc :: struct {
  type:        Texture_Type,
  format:      Format,
  extent:      [3]u32,
  mip_levels:  u32,
  array_count: u32,
  usage:       renderer.Texture_Usage_Flags,

  min_filter: Filter,
  mag_filter: Filter,
  mip_filter: Filter,
  wrap:       [3]Wrap,
}

Renderer :: struct {
  instance: renderer.Instance,
  device:   renderer.Device,
  surface:  renderer.Surface,
}

create_texture :: proc(desc: Texture_Desc) -> Texture {
  texture_dim: renderer.Texture_Dim
  view_dim:    renderer.Texture_View_Dim
  switch desc.type {
  case .D1:
    texture_dim = .D1
    view_dim = .D1
  case .D2:
    texture_dim = .D2
    view_dim = .D2
  case .D3:
    texture_dim = .D3
    view_dim = .D3
  case .Cube:
    texture_dim = .D3
    view_dim = .Cube
  case .D2_Array:
    texture_dim = .D2
    view_dim = .D2_Array
  case .Cube_Array:
    texture_dim = .D3
    view_dim = .Cube_Array
  }
  texture_desc := renderer.Texture_Desc {
    dim = texture_dim,
    format = desc.format,
    extent = desc.extent,
    mip_levels = desc.mip_levels,
    array_count = desc.array_count,
    usage = desc.usage,
  }
  texture := renderer.device_create_texture(application.device, texture_desc)
  view := renderer.device_create_texture_view(application.device, {
    texture = texture,
    dim = view_dim,
    array_layer_count = desc.array_count,
    mip_level_count = desc.mip_levels,
  })
  sampler := renderer.device_create_sampler(application.device, {
    min_filter = desc.min_filter,
    mag_filter = desc.mag_filter,
    mip_filter = desc.mip_filter,
    wrap       = desc.wrap,
  })
  return Texture{texture, view, sampler}
}

texture_set_pixels :: proc(texture: Texture, pixels: rawptr, offset: [3]u32, extent: [3]u32, mip := 0) {
  renderer.device_write_texture(application.device, {
    texture = texture.texture,
    mip_level = u32(mip),
    offset = offset,
    extent = extent,
    pixels = pixels,
  })
}

create_material :: proc(desc: Material_Desc) -> Material {
  device := application.device
  vs := renderer.device_create_shader(device, desc.vertex_shader)
  fs := renderer.device_create_shader(device, desc.fragment_shader)
  bgl_entries := make([]renderer.Bind_Group_Layout_Entry, len(desc.textures)*2)
  bg_entries := make([]renderer.Bind_Group_Entry, len(desc.textures)*2)
  for i in 0..<len(desc.textures) {
    bgl_entries[i*2]   = {binding = u32(i), visibility = {.Fragment}, layout = renderer.Sampler_Binding_Layout{}}
    bgl_entries[i*2+1] = {binding = u32(i+32), visibility = {.Fragment}, layout = renderer.Texture_Binding_Layout{dim = .D2}}
    bg_entries[i*2]    = {binding = u32(i), resource = desc.textures[i].sampler }
    bg_entries[i*2+1]  = {binding = u32(i+32), resource = desc.textures[i].view }
  }
  bind_group_layout := renderer.device_create_bind_group_layout(device, {
    entries = bgl_entries,
  })
  pipeline := renderer.device_create_graphics_pipeline(device, {
    vertex_shader = vs,
    fragment_shader = fs,
    attributes = {
      {binding=0, location=0, format = .RGB32_FLOAT },
      {binding=1, location=1, format = .RGB32_FLOAT },
      {binding=2, location=2, format = .RG32_FLOAT  },
      {binding=3, location=3, format = .RGBA32_FLOAT},
      {binding=4, location=4, format = .RGBA32_FLOAT},
    },
    bindings = {
      {binding=0, stride = size_of([3]f32)},
      {binding=1, stride = size_of([3]f32)},
      {binding=2, stride = size_of([2]f32)},
      {binding=3, stride = size_of([4]f32)},
      {binding=4, stride = size_of([4]f32)},
    },
    color_targets = {{format = .BGRA8_UNORM, blend = {color_write_mask=~{}}}},
    depth_stencil = {
      format = .D32_FLOAT_S8_UINT,
      depth_test_enable = true,
      depth_write_enable = true,
      depth_compare_func = .Less,
    },
    bind_group_layouts = {bind_group_layout},
    topology = .Triangle_List,
    cull_mode = .Back,
    front_face = .Counter_Clockwise,
    push_constant_ranges = {
      {stages = {.Vertex}, size = size_of(matrix[4,4]f32) * 3},
    }
  })
  bind_group := renderer.device_create_bind_group(device, {
    layout = bind_group_layout,
    entries = bg_entries,
  })
  return Material{
    pipeline,
    bind_group_layout,
    bind_group,
  }
}

// bind_texture :: proc(texture: renderer.Texture) {
//   renderer.bind_texture(&application.renderer, texture)
// }
//
// get_render_target :: proc() -> renderer.Image_View {
//   return application.renderer.get_render_target()
// }
//
// present :: proc() {
//   window_present(&application.window)
// }
//
// get_swapchain :: proc() -> renderer.Swapchain {
//   return window_get_swapchain(&application.window)
// }
