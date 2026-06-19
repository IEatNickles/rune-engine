package vulkan_backend

import "core:container/handle_map"
import vk "vendor:vulkan"

import ".."

Image_View_State :: struct {
  handle: rendering.Image_View,
  view:   vk.ImageView,
  size:   [3]u32,
  offset: [3]u32,
}

create_image_view :: proc(info: ^rendering.Image_View_Create_Info) -> rendering.Image_View {
  assert(info != nil)
  assert(info.image != {})
  state: Image_View_State
  img_state := handle_map.get(&ctx.images, info.image)
  create_info := vk.ImageViewCreateInfo {
    sType = .IMAGE_VIEW_CREATE_INFO,
    format = img_state.format,
    image = img_state.image,
    viewType = .D2,
    subresourceRange = {
      aspectMask = { .COLOR },
      layerCount = 1,
      levelCount = 1,
    },
  }
  vk.CreateImageView(ctx.device, &create_info, nil, &state.view)
  return handle_map.add(&ctx.image_views, state)
}

destroy_image_view :: proc(view: rendering.Image_View) {
  state := handle_map.get(&ctx.image_views, view)
  handle_map.remove(&ctx.image_views, view)
  vk.DestroyImageView(ctx.device, state.view, nil)
}
