package vulkan_backend

import hm "core:container/handle_map"
import "base:runtime"
import "core:dynlib"
import "core:fmt"

import vk "vendor:vulkan"
import "vendor:glfw"

import ".."

MAX_FRAMES_IN_FLIGHT :: 2
VALIDATION_LAYERS :: []cstring {
  "VK_LAYER_KHRONOS_validation"
}

ctx: struct {
  pipelines:   hm.Dynamic_Handle_Map(Pipeline_State, rendering.Pipeline),
  shaders:     hm.Dynamic_Handle_Map(Shader_State, rendering.Shader),
  textures:    hm.Dynamic_Handle_Map(Texture_State, rendering.Texture),
  buffers:     hm.Dynamic_Handle_Map(Buffer_State, rendering.Buffer),
  images:      hm.Dynamic_Handle_Map(Image_State, rendering.Image),
  image_views: hm.Dynamic_Handle_Map(Image_View_State, rendering.Image_View),
  bindings:    hm.Dynamic_Handle_Map(Bindings_State, rendering.Bindings),

  instance:     vk.Instance,
  phys_device:  vk.PhysicalDevice,
  device:       vk.Device,
  queue:        vk.Queue,
  queue_family: u32,

  swapchain: rendering.Vk_Swapchain,
  // surface:        vk.SurfaceKHR,
  // surface_format: vk.SurfaceFormatKHR,
  // swapchain:      vk.SwapchainKHR,
  // sc_raw_images:  [^]vk.Image,
  // sc_images:      [^]rendering.Image,
  // sc_image_views: [^]rendering.Image_View,
  // sc_image_count: u32,
  // sc_image_index: u32,

  command_pool:     vk.CommandPool,
  command_buffer:   vk.CommandBuffer,
  command_buffers:  [^]vk.CommandBuffer,
  current_frame: struct {
    cmd_buf:     vk.CommandBuffer,
    index:       i32,
    image_index: i32,
  },

  current_pass: struct {
    pipeline: struct {
      layout:     vk.PipelineLayout,
      bind_point: vk.PipelineBindPoint,
    }
  },

  descriptor_pool: vk.DescriptorPool,

  // submit_semaphores: [^]vk.Semaphore,
  // image_available_semaphores: [^]vk.Semaphore,
  in_flight_fences:           [^]vk.Fence,
  // fence:     vk.Fence,
  // semaphore: vk.Semaphore,
  // wait_semaphores:             [dynamic]vk.Semaphore,
  // signal_semaphores:           [dynamic]vk.Semaphore,

  indexed_draw: bool,
}

create_context :: proc(/* features: rendering.Renderer_Feature_Flags */ info: ^rendering.Vk_Renderer_Create_Info) {
  vk.load_proc_addresses_global(auto_cast vk_get_instance_proc_address)
  // create_instance()
  // pick_physical_device()
  // create_device()
  ctx.instance = info.instance
  ctx.phys_device = info.phys_device
  ctx.device = info.device
  ctx.queue = info.queue
  ctx.queue_family = info.queue_family
  // ctx.surface = info.surface
  // create_swapchain()
  create_command_pool()
  // fence_info := vk.FenceCreateInfo { sType = .FENCE_CREATE_INFO }
  // vk.CreateFence(ctx.device, &fence_info, nil, &ctx.fence)
  // semaphore_info := vk.SemaphoreCreateInfo { sType = .SEMAPHORE_CREATE_INFO }
  // vk.CreateSemaphore(ctx.device, &semaphore_info, nil, &ctx.semaphore)
  create_sync_objects()

  pool_sizes := []vk.DescriptorPoolSize {
    {
      type = .UNIFORM_BUFFER,
      descriptorCount = MAX_FRAMES_IN_FLIGHT
    },
    {
      type = .COMBINED_IMAGE_SAMPLER,
      descriptorCount = MAX_FRAMES_IN_FLIGHT
    }
  }
  vk.CreateDescriptorPool(ctx.device, &vk.DescriptorPoolCreateInfo {
    sType = .DESCRIPTOR_POOL_CREATE_INFO,
    maxSets = MAX_FRAMES_IN_FLIGHT,
    poolSizeCount = u32(len(pool_sizes)),
    pPoolSizes = raw_data(pool_sizes),
  }, nil, &ctx.descriptor_pool)
}

