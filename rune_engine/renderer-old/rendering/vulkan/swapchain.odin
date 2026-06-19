package vulkan_backend

// import "core:fmt"
// import vk "vendor:vulkan"
//
// import ".."

// @(private)
// create_swapchain :: proc() {
//   surf_caps: vk.SurfaceCapabilitiesKHR
//   vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(ctx.phys_device, ctx.surface, &surf_caps)
//   ctx.surface_format = pick_surface_format(ctx.phys_device, ctx.surface)
//
//   create_info := vk.SwapchainCreateInfoKHR {
//     sType = .SWAPCHAIN_CREATE_INFO_KHR,
//     surface = ctx.surface,
//     imageExtent = surf_caps.currentExtent,
//     presentMode = .FIFO,
//     imageColorSpace = ctx.surface_format.colorSpace,
//     imageFormat = ctx.surface_format.format,
//     imageUsage = { .COLOR_ATTACHMENT },
//     imageSharingMode = .EXCLUSIVE,
//     imageArrayLayers = 1,
//     preTransform = surf_caps.currentTransform,
//     compositeAlpha = { .OPAQUE },
//     minImageCount = surf_caps.minImageCount,
//     queueFamilyIndexCount = 1,
//     pQueueFamilyIndices = &ctx.queue_family,
//     clipped = true,
//   }
//   vk.CreateSwapchainKHR(ctx.device, &create_info, nil, &ctx.swapchain)
//
//   vk.GetSwapchainImagesKHR(ctx.device, ctx.swapchain, &ctx.sc_image_count, nil)
//   ctx.sc_raw_images = make([^]vk.Image, ctx.sc_image_count)
//   ctx.sc_images = make([^]rendering.Image, ctx.sc_image_count)
//   ctx.sc_image_views = make([^]rendering.Image_View, ctx.sc_image_count)
//   vk.GetSwapchainImagesKHR(ctx.device, ctx.swapchain, &ctx.sc_image_count, ctx.sc_raw_images)
//   for i in 0..<ctx.sc_image_count {
//     ctx.sc_images[i] = create_image(&{
//       raw_handle = cast(u64)ctx.sc_raw_images[i],
//       format = .RGBA8 if ctx.surface_format.format == .R8G8B8A8_UNORM else .BGRA8,
//       size = { surf_caps.currentExtent.width, surf_caps.currentExtent.height, 1 },
//       type = .D2,
//     })
//     ctx.sc_image_views[i] = create_image_view(&{
//       image = ctx.sc_images[i],
//       size = { surf_caps.currentExtent.width, surf_caps.currentExtent.height, 1 },
//       type = .D2,
//     })
//   }
// }
//
// @(private="file")
// pick_surface_format :: proc(phys_device: vk.PhysicalDevice, surface: vk.SurfaceKHR) -> vk.SurfaceFormatKHR {
//   format_count: u32
//   vk.GetPhysicalDeviceSurfaceFormatsKHR(phys_device, surface, &format_count, nil)
//   formats := make([^]vk.SurfaceFormatKHR, format_count)
//   defer free(formats)
//   vk.GetPhysicalDeviceSurfaceFormatsKHR(phys_device, surface, &format_count, formats)
//   for i in 0..<format_count {
//     f := formats[i]
//     #partial switch f.format {
//     case .B8G8R8A8_UNORM, .R8G8B8A8_UNORM: return f
//     }
//   }
//   return formats[0]
// }
//
// get_render_target :: proc() -> rendering.Image_View {
//   assert(vk.AcquireNextImageKHR(
//     ctx.device,
//     ctx.swapchain,
//     max(u64),
//     ctx.image_available_semaphores[ctx.current_frame.index],
//     0,
//     &ctx.sc_image_index) == .SUCCESS)
//   return ctx.sc_image_views[ctx.sc_image_index]
// }
//
// present :: proc() {
//   present_info := vk.PresentInfoKHR {
//     sType = .PRESENT_INFO_KHR,
//     swapchainCount = 1,
//     pSwapchains = &ctx.swapchain,
//     pImageIndices = &ctx.sc_image_index,
//     waitSemaphoreCount = 1,
//     pWaitSemaphores = &ctx.submit_semaphores[ctx.current_frame.index],
//   }
//   vk.QueuePresentKHR(ctx.queue, &present_info)
//
//   ctx.current_frame.index = (ctx.current_frame.index + 1) % MAX_FRAMES_IN_FLIGHT
// }
