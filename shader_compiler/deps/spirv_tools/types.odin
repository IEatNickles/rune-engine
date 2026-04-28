package spirv_tools

Result :: enum {
  SUCCESS = 0,
  UNSUPPORTED = 1,
  END_OF_STREAM = 2,
  WARNING = 3,
  FAILED_MATCH = 4,
  REQUESTED_TERMINATION = 5,  // Success, but signals early termination.
  ERROR_INTERNAL = -1,
  ERROR_OUT_OF_MEMORY = -2,
  ERROR_INVALID_POINTER = -3,
  ERROR_INVALID_BINARY = -4,
  ERROR_INVALID_TEXT = -5,
  ERROR_INVALID_TABLE = -6,
  ERROR_INVALID_VALUE = -7,
  ERROR_INVALID_DIAGNOSTIC = -8,
  ERROR_INVALID_LOOKUP = -9,
  ERROR_INVALID_ID = -10,
  ERROR_INVALID_CFG = -11,
  ERROR_INVALID_LAYOUT = -12,
  ERROR_INVALID_CAPABILITY = -13,
  ERROR_INVALID_DATA = -14,  // Indicates data rules validation failure.
  ERROR_MISSING_EXTENSION = -15,
  ERROR_WRONG_VERSION = -16,  // Indicates wrong SPIR-V version
  ERROR_FNVAR = -17,  // Error related to SPV_INTEL_function_variants extension
}

// Severity levels of messages communicated to the consumer.
Message_Level :: enum {
  FATAL,           // Unrecoverable error due to environment.
                   // Will exit the program immediately. E.g.,
                   // out of memory.
  INTERNAL_ERROR,  // Unrecoverable error due to SPIRV-Tools
                   // internals.
                   // Will exit the program immediately. E.g.,
                   // unimplemented feature.
  ERROR,           // Normal error due to user input.
  WARNING,         // Warning information.
  INFO,            // General information.
  DEBUG,           // Debug information.
}

Endianness :: enum {
  LITTLE,
  BIG,
}

