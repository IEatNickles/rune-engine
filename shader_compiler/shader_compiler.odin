package shader_compiler

import "core:slice"
import "core:encoding/json"
import "core:flags"
import "core:fmt"
import "core:strings"
import "core:os"

import "deps/glslang"
import spvc "deps/spirv_cross"
import spvr "deps/spirv_reflect"

Args :: struct {
  input_file: string `args:"pos=0,name=in,required" usage:"the input file"`,
  output_file: string `args:"name=out,required" usage:"the output file"`,
}
args: Args

main :: proc() {
  err := flags.parse(&args, os.args[1:])
  if err != nil {
    switch e in err {
    case flags.Parse_Error:      fmt.panicf("failed to parse args({}): {}", e.reason, e.message)
    case flags.Open_File_Error:  fmt.panicf("failed to open file '{}' ({})", e.filename, e.errno)
    case flags.Help_Request:     flags.write_usage(os.to_writer(os.stdout), Args)
    case flags.Validation_Error: fmt.panicf("failed to validate args: {}", e.message)
    }
  }

  source, ferr := os.read_entire_file(args.input_file, context.allocator)
  fmt.assertf(ferr == nil, "failed to read file '{}': {}", args.input_file, ferr)
  compile_shader(string(source), args.output_file)
}

read_shader_func :: proc(version: string, lines: []string) -> string {
  builder := strings.builder_make()
  fmt.sbprintln(&builder, version)
  for l in lines {
    fmt.sbprintln(&builder, l)
  }
  return strings.to_string(builder)
}

Uniform_Type :: enum {
  Float,
  Vec2,
  Vec3,
  Vec4,
  Int,
  IVec2,
  IVec3,
  IVec4,
  UInt,
  UVec2,
  UVec3,
  UVec4,
  Mat2,
  Mat3,
  Mat4,
}
Uniform :: struct {
  offset:   int,
  type:     Uniform_Type,
}
Uniform_Block :: struct {
  identifier: string,
  size:    int,
  members: map[string]Uniform,
}

Spirv_Binary :: struct {
  code:           []u32,
  uniform_blocks: map[string]Uniform_Block,
}

glsl_to_spirv :: proc(source: string, stage: glslang.Stage) -> (binary: []u32) {
  input := glslang.Input{
    code = strings.clone_to_cstring(source),
    language = .GLSL,
    stage = stage,
    client = .VULKAN,
    client_version = .VULKAN_1_0,
    default_profile = { .NO_PROFILE },
    default_version = 100,
    target_language = .SPV,
    target_language_version = .SPV_1_0,
    force_default_version_and_profile = false,
    forward_compatible = false,
    messages = nil,
    resource = glslang.default_resource(),
  }
  sh := glslang.shader_create(input)
  glslang.shader_set_options(sh, { .AUTO_MAP_LOCATIONS, .AUTO_MAP_BINDINGS })
  assert(sh != nil)
  if !glslang.shader_preprocess(sh, &input) {
    fmt.printfln("failed to preprocess GLSL({}):", stage)
    fmt.println(glslang.shader_get_info_log(sh))
    fmt.println(glslang.shader_get_info_debug_log(sh))
    fmt.println(input.code)
    assert(false)
  }
  if !glslang.shader_parse(sh, input) {
    fmt.printfln("failed to parse GLSL({}):", stage)
    fmt.println(glslang.shader_get_info_log(sh))
    fmt.println(glslang.shader_get_info_debug_log(sh))
    fmt.println(glslang.shader_get_preprocessed_code(sh))
    assert(false)
  }
  prog := glslang.program_create()
  glslang.program_add_shader(prog, sh)
  if !glslang.program_link(prog, {.VULKAN_RULES, .SPV_RULES}) {
    fmt.println("failed to link program:")
    fmt.println(glslang.program_get_info_log(prog))
    fmt.println(glslang.program_get_info_debug_log(prog))
    assert(false)
  }
  if !glslang.program_map_io(prog) {
    fmt.println("failed to map program io:")
    fmt.println(glslang.program_get_info_log(prog))
    fmt.println(glslang.program_get_info_debug_log(prog))
    assert(false)
  }
  glslang.program_SPIRV_generate(prog, stage)
  binary = make([]u32, glslang.program_SPIRV_get_size(prog))
  glslang.program_SPIRV_get(prog, raw_data(binary))

  if spv_messages := glslang.program_SPIRV_get_messages(prog); spv_messages != nil {
    fmt.printfln("error in SPIRV: {}", spv_messages)
  }

  glslang.program_delete(prog)
  glslang.shader_delete(sh)
  return
}

