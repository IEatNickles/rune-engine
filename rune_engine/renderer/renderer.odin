package renderer

import "core:log"

Backend :: enum {
  None,
  OpenGL,
  Vulkan,
  Direct3D11,
  Direct3D12,
  Metal,
  WebGL,
  WebGPU,
}

Backend_Flags :: bit_set[Backend]

when ODIN_OS == .Windows {
  SUPPORTED_BACKENDS :: Backend_Flags{ .OpenGL, .Vulkan, .Direct3D11, .Direct3D12 }
} else when ODIN_OS == .Linux {
  SUPPORTED_BACKENDS :: Backend_Flags{ .OpenGL, .Vulkan }
} else when ODIN_OS == .Darwin {
  SUPPORTED_BACKENDS :: Backend_Flags{ .Metal, .Vulkan }
} else when ODIN_OS == .JS {
  SUPPORTED_BACKENDS :: Backend_Flags{ .WebGL, .WebGPU }
} else {
  SUPPORTED_BACKENDS :: Backend_Flags{ .OpenGL }
}

Instance :: distinct rawptr
Surface  :: distinct rawptr
Device   :: distinct rawptr

Handle :: struct { idx: u16, gen: u16, }
Sampler           :: distinct Handle
Texture           :: distinct Handle
Texture_View      :: distinct Handle
Shader            :: distinct Handle
Pipeline          :: distinct Handle
Buffer            :: distinct Handle
Bind_Group_Layout :: distinct Handle
Bind_Group        :: distinct Handle

Command_Buffer :: distinct rawptr
Render_Pass    :: distinct rawptr

Buffer_Binding_Type :: enum {
  Uniform,
  Storage,
  Read_Only_Storage,
}

Sampler_Binding_Layout :: struct { }
Buffer_Binding_Layout :: struct {
  type: Buffer_Binding_Type,
}
Texture_Binding_Layout :: struct {
  dim:          Texture_Dim,
  multisampled: bool,
}
Storage_Texture_Binding_Layout :: struct {
  format: Format,
  dim:    Texture_Dim,
}

Bind_Group_Layout_Entry :: struct {
  binding:    u32,
  visibility: Shader_Stage_Flags,
  layout: union {
    Sampler_Binding_Layout,
    Buffer_Binding_Layout,
    Texture_Binding_Layout,
    Storage_Texture_Binding_Layout,
  },
}

Bind_Group_Layout_Desc :: struct {
  entries: []Bind_Group_Layout_Entry,
}

Binding_Resource :: union {
  Sampler,
  Buffer,
  Texture_View,
}

Bind_Group_Entry :: struct {
  binding:  u32,
  resource: Binding_Resource,
}

Bind_Group_Desc :: struct {
  layout:  Bind_Group_Layout,
  entries: []Bind_Group_Entry,
}

Surface_Texture :: struct {
  texture: Texture,
  view:    Texture_View,
}

Instance_Desc :: struct {
  backends:          Backend_Flags,
  enable_validation: bool,
  adapter_options:   Maybe(Adapter_Options),
  surface_desc:      Maybe(Surface_Desc),
}
DEFAULT_INSTANCE_DESC :: Instance_Desc {
  backends = { .Vulkan, .Direct3D12, .Metal, .WebGL }
}

Surface_Source_Win32 :: struct {
  hinstance: rawptr,
  hwnd:      rawptr,
}

Surface_Source_Xlib :: struct {
  display: rawptr,
  window:  u64,
}

Surface_Source_Wayland :: struct {
  display: rawptr,
  surface:  rawptr,
}

Surface_Source_Xcb :: struct {
  connection: rawptr,
  window:     u32,
}

Surface_Source_Metal :: struct {
  layer: rawptr,
}

Surface_Source_Html :: struct {
  canvas: rawptr,
}

Surface_Source_Android :: struct {
  window: rawptr,
}

Surface_Source :: union {
  Surface_Source_Win32,
  Surface_Source_Xlib,
  Surface_Source_Xcb,
  Surface_Source_Wayland,
  Surface_Source_Metal,
  Surface_Source_Html,
  Surface_Source_Android,
}

Surface_Desc :: struct {
  source: Surface_Source,
}

