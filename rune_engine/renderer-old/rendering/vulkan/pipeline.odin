package vulkan_backend

import "core:container/handle_map"
import vk "vendor:vulkan"

import ".."

Pipeline_State :: struct {
  handle:   rendering.Pipeline,
  pipeline: vk.Pipeline,
  shader:   rendering.Shader,
  descriptor_set: vk.DescriptorSet,
}

create_pipeline :: proc(info: ^rendering.Pipeline_Create_Info) -> rendering.Pipeline {
  shader := handle_map.get(&ctx.shaders, info.shader)
  stages := []vk.PipelineShaderStageCreateInfo {
    {
      sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
      module = shader.vs_module,
      stage = { .VERTEX },
      pName = "main",
    },
    {
      sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
      module = shader.fs_module,
      stage = { .FRAGMENT },
      pName = "main",
    }
  }

  descriptions := make([]vk.VertexInputAttributeDescription, len(info.vertex_layout))
  binding_count: int
  strides: [16]int
  for att, i in info.vertex_layout {
    descriptions[i] = {
      binding = u32(att.binding),
      location = u32(att.location),
      format = color_format_to_vulkan(att.format),
      offset = u32(att.offset),
    }
    if strides[att.binding] == 0 do binding_count += 1
    strides[att.binding] += rendering.color_format_size(att.format)
  }
  bindings := make([^]vk.VertexInputBindingDescription, binding_count)
  j := 0
  for i in 0..<binding_count {
    for strides[j] == 0 do j += 1
    bindings[i] = {
      binding = u32(j),
      stride = u32(strides[j]),
    }
    j += 1
  }

  vertex_input_info := vk.PipelineVertexInputStateCreateInfo {
    sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
    vertexAttributeDescriptionCount = u32(len(descriptions)),
    pVertexAttributeDescriptions = raw_data(descriptions),
    vertexBindingDescriptionCount = u32(binding_count),
    pVertexBindingDescriptions = bindings,
  }

  input_assembly := vk.PipelineInputAssemblyStateCreateInfo {
    sType = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
    topology = topology_type_to_vulkan(info.topology),
  }

  rasterization_state := vk.PipelineRasterizationStateCreateInfo {
    sType = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
    polygonMode = .FILL,
    lineWidth = 1.0,
    cullMode = cull_mode_to_vulkan(info.cull_mode),
    frontFace = front_face_to_vulkan(info.front_face),
  }

  multisample_state := vk.PipelineMultisampleStateCreateInfo {
    sType = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
    rasterizationSamples = { ._1 },
  }

  viewport_state := vk.PipelineViewportStateCreateInfo {
    sType = .PIPELINE_VIEWPORT_STATE_CREATE_INFO,
    viewportCount = 1,
    scissorCount = 1,
  }

  dynamic_states := []vk.DynamicState { .VIEWPORT, .SCISSOR }
  dynamic_state := vk.PipelineDynamicStateCreateInfo {
    sType = .PIPELINE_DYNAMIC_STATE_CREATE_INFO,
    dynamicStateCount = u32(len(dynamic_states)),
    pDynamicStates = raw_data(dynamic_states),
  }

  color_formats := make([^]vk.Format, len(info.color_attachments))
  color_attachments := make([^]vk.PipelineColorBlendAttachmentState, len(info.color_attachments))
  for att, i in info.color_attachments {
    color_formats[i] = color_format_to_vulkan(att.format)
    color_attachments[i] = {
      blendEnable = b32(att.blend_enabled),
      srcColorBlendFactor = blend_factor_to_vulkan(att.src_color_blend_factor),
      dstColorBlendFactor = blend_factor_to_vulkan(att.dst_color_blend_factor),
      colorBlendOp = blend_func_to_vulkan(att.color_blend_func),
      srcAlphaBlendFactor = blend_factor_to_vulkan(att.src_alpha_blend_factor),
      dstAlphaBlendFactor = blend_factor_to_vulkan(att.dst_alpha_blend_factor),
      alphaBlendOp = blend_func_to_vulkan(att.alpha_blend_func),
      colorWriteMask = color_component_flags_to_vulkan(att.color_write_mask),
    }
  }

  color_blending_state := vk.PipelineColorBlendStateCreateInfo {
    sType = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
    attachmentCount = u32(len(info.color_attachments)),
    pAttachments = color_attachments,
    blendConstants = info.blend_constant,
  }

  enable_depth := info.depth.compare != .Always
  depth_stencil_state := vk.PipelineDepthStencilStateCreateInfo {
    sType = .PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
    depthTestEnable = b32(enable_depth),
    depthWriteEnable = b32(info.depth.enable_write),
    depthCompareOp = compare_func_to_vulkan(info.depth.compare),
    depthBoundsTestEnable = false,
    minDepthBounds = 0.0,
    maxDepthBounds = 1.0,
    stencilTestEnable = b32(info.stencil.enabled),
    back = {
      failOp = stencil_func_to_vulkan(info.stencil.back.fail),
      passOp = stencil_func_to_vulkan(info.stencil.back.pass),
      depthFailOp = stencil_func_to_vulkan(info.stencil.back.depth_fail),
      compareOp = compare_func_to_vulkan(info.stencil.back.compare),
      compareMask = u32(info.stencil.read_mask),
      writeMask = u32(info.stencil.write_mask),
      reference = u32(info.stencil.reference),
    },
    front = {
      failOp = stencil_func_to_vulkan(info.stencil.front.fail),
      passOp = stencil_func_to_vulkan(info.stencil.front.pass),
      depthFailOp = stencil_func_to_vulkan(info.stencil.front.depth_fail),
      compareOp = compare_func_to_vulkan(info.stencil.front.compare),
      compareMask = u32(info.stencil.read_mask),
      writeMask = u32(info.stencil.write_mask),
      reference = u32(info.stencil.reference),
    },
  }

  rendering_create_info := vk.PipelineRenderingCreateInfo {
    sType = .PIPELINE_RENDERING_CREATE_INFO,
    colorAttachmentCount = u32(len(info.color_attachments)),
    pColorAttachmentFormats = color_formats,
    depthAttachmentFormat = color_format_to_vulkan(info.depth.format) if enable_depth else .UNDEFINED,
  }

  create_info := vk.GraphicsPipelineCreateInfo {
    sType = .GRAPHICS_PIPELINE_CREATE_INFO,
    pNext = &rendering_create_info,
    stageCount = u32(len(stages)),
    pStages = raw_data(stages),
    pVertexInputState = &vertex_input_info,
    pInputAssemblyState = &input_assembly,
    pRasterizationState = &rasterization_state,
    pMultisampleState = &multisample_state,
    pViewportState = &viewport_state,
    pDynamicState = &dynamic_state,
    pColorBlendState = &color_blending_state,
    pDepthStencilState = &depth_stencil_state,
    layout = shader.pipeline_layout,
  }

  state: Pipeline_State
  vk.CreateGraphicsPipelines(ctx.device, 0, 1, &create_info, nil, &state.pipeline)
  state.shader = info.shader

  alloc_info := vk.DescriptorSetAllocateInfo {
    sType = .DESCRIPTOR_SET_ALLOCATE_INFO,
    descriptorPool = ctx.descriptor_pool,
    descriptorSetCount = 1,
    pSetLayouts = &shader.descriptor_layout,
  }
  vk.AllocateDescriptorSets(ctx.device, &alloc_info, &state.descriptor_set)

  return handle_map.add(&ctx.pipelines, state)
}

