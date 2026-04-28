package editor

import "../rune_engine/"
import "core:os"

main :: proc() {
	args := os.args

	rune_engine.init({
    init_proc = editor_layer_on_attach,
    update_proc = editor_layer_on_update,
    event_proc = editor_on_event,
    quit_proc = editor_layer_on_detach,
    window = {
      "Editor",
      1700, 1000
    }
  })
	defer rune_engine.terminate()

	// rune_engine.push_layer(
	// 	Editor_Layer,
	// 	editor_layer_on_attach,
	// 	editor_layer_on_update,
	// 	editor_layer_on_detach,
	// )

	rune_engine.run()
}
