package vulkan_backend

import hm "core:container/handle_map"
import "base:runtime"
import "core:dynlib"
import "core:fmt"

import vk "vendor:vulkan"
import "vendor:glfw"

import ".."

VALIDATION_LAYERS :: []cstring {
  "VK_LAYER_KHRONOS_validation"
}

Context :: struct {
  shaders: hm.Dynamic_Handle_Map(Shader_State, rendering.Shader),

  instance:     vk.Instance,
  device:       vk.Device,
  phys_device:  vk.PhysicalDevice,
  queue:        vk.Queue,
  queue_family: u32,
}

create_context :: proc() -> ^Context {
  ctx := new(Context)
  vk.load_proc_addresses_global(auto_cast vk_get_instance_proc_address)
  create_instance(ctx)
  pick_physical_device(ctx)
  create_device(ctx)
  return ctx
}

create_instance :: proc(ctx: ^Context) {
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

pick_physical_device :: proc(ctx: ^Context) {
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

create_device :: proc(ctx: ^Context) {
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
