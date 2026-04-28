package fs_watcher

Watcher :: distinct rawptr

Event_Type_Flags :: bit_set[Event_Type]
Event_Type :: enum {
  Create,
  Move,
  Remove,
  Modify,
}
EVENT_TYPE_ALL :: Event_Type_Flags{ .Create, .Move, .Remove, .Modify }

Create_Flags :: bit_set[Create_Bits]
Create_Bits :: enum {
  Blocking,
}

Event :: union {
  Create_Event,
  Move_Event,
  Remove_Event,
  Modify_Event,
}

Create_Event :: struct {
  path: string,
}
Move_Event   :: struct {
  from: string,
  to:   string,
}
Remove_Event  :: struct {
  path: string,
}
Modify_Event :: struct {
  path: string,
}

create :: proc(types: Event_Type_Flags, path: string, flags := Create_Flags{}, allocator := context.allocator) -> Watcher {
  return _create(types, path, flags, allocator)
}

destroy :: proc(watcher: Watcher) {
  _destroy(watcher)
}

poll_events :: proc(watcher: Watcher, event: ^Event) -> bool {
  return _poll_events(watcher, event)
}
