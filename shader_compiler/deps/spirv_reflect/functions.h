
/*! @fn spvReflectCreateShaderModule

 @param  size      Size in bytes of SPIR-V code.
 @param  p_code    Pointer to SPIR-V code.
 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @return           SPV_REFLECT_RESULT_SUCCESS on success.

*/
SpvReflectResult spvReflectCreateShaderModule( size_t                   size, const void*              p_code, SpvReflectShaderModule*  p_module);

/*! @fn spvReflectCreateShaderModule2

 @param  flags     Flags for module creations.
 @param  size      Size in bytes of SPIR-V code.
 @param  p_code    Pointer to SPIR-V code.
 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @return           SPV_REFLECT_RESULT_SUCCESS on success.

*/
SpvReflectResult spvReflectCreateShaderModule2( SpvReflectModuleFlags    flags, size_t                   size, const void*              p_code, SpvReflectShaderModule*  p_module);

// SPV_REFLECT_DEPRECATED("renamed to spvReflectCreateShaderModule")
// SpvReflectResult spvReflectGetShaderModule( size_t                   size, const void*              p_code, SpvReflectShaderModule*  p_module);


/*! @fn spvReflectDestroyShaderModule

 @param  p_module  Pointer to an instance of SpvReflectShaderModule.

*/
void spvReflectDestroyShaderModule(SpvReflectShaderModule* p_module);


/*! @fn spvReflectGetCodeSize

 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @return           Returns the size of the SPIR-V in bytes

*/
uint32_t spvReflectGetCodeSize(const SpvReflectShaderModule* p_module);


/*! @fn spvReflectGetCode

 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @return           Returns a const pointer to the compiled SPIR-V bytecode.

*/
const uint32_t* spvReflectGetCode(const SpvReflectShaderModule* p_module);

/*! @fn spvReflectGetEntryPoint

 @param  p_module     Pointer to an instance of SpvReflectShaderModule.
 @param  entry_point  Name of the requested entry point.
 @return              Returns a const pointer to the requested entry point,
                      or NULL if it's not found.
*/
const SpvReflectEntryPoint* spvReflectGetEntryPoint( const SpvReflectShaderModule* p_module, const char*                   entry_point);

/*! @fn spvReflectEnumerateDescriptorBindings

 @param  p_module     Pointer to an instance of SpvReflectShaderModule.
 @param  p_count      If pp_bindings is NULL, the module's descriptor binding
                      count (across all descriptor sets) will be stored here.
                      If pp_bindings is not NULL, *p_count must contain the
                      module's descriptor binding count.
 @param  pp_bindings  If NULL, the module's total descriptor binding count
                      will be written to *p_count.
                      If non-NULL, pp_bindings must point to an array with
                      *p_count entries, where pointers to the module's
                      descriptor bindings will be written. The caller must not
                      free the binding pointers written to this array.
 @return              If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                      Otherwise, the error code indicates the cause of the
                      failure.

*/
SpvReflectResult spvReflectEnumerateDescriptorBindings( const SpvReflectShaderModule*  p_module, uint32_t*                      p_count, SpvReflectDescriptorBinding**  pp_bindings);

/*! @fn spvReflectEnumerateEntryPointDescriptorBindings
 @brief  Creates a listing of all descriptor bindings that are used in the
         static call tree of the given entry point.
 @param  p_module     Pointer to an instance of SpvReflectShaderModule.
 @param  entry_point  The name of the entry point to get the descriptor bindings for.
 @param  p_count      If pp_bindings is NULL, the entry point's descriptor binding
                      count (across all descriptor sets) will be stored here.
                      If pp_bindings is not NULL, *p_count must contain the
                      entry points's descriptor binding count.
 @param  pp_bindings  If NULL, the entry point's total descriptor binding count
                      will be written to *p_count.
                      If non-NULL, pp_bindings must point to an array with
                      *p_count entries, where pointers to the entry point's
                      descriptor bindings will be written. The caller must not
                      free the binding pointers written to this array.
 @return              If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                      Otherwise, the error code indicates the cause of the
                      failure.

*/
SpvReflectResult spvReflectEnumerateEntryPointDescriptorBindings( const SpvReflectShaderModule* p_module, const char*                   entry_point, uint32_t*                     p_count, SpvReflectDescriptorBinding** pp_bindings);

