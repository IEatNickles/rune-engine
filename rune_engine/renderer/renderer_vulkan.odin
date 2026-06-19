#+private
package renderer

import "core:slice"
import "core:mem"
import "core:math/linalg"
import "core:math"
import "core:os"
import "base:runtime"
import "core:fmt"
import "core:dynlib"
import hm "core:container/handle_map"

import vk "vendor:vulkan"

VK_MAX_COMMAND_BUFFERS :: 64
VK_VALIDATION_LAYERS :: []cstring {
  "VK_LAYER_KHRONOS_validation",
}

vk_init :: proc() {
  create_instance_impl = vk_create_instance
  destroy_instance = vk_destroy_instance

  instance_get_device = vk_instance_get_device
  instance_get_surface = vk_instance_get_surface

  device_begin_commands           = vk_device_begin_commands
  device_submit_commands          = vk_device_submit_commands
  device_create_texture           = vk_device_create_texture
  device_create_texture_view      = vk_device_create_texture_view
  device_create_sampler           = vk_device_create_sampler
  device_create_shader            = vk_device_create_shader
  device_create_graphics_pipeline = vk_device_create_graphics_pipeline
  device_create_buffer            = vk_device_create_buffer
  device_create_bind_group_layout = vk_device_create_bind_group_layout
  device_create_bind_group        = vk_device_create_bind_group
  device_write_texture            = vk_device_write_texture
  device_write_buffer             = vk_device_write_buffer

  device_destroy_sampler           = vk_device_destroy_sampler
  device_destroy_texture           = vk_device_destroy_texture
  device_destroy_texture_view      = vk_device_destroy_texture_view
  device_destroy_shader            = vk_device_destroy_shader
  device_destroy_pipeline          = vk_device_destroy_pipeline
  device_destroy_buffer            = vk_device_destroy_buffer
  device_destroy_bind_group_layout = vk_device_destroy_bind_group_layout
  device_destroy_bind_group        = vk_device_destroy_bind_group

  command_buffer_begin_render_pass  = vk_command_buffer_begin_render_pass
  command_buffer_end_render_pass    = vk_command_buffer_end_render_pass

  render_pass_set_pipeline       = vk_render_pass_set_pipeline
  render_pass_draw               = vk_render_pass_draw
  render_pass_set_vertex_buffers = vk_render_pass_set_vertex_buffers
  render_pass_set_index_buffer   = vk_render_pass_set_index_buffer
  render_pass_set_bind_group     = vk_render_pass_set_bind_group
  render_pass_set_push_constants = vk_render_pass_set_push_constants
  render_pass_set_viewport       = vk_render_pass_set_viewport
  render_pass_set_scissor        = vk_render_pass_set_scissor

  surface_configure = vk_surface_configure
  surface_get_current_texture = vk_surface_get_current_texture
  surface_present = vk_surface_present
}

Vk_Instance :: struct {
  instance:          vk.Instance,
  physical_device:   vk.PhysicalDevice,
  device:            Vk_Device,
  surface:           Vk_Surface,
  enable_validation: bool,
  lib: struct {
    lib: dynlib.Library,
    get_proc_address: vk.ProcGetInstanceProcAddr,
  },
}

@(private="file")
vk_create_instance :: proc(desc: Maybe(Instance_Desc)) -> (res: Instance, err: Error) {
  runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

  desc := desc.?
  instance := new(Vk_Instance)
  instance.enable_validation = desc.enable_validation

  // "borrowed" from https://github.com/Capati/odin-gpu
  library: dynlib.Library
  loaded: bool
  when ODIN_OS == .Windows {
    library, loaded = dynlib.load_library("vulkan-1.dll")
  } else when ODIN_OS == .Darwin {
    library, loaded = dynlib.load_library("libvulkan.dylib")

    if !loaded { library, loaded = dynlib.load_library("libvulkan.1.dylib") }

    if !loaded {
        _, found_lib_path := os.lookup_env("DYLD_FALLBACK_LIBRARY_PATH", context.temp_allocator)
        if !found_lib_path {
            library, loaded = dynlib.load_library("/usr/local/lib/libvulkan.dylib")
        }
    }

    if !loaded { library, loaded = dynlib.load_library("libMoltenVK.dylib") }
  } else {
    library, loaded = dynlib.load_library("libvulkan.so.1")
    if !loaded { library, loaded = dynlib.load_library("libvulkan.so") }
  }
  ensure(loaded, "unable to find vulkan library")

  get_proc_address := cast(vk.ProcGetInstanceProcAddr)dynlib.symbol_address(library, "vkGetInstanceProcAddr")
  instance.lib.lib = library
  instance.lib.get_proc_address = get_proc_address

  vk.load_proc_addresses_global(auto_cast get_proc_address)

  required_extensions: [dynamic; 4]cstring
  append(&required_extensions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)
  if surface_desc, ok := desc.surface_desc.?; ok {
    append(&required_extensions, vk.KHR_SURFACE_EXTENSION_NAME)

    #partial switch s in surface_desc.source {
    case Surface_Source_Win32:   append(&required_extensions, vk.KHR_WIN32_SURFACE_EXTENSION_NAME)
    case Surface_Source_Xlib:    append(&required_extensions, vk.KHR_XLIB_SURFACE_EXTENSION_NAME)
    case Surface_Source_Wayland: append(&required_extensions, vk.KHR_WAYLAND_SURFACE_EXTENSION_NAME)
    case Surface_Source_Xcb:     append(&required_extensions, vk.KHR_XCB_SURFACE_EXTENSION_NAME)
    case Surface_Source_Metal:   append(&required_extensions, vk.EXT_METAL_SURFACE_EXTENSION_NAME)
    }
    instance.surface.instance = instance
    instance.surface.get_next_image = true
  }

  create_info := vk.InstanceCreateInfo {
    sType = .INSTANCE_CREATE_INFO,
    enabledExtensionCount = u32(len(required_extensions)),
    ppEnabledExtensionNames = auto_cast &required_extensions,
    pApplicationInfo = &{
      sType = .APPLICATION_INFO,
      apiVersion = vk.API_VERSION_1_3,
      applicationVersion = vk.MAKE_VERSION(0, 0, 0),
      engineVersion = vk.MAKE_VERSION(0, 0, 0),
    },
  }
  if instance.enable_validation {
    create_info.enabledLayerCount = u32(len(VK_VALIDATION_LAYERS))
    create_info.ppEnabledLayerNames = raw_data(VK_VALIDATION_LAYERS)
  }
  vk.CreateInstance(&create_info, nil, &instance.instance)
  vk.load_proc_addresses_instance(instance.instance)

  options := desc.adapter_options.? or_else DEFAULT_ADAPTER_OPTIONS

  device_count: u32
  vk.EnumeratePhysicalDevices(instance.instance, &device_count, nil)
  devices := make([]vk.PhysicalDevice, device_count, context.temp_allocator)
  vk.EnumeratePhysicalDevices(instance.instance, &device_count, raw_data(devices))

  surface: vk.SurfaceKHR
  has_surface: bool
  if surface_desc, ok := desc.surface_desc.?; ok {
    has_surface = true
    switch source in surface_desc.source {
    case Surface_Source_Win32:
      vk.CreateWin32SurfaceKHR(instance.instance, &{
        sType = .WIN32_SURFACE_CREATE_INFO_KHR,
        hinstance = auto_cast source.hinstance,
        hwnd = auto_cast source.hwnd,
      }, nil, &surface)
    case Surface_Source_Xlib:
      vk.CreateXlibSurfaceKHR(instance.instance, &{
        sType = .XLIB_SURFACE_CREATE_INFO_KHR,
        dpy = auto_cast source.display,
        window = auto_cast source.window,
      }, nil, &surface)
    case Surface_Source_Wayland:
      vk.CreateWaylandSurfaceKHR(instance.instance, &{
        sType = .WAYLAND_SURFACE_CREATE_INFO_KHR,
        display = auto_cast source.display,
        surface = auto_cast source.surface,
      }, nil, &surface)
    case Surface_Source_Xcb:
      vk.CreateXcbSurfaceKHR(instance.instance, &{
        sType = .WAYLAND_SURFACE_CREATE_INFO_KHR,
        connection = auto_cast source.connection,
        window = auto_cast source.window,
      }, nil, &surface)
    case Surface_Source_Metal:
      vk.CreateMetalSurfaceEXT(instance.instance, &{
        sType = .METAL_SURFACE_CREATE_INFO_EXT,
        pLayer = auto_cast source.layer
      }, nil, &surface)
    case Surface_Source_Html: panic("html surface is unsupported")
    // TODO: figure out why there is no
    //  surface create function for android surface
    case Surface_Source_Android: panic("android surface is unsupported")
    }
  }
  instance.surface.surface = surface

  physical_device: vk.PhysicalDevice
  best_score: int
  for device in devices {
    props: vk.PhysicalDeviceProperties
    vk.GetPhysicalDeviceProperties(device, &props)

    if has_surface {
      queue_prop_count: u32
      vk.GetPhysicalDeviceQueueFamilyProperties(device, &queue_prop_count, nil)
      queue_props := make([]vk.QueueFamilyProperties, queue_prop_count, context.temp_allocator)
      vk.GetPhysicalDeviceQueueFamilyProperties(device, &queue_prop_count, raw_data(queue_props))
      surface_supported: b32
      for queue, i in queue_props {
        if .GRAPHICS not_in queue.queueFlags do continue
        vk.GetPhysicalDeviceSurfaceSupportKHR(device, u32(i), surface, &surface_supported)
        if surface_supported do break
      }
      if !surface_supported do continue
    }

    score: int
    switch options.power_preference {
    case .High_Performance:
      switch props.deviceType {
      case .DISCRETE_GPU:   score += 500
      case .INTEGRATED_GPU: score += 400
      case .VIRTUAL_GPU:    score += 300
      case .CPU:            score += 200
      case .OTHER:          score += 100
      }
    case .Low_Power_Usage:
      switch props.deviceType {
      case .INTEGRATED_GPU: score += 500
      case .DISCRETE_GPU:   score += 400
      case .VIRTUAL_GPU:    score += 300
      case .CPU:            score += 200
      case .OTHER:          score += 100
      }
    }

    if score > best_score {
      physical_device = device
      best_score = score
    }
  }

  if physical_device == nil {
    err = .Not_Found
    return
  }
  instance.physical_device = physical_device

  instance.surface.format = pick_surface_format(physical_device, surface)

  required_device_extensions := []cstring {
    vk.KHR_SWAPCHAIN_EXTENSION_NAME,
  }

  prop_count: u32
  vk.EnumerateDeviceExtensionProperties(physical_device, nil, &prop_count, nil)
  props := make([]vk.ExtensionProperties, prop_count, context.temp_allocator)
  vk.EnumerateDeviceExtensionProperties(physical_device, nil, &prop_count, raw_data(props))

  for req in required_device_extensions {
    found: bool
    for &p in props {
      if cstring(&p.extensionName[0]) == req {
        found = true
        break
      }
    }
    if !found do fmt.panicf("unsupported extension: {}", req)
  }

  find_queue_family :: proc(queue_families: []vk.QueueFamilyProperties, flags: vk.QueueFlags) -> u32 {
    for q, i in queue_families {
      if .GRAPHICS in flags && .GRAPHICS in q.queueFlags {
        return u32(i)
      }
      if .COMPUTE in flags && .COMPUTE in q.queueFlags {
        return u32(i)
      }
      if .TRANSFER in flags && .TRANSFER in q.queueFlags {
        return u32(i)
      }
    }
    return vk.QUEUE_FAMILY_IGNORED
  }

  queue_family_count: u32
  vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_count, nil)
  queue_families := make([]vk.QueueFamilyProperties, queue_family_count, context.temp_allocator)
  vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_count, raw_data(queue_families))
  graphics_queue_family := find_queue_family(queue_families, {.GRAPHICS})
  ensure(graphics_queue_family != vk.QUEUE_FAMILY_IGNORED, "graphics not supported for adapter")
  compute_queue_family  := find_queue_family(queue_families, {.COMPUTE})
  ensure(compute_queue_family != vk.QUEUE_FAMILY_IGNORED, "compute not supported for adapter")
  transfer_queue_family := find_queue_family(queue_families, {.TRANSFER})
  ensure(transfer_queue_family != vk.QUEUE_FAMILY_IGNORED, "transfer not supported for adapter")

  queue_create_infos := make([dynamic]vk.DeviceQueueCreateInfo, 0, 4, context.temp_allocator)
  queue_priority := f32(1)
  append(&queue_create_infos, vk.DeviceQueueCreateInfo {
    sType = .DEVICE_QUEUE_CREATE_INFO,
    queueFamilyIndex = graphics_queue_family,
    queueCount = 1,
    pQueuePriorities = &queue_priority,
  })
  if graphics_queue_family != compute_queue_family {
    append(&queue_create_infos, vk.DeviceQueueCreateInfo {
      sType = .DEVICE_QUEUE_CREATE_INFO,
      queueFamilyIndex = compute_queue_family,
      queueCount = 1,
      pQueuePriorities = &queue_priority,
    })
  }
  if compute_queue_family != transfer_queue_family && graphics_queue_family != transfer_queue_family {
    append(&queue_create_infos, vk.DeviceQueueCreateInfo {
      sType = .DEVICE_QUEUE_CREATE_INFO,
      queueFamilyIndex = transfer_queue_family,
      queueCount = 1,
      pQueuePriorities = &queue_priority,
    })
  }

  vulkan_12_features := vk.PhysicalDeviceVulkan12Features {
    sType = .PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
    timelineSemaphore = true
  }
  vulkan_13_features := vk.PhysicalDeviceVulkan13Features {
    sType = .PHYSICAL_DEVICE_VULKAN_1_3_FEATURES,
    dynamicRendering = true,
    synchronization2 = true,
    pNext = &vulkan_12_features,
  }

  device: vk.Device
  device_create_info := vk.DeviceCreateInfo {
    sType = .DEVICE_CREATE_INFO,
    queueCreateInfoCount = u32(len(queue_create_infos)),
    pQueueCreateInfos = raw_data(queue_create_infos),
    enabledExtensionCount = u32(len(required_device_extensions)),
    ppEnabledExtensionNames = raw_data(required_device_extensions),
    pNext = &vulkan_13_features,
  }
  if desc.enable_validation {
    device_create_info.enabledLayerCount   = u32(len(VK_VALIDATION_LAYERS))
    device_create_info.ppEnabledLayerNames = raw_data(VK_VALIDATION_LAYERS)
  }
  vk.CreateDevice(physical_device, &device_create_info, nil, &device)

  graphics_queue, compute_queue, transfer_queue: vk.Queue
  vk.GetDeviceQueue(device, graphics_queue_family, 0, &graphics_queue)
  vk.GetDeviceQueue(device, compute_queue_family,  0, &compute_queue)
  vk.GetDeviceQueue(device, transfer_queue_family, 0, &transfer_queue)
  instance.device.graphics_queue = { graphics_queue_family, graphics_queue }
  instance.device.compute_queue  = { compute_queue_family,  compute_queue }
  instance.device.transfer_queue = { transfer_queue_family, transfer_queue }
  instance.device.device = device
  instance.device.instance = instance
  instance.device.signal_semaphore.sType = .SEMAPHORE_SUBMIT_INFO

  command_pool: vk.CommandPool
  command_pool_create_info := vk.CommandPoolCreateInfo {
    sType = .COMMAND_POOL_CREATE_INFO,
    flags = { .TRANSIENT, .RESET_COMMAND_BUFFER },
    queueFamilyIndex = graphics_queue_family,
  }
  vk.CreateCommandPool(device, &command_pool_create_info, nil, &command_pool)
  instance.device.command_pool = command_pool

  command_buffer_alloc_info := vk.CommandBufferAllocateInfo {
    sType = .COMMAND_BUFFER_ALLOCATE_INFO,
    commandBufferCount = 1,
    commandPool = command_pool,
  }
  semaphore_debug_name := vk.DebugUtilsObjectNameInfoEXT {
    sType = .DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
    objectType = .SEMAPHORE,
  }
  for &buf, i in instance.device.command_buffers {
    vk.CreateSemaphore(device, &{ sType = .SEMAPHORE_CREATE_INFO, }, nil, &buf.semaphore)
    vk.CreateFence    (device, &{ sType = .FENCE_CREATE_INFO,     }, nil, &buf.fence)
    vk.AllocateCommandBuffers(device, &command_buffer_alloc_info, &buf.buffer)
    buf.device = &instance.device
    buf.available = true

    semaphore_debug_name.pObjectName = fmt.caprintf("CmdBuf Semaphore(%d)", i)
    semaphore_debug_name.objectHandle = u64(buf.semaphore)
    vk.SetDebugUtilsObjectNameEXT(device, &semaphore_debug_name)
  }
  instance.device.available_command_buffers = VK_MAX_COMMAND_BUFFERS

  res = Instance(instance)
  return
}

