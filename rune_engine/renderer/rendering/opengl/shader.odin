package opengl

import "core:container/handle_map"
import "base:runtime"

import "core:fmt"
import "core:os"
import "core:strings"

import gl "vendor:OpenGL"

import ".."

ShaderUniform :: struct {
  location: i32,
  type:     rendering.Uniform_Type,
  size:     int,
  offset:   int,
}

Shader_State :: struct {
  handle:     rendering.Shader,
  program_id: u32,
  uniforms:   map[string]ShaderUniform,
  push_constants: map[string]map[string]ShaderUniform,
  reflection_data: rendering.Shader_Reflection_Data,
}

pre_process_shader :: proc(path: string) -> map[ShaderType]string {
  shaders: map[ShaderType]string
  content_bytes, ok := os.read_entire_file(path, context.allocator)
  content := cast(string)content_bytes
  for l in strings.split_lines_iterator(&content) {
    if strings.starts_with(l, "#shader") {
      t, ok2 := strings.substring(l, strings.index_byte(l, ' '), len(l))
      switch t {
      case "vertex":
      case "fragment":
      case "geometry":
      }
    }
  }
  return shaders
}

create_shader_func :: proc(source: string, type: u32) -> u32 {
  shader := gl.CreateShader(type)
  csource := strings.clone_to_cstring(source)
  defer delete(csource)
  gl.ShaderSource(shader, 1, &csource, nil)
  gl.CompileShader(shader)
  return shader
}

create_shader :: proc(ctx: ^Context, desc: ^rendering.Shader_Create_Info) -> rendering.Shader {
  prog := gl.CreateProgram()

  vs := create_shader_func(string(desc.vs_func.glsl_code), gl.VERTEX_SHADER)
  fs := create_shader_func(string(desc.fs_func.glsl_code), gl.FRAGMENT_SHADER)
  gl.AttachShader(prog, vs)
  gl.AttachShader(prog, fs)
  gl.LinkProgram(prog)

  state := Shader_State {
    program_id = prog,
  }
  for name, pc in desc.vs_func.reflection_data.push_constants {
    value: map[string]ShaderUniform
    for name, member in pc.members {
      name := fmt.aprintf("%s.%s", pc.name, name)
      uniform: ShaderUniform
      uniform.type = member.type
      uniform.location = gl.GetUniformLocation(prog, strings.clone_to_cstring(name))
      uniform.size = rendering.get_uniform_type_size(uniform.type)
      uniform.offset = member.offset
      value[name] = uniform
    }
    map_insert(&state.push_constants, name, value)
  }
  // uniform_count: i32
  // gl.GetProgramiv(prog, gl.ACTIVE_UNIFORMS, &uniform_count)
  // if uniform_count > 0 {
  //  buf_len: i32
  //  gl.GetProgramiv(prog, gl.ACTIVE_UNIFORM_MAX_LENGTH, &buf_len)
  //  name := make([^]u8, buf_len)
  //  len: i32
  //  size: i32
  //  type: u32
  //  // map_insert(&uniforms, prog, map[string]ShaderUniform{})
  //  for i in 0 ..< u32(uniform_count) {
  //    gl.GetActiveUniform(prog, i, buf_len, &len, &size, &type, name)
  //    loc := gl.GetUniformLocation(prog, cstring(name))
  //    if loc < 0 do continue
  //    map_insert(
  //      &state.uniforms,
  //      strings.clone_from_ptr(name, int(len)),
  //      ShaderUniform{loc, cast(ShaderUniformType)type, u32(size)},
  //    )
  //  }
  // }

  return handle_map.add(&ctx.shaders, state)
}

destroy_shader :: proc(ctx: ^Context, shader: rendering.Shader) {
  state := handle_map.get(&ctx.shaders, shader)
  gl.DeleteProgram(state.program_id)
}

