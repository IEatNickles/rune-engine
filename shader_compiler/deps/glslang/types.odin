package glslang

import "core:c"

/* EShLanguage counterpart */
Stage_Mask :: bit_set[Stage]
Stage :: enum i32 {
  VERTEX,
  TESSCONTROL,
  TESSEVALUATION,
  GEOMETRY,
  FRAGMENT,
  COMPUTE,
  RAYGEN,
  RAYGEN_NV = RAYGEN,
  INTERSECT,
  INTERSECT_NV = INTERSECT,
  ANYHIT,
  ANYHIT_NV = ANYHIT,
  CLOSESTHIT,
  CLOSESTHIT_NV = CLOSESTHIT,
  MISS,
  MISS_NV = MISS,
  CALLABLE,
  CALLABLE_NV = CALLABLE,
  TASK,
  TASK_NV = TASK,
  MESH,
  MESH_NV = MESH,
}

/* EShSource counterpart */
Source :: enum i32 {
  NONE,
  GLSL,
  HLSL,
}

/* EShClient counterpart */
Client :: enum i32 {
  NONE,
  VULKAN,
  OPENGL,
}

/* EShTargetLanguage counterpart */
Target_Language :: enum i32 {
  NONE,
  SPV,
}

/* SH_TARGET_ClientVersion counterpart */
Target_Client_Version :: enum i32 {
  VULKAN_1_0 = (1 << 22),
  VULKAN_1_1 = (1 << 22) | (1 << 12),
  VULKAN_1_2 = (1 << 22) | (2 << 12),
  VULKAN_1_3 = (1 << 22) | (3 << 12),
  VULKAN_1_4 = (1 << 22) | (4 << 12),
  OPENGL_450 = 450,
}

/* SH_TARGET_LanguageVersion counterpart */
Target_Language_Version :: enum i32 {
  SPV_1_0 = (1 << 16),
  SPV_1_1 = (1 << 16) | (1 << 8),
  SPV_1_2 = (1 << 16) | (2 << 8),
  SPV_1_3 = (1 << 16) | (3 << 8),
  SPV_1_4 = (1 << 16) | (4 << 8),
  SPV_1_5 = (1 << 16) | (5 << 8),
  SPV_1_6 = (1 << 16) | (6 << 8),
}

/* EShExecutable counterpart */
Executable :: enum i32 { VERTEX_FRAGMENT, FRAGMENT }

// EShOptimizationLevel counterpart
// This enum is not used in the current C interface, but could be added at a later date.
// GLSLANG_OPT_NONE is the current default.
Optimization_Level :: enum i32 {
  NO_GENERATION,
  NONE,
  SIMPLE,
  FULL,
}

/* EShTextureSamplerTransformMode counterpart */
Texture_Sampler_Transform_mode :: enum i32 {
  KEEP,
  UPGRADE_TEXTURE_REMOVE_SAMPLER,
}

/* EShMessages counterpart */
Messages :: bit_set[Message]
Message :: enum i32 {
  RELAXED_ERRORS,
  SUPPRESS_WARNINGS,
  AST,
  SPV_RULES,
  VULKAN_RULES,
  ONLY_PREPROCESSOR,
  READ_HLSL,
  CASCADING_ERRORS,
  KEEP_UNCALLED,
  HLSL_OFFSETS,
  DEBUG_INFO,
  HLSL_ENABLE_16BIT_TYPES,
  HLSL_LEGALIZATION,
  HLSL_DX9_COMPATIBLE,
  BUILTIN_SYMBOL_TABLE,
  ENHANCED,
  ABSOLUTE_PATH,
  DISPLAY_ERROR_COLUMN,
  LINK_TIME_OPTIMIZATION,
  VALIDATE_CROSS_STAGE_IO,
}

/* EShReflectionOptions counterpart */
Reflection_Options :: bit_set[Reflection_Option]
Reflection_Option :: enum i32 {
  STRICT_ARRAY_SUFFIX,
  BASIC_ARRAY_SUFFIX,
  INTERMEDIATE_IOO,
  SEPARATE_BUFFERS,
  ALL_BLOCK_VARIABLES,
  UNWRAP_IO_BLOCKS,
  ALL_IO_VARIABLES,
  SHARED_STD140_SSBO,
  SHARED_STD140_UBO,
}

