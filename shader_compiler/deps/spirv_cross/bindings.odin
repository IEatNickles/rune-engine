package spirv_cross

when ODIN_OS == .Linux {
  foreign import spirv_cross {
    "system:spirv-cross-c-shared",
  }
} else when ODIN_OS == .Windows {
  foreign import spirv_cross "./spirv-cross-c-sharedd.lib"
}

Context :: distinct rawptr
Parsed_Ir :: distinct rawptr
Compiler :: distinct rawptr
Compiler_Options :: distinct rawptr
Resources :: distinct rawptr
Type :: distinct rawptr
Constant :: distinct rawptr
Set :: distinct rawptr

Type_Id     :: distinct Id
Variable_Id :: distinct Id
Constant_Id :: distinct Id

Reflected_Resource :: struct {
  id:           Variable_Id,
  base_type_id: Type_Id,
  type_id:      Type_Id,
  name:         cstring,
}

Reflected_Builtin_Resource :: struct {
  builtin:       BuiltIn,
  value_type_id: Type_Id,
  resource:      Reflected_Resource,
}

/* See C++ API. */
Entry_Point :: struct {
  execution_model: ExecutionModel,
  name:            cstring,
}

/* See C++ API. */
Combined_Image_Sampler :: struct {
  combined_id: Variable_Id,
  image_id:    Variable_Id,
  sampler_id:  Variable_Id,
}

/* See C++ API. */
Specialization_Constant :: struct {
  id:          Constant_Id,
  constant_id: u32,
}

/* See C++ API. */
Buffer_Range :: struct {
  index:  u32,
  offset: int,
  range:  int,
}

/* See C++ API. */
Hlsl_Root_Constants :: struct {
  start:   u32,
  end:     u32,
  binding: u32,
  space:   u32,
}

/* See C++ API. */
Hlsl_Vertex_Attribute_Remap :: struct {
  location: u32,
  semantic: cstring,
}

Result :: enum i32 {
  /* Success. */
  SUCCESS = 0,
  /* The SPIR-V is invalid. Should have been caught by validation ideally. */
  ERROR_INVALID_SPIRV = -1,
  /* The SPIR-V might be valid or invalid, but SPIRV-Cross currently cannot correctly translate this to your target language. */
  ERROR_UNSUPPORTED_SPIRV = -2,
  /* If for some reason we hit this, new or malloc failed. */
  ERROR_OUT_OF_MEMORY = -3,
  /* Invalid API argument. */
  ERROR_INVALID_ARGUMENT = -4,
}


Capture_Mode :: enum {
  /* The Parsed IR payload will be copied, and the handle can be reused to create other compiler instances. */
  COPY = 0,

  /*
   * The payload will now be owned by the compiler.
   * parsed_ir should now be considered a dead blob and must not be used further.
   * This is optimal for performance and should be the go-to option.
   */
  TAKE_OWNERSHIP = 1,
}

Backend :: enum {
  /* This backend can only perform reflection, no compiler options are supported. Maps to spirv_cross::Compiler. */
  NONE = 0,
  GLSL = 1, /* spirv_cross::CompilerGLSL */
  HLSL = 2, /* CompilerHLSL */
  MSL = 3, /* CompilerMSL */
  CPP = 4, /* CompilerCPP */
  JSON = 5, /* CompilerReflection w/ JSON backend */
}

/* Maps to C++ API. */
Resource_Type :: enum {
  UNKNOWN = 0,
  UNIFORM_BUFFER = 1,
  STORAGE_BUFFER = 2,
  STAGE_INPUT = 3,
  STAGE_OUTPUT = 4,
  SUBPASS_INPUT = 5,
  STORAGE_IMAGE = 6,
  SAMPLED_IMAGE = 7,
  ATOMIC_COUNTER = 8,
  PUSH_CONSTANT = 9,
  SEPARATE_IMAGE = 10,
  SEPARATE_SAMPLERS = 11,
  ACCELERATION_STRUCTURE = 12,
  RAY_QUERY = 13,
  SHADER_RECORD_BUFFER = 14,
  GL_PLAIN_UNIFORM = 15,
  TENSOR = 16,
}

Builtin_Resource_Type :: enum {
  UNKNOWN = 0,
  STAGE_INPUT = 1,
  STAGE_OUTPUT = 2,
}

/* Maps to spirv_cross::SPIRType::BaseType. */
Basetype :: enum {
  UNKNOWN = 0,
  VOID = 1,
  BOOLEAN = 2,
  INT8 = 3,
  UINT8 = 4,
  INT16 = 5,
  UINT16 = 6,
  INT32 = 7,
  UINT32 = 8,
  INT64 = 9,
  UINT64 = 10,
  ATOMIC_COUNTER = 11,
  FP16 = 12,
  FP32 = 13,
  FP64 = 14,
  STRUCT = 15,
  IMAGE = 16,
  SAMPLED_IMAGE = 17,
  SAMPLER = 18,
  ACCELERATION_STRUCTURE = 19,
}

SPVC_COMPILER_OPTION_COMMON_BIT :: 0x1000000
SPVC_COMPILER_OPTION_GLSL_BIT :: 0x2000000
SPVC_COMPILER_OPTION_HLSL_BIT :: 0x4000000
SPVC_COMPILER_OPTION_MSL_BIT :: 0x8000000
SPVC_COMPILER_OPTION_LANG_BITS :: 0x0f000000
SPVC_COMPILER_OPTION_ENUM_BITS :: 0xffffff

SPVC_MAKE_MSL_VERSION :: proc(major, minor, patch: int) -> int {
  return ((major) * 10000 + (minor) * 100 + (patch))
}

/* Maps to C++ API. */
Msl_Platform :: enum {
  IOS = 0,
  MACOS = 1,
}

/* Maps to C++ API. */
Msl_Index_Type :: enum {
  NONE = 0,
  UINT16 = 1,
  UINT32 = 2,
}