/*! @fn spvReflectEnumerateDescriptorSets

 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @param  p_count   If pp_sets is NULL, the module's descriptor set
                   count will be stored here.
                   If pp_sets is not NULL, *p_count must contain the
                   module's descriptor set count.
 @param  pp_sets   If NULL, the module's total descriptor set count
                   will be written to *p_count.
                   If non-NULL, pp_sets must point to an array with
                   *p_count entries, where pointers to the module's
                   descriptor sets will be written. The caller must not
                   free the descriptor set pointers written to this array.
 @return           If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                   Otherwise, the error code indicates the cause of the
                   failure.

*/
SpvReflectResult spvReflectEnumerateDescriptorSets( const SpvReflectShaderModule* p_module, uint32_t*                     p_count, SpvReflectDescriptorSet**     pp_sets);

/*! @fn spvReflectEnumerateEntryPointDescriptorSets
 @brief  Creates a listing of all descriptor sets and their bindings that are
         used in the static call tree of a given entry point.
 @param  p_module    Pointer to an instance of SpvReflectShaderModule.
 @param  entry_point The name of the entry point to get the descriptor bindings for.
 @param  p_count     If pp_sets is NULL, the module's descriptor set
                     count will be stored here.
                     If pp_sets is not NULL, *p_count must contain the
                     module's descriptor set count.
 @param  pp_sets     If NULL, the module's total descriptor set count
                     will be written to *p_count.
                     If non-NULL, pp_sets must point to an array with
                     *p_count entries, where pointers to the module's
                     descriptor sets will be written. The caller must not
                     free the descriptor set pointers written to this array.
 @return             If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                     Otherwise, the error code indicates the cause of the
                     failure.

*/
SpvReflectResult spvReflectEnumerateEntryPointDescriptorSets( const SpvReflectShaderModule* p_module, const char*                   entry_point, uint32_t*                     p_count, SpvReflectDescriptorSet**     pp_sets);


/*! @fn spvReflectEnumerateInterfaceVariables
 @brief  If the module contains multiple entry points, this will only get
         the interface variables for the first one.
 @param  p_module      Pointer to an instance of SpvReflectShaderModule.
 @param  p_count       If pp_variables is NULL, the module's interface variable
                       count will be stored here.
                       If pp_variables is not NULL, *p_count must contain
                       the module's interface variable count.
 @param  pp_variables  If NULL, the module's interface variable count will be
                       written to *p_count.
                       If non-NULL, pp_variables must point to an array with
                       *p_count entries, where pointers to the module's
                       interface variables will be written. The caller must not
                       free the interface variables written to this array.
 @return               If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                       Otherwise, the error code indicates the cause of the
                       failure.

*/
SpvReflectResult spvReflectEnumerateInterfaceVariables( const SpvReflectShaderModule* p_module, uint32_t*                     p_count, SpvReflectInterfaceVariable** pp_variables);

/*! @fn spvReflectEnumerateEntryPointInterfaceVariables
 @brief  Enumerate the interface variables for a given entry point.
 @param  entry_point The name of the entry point to get the interface variables for.
 @param  p_module      Pointer to an instance of SpvReflectShaderModule.
 @param  p_count       If pp_variables is NULL, the entry point's interface variable
                       count will be stored here.
                       If pp_variables is not NULL, *p_count must contain
                       the entry point's interface variable count.
 @param  pp_variables  If NULL, the entry point's interface variable count will be
                       written to *p_count.
                       If non-NULL, pp_variables must point to an array with
                       *p_count entries, where pointers to the entry point's
                       interface variables will be written. The caller must not
                       free the interface variables written to this array.
 @return               If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                       Otherwise, the error code indicates the cause of the
                       failure.

*/
SpvReflectResult spvReflectEnumerateEntryPointInterfaceVariables( const SpvReflectShaderModule* p_module, const char*                   entry_point, uint32_t*                     p_count, SpvReflectInterfaceVariable** pp_variables);


/*! @fn spvReflectEnumerateInputVariables
 @brief  If the module contains multiple entry points, this will only get
         the input variables for the first one.
 @param  p_module      Pointer to an instance of SpvReflectShaderModule.
 @param  p_count       If pp_variables is NULL, the module's input variable
                       count will be stored here.
                       If pp_variables is not NULL, *p_count must contain
                       the module's input variable count.
 @param  pp_variables  If NULL, the module's input variable count will be
                       written to *p_count.
                       If non-NULL, pp_variables must point to an array with
                       *p_count entries, where pointers to the module's
                       input variables will be written. The caller must not
                       free the interface variables written to this array.
 @return               If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                       Otherwise, the error code indicates the cause of the
                       failure.

*/
SpvReflectResult spvReflectEnumerateInputVariables( const SpvReflectShaderModule* p_module, uint32_t*                     p_count, SpvReflectInterfaceVariable** pp_variables);

