package opengl

import "base:runtime"

import "core:fmt"
import "core:io"
import "core:log"
import "core:os"
import "core:path/filepath"
import "core:strings"
import gl "vendor:OpenGL"

import ".."

ShaderUniform :: struct {
	location: i32,
	type:     ShaderUniformType,
	size:     u32,
}

// Shader :: struct {
// 	id:       u32,
// 	uniforms: map[string]ShaderUniform,
// }

uniforms: map[rendering.Shader]map[string]ShaderUniform

pre_process_shader :: proc(path: string) -> map[ShaderType]string {
	shaders: map[ShaderType]string
	content_bytes, ok := os.read_entire_file(path)
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

create_shader :: proc(vsh_path, fsh_path: string) -> rendering.Shader {
	prog := rendering.Shader(gl.CreateProgram())

	if err, ok := shader_attach_from_file(&prog, vsh_path, .Vertex); !ok {
		fmt.println("Vertex shader error: ", err)
	}
	if err, ok := shader_attach_from_file(&prog, fsh_path, .Fragment); !ok {
		fmt.println("Fragment shader error: ", err)
	}
	if err, ok := link_shader(&prog); !ok {
		fmt.println("Shader program error: ", err)
	}
	return prog
}

shader_attach_from_src :: proc(
	prog: ^rendering.Shader,
	src: string,
	type: ShaderType,
) -> (
	error: string,
	ok: bool,
) {
	shader := gl.CreateShader(cast(u32)type)
	src_cstring := cast(cstring)raw_data(src)
	length := cast(i32)len(src)
	gl.ShaderSource(shader, 1, &src_cstring, &length)
	gl.CompileShader(shader)
	when ODIN_DEBUG {
		error = check_error(
			shader,
			gl.COMPILE_STATUS,
			gl.GetShaderiv,
			gl.GetShaderInfoLog,
		) or_return
	}
	ok = true

	gl.AttachShader(cast(u32)prog^, shader)
	gl.DeleteShader(shader)
	return
}

shader_attach_from_file :: proc(
	prog: ^rendering.Shader,
	path: string,
	type: ShaderType,
) -> (
	error: string,
	ok: bool,
) {
	src: []u8
	src, ok = os.read_entire_file(path)
	if !ok {
		error = "Could not open file"
		return
	}
	return shader_attach_from_src(prog, cast(string)src, type)
}

link_shader :: proc(prog: ^rendering.Shader) -> (error: string, ok: bool) {
	gl.LinkProgram(cast(u32)prog^)
	when ODIN_DEBUG {
		error = check_error(
			cast(u32)prog^,
			gl.LINK_STATUS,
			gl.GetProgramiv,
			gl.GetProgramInfoLog,
		) or_return
	}
	gl.ValidateProgram(cast(u32)prog^)
	when ODIN_DEBUG {
		error = check_error(
			cast(u32)prog^,
			gl.VALIDATE_STATUS,
			gl.GetProgramiv,
			gl.GetProgramInfoLog,
		) or_return
	}
	ok = true

	uniform_count: i32
	gl.GetProgramiv(cast(u32)prog^, gl.ACTIVE_UNIFORMS, &uniform_count)
	if uniform_count > 0 {
		buf_len: i32
		gl.GetProgramiv(cast(u32)prog^, gl.ACTIVE_UNIFORM_MAX_LENGTH, &buf_len)
		name := make([^]u8, buf_len)
		len: i32
		size: i32
		type: u32
		map_insert(&uniforms, prog^, map[string]ShaderUniform{})
		for i in 0 ..< u32(uniform_count) {
			gl.GetActiveUniform(cast(u32)prog^, i, buf_len, &len, &size, &type, name)
			map_insert(
				&uniforms[prog^],
				strings.clone_from_ptr(name, int(len)),
				ShaderUniform{i32(i), cast(ShaderUniformType)type, u32(size)},
			)
		}
	}

	return
}

bind_shader :: proc(prog: ^rendering.Shader) {
	gl.UseProgram(cast(u32)prog^)
}

// Set a uniform in a shader.
//
// returns whether or not the uniform exists.
shader_uniform :: proc {//
	// Vec1
	shader_uniform_f32,
	shader_uniform_f64,
	shader_uniform_i32,
	shader_uniform_u32,

	// Vec4
	shader_uniform_vec4_f64,
	shader_uniform_vec4_f32,
	shader_uniform_vec4_i32,
	shader_uniform_vec4_u32,

	// Vec3
	shader_uniform_vec3_f64,
	shader_uniform_vec3_f32,
	shader_uniform_vec3_i32,
	shader_uniform_vec3_u32,

	// Vec2
	shader_uniform_vec2_f64,
	shader_uniform_vec2_f32,
	shader_uniform_vec2_i32,
	shader_uniform_vec2_u32,

	// Matrix f32
	shader_uniform_mat4_f32,
	shader_uniform_mat3_f32,
	shader_uniform_mat2_f32,
	shader_uniform_mat4x3_f32,
	shader_uniform_mat4x2_f32,
	shader_uniform_mat3x4_f32,
	shader_uniform_mat3x2_f32,
	shader_uniform_mat2x4_f32,
	shader_uniform_mat2x3_f32,

	// Matrix f64
	shader_uniform_mat4_f64,
	shader_uniform_mat3_f64,
	shader_uniform_mat2_f64,
	shader_uniform_mat4x3_f64,
	shader_uniform_mat4x2_f64,
	shader_uniform_mat3x4_f64,
	shader_uniform_mat3x2_f64,
	shader_uniform_mat2x4_f64,
	shader_uniform_mat2x3_f64,
}

shader_uniform_f32 :: proc(prog: ^rendering.Shader, name: string, value: f32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .Float)
	gl.ProgramUniform1f(cast(u32)prog^, uniform.location, value)
	return true
}

