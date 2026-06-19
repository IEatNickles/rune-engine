package vulkan_backend

import "core:container/handle_map"
import "core:hash"
import vk "vendor:vulkan"

import ".."

begin_pass :: proc(info: ^rendering.Pass_Info) {
  swapchain_pass := info.swapchain != nil
  if ctx.command_buffer == nil {
    vk.WaitForFences(ctx.device, 1, &ctx.in_flight_fences[ctx.current_frame.index], true, max(u64))
    vk.ResetFences(ctx.device, 1, &ctx.in_flight_fences[ctx.current_frame.index])

    ctx.command_buffer = ctx.command_buffers[ctx.current_frame.index]
    vk.ResetCommandBuffer(ctx.command_buffer, nil)
    vk.BeginCommandBuffer(ctx.command_buffer, &{
      sType = .COMMAND_BUFFER_BEGIN_INFO,
    })

    if swapchain_pass {
      assert(len(info.color_attachments) == 1)
      ctx.swapchain = info.swapchain.?
      barrier := vk.ImageMemoryBarrier {
        sType = .IMAGE_MEMORY_BARRIER,
        oldLayout = .UNDEFINED,
        newLayout = .GENERAL,
        srcAccessMask = { .COLOR_ATTACHMENT_WRITE },
        image = ctx.swapchain.color_image,
        subresourceRange = {
          aspectMask = { .COLOR },
          layerCount = 1,
          levelCount = 1,
        }
      }
      vk.CmdPipelineBarrier(ctx.command_buffer, { .COLOR_ATTACHMENT_OUTPUT }, { .TOP_OF_PIPE }, nil, 0, nil, 0, nil, 1, &barrier)
    }
  }

  extent: vk.Extent2D
  if swapchain_pass do extent = ctx.swapchain.extent
  else {
    state := handle_map.get(&ctx.image_views, info.color_attachments[0].view)
    extent = { state.size.x, state.size.y }
  }
  color_attachments := make([^]vk.RenderingAttachmentInfo, len(info.color_attachments))
  for i in 0..<len(info.color_attachments) {
    att := info.color_attachments[i]
    view: vk.ImageView
    if swapchain_pass {
      view = ctx.swapchain.color_view
    } else {
      state := handle_map.get(&ctx.image_views, att.view)
      view = state.view
    }
    color_attachments[i] = {
      sType = .RENDERING_ATTACHMENT_INFO,
      clearValue={color={float32 = att.clear_color}},
      loadOp = load_action_to_vulkan(att.load_action),
      storeOp = store_action_to_vulkan(att.store_action),
      imageView = view,
      imageLayout = .COLOR_ATTACHMENT_OPTIMAL,
    }
  }
  vk.CmdBeginRendering(ctx.command_buffer, &{
    sType = .RENDERING_INFO,
    colorAttachmentCount = u32(len(info.color_attachments)),
    pColorAttachments = color_attachments,
    renderArea = vk.Rect2D{{}, extent},
    layerCount = 1,
  })

  vk.CmdSetViewport(ctx.command_buffer, 0, 1, &vk.Viewport{
    x = 0, y = 0,
    width = f32(extent.width),
    height = f32(extent.height),
    minDepth = 0,
    maxDepth = 1,
  })

  vk.CmdSetScissor(ctx.command_buffer, 0, 1, &vk.Rect2D{{}, extent})
}

end_pass :: proc() {
  vk.CmdEndRendering(ctx.command_buffer)
}

submit :: proc() {
  assert(ctx.swapchain.swapchain != 0)

  barrier := vk.ImageMemoryBarrier {
    sType = .IMAGE_MEMORY_BARRIER,
    oldLayout = .GENERAL,
    newLayout = .PRESENT_SRC_KHR,
    srcAccessMask = { .COLOR_ATTACHMENT_WRITE },
    image = ctx.swapchain.color_image,
    srcQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED,
    dstQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED,
    subresourceRange = {
      aspectMask = { .COLOR },
      layerCount = 1,
      levelCount = 1,
    }
  }
  vk.CmdPipelineBarrier(ctx.command_buffer, { .COLOR_ATTACHMENT_OUTPUT }, { .BOTTOM_OF_PIPE }, nil, 0, nil, 0, nil, 1, &barrier)

  vk.EndCommandBuffer(ctx.command_buffer)

  wait_stage := vk.PipelineStageFlags{ .COLOR_ATTACHMENT_OUTPUT }
  submit_info := vk.SubmitInfo {
    sType = .SUBMIT_INFO,
    commandBufferCount = 1,
    pCommandBuffers = &ctx.command_buffer,
    signalSemaphoreCount = 1,
    pSignalSemaphores = &ctx.swapchain.submit_semaphore,
    waitSemaphoreCount = 1,
    pWaitSemaphores = &ctx.swapchain.get_image_semaphore,
    pWaitDstStageMask = &wait_stage,
  }
  vk.QueueSubmit(ctx.queue, 1, &submit_info, ctx.in_flight_fences[ctx.current_frame.index])

  ctx.swapchain = {}
  ctx.command_buffer = nil
}