/*! @fn spvReflectEnumerateEntryPointInputVariables
 @brief  Enumerate the input variables for a given entry point.
 @param  entry_point The name of the entry point to get the input variables for.
 @param  p_module      Pointer to an instance of SpvReflectShaderModule.
 @param  p_count       If pp_variables is NULL, the entry point's input variable
                       count will be stored here.
                       If pp_variables is not NULL, *p_count must contain
                       the entry point's input variable count.
 @param  pp_variables  If NULL, the entry point's input variable count will be
                       written to *p_count.
                       If non-NULL, pp_variables must point to an array with
                       *p_count entries, where pointers to the entry point's
                       input variables will be written. The caller must not
                       free the interface variables written to this array.
 @return               If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                       Otherwise, the error code indicates the cause of the
                       failure.

*/
SpvReflectResult spvReflectEnumerateEntryPointInputVariables( const SpvReflectShaderModule* p_module, const char*                   entry_point, uint32_t*                     p_count, SpvReflectInterfaceVariable** pp_variables);


/*! @fn spvReflectEnumerateOutputVariables
 @brief  Note: If the module contains multiple entry points, this will only get
         the output variables for the first one.
 @param  p_module      Pointer to an instance of SpvReflectShaderModule.
 @param  p_count       If pp_variables is NULL, the module's output variable
                       count will be stored here.
                       If pp_variables is not NULL, *p_count must contain
                       the module's output variable count.
 @param  pp_variables  If NULL, the module's output variable count will be
                       written to *p_count.
                       If non-NULL, pp_variables must point to an array with
                       *p_count entries, where pointers to the module's
                       output variables will be written. The caller must not
                       free the interface variables written to this array.
 @return               If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                       Otherwise, the error code indicates the cause of the
                       failure.

*/
SpvReflectResult spvReflectEnumerateOutputVariables( const SpvReflectShaderModule* p_module, uint32_t*                     p_count, SpvReflectInterfaceVariable** pp_variables);

/*! @fn spvReflectEnumerateEntryPointOutputVariables
 @brief  Enumerate the output variables for a given entry point.
 @param  p_module      Pointer to an instance of SpvReflectShaderModule.
 @param  entry_point   The name of the entry point to get the output variables for.
 @param  p_count       If pp_variables is NULL, the entry point's output variable
                       count will be stored here.
                       If pp_variables is not NULL, *p_count must contain
                       the entry point's output variable count.
 @param  pp_variables  If NULL, the entry point's output variable count will be
                       written to *p_count.
                       If non-NULL, pp_variables must point to an array with
                       *p_count entries, where pointers to the entry point's
                       output variables will be written. The caller must not
                       free the interface variables written to this array.
 @return               If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                       Otherwise, the error code indicates the cause of the
                       failure.

*/
SpvReflectResult spvReflectEnumerateEntryPointOutputVariables( const SpvReflectShaderModule* p_module, const char*                   entry_point, uint32_t*                     p_count, SpvReflectInterfaceVariable** pp_variables);


/*! @fn spvReflectEnumeratePushConstantBlocks
 @brief  Note: If the module contains multiple entry points, this will only get
         the push constant blocks for the first one.
 @param  p_module   Pointer to an instance of SpvReflectShaderModule.
 @param  p_count    If pp_blocks is NULL, the module's push constant
                    block count will be stored here.
                    If pp_blocks is not NULL, *p_count must
                    contain the module's push constant block count.
 @param  pp_blocks  If NULL, the module's push constant block count
                    will be written to *p_count.
                    If non-NULL, pp_blocks must point to an
                    array with *p_count entries, where pointers to
                    the module's push constant blocks will be written.
                    The caller must not free the block variables written
                    to this array.
 @return            If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                    Otherwise, the error code indicates the cause of the
                    failure.

*/
SpvReflectResult spvReflectEnumeratePushConstantBlocks( const SpvReflectShaderModule* p_module, uint32_t*                     p_count, SpvReflectBlockVariable**     pp_blocks);
// SPV_REFLECT_DEPRECATED("renamed to spvReflectEnumeratePushConstantBlocks")
// SpvReflectResult spvReflectEnumeratePushConstants( const SpvReflectShaderModule* p_module, uint32_t*                     p_count, SpvReflectBlockVariable**     pp_blocks);

