package spirv_reflect

import "core:c"

Result :: enum i32 {
  SPV_REFLECT_RESULT_SUCCESS,
  SPV_REFLECT_RESULT_NOT_READY,
  SPV_REFLECT_RESULT_ERROR_PARSE_FAILED,
  SPV_REFLECT_RESULT_ERROR_ALLOC_FAILED,
  SPV_REFLECT_RESULT_ERROR_RANGE_EXCEEDED,
  SPV_REFLECT_RESULT_ERROR_NULL_POINTER,
  SPV_REFLECT_RESULT_ERROR_INTERNAL_ERROR,
  SPV_REFLECT_RESULT_ERROR_COUNT_MISMATCH,
  SPV_REFLECT_RESULT_ERROR_ELEMENT_NOT_FOUND,
  SPV_REFLECT_RESULT_ERROR_SPIRV_INVALID_CODE_SIZE,
  SPV_REFLECT_RESULT_ERROR_SPIRV_INVALID_MAGIC_NUMBER,
  SPV_REFLECT_RESULT_ERROR_SPIRV_UNEXPECTED_EOF,
  SPV_REFLECT_RESULT_ERROR_SPIRV_INVALID_ID_REFERENCE,
  SPV_REFLECT_RESULT_ERROR_SPIRV_SET_NUMBER_OVERFLOW,
  SPV_REFLECT_RESULT_ERROR_SPIRV_INVALID_STORAGE_CLASS,
  SPV_REFLECT_RESULT_ERROR_SPIRV_RECURSION,
  SPV_REFLECT_RESULT_ERROR_SPIRV_INVALID_INSTRUCTION,
  SPV_REFLECT_RESULT_ERROR_SPIRV_UNEXPECTED_BLOCK_DATA,
  SPV_REFLECT_RESULT_ERROR_SPIRV_INVALID_BLOCK_MEMBER_REFERENCE,
  SPV_REFLECT_RESULT_ERROR_SPIRV_INVALID_ENTRY_POINT,
  SPV_REFLECT_RESULT_ERROR_SPIRV_INVALID_EXECUTION_MODE,
  SPV_REFLECT_RESULT_ERROR_SPIRV_MAX_RECURSIVE_EXCEEDED,
}

/*! @enum ModuleFlagBits

SPV_REFLECT_MODULE_FLAG_NO_COPY - Disables copying of SPIR-V code
  when a SPIRV-Reflect shader module is created. It is the
  responsibility of the calling program to ensure that the pointer
  remains valid and the memory it's pointing to is not freed while
  SPIRV-Reflect operations are taking place. Freeing the backing
  memory will cause undefined behavior or most likely a crash.
  This is flag is intended for cases where the memory overhead of
  storing the copied SPIR-V is undesirable.

*/
ModuleFlags :: bit_set[ModuleFlagBits]
ModuleFlagBits :: enum i32 {
  NO_COPY,
}

/*! @enum TypeFlagBits

*/
TypeFlags :: bit_set[TypeFlagBits]
TypeFlagBits :: enum i32 {
  VOID                             = 0,
  BOOL                             = 1,
  INT                              = 2,
  FLOAT                            = 3,
  VECTOR                           = 8,
  MATRIX                           = 9,
  EXTERNAL_IMAGE                   = 16,
  EXTERNAL_SAMPLER                 = 17,
  EXTERNAL_SAMPLED_IMAGE           = 18,
  EXTERNAL_BLOCK                   = 19,
  EXTERNAL_ACCELERATION_STRUCTURE  = 20,
  STRUCT                           = 24,
  ARRAY                            = 25,
  REF                              = 26,
}
TYPE_FLAGS_EXTERNAL_MASK :: 0x00FF0000