// The kinds of operands that an instruction may have.
//
// Some operand types are "concrete".  The binary parser uses a concrete
// operand type to describe an operand of a parsed instruction.
//
// The assembler uses all operand types.  In addition to determining what
// kind of value an operand may be, non-concrete operand types capture the
// fact that an operand might be optional (may be absent, or present exactly
// once), or might occur zero or more times.
//
// Sometimes we also need to be able to express the fact that an operand
// is a member of an optional tuple of values.  In that case the first member
// would be optional, and the subsequent members would be required.
//
// NOTE: Although we don't promise binary compatibility, as a courtesy, please
// add new enum values at the end.
Operand_Type :: enum {
  // A sentinel value.
  NONE = 0,

  // Set 1:  Operands that are IDs.
  ID,
  TYPE_ID,
  RESULT_ID,
  MEMORY_SEMANTICS_ID,  // SPIR-V Sec 3.25
  SCOPE_ID,             // SPIR-V Sec 3.27

  // Set 2:  Operands that are literal numbers.
  LITERAL_INTEGER,  // Always unsigned 32-bits.
  // The Instruction argument to OpExtInst. It's an unsigned 32-bit literal
  // number indicating which instruction to use from an extended instruction
  // set.
  EXTENSION_INSTRUCTION_NUMBER,
  // The Opcode argument to OpSpecConstantOp. It determines the operation
  // to be performed on constant operands to compute a specialization constant
  // result.
  SPEC_CONSTANT_OP_NUMBER,
  // A literal number whose format and size are determined by a previous operand
  // in the same instruction.  It's a signed integer, an unsigned integer, or a
  // floating point number.  It also has a specified bit width.  The width
  // may be larger than 32, which would require such a typed literal value to
  // occupy multiple SPIR-V words.
  TYPED_LITERAL_NUMBER,
  LITERAL_FLOAT,  // Always 32-bit float.

  // Set 3:  The literal string operand type.
  LITERAL_STRING,

  // Set 4:  Operands that are a single word enumerated value.
  SOURCE_LANGUAGE,               // SPIR-V Sec 3.2
  EXECUTION_MODEL,               // SPIR-V Sec 3.3
  ADDRESSING_MODEL,              // SPIR-V Sec 3.4
  MEMORY_MODEL,                  // SPIR-V Sec 3.5
  EXECUTION_MODE,                // SPIR-V Sec 3.6
  STORAGE_CLASS,                 // SPIR-V Sec 3.7
  DIMENSIONALITY,                // SPIR-V Sec 3.8
  SAMPLER_ADDRESSING_MODE,       // SPIR-V Sec 3.9
  SAMPLER_FILTER_MODE,           // SPIR-V Sec 3.10
  SAMPLER_IMAGE_FORMAT,          // SPIR-V Sec 3.11
  IMAGE_CHANNEL_ORDER,           // SPIR-V Sec 3.12
  IMAGE_CHANNEL_DATA_TYPE,       // SPIR-V Sec 3.13
  FP_ROUNDING_MODE,              // SPIR-V Sec 3.16
  LINKAGE_TYPE,                  // SPIR-V Sec 3.17
  ACCESS_QUALIFIER,              // SPIR-V Sec 3.18
  FUNCTION_PARAMETER_ATTRIBUTE,  // SPIR-V Sec 3.19
  DECORATION,                    // SPIR-V Sec 3.20
  BUILT_IN,                      // SPIR-V Sec 3.21
  GROUP_OPERATION,               // SPIR-V Sec 3.28
  KERNEL_ENQ_FLAGS,              // SPIR-V Sec 3.29
  KERNEL_PROFILING_INFO,         // SPIR-V Sec 3.30
  CAPABILITY,                    // SPIR-V Sec 3.31
  FPENCODING,                    // SPIR-V Sec 3.51

  // NOTE: New concrete enum values should be added at the end.

  // Set 5:  Operands that are a single word bitmask.
  // Sometimes a set bit indicates the instruction requires still more operands.
  IMAGE,                  // SPIR-V Sec 3.14
  FP_FAST_MATH_MODE,      // SPIR-V Sec 3.15
  SELECTION_CONTROL,      // SPIR-V Sec 3.22
  LOOP_CONTROL,           // SPIR-V Sec 3.23
  FUNCTION_CONTROL,       // SPIR-V Sec 3.24
  MEMORY_ACCESS,          // SPIR-V Sec 3.26
  FRAGMENT_SHADING_RATE,  // SPIR-V Sec 3.FSR

  // NOTE: New concrete enum values should be added at the end.

  // The "optional" and "variable"  operand types are only used internally by
  // the assembler and the binary parser.
  // There are two categories:
  //    Optional : expands to 0 or 1 operand, like ? in regular expressions.
  //    Variable : expands to 0, 1 or many operands or pairs of operands.
  //               This is similar to * in regular expressions.

  // Use characteristic function spvOperandIsConcrete to classify the
  // operand types; when it returns false, the operand is optional or variable.
  //
  // Any variable operand type is also optional.

  // An optional operand represents zero or one logical operands.
  // In an instruction definition, this may only appear at the end of the
  // operand types.
  OPTIONAL_ID,
  // An optional image operand type.
  OPTIONAL_IMAGE,
  // An optional memory access type.
  OPTIONAL_MEMORY_ACCESS,
  // An optional literal integer.
  OPTIONAL_LITERAL_INTEGER,
  // An optional literal number, which may be either integer or floating point.
  OPTIONAL_LITERAL_NUMBER,
  // Like TYPED_LITERAL_NUMBER, but optional, and integral.
  OPTIONAL_TYPED_LITERAL_INTEGER,
  // An optional literal string.
  OPTIONAL_LITERAL_STRING,
  // An optional access qualifier
  OPTIONAL_ACCESS_QUALIFIER,
  // An optional context-independent value, or CIV.  CIVs are tokens that we can
  // assemble regardless of where they occur -- literals, IDs, immediate
  // integers, etc.
  OPTIONAL_CIV,
  // An optional floating point encoding enum
  OPTIONAL_FPENCODING,

  // A variable operand represents zero or more logical operands.
  // In an instruction definition, this may only appear at the end of the
  // operand types.
  VARIABLE_ID,
  VARIABLE_LITERAL_INTEGER,
  // A sequence of zero or more pairs of (typed literal integer, Id).
  // Expands to zero or more:
  //  (SPV_OPERAND_TYPE_TYPED_LITERAL_INTEGER, SPV_OPERAND_TYPE_ID)
  // where the literal number must always be an integer of some sort.
  VARIABLE_LITERAL_INTEGER_ID,
  // A sequence of zero or more pairs of (Id, Literal integer)
  VARIABLE_ID_LITERAL_INTEGER,

  // The following are concrete enum types from the DebugInfo extended
  // instruction set.
  DEBUG_INFO_FLAGS,  // DebugInfo Sec 3.2.  A mask.
  DEBUG_BASE_TYPE_ATTRIBUTE_ENCODING,  // DebugInfo Sec 3.3
  DEBUG_COMPOSITE_TYPE,                // DebugInfo Sec 3.4
  DEBUG_TYPE_QUALIFIER,                // DebugInfo Sec 3.5
  DEBUG_OPERATION,                     // DebugInfo Sec 3.6

  // The following are concrete enum types from the OpenCL.DebugInfo.100
  // extended instruction set.
  CLDEBUG100_DEBUG_INFO_FLAGS,  // Sec 3.2. A Mask
  CLDEBUG100_DEBUG_BASE_TYPE_ATTRIBUTE_ENCODING,  // Sec 3.3
  CLDEBUG100_DEBUG_COMPOSITE_TYPE,                // Sec 3.4
  CLDEBUG100_DEBUG_TYPE_QUALIFIER,                // Sec 3.5
  CLDEBUG100_DEBUG_OPERATION,                     // Sec 3.6
  CLDEBUG100_DEBUG_IMPORTED_ENTITY,               // Sec 3.7

  // The following are concrete enum types from SPV_INTEL_float_controls2
  // https://github.com/intel/llvm/blob/39fa9b0cbfbae88327118990a05c5b387b56d2ef/sycl/doc/extensions/SPIRV/SPV_INTEL_float_controls2.asciidoc
  FPDENORM_MODE,     // Sec 3.17 FP Denorm Mode
  FPOPERATION_MODE,  // Sec 3.18 FP Operation Mode
  // A value enum from https://github.com/KhronosGroup/SPIRV-Headers/pull/177
  QUANTIZATION_MODES,
  // A value enum from https://github.com/KhronosGroup/SPIRV-Headers/pull/177
  OVERFLOW_MODES,

  // Concrete operand types for the provisional Vulkan ray tracing feature.
  RAY_FLAGS,               // SPIR-V Sec 3.RF
  RAY_QUERY_INTERSECTION,  // SPIR-V Sec 3.RQIntersection
  RAY_QUERY_COMMITTED_INTERSECTION_TYPE,  // SPIR-V Sec
                                                           // 3.RQCommitted
  RAY_QUERY_CANDIDATE_INTERSECTION_TYPE,  // SPIR-V Sec
                                                           // 3.RQCandidate

  // Concrete operand types for integer dot product.
  // Packed vector format
  PACKED_VECTOR_FORMAT,  // SPIR-V Sec 3.x
  // An optional packed vector format
  OPTIONAL_PACKED_VECTOR_FORMAT,

  // Concrete operand types for cooperative matrix.
  COOPERATIVE_MATRIX_OPERANDS,
  // An optional cooperative matrix operands
  OPTIONAL_COOPERATIVE_MATRIX_OPERANDS,
  COOPERATIVE_MATRIX_LAYOUT,
  COOPERATIVE_MATRIX_USE,

  // Enum type from SPV_INTEL_global_variable_fpga_decorations
  INITIALIZATION_MODE_QUALIFIER,
  // Enum type from SPV_INTEL_global_variable_host_access
  HOST_ACCESS_QUALIFIER,
  // Enum type from SPV_INTEL_cache_controls
  LOAD_CACHE_CONTROL,
  // Enum type from SPV_INTEL_cache_controls
  STORE_CACHE_CONTROL,
  // Enum type from SPV_INTEL_maximum_registers
  NAMED_MAXIMUM_NUMBER_OF_REGISTERS,
  // Enum type from SPV_NV_raw_access_chains
  RAW_ACCESS_CHAIN_OPERANDS,
  // Optional enum type from SPV_NV_raw_access_chains
  OPTIONAL_RAW_ACCESS_CHAIN_OPERANDS,
  // Enum type from SPV_NV_tensor_addressing
  TENSOR_CLAMP_MODE,
  // Enum type from SPV_NV_cooperative_matrix2
  COOPERATIVE_MATRIX_REDUCE,
  // Enum type from SPV_NV_cooperative_matrix2
  TENSOR_ADDRESSING_OPERANDS,
  // Optional types from SPV_INTEL_subgroup_matrix_multiply_accumulate
  MATRIX_MULTIPLY_ACCUMULATE_OPERANDS,
  OPTIONAL_MATRIX_MULTIPLY_ACCUMULATE_OPERANDS,

  COOPERATIVE_VECTOR_MATRIX_LAYOUT,
  COMPONENT_TYPE,

  // From nonesmantic.clspvreflection
  KERNEL_PROPERTY_FLAGS,

  // From nonesmantic.shader.debuginfo.100
  SHDEBUG100_BUILD_IDENTIFIER_FLAGS,
  SHDEBUG100_DEBUG_BASE_TYPE_ATTRIBUTE_ENCODING,
  SHDEBUG100_DEBUG_COMPOSITE_TYPE,
  SHDEBUG100_DEBUG_IMPORTED_ENTITY,
  SHDEBUG100_DEBUG_INFO_FLAGS,
  SHDEBUG100_DEBUG_OPERATION,
  SHDEBUG100_DEBUG_TYPE_QUALIFIER,

  // SPV_ARM_tensors
  TENSOR_OPERANDS,
  OPTIONAL_TENSOR_OPERANDS,

  // SPV_INTEL_function_variants
  OPTIONAL_CAPABILITY,
  VARIABLE_CAPABILITY,

  // This is a sentinel value, and does not represent an operand type.
  // It should come last.
  NUM_OPERAND_TYPES,
}

