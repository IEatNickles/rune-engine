package opengl

import "core:container/handle_map"
import "base:runtime"

import "core:fmt"
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

create_shader_func :: proc(source: string, type: u32) -> u32 {
  shader := gl.CreateShader(type)
  csource := strings.clone_to_cstring(source)
  defer delete(csource)
  gl.ShaderSource(shader, 1, &csource, nil)
  gl.CompileShader(shader)
  return shader
}

create_shader :: proc(desc: ^rendering.Shader_Create_Info) -> rendering.Shader {
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

destroy_shader :: proc(shader: rendering.Shader) {
  state := handle_map.get(&ctx.shaders, shader)
  gl.DeleteProgram(state.program_id)
}

// TODO:
//  maybe add updating a subset of a push constant?
//  (hence the offset and size parameters)
shader_set_push_constants :: proc(shader: rendering.Shader, name: string, data: rawptr, size, offset: int) {
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
