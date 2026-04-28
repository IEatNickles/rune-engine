package spirv_tools

when ODIN_OS == .Linux {
  foreign import spv {
    "system:SPIRV-Tools",
    "system:stdc++",
  }
}

import "core:c"

@(default_calling_convention="c")
foreign spv {
// Returns a string describing the given SPIR-V target environment.
@(link_name="spvTargetEnvDescription")
target_env_description :: proc(env: Target_Env) -> cstring ---

// Parses s into ^env and returns true if successful.  If unparsable, returns
// false and sets ^env to SPV_ENV_UNIVERSAL_1_0.
@(link_name="spvParseTargetEnv")
parse_target_env :: proc(s: cstring, env: ^Target_Env) -> bool ---

// Determines the target env value with the least features but which enables
// the given Vulkan and SPIR-V versions. If such a target is supported, returns
// true and writes the value to |env|, otherwise returns false.
//
// The Vulkan version is given as an unsigned 32-bit number as specified in
// Vulkan section "29.2.1 Version Numbers": the major version number appears
// in bits 22 to 21, and the minor version is in bits 12 to 21.  The SPIR-V
// version is given in the SPIR-V version header word: major version in bits
// 16 to 23, and minor version in bits 8 to 15.
@(link_name="spvParseVulkanEnv")
parse_vulkan_env :: proc(vulkan_ver: c.uint32_t, spirv_ver: c.uint32_t, env: ^Target_Env) -> bool ---

// Creates a context object for most of the SPIRV-Tools API.
// Returns null if env is invalid.
//
// See specific API calls for how the target environment is interpreted
// (particularly assembly and validation).
@(link_name="spvContextCreate")
context_create :: proc(env: Target_Env) -> Context ---

// Destroys the given context object.
@(link_name="spvContextDestroy")
context_destroy :: proc(_context: Context) ---

// Creates a Validator options object with default options. Returns a valid
// options object. The object remains valid until it is passed into
// Validator_options_destroy.
@(link_name="spvValidatorOptionsCreate")
validator_options_create :: proc() -> Validator_Options ---

// Destroys the given Validator options object.
@(link_name="spvValidatorOptionsDestroy")
validator_options_destroy :: proc(options: Validator_Options) ---

// Records the maximum Universal Limit that is considered valid in the given
// Validator options object. <options> argument must be a valid options object.
@(link_name="spvValidatorOptionsSetUniversalLimit")
validator_options_set_universal_limit :: proc(options: Validator_Options, limit_type: Validator_Limit, limit: c.uint32_t) ---

// Record whether or not the validator should relax the rules on types for
// stores to structs.  When relaxed, it will allow a type mismatch as long as
// the types are structs with the same layout.  Two structs have the same layout
// if
//
// 1) the members of the structs are either the same type or are structs with
// same layout, and
//
// 2) the decorations that affect the memory layout are identical for both
// types.  Other decorations are not relevant.
@(link_name="spvValidatorOptionsSetRelaxStoreStruct")
validator_options_set_relax_store_struct :: proc(options: Validator_Options, val: bool) ---

// Records whether or not the validator should relax the rules on pointer usage
// in logical addressing mode.
//
// When relaxed, it will allow the following usage cases of pointers:
// 1) Op_variable allocating an object whose type is a pointer type
// 2) Op_return_value returning a pointer value
@(link_name="spvValidatorOptionsSetRelaxLogicalPointer")
validator_options_set_relax_logical_pointer :: proc(options: Validator_Options, val: bool) ---

// Records whether or not the validator should relax the rules because it is
// expected that the optimizations will make the code legal.
//
// When relaxed, it will allow the following:
// 1) It will allow relaxed logical pointers.  Setting this option will also
//    set that option.
// 2) Pointers that are pass as parameters to function calls do not have to
//    match the storage class of the formal parameter.
// 3) Pointers that are actual parameters on function calls do not have to point
//    to the same type pointed as the formal parameter.  The types just need to
//    logically match.
// 4) GLSLstd450 ^Interpolate instructions can have a load of an interpolant
//    for a first argument.
@(link_name="spvValidatorOptionsSetBeforeHlslLegalization")
validator_options_set_before_hlsl_legalization :: proc(options: Validator_Options, val: bool) ---

// Records whether the validator should use "relaxed" block layout rules.
// Relaxed layout rules are described by Vulkan extension
// VK_KHR_relaxed_block_layout, and they affect uniform blocks, storage blocks,
// and push constants.
//
// This is enabled by default when targeting Vulkan 1.1 or later.
// Relaxed layout is more permissive than the default rules in Vulkan 1.0.
@(link_name="spvValidatorOptionsSetRelaxBlockLayout")
validator_options_set_relax_block_layout :: proc(options: Validator_Options, val: bool) ---

// Records whether the validator should use standard block layout rules for
// uniform blocks.
@(link_name="spvValidatorOptionsSetUniformBufferStandardLayout")
validator_options_set_uniform_buffer_standard_layout :: proc(options: Validator_Options, val: bool) ---

// Records whether the validator should use "scalar" block layout rules.
// Scalar layout rules are more permissive than relaxed block layout.
//
// See Vulkan extension VK_EXT_scalar_block_layout.  The scalar alignment is
// defined as follows:
// - scalar alignment of a scalar is the scalar size
// - scalar alignment of a vector is the scalar alignment of its component
// - scalar alignment of a matrix is the scalar alignment of its component
// - scalar alignment of an array is the scalar alignment of its element
// - scalar alignment of a struct is the max scalar alignment among its
//   members
//
// For a struct in Uniform, Storage_class, or Push_constant:
// - a member Offset must be a multiple of the member's scalar alignment
// - Array_stride or Matrix_stride must be a multiple of the array or matrix
//   scalar alignment
@(link_name="spvValidatorOptionsSetScalarBlockLayout")
validator_options_set_scalar_block_layout :: proc(options: Validator_Options, val: bool) ---

// Records whether the validator should use "scalar" block layout
// rules (defined: as above) for Workgroup blocks.  See Vulkan
// extension VK_KHR_workgroup_memory_explicit_layout.
@(link_name="spvValidatorOptionsSetWorkgroupScalarBlockLayout")
validator_options_set_workgroup_scalar_block_layout :: proc(options: Validator_Options, val: bool) ---

// Records whether or not the validator should skip validating standard
// uniform/storage block layout.
@(link_name="spvValidatorOptionsSetSkipBlockLayout")
validator_options_set_skip_block_layout :: proc(options: Validator_Options, val: bool) ---

// Records whether or not the validator should allow the Local_size_id
// decoration where the environment otherwise would not allow it.
@(link_name="spvValidatorOptionsSetAllowLocalSizeId")
validator_options_set_allow_local_size_id :: proc(options: Validator_Options, val: bool) ---

// Allow Offset (addition: in to Const_offset) for texture operations.
// Was added for VK_KHR_maintenance8
@(link_name="spvValidatorOptionsSetAllowOffsetTextureOperand")
validator_options_set_allow_offset_texture_operand :: proc(options: Validator_Options, val: bool) ---

// Allow base operands of some bit operations to be non-32-bit wide.
// Was added for VK_KHR_maintenance9
@(link_name="spvValidatorOptionsSetAllowVulkan32BitBitwise")
validator_options_set_allow_vulkan32_bit_bitwise :: proc(options: Validator_Options, val: bool) ---

// Whether friendly names should be used in validation error messages.
@(link_name="spvValidatorOptionsSetFriendlyNames")
validator_options_set_friendly_names :: proc(options: Validator_Options, val: bool) ---

// Creates an optimizer options object with default options. Returns a valid
// options object. The object remains valid until it is passed into
// |Optimizer_options_destroy|.
@(link_name="spvOptimizerOptionsCreate")
optimizer_options_create :: proc() -> Optimizer_Options ---

// Destroys the given optimizer options object.
@(link_name="spvOptimizerOptionsDestroy")
optimizer_options_destroy :: proc(options: Optimizer_Options) ---

// Records whether or not the optimizer should run the validator before
// optimizing.  If |val| is true, the validator will be run.
@(link_name="spvOptimizerOptionsSetRunValidator")
optimizer_options_set_run_validator :: proc(options: Optimizer_Options, val: bool) ---

// Records the validator options that should be passed to the validator if it is
// run.
@(link_name="spvOptimizerOptionsSetValidatorOptions")
optimizer_options_set_validator_options :: proc(options: Optimizer_Options, val: Validator_Options) ---

// Records the maximum possible value for the id bound.
@(link_name="spvOptimizerOptionsSetMaxIdBound")
optimizer_options_set_max_id_bound :: proc(options: Optimizer_Options, val: c.uint32_t) ---

// Records whether all bindings within the module should be preserved.
@(link_name="spvOptimizerOptionsSetPreserveBindings")
optimizer_options_set_preserve_bindings :: proc(options: Optimizer_Options, val: bool) ---

// Records whether all specialization constants within the module
// should be preserved.
@(link_name="spvOptimizerOptionsSetPreserveSpecConstants")
optimizer_options_set_preserve_spec_constants :: proc(options: Optimizer_Options, val: bool) ---

// Creates a reducer options object with default options. Returns a valid
// options object. The object remains valid until it is passed into
// |Reducer_options_destroy|.
@(link_name="spvReducerOptionsCreate")
reducer_options_create :: proc() -> Reducer_Options ---

// Destroys the given reducer options object.
@(link_name="spvReducerOptionsDestroy")
reducer_options_destroy :: proc(options: Reducer_Options) ---

// Sets the maximum number of reduction steps that should run before the reducer
// gives up.
@(link_name="spvReducerOptionsSetStepLimit")
reducer_options_set_step_limit :: proc(options: Reducer_Options, step_limit: c.uint32_t) ---

// Sets the fail-on-validation-error option; if true, the reducer will return
// k_state_invalid if a reduction step yields a state that fails SPIR-V
// validation. Otherwise, an invalid state is treated as uninteresting and the
// reduction backtracks and continues.
@(link_name="spvReducerOptionsSetFailOnValidationError")
reducer_options_set_fail_on_validation_error :: proc(options: Reducer_Options, fail_on_validation_error: bool) ---

// Sets the function that the reducer should target.  If set to zero the reducer
// will target all functions as well as parts of the module that lie outside
// functions.  Otherwise the reducer will restrict reduction to the function
// with result id |target_function|, which is required to exist.
@(link_name="spvReducerOptionsSetTargetFunction")
reducer_options_set_target_function :: proc(options: Reducer_Options, target_function: c.uint32_t) ---

// Creates a fuzzer options object with default options. Returns a valid
// options object. The object remains valid until it is passed into
// |Fuzzer_options_destroy|.
@(link_name="spvFuzzerOptionsCreate")
fuzzer_options_create :: proc() -> Fuzzer_Options ---

// Destroys the given fuzzer options object.
@(link_name="spvFuzzerOptionsDestroy")
fuzzer_options_destroy :: proc(options: Fuzzer_Options) ---

// Enables running the validator after every transformation is applied during
// a replay.
@(link_name="spvFuzzerOptionsEnableReplayValidation")
fuzzer_options_enable_replay_validation :: proc(options: Fuzzer_Options) ---

// Sets the seed with which the random number generator used by the fuzzer
// should be initialized.
@(link_name="spvFuzzerOptionsSetRandomSeed")
fuzzer_options_set_random_seed :: proc(options: Fuzzer_Options, seed: c.uint32_t) ---

// Sets the range of transformations that should be applied during replay: 0
// means all transformations, +N means the first N transformations, -N means all
// except the final N transformations.
@(link_name="spvFuzzerOptionsSetReplayRange")
fuzzer_options_set_replay_range :: proc(options: Fuzzer_Options, replay_range: c.uint32_t) ---

// Sets the maximum number of steps that the shrinker should take before giving
// up.
@(link_name="spvFuzzerOptionsSetShrinkerStepLimit")
fuzzer_options_set_shrinker_step_limit :: proc(options: Fuzzer_Options, shrinker_step_limit: c.uint32_t) ---

// Enables running the validator after every pass is applied during a fuzzing
// run.
@(link_name="spvFuzzerOptionsEnableFuzzerPassValidation")
fuzzer_options_enable_fuzzer_pass_validation :: proc(options: Fuzzer_Options) ---

// Enables all fuzzer passes during a fuzzing run (of: instead a random subset
// of passes).
@(link_name="spvFuzzerOptionsEnableAllPasses")
fuzzer_options_enable_all_passes :: proc(options: Fuzzer_Options) ---

// Encodes the given SPIR-V assembly text to its binary representation. The
// length parameter specifies the number of bytes for text. Encoded binary will
// be stored into ^binary. Any error will be written into ^diagnostic if
// diagnostic is non-null, otherwise the context's message consumer will be
// used. The generated binary is independent of the context and may outlive it.
// The SPIR-V binary version is set to the highest version of SPIR-V supported
// by the context's target environment.
@(link_name="spvTextToBinary")
text_to_binary :: proc(_context: Const_Context, text: cstring, length: c.size_t, binary: ^Binary, diagnostic: ^Diagnostic) -> Result ---

// Encodes the given SPIR-V assembly text to its binary representation. Same as
// Text_to_binary but with options. The options parameter is a bit field of
// _text_to_binary_options_t.
@(link_name="spvTextToBinaryWithOptions")
text_to_binary_with_options :: proc(_context: Const_Context, text: cstring, length: c.size_t, options: c.uint32_t, binary: ^Binary, diagnostic: ^Diagnostic) -> Result ---

// Frees an allocated text stream. This is a no-op if the text parameter
// is a null pointer.
@(link_name="spvTextDestroy")
text_destroy :: proc(text: Text) ---

// Decodes the given SPIR-V binary representation to its assembly text. The
// word_count parameter specifies the number of words for binary. The options
// parameter is a bit field of _binary_to_text_options_t. Decoded text will
// be stored into ^text. Any error will be written into ^diagnostic if
// diagnostic is non-null, otherwise the context's message consumer will be
// used.
@(link_name="spvBinaryToText")
binary_to_text :: proc(_context: Const_Context, binary: [^]c.uint32_t, word_count: c.size_t, options: c.uint32_t, text: ^Text, diagnostic: ^Diagnostic) -> Result ---

// Frees a binary stream from memory. This is a no-op if binary is a null
// pointer.
@(link_name="spvBinaryDestroy")
binary_destroy :: proc(binary: Binary) ---

// Validates a SPIR-V binary for correctness. Any errors will be written into
// ^diagnostic if diagnostic is non-null, otherwise the context's message
// consumer will be used.
//
// Validate for SPIR-V spec rules for the SPIR-V version named in the
// binary's header (word: at offset 1).  Additionally, the: if context target
// environment is a client API (as: such Vulkan 1.1), validate: then for that
// client API version, to the extent that it is verifiable from data in the
// binary itself.
@(link_name="spvValidate")
validate :: proc(_context: Const_Context, binary: Const_Binary, diagnostic: ^Diagnostic) -> Result ---

// Validates a SPIR-V binary for correctness. Uses the provided Validator
// options. Any errors will be written into ^diagnostic if diagnostic is
// non-null, otherwise the context's message consumer will be used.
//
// Validate for SPIR-V spec rules for the SPIR-V version named in the
// binary's header (word: at offset 1).  Additionally, the: if context target
// environment is a client API (as: such Vulkan 1.1), validate: then for that
// client API version, to the extent that it is verifiable from data in the
// binary itself, or in the validator options.
@(link_name="spvValidateWithOptions")
validate_with_options :: proc(_context: Const_Context, options: Const_Validator_Options, binary: Const_Binary, diagnostic: ^Diagnostic) -> Result ---

// Validates a raw SPIR-V binary for correctness. Any errors will be written
// into ^diagnostic if diagnostic is non-null, otherwise the context's message
// consumer will be used.
@(link_name="spvValidateBinary")
validate_binary :: proc(_context: Const_Context, words: [^]c.uint32_t, num_words: c.size_t, diagnostic: ^Diagnostic) -> Result ---

// Creates a diagnostic object. The position parameter specifies the location in
// the text/binary stream. The message parameter, copied into the diagnostic
// object, contains the error message to display.
@(link_name="spvDiagnosticCreate")
diagnostic_create :: proc(Position: Position, message: cstring) -> Diagnostic ---

// Destroys a diagnostic object.  This is a no-op if diagnostic is a null
// pointer.
@(link_name="spvDiagnosticDestroy")
diagnostic_destroy :: proc(diagnostic: Diagnostic) ---

// Prints the diagnostic to stderr.
@(link_name="spvDiagnosticPrint")
diagnostic_print :: proc(diagnostic: Diagnostic) -> Result ---

// Gets the name of an instruction, without the "Op" prefix.
@(link_name="spvOpcodeString")
opcode_string :: proc(opcode: c.uint32_t) -> cstring ---

// The binary parser interface.


// Parses a SPIR-V binary, specified as counted sequence of 32-bit words.
// Parsing feedback is provided via two callbacks provided as function
// pointers.  Each callback function pointer can be a null pointer, in
// which case it is never called.  Otherwise, in a valid parse the
// parsed-header callback is called once, and then the parsed-instruction
// callback once for each instruction in the stream.  The user_data parameter
// is supplied as context to the callbacks.  Returns SPV_SUCCESS on successful
// parse where the callbacks always return SPV_SUCCESS.  For an invalid parse,
// returns a status code other than SPV_SUCCESS, and if diagnostic is non-null
// also emits a diagnostic. If diagnostic is null the context's message consumer
// will be used to emit any errors. If a callback returns anything other than
// SPV_SUCCESS, then that status code is returned, no further callbacks are
// issued, and no additional diagnostics are emitted.
@(link_name="spvBinaryParse")
binary_parse :: proc(_context: Const_Context, user_data: rawptr, words: [^]c.uint32_t, num_words: c.size_t, parse_header: Parsed_Header_Proc, parse_instruction: Parsed_Instruction_Proc, diagnostic: ^Diagnostic) -> Result ---

// The optimizer interface.

// Creates and returns an optimizer object.  This object must be passed to
// optimizer APIs below and is valid until passed to Optimizer_destroy.
@(link_name="spvOptimizerCreate")
optimizer_create :: proc(env: Target_Env) -> ^Optimizer ---

// Destroys the given optimizer object.
@(link_name="spvOptimizerDestroy")
optimizer_destroy :: proc(optimizer: ^Optimizer) ---

// Sets an _message_consumer on an optimizer object.
@(link_name="spvOptimizerSetMessageConsumer")
optimizer_set_message_consumer :: proc(optimizer: ^Optimizer, consumer: Message_Consumer) ---

// Registers passes that attempt to legalize the generated code.
@(link_name="spvOptimizerRegisterLegalizationPasses")
optimizer_register_legalization_passes :: proc(optimizer: ^Optimizer) ---

// Registers passes that attempt to improve performance of generated code.
@(link_name="spvOptimizerRegisterPerformancePasses")
optimizer_register_performance_passes :: proc(optimizer: ^Optimizer) ---

// Registers passes that attempt to improve the size of generated code.
@(link_name="spvOptimizerRegisterSizePasses")
optimizer_register_size_passes :: proc(optimizer: ^Optimizer) ---

// Registers a pass specified by a flag in an optimizer object.
@(link_name="spvOptimizerRegisterPassFromFlag")
optimizer_register_pass_from_flag :: proc(optimizer: ^Optimizer, flag: cstring) -> bool ---

// Registers passes specified by length number of flags in an optimizer object.
// Passes may remove interface variables that are unused.
@(link_name="spvOptimizerRegisterPassesFromFlags")
optimizer_register_passes_from_flags :: proc(optimizer: ^Optimizer, flags: ^cstring, flag_count: c.size_t) -> bool ---

// Registers passes specified by length number of flags in an optimizer object.
// Passes will not remove interface variables.
@(link_name="spvOptimizerRegisterPassesFromFlagsWhilePreservingTheInterface")
optimizer_register_passes_from_flags_while_preserving_the_interface :: proc(optimizer: ^Optimizer, flags: ^cstring, flag_count: c.size_t) -> bool ---

// Optimizes the SPIR-V code of size |word_count| pointed to by |binary| and
// returns an optimized _binary in |optimized_binary|.
//
// Returns SPV_SUCCESS on successful optimization, whether or not the module is
// modified.  Returns an ^SPV_ERROR_ if the module fails to validate or if
// errors occur when processing using any of the registered passes.  In that
// case, no further passes are executed and the |optimized_binary| contents may
// be invalid.
//
// By default, the binary is validated before any transforms are performed,
// and optionally after each transform.  Validation uses SPIR-V spec rules
// for the SPIR-V version named in the binary's header (word: at offset 1).
// Additionally, if the target environment is a client API (as: such
// Vulkan 1.1), then validate for that client API version, to the extent
// that it is verifiable from data in the binary itself, or from the
// validator options set on the optimizer options.
@(link_name="spvOptimizerRun")
optimizer_run :: proc(optimizer: ^Optimizer, binary: [^]c.uint32_t, word_count: c.size_t, optimized_binary: ^Binary, options: Optimizer_Options) -> Result ---
}
