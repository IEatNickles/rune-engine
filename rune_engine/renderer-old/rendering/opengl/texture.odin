package opengl

import "core:container/handle_map"
import gl "vendor:OpenGL"

import ".."

Texture_State :: struct {
  handle: rendering.Texture,
  id:     u32,
  target: u32,
}

create_texture :: proc(info: ^rendering.Texture_Create_Info) -> rendering.Texture {
  texture: u32
  target := gl_texture_target(info.type)
  gl.GenTextures(1, &texture)
  gl.BindTexture(target, texture)
  gl.TexParameteri(target, gl.TEXTURE_MIN_FILTER, gl_min_filter(info.min_filter, info.mip_filter))
  gl.TexParameteri(target, gl.TEXTURE_MAG_FILTER, gl_mag_filter(info.mag_filter))
  gl.TexParameteri(target, gl.TEXTURE_WRAP_S, gl_wrap(info.wrap_mode_u))
  gl.TexParameteri(target, gl.TEXTURE_WRAP_T, gl_wrap(info.wrap_mode_v))
  gl.TexParameteri(target, gl.TEXTURE_WRAP_R, gl_wrap(info.wrap_mode_w))

  format := gl_get_texture_format(info.format)
  internal_format := gl_get_texture_internal_format(info.format)
  switch info.type {
  case .D2:
    gl.TexImage2D(target, 0, internal_format, info.size.x, info.size.y, 0, format, gl_get_texture_pixel_type(info.format), info.data)
  case .D3:
    gl.TexImage3D(target, 0, internal_format, info.size.x, info.size.y, info.size.z, 0, format, gl_get_texture_pixel_type(info.format), info.data)
  case .Array_2D: panic("TODO")
  case .Cube: panic("TODO")
  }

  state := Texture_State {
    id = texture,
    target = target,
  }
  return handle_map.add(&ctx.textures, state)
}

destroy_texture :: proc(texture: rendering.Texture) {
  state := handle_map.get(&ctx.textures, texture)
  handle_map.remove(&ctx.textures, texture)
  gl.DeleteTextures(1, &state.id)
}

get_texture_descriptor :: proc(texture: rendering.Texture) -> u64 {
  state := handle_map.get(&ctx.textures, texture)
  return cast(u64)state.id
}

bind_texture :: proc(texture: rendering.Texture, unit: u32 = 0) {
  state := handle_map.get(&ctx.textures, texture)
  gl.ActiveTexture(gl.TEXTURE0 + unit)
	gl.BindTexture(state.target, state.id)
}

gl_get_texture_internal_format :: proc(format: rendering.Color_Format) -> i32 {
  switch format {
  case .R8:      return gl.R8
  case .RG8:     return gl.RG8
  case .RGB8:    return gl.RGB8
  case .RGBA8:   return gl.RGBA8
  case .BGRA8:   return gl.RGBA8
  case .Depth:   return gl.DEPTH_COMPONENT32F
  case .R16F:    return gl.R16F
  case .RG16F:   return gl.RG16F
  case .RGB16F:  return gl.RGB16F
  case .RGBA16F: return gl.RGBA16F
  case .R32F:    return gl.R32F
  case .RG32F:   return gl.RG32F
  case .RGB32F:  return gl.RGB32F
  case .RGBA32F: return gl.RGBA32F
  case .Unknown: return gl.NONE
  }
  unreachable()
}

gl_get_texture_format :: proc(format: rendering.Color_Format) -> u32 {
  switch format {
  case .R8, .R16F, .R32F:      return gl.RED
  case .RG8, .RG16F, .RG32F:     return gl.RG
  case .RGB8, .RGB16F, .RGB32F:    return gl.RGB
  case .RGBA8, .RGBA16F, .RGBA32F:   return gl.RGBA
  case .BGRA8:   return gl.BGRA
  case .Depth:   return gl.DEPTH_COMPONENT
  case .Unknown: return gl.NONE
  }
  unreachable()
}

gl_get_texture_pixel_type :: proc(format: rendering.Color_Format) -> u32 {
  switch format {
  case .R8:      return gl.UNSIGNED_BYTE
  case .RG8:     return gl.UNSIGNED_BYTE
  case .RGB8:    return gl.UNSIGNED_BYTE
  case .RGBA8:   return gl.UNSIGNED_BYTE
  case .BGRA8:   return gl.UNSIGNED_BYTE
  case .Depth:   return gl.FLOAT
  case .R16F:    return gl.HALF_FLOAT
  case .RG16F:   return gl.HALF_FLOAT
  case .RGB16F:  return gl.HALF_FLOAT
  case .RGBA16F: return gl.HALF_FLOAT
  case .R32F:    return gl.FLOAT
  case .RG32F:   return gl.FLOAT
  case .RGB32F:  return gl.FLOAT
  case .RGBA32F: return gl.FLOAT
  case .Unknown: return gl.NONE
  }
  unreachable()
}

gl_texture_target :: proc(type: rendering.Texture_Type) -> u32 {
  switch type {
  case .D2:       return gl.TEXTURE_2D
  case .D3:       return gl.TEXTURE_3D
  case .Array_2D: return gl.TEXTURE_2D_ARRAY
  case .Cube:     return gl.TEXTURE_CUBE_MAP
  }
  unreachable()
}

gl_min_filter :: proc(min: rendering.Filter, mip: rendering.Filter) -> i32 {
  switch mip {
  case .None: return gl_mag_filter(min)
  case .Nearest:
    switch min {
    case .Nearest: return gl.NEAREST_MIPMAP_NEAREST
    case .Linear:  return gl.LINEAR_MIPMAP_NEAREST
    case .None: unreachable()
    }
  case .Linear:
    switch min {
    case .Nearest: return gl.NEAREST_MIPMAP_LINEAR
    case .Linear:  return gl.LINEAR_MIPMAP_LINEAR
    case .None: unreachable()
    }
  }
  unreachable()
}

gl_mag_filter :: proc(filter: rendering.Filter) -> i32 {
  switch filter {
  case .Nearest: return gl.NEAREST
  case .Linear:  return gl.LINEAR
  case .None: unreachable()
  }
  unreachable()
}