Program :: struct {
  name: string,
  vs:   string,
  fs:   string,
  cs:   string,
}

Image_Type :: enum {
  D1,
  D2,
  D3,
  Cube,
}

Sampler :: struct { }
Image_Data :: struct {
  dim:             Image_Type,
  is_array:        bool,
  is_depth:        bool,
  is_multisampled: bool,
}
Combined_Image_Sampler :: struct {
  using img: Image_Data,
}
Storage_Image :: struct {
  using img: Image_Data,
}
Sampled_Image :: struct {
  using img: Image_Data,
}

Shader_Member :: struct {
  name:   string,
  index:  int,
  size:   int,
  offset: int,
  type:   Uniform_Type,
}

Uniform_Buffer :: struct {
  members: map[string]Shader_Member,
}

Storage_Buffer :: struct { }

Descriptor_Binding :: struct {
  name:    string,
  id:      u32,
  binding: u32,
  type: union {
    Sampler,
    Combined_Image_Sampler,
    Sampled_Image,
    Storage_Image,
    Uniform_Buffer,
    Storage_Buffer,
  }
}

Push_Constant :: struct {
  name:    string,
  size:    int,
  offset:  int,
  members: map[string]Shader_Member,
}

Shader_Reflection_Data :: struct {
  descriptor_bindings: map[string]Descriptor_Binding,
  push_constants:      map[string]Push_Constant,
}