// Returns true if the given type is concrete.
OperandIsConcrete :: proc(type: Operand_Type) -> bool

// Returns true if the given type is concrete and also a mask.
OperandIsConcreteMask :: proc(type: Operand_Type) -> bool

Ext_Inst_Type :: enum {
  NONE = 0,
  GLSL_STD_450,
  OPENCL_STD,
  SPV_AMD_SHADER_EXPLICIT_VERTEX_PARAMETER,
  SPV_AMD_SHADER_TRINARY_MINMAX,
  SPV_AMD_GCN_SHADER,
  SPV_AMD_SHADER_BALLOT,
  DEBUGINFO,
  OPENCL_DEBUGINFO_100,
  NONSEMANTIC_CLSPVREFLECTION,
  NONSEMANTIC_SHADER_DEBUGINFO_100,
  NONSEMANTIC_VKSPREFLECTION,
  TOSA_001000_1,
  ARM_MOTION_ENGINE_100,

  // Multiple distinct extended instruction set types could return this
  // value, if they are prefixed with NonSemantic. and are otherwise
  // unrecognised
  NONSEMANTIC_UNKNOWN,
}

// This determines at a high level the kind of a binary-encoded literal
// number, but not the bit width.
// In principle, these could probably be folded into new entries in
// operand_type_t.  But then we'd have some special case differences
// between the assembler and disassembler.
Number_Kind :: enum {
  NONE = 0,  // The default for value initialization.
  UNSIGNED_INT,
  SIGNED_INT,
  FLOATING,
}