Present_Mode :: enum {
  Fifo,
  Mailbox,
}

Format :: enum {
  R8_UNORM,
  RG8_UNORM,
  RGB8_UNORM,
  RGBA8_UNORM,
  BGRA8_UNORM,
  R16_UNORM,
  RG16_UNORM,
  RGB16_UNORM,
  RGBA16_UNORM,

  R8_SNORM,
  RG8_SNORM,
  RGB8_SNORM,
  RGBA8_SNORM,
  R16_SNORM,
  RG16_SNORM,
  RGB16_SNORM,
  RGBA16_SNORM,

  R16_FLOAT,
  RG16_FLOAT,
  RGB16_FLOAT,
  RGBA16_FLOAT,
  R32_FLOAT,
  RG32_FLOAT,
  RGB32_FLOAT,
  RGBA32_FLOAT,

  R8_UINT,
  RG8_UINT,
  RGB8_UINT,
  RGBA8_UINT,
  R16_UINT,
  RG16_UINT,
  RGB16_UINT,
  RGBA16_UINT,
  R32_UINT,
  RG32_UINT,
  RGB32_UINT,
  RGBA32_UINT,

  R8_SINT,
  RG8_SINT,
  RGB8_SINT,
  RGBA8_SINT,
  R16_SINT,
  RG16_SINT,
  RGB16_SINT,
  RGBA16_SINT,
  R32_SINT,
  RG32_SINT,
  RGB32_SINT,
  RGBA32_SINT,

  D32_FLOAT,
  D24_UNORM_S8_UINT,
  D32_FLOAT_S8_UINT,
}

Surface_Options :: struct {
  extent:       [2]u32,
  format:       Format,
  present_mode: Present_Mode,
}

Power_Preference :: enum {
  Low_Power_Usage,
  High_Performance,
}

Adapter_Options :: struct {
  power_preference: Power_Preference,
}
DEFAULT_ADAPTER_OPTIONS :: Adapter_Options {
  power_preference = .High_Performance,
}

Error :: union {
  Physical_Device_Error,
}

Physical_Device_Error :: enum {
  Not_Found,
}

Texture_Dim :: enum {
  D1,
  D2,
  D3,
}

Texture_Mipmap_Level :: struct {
  data: rawptr,
}

Wrap :: enum {
  Repeat,
  Clamp_To_Edge,
  Clamp_To_Border,
  Mirror_Repeat,
  Mirror_Clamp_To_Edge,
}

Filter :: enum {
  Linear,
  Nearest,
}

Border_Color :: enum {
	Transparent_Black,
	Opaque_Black,
	Opaque_White,
}

Texture_Desc :: struct {
  dim:         Texture_Dim,
  format:      Format,
  extent:      [3]u32,
  mip_levels:  u32,
  array_count: u32,
  usage:       Texture_Usage_Flags,
}

Sampler_Desc :: struct {
  wrap:         [3]Wrap,
  border_color: Border_Color,
  min_filter:   Filter,
  mag_filter:   Filter,
  mip_filter:   Filter,
}

Texture_Usage_Flags :: bit_set[Texture_Usage]
Texture_Usage :: enum {
  Texture_Binding,
  Storage_Texture_Binding,
  Render_Attachment,
}

Texture_View_Dim :: enum {
  D1,
  D2,
  D3,
  D2_Array,
  Cube,
  Cube_Array,
}

Texture_View_Desc :: struct {
  texture:           Texture,
  dim:               Texture_View_Dim,
  base_mip_level:    u32,
  mip_level_count:   u32,
  base_array_layer:  u32,
  array_layer_count: u32,
}

Vertex_Step_Mode :: enum {
  Per_Vertex,
  Per_Instance,
}

Vertex_Binding_Desc :: struct {
  binding:    u32,
  stride:     u32,
  input_rate: Vertex_Step_Mode,
}

Vertex_Attribute_Desc :: struct {
  location: u32,
  binding:  u32,
  format:   Format,
  offset:   int,
}

Topology_Type :: enum {
  Point_List,
  Line_List,
  Line_Strip,
  Triangle_List,
  Triangle_Strip,
  Triangle_Fan,
}

