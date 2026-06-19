package vulkan_backend

import "core:mem"
import "core:container/handle_map"
import vk "vendor:vulkan"

import ".."

Image_State :: struct {
  handle: rendering.Image,
  image:  vk.Image,
  memory: vk.DeviceMemory,
  format: vk.Format,
}

create_image :: proc(info: ^rendering.Image_Create_Info) -> rendering.Image {
  state: Image_State
  state.format = color_format_to_vulkan(info.format)
  if info.raw_handle != nil {
    state.image = (vk.Image)(info.raw_handle.(u64))
  } else {
    create_info := vk.ImageCreateInfo {
      sType = .IMAGE_CREATE_INFO,
      format = state.format,
      imageType = image_type_to_vulkan(info.type),
      mipLevels = info.mip_levels,
      arrayLayers = 1,
      extent = vk.Extent3D {
        width  = info.size.x,
        height = info.size.y,
        depth  = info.size.z,
      },
      samples = { ._1 },
      usage = image_usage_to_vulkan(info.usage) | { .TRANSFER_SRC, .TRANSFER_DST },
      sharingMode = .EXCLUSIVE,
      tiling = .OPTIMAL,
      initialLayout = .UNDEFINED,
    }
    vk.CreateImage(ctx.device, &create_info, nil, &state.image)
    req: vk.MemoryRequirements
    vk.GetImageMemoryRequirements(ctx.device, state.image, &req)
    size := vk.DeviceSize(info.size.x * info.size.y * info.size.z * u32(rendering.color_format_component_count(info.format)))
    alloc_info := vk.MemoryAllocateInfo {
      sType = .MEMORY_ALLOCATE_INFO,
      allocationSize = size,
      memoryTypeIndex = find_memory_type_index(req.memoryTypeBits, { .DEVICE_LOCAL })
    }
    vk.AllocateMemory(ctx.device, &alloc_info, nil, &state.memory)
    data: rawptr
    vk.MapMemory(ctx.device, state.memory, {}, size, nil, &data)
    mem.copy(data, info.data, int(size))
    vk.UnmapMemory(ctx.device, state.memory)
  }
  return handle_map.add(&ctx.images, state)
}

destroy_image :: proc(image: rendering.Image) {
  state := handle_map.get(&ctx.images, image)
  handle_map.remove(&ctx.images, image)
  if state.memory != 0 do vk.FreeMemory(ctx.device, state.memory, nil)
  vk.DestroyImage(ctx.device, state.image, nil)
}

find_memory_type_index :: proc(type_filter: u32, properties: vk.MemoryPropertyFlags) -> u32 {
  mem_properties: vk.PhysicalDeviceMemoryProperties
  vk.GetPhysicalDeviceMemoryProperties(ctx.phys_device, &mem_properties)

  for i in 0..<mem_properties.memoryTypeCount {
    if (type_filter & (1 << i)) != 0 && (mem_properties.memoryTypes[i].propertyFlags & properties) == properties {
      return i
    }
  }

  panic("failed to find suitable memory type")
}