/*! @enum DecorationBits

NOTE: HLSL row_major and column_major decorations are reversed
      in SPIR-V. Meaning that matrices declrations with row_major
      will get reflected as column_major and vice versa. The
      row and column decorations get appied during the compilation.
      SPIRV-Reflect reads the data as is and does not make any
      attempt to correct it to match what's in the source.

      The Patch, PerVertex, and PerTask are used for Interface
      variables that can have array

*/
DecorationFlags :: bit_set[DecorationFlagBits]
DecorationFlagBits :: enum i32 {
  BLOCK,
  BUFFER_BLOCK,
  ROW_MAJOR,
  COLUMN_MAJOR,
  BUILT_IN,
  NOPERSPECTIVE,
  FLAT,
  NON_WRITABLE,
  RELAXED_PRECISION,
  NON_READABLE,
  PATCH,
  PER_VERTEX,
  PER_TASK,
  WEIGHT_TEXTURE,
  BLOCK_MATCH_TEXTURE,
}

// Based of SPV_GOOGLE_user_type
UserType :: enum i32 {
  INVALID = 0,
  CBUFFER,
  TBUFFER,
  APPEND_STRUCTURED_BUFFER,
  BUFFER,
  BYTE_ADDRESS_BUFFER,
  CONSTANT_BUFFER,
  CONSUME_STRUCTURED_BUFFER,
  INPUT_PATCH,
  OUTPUT_PATCH,
  RASTERIZER_ORDERED_BUFFER,
  RASTERIZER_ORDERED_BYTE_ADDRESS_BUFFER,
  RASTERIZER_ORDERED_STRUCTURED_BUFFER,
  RASTERIZER_ORDERED_TEXTURE_1D,
  RASTERIZER_ORDERED_TEXTURE_1D_ARRAY,
  RASTERIZER_ORDERED_TEXTURE_2D,
  RASTERIZER_ORDERED_TEXTURE_2D_ARRAY,
  RASTERIZER_ORDERED_TEXTURE_3D,
  RAYTRACING_ACCELERATION_STRUCTURE,
  RW_BUFFER,
  RW_BYTE_ADDRESS_BUFFER,
  RW_STRUCTURED_BUFFER,
  RW_TEXTURE_1D,
  RW_TEXTURE_1D_ARRAY,
  RW_TEXTURE_2D,
  RW_TEXTURE_2D_ARRAY,
  RW_TEXTURE_3D,
  STRUCTURED_BUFFER,
  SUBPASS_INPUT,
  SUBPASS_INPUT_MS,
  TEXTURE_1D,
  TEXTURE_1D_ARRAY,
  TEXTURE_2D,
  TEXTURE_2D_ARRAY,
  TEXTURE_2DMS,
  TEXTURE_2DMS_ARRAY,
  TEXTURE_3D,
  TEXTURE_BUFFER,
  TEXTURE_CUBE,
  TEXTURE_CUBE_ARRAY,
}

/*! @enum ResourceType

*/
ResourceTypeFlags :: bit_set[ResourceTypeBits]
ResourceTypeBits :: enum i32 {
  SAMPLER,
  CBV,
  SRV,
  UAV,
}

