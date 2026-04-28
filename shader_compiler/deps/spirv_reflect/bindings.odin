package spirv_reflect

when ODIN_OS == .Linux {
  foreign import spirv_reflect {
    "libspirv_reflect.a",
  }
}

import "core:c"

@(default_calling_convention="c")
foreign spirv_reflect {
  @(link_name="spvReflectCreateShaderModule")
  create_shader_module :: proc(
      size: c.size_t,
      p_code: rawptr,
      p_module: ^ShaderModule,
  ) -> Result ---;

  @(link_name="spvReflectCreateShaderModule2")
  create_shader_module2 :: proc(
      flags: ModuleFlags,
      size: c.size_t,
      p_code: rawptr,
      p_module: ^ShaderModule,
  ) -> Result ---;

  @(link_name="spvReflectDestroyShaderModule")
  destroy_shader_module :: proc(
      p_module: ^ShaderModule,
  ) ---;

  @(link_name="spvReflectGetCodeSize")
  get_code_size :: proc(
      p_module: ^ShaderModule,
  ) -> c.uint32_t ---;

  @(link_name="spvReflectGetCode")
  get_code :: proc(
      p_module: ^ShaderModule,
  ) -> ^c.uint32_t ---;

  @(link_name="spvReflectGetEntryPoint")
  get_entry_point :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
  ) -> ^EntryPoint ---;

  @(link_name="spvReflectEnumerateDescriptorBindings")
  enumerate_descriptor_bindings :: proc(
      p_module: ^ShaderModule,
      p_count: ^c.uint32_t,
      pp_bindings: ^^DescriptorBinding,
  ) -> Result ---;

  @(link_name="spvReflectEnumerateEntryPointDescriptorBindings")
  enumerate_entry_point_descriptor_bindings :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      p_count: ^c.uint32_t,
      pp_bindings: ^^DescriptorBinding,
  ) -> Result ---;

  @(link_name="spvReflectEnumerateDescriptorSets")
  enumerate_descriptor_sets :: proc(
      p_module: ^ShaderModule,
      p_count: ^c.uint32_t,
      pp_sets: ^^DescriptorSet,
  ) -> Result ---;

  @(link_name="spvReflectEnumerateEntryPointDescriptorSets")
  enumerate_entry_point_descriptor_sets :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      p_count: ^c.uint32_t,
      pp_sets: ^^DescriptorSet,
  ) -> Result ---;

  @(link_name="spvReflectEnumerateInterfaceVariables")
  enumerate_interface_variables :: proc(
      p_module: ^ShaderModule,
      p_count: ^c.uint32_t,
      pp_variables: ^^InterfaceVariable,
  ) -> Result ---;

  @(link_name="spvReflectEnumerateEntryPointInterfaceVariables")
  enumerate_entry_point_interface_variables :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      p_count: ^c.uint32_t,
      pp_variables: ^^InterfaceVariable,
  ) -> Result ---;

  @(link_name="spvReflectEnumerateInputVariables")
  enumerate_input_variables :: proc(
      p_module: ^ShaderModule,
      p_count: ^c.uint32_t,
      pp_variables: ^^InterfaceVariable,
  ) -> Result ---;

  @(link_name="spvReflectEnumerateEntryPointInputVariables")
  enumerate_entry_point_input_variables :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      p_count: ^c.uint32_t,
      pp_variables: ^^InterfaceVariable,
  ) -> Result ---;

  @(link_name="spvReflectEnumerateOutputVariables")
  enumerate_output_variables :: proc(
      p_module: ^ShaderModule,
      p_count: ^c.uint32_t,
      pp_variables: ^^InterfaceVariable,
  ) -> Result ---;

  @(link_name="spvReflectEnumerateEntryPointOutputVariables")
  enumerate_entry_point_output_variables :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      p_count: ^c.uint32_t,
      pp_variables: ^^InterfaceVariable,
  ) -> Result ---;

  @(link_name="spvReflectEnumeratePushConstantBlocks")
  enumerate_push_constant_blocks :: proc(
      p_module: ^ShaderModule,
      p_count: ^c.uint32_t,
      pp_blocks: ^^BlockVariable,
  ) -> Result ---;

  @(link_name="spvReflectEnumerateEntryPointPushConstantBlocks")
  enumerate_entry_point_push_constant_blocks :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      p_count: ^c.uint32_t,
      pp_blocks: ^^BlockVariable,
  ) -> Result ---;

  @(link_name="spvReflectEnumerateSpecializationConstants")
  enumerate_specialization_constants :: proc(
      p_module: ^ShaderModule,
      p_count: ^c.uint32_t,
      pp_constants: ^^SpecializationConstant,
  ) -> Result ---;

  @(link_name="spvReflectGetDescriptorBinding")
  get_descriptor_binding :: proc(
      p_module: ^ShaderModule,
      binding_number: c.uint32_t,
      set_number: c.uint32_t,
      p_result: ^Result,
  ) -> ^DescriptorBinding ---;

  @(link_name="spvReflectGetEntryPointDescriptorBinding")
  get_entry_point_descriptor_binding :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      binding_number: c.uint32_t,
      set_number: c.uint32_t,
      p_result: ^Result,
  ) -> ^DescriptorBinding ---;

  @(link_name="spvReflectGetDescriptorSet")
  get_descriptor_set :: proc(
      p_module: ^ShaderModule,
      set_number: c.uint32_t,
      p_result: ^Result,
  ) -> ^DescriptorSet ---;

  @(link_name="spvReflectGetEntryPointDescriptorSet")
  get_entry_point_descriptor_set :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      set_number: c.uint32_t,
      p_result: ^Result,
  ) -> ^DescriptorSet ---;

  @(link_name="spvReflectGetInputVariableByLocation")
  get_input_variable_by_location :: proc(
      p_module: ^ShaderModule,
      location: c.uint32_t,
      p_result: ^Result,
  ) -> ^InterfaceVariable ---;

  @(link_name="spvReflectGetEntryPointInputVariableByLocation")
  get_entry_point_input_variable_by_location :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      location: c.uint32_t,
      p_result: ^Result,
  ) -> ^InterfaceVariable ---;

  @(link_name="spvReflectGetInputVariableBySemantic")
  get_input_variable_by_semantic :: proc(
      p_module: ^ShaderModule,
      semantic: cstring,
      p_result: ^Result,
  ) -> ^InterfaceVariable ---;

  @(link_name="spvReflectGetEntryPointInputVariableBySemantic")
  get_entry_point_input_variable_by_semantic :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      semantic: cstring,
      p_result: ^Result,
  ) -> ^InterfaceVariable ---;

  @(link_name="spvReflectGetOutputVariableByLocation")
  get_output_variable_by_location :: proc(
      p_module: ^ShaderModule,
      location: c.uint32_t,
      p_result: ^Result,
  ) -> ^InterfaceVariable ---;

  @(link_name="spvReflectGetEntryPointOutputVariableByLocation")
  get_entry_point_output_variable_by_location :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      location: c.uint32_t,
      p_result: ^Result,
  ) -> ^InterfaceVariable ---;

  @(link_name="spvReflectGetOutputVariableBySemantic")
  get_output_variable_by_semantic :: proc(
      p_module: ^ShaderModule,
      semantic: cstring,
      p_result: ^Result,
  ) -> ^InterfaceVariable ---;

  @(link_name="spvReflectGetEntryPointOutputVariableBySemantic")
  get_entry_point_output_variable_by_semantic :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      semantic: cstring,
      p_result: ^Result,
  ) -> ^InterfaceVariable ---;

  @(link_name="spvReflectGetPushConstantBlock")
  get_push_constant_block :: proc(
      p_module: ^ShaderModule,
      index: c.uint32_t,
      p_result: ^Result,
  ) -> ^BlockVariable ---;

  @(link_name="spvReflectGetEntryPointPushConstantBlock")
  get_entry_point_push_constant_block :: proc(
      p_module: ^ShaderModule,
      entry_point: cstring,
      p_result: ^Result,
  ) -> ^BlockVariable ---;

  @(link_name="spvReflectChangeDescriptorBindingNumbers")
  change_descriptor_binding_numbers :: proc(
      p_module: ^ShaderModule,
      p_binding: ^DescriptorBinding,
      new_binding_number: c.uint32_t,
      new_set_number: c.uint32_t,
  ) -> Result ---;

  @(link_name="spvReflectChangeDescriptorSetNumber")
  change_descriptor_set_number :: proc(
      p_module: ^ShaderModule,
      p_set: ^DescriptorSet,
      new_set_number: c.uint32_t,
  ) -> Result ---;

  @(link_name="spvReflectChangeInputVariableLocation")
  change_input_variable_location :: proc(
      p_module: ^ShaderModule,
      p_input_variable: ^InterfaceVariable,
      new_location: c.uint32_t,
  ) -> Result ---;

  @(link_name="spvReflectChangeOutputVariableLocation")
  change_output_variable_location :: proc(
      p_module: ^ShaderModule,
      p_output_variable: ^InterfaceVariable,
      new_location: c.uint32_t,
  ) -> Result ---;

  @(link_name="spvReflectSourceLanguage")
  source_language :: proc(
      source_lang: SourceLanguage,
  ) -> cstring ---;

  @(link_name="spvReflectBlockVariableTypeName")
  block_variable_type_name :: proc(
      p_var: ^BlockVariable,
  ) -> cstring ---;
}