vk_destroy_instance :: proc(instance: Instance) {
  instance := cast(^Vk_Instance)instance
  device := &instance.device
  vk_device := device.device
  surface := instance.surface

  vk.DeviceWaitIdle(vk_device)

  if surface.surface != 0 {
    vk_destroy_swapchain(device, &surface)
    vk.DestroySurfaceKHR(instance.instance, surface.surface, nil)
  }
  for cmd in instance.device.command_buffers {
    vk_cmd := cmd.buffer
    vk.FreeCommandBuffers(vk_device, instance.device.command_pool, 1, &vk_cmd)
    vk.DestroySemaphore(vk_device, cmd.semaphore, nil)
    vk.DestroyFence(vk_device, cmd.fence, nil)
  }
  vk.DestroyCommandPool(vk_device, instance.device.command_pool, nil)
  vk.DestroySemaphore(vk_device, instance.device.last_submit_semaphore, nil)
  vk.DestroySemaphore(vk_device, instance.device.wait_semaphore, nil)
  vk.DestroySemaphore(vk_device, instance.device.signal_semaphore.semaphore, nil)

  it := hm.iterator_make(&instance.device.buffers)
  for _, buffer in hm.dynamic_iterate(&it) do vk_device_destroy_buffer(Device(&instance.device), buffer)
  it2 := hm.iterator_make(&instance.device.shaders)
  for _, shader in hm.dynamic_iterate(&it2) do vk_device_destroy_shader(Device(&instance.device), shader)
  it3 := hm.iterator_make(&instance.device.pipelines)
  for _, pipeline in hm.dynamic_iterate(&it3) do vk_device_destroy_pipeline(Device(&instance.device), pipeline)
  it4 := hm.iterator_make(&instance.device.bind_group_layouts)
  for _, bind_group_layout in hm.dynamic_iterate(&it4) do vk_device_destroy_bind_group_layout(Device(&instance.device), bind_group_layout)
  it5 := hm.iterator_make(&instance.device.bind_groups)
  for _, bind_group in hm.dynamic_iterate(&it5) do vk_device_destroy_bind_group(Device(&instance.device), bind_group)
  it6 := hm.iterator_make(&instance.device.textures)
  for _, texture in hm.dynamic_iterate(&it6) do vk_device_destroy_texture(Device(&instance.device), texture)
  it7 := hm.iterator_make(&instance.device.texture_views)
  for _, texture_view in hm.dynamic_iterate(&it7) do vk_device_destroy_texture_view(Device(&instance.device), texture_view)
  it8 := hm.iterator_make(&instance.device.samplers)
  for _, sampler in hm.dynamic_iterate(&it8) do vk_device_destroy_sampler(Device(&instance.device), sampler)

  vk.DestroyDevice(vk_device, nil)
  vk.DestroyInstance(instance.instance, nil)

  dynlib.unload_library(instance.lib.lib)
  free(instance)
}

vk_destroy_swapchain :: proc(device: ^Vk_Device, surface: ^Vk_Surface) {
  vk_device := device.device
  swapchain := surface.swapchain
  if swapchain != 0 {
    for img in surface.sc_images {
      vk.DestroySemaphore(vk_device, img.acquire_semaphore, nil)
      vk.DestroyFence(vk_device, img.fence, nil)
      hm.remove(&device.textures, img.texture.texture)
      vk_device_destroy_texture_view(Device(device), img.texture.view)
    }
    vk.DestroySwapchainKHR(vk_device, swapchain, nil)
    delete(surface.sc_images)
  }
  vk.DestroySemaphore(vk_device, surface.timeline_semaphore, nil)
  delete(surface.timeline_wait_values)
}

Vk_Queue_Data :: struct {
  family_index: u32,
  queue:        vk.Queue,
}
Vk_Device :: struct {
  instance:                  ^Vk_Instance,
  device:                    vk.Device,
  graphics_queue:            Vk_Queue_Data,
  compute_queue:             Vk_Queue_Data,
  transfer_queue:            Vk_Queue_Data,
  command_pool:              vk.CommandPool,
  command_buffers:           [VK_MAX_COMMAND_BUFFERS]Vk_Command_Buffer,
  last_submit_semaphore:     vk.Semaphore,
  wait_semaphore:            vk.Semaphore,
  signal_semaphore:          vk.SemaphoreSubmitInfo,
  available_command_buffers: int,

  // TODO(tomorrow(TM)): Replace these with handle maps
  samplers:           hm.Dynamic_Handle_Map(Vk_Sampler, Sampler),
  textures:           hm.Dynamic_Handle_Map(Vk_Texture, Texture),
  texture_views:      hm.Dynamic_Handle_Map(Vk_Texture_View, Texture_View),
  shaders:            hm.Dynamic_Handle_Map(Vk_Shader, Shader),
  pipelines:          hm.Dynamic_Handle_Map(Vk_Pipeline, Pipeline),
  buffers:            hm.Dynamic_Handle_Map(Vk_Buffer, Buffer),
  bind_group_layouts: hm.Dynamic_Handle_Map(Vk_Bind_Group_Layout, Bind_Group_Layout),
  bind_groups:        hm.Dynamic_Handle_Map(Vk_Bind_Group, Bind_Group),
}

Vk_Command_Buffer :: struct {
  device:          ^Vk_Device,
  buffer:          vk.CommandBuffer,
  semaphore:       vk.Semaphore,
  fence:           vk.Fence,
  current_pass:    ^Vk_Render_Pass,
  recording:       bool,
  available:       bool,
}

vk_instance_get_device :: proc(instance: Instance) -> Device {
  return Device(&(cast(^Vk_Instance)instance).device)
}

Swapchain_Image :: struct {
  texture:           Surface_Texture,
  acquire_semaphore: vk.Semaphore,
  fence:             vk.Fence,
}

Vk_Surface :: struct {
  instance:           ^Vk_Instance,
  surface:            vk.SurfaceKHR,
  format:             vk.SurfaceFormatKHR,
  swapchain:          vk.SwapchainKHR,
  sc_images:          []Swapchain_Image,
  timeline_semaphore: vk.Semaphore,
  timeline_wait_values:    []u64,
  current_image:      u32,
  current_frame:      u64,
  get_next_image:     bool,
}

