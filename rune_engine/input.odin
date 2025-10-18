package rune_engine

import "input"

key_down :: proc(key: input.KeyCode) -> bool {
	return key in application.input.keys
}

key_up :: proc(key: input.KeyCode) -> bool {
	return key not_in application.input.keys
}

key_pressed :: proc(key: input.KeyCode) -> bool {
	return key in application.input.keys && key not_in application.input.prev_keys
}

key_released :: proc(key: input.KeyCode) -> bool {
	return key not_in application.input.keys && key in application.input.prev_keys
}

get_mouse_delta :: proc() -> [2]f32 {
	return application.input.mouse_delta
}

get_mouse_position :: proc() -> [2]f32 {
	return application.input.mouse_position
}

get_scroll :: proc() -> f32 {
	return application.input.scroll
}

get_scroll_horizontal :: proc() -> f32 {
	return application.input.horizontal_scroll
}