// TODO:
//  maybe add updating a subset of a push constant?
//  (hence the offset and size parameters)
shader_set_push_constants :: proc(ctx: ^Context, shader: rendering.Shader, name: string, data: rawptr, size, offset: int) {
  data := data
  state := handle_map.get(&ctx.shaders, shader)

  for nm, member in state.push_constants[name] {
    // if offset >= size do break

    // TODO:
    //  add an array count
    switch member.type {
    case .Float: gl.Uniform1fv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .Vec2:  gl.Uniform2fv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .Vec3:  gl.Uniform3fv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .Vec4:  gl.Uniform4fv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .Int:   gl.Uniform1iv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .IVec2: gl.Uniform2iv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .IVec3: gl.Uniform3iv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .IVec4: gl.Uniform4iv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .UInt:  gl.Uniform1uiv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .UVec2: gl.Uniform2uiv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .UVec3: gl.Uniform3uiv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .UVec4: gl.Uniform4uiv(member.location, 1, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .Mat2:  gl.UniformMatrix2fv(member.location, 1, false, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .Mat3:  gl.UniformMatrix3fv(member.location, 1, false, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    case .Mat4:  gl.UniformMatrix4fv(member.location, 1, false, auto_cast rawptr(uintptr(data) + uintptr(member.offset)))
    }
    // data = rawptr(uintptr(data) + uintptr(member.size))
  }
}

// Set a uniform in a shader.
//
// returns whether or not the uniform exists.
shader_uniform :: proc {
  // Vec1
  shader_uniform_f32,
  shader_uniform_i32,
  shader_uniform_u32,

  // Vec4
  shader_uniform_vec4_f32,
  shader_uniform_vec4_i32,
  shader_uniform_vec4_u32,

  // Vec3
  shader_uniform_vec3_f32,
  shader_uniform_vec3_i32,
  shader_uniform_vec3_u32,

  // Vec2
  shader_uniform_vec2_f32,
  shader_uniform_vec2_i32,
  shader_uniform_vec2_u32,

  shader_uniform_mat4,
  shader_uniform_mat3,
  shader_uniform_mat2,
}

shader_uniform_f32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: f32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .Float)
  gl.ProgramUniform1f(cast(u32)state.program_id, uniform.location, value)
  return true
}

shader_uniform_i32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: i32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .Int)
  gl.ProgramUniform1i(cast(u32)state.program_id, uniform.location, value)
  return true
}

shader_uniform_u32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: u32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .UInt)
  gl.ProgramUniform1ui(cast(u32)state.program_id, uniform.location, value)
  return true
}

shader_uniform_vec4 :: proc {
  shader_uniform_vec4_f32,
  shader_uniform_vec4_i32,
  shader_uniform_vec4_u32,
}

shader_uniform_vec3 :: proc {
  shader_uniform_vec3_f32,
  shader_uniform_vec3_i32,
  shader_uniform_vec3_u32,
}

shader_uniform_vec2 :: proc {
  shader_uniform_vec2_f32,
  shader_uniform_vec2_i32,
  shader_uniform_vec2_u32,
}

shader_uniform_vec4_f32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: [4]f32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .Vec4)
  gl.ProgramUniform4f(cast(u32)state.program_id, uniform.location, value.x, value.y, value.z, value.w)
  return true
}

shader_uniform_vec3_f32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: [3]f32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .Vec3)
  gl.ProgramUniform3f(cast(u32)state.program_id, uniform.location, value.x, value.y, value.z)
  return true
}

shader_uniform_vec2_f32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: [2]f32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .Vec2)
  gl.ProgramUniform2f(cast(u32)state.program_id, uniform.location, value.x, value.y)
  return true
}

shader_uniform_vec4_i32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: [4]i32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .IVec4)
  gl.ProgramUniform4i(cast(u32)state.program_id, uniform.location, value.x, value.y, value.z, value.w)
  return true
}

shader_uniform_vec3_i32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: [3]i32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .IVec3)
  gl.ProgramUniform3i(cast(u32)state.program_id, uniform.location, value.x, value.y, value.z)
  return true
}

shader_uniform_vec2_i32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: [2]i32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .IVec2)
  gl.ProgramUniform2i(cast(u32)state.program_id, uniform.location, value.x, value.y)
  return true
}