Cull_Mode :: enum {
  None,
  Front,
  Back,
}

Front_Face :: enum {
  Clockwise,
  Counter_Clockwise,
}

Blend_Factor :: enum {
	Zero,
	One,
	Src_COLOR,
	One_Minus_Src_Color,
	Dst_Color,
	One_Minus_Dst_Color,
	Src_Alpha,
	One_Minus_Src_Alpha,
	Dst_Alpha,
	One_Minus_Dst_Alpha,
	Constant_Color,
	One_Minus_Constant_Color,
	Constant_Alpha,
	One_Minus_Constant_Alpha,
	Src_Alpha_Saturate,
	Src1_Color,
	One_Minus_Src1_Color,
	Src1_Alpha,
	One_Minus_Src1_Alpha,
}

Blend_Func :: enum {
	Add,
	Subtract,
	Reverse_Subtract,
	Min,
	Max,
}

Color_Component_Flags :: bit_set[Color_Component]
Color_Component :: enum {
  R, G, B, A
}

Color_Blend_Attachment :: struct {
	src_color_blend_factor: Blend_Factor,
	dst_color_blend_factor: Blend_Factor,
	color_blend_func:       Blend_Func,
	src_alpha_blend_factor: Blend_Factor,
	dst_alpha_blend_factor: Blend_Factor,
	alpha_blend_func:       Blend_Func,
	color_write_mask:       Color_Component_Flags,
	blend_enabled:          bool,
}

Pipeline_Color_Target :: struct {
  format: Format,
  blend:  Color_Blend_Attachment,
}

Push_Constant_Range :: struct {
  stages: Shader_Stage_Flags,
  offset: int,
  size:   int,
}

Compare_Func :: enum {
	Never,
	Less,
	Equal,
	Less_Or_Equal,
	Greater,
	Not_Equal,
	Greater_Or_Equal,
	Always,
}

Stencil_Func :: enum {
	Keep,
	Zero,
	Replace,
	Increment_And_Clamp,
	Decrement_And_Clamp,
	Invert,
	Increment_And_Wrap,
	Decrement_And_Wrap,
}

Stencil_State :: struct {
	fail:         Stencil_Func,
	pass:         Stencil_Func,
	depth_fail:   Stencil_Func,
	compare:      Compare_Func,
	compare_mask: u32,
	write_mask:   u32,
	reference:    u32,
}

Pipeline_Depth_Stencil_Target :: struct {
  format:                   Format,
  depth_test_enable:        bool,
  depth_write_enable:       bool,
  depth_compare_func:       Compare_Func,
  depth_bounds_test_enable: bool,
  stencil_test_enable:      bool,
  stencil_front:            Stencil_State,
  stencil_back:             Stencil_State,
  min_depth_bounds:         f32,
  max_depth_bounds:         f32,
}

Vertex_Attribute :: struct {
  format:   Format,
  location: u32,
  offset:   int,
}

Graphics_Pipeline_Desc :: struct {
  bindings:             []Vertex_Binding_Desc,
  attributes:           []Vertex_Attribute_Desc,
  topology:             Topology_Type,
  cull_mode:            Cull_Mode,
  front_face:           Front_Face,
  color_targets:        []Pipeline_Color_Target,
  depth_stencil:        Pipeline_Depth_Stencil_Target,
  blend_constant:       [4]f32,
  vertex_shader:        Shader,
  fragment_shader:      Shader,
  bind_group_layouts:   []Bind_Group_Layout,
  push_constant_ranges: []Push_Constant_Range,
}

Shader_Stage_Flags :: bit_set[Shader_Stage]
Shader_Stage :: enum {
  Vertex,
  Tessellation_Control,
  Tessellation_Evaluation,
  Geometry,
  Fragment,
  Compute,
}

Shader_Code_Type :: enum {
  Spirv,
  Glsl,
  Hlsl,
}

Shader_Desc :: struct {
  code:      []u32,
  code_type: Shader_Code_Type,
}

Buffer_Usage_Flags :: bit_set[Buffer_Usage_Flag]
Buffer_Usage_Flag :: enum {
  Vertex_Buffer,
  Index_Buffer,
  Uniform_Buffer,
  Storage_Buffer,
}