vk_instance_get_surface :: proc(instance: Instance) -> Surface {
  return Surface(&(cast(^Vk_Instance)instance).surface)
}

@(private="file")
pick_surface_format :: proc(device: vk.PhysicalDevice, surface: vk.SurfaceKHR) -> vk.SurfaceFormatKHR {
  runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
  format_count: u32
  vk.GetPhysicalDeviceSurfaceFormatsKHR(device, surface, &format_count, nil)
  formats := make([^]vk.SurfaceFormatKHR, format_count, context.temp_allocator)
  vk.GetPhysicalDeviceSurfaceFormatsKHR(device, surface, &format_count, formats)
  for i in 0..<format_count {
    f := formats[i]
    #partial switch f.format {
    case .B8G8R8A8_UNORM, .R8G8B8A8_UNORM: return f
    }
  }
  return formats[0]
}

vk_device_begin_commands :: proc(device: Device) -> Command_Buffer {
  device := cast(^Vk_Device)device
  for device.available_command_buffers == 0 {
    vk_purge_command_buffers(device)
  }

  current: ^Vk_Command_Buffer
  for &buf in device.command_buffers {
    if buf.available {
      current = &buf
      break
    }
  }
  assert(current != nil)
  current.available = false
  device.available_command_buffers -= 1

  vk.BeginCommandBuffer(current.buffer, &{
    sType = .COMMAND_BUFFER_BEGIN_INFO,
    flags = { .ONE_TIME_SUBMIT },
  })
  return Command_Buffer(current)
}

vk_purge_command_buffers :: proc(device: ^Vk_Device) {
  for &buf in device.command_buffers {
    if buf.available do continue
    res := vk.WaitForFences(device.device, 1, &buf.fence, true, 0)

    if res == .SUCCESS {
      vk.ResetCommandBuffer(buf.buffer, nil)
      vk.ResetFences(device.device, 1, &buf.fence)
      buf.available = true
      device.available_command_buffers += 1
    } else if res != .TIMEOUT do panic("failed to wait for fence")
  }
}

vk_device_submit_commands :: proc(device: Device, command_buffer: Command_Buffer) {
  device := cast(^Vk_Device)device
  command_buffer := cast(^Vk_Command_Buffer)command_buffer
  vk.EndCommandBuffer(command_buffer.buffer)
  command_buffer.recording = false

  wait_semaphores: [dynamic; 2]vk.SemaphoreSubmitInfo
  if device.wait_semaphore != 0 {
    append(&wait_semaphores, vk.SemaphoreSubmitInfo{
      sType = .SEMAPHORE_SUBMIT_INFO,
      semaphore = device.wait_semaphore,
      stageMask = { .ALL_COMMANDS },
    })
  }
  if device.last_submit_semaphore != 0 {
    append(&wait_semaphores, vk.SemaphoreSubmitInfo{
      sType = .SEMAPHORE_SUBMIT_INFO,
      semaphore = device.last_submit_semaphore,
      stageMask = { .ALL_COMMANDS },
    })
  }
  signal_semaphores: [dynamic; 2]vk.SemaphoreSubmitInfo
  append(&signal_semaphores, vk.SemaphoreSubmitInfo{
    sType = .SEMAPHORE_SUBMIT_INFO,
    semaphore = command_buffer.semaphore,
    stageMask = { .ALL_COMMANDS }
  })
  if device.signal_semaphore.semaphore != 0 do append(&signal_semaphores, device.signal_semaphore)
  vk.QueueSubmit2(device.graphics_queue.queue, 1, &vk.SubmitInfo2{
    sType = .SUBMIT_INFO_2,
    commandBufferInfoCount = 1,
    pCommandBufferInfos = &vk.CommandBufferSubmitInfo{
      sType = .COMMAND_BUFFER_SUBMIT_INFO,
      commandBuffer = command_buffer.buffer,
    },
    signalSemaphoreInfoCount = u32(len(signal_semaphores)),
    pSignalSemaphoreInfos = auto_cast &signal_semaphores,
    waitSemaphoreInfoCount = u32(len(wait_semaphores)),
    pWaitSemaphoreInfos = auto_cast &wait_semaphores,
  }, command_buffer.fence)
  device.last_submit_semaphore = command_buffer.semaphore
  device.wait_semaphore = 0
  device.signal_semaphore.semaphore = 0
}

Vk_Sampler :: struct {
  handle:  Sampler,
  sampler: vk.Sampler,
}

vk_device_create_sampler :: proc(device: Device, desc: Sampler_Desc) -> Sampler {
  device := cast(^Vk_Device)device
  sampler: vk.Sampler
  vk.CreateSampler(device.device, &{
    sType = .SAMPLER_CREATE_INFO,
    addressModeU = wrap_to_vk_sampler_address_mode(desc.wrap.x),
    addressModeV = wrap_to_vk_sampler_address_mode(desc.wrap.y),
    addressModeW = wrap_to_vk_sampler_address_mode(desc.wrap.z),
    borderColor  = border_color_to_vulkan(desc.border_color),
    minFilter  = filter_to_vulkan(desc.min_filter),
    magFilter  = filter_to_vulkan(desc.mag_filter),
    mipmapMode = auto_cast filter_to_vulkan(desc.mip_filter),
  }, nil, &sampler)
  res: Vk_Sampler
  res.sampler = sampler
  return hm.add(&device.samplers, res)
}

Vk_Texture :: struct {
  handle:  Texture,
  image:   vk.Image,
  memory:  vk.DeviceMemory,
  dim:     Texture_Dim,
  format:  vk.Format,
  extent:  [3]u32,
  storage: bool,
}

vk_device_create_texture :: proc(device: Device, desc: Texture_Desc) -> Texture {
  device := cast(^Vk_Device)device
  instance := device.instance

  usage: vk.ImageUsageFlags
  usage |= {.TRANSFER_DST}
  if .Texture_Binding         in desc.usage do usage |= {.SAMPLED}
  if .Storage_Texture_Binding in desc.usage do usage |= {.STORAGE}
  if .Render_Attachment       in desc.usage {
    #partial switch desc.format {
    case .D32_FLOAT, .D24_UNORM_S8_UINT, .D32_FLOAT_S8_UINT: usage |= {.DEPTH_STENCIL_ATTACHMENT}
    case: usage |= {.COLOR_ATTACHMENT}
    }
  }

  image: vk.Image
  vk.CreateImage(device.device, &{
    sType = .IMAGE_CREATE_INFO,
    imageType = texture_dim_to_vulkan(desc.dim),
    arrayLayers = desc.array_count,
    extent = transmute(vk.Extent3D)desc.extent,
    format = format_to_vulkan(desc.format),
    mipLevels = desc.mip_levels,
    samples = { ._1 },
    usage = usage,
  }, nil, &image)

  memory_requirements: vk.MemoryRequirements
  vk.GetImageMemoryRequirements(device.device, image, &memory_requirements)
  memory: vk.DeviceMemory
  vk.AllocateMemory(device.device, &{
    sType = .MEMORY_ALLOCATE_INFO,
    allocationSize = memory_requirements.size,
    memoryTypeIndex = vk_find_memory_type(instance.physical_device, memory_requirements.memoryTypeBits, {.DEVICE_LOCAL}),
  }, nil, &memory)
  vk.BindImageMemory(device.device, image, memory, 0)

  layout: vk.ImageLayout
  aspect: vk.ImageAspectFlags
  if .Render_Attachment in desc.usage {
    #partial switch desc.format {
    case .D32_FLOAT:
      aspect = {.DEPTH}
      layout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    case .D24_UNORM_S8_UINT, .D32_FLOAT_S8_UINT:
      aspect = {.DEPTH, .STENCIL}
      layout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    case:
      aspect = {.COLOR}
      layout = .COLOR_ATTACHMENT_OPTIMAL
    }
  } else if .Texture_Binding in desc.usage {
    #partial switch desc.format {
    case .D32_FLOAT: aspect = {.DEPTH}
    case .D24_UNORM_S8_UINT, .D32_FLOAT_S8_UINT: aspect = {.DEPTH, .STENCIL}
    case: aspect = {.COLOR}
    }
    layout = .SHADER_READ_ONLY_OPTIMAL
  }

  cmd := vk_device_begin_commands(Device(device))
  vk_transition_image((cast(^Vk_Command_Buffer)cmd).buffer, image, .UNDEFINED, layout, {
    aspectMask = aspect,
    layerCount = 1,
    levelCount = 1,
  })
  vk_device_submit_commands(Device(device), cmd)

  res: Vk_Texture
  res.image = image
  res.memory = memory
  res.dim = desc.dim
  res.format = format_to_vulkan(desc.format)
  res.extent = desc.extent
  res.storage = .Storage_Texture_Binding in desc.usage
  return hm.add(&device.textures, res)
}

vk_create_staging_buffer :: proc(device: vk.Device, physical_device: vk.PhysicalDevice, size: int, usage: vk.BufferUsageFlags, properties: vk.MemoryPropertyFlags) -> (buffer: vk.Buffer, memory: vk.DeviceMemory) {
  buffer_info := vk.BufferCreateInfo {
    sType = .BUFFER_CREATE_INFO,
    size = vk.DeviceSize(size),
    usage = usage,
  }

  if vk.CreateBuffer(device, &buffer_info, nil, &buffer) != .SUCCESS {
    panic("failed to create vertex buffer")
  }

  mem_requirements: vk.MemoryRequirements
  vk.GetBufferMemoryRequirements(device, buffer, &mem_requirements)

  alloc_info: vk.MemoryAllocateInfo
  alloc_info.sType = .MEMORY_ALLOCATE_INFO
  alloc_info.allocationSize = mem_requirements.size
  alloc_info.memoryTypeIndex = vk_find_memory_type(physical_device, mem_requirements.memoryTypeBits, properties)

  if vk.AllocateMemory(device, &alloc_info, nil, &memory) != .SUCCESS {
    panic("failed to allocate memeory for vertex buffer")
  }

  vk.BindBufferMemory(device, buffer, memory, 0)
  return
}

vk_find_memory_type :: proc(physical_device: vk.PhysicalDevice, type_filter: u32, properties: vk.MemoryPropertyFlags) -> u32 {
  memory_properties: vk.PhysicalDeviceMemoryProperties
  vk.GetPhysicalDeviceMemoryProperties(physical_device, &memory_properties)
  for i in 0..<memory_properties.memoryTypeCount {
    if (type_filter & (1 << i)) != 0 && memory_properties.memoryTypes[i].propertyFlags >= properties {
      return i
    }
  }
  panic("no supported memory type")
}

get_mipmap_size :: proc(size: [3]u32, mip_level: u32) -> [3]u32 {
  if mip_level == 0 do return size
  max_dim := linalg.max(size)
  return max(u32(math.floor(math.log2(f32(max_dim)))), 1)
}

Vk_Texture_View :: struct {
  handle:  Texture_View,
  texture: ^Vk_Texture,
  view:    vk.ImageView,
}

