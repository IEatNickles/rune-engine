package editor

import "core:sys/linux"
import "core:mem"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"

import fs_watcher "filesystem_watcher"

import imgui "deps/odin-imgui"

asset_infos: [Asset_Type]map[string]Asset_Create_Info

filesystem_browser: struct {
  root_directory: Directory
}

File :: struct {
  name:      string,
  path:      string,
  extension: string,
}

Directory :: struct {
  name:           string,
  path:           string,
  files:          [dynamic]File,
  subdirectories: [dynamic]Directory,
}

fw: linux.Fd
wd: linux.Wd

watcher: fs_watcher.Watcher

filesytem_browser_init :: proc(path: string) {
  watcher = fs_watcher.create(fs_watcher.EVENT_TYPE_ALL, path)

  path, _ := os.get_absolute_path(path, context.allocator)
  filesystem_browser.root_directory.path = path
  init_directory(&filesystem_browser.root_directory, context.temp_allocator)
  free_all(context.temp_allocator)
}

fs_browser_destroy :: proc() {
  fs_watcher.destroy(watcher)
}

refresh_filesystem :: proc() {
  clear(&filesystem_browser.root_directory.subdirectories)
  clear(&filesystem_browser.root_directory.files)
  init_directory(&filesystem_browser.root_directory, context.temp_allocator)
  free_all(context.temp_allocator)
}

import_assets :: proc() {
  
}

filesytem_browser :: proc() {
  ev: fs_watcher.Event
  for fs_watcher.poll_events(watcher, &ev) {
    switch e in ev {
    case fs_watcher.Create_Event: fmt.printfln("created file: {}", e.path)
    case fs_watcher.Move_Event: fmt.printfln("moved file: {}, to: {}", e.from, e.to)
    case fs_watcher.Remove_Event: fmt.printfln("removed file: {}", e.path)
    case fs_watcher.Modify_Event: fmt.printfln("modified file: {}", e.path)
    }
  }

  imgui.begin("Assets")
  if imgui.button("refresh") {
    refresh_filesystem()
  }
  draw_directory(filesystem_browser.root_directory, true)
  imgui.end()
}

print_directory :: proc(dir: Directory, indent := 0) {
  if indent > 0 {
    for i in 0..<indent-1 do fmt.print("|  ")
    fmt.print("|- ")
  }
  fmt.printfln("[36m{}/[0m", dir.name)
  for sub in dir.subdirectories {
    print_directory(sub, indent + 1)
  }
  for file in dir.files {
    for i in 0..<indent do fmt.print("|  ")
    fmt.print("|- ")
    fmt.println(file.name)
  }
}

init_directory :: proc(dir: ^Directory, allocator: mem.Allocator) {
  _, dir.name = os.split_path(dir.path)
  infos, _ := os.read_all_directory_by_path(dir.path, allocator)
  for info in infos {
    if info.type == .Directory {
      sub: Directory
      sub.path = strings.clone(info.fullpath)
      _, sub.name = os.split_path(sub.path)
      init_directory(&sub, allocator)
      append(&dir.subdirectories, sub)
    } else {
      file: File
      file.path = strings.clone(info.fullpath)
      _, file.name = os.split_path(file.path)
      file.extension = os.ext(file.name)
      if file.extension == ".asset" do continue
      append(&dir.files, file)
    }
  }
  slice.sort_by_cmp(dir.subdirectories[:], proc(i, j: Directory) -> slice.Ordering {
    return cast(slice.Ordering)strings.compare(i.name, j.name)
  })
  slice.sort_by_cmp(dir.files[:], proc(i, j: File) -> slice.Ordering {
    return cast(slice.Ordering)strings.compare(i.name, j.name)
  })
}

draw_directory :: proc(dir: Directory, root := false) {
  c_name := strings.clone_to_cstring(dir.name)
  flags := imgui.Tree_Node_Flags{.Span_Avail_Width}
  if root do flags |= { .Framed, .Default_Open }
  if imgui.tree_node_ex(c_name, flags) {
    for sub in dir.subdirectories {
      draw_directory(sub)
    }
    for file in dir.files {
      c_name := strings.clone_to_cstring(file.name)
      if imgui.tree_node_ex(c_name, {.Leaf, .Span_Avail_Width}) {
        imgui.tree_pop()
      }
    }
    imgui.tree_pop()
  }
}
