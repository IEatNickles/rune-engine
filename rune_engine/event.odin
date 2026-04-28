package rune_engine

import "input"

Key_Event :: struct {
	key:      input.KeyCode,
	action:   input.Action,
	mods:     input.Modifiers,
}

Mouse_Button_Event :: struct {
	button: input.MouseButton,
	action: input.Action,
}

Mouse_Pos_Event :: struct {
	position: [2]f32,
  delta:    [2]f32,
}

Mouse_Enter_Event :: struct {
  entered: bool,
}

Scroll_Event :: struct {
	vertical:   f32,
	horizontal: f32,
}

Text_Event :: struct {
  codepoint: rune
}

Event :: union {
	Key_Event,
	Mouse_Button_Event,
	Mouse_Pos_Event,
  Mouse_Enter_Event,
	Scroll_Event,
  Text_Event,
}
