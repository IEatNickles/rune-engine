#+build linux
package fs_watcher

import "core:mem"
import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/linux"

Watch_Item :: struct {
  wd:   linux.Wd,
  path: string,
}

Watcher_Linux :: struct {
  allocator:  mem.Allocator,
  descriptor: linux.Fd,
  watches:    [dynamic]Watch_Item,
  flags:      linux.Inotify_Event_Mask,
}

@(private="file")
add :: proc(watcher: ^Watcher_Linux, path: string) {
  c_path := strings.clone_to_cstring(path)
  wd, err := linux.inotify_add_watch(watcher.descriptor, c_path, watcher.flags)
  if err != nil do fmt.panicf("{}", err)
  append(&watcher.watches, Watch_Item { wd, path })
}

@(private="file")
remove :: proc(watcher: ^Watcher_Linux, wd: linux.Wd) {
  for w, i in watcher.watches {
    if w.wd == wd {
      linux.inotify_rm_watch(watcher.descriptor, w.wd)
      unordered_remove(&watcher.watches, i)
      break
    }
  }
}

@(private="file")
add_recursive :: proc(watcher: ^Watcher_Linux, path: string) {
  add(watcher, path)
  dir, err := os.open(path)
  fmt.assertf(err == nil, "{}", err)
  defer os.close(dir)
  dirs, err2 := os.read_all_directory(dir, context.allocator)
  fmt.assertf(err2 == nil, "{}", err2)
  defer delete(dirs)
  for d in dirs {
    if d.type != .Directory do continue
    add_recursive(watcher, d.fullpath)
  }
}

@(private)
_create :: proc(types: Event_Type_Flags, path: string, flags: Create_Flags, allocator: mem.Allocator) -> Watcher {
  init_flags: linux.Inotify_Init_Flags
  if .Blocking not_in flags do init_flags |= { .NONBLOCK }
  watcher := new(Watcher_Linux)
  err: linux.Errno
  watcher.descriptor, err = linux.inotify_init1(init_flags)
  if err != nil do fmt.panicf("{}", err)
  watcher.allocator = allocator
  watcher.watches = make([dynamic]Watch_Item, 0, 16, watcher.allocator)
  if .Create in types do watcher.flags |= { .CREATE }
  if .Remove in types do watcher.flags |= { .DELETE }
  if .Move   in types do watcher.flags |= { .MOVED_TO, .MOVED_FROM }
  if .Modify in types do watcher.flags |= { .MODIFY }
  watcher.flags |= { .DELETE_SELF }
  add_recursive(watcher, path)
  return auto_cast watcher
}

@(private)
_destroy :: proc(watcher: Watcher) {
  watcher := cast(^Watcher_Linux)watcher
  linux.close(watcher.descriptor)
  delete(watcher.watches)
}

@(private="file")
get_wd_path :: proc(watcher: ^Watcher_Linux, wd: linux.Wd) -> string {
  for w in watcher.watches {
    if w.wd == wd do return w.path
  }
  return ""
}

@(private="file")
get_full_path :: proc(watcher: ^Watcher_Linux, wd: linux.Wd, name: string) -> (res: string) {
  watch_path := get_wd_path(watcher, wd)
  res, _ = os.join_path({watch_path, name}, watcher.allocator)
  return
}

@(private="file")
event_queue: queue.Queue(Event)

@(private)
_poll_events :: proc(watcher: Watcher, event: ^Event) -> bool {
  watcher := cast(^Watcher_Linux)watcher
  move_src:    string
  move_cookie: u32
  for {
    buf := make([]u8, 4096)
    defer delete(buf)
    bytes_read, err := linux.read(watcher.descriptor, buf)
    // if err != nil do fmt.panicf("{}", err)
    if bytes_read <= 0 do break

    for i := 0; i < bytes_read; {
      ev := cast(^linux.Inotify_Event)raw_data(buf)
      name_ptr := cast([^]u8)(uintptr(ev) + size_of(linux.Inotify_Event))
      name := string(name_ptr[:ev.len - 1])
      is_dir         := .ISDIR      in ev.mask
      is_create      := .CREATE     in ev.mask
      is_delete      := .DELETE     in ev.mask
      is_modify      := .MODIFY     in ev.mask
      is_moved_to    := .MOVED_TO   in ev.mask
      is_moved_from  := .MOVED_FROM in ev.mask
      is_delete_self := .DELETE     in ev.mask

      if is_dir {
        switch {
        case is_create:
          path := get_full_path(watcher, ev.wd, name)
          add(watcher, path)
          queue.enqueue(&event_queue, Create_Event{path})
        case is_delete:
          queue.enqueue(&event_queue, Remove_Event{get_full_path(watcher, ev.wd, name)})
        case is_delete_self:
          remove(watcher, ev.wd)
        }
      } else {
        switch {
        case is_create:
          queue.enqueue(&event_queue, Create_Event{get_full_path(watcher, ev.wd, name)})
        case is_delete:
          queue.enqueue(&event_queue, Remove_Event{get_full_path(watcher, ev.wd, name)})
        case is_modify:
          queue.enqueue(&event_queue, Modify_Event{get_full_path(watcher, ev.wd, name)})
        case is_moved_from:
          if len(move_src) != 0 {
            queue.enqueue(&event_queue, Move_Event{get_full_path(watcher, ev.wd, name), ""})
            move_src = ""
          }
          move_src = get_full_path(watcher, ev.wd, name)
          move_cookie = ev.cookie
        case is_moved_to:
          if len(move_src) > 0 && ev.cookie == move_cookie {
            queue.enqueue(&event_queue, Move_Event{move_src, get_full_path(watcher, ev.wd, name)})
            move_src = ""
            move_cookie = 0
          } else if len(move_src) > 0 {
            queue.enqueue(&event_queue, Move_Event{move_src, ""})

            move_src = ""
            move_cookie = 0

            queue.enqueue(&event_queue, Move_Event{"", get_full_path(watcher, ev.wd, name)})
          } else {
            queue.enqueue(&event_queue, Move_Event{"", get_full_path(watcher, ev.wd, name)})
          }
        }
      }

      i += size_of(linux.Inotify_Event) + int(ev.len)
      buf = buf[i:]
    }
  }

  if len(move_src) > 0 {
    queue.enqueue(&event_queue, Move_Event{move_src, ""})
  }

  if event_queue.len > 0 {
    event^ = queue.dequeue(&event_queue)
    return true
  }
  return false
}
