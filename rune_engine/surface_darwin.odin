#+build darwin
package rune_engine

import NS "core:sys/darwin/Foundation"
import CA "vendor:darwin/QuartzCore"
import "vendor:glfw"
import "renderer"

get_surface_desc :: proc(window: glfw.WindowHandle) -> renderer.Surface_Desc {
    nativeWindow := (^NS.Window)(glfw.GetCocoaWindow(ctx.os.window))

    metalLayer := CA.MetalLayer.layer()
    defer metalLayer->release()

    nativeWindow->contentView()->setLayer(metalLayer)

    return {
      source = renderer.Surface_Source_Metal {
        layer = metalLayer,
      }
    }
}