/* EProfile counterpart (from Versions.h) */
Profile :: bit_set[Profile_Bits]
Profile_Bits :: enum i32 {
  NO_PROFILE,
  CORE,
  COMPATIBILITY,
  ES,
}

/* Shader options */
Shader_Options :: bit_set[Shader_Option]
Shader_Option :: enum c.int {
  AUTO_MAP_BINDINGS,
  AUTO_MAP_LOCATIONS,
  VULKAN_RULES_RELAXED,
  PER_RESOURCE_TYPE,
}

/* TResourceType counterpart */
Resource_Type :: enum i32 {
  SAMPLER,
  TEXTURE,
  IMAGE,
  UBO,
  SSBO,
  UAV,
  COMBINED_SAMPLER,
  AS,
  TENSOR,
}


Shader :: struct{}
Program :: struct{}
Mapper :: struct{}
Resolver :: struct{}

/* Version counterpart */
Version :: struct {
  major: c.int,
  minor: c.int,
  patch: c.int,
  flavor: cstring,
}

/* TLimits counterpart */
Limits :: struct {
  non_inductive_for_loops: bool,
  while_loops: bool,
  do_while_loops: bool,
  general_uniform_indexing: bool,
  general_attribute_matrix_vector_indexing: bool,
  general_varying_indexing: bool,
  general_sampler_indexing: bool,
  general_variable_indexing: bool,
  general_constant_matrix_vector_indexing: bool,
}

/* TBuiltInResource counterpart */
Resource :: struct {
    max_lights: c.int,
    max_clip_planes: c.int,
    max_texture_units: c.int,
    max_texture_coords: c.int,
    max_vertex_attribs: c.int,
    max_vertex_uniform_components: c.int,
    max_varying_floats: c.int,
    max_vertex_texture_image_units: c.int,
    max_combined_texture_image_units: c.int,
    max_texture_image_units: c.int,
    max_fragment_uniform_components: c.int,
    max_draw_buffers: c.int,
    max_vertex_uniform_vectors: c.int,
    max_varying_vectors: c.int,
    max_fragment_uniform_vectors: c.int,
    max_vertex_output_vectors: c.int,
    max_fragment_input_vectors: c.int,
    min_program_texel_offset: c.int,
    max_program_texel_offset: c.int,
    max_clip_distances: c.int,
    max_compute_work_group_count_x: c.int,
    max_compute_work_group_count_y: c.int,
    max_compute_work_group_count_z: c.int,
    max_compute_work_group_size_x: c.int,
    max_compute_work_group_size_y: c.int,
    max_compute_work_group_size_z: c.int,
    max_compute_uniform_components: c.int,
    max_compute_texture_image_units: c.int,
    max_compute_image_uniforms: c.int,
    max_compute_atomic_counters: c.int,
    max_compute_atomic_counter_buffers: c.int,
    max_varying_components: c.int,
    max_vertex_output_components: c.int,
    max_geometry_input_components: c.int,
    max_geometry_output_components: c.int,
    max_fragment_input_components: c.int,
    max_image_units: c.int,
    max_combined_image_units_and_fragment_outputs: c.int,
    max_combined_shader_output_resources: c.int,
    max_image_samples: c.int,
    max_vertex_image_uniforms: c.int,
    max_tess_control_image_uniforms: c.int,
    max_tess_evaluation_image_uniforms: c.int,
    max_geometry_image_uniforms: c.int,
    max_fragment_image_uniforms: c.int,
    max_combined_image_uniforms: c.int,
    max_geometry_texture_image_units: c.int,
    max_geometry_output_vertices: c.int,
    max_geometry_total_output_components: c.int,
    max_geometry_uniform_components: c.int,
    max_geometry_varying_components: c.int,
    max_tess_control_input_components: c.int,
    max_tess_control_output_components: c.int,
    max_tess_control_texture_image_units: c.int,
    max_tess_control_uniform_components: c.int,
    max_tess_control_total_output_components: c.int,
    max_tess_evaluation_input_components: c.int,
    max_tess_evaluation_output_components: c.int,
    max_tess_evaluation_texture_image_units: c.int,
    max_tess_evaluation_uniform_components: c.int,
    max_tess_patch_components: c.int,
    max_patch_vertices: c.int,
    max_tess_gen_level: c.int,
    max_viewports: c.int,
    max_vertex_atomic_counters: c.int,
    max_tess_control_atomic_counters: c.int,
    max_tess_evaluation_atomic_counters: c.int,
    max_geometry_atomic_counters: c.int,
    max_fragment_atomic_counters: c.int,
    max_combined_atomic_counters: c.int,
    max_atomic_counter_bindings: c.int,
    max_vertex_atomic_counter_buffers: c.int,
    max_tess_control_atomic_counter_buffers: c.int,
    max_tess_evaluation_atomic_counter_buffers: c.int,
    max_geometry_atomic_counter_buffers: c.int,
    max_fragment_atomic_counter_buffers: c.int,
    max_combined_atomic_counter_buffers: c.int,
    max_atomic_counter_buffer_size: c.int,
    max_transform_feedback_buffers: c.int,
    max_transform_feedback_interleaved_components: c.int,
    max_cull_distances: c.int,
    max_combined_clip_and_cull_distances: c.int,
    max_samples: c.int,
    max_mesh_output_vertices_nv: c.int,
    max_mesh_output_primitives_nv: c.int,
    max_mesh_work_group_size_x_nv: c.int,
    max_mesh_work_group_size_y_nv: c.int,
    max_mesh_work_group_size_z_nv: c.int,
    max_task_work_group_size_x_nv: c.int,
    max_task_work_group_size_y_nv: c.int,
    max_task_work_group_size_z_nv: c.int,
    max_mesh_view_count_nv: c.int,
    max_mesh_output_vertices_ext: c.int,
    max_mesh_output_primitives_ext: c.int,
    max_mesh_work_group_size_x_ext: c.int,
    max_mesh_work_group_size_y_ext: c.int,
    max_mesh_work_group_size_z_ext: c.int,
    max_task_work_group_size_x_ext: c.int,
    max_task_work_group_size_y_ext: c.int,
    max_task_work_group_size_z_ext: c.int,
    max_mesh_view_count_ext: c.int,
    using _: struct #raw_union {
      max_dual_source_draw_buffers_ext: c.int,

        /* Incorrectly capitalized name retained for backward compatibility */
      maxDualSourceDrawBuffersEXT: c.int
    },

    limits: Limits,
}