/*! @enum Format

*/
Format :: enum i32 {
  SPV_REFLECT_FORMAT_UNDEFINED           =   0, // = VK_FORMAT_UNDEFINED
  SPV_REFLECT_FORMAT_R16_UINT            =  74, // = VK_FORMAT_R16_UINT
  SPV_REFLECT_FORMAT_R16_SINT            =  75, // = VK_FORMAT_R16_SINT
  SPV_REFLECT_FORMAT_R16_SFLOAT          =  76, // = VK_FORMAT_R16_SFLOAT
  SPV_REFLECT_FORMAT_R16G16_UINT         =  81, // = VK_FORMAT_R16G16_UINT
  SPV_REFLECT_FORMAT_R16G16_SINT         =  82, // = VK_FORMAT_R16G16_SINT
  SPV_REFLECT_FORMAT_R16G16_SFLOAT       =  83, // = VK_FORMAT_R16G16_SFLOAT
  SPV_REFLECT_FORMAT_R16G16B16_UINT      =  88, // = VK_FORMAT_R16G16B16_UINT
  SPV_REFLECT_FORMAT_R16G16B16_SINT      =  89, // = VK_FORMAT_R16G16B16_SINT
  SPV_REFLECT_FORMAT_R16G16B16_SFLOAT    =  90, // = VK_FORMAT_R16G16B16_SFLOAT
  SPV_REFLECT_FORMAT_R16G16B16A16_UINT   =  95, // = VK_FORMAT_R16G16B16A16_UINT
  SPV_REFLECT_FORMAT_R16G16B16A16_SINT   =  96, // = VK_FORMAT_R16G16B16A16_SINT
  SPV_REFLECT_FORMAT_R16G16B16A16_SFLOAT =  97, // = VK_FORMAT_R16G16B16A16_SFLOAT
  SPV_REFLECT_FORMAT_R32_UINT            =  98, // = VK_FORMAT_R32_UINT
  SPV_REFLECT_FORMAT_R32_SINT            =  99, // = VK_FORMAT_R32_SINT
  SPV_REFLECT_FORMAT_R32_SFLOAT          = 100, // = VK_FORMAT_R32_SFLOAT
  SPV_REFLECT_FORMAT_R32G32_UINT         = 101, // = VK_FORMAT_R32G32_UINT
  SPV_REFLECT_FORMAT_R32G32_SINT         = 102, // = VK_FORMAT_R32G32_SINT
  SPV_REFLECT_FORMAT_R32G32_SFLOAT       = 103, // = VK_FORMAT_R32G32_SFLOAT
  SPV_REFLECT_FORMAT_R32G32B32_UINT      = 104, // = VK_FORMAT_R32G32B32_UINT
  SPV_REFLECT_FORMAT_R32G32B32_SINT      = 105, // = VK_FORMAT_R32G32B32_SINT
  SPV_REFLECT_FORMAT_R32G32B32_SFLOAT    = 106, // = VK_FORMAT_R32G32B32_SFLOAT
  SPV_REFLECT_FORMAT_R32G32B32A32_UINT   = 107, // = VK_FORMAT_R32G32B32A32_UINT
  SPV_REFLECT_FORMAT_R32G32B32A32_SINT   = 108, // = VK_FORMAT_R32G32B32A32_SINT
  SPV_REFLECT_FORMAT_R32G32B32A32_SFLOAT = 109, // = VK_FORMAT_R32G32B32A32_SFLOAT
  SPV_REFLECT_FORMAT_R64_UINT            = 110, // = VK_FORMAT_R64_UINT
  SPV_REFLECT_FORMAT_R64_SINT            = 111, // = VK_FORMAT_R64_SINT
  SPV_REFLECT_FORMAT_R64_SFLOAT          = 112, // = VK_FORMAT_R64_SFLOAT
  SPV_REFLECT_FORMAT_R64G64_UINT         = 113, // = VK_FORMAT_R64G64_UINT
  SPV_REFLECT_FORMAT_R64G64_SINT         = 114, // = VK_FORMAT_R64G64_SINT
  SPV_REFLECT_FORMAT_R64G64_SFLOAT       = 115, // = VK_FORMAT_R64G64_SFLOAT
  SPV_REFLECT_FORMAT_R64G64B64_UINT      = 116, // = VK_FORMAT_R64G64B64_UINT
  SPV_REFLECT_FORMAT_R64G64B64_SINT      = 117, // = VK_FORMAT_R64G64B64_SINT
  SPV_REFLECT_FORMAT_R64G64B64_SFLOAT    = 118, // = VK_FORMAT_R64G64B64_SFLOAT
  SPV_REFLECT_FORMAT_R64G64B64A64_UINT   = 119, // = VK_FORMAT_R64G64B64A64_UINT
  SPV_REFLECT_FORMAT_R64G64B64A64_SINT   = 120, // = VK_FORMAT_R64G64B64A64_SINT
  SPV_REFLECT_FORMAT_R64G64B64A64_SFLOAT = 121, // = VK_FORMAT_R64G64B64A64_SFLOAT
}

/*! @enum VariableFlagBits

*/
VariableFlags :: bit_set[VariableFlagBits]
VariableFlagBits :: enum i32 {
  UNUSED,
  // If variable points to a copy of the PhysicalStorageBuffer struct
  PHYSICAL_POINTER_COPY,
};