/*! @fn spvReflectEnumerateEntryPointPushConstantBlocks
 @brief  Enumerate the push constant blocks used in the static call tree of a
         given entry point.
 @param  p_module   Pointer to an instance of SpvReflectShaderModule.
 @param  p_count    If pp_blocks is NULL, the entry point's push constant
                    block count will be stored here.
                    If pp_blocks is not NULL, *p_count must
                    contain the entry point's push constant block count.
 @param  pp_blocks  If NULL, the entry point's push constant block count
                    will be written to *p_count.
                    If non-NULL, pp_blocks must point to an
                    array with *p_count entries, where pointers to
                    the entry point's push constant blocks will be written.
                    The caller must not free the block variables written
                    to this array.
 @return            If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                    Otherwise, the error code indicates the cause of the
                    failure.

*/
SpvReflectResult spvReflectEnumerateEntryPointPushConstantBlocks( const SpvReflectShaderModule* p_module, const char*                   entry_point, uint32_t*                     p_count, SpvReflectBlockVariable**     pp_blocks);


/*! @fn spvReflectEnumerateSpecializationConstants
 @param  p_module      Pointer to an instance of SpvReflectShaderModule.
 @param  p_count       If pp_blocks is NULL, the module's specialization constant
                       count will be stored here. If pp_blocks is not NULL, *p_count
                       must contain the module's specialization constant count.
 @param  pp_constants  If NULL, the module's specialization constant count
                       will be written to *p_count. If non-NULL, pp_blocks must
                       point to an array with *p_count entries, where pointers to
                       the module's specialization constant blocks will be written.
                       The caller must not free the  variables written to this array.
 @return               If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                       Otherwise, the error code indicates the cause of the failure.
*/
SpvReflectResult spvReflectEnumerateSpecializationConstants( const SpvReflectShaderModule*      p_module, uint32_t*                          p_count, SpvReflectSpecializationConstant** pp_constants);

/*! @fn spvReflectGetDescriptorBinding

 @param  p_module        Pointer to an instance of SpvReflectShaderModule.
 @param  binding_number  The "binding" value of the requested descriptor
                         binding.
 @param  set_number      The "set" value of the requested descriptor binding.
 @param  p_result        If successful, SPV_REFLECT_RESULT_SUCCESS will be
                         written to *p_result. Otherwise, a error code
                         indicating the cause of the failure will be stored
                         here.
 @return                 If the module contains a descriptor binding that
                         matches the provided [binding_number, set_number]
                         values, a pointer to that binding is returned. The
                         caller must not free this pointer.
                         If no match can be found, or if an unrelated error
                         occurs, the return value will be NULL. Detailed
                         error results are written to *pResult.
@note                    If the module contains multiple desriptor bindings
                         with the same set and binding numbers, there are
                         no guarantees about which binding will be returned.

*/
const SpvReflectDescriptorBinding* spvReflectGetDescriptorBinding( const SpvReflectShaderModule* p_module, uint32_t                      binding_number, uint32_t                      set_number, SpvReflectResult*             p_result);

/*! @fn spvReflectGetEntryPointDescriptorBinding
 @brief  Get the descriptor binding with the given binding number and set
         number that is used in the static call tree of a certain entry
         point.
 @param  p_module        Pointer to an instance of SpvReflectShaderModule.
 @param  entry_point     The entry point to get the binding from.
 @param  binding_number  The "binding" value of the requested descriptor
                         binding.
 @param  set_number      The "set" value of the requested descriptor binding.
 @param  p_result        If successful, SPV_REFLECT_RESULT_SUCCESS will be
                         written to *p_result. Otherwise, a error code
                         indicating the cause of the failure will be stored
                         here.
 @return                 If the entry point contains a descriptor binding that
                         matches the provided [binding_number, set_number]
                         values, a pointer to that binding is returned. The
                         caller must not free this pointer.
                         If no match can be found, or if an unrelated error
                         occurs, the return value will be NULL. Detailed
                         error results are written to *pResult.
@note                    If the entry point contains multiple desriptor bindings
                         with the same set and binding numbers, there are
                         no guarantees about which binding will be returned.

*/
const SpvReflectDescriptorBinding* spvReflectGetEntryPointDescriptorBinding( const SpvReflectShaderModule* p_module, const char*                   entry_point, uint32_t                      binding_number, uint32_t                      set_number, SpvReflectResult*             p_result);