vk_device_create_texture_view :: proc(device: Device, desc: Texture_View_Desc) -> Texture_View {
  device := cast(^Vk_Device)device
  texture, ok := hm.get(&device.textures, desc.texture)
  assert(ok)
  view: vk.ImageView

  aspect: vk.ImageAspectFlags
  #partial switch texture.format {
  case .D32_SFLOAT: aspect = {.DEPTH}
  case .D32_SFLOAT_S8_UINT: aspect = {.DEPTH, .STENCIL}
  case .D24_UNORM_S8_UINT: aspect = {.DEPTH, .STENCIL}
  case: aspect = {.COLOR}
  }
  vk.CreateImageView(device.device, &{
    sType = .IMAGE_VIEW_CREATE_INFO,
    viewType = texture_view_dim_to_vulkan(desc.dim),
    format = texture.format,
    image = texture.image,
    subresourceRange = {
      aspectMask = aspect,
      baseArrayLayer = desc.base_array_layer,
      layerCount = desc.array_layer_count,
      baseMipLevel = desc.base_mip_level,
      levelCount = desc.mip_level_count,
    }
  }, nil, &view)

  res: Vk_Texture_View
  res.texture = texture
  res.view = view
  return hm.add(&device.texture_views, res)
}

vk_command_buffer_begin_render_pass :: proc(command_buffer: Command_Buffer, desc: Render_Pass_Desc) -> Render_Pass {
  assert(len(desc.color_attachents) > 0)
  runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
  command_buffer := cast(^Vk_Command_Buffer)command_buffer

  color_attachments := make([]vk.RenderingAttachmentInfo, len(desc.color_attachents), context.temp_allocator)
  for att, i in desc.color_attachents {
    view, ok := hm.get(&command_buffer.device.texture_views, att.view)
    assert(ok)
    color_attachments[i] = {
      sType = .RENDERING_ATTACHMENT_INFO,
      clearValue = {color={float32 = att.clear_value}},
      loadOp  = load_action_to_vulkan(att.load_action),
      storeOp = store_action_to_vulkan(att.store_action),
      imageView = view.view,
      imageLayout = .COLOR_ATTACHMENT_OPTIMAL,
    }
    texture := view.texture
    aspect: vk.ImageAspectFlags
    #partial switch texture.format {
    case .D32_SFLOAT: aspect = {.DEPTH}
    case .D32_SFLOAT_S8_UINT: aspect = {.DEPTH, .STENCIL}
    case .D24_UNORM_S8_UINT: aspect = {.DEPTH, .STENCIL}
    case: aspect = {.COLOR}
    }
    vk_transition_image(command_buffer.buffer, texture.image, .UNDEFINED, .COLOR_ATTACHMENT_OPTIMAL, {
      aspectMask = aspect,
      layerCount = 1,
      levelCount = 1,
    })
  }

  color0, ok := hm.get(&command_buffer.device.texture_views, desc.color_attachents[0].view)
  assert(ok)
  texture0 := color0.texture
  render_area := desc.render_area.? or_else Rect2D{{}, texture0.extent.xy}

  rendering_info := vk.RenderingInfo{
    sType = .RENDERING_INFO,
    renderArea = transmute(vk.Rect2D)render_area,
    layerCount = 1,
    colorAttachmentCount = u32(len(color_attachments)),
    pColorAttachments = raw_data(color_attachments),
  }

  if depth_stencil_attachment, ok := desc.depth_stencil_attachment.?; ok {
    view := hm.get(&command_buffer.device.texture_views, depth_stencil_attachment.view)
    #partial switch view.texture.format {
    case .D32_SFLOAT:
      rendering_info.pDepthAttachment = &vk.RenderingAttachmentInfo {
        sType = .RENDERING_ATTACHMENT_INFO,
        imageView = view.view,
        imageLayout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        clearValue = {depthStencil={depth=depth_stencil_attachment.depth_ops.clear_value}},
        loadOp = load_action_to_vulkan(depth_stencil_attachment.depth_ops.load_action),
        storeOp = store_action_to_vulkan(depth_stencil_attachment.depth_ops.store_action),
      }
    case .D24_UNORM_S8_UINT, .D32_SFLOAT_S8_UINT:
      rendering_info.pDepthAttachment = &vk.RenderingAttachmentInfo {
        sType = .RENDERING_ATTACHMENT_INFO,
        imageView = view.view,
        imageLayout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        clearValue = {depthStencil={depth=depth_stencil_attachment.depth_ops.clear_value}},
        loadOp = load_action_to_vulkan(depth_stencil_attachment.depth_ops.load_action),
        storeOp = store_action_to_vulkan(depth_stencil_attachment.depth_ops.store_action),
      }
      rendering_info.pStencilAttachment = &vk.RenderingAttachmentInfo {
        sType = .RENDERING_ATTACHMENT_INFO,
        imageView = view.view,
        imageLayout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        clearValue = {depthStencil={stencil=depth_stencil_attachment.stencil_ops.clear_value}},
        loadOp = load_action_to_vulkan(depth_stencil_attachment.stencil_ops.load_action),
        storeOp = store_action_to_vulkan(depth_stencil_attachment.stencil_ops.store_action),
      }
    case: panic("attempt to use texture view with a non-depth format")
    }
  }

  vk.CmdBeginRendering(command_buffer.buffer, &rendering_info)
  vk.CmdSetViewport(command_buffer.buffer, 0, 1, &vk.Viewport{
    x = f32(render_area.offset.x),
    y = f32(render_area.offset.y + render_area.extent.y),
    width = f32(render_area.extent.x),
    height = -f32(render_area.extent.y),
    maxDepth = 1.0,
  })
  vk.CmdSetScissor(command_buffer.buffer, 0, 1, cast(^vk.Rect2D)&render_area)

  res := new(Vk_Render_Pass)
  res.device = command_buffer.device
  res.command_buffer = command_buffer.buffer
  command_buffer.current_pass = res
  return Render_Pass(res)
}

vk_command_buffer_end_render_pass :: proc(command_buffer: Command_Buffer) {
  command_buffer := cast(^Vk_Command_Buffer)command_buffer
  vk.CmdEndRendering(command_buffer.buffer)
  free(command_buffer.current_pass)
}

vk_surface_configure :: proc(surface: Surface, options: Surface_Options) {
  surface := cast(^Vk_Surface)surface
  assert(surface != nil, "no surface has been provided for instance")
  instance := cast(^Vk_Instance)surface.instance

  physical_device := instance.physical_device
  device := &instance.device
  vk_device := device.device
  graphics_queue := device.graphics_queue.family_index

  vk.DeviceWaitIdle(vk_device)

  caps: vk.SurfaceCapabilitiesKHR
  vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device, surface.surface, &caps)
  extent := transmute(vk.Extent2D)options.extent
  extent.width = math.clamp(extent.width, caps.minImageExtent.width, caps.maxImageExtent.width)
  extent.height = math.clamp(extent.height, caps.minImageExtent.height, caps.maxImageExtent.height)

  old_swapchain := surface.swapchain
  reconfigure := old_swapchain != 0
  format := format_to_vulkan(options.format)
  swapchain: vk.SwapchainKHR
  sc_create_info := vk.SwapchainCreateInfoKHR {
    sType = .SWAPCHAIN_CREATE_INFO_KHR,
    surface = surface.surface,
    minImageCount = caps.minImageCount,
    preTransform = caps.currentTransform,
    compositeAlpha = {.OPAQUE},
    imageArrayLayers = 1,
    imageUsage = { .COLOR_ATTACHMENT },
    imageFormat = format,
    imageColorSpace = surface.format.colorSpace,
    imageExtent = extent,
    imageSharingMode = .EXCLUSIVE,
    presentMode = present_mode_to_vulkan(options.present_mode),
    queueFamilyIndexCount = 1,
    pQueueFamilyIndices = &graphics_queue,
    oldSwapchain = old_swapchain,
  }
  vk.CreateSwapchainKHR(vk_device, &sc_create_info, nil, &swapchain)

  if reconfigure {
    vk_destroy_swapchain(device, surface)
  }

  image_count: u32
  vk.GetSwapchainImagesKHR(vk_device, swapchain, &image_count, nil)
  images := make([]vk.Image, image_count, context.temp_allocator)
  vk.GetSwapchainImagesKHR(vk_device, swapchain, &image_count, raw_data(images))

  semaphore_debug_name := vk.DebugUtilsObjectNameInfoEXT {
    sType = .DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
    objectType = .SEMAPHORE,
  }
  sc_images := make([]Swapchain_Image, image_count)
  for img, i in images {
    texture := hm.add(&device.textures, Vk_Texture {
      image = img,
      dim = .D2,
      extent = {extent.width, extent.height, 1},
      format = format,
    })
    view := vk_device_create_texture_view(Device(device), {
      texture = texture,
      array_layer_count = 1,
      mip_level_count = 1,
      dim = .D2,
    })
    sc_images[i].texture = {texture, view}
    vk.CreateSemaphore(vk_device, &{ sType = .SEMAPHORE_CREATE_INFO }, nil, &sc_images[i].acquire_semaphore)
    vk.CreateFence(vk_device, &{ sType = .FENCE_CREATE_INFO, flags={.SIGNALED} }, nil, &sc_images[i].fence)

    semaphore_debug_name.pObjectName = fmt.caprintf("Surface Acquire Semaphore(%d)", i)
    semaphore_debug_name.objectHandle = u64(sc_images[i].acquire_semaphore)
    vk.SetDebugUtilsObjectNameEXT(vk_device, &semaphore_debug_name)
  }
  surface.sc_images = sc_images
  surface.swapchain = swapchain

  timeline_semaphore: vk.Semaphore
  semaphore_type_create_info := vk.SemaphoreTypeCreateInfo {
    sType = .SEMAPHORE_TYPE_CREATE_INFO,
    semaphoreType = .TIMELINE,
  }
  vk.CreateSemaphore(vk_device, &{
    sType = .SEMAPHORE_CREATE_INFO,
    pNext = &semaphore_type_create_info,
  }, nil, &timeline_semaphore)
  surface.timeline_semaphore = timeline_semaphore
  surface.timeline_wait_values = make([]u64, len(surface.sc_images))
}

vk_surface_get_current_texture :: proc(surface: Surface) -> Surface_Texture {
  surface := cast(^Vk_Surface)surface
  if surface.get_next_image {
    instance := surface.instance
    device := &instance.device

    vk.WaitSemaphores(device.device, &{
      sType = .SEMAPHORE_WAIT_INFO,
      semaphoreCount = 1,
      pSemaphores = &surface.timeline_semaphore,
      pValues = &surface.timeline_wait_values[surface.current_image],
    }, max(u64))

    image := surface.sc_images[surface.current_image]
    vk.WaitForFences(device.device, 1, &image.fence, true, max(u64))
    vk.ResetFences(device.device, 1, &image.fence)
    vk.AcquireNextImageKHR(device.device, surface.swapchain, max(u64), image.acquire_semaphore, image.fence, &surface.current_image)
    device.wait_semaphore = image.acquire_semaphore

    signal_value := surface.current_frame + u64(len(surface.sc_images))
    surface.timeline_wait_values[surface.current_image] = signal_value
    device.signal_semaphore.semaphore = surface.timeline_semaphore
    device.signal_semaphore.value = signal_value

    surface.get_next_image = false
  }
  return surface.sc_images[surface.current_image].texture
}