Buffer_Desc :: struct {
  size:  u32,
  usage: Buffer_Usage_Flags,
}

Index_Type :: enum {
  U32,
  U16,
}

Load_Action :: enum {
  Load,
  Dont_Care,
  Clear,
}

Store_Action :: enum {
  Store,
  Dont_Care,
}

Color_Attachment :: struct {
  view:         Texture_View,
  load_action:  Load_Action,
  store_action: Store_Action,
  clear_value:  [4]f32,
}

Depth_Operations :: struct {
  load_action:  Load_Action,
  store_action: Store_Action,
  clear_value:  f32,
}

Stencil_Operations :: struct {
  load_action:  Load_Action,
  store_action: Store_Action,
  clear_value:  u32,
}

Depth_Stencil_Attachment :: struct {
  view:        Texture_View,
  depth_ops:   Depth_Operations,
  stencil_ops: Stencil_Operations,
}

Viewport :: struct {
  offset: [2]f32,
  extent: [2]f32,
}

Rect2D :: struct {
  offset: [2]u32,
  extent: [2]u32,
}

Render_Pass_Desc :: struct {
  color_attachents:         []Color_Attachment,
  depth_stencil_attachment: Maybe(Depth_Stencil_Attachment),
  render_area:              Maybe(Rect2D),
}

Texture_Write_Info :: struct {
  texture:     Texture,
  pixels:      rawptr,
  offset:      [3]u32,
  extent:      [3]u32,
  mip_level:   u32,
  array_layer: u32,
}

Buffer_Write_Info :: struct {
  buffer: Buffer,
  data:   rawptr,
  offset: int,
  size:   int,
}

Push_Constant_Info :: struct {
  data:   rawptr,
  stages: Shader_Stage_Flags,
  offset: int,
  size:   int,
}

create_instance :: proc(desc: Maybe(Instance_Desc)) -> (Instance, Error) {
  desc := desc.? or_else DEFAULT_INSTANCE_DESC
  log.ensure(desc.backends != nil, "please specify a backend")

  backends := desc.backends & SUPPORTED_BACKENDS
  log.ensure(backends != nil, "no supplied backends supported")

  when ODIN_OS == .Windows {
    // TODO: add support for direct3d
    backends -= { .Direct3D12, .Direct3D11 }
    if .Direct3D12 in backends {
    } else if .Vulkan in backends {
      vk_init()
    } else if .Direct3D11 in backends {
    } else if .OpenGL in backends {
      gl_init()
    } else do unreachable()
  } else when ODIN_OS == .Linux {
    if .Vulkan in backends {
      vk_init()
    } else if .OpenGL in backends {
      gl_init()
    }
  } else when ODIN_OS == .Darwin {
    // TODO: add support for metal
    backends -= { .Metal }
    if .Metal in backends {
    } else if .Vulkan in backends {
      vk_init()
    }
  }
  return create_instance_impl(desc)
}

create_instance_impl: proc(desc: Maybe(Instance_Desc)) -> (Instance, Error)
destroy_instance: proc(instance: Instance)

instance_get_device: proc(instance: Instance) -> Device
instance_get_surface: proc(instance: Instance) -> Surface

device_begin_commands: proc(device: Device) -> Command_Buffer
device_submit_commands: proc(device: Device, command_buffer: Command_Buffer)
device_create_sampler: proc(device: Device, desc: Sampler_Desc) -> Sampler
device_create_texture: proc(device: Device, desc: Texture_Desc) -> Texture
device_create_texture_view: proc(device: Device, desc: Texture_View_Desc) -> Texture_View
device_create_shader: proc(device: Device, desc: Shader_Desc) -> Shader
device_create_graphics_pipeline: proc(device: Device, desc: Graphics_Pipeline_Desc) -> Pipeline
device_create_buffer: proc(device: Device, desc: Buffer_Desc) -> Buffer
device_create_bind_group_layout: proc(device: Device, desc: Bind_Group_Layout_Desc) -> Bind_Group_Layout
device_create_bind_group: proc(device: Device, desc: Bind_Group_Desc) -> Bind_Group
device_write_texture: proc(device: Device, info: Texture_Write_Info)
device_write_buffer: proc(device: Device, info: Buffer_Write_Info)

