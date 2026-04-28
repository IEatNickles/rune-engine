#+build windows
package fs_watcher

@(private)
_fs_watcher_create :: proc(types: Event_Type_Flags) -> Filesystem_Watcher {
  return nil
}
