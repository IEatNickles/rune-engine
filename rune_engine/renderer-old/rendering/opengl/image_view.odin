package opengl

import "core:container/handle_map"
import ".."

Image_View_State :: struct {
  handle: rendering.Image_View,
  image:  u32,
}

create_image_view :: proc(info: ^rendering.Image_View_Create_Info) -> rendering.Image_View {
  return {}
}

destroy_image_view :: proc(view: rendering.Image_View) {
  handle_map.remove(&ctx.image_views, view)
}