destroy_pipeline :: proc(pipeline: rendering.Pipeline) {
  pip := handle_map.get(&ctx.pipelines, pipeline)
  handle_map.remove(&ctx.pipelines, pipeline)
  vk.DestroyPipeline(ctx.device, pip.pipeline, nil)
}

bind_pipeline :: proc(pipeline: rendering.Pipeline) {
  state := handle_map.get(&ctx.pipelines, pipeline)
  shader := handle_map.get(&ctx.shaders, state.shader)
  vk.CmdBindPipeline(ctx.command_buffer, .GRAPHICS, state.pipeline)
  vk.CmdBindDescriptorSets(ctx.command_buffer, .GRAPHICS, shader.pipeline_layout, 0, 1, &state.descriptor_set, 0, nil)
  ctx.current_pass.pipeline.bind_point = .GRAPHICS
  ctx.current_pass.pipeline.layout = shader.pipeline_layout
}

draw :: proc(element_count, first_element, instance_count, first_instance: int) {
  if ctx.indexed_draw {
    vk.CmdDrawIndexed(ctx.command_buffer,
      u32(element_count),
      u32(instance_count),
      u32(first_element),
      0 /* first_vertex */,
      u32(first_instance))
    ctx.indexed_draw = false
  } else {
    vk.CmdDraw(ctx.command_buffer,
      u32(element_count),
      u32(instance_count),
      u32(first_element),
      u32(first_instance))
  }
}