// Represent the encoding of floating point values
Fp_Encoding :: enum {
  UNKNOWN = 0,  // The encoding is not specified. Has to be deduced from bitwidth
  IEEE754_BINARY16,  // half float
  IEEE754_BINARY32,  // single float
  IEEE754_BINARY64,  // double float
  BFLOAT16,
  FLOAT8_E4M3,
  FLOAT8_E5M2,
}

Text_To_Binary_Options :: bit_set[Text_To_Binary_Option]
Text_To_Binary_Option :: enum {
  NONE,
  // Numeric IDs in the binary will have the same values as in the source.
  // Non-numeric IDs are allocated by filling in the gaps, starting with 1
  // and going up.
  PRESERVE_NUMERIC_IDS,
}

Binary_To_Text_Options :: bit_set[Binary_To_Text_Option]
Binary_To_Text_Option :: enum {
  NONE,
  PRINT,
  COLOR,
  INDENT,
  SHOW_BYTE_OFFSET,
  // Do not output the module header as leading comments in the assembly.
  NO_HEADER,
  // Use friendly names where possible.  The heuristic may expand over
  // time, but will use common names for scalar types, and debug names from
  // OpName instructions.
  FRIENDLY_NAMES,
  // Add some comments to the generated assembly
  COMMENT,
  // Use nested indentation for more readable SPIR-V
  NESTED_INDENT,
  // Reorder blocks to match the structured control flow of SPIR-V to increase
  // readability.
  REORDER_BLOCKS,
  // Handle unknown opcodes and unknown extended instruction numbers by emitting
  // them as OpUnknown instructions with raw integer operands.
  HANDLE_UNKNOWN_OPCODES,
}

