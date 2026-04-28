package sandbox

// import "base:runtime"
// import "core:os"
//
// import "core:fmt"
//
// import "core:encoding/cbor"
// import "core:encoding/json"

// main :: proc {
//   info := runtime.type_info_base(type_info_of(GayLayer)).variant.(reflect.Type_Info_Struct)
//   name := reflect.struct_tag_get(reflect.Struct_Tag(info.tags[0]), "field")
//   fmt.println(name)
//
//   j, e := json.parse(#load("./test.json", []byte))
//
//   cbor_data, e2 := cbor.from_json(j)
//
//   cbor_file, err := os.create("test.cbor")
//   os.write(cbor_file, transmute([]byte)cbor_data)
//
//   j, e2 = cbor.to_json(cbor_data)
//   d, e3 := json.marshal(j, json.Marshal_Options{pretty = true, spaces = 2, use_spaces = true})
//   fmt.println(string(d))
// }
