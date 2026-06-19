package opengl

import "core:container/handle_map"
import ".."

Image_State :: struct {
  handle: rendering.Image,
}

create_image :: proc(info: ^rendering.Image_Create_Info) -> rendering.Image {
  return {}
}

destroy_image :: proc(image: rendering.Image) {
  handle_map.remove(&ctx.images, image)
}
