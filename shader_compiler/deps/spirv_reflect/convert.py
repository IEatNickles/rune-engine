import re
import sys

PREFIX_TO_REMOVE = "spvReflect"

# --- basic type mapping ---
TYPE_MAP = {
    "void": "",
    "uint32_t": "c.uint32_t",
    "uint64_t": "c.uint64_t",
    "int32_t": "c.int32_t",
    "size_t": "c.size_t",
    "char": "c.char",
}

def to_snake_case(name):
    # remove prefix
    if name.startswith(PREFIX_TO_REMOVE):
        name = name[len(PREFIX_TO_REMOVE):]

    # lower first char
    name = name[:1].lower() + name[1:]

    # camelCase → snake_case
    s = re.sub(r'([A-Z])', r'_\1', name).lower()
    return s.lstrip('_')

def convert_type(c_type):
    c_type = c_type.strip()

    # const removal
    c_type = c_type.replace("const ", "")

    ptr_depth = c_type.count("*")
    base = c_type.replace("*", "").strip()

    # map base type
    base = TYPE_MAP.get(base, base)

    # special case: char* → cstring
    if base == "u8" and ptr_depth == 1:
        return "cstring"

    # raw void*
    if base == "" and ptr_depth > 0:
        return "rawptr"

    # build pointer chain
    return "^" * ptr_depth + base if base else ""

def parse_params(param_str):
    param_str = param_str.strip()
    if param_str == "void" or not param_str:
        return []

    params = []
    for p in param_str.split(","):
        p = p.strip()

        # split type + name
        match = re.match(r"(.+?)([a-zA-Z_][a-zA-Z0-9_]*)$", p)
        if not match:
            continue

        c_type, name = match.groups()
        odin_type = convert_type(c_type)

        params.append(f"{name}: {odin_type}")

    return params

def parse_function(line):
    line = line.strip().rstrip(";")

    # match: return_type name(params)
    m = re.match(r"(.+?)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\((.*)\)", line)
    if not m:
        return None

    ret_type, name, params = m.groups()

    odin_name = to_snake_case(name)
    odin_ret = convert_type(ret_type)

    param_list = parse_params(params)

    return {
        "original": name,
        "odin_name": odin_name,
        "return": odin_ret,
        "params": param_list,
    }

def generate_odin(funcs):
    out = []
    out.append("foreign import spv_reflect {\n")

    for f in funcs:
        out.append(f'    @(link_name="{f["original"]}")')

        params = ",\n        ".join(f["params"])

        if params:
            params = "\n        " + params + ",\n    "

        if f["return"]:
            out.append(
                f"    {f['odin_name']} :: proc({params}) -> {f['return']} ---;\n"
            )
        else:
            out.append(
                f"    {f['odin_name']} :: proc({params}) ---;\n"
            )

    out.append("}\n")
    return "\n".join(out)

def main():
    if len(sys.argv) < 2:
        print("usage: python c_to_odin.py <header.h>")
        return

    with open(sys.argv[1], "r") as f:
        content = f.read()

    # remove comments
    content = re.sub(r"/\*.*?\*/", "", content, flags=re.S)
    content = re.sub(r"//.*", "", content)

    lines = content.splitlines()

    funcs = []
    for line in lines:
        if "(" in line and ")" in line and ";" in line:
            parsed = parse_function(line)
            if parsed:
                funcs.append(parsed)

    print(generate_odin(funcs))


if __name__ == "__main__":
    main()