compile_shader :: proc(source: string, output_path: string) {
  lines := strings.split_lines(source)
  version := "#version 450"
  in_vs, in_fs, in_cs: bool
  vs_map: map[string]string
  fs_map: map[string]string
  cs_map: map[string]string
  programs: map[string]Program
  shader_name: string
  start: int
  i := 0
  for i < len(lines) {
    line := lines[i]
    if len(line) == 0 {
      i += 1
      continue
    }
    if line[0] == '@' {
      tokens := strings.split(line, " ")
      switch tokens[0] {
      case "@vs":
        assert(!in_vs && !in_fs && !in_cs)
        shader_name = tokens[1]
        start = i + 1
        in_vs = true
      case "@fs":
        assert(!in_vs && !in_fs && !in_cs)
        shader_name = tokens[1]
        start = i + 1
        in_fs = true
      case "@cs":
        assert(!in_vs && !in_fs && !in_cs)
        shader_name = tokens[1]
        start = i + 1
        in_cs = true
      case "@program":
        name := tokens[1]
        programs[name] = {
          vs = tokens[2],
          fs = tokens[3],
        }
      case "@end":
        if in_vs {
          vs_map[shader_name] = read_shader_func(version, lines[start:i])
          in_vs = false
        } else if in_fs {
          fs_map[shader_name] = read_shader_func(version, lines[start:i])
          in_fs = false
        } else if in_cs {
          cs_map[shader_name] = read_shader_func(version, lines[start:i])
          in_cs = false
        }
      }
    }
    i += 1
  }

  file, _ := os.open(output_path, {.Write, .Create, .Trunc})
  os.write_string(file, "package rune_engine\n\n")

  write_bytecode :: proc(file: ^os.File, bytecode: []u8) {
    for b, i in bytecode {
      if i % 24 == 0 do os.write_rune(file, '\n')
      os.write_string(file, fmt.tprintf("%#02x,", b))
    }
  }
  write_shader :: proc(file: ^os.File, name: string, source: string, stage: glslang.Stage) {
    binary := glsl_to_spirv(source, stage)
    sh: spvr.ShaderModule
    spvr.create_shader_module(len(binary) * 4, raw_data(binary), &sh)

    reflection_data: Shader_Reflection_Data
    for i in 0..<sh.descriptor_binding_count {
      desc := sh.descriptor_bindings[i]
      name: string
      if desc.name != "" do name = strings.clone_from_cstring(desc.name)
      else do name = fmt.aprintf("_{}", desc.spirv_id)
      value: Descriptor_Binding
      value.binding = desc.binding
      value.name = name
      value.id = desc.spirv_id
      #partial switch desc.descriptor_type {
      case .SAMPLER: value.type = Sampler{}
      case .COMBINED_IMAGE_SAMPLER:
        dim: Image_Type
        #partial switch desc.image.dim {
        case .D1: dim = .D1
        case .D2: dim = .D2
        case .D3: dim = .D3
        case .Cube: dim = .Cube
        case: unreachable()
        }
        value.type = Combined_Image_Sampler{
          img = Image_Data {
            dim = dim,
            is_array = desc.image.arrayed == 1,
            is_depth = desc.image.depth == 1,
            is_multisampled = desc.image.ms == 1,
          }
        }
      case .SAMPLED_IMAGE:
        dim: Image_Type
        #partial switch desc.image.dim {
        case .D1: dim = .D1
        case .D2: dim = .D2
        case .D3: dim = .D3
        case .Cube: dim = .Cube
        case: unreachable()
        }
        value.type = Sampled_Image{
          img = Image_Data {
            dim = dim,
            is_array = desc.image.arrayed == 1,
            is_depth = desc.image.depth == 1,
            is_multisampled = desc.image.ms == 1,
          }
        }
      case .STORAGE_IMAGE:
        dim: Image_Type
        fmt.println(desc.image)
        #partial switch desc.image.dim {
        case .D1: dim = .D1
        case .D2: dim = .D2
        case .D3: dim = .D3
        case .Cube: dim = .Cube
        case: unreachable()
        }
        value.type = Storage_Image{
          img = Image_Data {
            dim = dim,
            is_array = desc.image.arrayed == 1,
            is_depth = desc.image.depth == 1,
            is_multisampled = desc.image.ms == 1,
          }
        }
      case .UNIFORM_BUFFER:
        ub: Uniform_Buffer
        for i in 0..<desc.block.member_count {
          m := desc.block.members[i]
          member := block_varaible_to_shader_member(m)
          map_insert(&ub.members, member.name, member)
        }
        value.type = ub
      case .STORAGE_BUFFER: value.type = Storage_Buffer{}
      case: unreachable()
      }
      map_insert(&reflection_data.descriptor_bindings, name, value)
    }
    for i in 0..<sh.push_constant_block_count {
      p := sh.push_constant_blocks[i]
      name: string
      if p.name != "" do name = strings.clone_from(p.name)
      else do name = fmt.aprintf("_{}", p.spirv_id)
      pc: Push_Constant
      pc.name = name
      pc.size = int(p.size)
      pc.offset = int(p.offset)
      for i in 0..<p.member_count {
        m := p.members[i]
        member := block_varaible_to_shader_member(m)
        map_insert(&pc.members, member.name, member)
      }
      map_insert(&reflection_data.push_constants, name, pc)
    }

    _ = os.write_entire_file(fmt.tprintf("{}_spirv", name), slice.reinterpret([]u8, binary))
    os.write_string(file, fmt.tprintfln("// ============= {} shader sources ====================", name))

    // SPIRV
    os.write_string(file, fmt.tprintf("{}_spirv := [{}]u8 {{", name, len(binary) * 4))
    write_bytecode(file, slice.reinterpret([]u8, binary))
    os.write_string(file, "\n}\n")

    ctx: spvc.Context
    spvc.context_create(&ctx)
    defer spvc.context_destroy(ctx)
    ir: spvc.Parsed_Ir
    spvc.context_parse_spirv(ctx, raw_data(binary), len(binary), &ir)

    // JSON (for reflection stuff)
    // uniform_blocks: map[string]Uniform_Block
    // {
    //   json_compiler: spvc.Compiler
    //   spvc.context_create_compiler(ctx, .JSON, ir, .COPY, &json_compiler)
    //   src: cstring
    //   spvc.compiler_compile(json_compiler, &src)
    //   j, _ := json.parse(transmute([]u8)strings.clone_from_cstring(src))
    //
    //   root := j.(json.Object)
    //   entry_points, has_entry := root["entryPoints"].(json.Array)
    //   inputs, has_inputs := root["inputs"].(json.Array)
    //   outputs, has_outputs := root["outputs"].(json.Array)
    //   ubos, has_ubos := root["ubos"].(json.Array)
    //   types, has_types := root["types"].(json.Object)
    //
    //   // fmt.println(root)
    //   for ub_data in ubos {
    //     ub_data := ub_data.(json.Object)
    //     ub: Uniform_Block
    //     ub.size = auto_cast ub_data["block_size"].(json.Float)
    //     type := types[ub_data["type"].(json.String)].(json.Object)
    //     for m in type["members"].(json.Array) {
    //       m := m.(json.Object)
    //       u_type: Uniform_Type
    //       switch m["type"].(json.String) {
    //       case "float": u_type = .Float
    //       case "vec2": u_type = .Vec2
    //       case "vec3": u_type = .Vec3
    //       case "vec4": u_type = .Vec4
    //       case "int": u_type = .Int
    //       case "ivec2": u_type = .IVec2
    //       case "ivec3": u_type = .IVec3
    //       case "ivec4": u_type = .IVec4
    //       case "unsigned int": u_type = .UInt
    //       case "uvec2": u_type = .UVec2
    //       case "uvec3": u_type = .UVec3
    //       case "uvec4": u_type = .UVec4
    //       case "mat2": u_type = .Mat2
    //       case "mat3": u_type = .Mat3
    //       case "mat4": u_type = .Mat4
    //       }
    //       ub.members[m["name"].(json.String)] = {
    //         offset = auto_cast m["offset"].(json.Float),
    //         type = u_type,
    //       }
    //     }
    //     uniform_blocks[ub_data["name"].(json.String)] = ub
    //   }
    // }

    // GLSL
    glsl_compiler: spvc.Compiler
    glsl_opt: spvc.Compiler_Options
    spvc.context_create_compiler(ctx, .GLSL, ir, .COPY, &glsl_compiler)
    spvc.compiler_create_compiler_options(glsl_compiler, &glsl_opt)
    spvc.compiler_options_set_uint(glsl_opt, .GLSL_VERSION, 330)
    // spvc.compiler_options_set_bool(glsl_opt, .GLSL_EMIT_UNIFORM_BUFFER_AS_PLAIN_UNIFORMS, true)
    spvc.compiler_install_compiler_options(glsl_compiler, glsl_opt)
    glsl_source: cstring
    spvc.compiler_compile(glsl_compiler, &glsl_source)
    res: spvc.Resources
    assert(spvc.compiler_create_shader_resources(glsl_compiler, &res) == .SUCCESS)
    resource_size: int
    resources: [^]spvc.Reflected_Resource
    assert(spvc.resources_get_resource_list_for_type(res, .UNIFORM_BUFFER, &resources, &resource_size) == .SUCCESS)
    // for i in 0..<resource_size {
    //   res := resources[i]
    //   ub := &uniform_blocks[strings.clone_from_cstring(res.name)]
    //   ub.identifier = fmt.aprintf("_%d", res.id)
    // }
    os.write_string(file, fmt.tprintf("\n/*\n{}*/\n", glsl_source))
    os.write_string(file, fmt.tprintf("{}_glsl := [{}]u8 {{", name, len(glsl_source)))
    write_bytecode(file, transmute([]u8)strings.clone_from_cstring(glsl_source))
    os.write_string(file, "\n}\n")

    // HLSL
    hlsl_compiler: spvc.Compiler
    spvc.context_create_compiler(ctx, .HLSL, ir, .COPY, &hlsl_compiler)
    hlsl_source: cstring
    spvc.compiler_compile(hlsl_compiler, &hlsl_source)
    os.write_string(file, fmt.tprintf("\n/*\n{}*/\n", hlsl_source))
    os.write_string(file, fmt.tprintf("{}_hlsl := [{}]u8 {{", name, len(hlsl_source)))
    write_bytecode(file, transmute([]u8)strings.clone_from_cstring(hlsl_source))
    os.write_string(file, "\n}\n")

    // MSL
    msl_compiler: spvc.Compiler
    spvc.context_create_compiler(ctx, .MSL, ir, .COPY, &msl_compiler)
    msl_source: cstring
    spvc.compiler_compile(msl_compiler, &msl_source)
    os.write_string(file, fmt.tprintf("\n/*\n{}*/\n", msl_source))
    os.write_string(file, fmt.tprintf("{}_msl := [{}]u8 {{", name, len(msl_source)))
    write_bytecode(file, transmute([]u8)strings.clone_from_cstring(msl_source))
    os.write_string(file, "\n}\n\n")

    // TODO:
    //  This is a crime against humanity
    //  ...actually, maybe not?
    // json_out, _ := json.marshal(uniform_blocks)
    json_out, _ := json.marshal(reflection_data)
    os.write_string(file, fmt.tprintf("{}_uniform_blocks := `{}`\n", name, string(json_out)))

    os.write_string(file, "// ========================================================\n")
    free_all(context.temp_allocator)
  }
  glslang.initialize_process()
  for name, code in vs_map do write_shader(file, name, code, .VERTEX)
  os.write_rune(file, '\n')
  for name, code in fs_map do write_shader(file, name, code, .FRAGMENT)
  os.write_rune(file, '\n')
  for name, code in cs_map do write_shader(file, name, code, .COMPUTE)
  os.close(file)
  glslang.finalize_process()

  // ctx: spvc.Context
  // ir: spvc.Parsed_Ir
  // spvc.context_create(&ctx)
  // spvc.context_parse_spirv(ctx, raw_data(words_vs), len(words_vs), &ir)
  //
  // compiler: spvc.Compiler
  // spvc.context_create_compiler(ctx, .GLSL, ir, .TAKE_OWNERSHIP, &compiler)
  // opt: spvc.Compiler_Options
  // spvc.compiler_create_compiler_options(compiler, &opt)
  // spvc.compiler_options_set_uint(opt, .GLSL_VERSION, 330)
  // source: cstring
  // spvc.compiler_compile(compiler, &source)
  // fmt.println(source)
  // spvc.context_destroy(ctx)
}