create_instance :: proc() {
  exts := glfw.GetRequiredInstanceExtensions()
  required_extensions: [dynamic]cstring
  reserve(&required_extensions, len(exts) + 2)
  append(&required_extensions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)
  append(&required_extensions, vk.KHR_SURFACE_EXTENSION_NAME)
  for e in exts do append(&required_extensions, e)

  prop_count: u32
  vk.EnumerateInstanceExtensionProperties(nil, &prop_count, nil)
  props := make([]vk.ExtensionProperties, prop_count)
  vk.EnumerateInstanceExtensionProperties(nil, &prop_count, raw_data(props))
  for req in required_extensions {
    supported: bool
    for &p in props {
      if cstring(&p.extensionName[0]) == req {
        supported = true
        break
      }
    }
    fmt.assertf(supported, "unsupported extension: {}", req)
  }

  instance_create_info := vk.InstanceCreateInfo {
    sType = .INSTANCE_CREATE_INFO,
    pApplicationInfo = &{
      sType = .APPLICATION_INFO,
      apiVersion = vk.API_VERSION_1_3,
      applicationVersion = vk.MAKE_VERSION(0, 0, 0),
      engineVersion = vk.MAKE_VERSION(0, 0, 0),
      pApplicationName = "app",
      pEngineName = "engine",
    },
      enabledExtensionCount = u32(len(required_extensions)),
      ppEnabledExtensionNames = raw_data(required_extensions),
      enabledLayerCount = u32(len(VALIDATION_LAYERS)),
      ppEnabledLayerNames = raw_data(VALIDATION_LAYERS),
  }

  vk.CreateInstance(&instance_create_info, nil, &ctx.instance)
  vk.load_proc_addresses_instance(ctx.instance)
}

pick_physical_device :: proc() {
  device_count: u32
  vk.EnumeratePhysicalDevices(ctx.instance, &device_count, nil)
  devices := make([^]vk.PhysicalDevice, device_count)
  defer free(devices)
  vk.EnumeratePhysicalDevices(ctx.instance, &device_count, devices)

  max_score := min(int)
  for i in 0..<device_count {
    props: vk.PhysicalDeviceProperties
    vk.GetPhysicalDeviceProperties(devices[i], &props)

    queue_family_count: u32
    vk.GetPhysicalDeviceQueueFamilyProperties(devices[i], &queue_family_count, nil)
    queue_family_props := make([^]vk.QueueFamilyProperties, queue_family_count)
    defer free(queue_family_props)
    vk.GetPhysicalDeviceQueueFamilyProperties(devices[i], &queue_family_count, queue_family_props)

    required_flags := vk.QueueFlags{ .GRAPHICS, .COMPUTE, .TRANSFER }
    queue_family_index := max(u32)
    for i in 0..<queue_family_count {
      p := queue_family_props[i]
      if p.queueFlags >= required_flags {
        queue_family_index = i
        break
      }
    }
    if queue_family_index == max(u32) do continue
    ctx.queue_family = queue_family_index

    // present_supported: b32
    // vk.GetPhysicalDeviceSurfaceSupportKHR(devices[i], ctx.queue_family, ctx.surface, &present_supported)
    // if !present_supported do continue

    score: int
    switch props.deviceType {
    case .DISCRETE_GPU:   score += 1000
    case .CPU:            score += 100
    case .INTEGRATED_GPU: score += 10
    case .VIRTUAL_GPU:    score += 1
    case .OTHER:
    }

    if score > max_score {
      ctx.phys_device = devices[i]
    }
  }
}

create_device :: proc() {
  required_extensions := []cstring {
    vk.KHR_SWAPCHAIN_EXTENSION_NAME,
    vk.EXT_DESCRIPTOR_BUFFER_EXTENSION_NAME,
    vk.KHR_DRAW_INDIRECT_COUNT_EXTENSION_NAME,
  }

  prop_count: u32
  vk.EnumerateDeviceExtensionProperties(ctx.phys_device, nil, &prop_count, nil)
  props := make([]vk.ExtensionProperties, prop_count)
  vk.EnumerateDeviceExtensionProperties(ctx.phys_device, nil, &prop_count, raw_data(props))

  for req in required_extensions {
    found: bool
    for &p in props {
      if cstring(&p.extensionName[0]) == req {
        found = true
        break
      }
    }
    if !found do fmt.panicf("unsupported extension: {}", req)
  }

  descriptor_buffer := vk.PhysicalDeviceDescriptorBufferFeaturesEXT {
    sType = .PHYSICAL_DEVICE_DESCRIPTOR_BUFFER_FEATURES_EXT,
    descriptorBuffer = true,
  }

  vk_12_features := vk.PhysicalDeviceVulkan12Features {
    sType = .PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
    bufferDeviceAddress = true,
    drawIndirectCount = true,
    pNext = &descriptor_buffer,
  }

  vk_13_features := vk.PhysicalDeviceVulkan13Features {
    sType = .PHYSICAL_DEVICE_VULKAN_1_3_FEATURES,
    dynamicRendering = true,
    pNext = &vk_12_features,
  }

  physical_device_features := vk.PhysicalDeviceFeatures2 {
    sType = .PHYSICAL_DEVICE_FEATURES_2,
    pNext = &vk_13_features
  }

  queue_priority := f32(0)
  device_features: vk.PhysicalDeviceFeatures
  create_info := vk.DeviceCreateInfo {
    sType = .DEVICE_CREATE_INFO,
    queueCreateInfoCount = 1,
    pQueueCreateInfos = &vk.DeviceQueueCreateInfo{
      sType = .DEVICE_QUEUE_CREATE_INFO,
      queueFamilyIndex = ctx.queue_family,
      queueCount = 1,
      pQueuePriorities = &queue_priority,
    },
    enabledExtensionCount = u32(len(required_extensions)),
    ppEnabledExtensionNames = raw_data(required_extensions),
    enabledLayerCount = u32(len(VALIDATION_LAYERS)),
    ppEnabledLayerNames = raw_data(VALIDATION_LAYERS),
    pNext = &physical_device_features,
  }
  vk.CreateDevice(ctx.phys_device, &create_info, nil, &ctx.device)
  vk.GetDeviceQueue(ctx.device, ctx.queue_family, 0, &ctx.queue)
}

