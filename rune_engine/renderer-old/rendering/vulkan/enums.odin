package vulkan_backend

import vk "vendor:vulkan"

import ".."

color_format_to_vulkan :: proc(format: rendering.Color_Format) -> vk.Format {
  switch format {
  case .R8:      return .R8_UNORM
  case .RG8:     return .R8G8_UNORM
  case .RGB8:    return .R8G8B8_UNORM
  case .RGBA8:   return .R8G8B8A8_UNORM
  case .BGRA8:   return .B8G8R8A8_UNORM
  case .R16F:    return .R16_SFLOAT
  case .RG16F:   return .R16G16_SFLOAT
  case .RGB16F:  return .R16G16B16_SFLOAT
  case .RGBA16F: return .R16G16B16A16_SFLOAT
  case .R32F:    return .R32_SFLOAT
  case .RG32F:   return .R32G32_SFLOAT
  case .RGB32F:  return .R32G32B32_SFLOAT
  case .RGBA32F: return .R32G32B32A32_SFLOAT
  case .Depth:   return .D32_SFLOAT
  case .Unknown: return .UNDEFINED
  }
  unreachable()
}

topology_type_to_vulkan :: proc(topology: rendering.Topology_Type) -> vk.PrimitiveTopology {
  switch topology {
  case .Point_List:     return .POINT_LIST
  case .Line_List:      return .LINE_LIST
  case .Line_Strip:     return .LINE_STRIP
  case .Triangle_List:  return .TRIANGLE_LIST
  case .Triangle_Fan:   return .TRIANGLE_FAN
  case .Triangle_Strip: return .TRIANGLE_STRIP
  }
  unreachable()
}

cull_mode_to_vulkan :: proc(cull_mode: rendering.Cull_Mode) -> vk.CullModeFlags {
  switch cull_mode {
  case .None:  return nil
  case .Front: return { .FRONT }
  case .Back:  return { .BACK }
  }
  unreachable()
}

front_face_to_vulkan :: proc(front_face: rendering.Front_Face) -> vk.FrontFace {
  switch front_face {
  case .Clockwise:         return .CLOCKWISE
  case .Counter_Clockwise: return .COUNTER_CLOCKWISE
  }
  unreachable()
}

blend_factor_to_vulkan :: proc(factor: rendering.Blend_Factor) -> vk.BlendFactor {
  switch factor {
  case .Zero:                     return .ZERO
  case .One:                      return .ONE
  case .Src_COLOR:                return .SRC_COLOR
  case .One_Minus_Src_Color:      return .ONE_MINUS_SRC_COLOR
  case .Dst_Color:                return .DST_COLOR
  case .One_Minus_Dst_Color:      return .ONE_MINUS_DST_COLOR
  case .Src_Alpha:                return .SRC_ALPHA
  case .One_Minus_Src_Alpha:      return .ONE_MINUS_SRC_ALPHA
  case .Dst_Alpha:                return .DST_ALPHA
  case .One_Minus_Dst_Alpha:      return .ONE_MINUS_DST_ALPHA
  case .Constant_Color:           return .CONSTANT_COLOR
  case .One_Minus_Constant_Color: return .ONE_MINUS_CONSTANT_COLOR
  case .Constant_Alpha:           return .CONSTANT_ALPHA
  case .One_Minus_Constant_Alpha: return .ONE_MINUS_CONSTANT_ALPHA
  case .Src_Alpha_Saturate:       return .SRC_ALPHA_SATURATE
  case .Src1_Color:               return .SRC1_COLOR
  case .One_Minus_Src1_Color:     return .ONE_MINUS_SRC1_COLOR
  case .Src1_Alpha:               return .SRC1_ALPHA
  case .One_Minus_Src1_Alpha:     return .ONE_MINUS_SRC1_ALPHA
  }
  unreachable()
}

blend_func_to_vulkan :: proc(func: rendering.Blend_Func) -> vk.BlendOp {
  switch func {
  case .Add:              return .ADD
  case .Subtract:         return .SUBTRACT
  case .Reverse_Subtract: return .REVERSE_SUBTRACT
  case .Min:              return .MIN
  case .Max:              return .MAX
  }
  unreachable()
}