block_varaible_to_shader_member :: proc(m: spvr.BlockVariable) -> (member: Shader_Member) {
  name: string
  if m.name != "" do name = strings.clone_from(m.name)
  else do name = fmt.aprintf("_{}", m.spirv_id)
  member.name = name
  member.size = int(m.size)
  member.offset = int(m.offset)
  if m.type_description != nil {
    flags := m.type_description.type_flags
    switch {
    case .MATRIX in m.type_description.type_flags:
      assert(m.type_description.traits.numeric._matrix.column_count == m.type_description.traits.numeric._matrix.row_count, "only square matrices are supported")
      switch m.type_description.traits.numeric._matrix.column_count {
      case 2: member.type = .Mat2
      case 3: member.type = .Mat3
      case 4: member.type = .Mat4
      }
    case .VECTOR in m.type_description.type_flags:
      switch {
      case .FLOAT in flags:
        switch m.type_description.traits.numeric.vector.component_count {
        case 2: member.type = .Vec2
        case 3: member.type = .Vec3
        case 4: member.type = .Vec4
        }
      case .INT in flags:
        if m.type_description.traits.numeric.scalar.signedness == 1 {
          switch m.type_description.traits.numeric.vector.component_count {
          case 2: member.type = .IVec2
          case 3: member.type = .IVec3
          case 4: member.type = .IVec4
          }
        } else {
          switch m.type_description.traits.numeric.vector.component_count {
          case 2: member.type = .UVec2
          case 3: member.type = .UVec3
          case 4: member.type = .UVec4
          }
        }
      }
    case .FLOAT  in m.type_description.type_flags: member.type = .Float
    case .INT    in m.type_description.type_flags:
      if m.type_description.traits.numeric.scalar.signedness == 1 do member.type = .Int
      else do member.type = .UInt
    }
  }
  return
}