vk_surface_present :: proc(surface: Surface) {
  surface := cast(^Vk_Surface)surface
  instance := surface.instance
  device := &instance.device
  buf := vk_device_begin_commands(Device(device))
  texture := hm.get(&device.textures, surface.sc_images[surface.current_image].texture.texture)
  vk_transition_image((cast(^Vk_Command_Buffer)buf).buffer, texture.image, .UNDEFINED, .PRESENT_SRC_KHR, {
    aspectMask = {.COLOR},
    layerCount = 1,
    levelCount = 1,
  })
  vk_device_submit_commands(Device(device), buf)

  wait_semaphore := device.last_submit_semaphore
  device.last_submit_semaphore = 0
  vk.QueuePresentKHR(device.graphics_queue.queue, &{
    sType = .PRESENT_INFO_KHR,
    swapchainCount = 1,
    pSwapchains = &surface.swapchain,
    pImageIndices = &surface.current_image,
    waitSemaphoreCount = 1,
    pWaitSemaphores = &wait_semaphore,
  })
  surface.get_next_image = true
  surface.current_frame += 1
}

vk_transition_image :: proc(
  command_buffer:    vk.CommandBuffer,
  image:             vk.Image,
  old_layout:        vk.ImageLayout,
  new_layout:        vk.ImageLayout,
  subresource_range: vk.ImageSubresourceRange,
) {
  src_stage, src_access := vk_get_pipeline_stage_access(old_layout)
  dst_stage, dst_access := vk_get_pipeline_stage_access(new_layout)

  barrier := vk.ImageMemoryBarrier2 {
    sType = .IMAGE_MEMORY_BARRIER_2,
    image = image,
    oldLayout = old_layout,
    newLayout = new_layout,
    srcStageMask  = src_stage,
    dstStageMask  = dst_stage,
    srcAccessMask = src_access,
    dstAccessMask = dst_access,
    srcQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED,
    dstQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED,
    subresourceRange = subresource_range,
  }
  dep := vk.DependencyInfo {
    sType = .DEPENDENCY_INFO,
    imageMemoryBarrierCount = 1,
    pImageMemoryBarriers = &barrier,
  }
  vk.CmdPipelineBarrier2(command_buffer, &dep)
}

vk_get_pipeline_stage_access :: proc "contextless" (layout: vk.ImageLayout) -> (stage: vk.PipelineStageFlags2, access: vk.AccessFlags2) {
  #partial switch layout {
  case .UNDEFINED:
    stage  = { .TOP_OF_PIPE }
    access = nil
  case .COLOR_ATTACHMENT_OPTIMAL:
    stage  = { .COLOR_ATTACHMENT_OUTPUT }
    access = { .COLOR_ATTACHMENT_READ, .COLOR_ATTACHMENT_WRITE }
  case .DEPTH_STENCIL_ATTACHMENT_OPTIMAL:
    stage  = { .LATE_FRAGMENT_TESTS, .EARLY_FRAGMENT_TESTS }
    access = { .DEPTH_STENCIL_ATTACHMENT_READ, .DEPTH_STENCIL_ATTACHMENT_WRITE }
  case .SHADER_READ_ONLY_OPTIMAL:
    stage  = { .FRAGMENT_SHADER, .COMPUTE_SHADER, .PRE_RASTERIZATION_SHADERS }
    access = { .SHADER_READ }
  case .TRANSFER_SRC_OPTIMAL:
    stage  = { .TRANSFER }
    access = { .TRANSFER_READ }
  case .TRANSFER_DST_OPTIMAL:
    stage  = { .TRANSFER }
    access = { .TRANSFER_WRITE }
  case .GENERAL:
    stage  = { .COMPUTE_SHADER, .TRANSFER }
    access = { .MEMORY_READ, .MEMORY_WRITE, .TRANSFER_WRITE }
  case .PRESENT_SRC_KHR:
    stage  = { .COLOR_ATTACHMENT_OUTPUT, .COMPUTE_SHADER }
    access = { .SHADER_WRITE }
  case:
    panic_contextless("unsupported image layout transition")
  }
  return
}

Vk_Pipeline :: struct {
  handle:   Pipeline,
  pipeline: vk.Pipeline,
  layout:   vk.PipelineLayout,
}

vk_device_create_graphics_pipeline :: proc(device: Device, desc: Graphics_Pipeline_Desc) -> Pipeline {
  runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
  device := cast(^Vk_Device)device
  vertex_binding_descriptions := make([]vk.VertexInputBindingDescription, len(desc.bindings), context.temp_allocator)
  for binding, i in desc.bindings {
    vertex_binding_descriptions[i] = {
      binding   = binding.binding,
      stride    = binding.stride,
      inputRate = .VERTEX if binding.input_rate == .Per_Vertex else .INSTANCE,
    }
  }
  vertex_attribute_descriptions := make([]vk.VertexInputAttributeDescription, len(desc.attributes), context.temp_allocator)
  for attribute, i in desc.attributes {
    vertex_attribute_descriptions[i] = {
      binding  = attribute.binding,
      location = attribute.location,
      format   = format_to_vulkan(attribute.format),
      offset   = u32(attribute.offset),
    }
  }
  vertex_input_state := vk.PipelineVertexInputStateCreateInfo {
    sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
    vertexAttributeDescriptionCount = u32(len(vertex_attribute_descriptions)),
    pVertexAttributeDescriptions    = raw_data(vertex_attribute_descriptions),
    vertexBindingDescriptionCount   = u32(len(vertex_binding_descriptions)),
    pVertexBindingDescriptions      = raw_data(vertex_binding_descriptions),
  }
  input_assembly_state := vk.PipelineInputAssemblyStateCreateInfo {
    sType    = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
    topology = topology_type_to_vulkan(desc.topology),
  }
  tessellation_state := vk.PipelineTessellationStateCreateInfo { sType = .PIPELINE_TESSELLATION_STATE_CREATE_INFO, }
  viewport_state := vk.PipelineViewportStateCreateInfo {
    sType = .PIPELINE_VIEWPORT_STATE_CREATE_INFO,
    viewportCount = 1,
    scissorCount = 1,
  }
  rasterization_state := vk.PipelineRasterizationStateCreateInfo {
    sType = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
    cullMode = cull_mode_to_vulkan(desc.cull_mode),
    frontFace = .CLOCKWISE if desc.front_face == .Clockwise else .COUNTER_CLOCKWISE,
    polygonMode = .FILL,
    lineWidth = 1.0,
  }
  multisample_state := vk.PipelineMultisampleStateCreateInfo {
    sType = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
    rasterizationSamples = {._1},
  }
  depth_stencil_state := vk.PipelineDepthStencilStateCreateInfo {
    sType = .PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
    depthTestEnable = b32(desc.depth_stencil.depth_test_enable),
    depthWriteEnable = b32(desc.depth_stencil.depth_write_enable),
    depthCompareOp = compare_func_to_vulkan(desc.depth_stencil.depth_compare_func),
    depthBoundsTestEnable = b32(desc.depth_stencil.depth_bounds_test_enable),
    stencilTestEnable = b32(desc.depth_stencil.stencil_test_enable),
    front = stencil_state_to_vulkan(desc.depth_stencil.stencil_front),
    back  = stencil_state_to_vulkan(desc.depth_stencil.stencil_back),
    minDepthBounds = desc.depth_stencil.min_depth_bounds,
    maxDepthBounds = desc.depth_stencil.max_depth_bounds,
  }
  depth_format: vk.Format
  stencil_format: vk.Format
  #partial switch desc.depth_stencil.format {
  case .D32_FLOAT: depth_format = .D32_SFLOAT
  case .D24_UNORM_S8_UINT:
    depth_format = .D24_UNORM_S8_UINT
    stencil_format = .D24_UNORM_S8_UINT
  case .D32_FLOAT_S8_UINT:
    depth_format = .D32_SFLOAT_S8_UINT
    stencil_format = .D32_SFLOAT_S8_UINT
  }

  color_blend_attachments := make([]vk.PipelineColorBlendAttachmentState, len(desc.color_targets), context.temp_allocator)
  color_formats := make([]vk.Format, len(desc.color_targets), context.temp_allocator)
  for target, i in desc.color_targets {
    color_mask: vk.ColorComponentFlags
    if .R in target.blend.color_write_mask do color_mask |= {.R}
    if .G in target.blend.color_write_mask do color_mask |= {.G}
    if .B in target.blend.color_write_mask do color_mask |= {.B}
    if .A in target.blend.color_write_mask do color_mask |= {.A}
    color_blend_attachments[i] = {
      blendEnable = b32(target.blend.blend_enabled),
      srcColorBlendFactor = blend_factor_to_vulkan(target.blend.src_color_blend_factor),
      dstColorBlendFactor = blend_factor_to_vulkan(target.blend.dst_color_blend_factor),
      colorBlendOp        = blend_func_to_vulkan(target.blend.color_blend_func),
      srcAlphaBlendFactor = blend_factor_to_vulkan(target.blend.src_alpha_blend_factor),
      dstAlphaBlendFactor = blend_factor_to_vulkan(target.blend.dst_alpha_blend_factor),
      alphaBlendOp        = blend_func_to_vulkan(target.blend.alpha_blend_func),
      colorWriteMask      = color_mask,
    }
    color_formats[i] = format_to_vulkan(target.format)
  }
  color_blend_state := vk.PipelineColorBlendStateCreateInfo {
    sType = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
    attachmentCount = u32(len(color_blend_attachments)),
    pAttachments    = raw_data(color_blend_attachments),
    blendConstants  = desc.blend_constant,
  }

  rendering_create_info := vk.PipelineRenderingCreateInfo {
    sType = .PIPELINE_RENDERING_CREATE_INFO,
    colorAttachmentCount = u32(len(color_formats)),
    pColorAttachmentFormats = raw_data(color_formats),
    depthAttachmentFormat = depth_format,
    stencilAttachmentFormat = stencil_format,
  }

  dynamic_states := [?]vk.DynamicState { .VIEWPORT, .SCISSOR }
  dynamic_state := vk.PipelineDynamicStateCreateInfo {
    sType = .PIPELINE_DYNAMIC_STATE_CREATE_INFO,
    dynamicStateCount = len(dynamic_states),
    pDynamicStates = raw_data(&dynamic_states),
  }

  set_layouts := make([]vk.DescriptorSetLayout, len(desc.bind_group_layouts), context.temp_allocator)
  for group, i in desc.bind_group_layouts {
    set_layouts[i] = (hm.get(&device.bind_group_layouts, group)).layout
  }
  push_constant_ranges := make([]vk.PushConstantRange, len(desc.push_constant_ranges), context.temp_allocator)
  for pc, i in desc.push_constant_ranges {
    push_constant_ranges[i] = {
      stageFlags = shader_stage_flags_to_vulkan(pc.stages),
      offset = u32(pc.offset),
      size = u32(pc.size),
    }
  }
  layout: vk.PipelineLayout
  vk.CreatePipelineLayout(device.device, &{
    sType = .PIPELINE_LAYOUT_CREATE_INFO,
    setLayoutCount = u32(len(set_layouts)),
    pSetLayouts = raw_data(set_layouts),
    pushConstantRangeCount = u32(len(push_constant_ranges)),
    pPushConstantRanges = raw_data(push_constant_ranges),
  }, nil, &layout)

  vs, ok := hm.get(&device.shaders, desc.vertex_shader)
  assert(ok)
  fs, ok2 := hm.get(&device.shaders, desc.fragment_shader)
  assert(ok2)
  stages := [2]vk.PipelineShaderStageCreateInfo {
    {
      sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
      module = vs.module,
      pName = "main",
      stage = {.VERTEX},
    },
    {
      sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
      module = fs.module,
      pName = "main",
      stage = {.FRAGMENT},
    }
  }
  create_info := vk.GraphicsPipelineCreateInfo {
    sType = .GRAPHICS_PIPELINE_CREATE_INFO,
    stageCount = 2,
    pStages = raw_data(&stages),
    pVertexInputState = &vertex_input_state,
    pInputAssemblyState = &input_assembly_state,
    pTessellationState = &tessellation_state,
    pViewportState = &viewport_state,
    pRasterizationState = &rasterization_state,
    pMultisampleState = &multisample_state,
    pDepthStencilState = &depth_stencil_state,
    pColorBlendState = &color_blend_state,
    pDynamicState = &dynamic_state,
    layout = layout,
    pNext = &rendering_create_info,
  }

  pipeline: vk.Pipeline
  vk.CreateGraphicsPipelines(device.device, 0, 1, &create_info, nil, &pipeline)

  res: Vk_Pipeline
  res.pipeline = pipeline
  res.layout   = layout
  return hm.add(&device.pipelines, res)
}