/*! @fn spvReflectGetDescriptorSet

 @param  p_module    Pointer to an instance of SpvReflectShaderModule.
 @param  set_number  The "set" value of the requested descriptor set.
 @param  p_result    If successful, SPV_REFLECT_RESULT_SUCCESS will be
                     written to *p_result. Otherwise, a error code
                     indicating the cause of the failure will be stored
                     here.
 @return             If the module contains a descriptor set with the
                     provided set_number, a pointer to that set is
                     returned. The caller must not free this pointer.
                     If no match can be found, or if an unrelated error
                     occurs, the return value will be NULL. Detailed
                     error results are written to *pResult.

*/
const SpvReflectDescriptorSet* spvReflectGetDescriptorSet( const SpvReflectShaderModule* p_module, uint32_t                      set_number, SpvReflectResult*             p_result);

/*! @fn spvReflectGetEntryPointDescriptorSet

 @param  p_module    Pointer to an instance of SpvReflectShaderModule.
 @param  entry_point The entry point to get the descriptor set from.
 @param  set_number  The "set" value of the requested descriptor set.
 @param  p_result    If successful, SPV_REFLECT_RESULT_SUCCESS will be
                     written to *p_result. Otherwise, a error code
                     indicating the cause of the failure will be stored
                     here.
 @return             If the entry point contains a descriptor set with the
                     provided set_number, a pointer to that set is
                     returned. The caller must not free this pointer.
                     If no match can be found, or if an unrelated error
                     occurs, the return value will be NULL. Detailed
                     error results are written to *pResult.

*/
const SpvReflectDescriptorSet* spvReflectGetEntryPointDescriptorSet( const SpvReflectShaderModule* p_module, const char*                   entry_point, uint32_t                      set_number, SpvReflectResult*             p_result);


/* @fn spvReflectGetInputVariableByLocation

 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @param  location  The "location" value of the requested input variable.
                   A location of 0xFFFFFFFF will always return NULL
                   with *p_result == ELEMENT_NOT_FOUND.
 @param  p_result  If successful, SPV_REFLECT_RESULT_SUCCESS will be
                   written to *p_result. Otherwise, a error code
                   indicating the cause of the failure will be stored
                   here.
 @return           If the module contains an input interface variable
                   with the provided location value, a pointer to that
                   variable is returned. The caller must not free this
                   pointer.
                   If no match can be found, or if an unrelated error
                   occurs, the return value will be NULL. Detailed
                   error results are written to *pResult.
@note

*/
const SpvReflectInterfaceVariable* spvReflectGetInputVariableByLocation( const SpvReflectShaderModule* p_module, uint32_t                      location, SpvReflectResult*             p_result);
// SPV_REFLECT_DEPRECATED("renamed to spvReflectGetInputVariableByLocation")
// const SpvReflectInterfaceVariable* spvReflectGetInputVariable( const SpvReflectShaderModule* p_module, uint32_t                      location, SpvReflectResult*             p_result);

/* @fn spvReflectGetEntryPointInputVariableByLocation

 @param  p_module    Pointer to an instance of SpvReflectShaderModule.
 @param  entry_point The entry point to get the input variable from.
 @param  location    The "location" value of the requested input variable.
                     A location of 0xFFFFFFFF will always return NULL
                     with *p_result == ELEMENT_NOT_FOUND.
 @param  p_result    If successful, SPV_REFLECT_RESULT_SUCCESS will be
                     written to *p_result. Otherwise, a error code
                     indicating the cause of the failure will be stored
                     here.
 @return             If the entry point contains an input interface variable
                     with the provided location value, a pointer to that
                     variable is returned. The caller must not free this
                     pointer.
                     If no match can be found, or if an unrelated error
                     occurs, the return value will be NULL. Detailed
                     error results are written to *pResult.
@note

*/
const SpvReflectInterfaceVariable* spvReflectGetEntryPointInputVariableByLocation( const SpvReflectShaderModule* p_module, const char*                   entry_point, uint32_t                      location, SpvReflectResult*             p_result);