/* Maps to C++ API. */
Msl_Shader_Variable_Format :: enum {
  SHADER_VARIABLE_FORMAT_OTHER = 0,
  SHADER_VARIABLE_FORMAT_UINT8 = 1,
  SHADER_VARIABLE_FORMAT_UINT16 = 2,
  SHADER_VARIABLE_FORMAT_ANY16 = 3,
  SHADER_VARIABLE_FORMAT_ANY32 = 4,

  /* Deprecated names. */
  VERTEX_FORMAT_OTHER        = SHADER_VARIABLE_FORMAT_OTHER,
  VERTEX_FORMAT_UINT8        = SHADER_VARIABLE_FORMAT_UINT8,
  VERTEX_FORMAT_UINT16       = SHADER_VARIABLE_FORMAT_UINT16,
  SHADER_INPUT_FORMAT_OTHER  = SHADER_VARIABLE_FORMAT_OTHER,
  SHADER_INPUT_FORMAT_UINT8  = SHADER_VARIABLE_FORMAT_UINT8,
  SHADER_INPUT_FORMAT_UINT16 = SHADER_VARIABLE_FORMAT_UINT16,
  SHADER_INPUT_FORMAT_ANY16  = SHADER_VARIABLE_FORMAT_ANY16,
  SHADER_INPUT_FORMAT_ANY32  = SHADER_VARIABLE_FORMAT_ANY32,
}
Msl_Shader_Input_Format :: Msl_Shader_Variable_Format
Msl_Vertex_Format :: Msl_Shader_Variable_Format

/* Maps to C++ API. Deprecated; use Msl_Shader_Interface_Var. */
Msl_Vertex_Attribute :: struct {
  location: u32,

  /* Obsolete, do not use. Only lingers on for ABI compatibility. */
  msl_buffer: u32,
  /* Obsolete, do not use. Only lingers on for ABI compatibility. */
  msl_offset: u32,
  /* Obsolete, do not use. Only lingers on for ABI compatibility. */
  msl_stride: u32,
  /* Obsolete, do not use. Only lingers on for ABI compatibility. */
  per_instance: bool,

  format: Msl_Vertex_Format,
  builtin: BuiltIn,
}

/* Maps to C++ API. Deprecated; use Msl_Shader_Interface_Var_2. */
Msl_Shader_Interface_Var :: struct {
  location: u32,
  format: Msl_Vertex_Format,
  builtin: BuiltIn,
  vecsize: u32,
}
Msl_Shader_Input :: Msl_Shader_Interface_Var

/* Maps to C++ API. */
Msl_Shader_Variable_Rate :: enum {
  PER_VERTEX = 0,
  PER_PRIMITIVE = 1,
  PER_PATCH = 2,
}

/* Maps to C++ API. */
Msl_Shader_Interface_Var_2 :: struct {
  location: u32,
  format: Msl_Shader_Variable_Format,
  builtin: BuiltIn ,
  vecsize: u32,
  rate: Msl_Shader_Variable_Rate,
}

/* Maps to C++ API.
 * Deprecated. Use Msl_Resource_Binding_2. */
Msl_Resource_Binding :: struct {
  stage: ExecutionModel,
  desc_set: u32,
  binding: u32,
  msl_buffer: u32,
  msl_texture: u32,
  msl_sampler: u32,
}

Msl_Resource_Binding_2 :: struct {
  stage: ExecutionModel,
  desc_set: u32,
  binding: u32,
  count: u32,
  msl_buffer: u32,
  msl_texture: u32,
  msl_sampler: u32,
}

SPVC_MSL_PUSH_CONSTANT_DESC_SET :: ~u32(0)
SPVC_MSL_PUSH_CONSTANT_BINDING :: 0
SPVC_MSL_SWIZZLE_BUFFER_BINDING :: ~u32(1)
SPVC_MSL_BUFFER_SIZE_BUFFER_BINDING :: ~u32(2)
SPVC_MSL_ARGUMENT_BUFFER_BINDING :: ~u32(3)

/* Obsolete. Sticks around for backwards compatibility. */
SPVC_MSL_AUX_BUFFER_STRUCT_VERSION :: 1

/* Maps to C++ API. */
Msl_Sampler_Coord :: enum {
  NORMALIZED = 0,
  PIXEL = 1,
}

/* Maps to C++ API. */
Msl_Sampler_Filter :: enum {
  NEAREST = 0,
  LINEAR = 1,
}

/* Maps to C++ API. */
Msl_Sampler_Mip_Filter :: enum {
  NONE = 0,
  NEAREST = 1,
  LINEAR = 2,
}

/* Maps to C++ API. */
Msl_Sampler_Address :: enum {
  CLAMP_TO_ZERO = 0,
  CLAMP_TO_EDGE = 1,
  CLAMP_TO_BORDER = 2,
  REPEAT = 3,
  MIRRORED_REPEAT = 4,
}

/* Maps to C++ API. */
Msl_Sampler_Compare_Func :: enum {
  NEVER = 0,
  LESS = 1,
  LESS_EQUAL = 2,
  GREATER = 3,
  GREATER_EQUAL = 4,
  EQUAL = 5,
  NOT_EQUAL = 6,
  ALWAYS = 7,
}

/* Maps to C++ API. */
Msl_Sampler_Border_Color :: enum {
  TRANSPARENT_BLACK = 0,
  OPAQUE_BLACK = 1,
  OPAQUE_WHITE = 2,
}

/* Maps to C++ API. */
Msl_Format_Resolution :: enum {
  _444 = 0,
  _422,
  _420,
}

/* Maps to C++ API. */
Msl_Chroma_Location :: enum {
  COSITED_EVEN = 0,
  MIDPOINT,
}

/* Maps to C++ API. */
Msl_Component_Swizzle :: enum {
  IDENTITY = 0,
  ZERO,
  ONE,
  R,
  G,
  B,
  A,
}

/* Maps to C++ API. */
Msl_Sampler_Ycbcr_Model_Conversion :: enum {
  RGB_IDENTITY = 0,
  YCBCR_IDENTITY,
  YCBCR_BT_709,
  YCBCR_BT_601,
  YCBCR_BT_2020,
}

/* Maps to C+ API. */
Msl_Sampler_Ycbcr_Range :: enum {
  ITU_FULL = 0,
  ITU_NARROW,
}

/* Maps to C++ API. */
Msl_Constexpr_Sampler :: struct {
  coord: Msl_Sampler_Coord,
  min_filter: Msl_Sampler_Filter,
  mag_filter: Msl_Sampler_Filter,
  mip_filter: Msl_Sampler_Mip_Filter,
  s_address: Msl_Sampler_Address,
  t_address: Msl_Sampler_Address,
  r_address: Msl_Sampler_Address,
  compare_func: Msl_Sampler_Compare_Func,
  border_color: Msl_Sampler_Border_Color,
  lod_clamp_min: f32,
  lod_clamp_max: f32,
  max_anisotropy: int,

  compare_enable: bool,
  lod_clamp_enable: bool,
  anisotropy_enable: bool,
}

