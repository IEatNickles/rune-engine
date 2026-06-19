package vulkan_backend

import "core:container/handle_map"
import vk "vendor:vulkan"

import ".."

Bindings_State :: struct {
  handle:     rendering.Bindings,
  pool:       vk.DescriptorPool,
  set:        vk.DescriptorSet,
  set_layout: vk.DescriptorSetLayout,
}

create_bindings :: proc(info: ^rendering.Bindings_Create_Info) -> rendering.Bindings {
  state: Bindings_State
  pool_sizes := make([]vk.DescriptorPoolSize, len(info.layout))
  defer delete(pool_sizes)
  for entry, i in info.layout {
    pool_sizes[i] = {
      type = binding_type_to_vulkan(entry.type),
      descriptorCount = 1,
    }
  }
  dp_create_info := vk.DescriptorPoolCreateInfo {
    sType = .DESCRIPTOR_POOL_CREATE_INFO,
    maxSets = 1,
    poolSizeCount = u32(len(pool_sizes)),
    pPoolSizes = raw_data(pool_sizes),
  }
  vk.CreateDescriptorPool(ctx.device, &dp_create_info, nil, &state.pool)

  dsl_bindings := make([]vk.DescriptorSetLayoutBinding, len(info.layout))
  defer delete(dsl_bindings)
  for entry, i in info.layout {
    dsl_bindings[i] = {
      binding = entry.binding,
      descriptorCount = 1,
      descriptorType = binding_type_to_vulkan(entry.type),
      stageFlags = { shader_stage_to_vulkan(entry.stage) },
    }
  }
  dsl_create_info := vk.DescriptorSetLayoutCreateInfo {
    sType = .DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
    bindingCount = u32(len(dsl_bindings)),
    pBindings = raw_data(dsl_bindings),
  }
  vk.CreateDescriptorSetLayout(ctx.device, &dsl_create_info, nil, &state.set_layout)

  alloc_info := vk.DescriptorSetAllocateInfo {
    sType = .DESCRIPTOR_SET_ALLOCATE_INFO,
    descriptorPool = state.pool,
    descriptorSetCount = 1,
    pSetLayouts = &state.set_layout,
  }
  vk.AllocateDescriptorSets(ctx.device, &alloc_info, &state.set)
  return handle_map.add(&ctx.bindings, state)
}

destroy_bindings :: proc(bindings: rendering.Bindings) {
  state := handle_map.get(&ctx.bindings, bindings)
  handle_map.remove(&ctx.bindings, bindings)
  vk.FreeDescriptorSets(ctx.device, state.pool, 1, &state.set)
  vk.DestroyDescriptorSetLayout(ctx.device, state.set_layout, nil)
  vk.DestroyDescriptorPool(ctx.device, state.pool, nil)
}

bind_bindings :: proc(bindings: rendering.Bindings) {
  state := handle_map.get(&ctx.bindings, bindings)
  vk.CmdBindDescriptorSets(ctx.command_buffer, ctx.current_pass.pipeline.bind_point, ctx.current_pass.pipeline.layout, 0, 1, &state.set, 0, nil)
}