/* @fn spvReflectGetInputVariableBySemantic

 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @param  semantic  The "semantic" value of the requested input variable.
                   A semantic of NULL will return NULL.
                   A semantic of "" will always return NULL with
                   *p_result == ELEMENT_NOT_FOUND.
 @param  p_result  If successful, SPV_REFLECT_RESULT_SUCCESS will be
                   written to *p_result. Otherwise, a error code
                   indicating the cause of the failure will be stored
                   here.
 @return           If the module contains an input interface variable
                   with the provided semantic, a pointer to that
                   variable is returned. The caller must not free this
                   pointer.
                   If no match can be found, or if an unrelated error
                   occurs, the return value will be NULL. Detailed
                   error results are written to *pResult.
@note

*/
const SpvReflectInterfaceVariable* spvReflectGetInputVariableBySemantic( const SpvReflectShaderModule* p_module, const char*                   semantic, SpvReflectResult*             p_result);

/* @fn spvReflectGetEntryPointInputVariableBySemantic

 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @param  entry_point The entry point to get the input variable from.
 @param  semantic  The "semantic" value of the requested input variable.
                   A semantic of NULL will return NULL.
                   A semantic of "" will always return NULL with
                   *p_result == ELEMENT_NOT_FOUND.
 @param  p_result  If successful, SPV_REFLECT_RESULT_SUCCESS will be
                   written to *p_result. Otherwise, a error code
                   indicating the cause of the failure will be stored
                   here.
 @return           If the entry point contains an input interface variable
                   with the provided semantic, a pointer to that
                   variable is returned. The caller must not free this
                   pointer.
                   If no match can be found, or if an unrelated error
                   occurs, the return value will be NULL. Detailed
                   error results are written to *pResult.
@note

*/
const SpvReflectInterfaceVariable* spvReflectGetEntryPointInputVariableBySemantic( const SpvReflectShaderModule* p_module, const char*                   entry_point, const char*                   semantic, SpvReflectResult*             p_result);

/* @fn spvReflectGetOutputVariableByLocation

 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @param  location  The "location" value of the requested output variable.
                   A location of 0xFFFFFFFF will always return NULL
                   with *p_result == ELEMENT_NOT_FOUND.
 @param  p_result  If successful, SPV_REFLECT_RESULT_SUCCESS will be
                   written to *p_result. Otherwise, a error code
                   indicating the cause of the failure will be stored
                   here.
 @return           If the module contains an output interface variable
                   with the provided location value, a pointer to that
                   variable is returned. The caller must not free this
                   pointer.
                   If no match can be found, or if an unrelated error
                   occurs, the return value will be NULL. Detailed
                   error results are written to *pResult.
@note

*/
const SpvReflectInterfaceVariable* spvReflectGetOutputVariableByLocation( const SpvReflectShaderModule*  p_module, uint32_t                       location, SpvReflectResult*              p_result);
// SPV_REFLECT_DEPRECATED("renamed to spvReflectGetOutputVariableByLocation")
// const SpvReflectInterfaceVariable* spvReflectGetOutputVariable( const SpvReflectShaderModule*  p_module, uint32_t                       location, SpvReflectResult*              p_result);

/* @fn spvReflectGetEntryPointOutputVariableByLocation

 @param  p_module     Pointer to an instance of SpvReflectShaderModule.
 @param  entry_point  The entry point to get the output variable from.
 @param  location     The "location" value of the requested output variable.
                      A location of 0xFFFFFFFF will always return NULL
                      with *p_result == ELEMENT_NOT_FOUND.
 @param  p_result     If successful, SPV_REFLECT_RESULT_SUCCESS will be
                      written to *p_result. Otherwise, a error code
                      indicating the cause of the failure will be stored
                      here.
 @return              If the entry point contains an output interface variable
                      with the provided location value, a pointer to that
                      variable is returned. The caller must not free this
                      pointer.
                      If no match can be found, or if an unrelated error
                      occurs, the return value will be NULL. Detailed
                      error results are written to *pResult.
@note

*/
const SpvReflectInterfaceVariable* spvReflectGetEntryPointOutputVariableByLocation( const SpvReflectShaderModule*  p_module, const char*                    entry_point, uint32_t                       location, SpvReflectResult*              p_result);

/* @fn spvReflectGetOutputVariableBySemantic

 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @param  semantic  The "semantic" value of the requested output variable.
                   A semantic of NULL will return NULL.
                   A semantic of "" will always return NULL with
                   *p_result == ELEMENT_NOT_FOUND.
 @param  p_result  If successful, SPV_REFLECT_RESULT_SUCCESS will be
                   written to *p_result. Otherwise, a error code
                   indicating the cause of the failure will be stored
                   here.
 @return           If the module contains an output interface variable
                   with the provided semantic, a pointer to that
                   variable is returned. The caller must not free this
                   pointer.
                   If no match can be found, or if an unrelated error
                   occurs, the return value will be NULL. Detailed
                   error results are written to *pResult.
@note

*/
const SpvReflectInterfaceVariable* spvReflectGetOutputVariableBySemantic( const SpvReflectShaderModule*  p_module, const char*                    semantic, SpvReflectResult*              p_result);