Vk_Shader :: struct {
  handle: Shader,
  module: vk.ShaderModule,
}

vk_device_create_shader :: proc(device: Device, desc: Shader_Desc) -> Shader {
  ensure(desc.code_type == .Spirv, "Vulkan only supports Spirv shaders")

  device := cast(^Vk_Device)device
  create_info := vk.ShaderModuleCreateInfo {
    sType    = .SHADER_MODULE_CREATE_INFO,
    codeSize = len(desc.code) * size_of(u32),
    pCode    = raw_data(desc.code),
  }
  module: vk.ShaderModule
  vk.CreateShaderModule(device.device, &create_info, nil, &module)
  res: Vk_Shader
  res.module = module
  return hm.add(&device.shaders, res)
}

Vk_Buffer :: struct {
  handle: Buffer,
  buffer: vk.Buffer,
  memory: vk.DeviceMemory,
}

vk_device_create_buffer :: proc(device: Device, desc: Buffer_Desc) -> Buffer {
  device := cast(^Vk_Device)device

  buffer_create_info := vk.BufferCreateInfo {
    sType = .BUFFER_CREATE_INFO,
    size = vk.DeviceSize(desc.size),
    usage = buffer_usage_to_vulkan(desc.usage) | {.TRANSFER_DST},
  }
  buffer: vk.Buffer
  vk.CreateBuffer(device.device, &buffer_create_info, nil, &buffer)

  req: vk.MemoryRequirements
  vk.GetBufferMemoryRequirements(device.device, buffer, &req)
  memory: vk.DeviceMemory
  alloc_info := vk.MemoryAllocateInfo {
    sType = .MEMORY_ALLOCATE_INFO,
    allocationSize = req.size,
    memoryTypeIndex = vk_find_memory_type(device.instance.physical_device, req.memoryTypeBits, {.HOST_VISIBLE, .HOST_COHERENT})
  }
  vk.AllocateMemory(device.device, &alloc_info, nil, &memory)
  vk.BindBufferMemory(device.device, buffer, memory, 0)

  // staging_buffer_create_info := vk.BufferCreateInfo {
  //   sType = .BUFFER_CREATE_INFO,
  //   size = vk.DeviceSize(desc.size),
  //   usage = {.TRANSFER_SRC},
  // }
  // staging_buffer: vk.Buffer
  // vk.CreateBuffer(device.device, &staging_buffer_create_info, nil, &staging_buffer)
  // defer vk.DestroyBuffer(device.device, staging_buffer, nil)
  // staging_memory: vk.DeviceMemory
  // staging_alloc_info := vk.MemoryAllocateInfo {
  //   sType = .MEMORY_ALLOCATE_INFO,
  //   allocationSize = req.size,
  //   memoryTypeIndex = vk_find_memory_type(device.instance.physical_device, req.memoryTypeBits, {.HOST_VISIBLE, .HOST_COHERENT})
  // }
  // vk.AllocateMemory(device.device, &staging_alloc_info, nil, &staging_memory)
  // defer vk.FreeMemory(device.device, staging_memory, nil)
  // vk.BindBufferMemory(device.device, staging_buffer, staging_memory, 0)

  // data: rawptr
  // vk.MapMemory(device.device, staging_memory, 0, req.size, nil, &data)
  // mem.copy(data, desc.data, int(desc.size))
  // vk.UnmapMemory(device.device, staging_memory)

  // cmd := vk_device_begin_commands(Device(device))
  // copy_info := vk.BufferCopy { size = vk.DeviceSize(desc.size), }
  // vk.CmdCopyBuffer((cast(^Vk_Command_Buffer)cmd).buffer, staging_buffer, buffer, 1, &copy_info)
  // vk_device_submit_commands(Device(device), cmd)
  // vk.QueueWaitIdle(device.graphics_queue.queue)
  res: Vk_Buffer
  res.buffer = buffer
  res.memory = memory
  return hm.add(&device.buffers, res)
}

vk_render_pass_set_pipeline :: proc(pass: Render_Pass, pipeline: Pipeline) {
  pass := cast(^Vk_Render_Pass)pass
  pipeline, ok := hm.get(&pass.device.pipelines, pipeline)
  assert(ok)
  vk.CmdBindPipeline(pass.command_buffer, .GRAPHICS, pipeline.pipeline)
  pass.pipeline_layout = pipeline.layout
}

vk_render_pass_draw :: proc(pass: Render_Pass, element_count: int, first_element: int, instance_count: int, first_instance: int) {
  pass := cast(^Vk_Render_Pass)pass
  if pass.indexed_draw {
    vk.CmdDrawIndexed(pass.command_buffer, u32(element_count), u32(instance_count), u32(first_element), 0, u32(first_instance))
  } else {
    vk.CmdDraw(pass.command_buffer, u32(element_count), u32(instance_count), u32(first_element), u32(first_instance))
  }
}

vk_render_pass_set_vertex_buffers :: proc(pass: Render_Pass, buffers: []Buffer) {
  runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
  pass := cast(^Vk_Render_Pass)pass
  vk_buffers := make([^]vk.Buffer, len(buffers), context.temp_allocator)
  offsets := make([^]vk.DeviceSize, len(buffers), context.temp_allocator)
  for i in 0..<len(buffers) {
    buf, ok := hm.get(&pass.device.buffers, buffers[i])
    assert(ok)
    vk_buffers[i] = buf.buffer
    offsets[i] = 0
  }
  vk.CmdBindVertexBuffers(pass.command_buffer, 0, u32(len(buffers)), vk_buffers, offsets)
}

vk_render_pass_set_index_buffer :: proc(pass: Render_Pass, buffer: Buffer, index_type: Index_Type, offset: int) {
  pass := cast(^Vk_Render_Pass)pass
  buffer, ok := hm.get(&pass.device.buffers, buffer)
  assert(ok)
  vk.CmdBindIndexBuffer(pass.command_buffer, buffer.buffer, vk.DeviceSize(offset), index_type_to_vulkan(index_type))
  pass.indexed_draw = true
}

Vk_Bind_Group_Layout :: struct {
  handle: Bind_Group_Layout,
  layout: vk.DescriptorSetLayout,
  desc:   Bind_Group_Layout_Desc,
}

vk_device_create_bind_group_layout :: proc(device: Device, desc: Bind_Group_Layout_Desc) -> Bind_Group_Layout {
  runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

  device := cast(^Vk_Device)device
  bindings := make([]vk.DescriptorSetLayoutBinding, len(desc.entries), context.temp_allocator)
  for entry, i in desc.entries {
    bindings[i] = {
      descriptorType = bind_group_layout_entry_to_descriptor_type(entry),
      binding = entry.binding,
      descriptorCount = 1,
      stageFlags = shader_stage_flags_to_vulkan(entry.visibility),
    }
  }
  layout: vk.DescriptorSetLayout
  vk.CreateDescriptorSetLayout(device.device, &{
    sType = .DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
    bindingCount = u32(len(bindings)),
    pBindings = raw_data(bindings),
  }, nil, &layout)
  res: Vk_Bind_Group_Layout
  res.layout = layout
  res.desc = desc
  return hm.add(&device.bind_group_layouts, res)
}

Vk_Bind_Group :: struct {
  handle:          Bind_Group,
  descriptor_pool: vk.DescriptorPool,
  descriptor_set:  vk.DescriptorSet,
  texture_views:   []Texture_View,
}

vk_device_create_bind_group :: proc(device: Device, desc: Bind_Group_Desc) -> Bind_Group {
  runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
  device := cast(^Vk_Device)device
  layout, ok := hm.get(&device.bind_group_layouts, desc.layout)
  assert(ok)

  sampler_pool_size := vk.DescriptorPoolSize{type = .SAMPLER}
  uniform_buffer_pool_size := vk.DescriptorPoolSize{type = .UNIFORM_BUFFER}
  storage_buffer_pool_size := vk.DescriptorPoolSize{type = .STORAGE_BUFFER}
  iamge_pool_size := vk.DescriptorPoolSize{type = .SAMPLED_IMAGE}
  storage_iamge_pool_size := vk.DescriptorPoolSize{type = .STORAGE_IMAGE}
  buffer_count: u32
  image_count:  u32
  for entry in layout.desc.entries {
    switch l in entry.layout {
    case Sampler_Binding_Layout:
      sampler_pool_size.descriptorCount += 1
      image_count += 1
    case Buffer_Binding_Layout:
      switch l.type {
      case .Uniform: uniform_buffer_pool_size.descriptorCount += 1
      case .Storage, .Read_Only_Storage: storage_buffer_pool_size.descriptorCount += 1
      }
      buffer_count += 1
    case Texture_Binding_Layout:
      iamge_pool_size.descriptorCount += 1
      image_count += 1
    case Storage_Texture_Binding_Layout:
      storage_iamge_pool_size.descriptorCount += 1
      image_count += 1
    }
  }
  pool_sizes: [dynamic; 8]vk.DescriptorPoolSize
  if sampler_pool_size.descriptorCount != 0 do append(&pool_sizes, sampler_pool_size)
  if uniform_buffer_pool_size.descriptorCount != 0 do append(&pool_sizes, uniform_buffer_pool_size)
  if storage_buffer_pool_size.descriptorCount != 0 do append(&pool_sizes, storage_buffer_pool_size)
  if iamge_pool_size.descriptorCount != 0 do append(&pool_sizes, iamge_pool_size)
  if storage_iamge_pool_size.descriptorCount != 0 do append(&pool_sizes, storage_iamge_pool_size)
  pool_create_info := vk.DescriptorPoolCreateInfo {
    sType = .DESCRIPTOR_POOL_CREATE_INFO,
    maxSets = 1,
    poolSizeCount = u32(len(pool_sizes)),
    pPoolSizes = raw_data(&pool_sizes),
  }
  descriptor_pool: vk.DescriptorPool
  vk.CreateDescriptorPool(device.device, &pool_create_info, nil, &descriptor_pool)

  descriptor_set: vk.DescriptorSet
  set_alloc_info := vk.DescriptorSetAllocateInfo {
    sType = .DESCRIPTOR_SET_ALLOCATE_INFO,
    descriptorPool = descriptor_pool,
    descriptorSetCount = 1,
    pSetLayouts = &layout.layout,
  }
  vk.AllocateDescriptorSets(device.device, &set_alloc_info, &descriptor_set)

  buffer_infos := make([]vk.DescriptorBufferInfo, buffer_count, context.temp_allocator)
  image_infos  := make([]vk.DescriptorImageInfo,  image_count,  context.temp_allocator)
  image_idx, buffer_idx: int

  texture_views := make([dynamic]Texture_View, 0, 16)

  descriptor_set_writes := make([]vk.WriteDescriptorSet, len(desc.entries), context.temp_allocator)
  for entry, i in desc.entries {
    layout_entry_idx, found := slice.binary_search_by(layout.desc.entries, entry.binding, proc(t: Bind_Group_Layout_Entry, k: u32) -> slice.Ordering {
      return slice.cmp(t.binding, k)
    })
    assert(found, "bind group entry does not extist in layout")
    layout_entry := layout.desc.entries[layout_entry_idx]
    write := vk.WriteDescriptorSet {
      sType = .WRITE_DESCRIPTOR_SET,
      descriptorType = bind_group_layout_entry_to_descriptor_type(layout_entry),
      descriptorCount = 1,
      dstBinding = entry.binding,
      dstSet = descriptor_set,
    }
    switch res in entry.resource {
    case Sampler:
      sampler, ok := hm.get(&device.samplers, res)
  assert(ok)
      image_infos[image_idx] = { sampler = sampler.sampler, }
      write.pImageInfo = &image_infos[image_idx]
      image_idx += 1
    case Buffer:
      buffer, ok := hm.get(&device.buffers, res)
  assert(ok)
      buffer_infos[buffer_idx] = {
        buffer = buffer.buffer,
        range = vk.DeviceSize(vk.WHOLE_SIZE),
      }
      write.pBufferInfo = &buffer_infos[buffer_idx]
      buffer_idx += 1
    case Texture_View:
      view, ok := hm.get(&device.texture_views, res)
  assert(ok)
      image_layout: vk.ImageLayout
      #partial switch _ in layout_entry.layout {
      case Texture_Binding_Layout:
        image_layout = .SHADER_READ_ONLY_OPTIMAL
      case Storage_Texture_Binding_Layout:
        image_layout = .GENERAL
      case: unreachable()
      }
      image_infos[image_idx] = { imageView = view.view, imageLayout = image_layout }
      write.pImageInfo = &image_infos[image_idx]
      append(&texture_views, res)
      image_idx += 1
    }
    descriptor_set_writes[i] = write
  }
  vk.UpdateDescriptorSets(device.device, u32(len(descriptor_set_writes)), raw_data(descriptor_set_writes), 0, nil)

  res: Vk_Bind_Group
  res.descriptor_pool = descriptor_pool
  res.descriptor_set = descriptor_set
  res.texture_views = texture_views[:]
  return hm.add(&device.bind_groups, res)
}