// Constants

// The default id bound is to the minimum value for the id limit
// in the spir-v specification under the section "Universal Limits".
kDefaultMaxIdBound :: 0x3FFFFF;

// Structures

// Information about an operand parsed from a binary SPIR-V module.
// Note that the values are not included.  You still need access to the binary
// to extract the values.
Parsed_Operand :: struct {
  // Location of the operand, in words from the start of the instruction.
  offset: u16,
  // Number of words occupied by this operand.
  num_words: u16,
  // The "concrete" operand type.  See the definition of operand_type_t
  // for details.
  type: Operand_Type,
  // If type is a literal number type, then number_kind says whether it's
  // a signed integer, an unsigned integer, or a floating point number.
  number_kind: Number_Kind,
  // The number of bits for a literal number type.
  number_bit_width: u32,
  // The encoding used for floating point values
  fp_encoding: Fp_Encoding,
}

// An instruction parsed from a binary SPIR-V module.
Parsed_Instruction :: struct {
  // An array of words for this instruction, in native endianness.
  words: [^]u32,
  // The number of words in this instruction.
  num_words: u16,
  opcode: u16,
  // The extended instruction type, if opcode is OpExtInst.  Otherwise
  // this is the "none" value.
  ext_inst_type: Ext_Inst_Type,
  // The type id, or 0 if this instruction doesn't have one.
  type_id: u32,
  // The result id, or 0 if this instruction doesn't have one.
  result_id: u32,
  // The array of parsed operands.
  operands: [^]Parsed_Operand,
  num_operands: u16,
}

Parsed_Header :: struct {
  // The magic number of the SPIR-V module.
  magic: u32,
  // Version number.
  version: u32,
  // Generator's magic number.
  generator: u32,
  // IDs bound for this module (0 < id < bound).
  bound: u32,
  // reserved.
  reserved: u32,
}

Const_Binary :: struct {
  code: [^]u32, // const
  wordCount: int, // const
}

Binary :: struct {
  code: [^]u32,
  wordCount: int,
}

Text :: struct {
  str: cstring,
  length: int,
}

Position :: struct {
  line: int,
  column: int,
  index: int,
}

Diagnostic :: struct {
  position: Position,
  error: [^]u8,
  isTextSource: bool,
}

// Type Definitions

Optimizer :: struct{}

// Const_Binary :: ^Const_Binary
// Binary :: ^Binary
// Text :: ^Text
// Position :: ^Position
// Diagnostic :: ^Diagnostic
Const_Context :: distinct rawptr
Context :: distinct rawptr
Validator_Options :: distinct rawptr
Const_Validator_Options :: distinct rawptr
Optimizer_Options :: distinct rawptr
Const_Optimizer_Options :: distinct rawptr
Reducer_Options :: distinct rawptr
Const_Reducer_Options :: distinct rawptr
Fuzzer_Options :: distinct rawptr
Const_Fuzzer_Options :: distinct rawptr

// Platform API

// Returns the SPIRV-Tools software version as a null-terminated string.
// The contents of the underlying storage is valid for the remainder of
// the process.
SoftwareVersionString :: proc() -> [^]u8
// Returns a null-terminated string containing the name of the project,
// the software version string, and commit details.
// The contents of the underlying storage is valid for the remainder of
// the process.
SoftwareVersionDetailsString :: proc() -> [^]u8

