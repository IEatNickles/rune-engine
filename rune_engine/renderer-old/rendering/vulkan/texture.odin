package vulkan_backend

import ".."

Texture_State :: struct {
  handle: rendering.Texture,
}

create_texture :: proc(info: ^rendering.Texture_Create_Info) -> rendering.Texture {
  return {}
}

destroy_texture :: proc(texture: rendering.Texture) {
}

get_texture_descriptor :: proc(texture: rendering.Texture) -> u64 {
  return 0
}