/* Maps to the sampler Y'CbCr conversion-related portions of MSLConstexprSampler. See C++ API for defaults and details. */
Msl_Sampler_Ycbcr_Conversion :: struct {
  planes: u32,
  resolution: Msl_Format_Resolution,
  chroma_filter: Msl_Sampler_Filter,
  x_chroma_offset: Msl_Chroma_Location,
  y_chroma_offset: Msl_Chroma_Location,
  swizzle: [4]Msl_Component_Swizzle,
  ycbcr_model: Msl_Sampler_Ycbcr_Model_Conversion,
  ycbcr_range: Msl_Sampler_Ycbcr_Range,
  bpc: u32,
}

/* Maps to C++ API. */
Hlsl_Binding_Flags :: bit_set[Hlsl_Binding_Flag_Bits]
Hlsl_Binding_Flag_Bits :: enum {
  PUSH_CONSTANT = 0,
  CBV = 1,
  SRV = 2,
  UAV = 3,
  SAMPLER = 4,
}

SPVC_HLSL_PUSH_CONSTANT_DESC_SET :: ~u32(0)
SPVC_HLSL_PUSH_CONSTANT_BINDING  :: 0

/* Maps to C++ API. */
Hlsl_Resource_Binding_Mapping :: struct {
  register_space: u32,
  register_binding: u32,
}

Hlsl_Resource_Binding :: struct {
  stage: ExecutionModel,
  desc_set: u32,
  binding: u32,

  cbv, uav, srv, sampler: Hlsl_Resource_Binding_Mapping,
}