shader_uniform_f64 :: proc(prog: ^rendering.Shader, name: string, value: f64) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .Double)
	gl.ProgramUniform1d(cast(u32)prog^, uniform.location, value)
	return true
}

shader_uniform_i32 :: proc(prog: ^rendering.Shader, name: string, value: i32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .Int)
	gl.ProgramUniform1i(cast(u32)prog^, uniform.location, value)
	return true
}

shader_uniform_u32 :: proc(prog: ^rendering.Shader, name: string, value: u32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .UnsignedInt)
	gl.ProgramUniform1ui(cast(u32)prog^, uniform.location, value)
	return true
}

shader_uniform_vec4 :: proc {
	shader_uniform_vec4_f64,
	shader_uniform_vec4_f32,
	shader_uniform_vec4_i32,
	shader_uniform_vec4_u32,
}

shader_uniform_vec3 :: proc {
	shader_uniform_vec3_f64,
	shader_uniform_vec3_f32,
	shader_uniform_vec3_i32,
	shader_uniform_vec3_u32,
}

shader_uniform_vec2 :: proc {
	shader_uniform_vec2_f64,
	shader_uniform_vec2_f32,
	shader_uniform_vec2_i32,
	shader_uniform_vec2_u32,
}

shader_uniform_vec4_f32 :: proc(prog: ^rendering.Shader, name: string, value: [4]f32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatVec4)
	gl.ProgramUniform4f(cast(u32)prog^, uniform.location, value.x, value.y, value.z, value.w)
	return true
}

shader_uniform_vec3_f32 :: proc(prog: ^rendering.Shader, name: string, value: [3]f32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatVec3)
	gl.ProgramUniform3f(cast(u32)prog^, uniform.location, value.x, value.y, value.z)
	return true
}

shader_uniform_vec2_f32 :: proc(prog: ^rendering.Shader, name: string, value: [2]f32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatVec2)
	gl.ProgramUniform2f(cast(u32)prog^, uniform.location, value.x, value.y)
	return true
}

shader_uniform_vec4_f64 :: proc(prog: ^rendering.Shader, name: string, value: [4]f64) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleVec4)
	gl.ProgramUniform4d(cast(u32)prog^, uniform.location, value.x, value.y, value.z, value.w)
	return true
}

shader_uniform_vec3_f64 :: proc(prog: ^rendering.Shader, name: string, value: [3]f64) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleVec3)
	gl.ProgramUniform3d(cast(u32)prog^, uniform.location, value.x, value.y, value.z)
	return true
}

shader_uniform_vec2_f64 :: proc(prog: ^rendering.Shader, name: string, value: [2]f64) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleVec2)
	gl.ProgramUniform2d(cast(u32)prog^, uniform.location, value.x, value.y)
	return true
}

shader_uniform_vec4_i32 :: proc(prog: ^rendering.Shader, name: string, value: [4]i32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .IntVec4)
	gl.ProgramUniform4i(cast(u32)prog^, uniform.location, value.x, value.y, value.z, value.w)
	return true
}

shader_uniform_vec3_i32 :: proc(prog: ^rendering.Shader, name: string, value: [3]i32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .IntVec3)
	gl.ProgramUniform3i(cast(u32)prog^, uniform.location, value.x, value.y, value.z)
	return true
}

shader_uniform_vec2_i32 :: proc(prog: ^rendering.Shader, name: string, value: [2]i32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .IntVec2)
	gl.ProgramUniform2i(cast(u32)prog^, uniform.location, value.x, value.y)
	return true
}

shader_uniform_vec4_u32 :: proc(prog: ^rendering.Shader, name: string, value: [4]u32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .UnsignedIntVec4)
	gl.ProgramUniform4ui(cast(u32)prog^, uniform.location, value.x, value.y, value.z, value.w)
	return true
}

shader_uniform_vec3_u32 :: proc(prog: ^rendering.Shader, name: string, value: [3]u32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .UnsignedIntVec3)
	gl.ProgramUniform3ui(cast(u32)prog^, uniform.location, value.x, value.y, value.z)
	return true
}