create_command_pool :: proc() {
  create_info := vk.CommandPoolCreateInfo {
    sType = .COMMAND_POOL_CREATE_INFO,
    queueFamilyIndex = ctx.queue_family,
    flags = { .RESET_COMMAND_BUFFER },
  }
  vk.CreateCommandPool(ctx.device, &create_info, nil, &ctx.command_pool)

  ctx.command_buffers = make([^]vk.CommandBuffer, MAX_FRAMES_IN_FLIGHT)
  alloc_info := vk.CommandBufferAllocateInfo {
    sType = .COMMAND_BUFFER_ALLOCATE_INFO,
    commandBufferCount = MAX_FRAMES_IN_FLIGHT,
    commandPool = ctx.command_pool,
    level = .PRIMARY
  }
  vk.AllocateCommandBuffers(ctx.device, &alloc_info, ctx.command_buffers)

  // alloc_info = vk.CommandBufferAllocateInfo {
  //   sType = .COMMAND_BUFFER_ALLOCATE_INFO,
  //   commandBufferCount = 1,
  //   commandPool = ctx.command_pool,
  // }
  // vk.AllocateCommandBuffers(ctx.device, &alloc_info, &ctx.command_buffer)
}

create_sync_objects :: proc() {
  // ctx.submit_semaphores = make([^]vk.Semaphore, MAX_FRAMES_IN_FLIGHT)
  // ctx.image_available_semaphores = make([^]vk.Semaphore, MAX_FRAMES_IN_FLIGHT)
  ctx.in_flight_fences = make([^]vk.Fence, MAX_FRAMES_IN_FLIGHT)

  // semaphore_info := vk.SemaphoreCreateInfo { sType = .SEMAPHORE_CREATE_INFO }
  // for i in 0..<MAX_FRAMES_IN_FLIGHT {
  //   vk.CreateSemaphore(ctx.device, &semaphore_info, nil, &ctx.submit_semaphores[i])
  //   when ODIN_DEBUG {
  //     vk.SetDebugUtilsObjectNameEXT(ctx.device, &{
  //       sType = .DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
  //       pObjectName = fmt.caprintf("Submit Semaphore({})", i),
  //       objectHandle = u64(ctx.submit_semaphores[i]),
  //       objectType = .SEMAPHORE,
  //     })
  //   }
  //   vk.CreateSemaphore(ctx.device, &semaphore_info, nil, &ctx.image_available_semaphores[i])
  //   when ODIN_DEBUG {
  //     vk.SetDebugUtilsObjectNameEXT(ctx.device, &{
  //       sType = .DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
  //       pObjectName = fmt.caprintf("Image Available Semaphore({})", i),
  //       objectHandle = u64(ctx.image_available_semaphores[i]),
  //       objectType = .SEMAPHORE,
  //     })
  //   }
  // }

  create_info := vk.FenceCreateInfo { sType = .FENCE_CREATE_INFO, flags = { .SIGNALED } }
  for i in 0..<MAX_FRAMES_IN_FLIGHT {
    vk.CreateFence(ctx.device, &create_info, nil, &ctx.in_flight_fences[i])
  }
}

// queue_wait_semaphore :: proc(semaphore: vk.Semaphore) {
//   append(&ctx.wait_semaphores, semaphore)
// }
//
// queue_signal_semaphore :: proc(semaphore: vk.Semaphore) {
//   append(&ctx.signal_semaphores, semaphore)
// }

vk_get_instance_proc_address :: proc "c" (p: rawptr, name: cstring) -> rawptr {
  context = runtime.default_context()

  vk_lib_path: string
  when ODIN_OS == .Windows {
    vk_lib_path = "vulkan-1.dll"
  } else when ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
    vk_lib_path = "libvulkan.so"
  } else when ODIN_OS == .Linux {
    vk_lib_path = "libvulkan.so.1"
  } else do #panic("OS does not support vulkan")

  @(static) vk_lib: dynlib.Library
  if vk_lib == nil {
    ok: bool
    vk_lib, ok = dynlib.load_library(vk_lib_path)
    vk.GetInstanceProcAddr = auto_cast dynlib.symbol_address(vk_lib, "vkGetInstanceProcAddr")
    assert(ok)
  }

  if name == "vkGetInstanceProcAddr" do return auto_cast vk.GetInstanceProcAddr

  addr := vk.GetInstanceProcAddr(auto_cast p, name)
  if addr == nil do addr = auto_cast dynlib.symbol_address(vk_lib, string(name))
  return auto_cast addr
}