/* Maps to the various spirv_cross::Compiler*::Option structures. See C++ API for defaults and details. */
Compiler_Option :: enum {
  UNKNOWN = 0,


  // Debug option to always emit temporary variables for all expressions.
  FORCE_TEMPORARY = 1 | SPVC_COMPILER_OPTION_COMMON_BIT,

  // Flattens multidimensional arrays, e.g. float foo[a][b][c] into single-dimensional arrays,
  // e.g. float foo[a * b * c].
  // This function does not change the actual SPIRType of any object.
  // Only the generated code, including declarations of interface variables are changed to be single array dimension.
  FLATTEN_MULTIDIMENSIONAL_ARRAYS = 2 | SPVC_COMPILER_OPTION_COMMON_BIT,

  FIXUP_DEPTH_CONVENTION = 3 | SPVC_COMPILER_OPTION_COMMON_BIT,

  // In vertex-like shaders, inverts gl_Position.y or equivalent.
  FLIP_VERTEX_Y = 4 | SPVC_COMPILER_OPTION_COMMON_BIT,

  GLSL_SUPPORT_NONZERO_BASE_INSTANCE = 5 | SPVC_COMPILER_OPTION_GLSL_BIT,

  // If true, gl_PerVertex is explicitly redeclared in vertex, geometry and tessellation shaders.
  // The members of gl_PerVertex is determined by which built-ins are declared by the shader.
  // This option is ignored in ES versions, as redeclaration in ES is not required, and it depends on a different extension
  // (EXT_shader_io_blocks) which makes things a bit more fuzzy.
  GLSL_SEPARATE_SHADER_OBJECTS = 6 | SPVC_COMPILER_OPTION_GLSL_BIT,

  // For older desktop GLSL targets than version 420, the
  // GL_ARB_shading_language_420pack extensions is used to be able to support
  // layout(binding) on UBOs and samplers.
  // If disabled on older targets, binding decorations will be stripped.
  GLSL_ENABLE_420PACK_EXTENSION = 7 | SPVC_COMPILER_OPTION_GLSL_BIT,

  // The shading language version. Corresponds to #version $VALUE.
  GLSL_VERSION = 8 | SPVC_COMPILER_OPTION_GLSL_BIT,

  // Emit the OpenGL ES shading language instead of desktop OpenGL.
  GLSL_ES = 9 | SPVC_COMPILER_OPTION_GLSL_BIT,

  // If true, Vulkan GLSL features are used instead of GL-compatible features.
  // Mostly useful for debugging SPIR-V files.
  GLSL_VULKAN_SEMANTICS = 10 | SPVC_COMPILER_OPTION_GLSL_BIT,

  GLSL_ES_DEFAULT_FLOAT_PRECISION_HIGHP = 11 | SPVC_COMPILER_OPTION_GLSL_BIT,
  GLSL_ES_DEFAULT_INT_PRECISION_HIGHP = 12 | SPVC_COMPILER_OPTION_GLSL_BIT,

  HLSL_SHADER_MODEL = 13 | SPVC_COMPILER_OPTION_HLSL_BIT,

  // Allows the PointSize builtin in SM 4.0+, and ignores it, as PointSize is not supported in SM 4+.
  HLSL_POINT_SIZE_COMPAT = 14 | SPVC_COMPILER_OPTION_HLSL_BIT,

  // Allows the PointCoord builtin, returns float2(0.5, 0.5), as PointCoord is not supported in HLSL.
  HLSL_POINT_COORD_COMPAT = 15 | SPVC_COMPILER_OPTION_HLSL_BIT,

  // If true, the backend will assume that VertexIndex and InstanceIndex will need to apply
  // a base offset, and you will need to fill in a cbuffer with offsets.
  // Set to false if you know you will never use base instance or base vertex
  // functionality as it might remove an internal cbuffer.
  HLSL_SUPPORT_NONZERO_BASE_VERTEX_BASE_INSTANCE = 16 | SPVC_COMPILER_OPTION_HLSL_BIT,

  MSL_VERSION = 17 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_TEXEL_BUFFER_TEXTURE_WIDTH = 18 | SPVC_COMPILER_OPTION_MSL_BIT,

  /* Obsolete, use SWIZZLE_BUFFER_INDEX instead. */
  MSL_AUX_BUFFER_INDEX = 19 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_SWIZZLE_BUFFER_INDEX = 19 | SPVC_COMPILER_OPTION_MSL_BIT,

  MSL_INDIRECT_PARAMS_BUFFER_INDEX = 20 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_SHADER_OUTPUT_BUFFER_INDEX = 21 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_SHADER_PATCH_OUTPUT_BUFFER_INDEX = 22 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_SHADER_TESS_FACTOR_OUTPUT_BUFFER_INDEX = 23 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_SHADER_INPUT_WORKGROUP_INDEX = 24 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_ENABLE_POINT_SIZE_BUILTIN = 25 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_DISABLE_RASTERIZATION = 26 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_CAPTURE_OUTPUT_TO_BUFFER = 27 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_SWIZZLE_TEXTURE_SAMPLES = 28 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_PAD_FRAGMENT_OUTPUT_COMPONENTS = 29 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_TESS_DOMAIN_ORIGIN_LOWER_LEFT = 30 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_PLATFORM = 31 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_ARGUMENT_BUFFERS = 32 | SPVC_COMPILER_OPTION_MSL_BIT,

  // In non-Vulkan GLSL, emit push constant blocks as UBOs rather than plain uniforms.
  GLSL_EMIT_PUSH_CONSTANT_AS_UNIFORM_BUFFER = 33 | SPVC_COMPILER_OPTION_GLSL_BIT,

  MSL_TEXTURE_BUFFER_NATIVE = 34 | SPVC_COMPILER_OPTION_MSL_BIT,

  // Always emit uniform blocks as plain uniforms, regardless of the GLSL version, even when UBOs are supported.
  // Does not apply to shader storage or push constant blocks.
  GLSL_EMIT_UNIFORM_BUFFER_AS_PLAIN_UNIFORMS = 35 | SPVC_COMPILER_OPTION_GLSL_BIT,

  MSL_BUFFER_SIZE_BUFFER_INDEX = 36 | SPVC_COMPILER_OPTION_MSL_BIT,

  // Emit OpLine directives if present in the module.
  // May not correspond exactly to original source, but should be a good approximation.
  EMIT_LINE_DIRECTIVES = 37 | SPVC_COMPILER_OPTION_COMMON_BIT,

  MSL_MULTIVIEW = 38 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_VIEW_MASK_BUFFER_INDEX = 39 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_DEVICE_INDEX = 40 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_VIEW_INDEX_FROM_DEVICE_INDEX = 41 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_DISPATCH_BASE = 42 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_DYNAMIC_OFFSETS_BUFFER_INDEX = 43 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_TEXTURE_1D_AS_2D = 44 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_ENABLE_BASE_INDEX_ZERO = 45 | SPVC_COMPILER_OPTION_MSL_BIT,

  /* Obsolete. Use MSL_FRAMEBUFFER_FETCH_SUBPASS instead. */
  MSL_IOS_FRAMEBUFFER_FETCH_SUBPASS = 46 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_FRAMEBUFFER_FETCH_SUBPASS = 46 | SPVC_COMPILER_OPTION_MSL_BIT,

  MSL_INVARIANT_FP_MATH = 47 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_EMULATE_CUBEMAP_ARRAY = 48 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_ENABLE_DECORATION_BINDING = 49 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_FORCE_ACTIVE_ARGUMENT_BUFFER_RESOURCES = 50 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_FORCE_NATIVE_ARRAYS = 51 | SPVC_COMPILER_OPTION_MSL_BIT,

  ENABLE_STORAGE_IMAGE_QUALIFIER_DEDUCTION = 52 | SPVC_COMPILER_OPTION_COMMON_BIT,

  HLSL_FORCE_STORAGE_BUFFER_AS_UAV = 53 | SPVC_COMPILER_OPTION_HLSL_BIT,

  // On some targets (WebGPU), uninitialized variables are banned.
  // If this is enabled, all variables (temporaries, Private, Function)
  // which would otherwise be uninitialized will now be initialized to 0 instead.
  FORCE_ZERO_INITIALIZED_VARIABLES = 54 | SPVC_COMPILER_OPTION_COMMON_BIT,

  HLSL_NONWRITABLE_UAV_TEXTURE_AS_SRV = 55 | SPVC_COMPILER_OPTION_HLSL_BIT,

  MSL_ENABLE_FRAG_OUTPUT_MASK = 56 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_ENABLE_FRAG_DEPTH_BUILTIN = 57 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_ENABLE_FRAG_STENCIL_REF_BUILTIN = 58 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_ENABLE_CLIP_DISTANCE_USER_VARYING = 59 | SPVC_COMPILER_OPTION_MSL_BIT,

  HLSL_ENABLE_16BIT_TYPES = 60 | SPVC_COMPILER_OPTION_HLSL_BIT,

  MSL_MULTI_PATCH_WORKGROUP = 61 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_SHADER_INPUT_BUFFER_INDEX = 62 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_SHADER_INDEX_BUFFER_INDEX = 63 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_VERTEX_FOR_TESSELLATION = 64 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_VERTEX_INDEX_TYPE = 65 | SPVC_COMPILER_OPTION_MSL_BIT,

  // In GLSL, force use of I/O block flattening, similar to
  // what happens on legacy GLSL targets for blocks and structs.
  GLSL_FORCE_FLATTENED_IO_BLOCKS = 66 | SPVC_COMPILER_OPTION_GLSL_BIT,

  MSL_MULTIVIEW_LAYERED_RENDERING = 67 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_ARRAYED_SUBPASS_INPUT = 68 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_R32UI_LINEAR_TEXTURE_ALIGNMENT = 69 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_R32UI_ALIGNMENT_CONSTANT_ID = 70 | SPVC_COMPILER_OPTION_MSL_BIT,

  HLSL_FLATTEN_MATRIX_VERTEX_INPUT_SEMANTICS = 71 | SPVC_COMPILER_OPTION_HLSL_BIT,

  MSL_IOS_USE_SIMDGROUP_FUNCTIONS = 72 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_EMULATE_SUBGROUPS = 73 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_FIXED_SUBGROUP_SIZE = 74 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_FORCE_SAMPLE_RATE_SHADING = 75 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_IOS_SUPPORT_BASE_VERTEX_INSTANCE = 76 | SPVC_COMPILER_OPTION_MSL_BIT,

  // If non-zero, controls layout(num_views = N) in; in GL_OVR_multiview2.
  GLSL_OVR_MULTIVIEW_VIEW_COUNT = 77 | SPVC_COMPILER_OPTION_GLSL_BIT,

  // For opcodes where we have to perform explicit additional nan checks, very ugly code is generated.
  // If we opt-in, ignore these requirements.
  // In opcodes like NClamp/NMin/NMax and FP compare, ignore NaN behavior.
  // Use FClamp/FMin/FMax semantics for clamps and lets implementation choose ordered or unordered
  // compares.
  RELAX_NAN_CHECKS = 78 | SPVC_COMPILER_OPTION_COMMON_BIT,

  MSL_RAW_BUFFER_TESE_INPUT = 79 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_SHADER_PATCH_INPUT_BUFFER_INDEX = 80 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_MANUAL_HELPER_INVOCATION_UPDATES = 81 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_CHECK_DISCARDED_FRAG_STORES = 82 | SPVC_COMPILER_OPTION_MSL_BIT,

  // Loading row-major matrices from UBOs on older AMD Windows OpenGL drivers is problematic.
  // To load these types correctly, we must generate a wrapper. them in a dummy function which only purpose is to
  // ensure row_major decoration is actually respected.
  // This workaround may cause significant performance degeneration on some Android devices.
  GLSL_ENABLE_ROW_MAJOR_LOAD_WORKAROUND = 83 | SPVC_COMPILER_OPTION_GLSL_BIT,

  MSL_ARGUMENT_BUFFERS_TIER = 84 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_SAMPLE_DREF_LOD_ARRAY_AS_GRAD = 85 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_READWRITE_TEXTURE_FENCES = 86 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_REPLACE_RECURSIVE_INPUTS = 87 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_AGX_MANUAL_CUBE_GRAD_FIXUP = 88 | SPVC_COMPILER_OPTION_MSL_BIT,
  MSL_FORCE_FRAGMENT_WITH_SIDE_EFFECTS_EXECUTION = 89 | SPVC_COMPILER_OPTION_MSL_BIT,

  // Emit the entry point name in SPIR-V rather than "main".
  HLSL_USE_ENTRY_POINT_NAME = 90 | SPVC_COMPILER_OPTION_HLSL_BIT,
  HLSL_PRESERVE_STRUCTURED_BUFFERS = 91 | SPVC_COMPILER_OPTION_HLSL_BIT,

  MSL_AUTO_DISABLE_RASTERIZATION = 92 | SPVC_COMPILER_OPTION_MSL_BIT,

  MSL_ENABLE_POINT_SIZE_DEFAULT = 93 | SPVC_COMPILER_OPTION_MSL_BIT,

  HLSL_USER_SEMANTIC = 94 | SPVC_COMPILER_OPTION_HLSL_BIT,
}

