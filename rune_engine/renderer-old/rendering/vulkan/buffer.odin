package vulkan_backend

import "core:mem"
import "core:container/handle_map"
import vk "vendor:vulkan"

import ".."

Buffer_State :: struct {
  handle: rendering.Buffer,
  buffer: vk.Buffer,
  memory: vk.DeviceMemory,
}

create_buffer :: proc(info: ^rendering.Buffer_Create_Info) -> rendering.Buffer {
  assert(info.size > 0)
  state: Buffer_State

  size := vk.DeviceSize(info.size)
  state.buffer, state.memory = create_buffer_with_memory(size, buffer_usage_to_vulkan(info.usage) | {.TRANSFER_DST}, {.HOST_VISIBLE, .HOST_COHERENT})

  // TODO:
  //  should you be allowed to make a buffer without data?
  if info.data != nil {
    staging_buffer, staging_memory := create_buffer_with_memory(size, {.TRANSFER_SRC}, {.HOST_VISIBLE, .HOST_COHERENT})
    defer {
      vk.DestroyBuffer(ctx.device, staging_buffer, nil)
      vk.FreeMemory(ctx.device, staging_memory, nil)
    }

    data: rawptr
    vk.MapMemory(ctx.device, staging_memory, 0, size, nil, &data)
    mem.copy(data, info.data, info.size)
    vk.UnmapMemory(ctx.device, staging_memory)
    copy_buffer(state.buffer, staging_buffer, size)
  }

  return handle_map.add(&ctx.buffers, state)
}

destroy_buffer :: proc(buffer: rendering.Buffer) {
  state := handle_map.get(&ctx.buffers, buffer)
  handle_map.remove(&ctx.buffers, buffer)
  vk.DestroyBuffer(ctx.device, state.buffer, nil)
  vk.FreeMemory(ctx.device, state.memory, nil)
}

@(private)
create_buffer_with_memory :: proc(
  size: vk.DeviceSize,
  usage: vk.BufferUsageFlags,
  properties: vk.MemoryPropertyFlags,
) -> (buffer: vk.Buffer, memory: vk.DeviceMemory) {
  buffer_info := vk.BufferCreateInfo {
    sType = .BUFFER_CREATE_INFO,
    size = size,
    usage = usage,
    sharingMode = .EXCLUSIVE,
  }

  vk.CreateBuffer(ctx.device, &buffer_info, nil, &buffer)

  mem_requirements: vk.MemoryRequirements
  vk.GetBufferMemoryRequirements(ctx.device, buffer, &mem_requirements)

  alloc_info := vk.MemoryAllocateInfo {
    sType = .MEMORY_ALLOCATE_INFO,
    allocationSize = mem_requirements.size,
    memoryTypeIndex = find_memory_type_index(mem_requirements.memoryTypeBits, properties),
  }

  vk.AllocateMemory(ctx.device, &alloc_info, nil, &memory)
  vk.BindBufferMemory(ctx.device, buffer, memory, 0)
  return
}

copy_buffer :: proc(dst, src: vk.Buffer, size: vk.DeviceSize) {
  alloc_info: vk.CommandBufferAllocateInfo
  alloc_info.sType = .COMMAND_BUFFER_ALLOCATE_INFO
  alloc_info.level = .PRIMARY
  alloc_info.commandPool = ctx.command_pool
  alloc_info.commandBufferCount = 1

  command_buffer: vk.CommandBuffer
  vk.AllocateCommandBuffers(ctx.device, &alloc_info, &command_buffer)

  begin_info: vk.CommandBufferBeginInfo
  begin_info.sType = .COMMAND_BUFFER_BEGIN_INFO
  begin_info.flags = { .ONE_TIME_SUBMIT }
  vk.BeginCommandBuffer(command_buffer, &begin_info)

  copy_region: vk.BufferCopy
  copy_region.srcOffset = 0
  copy_region.dstOffset = 0
  copy_region.size = size
  vk.CmdCopyBuffer(command_buffer, src, dst, 1, &copy_region)

  vk.EndCommandBuffer(command_buffer)

  submit_info: vk.SubmitInfo
  submit_info.sType = .SUBMIT_INFO
  submit_info.commandBufferCount = 1
  submit_info.pCommandBuffers = &command_buffer

  vk.QueueSubmit(ctx.queue, 1, &submit_info, 0)
  vk.QueueWaitIdle(ctx.queue)

  vk.FreeCommandBuffers(ctx.device, ctx.command_pool, 1, &command_buffer)
}

bind_vertex_buffers :: proc(buffers: []rendering.Buffer) {
  vbs := make([^]vk.Buffer, len(buffers))
  offsets := make([^]vk.DeviceSize, len(buffers))
  for b, i in buffers {
    if b == {} do continue
    state := handle_map.get(&ctx.buffers, b)
    vbs[i] = state.buffer
    offsets[i] = 0
  }
  vk.CmdBindVertexBuffers(ctx.command_buffer, 0, u32(len(buffers)), vbs, offsets)
}

bind_index_buffer :: proc(buffer: rendering.Buffer) {
  state := handle_map.get(&ctx.buffers, buffer)
  vk.CmdBindIndexBuffer(ctx.command_buffer, state.buffer, 0, .UINT16)
  ctx.indexed_draw = true
}