color_component_flags_to_vulkan :: proc(flags: rendering.Color_Component_Flags) -> (res: vk.ColorComponentFlags) {
  if .R in flags do res |= { .R }
  if .G in flags do res |= { .G }
  if .B in flags do res |= { .B }
  if .A in flags do res |= { .A }
  return
}

compare_func_to_vulkan :: proc(cmp: rendering.Compare_Func) -> vk.CompareOp {
  switch cmp {
  case .Always:        return .ALWAYS
  case .Less:          return .LESS
  case .Less_Equal:    return .LESS_OR_EQUAL
  case .Equal:         return .EQUAL
  case .Not_Equal:     return .NOT_EQUAL
  case .Greater_Equal: return .GREATER_OR_EQUAL
  case .Greater:       return .GREATER
  case .Never:         return .NEVER
  case: unreachable()
  }
}

stencil_func_to_vulkan :: proc(func: rendering.Stencil_Func) -> vk.StencilOp {
  switch func {
  case .Keep:                return .KEEP
  case .Zero:                return .ZERO
  case .Replace:             return .REPLACE
  case .Increment_And_Clamp: return .INCREMENT_AND_CLAMP
  case .Decrement_And_Clamp: return .DECREMENT_AND_CLAMP
  case .Invert:              return .INVERT
  case .Increment_And_Wrap:  return .INCREMENT_AND_WRAP
  case .Decrement_And_Wrap:  return .DECREMENT_AND_WRAP
  case: unreachable()
  }
}

image_type_to_vulkan :: proc(type: rendering.Texture_Type) -> vk.ImageType {
  switch type {
  case .D2:       return .D2
  case .D3:       return .D3
  case .Array_2D: return .D2
  case .Cube:     return .D3
  }
  unreachable()
}

image_usage_to_vulkan :: proc(usage: rendering.Image_Usage_Flags) -> (res: vk.ImageUsageFlags) {
  if .Storage in usage do res |= { .STORAGE }
  else do res |= { .SAMPLED }
  if .Color_Attachment in usage do res |= { .COLOR_ATTACHMENT }
  if .Resolve_Attachment in usage do res |= { .COLOR_ATTACHMENT }
  if .Depth_Stencil_Attachment in usage do res |= { .DEPTH_STENCIL_ATTACHMENT }
  return
}

buffer_usage_to_vulkan :: proc(usage: rendering.Buffer_Usage_Flags) -> (res: vk.BufferUsageFlags) {
  if .Index_Buffer in usage do res |= { .INDEX_BUFFER }
  if .Vertex_Buffer in usage do res |= { .VERTEX_BUFFER }
  return
}

load_action_to_vulkan :: proc(action: rendering.Load_Action) -> vk.AttachmentLoadOp {
  switch action {
  case .Load:      return .LOAD
  case .Clear:     return .CLEAR
  case .Dont_Care: return .DONT_CARE
  }
  unreachable()
}

store_action_to_vulkan :: proc(action: rendering.Store_Action) -> vk.AttachmentStoreOp {
  switch action {
  case .Store:     return .STORE
  case .Dont_Care: return .DONT_CARE
  }
  unreachable()
}

binding_type_to_vulkan :: proc(type: rendering.Binding_Type) -> vk.DescriptorType {
  switch type {
  case .Sampler:        return .SAMPLER
  case .Sampled_Image:  return .SAMPLED_IMAGE
  case .Storage_Image:  return .STORAGE_IMAGE
  case .Storage_Buffer: return .STORAGE_BUFFER
  case .Uniform_Buffer: return .UNIFORM_BUFFER
  }
  unreachable()
}

shader_stage_to_vulkan :: proc(stage: rendering.Shader_Stage) -> vk.ShaderStageFlag {
  switch stage {
  case .Vertex:   return .VERTEX
  case .Fragment: return .FRAGMENT
  case .Compute:  return .COMPUTE
  }
  unreachable()
}