/* @fn spvReflectGetEntryPointOutputVariableBySemantic

 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @param  entry_point  The entry point to get the output variable from.
 @param  semantic  The "semantic" value of the requested output variable.
                   A semantic of NULL will return NULL.
                   A semantic of "" will always return NULL with
                   *p_result == ELEMENT_NOT_FOUND.
 @param  p_result  If successful, SPV_REFLECT_RESULT_SUCCESS will be
                   written to *p_result. Otherwise, a error code
                   indicating the cause of the failure will be stored
                   here.
 @return           If the entry point contains an output interface variable
                   with the provided semantic, a pointer to that
                   variable is returned. The caller must not free this
                   pointer.
                   If no match can be found, or if an unrelated error
                   occurs, the return value will be NULL. Detailed
                   error results are written to *pResult.
@note

*/
const SpvReflectInterfaceVariable* spvReflectGetEntryPointOutputVariableBySemantic( const SpvReflectShaderModule*  p_module, const char*                    entry_point, const char*                    semantic, SpvReflectResult*              p_result);

/*! @fn spvReflectGetPushConstantBlock

 @param  p_module  Pointer to an instance of SpvReflectShaderModule.
 @param  index     The index of the desired block within the module's
                   array of push constant blocks.
 @param  p_result  If successful, SPV_REFLECT_RESULT_SUCCESS will be
                   written to *p_result. Otherwise, a error code
                   indicating the cause of the failure will be stored
                   here.
 @return           If the provided index is within range, a pointer to
                   the corresponding push constant block is returned.
                   The caller must not free this pointer.
                   If no match can be found, or if an unrelated error
                   occurs, the return value will be NULL. Detailed
                   error results are written to *pResult.

*/
const SpvReflectBlockVariable* spvReflectGetPushConstantBlock( const SpvReflectShaderModule*  p_module, uint32_t                       index, SpvReflectResult*              p_result);
// SPV_REFLECT_DEPRECATED("renamed to spvReflectGetPushConstantBlock")
// const SpvReflectBlockVariable* spvReflectGetPushConstant( const SpvReflectShaderModule*  p_module, uint32_t                       index, SpvReflectResult*              p_result);

/*! @fn spvReflectGetEntryPointPushConstantBlock
 @brief  Get the push constant block corresponding to the given entry point.
         As by the Vulkan specification there can be no more than one push
         constant block used by a given entry point, so if there is one it will
         be returned, otherwise NULL will be returned.
 @param  p_module     Pointer to an instance of SpvReflectShaderModule.
 @param  entry_point  The entry point to get the push constant block from.
 @param  p_result     If successful, SPV_REFLECT_RESULT_SUCCESS will be
                      written to *p_result. Otherwise, a error code
                      indicating the cause of the failure will be stored
                      here.
 @return              If the provided index is within range, a pointer to
                      the corresponding push constant block is returned.
                      The caller must not free this pointer.
                      If no match can be found, or if an unrelated error
                      occurs, the return value will be NULL. Detailed
                      error results are written to *pResult.

*/
const SpvReflectBlockVariable* spvReflectGetEntryPointPushConstantBlock( const SpvReflectShaderModule*  p_module, const char*                    entry_point, SpvReflectResult*              p_result);


/*! @fn spvReflectChangeDescriptorBindingNumbers
 @brief  Assign new set and/or binding numbers to a descriptor binding.
         In addition to updating the reflection data, this function modifies
         the underlying SPIR-V bytecode. The updated code can be retrieved
         with spvReflectGetCode().  If the binding is used in multiple
         entry points within the module, it will be changed in all of them.
 @param  p_module            Pointer to an instance of SpvReflectShaderModule.
 @param  p_binding           Pointer to the descriptor binding to modify.
 @param  new_binding_number  The new binding number to assign to the
                             provided descriptor binding.
                             To leave the binding number unchanged, pass
                             SPV_REFLECT_BINDING_NUMBER_DONT_CHANGE.
 @param  new_set_number      The new set number to assign to the
                             provided descriptor binding. Successfully changing
                             a descriptor binding's set number invalidates all
                             existing SpvReflectDescriptorBinding and
                             SpvReflectDescriptorSet pointers from this module.
                             To leave the set number unchanged, pass
                             SPV_REFLECT_SET_NUMBER_DONT_CHANGE.
 @return                     If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                             Otherwise, the error code indicates the cause of
                             the failure.
*/
SpvReflectResult spvReflectChangeDescriptorBindingNumbers( SpvReflectShaderModule*            p_module, const SpvReflectDescriptorBinding* p_binding, uint32_t                           new_binding_number, uint32_t                           new_set_number);
// SPV_REFLECT_DEPRECATED("Renamed to spvReflectChangeDescriptorBindingNumbers")
// SpvReflectResult spvReflectChangeDescriptorBindingNumber( SpvReflectShaderModule*            p_module, const SpvReflectDescriptorBinding* p_descriptor_binding, uint32_t                           new_binding_number, uint32_t                           optional_new_set_number);

