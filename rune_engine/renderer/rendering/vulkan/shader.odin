package vulkan_backend

import "core:slice"
import "core:container/handle_map"
import vk "vendor:vulkan"

import ".."

Shader_State :: struct {
  handle:            rendering.Shader,
  descriptor_layout: vk.DescriptorSetLayout,
  vs_module:         vk.ShaderModule,
  fs_module:         vk.ShaderModule,
  cs_module:         vk.ShaderModule,
}

create_shader_module :: proc(ctx: ^Context, shader: rendering.Shader_Func) -> (module: vk.ShaderModule) {
  code := slice.reinterpret([]u32, shader.spirv_code)
  info := vk.ShaderModuleCreateInfo {
    sType = .SHADER_MODULE_CREATE_INFO,
    pCode = raw_data(code),
    codeSize = len(code),
  }
  vk.CreateShaderModule(ctx.device, &info, nil, &module)
  return
}

create_shader :: proc(ctx: ^Context, info: ^rendering.Shader_Create_Info) -> rendering.Shader {
  state: Shader_State

  vs_module := create_shader_module(ctx, info.vs_func)
  fs_module := create_shader_module(ctx, info.fs_func)

  desc_bindings: [dynamic]vk.DescriptorSetLayoutBinding
  for name, data in info.vs_func.reflection_data.descriptor_bindings {
    binding := vk.DescriptorSetLayoutBinding {
      binding = data.binding,
      stageFlags = { .VERTEX },
      descriptorCount = 1,
    }

    switch b in data.type {
    case rendering.Sampler: binding.descriptorType = .SAMPLER
    case rendering.Combined_Image_Sampler: binding.descriptorType = .COMBINED_IMAGE_SAMPLER
    case rendering.Sampled_Image: binding.descriptorType = .SAMPLED_IMAGE
    case rendering.Storage_Image: binding.descriptorType = .STORAGE_IMAGE
    case rendering.Uniform_Buffer: binding.descriptorType = .UNIFORM_BUFFER
    case rendering.Storage_Buffer: binding.descriptorType = .STORAGE_BUFFER
    }
    append(&desc_bindings, binding)
  }
  for name, data in info.fs_func.reflection_data.descriptor_bindings {
    binding := vk.DescriptorSetLayoutBinding {
      binding = data.binding,
      stageFlags = { .FRAGMENT },
      descriptorCount = 1,
    }

    switch b in data.type {
    case rendering.Sampler: binding.descriptorType = .SAMPLER
    case rendering.Combined_Image_Sampler: binding.descriptorType = .COMBINED_IMAGE_SAMPLER
    case rendering.Sampled_Image: binding.descriptorType = .SAMPLED_IMAGE
    case rendering.Storage_Image: binding.descriptorType = .STORAGE_IMAGE
    case rendering.Uniform_Buffer: binding.descriptorType = .UNIFORM_BUFFER
    case rendering.Storage_Buffer: binding.descriptorType = .STORAGE_BUFFER
    }
    append(&desc_bindings, binding)
  }
  desc_info := vk.DescriptorSetLayoutCreateInfo {
    sType = .DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
    bindingCount = u32(len(desc_bindings)),
    pBindings = raw_data(desc_bindings),
  }
  vk.CreateDescriptorSetLayout(ctx.device, &desc_info, nil, &state.descriptor_layout)
  return handle_map.add(&ctx.shaders, state)
}

destroy_shader :: proc(ctx: ^Context, shader: rendering.Shader) {
  state := handle_map.get(&ctx.shaders, shader)
  vk.DestroyShaderModule(ctx.device, state.vs_module, nil)
  vk.DestroyShaderModule(ctx.device, state.fs_module, nil)
}