Error_Callback :: #type proc "c" (userdata: rawptr, error: cstring)

@(default_calling_convention="c", link_prefix="spvc_")
foreign spirv_cross {
/*
 * Context is the highest-level API construct.
 * The context owns all memory allocations made by its child object hierarchy, including various non-opaque structs and strings.
 * This means that the API user only has to care about one "destroy" call ever when using the C API.
 * All pointers handed out by the APIs are only valid as long as the context
 * is alive and Context_Release_Allocations has not been called.
 */
context_create :: proc(_context: ^Context) -> Result  ---

/* Frees all memory allocations and objects associated with the context and its child objects. */
context_destroy :: proc(_context: Context) ---

/* Frees all memory allocations and objects associated with the context and its child objects, but keeps the context alive. */
context_release_allocations :: proc(_context: Context) ---

/* Get the string for the last error which was logged. */
context_get_last_error_string :: proc(_context: Context) -> cstring ---

/* Get notified in a callback when an error triggers. Useful for debugging. */
context_set_error_callback :: proc(_context: Context, cb: Error_Callback, userdata: rawptr) ---

/* SPIR-V parsing interface. Maps to Parser which then creates a ParsedIR, and that IR is extracted into the handle. */
context_parse_spirv :: proc(_context: Context, spirv: [^]u32, word_count: int, parsed_ir: ^Parsed_Ir) -> Result  ---

/*
 * Create a compiler backend. Capture mode controls if we construct by copy or move semantics.
 * It is always recommended to use SPVC_CAPTURE_MODE_TAKE_OWNERSHIP if you only intend to cross-compile the IR once.
 */
context_create_compiler :: proc(_context: Context, backend: Backend, parsed_ir: Parsed_Ir, mode: Capture_Mode, compiler: ^Compiler) -> Result  ---

/* Maps directly to C++ API. */
compiler_get_current_id_bound :: proc(compiler: Compiler) -> u32 ---

/* Create compiler options, which will initialize defaults. */
compiler_create_compiler_options :: proc(compiler: Compiler, options: ^Compiler_Options) -> Result  ---
/* Override options. Will return error if e.g. MSL options are used for the HLSL backend, etc. */
compiler_options_set_bool :: proc(options: Compiler_Options, option: Compiler_Option, value: bool) -> Result  ---
compiler_options_set_uint :: proc(options: Compiler_Options, option: Compiler_Option, value: u32) -> Result  ---
/* Set compiler options. */
compiler_install_compiler_options :: proc(compiler: Compiler, options: Compiler_Options) -> Result  ---

/* Compile IR into a string. *source is owned by the context, and caller must not free it themselves. */
compiler_compile :: proc(compiler: Compiler, source: ^cstring) -> Result  ---

/* Maps to C++ API. */
compiler_add_header_line :: proc(compiler: Compiler , line: cstring) -> Result  ---
compiler_require_extension :: proc(compiler: Compiler, ext: cstring) -> Result  ---
compiler_get_num_required_extensions :: proc(compiler: Compiler) -> int ---
compiler_get_required_extension :: proc(compiler: Compiler, index: int) -> cstring ---
compiler_flatten_buffer_block :: proc(compiler: Compiler, id: Variable_Id) -> Result  ---

compiler_variable_is_depth_or_compare :: proc(compiler: Compiler, id: Variable_Id) -> bool  ---

compiler_mask_stage_output_by_location :: proc(compiler: Compiler, location: u32, component: u32) -> Result ---
compiler_mask_stage_output_by_builtin :: proc(compiler: Compiler, builtin: BuiltIn) -> Result  ---

/*
 * HLSL specifics.
 * Maps to C++ API.
 */
compiler_hlsl_set_root_constants_layout :: proc(compiler: Compiler, constant_info: ^Hlsl_Root_Constants, count: int) -> Result  ---
compiler_hlsl_add_vertex_attribute_remap :: proc(compiler: Compiler, remap: ^Hlsl_Vertex_Attribute_Remap, remaps: int) -> Result  ---
compiler_hlsl_remap_num_workgroups_builtin :: proc(compiler: Compiler) -> Variable_Id  ---

compiler_hlsl_set_resource_binding_flags :: proc(compiler: Compiler, flags: Hlsl_Binding_Flags ) -> Result  ---

compiler_hlsl_add_resource_binding :: proc(compiler: Compiler, binding: ^Hlsl_Resource_Binding) -> Result  ---
compiler_hlsl_is_resource_used :: proc(compiler: Compiler, model: ExecutionModel, set: u32, binding: u32) -> bool  ---

/*
 * MSL specifics.
 * Maps to C++ API.
 */
compiler_msl_is_rasterization_disabled :: proc(compiler: Compiler) -> bool  ---

/* Obsolete. Renamed to needs_swizzle_buffer. */
compiler_msl_needs_aux_buffer :: proc(compiler: Compiler) -> bool  ---
compiler_msl_needs_swizzle_buffer :: proc(compiler: Compiler) -> bool  ---
compiler_msl_needs_buffer_size_buffer :: proc(compiler: Compiler) -> bool  ---

compiler_msl_needs_output_buffer :: proc(compiler: Compiler) -> bool  ---
compiler_msl_needs_patch_output_buffer :: proc(compiler: Compiler) -> bool  ---
compiler_msl_needs_input_threadgroup_mem :: proc(compiler: Compiler) -> bool  ---
compiler_msl_add_vertex_attribute :: proc(compiler: Compiler, attrs: ^Msl_Vertex_Attribute) -> Result  ---
/* Deprecated; use Compiler_msl_add_resource_binding_2(). */
compiler_msl_add_resource_binding :: proc(compiler: Compiler, binding: ^Msl_Resource_Binding) -> Result  ---
compiler_msl_add_resource_binding_2 :: proc(compiler: Compiler, binding: ^Msl_Resource_Binding_2) -> Result  ---
/* Deprecated; use Compiler_msl_add_shader_input_2(). */
compiler_msl_add_shader_input :: proc(compiler: Compiler, input: ^Msl_Shader_Interface_Var) -> Result  ---
compiler_msl_add_shader_input_2 :: proc(compiler: Compiler, input: ^Msl_Shader_Interface_Var_2) -> Result  ---
/* Deprecated; use Compiler_msl_add_shader_output_2(). */
compiler_msl_add_shader_output :: proc(compiler: Compiler, output: ^Msl_Shader_Interface_Var) -> Result  ---
compiler_msl_add_shader_output_2 :: proc(compiler: Compiler, output: ^Msl_Shader_Interface_Var_2) -> Result  ---
compiler_msl_add_discrete_descriptor_set :: proc(compiler: Compiler, desc_set: u32) -> Result  ---
compiler_msl_set_argument_buffer_device_address_space :: proc(compiler: Compiler, desc_set: u32, device_address: bool) -> Result  ---

/* Obsolete, use is_shader_input_used. */
compiler_msl_is_vertex_attribute_used :: proc(compiler: Compiler, location: u32) -> bool  ---
compiler_msl_is_shader_input_used :: proc(compiler: Compiler, location: u32) -> bool  ---
compiler_msl_is_shader_output_used :: proc(compiler: Compiler, location: u32) -> bool  ---

compiler_msl_is_resource_used :: proc(compiler: Compiler, model: ExecutionModel , set: u32, binding: u32) -> bool  ---
compiler_msl_remap_constexpr_sampler :: proc(compiler: Compiler, id: Variable_Id, sampler: ^Msl_Constexpr_Sampler) -> Result  ---
compiler_msl_remap_constexpr_sampler_by_binding :: proc(compiler: Compiler, desc_set: u32, binding: u32, sampler: ^Msl_Constexpr_Sampler) -> Result  ---
compiler_msl_remap_constexpr_sampler_ycbcr :: proc(compiler: Compiler, id: Variable_Id, sampler: ^Msl_Constexpr_Sampler, conv: ^Msl_Sampler_Ycbcr_Conversion) -> Result  ---
compiler_msl_remap_constexpr_sampler_by_binding_ycbcr :: proc(compiler: Compiler, desc_set: u32, binding: u32, sampler: ^Msl_Constexpr_Sampler, conv: ^Msl_Sampler_Ycbcr_Conversion) -> Result  ---
compiler_msl_set_fragment_output_components :: proc(compiler: Compiler, location: u32, components: u32) -> Result  ---

compiler_msl_get_automatic_resource_binding :: proc(compiler: Compiler, id: Variable_Id) -> u32 ---
compiler_msl_get_automatic_resource_binding_secondary :: proc(compiler: Compiler, id: Variable_Id) -> u32 ---

compiler_msl_add_dynamic_buffer :: proc(compiler: Compiler, desc_set: u32, binding: u32, index: u32) -> Result  ---

compiler_msl_add_inline_uniform_block :: proc(compiler: Compiler, desc_set: u32, binding: u32) -> Result  ---

compiler_msl_set_combined_sampler_suffix :: proc(compiler: Compiler, suffix: cstring) -> Result  ---
compiler_msl_get_combined_sampler_suffix :: proc(compiler: Compiler) -> cstring ---

/*
 * Reflect resources.
 * Maps almost 1:1 to C++ API.
 */
compiler_get_active_interface_variables :: proc(compiler: Compiler, set: ^Set) -> Result  ---
compiler_set_enabled_interface_variables :: proc(compiler: Compiler, set: Set) -> Result  ---
compiler_create_shader_resources :: proc(compiler: Compiler, resources: ^Resources) -> Result  ---
compiler_create_shader_resources_for_active_variables :: proc(compiler: Compiler, resources: ^Resources, active: Set) -> Result  ---
resources_get_resource_list_for_type :: proc(resources: Resources, type: Resource_Type, resource_list: ^[^]Reflected_Resource, resource_size: ^int) -> Result  ---

resources_get_builtin_resource_list_for_type :: proc(resources: Resources, type: Builtin_Resource_Type, resource_list: ^[^]Reflected_Builtin_Resource, resource_size: ^int) -> Result  ---

/*
 * Decorations.
 * Maps to C++ API.
 */
compiler_set_decoration :: proc(compiler: Compiler, id: Id, decoration: Decoration, argument: u32) ---
compiler_set_decoration_string :: proc(compiler: Compiler, id: Id, decoration: Decoration, argument: cstring) ---
compiler_set_name :: proc(compiler: Compiler, id: Id, argument: cstring) ---
compiler_set_member_decoration :: proc(compiler: Compiler, id: Type_Id, member_index: u32, decoration: Decoration, argument: u32) ---
compiler_set_member_decoration_string :: proc(compiler: Compiler, id: Type_Id, member_index: u32, decoration: Decoration, argument: cstring) ---
compiler_set_member_name :: proc(compiler: Compiler, id: Type_Id, member_index: u32, argument: cstring) ---
compiler_unset_decoration :: proc(compiler: Compiler, id: Id, decoration: Decoration) ---
compiler_unset_member_decoration :: proc(compiler: Compiler, id: Type_Id, member_index: u32, decoration: Decoration) ---

compiler_has_decoration :: proc(compiler: Compiler, id: Id, decoration: Decoration) -> bool  ---
compiler_has_member_decoration :: proc(compiler: Compiler, id: Type_Id, member_index: u32, decoration: Decoration) -> bool  ---
compiler_get_name :: proc(compiler: Compiler, id: Id) -> cstring ---
compiler_get_decoration :: proc(compiler: Compiler, id: Id, decoration: Decoration) -> u32 ---
compiler_get_decoration_string :: proc(compiler: Compiler, id: Id, decoration: Decoration) -> cstring ---
compiler_get_member_decoration :: proc(compiler: Compiler, id: Type_Id, member_index: u32, decoration: Decoration) -> u32 ---
compiler_get_member_decoration_string :: proc(compiler: Compiler, id: Type_Id, member_index: u32, decoration: Decoration) -> cstring ---
compiler_get_member_name :: proc(compiler: Compiler, id: Type_Id, member_index: u32) -> cstring ---

/*
 * Entry points.
 * Maps to C++ API.
 */
compiler_get_entry_points :: proc(compiler: Compiler, entry_points: ^[^]Entry_Point, num_entry_points: ^int) -> Result  ---
compiler_set_entry_point :: proc(compiler: Compiler, name: cstring, model: ExecutionModel) -> Result  ---
compiler_rename_entry_point :: proc(compiler: Compiler, old_name: cstring, new_name: cstring, model: ExecutionModel) -> Result  ---
compiler_get_cleansed_entry_point_name :: proc(compiler: Compiler, name: cstring, model: ExecutionModel) -> cstring ---
compiler_set_execution_mode :: proc(compiler: Compiler, mode: ExecutionMode) ---
compiler_unset_execution_mode :: proc(compiler: Compiler, mode: ExecutionMode) ---
compiler_set_execution_mode_with_arguments :: proc(compiler: Compiler, mode: ExecutionMode, arg0: u32, arg1: u32, arg2: u32) ---
compiler_get_execution_modes :: proc(compiler: Compiler, modes: ^[^]ExecutionMode, num_modes: ^int) -> Result  ---
compiler_get_execution_mode_argument :: proc(compiler: Compiler, mode: ExecutionMode) -> u32 ---
compiler_get_execution_mode_argument_by_index :: proc(compiler: Compiler, mode: ExecutionMode, index: u32) -> u32 ---
compiler_get_execution_model :: proc(compiler: Compiler) -> ExecutionModel  ---
compiler_update_active_builtins :: proc(compiler: Compiler) ---
compiler_has_active_builtin :: proc(compiler: Compiler, builtin: BuiltIn, storage: StorageClass) -> bool  ---

/*
 * Type query interface.
 * Maps to C++ API, except it's read-only.
 */
compiler_get_type_handle :: proc(compiler: Compiler, id: Type_Id) -> Type  ---

/* Pulls out SPIRType::self. This effectively gives the type ID without array or pointer qualifiers.
 * This is necessary when reflecting decoration/name information on members of a struct,
 * which are placed in the base type, not the qualified type.
 * This is similar to Reflected_Resource::base_type_id. */
type_get_base_type_id :: proc(type: Type) -> Type_Id  ---

type_get_basetype :: proc(type: Type) -> Basetype  ---
type_get_bit_width :: proc(type: Type) -> u32 ---
type_get_vector_size :: proc(type: Type) -> u32 ---
type_get_columns :: proc(type: Type) -> u32 ---
type_get_num_array_dimensions :: proc(type: Type) -> u32 ---
type_array_dimension_is_literal :: proc(type: Type, dimension: u32) -> bool  ---
type_get_array_dimension :: proc(type: Type, dimension: u32) -> Id  ---
type_get_num_member_types :: proc(type: Type) -> u32 ---
type_get_member_type :: proc(type: Type, index: u32) -> Type_Id  ---
type_get_storage_class :: proc(type: Type) -> StorageClass  ---

/* Image type query. */
type_get_image_sampled_type :: proc(type: Type) -> Type_Id  ---
type_get_image_dimension :: proc(type: Type) -> Dim  ---
type_get_image_is_depth :: proc(type: Type) -> bool  ---
type_get_image_arrayed :: proc(type: Type) -> bool  ---
type_get_image_multisampled :: proc(type: Type) -> bool  ---
type_get_image_is_storage :: proc(type: Type) -> bool  ---
type_get_image_storage_format :: proc(type: Type) -> ImageFormat  ---
type_get_image_access_qualifier :: proc(type: Type) -> AccessQualifier  ---

/*
 * Buffer layout query.
 * Maps to C++ API.
 */
compiler_get_declared_struct_size :: proc(compiler: Compiler, struct_type: Type, size: ^int) -> Result  ---
compiler_get_declared_struct_size_runtime_array :: proc(compiler: Compiler, struct_type: Type, array_size: int, size: ^int) -> Result  ---
compiler_get_declared_struct_member_size :: proc(compiler: Compiler, type: Type, index: u32, size: ^int) -> Result  ---

compiler_type_struct_member_offset :: proc(compiler: Compiler, type: Type, index: u32, offset: ^u32) -> Result  ---
compiler_type_struct_member_array_stride :: proc(compiler: Compiler, type: Type, index: u32, stride: ^u32) -> Result  ---
compiler_type_struct_member_matrix_stride :: proc(compiler: Compiler, type: Type, index: u32, stride: ^u32) -> Result  ---

/*
 * Workaround helper functions.
 * Maps to C++ API.
 */
compiler_build_dummy_sampler_for_combined_images :: proc(compiler: Compiler, id: ^Variable_Id) -> Result  ---
compiler_build_combined_image_samplers :: proc(compiler: Compiler) -> Result  ---
compiler_get_combined_image_samplers :: proc(compiler: Compiler, samplers: ^[^]Combined_Image_Sampler, num_samplers: ^int) -> Result  ---

/*
 * Constants
 * Maps to C++ API.
 */
compiler_get_specialization_constants :: proc(compiler: Compiler, constants: ^[^]Specialization_Constant, num_constants: ^int) -> Result  ---
compiler_get_constant_handle :: proc(compiler: Compiler, id: Constant_Id) -> Constant  ---

compiler_get_work_group_size_specialization_constants :: proc(compiler: Compiler, x: ^Specialization_Constant, y: ^Specialization_Constant, z: ^Specialization_Constant) -> Constant_Id  ---

/*
 * Buffer ranges
 * Maps to C++ API.
 */
compiler_get_active_buffer_ranges :: proc(compiler: Compiler, id: Variable_Id, ranges: ^[^]Buffer_Range, num_ranges: ^int) -> Result  ---

/*
 * No stdint.h until C99, sigh :(
 * For smaller types, the result is sign or zero-extended as appropriate.
 * Maps to C++ API.
 * TODO: The SPIRConstant query interface and modification interface is not quite complete.
 */
constant_get_scalar_fp16 :: proc(constant: Constant, column: u32, row: u32) -> f32  ---
constant_get_scalar_fp32 :: proc(constant: Constant, column: u32, row: u32) -> f32  ---
constant_get_scalar_fp64 :: proc(constant: Constant, column: u32, row: u32) -> f64  ---
constant_get_scalar_u32 :: proc(constant: Constant, column: u32, row: u32) -> u32 ---
constant_get_scalar_i32 :: proc(constant: Constant, column: u32, row: u32) -> i32  ---
constant_get_scalar_u16 :: proc(constant: Constant, column: u32, row: u32) -> u16 ---
constant_get_scalar_i16 :: proc(constant: Constant, column: u32, row: u32) -> i16 ---
constant_get_scalar_u8 :: proc(constant: Constant, column: u32, row: u32) -> u8 ---
constant_get_scalar_i8 :: proc(constant: Constant, column: u32, row: u32) -> u8 ---
constant_get_subconstants :: proc(constant: Constant, constituents: ^[^]Constant_Id, count: ^int) ---
constant_get_scalar_u64 :: proc(constant: Constant, column: u32, row: u32) -> u64 ---
constant_get_scalar_i64 :: proc(constant: Constant, column: u32, row: u32) -> i64 ---
constant_get_type :: proc(constant: Constant) -> Type_Id  ---

/*
 * C implementation of the C++ api.
 */
constant_set_scalar_fp16 :: proc(constant: Constant, column: u32, row: u32, value: f16) ---
constant_set_scalar_fp32 :: proc(constant: Constant, column: u32, row: u32, value: f32) ---
constant_set_scalar_fp64 :: proc(constant: Constant, column: u32, row: u32, value: f64) ---
constant_set_scalar_u32 :: proc(constant: Constant, column: u32, row: u32, value: u32) ---
constant_set_scalar_i32 :: proc(constant: Constant, column: u32, row: u32, value: i32) ---
constant_set_scalar_u64 :: proc(constant: Constant, column: u32, row: u32, value: u64) ---
constant_set_scalar_i64 :: proc(constant: Constant, column: u32, row: u32, value: i64) ---
constant_set_scalar_u16 :: proc(constant: Constant, column: u32, row: u32, value: u16) ---
constant_set_scalar_i16 :: proc(constant: Constant, column: u32, row: u32, value: i16) ---
constant_set_scalar_u8 :: proc(constant: Constant, column: u32, row: u32, value: u8) ---
constant_set_scalar_i8 :: proc(constant: Constant, column: u32, row: u32, value: i8) ---

/*
 * Misc reflection
 * Maps to C++ API.
 */
compiler_get_binary_offset_for_decoration :: proc(compiler: Compiler, id: Variable_Id, decoration: Decoration, word_offset: ^u32) -> bool  ---

compiler_buffer_is_hlsl_counter_buffer :: proc(compiler: Compiler, id: Variable_Id) -> bool  ---
compiler_buffer_get_hlsl_counter_buffer :: proc(compiler: Compiler, id: Variable_Id, counter_id: ^Variable_Id) -> bool  ---

compiler_get_declared_capabilities :: proc(compiler: Compiler, capabilities: ^[^]Capability, num_capabilities: ^int) -> Result  ---
compiler_get_declared_extensions :: proc(compiler: Compiler, extensions: ^[^]cstring, num_extensions: ^int) -> Result  ---

compiler_get_remapped_declared_block_name :: proc(compiler: Compiler, id: Variable_Id) -> cstring ---
compiler_get_buffer_block_decorations :: proc(compiler: Compiler, id: Variable_Id, decorations: ^[^]Decoration, num_decorations: ^int) -> Result  ---


/*
 * Initializes the resource binding struct.
 * The defaults are non-zero.
 */
hlsl_resource_binding_init :: proc(binding: ^Hlsl_Resource_Binding) ---

/*
 * Initializes the vertex attribute struct.
 */
msl_vertex_attribute_init :: proc(attr: ^Msl_Vertex_Attribute) ---
/*
 * Initializes the shader input struct.
 * Deprecated. Use Msl_Shader_Interface_Var_Init_2().
 */
msl_shader_interface_var_init :: proc(var: ^Msl_Shader_Interface_Var) ---
/*
 * Deprecated. Use Msl_Shader_Interface_Var_Init_2().
 */
msl_shader_input_init :: proc(input: ^Msl_Shader_Input) ---

/*
 * Initializes the shader interface variable struct.
 */
msl_shader_interface_var_init_2 :: proc(var: ^Msl_Shader_Interface_Var_2) ---

/*
 * Initializes the resource binding struct.
 * The defaults are non-zero.
 * Deprecated: Use Msl_Resource_Binding_Init_2.
 */
msl_resource_binding_init :: proc(binding: ^Msl_Resource_Binding) ---
msl_resource_binding_init_2 :: proc(binding: ^Msl_Resource_Binding_2) ---

/* Runtime check for incompatibility. Obsolete. */
Msl_Get_Aux_Buffer_Struct_Version :: proc() -> u32 ---

/*
 * Initializes the constexpr sampler struct.
 * The defaults are non-zero.
 */
msl_constexpr_sampler_init :: proc(sampler: ^Msl_Constexpr_Sampler) ---

/*
 * Initializes the constexpr sampler struct.
 * The defaults are non-zero.
 */
msl_sampler_ycbcr_conversion_init :: proc(conv: ^Msl_Sampler_Ycbcr_Conversion) ---
}