/* Inclusion result structure allocated by C include_local/include_system callbacks */
Glsl_Include_Result :: struct {
    /* Header file name or NULL if inclusion failed */
  header_name: cstring,

  /* Header contents or NULL */
  header_data: cstring,
  header_length: c.size_t,
}

/* Callback for local file inclusion */
Glsl_Include_Local_Func :: #type proc(ctx: rawptr, header_name: cstring, includer_name: cstring, include_depth: c.size_t) -> ^Glsl_Include_Result

/* Callback for system file inclusion */
Glsl_Include_System_Func :: #type proc(ctx: rawptr, header_name: cstring, includer_name: cstring, include_depth: c.size_t) -> Glsl_Include_Result

/* Callback for include result destruction */
Glsl_Free_Include_Result_Func :: #type proc(ctx: rawptr, result: ^Glsl_Include_Result) -> c.int

/* Collection of callbacks for GLSL preprocessor */
Glsl_Include_Callbacks :: struct {
  include_system: Glsl_Include_System_Func,
  include_local: Glsl_Include_Local_Func,
  free_include_result: Glsl_Free_Include_Result_Func,
}

Input :: struct {
  language: Source,
  stage: Stage,
  client: Client,
  client_version: Target_Client_Version,
  target_language: Target_Language,
  target_language_version: Target_Language_Version,
  /** Shader source code */
  code: cstring,
  default_version: c.int,
  default_profile: Profile,
  force_default_version_and_profile: b32,
  forward_compatible: b32,
  messages: Messages,
  resource: ^Resource,
  callbacks: Glsl_Include_Callbacks,
  callbacks_ctx: rawptr,
}

/* SpvOptions counterpart */
Spv_Options :: struct {
  generate_debug_info: c.bool,
  strip_debug_info: c.bool,
  disable_optimizer: c.bool,
  optimize_size: c.bool,
  disassemble: c.bool,
  validate: c.bool,
  emit_nonsemantic_shader_debug_info: c.bool,
  emit_nonsemantic_shader_debug_source: c.bool,
  compile_only: c.bool,
  optimize_allow_expanded_id_bound: c.bool,
}