/*! @enum DescriptorType

*/
DescriptorType :: enum i32 {
  SAMPLER                    =  0,        // = VK_DESCRIPTOR_TYPE_SAMPLER
  COMBINED_IMAGE_SAMPLER     =  1,        // = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER
  SAMPLED_IMAGE              =  2,        // = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE
  STORAGE_IMAGE              =  3,        // = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE
  UNIFORM_TEXEL_BUFFER       =  4,        // = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER
  STORAGE_TEXEL_BUFFER       =  5,        // = VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER
  UNIFORM_BUFFER             =  6,        // = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER
  STORAGE_BUFFER             =  7,        // = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER
  UNIFORM_BUFFER_DYNAMIC     =  8,        // = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC
  STORAGE_BUFFER_DYNAMIC     =  9,        // = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC
  INPUT_ATTACHMENT           = 10,        // = VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT
  ACCELERATION_STRUCTURE_KHR = 1000150000 // = VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR
}

/*! @enum ShaderStageFlagBits

*/
ShaderStageFlags :: bit_set[ShaderStageFlagBits]
ShaderStageFlagBits :: enum i32 {
  VERTEX,                  // = VK_SHADER_STAGE_VERTEX_BIT
  TESSELLATION_CONTROL,    // = VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT
  TESSELLATION_EVALUATION, // = VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT
  GEOMETRY,                // = VK_SHADER_STAGE_GEOMETRY_BIT
  FRAGMENT,                // = VK_SHADER_STAGE_FRAGMENT_BIT
  COMPUTE,                 // = VK_SHADER_STAGE_COMPUTE_BIT
  TASK_NV,                 // = VK_SHADER_STAGE_TASK_BIT_NV
  TASK_EXT = TASK_NV,      // = VK_SHADER_STAGE_CALLABLE_BIT_EXT
  MESH_NV,                 // = VK_SHADER_STAGE_MESH_NV
  MESH_EXT = MESH_NV,      // = VK_SHADER_STAGE_CALLABLE_BIT_EXT
  RAYGEN_KHR,              // = VK_SHADER_STAGE_RAYGEN_BIT_KHR
  ANY_HIT_KHR,             // = VK_SHADER_STAGE_ANY_HIT_BIT_KHR
  CLOSEST_HIT_KHR,         // = VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR
  MISS_KHR,                // = VK_SHADER_STAGE_MISS_BIT_KHR
  INTERSECTION_KHR,        // = VK_SHADER_STAGE_INTERSECTION_BIT_KHR
  CALLABLE_KHR,            // = VK_SHADER_STAGE_CALLABLE_BIT_KHR

}

/*! @enum Generator

*/
Generator :: enum i32 {
  KHRONOS_LLVM_SPIRV_TRANSLATOR         = 6,
  KHRONOS_SPIRV_TOOLS_ASSEMBLER         = 7,
  KHRONOS_GLSLANG_REFERENCE_FRONT_END   = 8,
  GOOGLE_SHADERC_OVER_GLSLANG           = 13,
  GOOGLE_SPIREGG                        = 14,
  GOOGLE_RSPIRV                         = 15,
  X_LEGEND_MESA_MESAIR_SPIRV_TRANSLATOR = 16,
  KHRONOS_SPIRV_TOOLS_LINKER            = 17,
  WINE_VKD3D_SHADER_COMPILER            = 18,
  CLAY_CLAY_SHADER_COMPILER             = 19,
}

MAX_ARRAY_DIMS                    :: 32
MAX_DESCRIPTOR_SETS               :: 64

BINDING_NUMBER_DONT_CHANGE        :: ~int(0)
SET_NUMBER_DONT_CHANGE            :: ~int(0)

NumericTraits :: struct {
  scalar: struct{
    width: c.uint,
    signedness: c.uint,
  },

  vector: struct {
    component_count: c.uint,
  },

  _matrix: struct {
    column_count: c.uint,
    row_count: c.uint,
    stride: c.uint, // Measured in bytes
  }
}

