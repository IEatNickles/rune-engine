package rune_engine

import "renderer"

create_texture :: proc(info: ^renderer.Texture_Create_Info) -> renderer.Texture {
  return renderer.create_texture(&application.renderer, info)
}

bind_texture :: proc(texture: renderer.Texture) {
  renderer.bind_texture(&application.renderer, texture)
}