shader_uniform_vec2_u32 :: proc(prog: ^rendering.Shader, name: string, value: [2]u32) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .UnsignedIntVec2)
	gl.ProgramUniform2ui(cast(u32)prog^, uniform.location, value.x, value.y)
	return true
}

shader_uniform_matrix :: proc {//
	// Float
	shader_uniform_mat4_f32,
	shader_uniform_mat3_f32,
	shader_uniform_mat2_f32,
	shader_uniform_mat4x3_f32,
	shader_uniform_mat4x2_f32,
	shader_uniform_mat3x4_f32,
	shader_uniform_mat3x2_f32,
	shader_uniform_mat2x4_f32,
	shader_uniform_mat2x3_f32,

	// Double
	shader_uniform_mat4_f64,
	shader_uniform_mat3_f64,
	shader_uniform_mat2_f64,
	shader_uniform_mat4x3_f64,
	shader_uniform_mat4x2_f64,
	shader_uniform_mat3x4_f64,
	shader_uniform_mat3x2_f64,
	shader_uniform_mat2x4_f64,
	shader_uniform_mat2x3_f64,
}

shader_uniform_mat4 :: proc {
	shader_uniform_mat4_f32,
	shader_uniform_mat4_f64,
}

shader_uniform_mat3 :: proc {
	shader_uniform_mat3_f32,
	shader_uniform_mat3_f64,
}

shader_uniform_mat2 :: proc {
	shader_uniform_mat2_f32,
	shader_uniform_mat2_f64,
}

shader_uniform_mat4x3 :: proc {
	shader_uniform_mat4x3_f32,
	shader_uniform_mat4x3_f64,
}

shader_uniform_mat4x2 :: proc {
	shader_uniform_mat4x2_f32,
	shader_uniform_mat4x2_f64,
}

shader_uniform_mat3x4 :: proc {
	shader_uniform_mat3x4_f32,
	shader_uniform_mat3x4_f64,
}

shader_uniform_mat3x2 :: proc {
	shader_uniform_mat3x2_f32,
	shader_uniform_mat3x2_f64,
}

shader_uniform_mat2x4 :: proc {
	shader_uniform_mat2x4_f32,
	shader_uniform_mat2x4_f64,
}

shader_uniform_mat2x3 :: proc {
	shader_uniform_mat2x3_f32,
	shader_uniform_mat2x3_f64,
}

shader_uniform_mat4_f32 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[4, 4]f32,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatMat4)
	gl.ProgramUniformMatrix4fv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat3_f32 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[3, 3]f32,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatMat3)
	gl.ProgramUniformMatrix3fv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat2_f32 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[2, 2]f32,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatMat2)
	gl.ProgramUniformMatrix2fv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat4x3_f32 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[4, 3]f32,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatMat4x3)
	gl.ProgramUniformMatrix4x3fv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat4x2_f32 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[4, 2]f32,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatMat4x2)
	gl.ProgramUniformMatrix4x2fv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat3x4_f32 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[3, 4]f32,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatMat3x4)
	gl.ProgramUniformMatrix3x4fv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat3x2_f32 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[3, 2]f32,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatMat3x2)
	gl.ProgramUniformMatrix3x2fv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat2x4_f32 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[2, 4]f32,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatMat2x4)
	gl.ProgramUniformMatrix2x4fv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat2x3_f32 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[2, 3]f32,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .FloatMat2x3)
	gl.ProgramUniformMatrix2x3fv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat4_f64 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[4, 4]f64,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleMat4)
	gl.ProgramUniformMatrix4dv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat3_f64 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[3, 3]f64,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleMat3)
	gl.ProgramUniformMatrix3dv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat2_f64 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[2, 2]f64,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleMat2)
	gl.ProgramUniformMatrix2dv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat4x3_f64 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[4, 3]f64,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleMat4x3)
	gl.ProgramUniformMatrix4x3dv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat4x2_f64 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[4, 2]f64,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleMat4x2)
	gl.ProgramUniformMatrix4x2dv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat3x4_f64 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[3, 4]f64,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleMat3x4)
	gl.ProgramUniformMatrix3x4dv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat3x2_f64 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[3, 2]f64,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleMat3x2)
	gl.ProgramUniformMatrix3x2dv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat2x4_f64 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[2, 4]f64,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleMat2x4)
	gl.ProgramUniformMatrix2x4dv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
	return true
}

shader_uniform_mat2x3_f64 :: proc(
	prog: ^rendering.Shader,
	name: string,
	value: ^matrix[2, 3]f64,
) -> bool {
	uniform := uniforms[prog^][name] or_return
	assert(uniform.type == .DoubleMat2x3)
	gl.ProgramUniformMatrix2x3dv(cast(u32)prog^, uniform.location, 1, false, &value[0, 0])
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
