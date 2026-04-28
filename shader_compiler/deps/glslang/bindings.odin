package glslang

when ODIN_OS == .Linux {
  foreign import glslang {
    "system:glslang",
    "system:glslang-default-resource-limits",
  }
}

import "core:c"

@(default_calling_convention="c")
@(link_prefix="glslang_")
foreign glslang {
get_version :: proc(version: ^Version) ---

initialize_process :: proc() -> c.int ---
finalize_process :: proc() ---

shader_create :: proc(#by_ptr input: Input) -> ^Shader ---
shader_delete :: proc(shader: ^Shader) ---
shader_set_preamble :: proc(shader: ^Shader, s: cstring) ---
shader_set_entry_point :: proc(shader: ^Shader, s: cstring) ---
shader_set_invert_y :: proc(shader: ^Shader, y: bool) ---
shader_shift_binding :: proc(shader: ^Shader, res: Resource_Type, base: c.uint) ---
shader_shift_binding_for_set :: proc(shader: ^Shader, res: Resource_Type, base: c.uint, set: c.uint) ---
shader_set_options :: proc(shader: ^Shader, options: Shader_Options) ---
shader_set_glsl_version :: proc(shader: ^Shader, version: c.int) ---
shader_set_default_uniform_block_set_and_binding :: proc(shader: ^Shader, set: c.uint, binding: c.uint) ---
shader_set_default_uniform_block_name :: proc(shader: ^Shader, name: cstring) ---
shader_set_resource_set_binding :: proc(shader: ^Shader, bindings: cstring, num_bindings: c.uint) ---
shader_preprocess :: proc(shader: ^Shader, input: ^Input) -> b32 ---
shader_parse :: proc(shader: ^Shader, #by_ptr input: Input) -> b32 ---
shader_get_preprocessed_code :: proc(shader: ^Shader) -> cstring ---
shader_set_preprocessed_code :: proc(shader: ^Shader, code: cstring) ---
shader_get_info_log :: proc(shader: ^Shader) -> cstring ---
shader_get_info_debug_log :: proc(shader: ^Shader) -> cstring ---

program_create :: proc() -> ^Program ---
program_delete :: proc(program: ^Program) ---
program_add_shader :: proc(program: ^Program, shader: ^Shader) ---
program_link :: proc(program: ^Program, messages: Messages) -> b32 --- // messages
program_add_source_text :: proc(program: ^Program, stage: Stage, text: cstring, len: c.size_t) ---
program_set_source_file :: proc(program: ^Program, stage: Stage, file: cstring) ---
program_map_io :: proc(program: ^Program) -> b32 ---
program_map_io_with_resolver_and_mapper :: proc(program: ^Program, resolver: ^Resolver, mapper: ^Mapper) -> b32 ---
program_SPIRV_generate :: proc(program: ^Program, stage: Stage) ---
program_SPIRV_generate_with_options :: proc(program: ^Program, stage: Stage, spv_options: ^Spv_Options) ---
program_SPIRV_get_size :: proc(program: ^Program) -> c.size_t ---
program_SPIRV_get :: proc(program: ^Program, ptr: [^]c.uint) ---
program_SPIRV_get_ptr :: proc(program: ^Program) -> [^]c.uint ---
program_SPIRV_get_messages :: proc(program: ^Program) -> cstring ---
program_get_info_log :: proc(program: ^Program) -> cstring ---
program_get_info_debug_log :: proc(program: ^Program) -> cstring ---

glsl_mapper_create :: proc() -> Mapper ---
glsl_mapper_delete :: proc(mapper: Mapper) ---

glsl_resolver_create :: proc(program: ^Program, stage: Stage) -> ^Resolver ---
glsl_resolver_delete :: proc(resolver: ^Resolver) ---

// Returns a struct that can be used to create custom resource values.
@(link_name="glslang_resource")
glslang_resource :: proc() -> ^Resource ---

// These are the default resources for TBuiltInResources, used for both
//  - parsing this string for the case where the user didn't supply one,
//  - dumping out a template for user construction of a config file.
default_resource :: proc() -> ^Resource ---

// Returns the DefaultTBuiltInResource as a human-readable string.
// NOTE: User is responsible for freeing this string.
default_resource_string :: proc() -> cstring ---

// Decodes the resource limits from |config| to |resources|.
decode_resource_limits :: proc(resources: ^Resource, config: ^u8) ---
}
