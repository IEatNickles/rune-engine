package input

MouseButton :: enum {
	Mouse1,
	Mouse2,
	Mouse3,
	Mouse4,
	Mouse5,
	Mouse6,
	Mouse7,
	Mouse8,

	// Aliases
	Left = Mouse1,
	Right = Mouse2,
	Middle = Mouse3,
}
MouseButton_BitSet :: bit_set[MouseButton]