bind_group_layout_entry_to_descriptor_type :: proc "contextless" (entry: Bind_Group_Layout_Entry) -> vk.DescriptorType {
  switch l in entry.layout {
  case Sampler_Binding_Layout: return .SAMPLER
  case Buffer_Binding_Layout:
    switch l.type {
    case .Uniform: return .UNIFORM_BUFFER
    case .Storage, .Read_Only_Storage: return .STORAGE_BUFFER
    }
  case Texture_Binding_Layout: return .SAMPLED_IMAGE
  case Storage_Texture_Binding_Layout: return .STORAGE_IMAGE
  }
  unreachable()
}

vk_device_write_texture :: proc(device: Device, info: Texture_Write_Info) {
  device := cast(^Vk_Device)device
  texture, ok := hm.get(&device.textures, info.texture)
  assert(ok)

  memory_requirements: vk.MemoryRequirements
  vk.GetImageMemoryRequirements(device.device, texture.image, &memory_requirements)

  staging_buffer, staging_memory := vk_create_staging_buffer(device.device, device.instance.physical_device, int(memory_requirements.size), {.TRANSFER_SRC}, {.HOST_VISIBLE})
  defer {
    vk.DestroyBuffer(device.device, staging_buffer, nil)
    vk.FreeMemory(device.device, staging_memory, nil)
  }

  data: rawptr
  vk.MapMemory(device.device, staging_memory, 0, memory_requirements.size, nil, &data)
  mem.copy(data, info.pixels, int(memory_requirements.size))
  vk.UnmapMemory(device.device, staging_memory)

  cmd := vk_device_begin_commands(Device(device))
  vk_cmd := cast(^Vk_Command_Buffer)cmd

  aspect: vk.ImageAspectFlags
  #partial switch texture.format {
  case .D32_SFLOAT: aspect = {.DEPTH}
  case .D32_SFLOAT_S8_UINT: aspect = {.DEPTH, .STENCIL}
  case .D24_UNORM_S8_UINT: aspect = {.DEPTH, .STENCIL}
  case: aspect = {.COLOR}
  }
  vk_transition_image(vk_cmd.buffer, texture.image, .UNDEFINED, .TRANSFER_DST_OPTIMAL, {
    aspectMask = aspect,
    baseArrayLayer = info.array_layer,
    layerCount = 1,
    baseMipLevel = info.mip_level,
    levelCount = 1,
  })
  region := vk.BufferImageCopy {
    imageOffset = transmute(vk.Offset3D)info.offset,
    imageExtent = transmute(vk.Extent3D)info.extent,
    imageSubresource = {
      aspectMask     = aspect,
      layerCount     = 1,
      mipLevel       = info.mip_level,
      baseArrayLayer = info.array_layer,
    },
  }
  vk.CmdCopyBufferToImage(vk_cmd.buffer, staging_buffer, texture.image, .TRANSFER_DST_OPTIMAL, 1, &region)

  if texture.storage {
    vk_transition_image(vk_cmd.buffer, texture.image, .UNDEFINED, .GENERAL, {
      aspectMask = aspect,
      layerCount = 1,
      levelCount = 1,
    })
  } else {
    vk_transition_image(vk_cmd.buffer, texture.image, .UNDEFINED, .SHADER_READ_ONLY_OPTIMAL, {
      aspectMask = aspect,
      layerCount = 1,
      levelCount = 1,
    })
  }
  vk_device_submit_commands(Device(device), Command_Buffer(cmd))
  vk.QueueWaitIdle(device.graphics_queue.queue)
}

vk_device_write_buffer :: proc(device: Device, info: Buffer_Write_Info) {
  device := cast(^Vk_Device)device
  buffer, ok := hm.get(&device.buffers, info.buffer)
  assert(ok)

  data: rawptr
  vk.MapMemory(device.device, buffer.memory, vk.DeviceSize(info.offset), vk.DeviceSize(info.size), nil, &data)
  mem.copy(data, info.data, info.size)
  vk.UnmapMemory(device.device, buffer.memory)
}

// ----- Render Pass ------

Vk_Render_Pass :: struct {
  device:          ^Vk_Device,
  command_buffer:  vk.CommandBuffer,
  pipeline_layout: vk.PipelineLayout,
  indexed_draw:    bool,
}

vk_render_pass_set_bind_group :: proc(pass: Render_Pass, group_index: int, bind_group: Bind_Group) {
  pass := cast(^Vk_Render_Pass)pass
  bind_group, ok := hm.get(&pass.device.bind_groups, bind_group)
  assert(ok)
  vk.CmdBindDescriptorSets(pass.command_buffer, .GRAPHICS, pass.pipeline_layout, u32(group_index), 1, &bind_group.descriptor_set, 0, nil)
}

vk_render_pass_set_push_constants :: proc(pass: Render_Pass, info: Push_Constant_Info) {
  pass := cast(^Vk_Render_Pass)pass
  vk.CmdPushConstants(pass.command_buffer, pass.pipeline_layout,
    shader_stage_flags_to_vulkan(info.stages),
    u32(info.offset), u32(info.size), info.data)
}

vk_render_pass_set_viewport :: proc(pass: Render_Pass, viewport: Viewport) {
  viewport := vk.Viewport {
    x = viewport.offset.x,
    y = viewport.offset.y,
    width = viewport.extent.x,
    height = viewport.extent.y,
    maxDepth = 1,
  }
  vk.CmdSetViewport((cast(^Vk_Render_Pass)pass).command_buffer, 0, 1, &viewport)
}

vk_render_pass_set_scissor :: proc(pass: Render_Pass, rect: Rect2D) {
  rect := vk.Rect2D {
    offset = {i32(rect.offset.x), i32(rect.offset.y)},
    extent = {rect.extent.x, rect.extent.y},
  }
  vk.CmdSetScissor((cast(^Vk_Render_Pass)pass).command_buffer, 0, 1, &rect)
}

// ----- Device Functions -----

vk_device_destroy_sampler :: proc(device: Device, sampler: Sampler) {
  device := cast(^Vk_Device)device
  sampler, ok := hm.get(&device.samplers, sampler)
  assert(ok)
  vk.DestroySampler(device.device, sampler.sampler, nil)
  hm.remove(&device.samplers, sampler.handle)
}

vk_device_destroy_texture :: proc(device: Device, texture: Texture) {
  device := cast(^Vk_Device)device
  texture, ok := hm.get(&device.textures, texture)
  assert(ok)
  vk.FreeMemory(device.device, texture.memory, nil)
  vk.DestroyImage(device.device, texture.image, nil)
  hm.remove(&device.textures, texture.handle)
}

vk_device_destroy_texture_view :: proc(device: Device, view: Texture_View) {
  device := cast(^Vk_Device)device
  view, ok := hm.get(&device.texture_views, view)
  assert(ok)
  vk.DestroyImageView(device.device, view.view, nil)
  hm.remove(&device.texture_views, view.handle)
}

vk_device_destroy_shader :: proc(device: Device, shader: Shader) {
  device := cast(^Vk_Device)device
  shader, ok := hm.get(&device.shaders, shader)
  assert(ok)
  vk.DestroyShaderModule(device.device, shader.module, nil)
  hm.remove(&device.shaders, shader.handle)
}

vk_device_destroy_pipeline :: proc(device: Device, pipeline: Pipeline) {
  device := cast(^Vk_Device)device
  pipeline, ok := hm.get(&device.pipelines, pipeline)
  assert(ok)
  vk.DestroyPipelineLayout(device.device, pipeline.layout, nil)
  vk.DestroyPipeline(device.device, pipeline.pipeline, nil)
  hm.remove(&device.pipelines, pipeline.handle)
}

vk_device_destroy_buffer :: proc(device: Device, buffer: Buffer) {
  device := cast(^Vk_Device)device
  buffer, ok := hm.get(&device.buffers, buffer)
  assert(ok)
  vk.DestroyBuffer(device.device, buffer.buffer, nil)
  vk.FreeMemory(device.device, buffer.memory, nil)
  hm.remove(&device.buffers, buffer.handle)
}

vk_device_destroy_bind_group_layout :: proc(device: Device, layout: Bind_Group_Layout) {
  device := cast(^Vk_Device)device
  layout, ok := hm.get(&device.bind_group_layouts, layout)
  assert(ok)
  vk.DestroyDescriptorSetLayout(device.device, layout.layout, nil)
  hm.remove(&device.bind_group_layouts, layout.handle)
}

vk_device_destroy_bind_group :: proc(device: Device, bind_group: Bind_Group) {
  device := cast(^Vk_Device)device
  bind_group, ok := hm.get(&device.bind_groups, bind_group)
  assert(ok)
  vk.DestroyDescriptorPool(device.device, bind_group.descriptor_pool, nil)
  hm.remove(&device.bind_groups, bind_group.handle)
}

