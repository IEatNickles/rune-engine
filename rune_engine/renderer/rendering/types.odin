package rendering

import hm "core:container/handle_map"

Handle :: hm.Handle64

Pipeline :: distinct Handle
Shader :: distinct Handle
Texture :: distinct Handle
Material :: distinct Handle
Buffer :: distinct Handle

// TODO:
//  get rid of this
Mesh :: distinct u32

Vertex_Attribute :: struct {
  format:   Color_Format,
  location: int,
}

Pipeline_Create_Info :: struct {
  vertex_layout: []Vertex_Attribute,
  shader:        Shader,
}

Buffer_Usage_Flags :: bit_set[Buffer_Usage_Flag]
Buffer_Usage_Flag :: enum {
  Vertex_Buffer,
  Index_Buffer,
}

Buffer_Create_Info :: struct {
  usage: Buffer_Usage_Flags,
  data:  rawptr,
  size:  int,
}

Filter :: enum {
  None,
  Nearest,
  Linear,
}

Wrap_Mode :: enum {
  Clamp_To_Edge,
  Clamp_To_Border,
  Repeat,
}

Texture_Type :: enum {
  D2,
  D3,
  Array_2D,
  Cube,
}

Texture_Create_Info :: struct {
  format:      Color_Format,
  data:        rawptr,
  size:        [3]i32,
  min_filter:  Filter,
  mag_filter:  Filter,
  mip_filter:  Filter,
  wrap_mode_u: Wrap_Mode,
  wrap_mode_v: Wrap_Mode,
  wrap_mode_w: Wrap_Mode,
  type:        Texture_Type,
}

Store_Action :: enum {
  Store,
  Dont_Care,
}

Load_Action :: enum {
  Load,
  Clear,
  Dont_Care,
}

Color_Attachment :: struct {
  format:       Color_Format,
  texture:      Texture,
  clear_color:  [4]f32,
  load_action:  Load_Action,
  store_action: Store_Action,
}

Depth_Attachment :: struct {
  format:       Color_Format,
  texture:      Texture,
  clear_value:  f32,
  load_action:  Load_Action,
  store_action: Store_Action,
}

Pass_Info :: struct {
  color_attachments: []Color_Attachment,
  depth_attachment:  Depth_Attachment,
  compute: bool
}

Uniform_Type :: enum {
  Float,
  Vec2,
  Vec3,
  Vec4,
  Int,
  IVec2,
  IVec3,
  IVec4,
  UInt,
  UVec2,
  UVec3,
  UVec4,
  Mat2,
  Mat3,
  Mat4,
}

Uniform :: struct {
  offset: int,
  type:   Uniform_Type
}

Uniform_Block :: struct {
  identifier: string,
  size:    int,
  members: map[string]Uniform,
}

Shader_Type :: enum {
  Vertex,
  Fragment,
  Compute,
}

Image_Type :: enum {
  D1,
  D2,
  D3,
  Cube,
}

Sampler :: struct { }
Image_Data :: struct {
  dim:             Image_Type,
  is_array:        bool,
  is_depth:        bool,
  is_multisampled: bool,
}
Combined_Image_Sampler :: struct {
  using img: Image_Data,
}
Storage_Image :: struct {
  using img: Image_Data,
}
Sampled_Image :: struct {
  using img: Image_Data,
}

Shader_Member :: struct {
  name:   string,
  index:  int,
  size:   int,
  offset: int,
  type:   Uniform_Type,
}

Uniform_Buffer :: struct {
  members: map[string]Shader_Member,
}

Storage_Buffer :: struct { }

Descriptor_Binding :: struct {
  name:    string,
  id:      u32,
  binding: u32,
  type: union {
    Sampler,
    Combined_Image_Sampler,
    Sampled_Image,
    Storage_Image,
    Uniform_Buffer,
    Storage_Buffer,
  }
}

Push_Constant :: struct {
  name:    string,
  size:    int,
  offset:  int,
  members: map[string]Shader_Member,
}

Shader_Reflection_Data :: struct {
  descriptor_bindings: map[string]Descriptor_Binding,
  push_constants:      map[string]Push_Constant,
}

Shader_Func :: struct {
  type:       Shader_Type,
  spirv_code: []u8,
  glsl_code:  []u8,
  hlsl_code:  []u8,
  msl_code:   []u8,
  reflection_data: Shader_Reflection_Data,
}

Shader_Create_Info :: struct {
  vs_func: Shader_Func,
  fs_func: Shader_Func,
  cs_func: Shader_Func,
}

Color_Format :: enum {
  Unknown,
  R8,
  RG8,
  RGB8,
  RGBA8,

  R16F,
  RG16F,
  RGB16F,
  RGBA16F,

  R32F,
  RG32F,
  RGB32F,
  RGBA32F,

  Depth,
}

get_uniform_type_size :: proc(type: Uniform_Type) -> int {
  switch type {
  case .Float: return size_of(f32)
  case .Vec2:  return size_of([2]f32)
  case .Vec3:  return size_of([3]f32)
  case .Vec4:  return size_of([4]f32)
  case .Int:   return size_of(i32)
  case .IVec2: return size_of([2]i32)
  case .IVec3: return size_of([3]i32)
  case .IVec4: return size_of([4]i32)
  case .UInt:  return size_of(u32)
  case .UVec2: return size_of([2]u32)
  case .UVec3: return size_of([3]u32)
  case .UVec4: return size_of([4]u32)
  case .Mat2:  return size_of(matrix[2,2]f32)
  case .Mat3:  return size_of(matrix[3,3]f32)
  case .Mat4:  return size_of(matrix[4,4]f32)
  }
  unreachable()
}

color_format_component_count :: proc(format: Color_Format) -> int {
  switch format {
  case .R8:      return 1
  case .RG8:     return 2
  case .RGB8:    return 3
  case .RGBA8:   return 4
  case .R16F:    return 1
  case .RG16F:   return 2
  case .RGB16F:  return 3
  case .RGBA16F: return 4
  case .R32F:    return 1
  case .RG32F:   return 2
  case .RGB32F:  return 3
  case .RGBA32F: return 4
  case .Depth:   return 1
  case .Unknown: return 0
  }
  unreachable()
}

color_format_size :: proc(format: Color_Format) -> int {
  switch format {
  case .R8:      return size_of(u8)
  case .RG8:     return size_of([2]u8)
  case .RGB8:    return size_of([3]u8)
  case .RGBA8:   return size_of([4]u8)
  case .R16F:    return size_of(f16)
  case .RG16F:   return size_of([2]f16)
  case .RGB16F:  return size_of([3]f16)
  case .RGBA16F: return size_of([4]f16)
  case .R32F:    return size_of(f32)
  case .RG32F:   return size_of([2]f32)
  case .RGB32F:  return size_of([3]f32)
  case .RGBA32F: return size_of([4]f32)
  case .Depth:   return size_of(f32)
  case .Unknown: return 0
  }
  unreachable()
}