shader_uniform_vec4_u32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: [4]u32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .UVec4)
  gl.ProgramUniform4ui(cast(u32)state.program_id, uniform.location, value.x, value.y, value.z, value.w)
  return true
}

shader_uniform_vec3_u32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: [3]u32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .UVec3)
  gl.ProgramUniform3ui(cast(u32)state.program_id, uniform.location, value.x, value.y, value.z)
  return true
}

shader_uniform_vec2_u32 :: proc(ctx: ^Context, shader: rendering.Shader, name: string, value: [2]u32) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .UVec2)
  gl.ProgramUniform2ui(cast(u32)state.program_id, uniform.location, value.x, value.y)
  return true
}

shader_uniform_matrix :: proc {
  shader_uniform_mat4,
  shader_uniform_mat3,
  shader_uniform_mat2,
}

shader_uniform_mat4 :: proc(
  ctx: ^Context,
  shader: rendering.Shader,
  name: string,
  value: ^matrix[4, 4]f32,
) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .Mat4)
  gl.ProgramUniformMatrix4fv(cast(u32)state.program_id, uniform.location, 1, false, &value[0, 0])
  return true
}

shader_uniform_mat3 :: proc(
  ctx: ^Context,
  shader: rendering.Shader,
  name: string,
  value: ^matrix[3, 3]f32,
) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .Mat3)
  gl.ProgramUniformMatrix3fv(cast(u32)state.program_id, uniform.location, 1, false, &value[0, 0])
  return true
}

shader_uniform_mat2 :: proc(
  ctx: ^Context,
  shader: rendering.Shader,
  name: string,
  value: ^matrix[2, 2]f32,
) -> bool {
  state := handle_map.get(&ctx.shaders, shader)
  uniform := state.uniforms[name] or_return
  assert(uniform.type == .Mat2)
  gl.ProgramUniformMatrix2fv(cast(u32)state.program_id, uniform.location, 1, false, &value[0, 0])
  return true
}