ImageTraits :: struct {
  dim: Dim,
  depth: c.uint,
  arrayed: c.uint,
  ms: c.uint, // 0: single-sampled; 1: multisampled
  sampled: c.uint,
  image_format: ImageFormat,
}

ArrayDimType :: enum i32 {
  RUNTIME       = 0,         // OpTypeRuntimeArray
}

ArrayTraits :: struct {
  dims_count: c.uint,
  // Each entry is either:
  // - specialization constant dimension
  // - OpTypeRuntimeArray
  // - the array length otherwise
  dims: [MAX_ARRAY_DIMS]c.uint,
  // Stores Ids for dimensions that are specialization constants
  spec_constant_op_ids: [MAX_ARRAY_DIMS]c.uint,
  stride: c.uint, // Measured in bytes
}

BindingArrayTraits :: struct {
  dims_count: c.uint,
  dims: [MAX_ARRAY_DIMS]c.uint,
}

/*! @struct TypeDescription
    @brief Information about an OpType* instruction
*/
TypeDescription :: struct {
  id: c.uint,
  op: Op,
  type_name: cstring,
  // Non-NULL if type is member of a struct
  struct_member_name: cstring,

  // The storage class (SpvStorageClass) if the type, and -1 if it does not have a storage class.
  storage_class: c.int,
  type_flags: TypeFlags,
  decoration_flags: DecorationFlags,

  traits: struct {
    numeric: NumericTraits,
    image: ImageTraits,
    array: ArrayTraits,
  },

  // If underlying type is a struct (ex. array of structs)
  // this gives access to the OpTypeStruct
  struct_type_description: ^TypeDescription,

  // Some pointers to TypeDescription are really
  // just copies of another reference to the same OpType
  copied: c.uint,

  // @deprecated use struct_type_description instead
  member_count: c.uint,
  // @deprecated use struct_type_description instead
  members: [^]TypeDescription,
}


/*! @struct InterfaceVariable
    @brief The OpVariable that is either an Input or Output to the module
*/
InterfaceVariable :: struct {
  spirv_id: c.uint,
  name: cstring,
  location: c.uint,
  component: c.uint,
  storage_class: StorageClass,
  semantic: cstring,
  decoration_flags: DecorationFlags,

  // The builtin id (SpvBuiltIn) if the variable is a builtin, and -1 otherwise.
  built_in: c.int,
  numeric: NumericTraits,
  array: ArrayTraits,

  member_count: c.uint,
  members: [^]InterfaceVariable,

  format: Format,

  // NOTE: SPIR-V shares type references for variables
  //       that have the same underlying type. This means
  //       that the same type name will appear for multiple
  //       variables.
  type_description: ^TypeDescription,

  word_offset: struct {
    location: c.uint,
  },
}

/*! @struct BlockVariable

*/
BlockVariable :: struct {
  spirv_id: c.uint,
  name: cstring,
  // For Push Constants, this is the lowest offset of all memebers
  offset: c.uint,           // Measured in bytes
  absolute_offset: c.uint,  // Measured in bytes
  size: c.uint,             // Measured in bytes
  padded_size: c.uint,      // Measured in bytes
  decoration_flags: DecorationFlags,
  numeric: NumericTraits,
  array: ArrayTraits,
  flags: VariableFlags,

  member_count: c.uint,
  members: [^]BlockVariable,

  type_description: ^TypeDescription,

  word_offset: struct {
    offset: c.uint,
  },
}

/*! @struct DescriptorBinding

*/
DescriptorBinding :: struct {
  spirv_id: c.uint,
  name: cstring,
  binding: c.uint,
  input_attachment_index: c.uint,
  set: c.uint,
  descriptor_type: DescriptorType,
  resource_type: ResourceTypeFlags,
  image: ImageTraits,
  block: BlockVariable,
  array: BindingArrayTraits,
  count: c.uint,
  accessed: c.uint,
  uav_counter_id: c.uint,
  uav_counter_binding: ^DescriptorBinding,
  byte_address_buffer_offset_count: c.uint,
  byte_address_buffer_offsets: [^]c.uint,

  type_description: ^TypeDescription,

  word_offset: struct {
    binding: c.uint,
    set: c.uint,
  },

  decoration_flags: DecorationFlags,
  // Requires SPV_GOOGLE_user_type
  user_type: UserType,
}