// Certain target environments impose additional restrictions on SPIR-V, so it's
// often necessary to specify which one applies.  SPV_ENV_UNIVERSAL_* implies an
// environment-agnostic SPIR-V.
//
// When an API method needs to derive a SPIR-V version from a target environment
// (from the context object), the method will choose the highest version of
// SPIR-V supported by the target environment.  Examples:
//    SPV_ENV_VULKAN_1_0           ->  SPIR-V 1.0
//    SPV_ENV_VULKAN_1_1           ->  SPIR-V 1.3
//    SPV_ENV_VULKAN_1_1_SPIRV_1_4 ->  SPIR-V 1.4
//    SPV_ENV_VULKAN_1_2           ->  SPIR-V 1.5
//    SPV_ENV_VULKAN_1_3           ->  SPIR-V 1.6
//    SPV_ENV_VULKAN_1_4           ->  SPIR-V 1.6
// Consult the description of API entry points for specific rules.
Target_Env :: enum {
  UNIVERSAL_1_0,  // SPIR-V 1.0 latest revision, no other restrictions.
  VULKAN_1_0,     // Vulkan 1.0 latest revision.
  UNIVERSAL_1_1,  // SPIR-V 1.1 latest revision, no other restrictions.
  OPENCL_2_1,     // OpenCL Full Profile 2.1 latest revision.
  OPENCL_2_2,     // OpenCL Full Profile 2.2 latest revision.
  OPENGL_4_0,     // OpenGL 4.0 plus GL_ARB_gl_spirv, latest revisions.
  OPENGL_4_1,     // OpenGL 4.1 plus GL_ARB_gl_spirv, latest revisions.
  OPENGL_4_2,     // OpenGL 4.2 plus GL_ARB_gl_spirv, latest revisions.
  OPENGL_4_3,     // OpenGL 4.3 plus GL_ARB_gl_spirv, latest revisions.
  // There is no variant for OpenGL 4.4.
  OPENGL_4_5,     // OpenGL 4.5 plus GL_ARB_gl_spirv, latest revisions.
  UNIVERSAL_1_2,  // SPIR-V 1.2, latest revision, no other restrictions.
  OPENCL_1_2,     // OpenCL Full Profile 1.2 plus cl_khr_il_program,
                          // latest revision.
  OPENCL_EMBEDDED_1_2,  // OpenCL Embedded Profile 1.2 plus
                                // cl_khr_il_program, latest revision.
  OPENCL_2_0,  // OpenCL Full Profile 2.0 plus cl_khr_il_program,
                       // latest revision.
  OPENCL_EMBEDDED_2_0,  // OpenCL Embedded Profile 2.0 plus
                                // cl_khr_il_program, latest revision.
  OPENCL_EMBEDDED_2_1,  // OpenCL Embedded Profile 2.1 latest revision.
  OPENCL_EMBEDDED_2_2,  // OpenCL Embedded Profile 2.2 latest revision.
  UNIVERSAL_1_3,  // SPIR-V 1.3 latest revision, no other restrictions.
  VULKAN_1_1,     // Vulkan 1.1 latest revision.
  WEBGPU_0,       // DEPRECATED, may be removed in the future.
  UNIVERSAL_1_4,  // SPIR-V 1.4 latest revision, no other restrictions.

  // Vulkan 1.1 with VK_KHR_spirv_1_4, i.e. SPIR-V 1.4 binary.
  VULKAN_1_1_SPIRV_1_4,

  UNIVERSAL_1_5,  // SPIR-V 1.5 latest revision, no other restrictions.
  VULKAN_1_2,     // Vulkan 1.2 latest revision.

  UNIVERSAL_1_6,  // SPIR-V 1.6 latest revision, no other restrictions.
  VULKAN_1_3,     // Vulkan 1.3 latest revision.
  VULKAN_1_4,     // Vulkan 1.4 latest revision.

  MAX  // Keep this as the last enum value.
}

// SPIR-V Validator can be parameterized with the following Universal Limits.
Validator_Limit :: enum {
  max_struct_members,
  max_struct_depth,
  max_local_variables,
  max_global_variables,
  max_switch_branches,
  max_function_args,
  max_control_flow_nesting_depth,
  max_access_chain_indexes,
  max_id_bound,
}

// A pointer to a function that accepts a parsed SPIR-V header.
// The integer arguments are the 32-bit words from the header, as specified
// in SPIR-V 1.0 Section 2.3 Table 1.
// The function should return SPV_SUCCESS if parsing should continue.
Parsed_Header_Proc :: #type proc "c" (user_data: rawptr, endian: Endianness, magic: u32, version: u32, generator: u32, id_bound: u32, reserved: u32) -> Result

// A pointer to a function that accepts a parsed SPIR-V instruction.
// The parsed_instruction value is transient: it may be overwritten
// or released immediately after the function has returned.  That also
// applies to the words array member of the parsed instruction.  The
// function should return SPV_SUCCESS if and only if parsing should
// continue.
Parsed_Instruction_Proc :: #type proc "c" (user_data: rawptr, parsed_instruction: [^]Parsed_Instruction) -> Result

// A pointer to a function that accepts a log message from an optimizer.
Message_Consumer :: #type proc "c" (Message_Level, cstring, [^]Position, cstring);
