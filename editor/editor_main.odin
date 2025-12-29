package editor

import "../rune_engine/"
import "core:os/os2"

main :: proc() {
	args := os2.args

	rune_engine.init("Editor", 1700, 1000)
	defer rune_engine.terminate()

	rune_engine.push_layer(
		EditorLayer,
		editor_layer_on_attach,
		editor_layer_on_update,
		editor_layer_on_detach,
	)

	rune_engine.run()
}