device_destroy_sampler: proc(device: Device, sampler: Sampler)
device_destroy_texture: proc(device: Device, texture: Texture)
device_destroy_texture_view: proc(device: Device, view: Texture_View)
device_destroy_shader: proc(device: Device, shader: Shader)
device_destroy_pipeline: proc(device: Device, pipeline: Pipeline)
device_destroy_buffer: proc(device: Device, buffer: Buffer)
device_destroy_bind_group_layout: proc(device: Device, layout: Bind_Group_Layout)
device_destroy_bind_group: proc(device: Device, bind_group: Bind_Group)

surface_configure: proc(surface: Surface, options: Surface_Options)
surface_get_current_texture: proc(surface: Surface) -> Surface_Texture
surface_present: proc(surface: Surface)

command_buffer_begin_render_pass: proc(command_buffer: Command_Buffer, desc: Render_Pass_Desc) -> Render_Pass
command_buffer_end_render_pass: proc(command_buffer: Command_Buffer)

render_pass_set_pipeline: proc(pass: Render_Pass, pipeline: Pipeline)
render_pass_draw: proc(pass: Render_Pass, element_count: int, first_element := 0, instance_count := 1, first_instance := 0)
render_pass_set_vertex_buffers: proc(pass: Render_Pass, buffers: []Buffer)
render_pass_set_index_buffer:   proc(pass: Render_Pass, buffer: Buffer, index_type: Index_Type, offset := 0)
render_pass_set_bind_group: proc(pass: Render_Pass, group_index: int, bind_group: Bind_Group)
render_pass_set_push_constants: proc(pass: Render_Pass, info: Push_Constant_Info)
render_pass_set_viewport: proc(pass: Render_Pass, viewport: Viewport)
render_pass_set_scissor: proc(pass: Render_Pass, rect: Rect2D)

get_components_in_format :: #force_inline proc "contextless" (format: Format) -> int {
  switch format {
  case .R8_UNORM: return 1
  case .RG8_UNORM: return 2
  case .RGB8_UNORM: return 3
  case .RGBA8_UNORM: return 4
  case .BGRA8_UNORM: return 4
  case .R16_UNORM: return 1
  case .RG16_UNORM: return 2
  case .RGB16_UNORM: return 3
  case .RGBA16_UNORM: return 4
  case .R8_SNORM: return 1
  case .RG8_SNORM: return 2
  case .RGB8_SNORM: return 3
  case .RGBA8_SNORM: return 4
  case .R16_SNORM: return 1
  case .RG16_SNORM: return 2
  case .RGB16_SNORM: return 3
  case .RGBA16_SNORM: return 4
  case .R16_FLOAT: return 1
  case .RG16_FLOAT: return 2
  case .RGB16_FLOAT: return 3
  case .RGBA16_FLOAT: return 4
  case .R32_FLOAT: return 1
  case .RG32_FLOAT: return 2
  case .RGB32_FLOAT: return 3
  case .RGBA32_FLOAT: return 4
  case .R8_UINT: return 1
  case .RG8_UINT: return 2
  case .RGB8_UINT: return 3
  case .RGBA8_UINT: return 4
  case .R16_UINT: return 1
  case .RG16_UINT: return 2
  case .RGB16_UINT: return 3
  case .RGBA16_UINT: return 4
  case .R32_UINT: return 1
  case .RG32_UINT: return 2
  case .RGB32_UINT: return 3
  case .RGBA32_UINT: return 4
  case .R8_SINT: return 1
  case .RG8_SINT: return 2
  case .RGB8_SINT: return 2
  case .RGBA8_SINT: return 4
  case .R16_SINT: return 1
  case .RG16_SINT: return 2
  case .RGB16_SINT: return 2
  case .RGBA16_SINT: return 4
  case .R32_SINT: return 1
  case .RG32_SINT: return 2
  case .RGB32_SINT: return 3
  case .RGBA32_SINT: return 4
  case .D32_FLOAT: return 1
  case .D24_UNORM_S8_UINT: return 4
  case .D32_FLOAT_S8_UINT: return 1
  }
  unreachable()
}