when ODIN_DEBUG {
  check_error :: proc(
    id: u32,
    pname: u32,
    iv_proc: proc "c" (_: u32, _: u32, _: [^]i32, _: runtime.Source_Code_Location),
    log_proc: proc "c" (_: u32, _: i32, _: ^i32, _: [^]u8, _: runtime.Source_Code_Location),
  ) -> (
    error: string,
    ok: bool,
  ) {
    status: i32
    if iv_proc(id, pname, &status, #location()); status == 0 {
      log_length: i32
      iv_proc(id, gl.INFO_LOG_LENGTH, &log_length, #location())
      info_log := make([^]u8, log_length)
      log_proc(id, log_length, &log_length, info_log, #location())
      error = strings.clone_from_ptr(info_log, cast(int)log_length, context.temp_allocator)
      fmt.println(error)
      return
    }
    ok = true
    return
  }
}

ShaderType :: enum {
  Fragment       = gl.FRAGMENT_SHADER,
  Vertex         = gl.VERTEX_SHADER,
  Geometry       = gl.GEOMETRY_SHADER,
  Compute        = gl.COMPUTE_SHADER,
  TessEvaluation = gl.TESS_EVALUATION_SHADER,
  TessControl    = gl.TESS_CONTROL_SHADER,
}

ShaderUniformType :: enum {
  Float                                 = gl.FLOAT,
  FloatVec2                             = gl.FLOAT_VEC2,
  FloatVec3                             = gl.FLOAT_VEC3,
  FloatVec4                             = gl.FLOAT_VEC4,
  Double                                = gl.DOUBLE,
  DoubleVec2                            = gl.DOUBLE_VEC2,
  DoubleVec3                            = gl.DOUBLE_VEC3,
  DoubleVec4                            = gl.DOUBLE_VEC4,
  Int                                   = gl.INT,
  IntVec2                               = gl.INT_VEC2,
  IntVec3                               = gl.INT_VEC3,
  IntVec4                               = gl.INT_VEC4,
  UnsignedInt                           = gl.UNSIGNED_INT,
  UnsignedIntVec2                       = gl.UNSIGNED_INT_VEC2,
  UnsignedIntVec3                       = gl.UNSIGNED_INT_VEC3,
  UnsignedIntVec4                       = gl.UNSIGNED_INT_VEC4,
  Bool                                  = gl.BOOL,
  BoolVec2                              = gl.BOOL_VEC2,
  BoolVec3                              = gl.BOOL_VEC3,
  BoolVec4                              = gl.BOOL_VEC4,
  FloatMat2                             = gl.FLOAT_MAT2,
  FloatMat3                             = gl.FLOAT_MAT3,
  FloatMat4                             = gl.FLOAT_MAT4,
  FloatMat2x3                           = gl.FLOAT_MAT2x3,
  FloatMat2x4                           = gl.FLOAT_MAT2x4,
  FloatMat3x2                           = gl.FLOAT_MAT3x2,
  FloatMat3x4                           = gl.FLOAT_MAT3x4,
  FloatMat4x2                           = gl.FLOAT_MAT4x2,
  FloatMat4x3                           = gl.FLOAT_MAT4x3,
  DoubleMat2                            = gl.DOUBLE_MAT2,
  DoubleMat3                            = gl.DOUBLE_MAT3,
  DoubleMat4                            = gl.DOUBLE_MAT4,
  DoubleMat2x3                          = gl.DOUBLE_MAT2x3,
  DoubleMat2x4                          = gl.DOUBLE_MAT2x4,
  DoubleMat3x2                          = gl.DOUBLE_MAT3x2,
  DoubleMat3x4                          = gl.DOUBLE_MAT3x4,
  DoubleMat4x2                          = gl.DOUBLE_MAT4x2,
  DoubleMat4x3                          = gl.DOUBLE_MAT4x3,
  Sampler1D                             = gl.SAMPLER_1D,
  Sampler2D                             = gl.SAMPLER_2D,
  Sampler3D                             = gl.SAMPLER_3D,
  SamplerCube                           = gl.SAMPLER_CUBE,
  Sampler1DShadow                       = gl.SAMPLER_1D_SHADOW,
  Sampler2DShadow                       = gl.SAMPLER_2D_SHADOW,
  Sampler1DArray                        = gl.SAMPLER_1D_ARRAY,
  Sampler2DArray                        = gl.SAMPLER_2D_ARRAY,
  Sampler1DArray_Shadow                 = gl.SAMPLER_1D_ARRAY_SHADOW,
  Sampler2DArray_Shadow                 = gl.SAMPLER_2D_ARRAY_SHADOW,
  Sampler2DMultisample                  = gl.SAMPLER_2D_MULTISAMPLE,
  Sampler2DMultisampleArray             = gl.SAMPLER_2D_MULTISAMPLE_ARRAY,
  SamplerCube_Shadow                    = gl.SAMPLER_CUBE_SHADOW,
  SamplerBuffer                         = gl.SAMPLER_BUFFER,
  Sampler2DRect                         = gl.SAMPLER_2D_RECT,
  Sampler2DRectShadow                   = gl.SAMPLER_2D_RECT_SHADOW,
  IntSampler1D                          = gl.INT_SAMPLER_1D,
  IntSampler2D                          = gl.INT_SAMPLER_2D,
  IntSampler3D                          = gl.INT_SAMPLER_3D,
  IntSamplerCube                        = gl.INT_SAMPLER_CUBE,
  IntSampler1DArray                     = gl.INT_SAMPLER_1D_ARRAY,
  IntSampler2DArray                     = gl.INT_SAMPLER_2D_ARRAY,
  IntSampler2DMultisample               = gl.INT_SAMPLER_2D_MULTISAMPLE,
  IntSampler2DMultisampleArray          = gl.INT_SAMPLER_2D_MULTISAMPLE_ARRAY,
  IntSamplerBuffer                      = gl.INT_SAMPLER_BUFFER,
  IntSampler2DRect                      = gl.INT_SAMPLER_2D_RECT,
  UnsignedIntSampler1D                  = gl.UNSIGNED_INT_SAMPLER_1D,
  UnsignedIntSampler2D                  = gl.UNSIGNED_INT_SAMPLER_2D,
  UnsignedIntSampler3D                  = gl.UNSIGNED_INT_SAMPLER_3D,
  UnsignedIntSamplerCube                = gl.UNSIGNED_INT_SAMPLER_CUBE,
  UnsignedIntSampler1DArray             = gl.UNSIGNED_INT_SAMPLER_1D_ARRAY,
  UnsignedIntSampler2DArray             = gl.UNSIGNED_INT_SAMPLER_2D_ARRAY,
  UnsignedIntSampler2DMultisample       = gl.UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE,
  UnsignedIntSampler2DMultisample_Array = gl.UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY,
  UnsignedIntSamplerBuffer              = gl.UNSIGNED_INT_SAMPLER_BUFFER,
  UnsignedIntSampler2DRect              = gl.UNSIGNED_INT_SAMPLER_2D_RECT,
  Image1D                               = gl.IMAGE_1D,
  Image2D                               = gl.IMAGE_2D,
  Image3D                               = gl.IMAGE_3D,
  Image2DRect                           = gl.IMAGE_2D_RECT,
  ImageCube                             = gl.IMAGE_CUBE,
  ImageBuffer                           = gl.IMAGE_BUFFER,
  Image1DArray                          = gl.IMAGE_1D_ARRAY,
  Image2DArray                          = gl.IMAGE_2D_ARRAY,
  ImageCubeMapArray                     = gl.IMAGE_CUBE_MAP_ARRAY,
  Image2DMultisample                    = gl.IMAGE_2D_MULTISAMPLE,
  Image2DMultisampleArray               = gl.IMAGE_2D_MULTISAMPLE_ARRAY,
  IntImage1D                            = gl.INT_IMAGE_1D,
  IntImage2D                            = gl.INT_IMAGE_2D,
  IntImage3D                            = gl.INT_IMAGE_3D,
  IntImage2DRect                        = gl.INT_IMAGE_2D_RECT,
  IntImageCube                          = gl.INT_IMAGE_CUBE,
  IntImageBuffer                        = gl.INT_IMAGE_BUFFER,
  IntImage1DArray                       = gl.INT_IMAGE_1D_ARRAY,
  IntImage2DArray                       = gl.INT_IMAGE_2D_ARRAY,
  IntImageCubeMapArray                  = gl.INT_IMAGE_CUBE_MAP_ARRAY,
  IntImage2DMultisample                 = gl.INT_IMAGE_2D_MULTISAMPLE,
  IntImage2DMultisampleArray            = gl.INT_IMAGE_2D_MULTISAMPLE_ARRAY,
  UnsignedIntImage1D                    = gl.UNSIGNED_INT_IMAGE_1D,
  UnsignedIntImage2D                    = gl.UNSIGNED_INT_IMAGE_2D,
  UnsignedIntImage3D                    = gl.UNSIGNED_INT_IMAGE_3D,
  UnsignedIntImage2DRect                = gl.UNSIGNED_INT_IMAGE_2D_RECT,
  UnsignedIntImageCube                  = gl.UNSIGNED_INT_IMAGE_CUBE,
  UnsignedIntImageBuffer                = gl.UNSIGNED_INT_IMAGE_BUFFER,
  UnsignedIntImage1DArray               = gl.UNSIGNED_INT_IMAGE_1D_ARRAY,
  UnsignedIntImage2DArray               = gl.UNSIGNED_INT_IMAGE_2D_ARRAY,
  UnsignedIntImageCube_Map_Array        = gl.UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY,
  UnsignedIntImage2DMultisample         = gl.UNSIGNED_INT_IMAGE_2D_MULTISAMPLE,
  UnsignedIntImage2DMultisample_Array   = gl.UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY,
  UnsignedIntAtomicCounter              = gl.UNSIGNED_INT_ATOMIC_COUNTER,
}