// ----- Conversion Functions -------
@(private="file")
format_to_vulkan :: #force_inline proc "contextless" (format: Format) -> vk.Format {
  switch format {
  case .R8_UNORM: return .R8_UNORM
  case .RG8_UNORM: return .R8G8_UNORM
  case .RGB8_UNORM: return .R8G8B8_UNORM
  case .RGBA8_UNORM: return .R8G8B8A8_UNORM
  case .BGRA8_UNORM: return .B8G8R8A8_UNORM
  case .R16_UNORM: return .R16_UNORM
  case .RG16_UNORM: return .R16G16_UNORM
  case .RGB16_UNORM: return .R16G16B16_UNORM
  case .RGBA16_UNORM: return .R16G16B16A16_UNORM
  case .R8_SNORM: return .R8_SNORM
  case .RG8_SNORM: return .R8G8_SNORM
  case .RGB8_SNORM: return .R8G8B8_SNORM
  case .RGBA8_SNORM: return .R8G8B8A8_SNORM
  case .R16_SNORM: return .R16_SNORM
  case .RG16_SNORM: return .R16G16_SNORM
  case .RGB16_SNORM: return .R16G16B16_SNORM
  case .RGBA16_SNORM: return .R16G16B16A16_SNORM
  case .R16_FLOAT: return .R16_SFLOAT
  case .RG16_FLOAT: return .R16G16_SFLOAT
  case .RGB16_FLOAT: return .R16G16B16_SFLOAT
  case .RGBA16_FLOAT: return .R16G16B16A16_SFLOAT
  case .R32_FLOAT: return .R32_SFLOAT
  case .RG32_FLOAT: return .R32G32_SFLOAT
  case .RGB32_FLOAT: return .R32G32B32_SFLOAT
  case .RGBA32_FLOAT: return .R32G32B32A32_SFLOAT
  case .R8_UINT: return .R8_UINT
  case .RG8_UINT: return .R8G8_UINT
  case .RGB8_UINT: return .R8G8B8_UINT
  case .RGBA8_UINT: return .R8G8B8A8_UINT
  case .R16_UINT: return .R16_UINT
  case .RG16_UINT: return .R16G16_UINT
  case .RGB16_UINT: return .R16G16B16_UINT
  case .RGBA16_UINT: return .R16G16B16A16_UINT
  case .R32_UINT: return .R32_UINT
  case .RG32_UINT: return .R32G32_UINT
  case .RGB32_UINT: return .R32G32B32_UINT
  case .RGBA32_UINT: return .R32G32B32A32_UINT
  case .R8_SINT: return .R8_SINT
  case .RG8_SINT: return .R8G8_SINT
  case .RGB8_SINT: return .R8G8B8_SINT
  case .RGBA8_SINT: return .R8G8B8A8_SINT
  case .R16_SINT: return .R16_SINT
  case .RG16_SINT: return .R16G16_SINT
  case .RGB16_SINT: return .R16G16B16_SINT
  case .RGBA16_SINT: return .R16G16B16A16_SINT
  case .R32_SINT: return .R32_SINT
  case .RG32_SINT: return .R32G32_SINT
  case .RGB32_SINT: return .R32G32B32_SINT
  case .RGBA32_SINT: return .R32G32B32A32_SINT
  case .D32_FLOAT: return .D32_SFLOAT
  case .D24_UNORM_S8_UINT: return .D24_UNORM_S8_UINT
  case .D32_FLOAT_S8_UINT: return .D32_SFLOAT_S8_UINT
  }
  unreachable()
}

present_mode_to_vulkan :: #force_inline proc "contextless" (present_mode: Present_Mode) -> vk.PresentModeKHR {
  switch present_mode {
  case .Fifo:    return .FIFO
  case .Mailbox: return .MAILBOX
  }
  unreachable()
}

texture_dim_to_vulkan :: #force_inline proc "contextless" (dim: Texture_Dim) -> vk.ImageType {
  switch dim {
  case .D1:         return .D1
  case .D2:         return .D2
  case .D3:         return .D3
  }
  unreachable()
}

texture_view_dim_to_vulkan :: #force_inline proc "contextless" (dim: Texture_View_Dim) -> vk.ImageViewType {
  switch dim {
  case .D1:         return .D1
  case .D2:         return .D2
  case .D3:         return .D3
  case .D2_Array:      return .D2_ARRAY
  case .Cube:       return .CUBE
  case .Cube_Array: return .CUBE_ARRAY
  }
  unreachable()
}

wrap_to_vk_sampler_address_mode :: #force_inline proc "contextless" (wrap: Wrap) -> vk.SamplerAddressMode {
  switch wrap {
  case .Clamp_To_Edge:        return .CLAMP_TO_EDGE
  case .Clamp_To_Border:      return .CLAMP_TO_BORDER
  case .Repeat:               return .REPEAT
  case .Mirror_Repeat:        return .MIRRORED_REPEAT
  case .Mirror_Clamp_To_Edge: return .MIRROR_CLAMP_TO_EDGE
  }
  unreachable()
}

border_color_to_vulkan :: #force_inline proc "contextless" (border_color: Border_Color) -> vk.BorderColor {
  switch border_color {
  case .Transparent_Black: return .FLOAT_TRANSPARENT_BLACK
  case .Opaque_Black:      return .FLOAT_OPAQUE_BLACK
  case .Opaque_White:      return .FLOAT_OPAQUE_WHITE
  }
  unreachable()
}

filter_to_vulkan :: #force_inline proc "contextless" (filter: Filter) -> vk.Filter {
  return .LINEAR if filter == .Linear else .NEAREST
}

load_action_to_vulkan :: #force_inline proc "contextless" (action: Load_Action) -> vk.AttachmentLoadOp {
  switch action {
  case .Dont_Care: return .DONT_CARE
  case .Load:      return .LOAD
  case .Clear:     return .CLEAR
  }
  unreachable()
}

store_action_to_vulkan :: #force_inline proc "contextless" (action: Store_Action) -> vk.AttachmentStoreOp {
  switch action {
  case .Dont_Care: return .DONT_CARE
  case .Store:     return .STORE
  }
  unreachable()
}

topology_type_to_vulkan :: #force_inline proc "contextless" (topology: Topology_Type) -> vk.PrimitiveTopology {
  switch topology {
  case .Point_List:     return .POINT_LIST
  case .Line_List:      return .LINE_LIST
  case .Line_Strip:     return .LINE_STRIP
  case .Triangle_List:  return .TRIANGLE_LIST
  case .Triangle_Strip: return .TRIANGLE_STRIP
  case .Triangle_Fan:   return .TRIANGLE_FAN
  }
  unreachable()
}

cull_mode_to_vulkan :: #force_inline proc "contextless" (cull_mode: Cull_Mode) -> vk.CullModeFlags {
  switch cull_mode {
  case .None:  return nil
  case .Front: return {.FRONT}
  case .Back:  return {.BACK}
  }
  unreachable()
}

blend_factor_to_vulkan :: #force_inline proc "contextless" (factor: Blend_Factor) -> vk.BlendFactor {
  switch factor {
  case .Zero:                     return .ZERO
  case .One:                      return .ONE
  case .Src_COLOR:                return .SRC_COLOR
  case .One_Minus_Src_Color:      return .ONE_MINUS_SRC_COLOR
  case .Dst_Color:                return .DST_COLOR
  case .One_Minus_Dst_Color:      return .ONE_MINUS_DST_COLOR
  case .Src_Alpha:                return .SRC_ALPHA
  case .One_Minus_Src_Alpha:      return .ONE_MINUS_SRC_ALPHA
  case .Dst_Alpha:                return .DST_ALPHA
  case .One_Minus_Dst_Alpha:      return .ONE_MINUS_DST_ALPHA
  case .Constant_Color:           return .CONSTANT_COLOR
  case .One_Minus_Constant_Color: return .ONE_MINUS_CONSTANT_COLOR
  case .Constant_Alpha:           return .CONSTANT_ALPHA
  case .One_Minus_Constant_Alpha: return .ONE_MINUS_CONSTANT_ALPHA
  case .Src_Alpha_Saturate:       return .SRC_ALPHA_SATURATE
  case .Src1_Color:               return .SRC1_COLOR
  case .One_Minus_Src1_Color:     return .ONE_MINUS_SRC1_COLOR
  case .Src1_Alpha:               return .SRC1_ALPHA
  case .One_Minus_Src1_Alpha:     return .ONE_MINUS_SRC1_ALPHA
  }
  unreachable()
}

blend_func_to_vulkan :: #force_inline proc "contextless" (func: Blend_Func) -> vk.BlendOp {
  switch func {
  case .Add:              return .ADD
  case .Subtract:         return .SUBTRACT
  case .Reverse_Subtract: return .REVERSE_SUBTRACT
  case .Min:              return .MIN
  case .Max:              return .MAX
  }
  unreachable()
}

buffer_usage_to_vulkan :: #force_inline proc "contextless" (usage: Buffer_Usage_Flags) -> (res: vk.BufferUsageFlags) {
  if .Vertex_Buffer  in usage do res |= {.VERTEX_BUFFER}
  if .Index_Buffer   in usage do res |= {.INDEX_BUFFER}
  if .Uniform_Buffer in usage do res |= {.UNIFORM_BUFFER}
  if .Storage_Buffer in usage do res |= {.STORAGE_BUFFER}
  return
}

index_type_to_vulkan :: #force_inline proc "contextless" (type: Index_Type) -> vk.IndexType {
  switch type {
  case .U32: return .UINT32
  case .U16: return .UINT16
  }
  unreachable()
}

shader_stage_flags_to_vulkan :: #force_inline proc "contextless" (flags: Shader_Stage_Flags) -> (res: vk.ShaderStageFlags) {
  if .Vertex                  in flags do res |= { .VERTEX }
  if .Fragment                in flags do res |= { .FRAGMENT }
  if .Tessellation_Control    in flags do res |= { .TESSELLATION_CONTROL }
  if .Tessellation_Evaluation in flags do res |= { .TESSELLATION_EVALUATION }
  if .Geometry                in flags do res |= { .GEOMETRY }
  if .Compute                 in flags do res |= { .COMPUTE }
  return
}

compare_func_to_vulkan :: #force_inline proc "contextless" (compare_func: Compare_Func) -> vk.CompareOp {
  switch compare_func {
  case .Never: return .NEVER
  case .Less: return .LESS
  case .Equal: return .EQUAL
  case .Less_Or_Equal: return .LESS_OR_EQUAL
  case .Greater: return .GREATER
  case .Not_Equal: return .NOT_EQUAL
  case .Greater_Or_Equal: return .GREATER_OR_EQUAL
  case .Always: return .ALWAYS
  }
  unreachable()
}

stencil_state_to_vulkan :: #force_inline proc "contextless" (state: Stencil_State) -> (res: vk.StencilOpState) {
  res.compareOp = compare_func_to_vulkan(state.compare)
  res.failOp = stencil_func_to_vulkane(state.fail)
  res.passOp = stencil_func_to_vulkane(state.pass)
  res.depthFailOp = stencil_func_to_vulkane(state.depth_fail)
  res.compareMask = state.compare_mask
  res.writeMask   = state.write_mask
  res.reference   = state.reference
  return
}

stencil_func_to_vulkane :: #force_inline proc "contextless" (func: Stencil_Func) -> vk.StencilOp {
  switch func {
  case .Keep: return .KEEP
  case .Zero: return .ZERO
  case .Replace: return .REPLACE
  case .Increment_And_Clamp: return .INCREMENT_AND_CLAMP
  case .Decrement_And_Clamp: return .DECREMENT_AND_CLAMP
  case .Invert: return .INVERT
  case .Increment_And_Wrap: return .INCREMENT_AND_WRAP
  case .Decrement_And_Wrap: return .DECREMENT_AND_WRAP
  }
  unreachable()
}