/*! @struct DescriptorSet

*/
DescriptorSet :: struct {
  set: c.uint,
  binding_count: c.uint,
  bindings: ^[^]DescriptorBinding,
}

ExecutionModeValue :: enum u32 {
  SPEC_CONSTANT = 0xFFFFFFFF // specialization constant
}

/*! @struct EntryPoint

 */
EntryPoint :: struct {
  name: cstring,
  id: c.uint,

  spirv_execution_model: ExecutionModel,
  shader_stage: ShaderStageFlags,

  input_variable_count: c.uint,
  input_variables: [^]^InterfaceVariable,
  output_variable_count: c.uint,
  output_variables: [^]^InterfaceVariable,
  interface_variable_count: c.uint,
  interface_variables: [^]InterfaceVariable,

  descriptor_set_count: c.uint,
  descriptor_sets: [^]DescriptorSet,

  used_uniform_count: c.uint,
  used_uniforms: [^]c.uint,
  used_push_constant_count: c.uint,
  used_push_constants: [^]c.uint,

  execution_mode_count: c.uint,
  execution_modes: [^]ExecutionMode,

  local_size: struct {
    x: c.uint,
    y: c.uint,
    z: c.uint,
  },
  invocations: c.uint, // valid for geometry
  output_vertices: c.uint, // valid for geometry, tesselation
}

/*! @struct Capability

*/
Capability :: struct {
  value: SpvCapability,
  word_offset: c.uint,
}


/*! @struct SpecId

*/
SpecializationConstant :: struct {
  spirv_id: c.uint,
  constant_id: c.uint,
  name: cstring,
}

/*! @struct ShaderModule

*/
ShaderModule :: struct {
  generator: Generator,
  entry_point_name: cstring,
  entry_point_id: c.uint,
  entry_point_count: c.uint,
  entry_points: [^]EntryPoint,
  source_language: SourceLanguage,
  source_language_version: c.uint,
  source_file: cstring,
  source_source: cstring,
  capability_count: c.uint,
  capabilities: [^]Capability,
  spirv_execution_model: ExecutionModel,                            // Uses value(s) from first entry point
  shader_stage: ShaderStageFlagBits,                                     // Uses value(s) from first entry point
  descriptor_binding_count: c.uint,                         // Uses value(s) from first entry point
  descriptor_bindings: [^]DescriptorBinding,                              // Uses value(s) from first entry point
  descriptor_set_count: c.uint,                             // Uses value(s) from first entry point
  descriptor_sets: [MAX_DESCRIPTOR_SETS]DescriptorSet, // Uses value(s) from first entry point
  input_variable_count: c.uint,                             // Uses value(s) from first entry point
  input_variables: ^[^]InterfaceVariable,                                  // Uses value(s) from first entry point
  output_variable_count: c.uint,                            // Uses value(s) from first entry point
  output_variables: ^[^]InterfaceVariable,                                 // Uses value(s) from first entry point
  interface_variable_count: c.uint,                         // Uses value(s) from first entry point
  interface_variables: [^]InterfaceVariable,                              // Uses value(s) from first entry point
  push_constant_block_count: c.uint,                        // Uses value(s) from first entry point
  push_constant_blocks: [^]BlockVariable,                             // Uses value(s) from first entry point
  spec_constant_count: c.uint,                              // Uses value(s) from first entry point
  spec_constants: [^]SpecializationConstant,                                   // Uses value(s) from first entry point

  _internal: ^struct {
    module_flags: ModuleFlags,
    spirv_size: c.size_t,
    spirv_code: [^]c.uint,
    spirv_word_count: c.uint,

    type_description_count: c.size_t,
    type_descriptions: [^]TypeDescription,
  },
}