/*! @fn spvReflectChangeDescriptorSetNumber
 @brief  Assign a new set number to an entire descriptor set (including
         all descriptor bindings in that set).
         In addition to updating the reflection data, this function modifies
         the underlying SPIR-V bytecode. The updated code can be retrieved
         with spvReflectGetCode().  If the descriptor set is used in
         multiple entry points within the module, it will be modified in all
         of them.
 @param  p_module        Pointer to an instance of SpvReflectShaderModule.
 @param  p_set           Pointer to the descriptor binding to modify.
 @param  new_set_number  The new set number to assign to the
                         provided descriptor set, and all its descriptor
                         bindings. Successfully changing a descriptor
                         binding's set number invalidates all existing
                         SpvReflectDescriptorBinding and
                         SpvReflectDescriptorSet pointers from this module.
                         To leave the set number unchanged, pass
                         SPV_REFLECT_SET_NUMBER_DONT_CHANGE.
 @return                 If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                         Otherwise, the error code indicates the cause of
                         the failure.
*/
SpvReflectResult spvReflectChangeDescriptorSetNumber( SpvReflectShaderModule*        p_module, const SpvReflectDescriptorSet* p_set, uint32_t                       new_set_number);

/*! @fn spvReflectChangeInputVariableLocation
 @brief  Assign a new location to an input interface variable.
         In addition to updating the reflection data, this function modifies
         the underlying SPIR-V bytecode. The updated code can be retrieved
         with spvReflectGetCode().
         It is the caller's responsibility to avoid assigning the same
         location to multiple input variables.  If the input variable is used
         by multiple entry points in the module, it will be changed in all of
         them.
 @param  p_module          Pointer to an instance of SpvReflectShaderModule.
 @param  p_input_variable  Pointer to the input variable to update.
 @param  new_location      The new location to assign to p_input_variable.
 @return                   If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                           Otherwise, the error code indicates the cause of
                           the failure.

*/
SpvReflectResult spvReflectChangeInputVariableLocation( SpvReflectShaderModule*            p_module, const SpvReflectInterfaceVariable* p_input_variable, uint32_t                           new_location);


/*! @fn spvReflectChangeOutputVariableLocation
 @brief  Assign a new location to an output interface variable.
         In addition to updating the reflection data, this function modifies
         the underlying SPIR-V bytecode. The updated code can be retrieved
         with spvReflectGetCode().
         It is the caller's responsibility to avoid assigning the same
         location to multiple output variables.  If the output variable is used
         by multiple entry points in the module, it will be changed in all of
         them.
 @param  p_module          Pointer to an instance of SpvReflectShaderModule.
 @param  p_output_variable Pointer to the output variable to update.
 @param  new_location      The new location to assign to p_output_variable.
 @return                   If successful, returns SPV_REFLECT_RESULT_SUCCESS.
                           Otherwise, the error code indicates the cause of
                           the failure.

*/
SpvReflectResult spvReflectChangeOutputVariableLocation( SpvReflectShaderModule*             p_module, const SpvReflectInterfaceVariable*  p_output_variable, uint32_t                            new_location);


/*! @fn spvReflectSourceLanguage

 @param  source_lang  The source language code.
 @return Returns string of source language specified in \a source_lang.
         The caller must not free the memory associated with this string.
*/
const char* spvReflectSourceLanguage(SpvSourceLanguage source_lang);

/*! @fn spvReflectBlockVariableTypeName

 @param  p_var Pointer to block variable.
 @return Returns string of block variable's type description type name
         or NULL if p_var is NULL.
*/
const char* spvReflectBlockVariableTypeName( const SpvReflectBlockVariable* p_var);
