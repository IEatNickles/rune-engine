package rune_engine

import "core:fmt"
import os "core:os/os2"
import "core:strings"

Project :: struct {
	name: string,
	path: string,
}

create_project :: proc(name, path: string) -> Project {
	err := os.make_directory_all(path)
	if err != nil && err != .Exist do fmt.printfln("Error creating project path '{}': {}", path, err)
	err = os.make_directory(strings.concatenate({path, "/assets"}))
	if err != nil && err != .Exist do fmt.printfln("Error creating asset path '{}/assets': {}", path, err)
	proj_file: ^os.File
	proj_file, err = os.create(strings.concatenate({path, "/", name, ".rproj"}))
	defer os.close(proj_file)
	if err != nil do fmt.printfln("Error creating file '{}/{}.rproj': {}", path, name, err)

	return {}
}

open_project :: proc(path: string) -> Project {
	proj_file, err := os.open(path, {.Read, .Write})
	defer os.close(proj_file)
	if err == .Not_Exist {
		fmt.printfln("Project does not exist at '{}'", path)
		return {}
	}
	file_name := os.name(proj_file)
	name, ok := strings.substring_to(file_name, len(file_name) - 6)
	if !ok {
		fmt.printfln("Could not substring filename '{}'", file_name)
		return {}
	}
	return {name, path}
}
