package main

import "core:os"
import "core:path/filepath"
import "core:strings"

find_test_files :: proc(dir: string) -> []string {
	files: [dynamic]string

	// Walk directory recursively
	walk_dir(dir, &files)

	return files[:]
}

walk_dir :: proc(dir: string, files: ^[dynamic]string) {
	entries, err := os.read_all_directory_by_path(dir, context.allocator)
	if err != os.ERROR_NONE {
		return
	}
	defer delete(entries)

	for entry in entries {
		full_path, join_err := filepath.join({dir, entry.name}, context.allocator)
		if join_err != nil {
			continue
		}

		if entry.type == .Directory {
			walk_dir(full_path, files)
		} else if strings.has_suffix(entry.name, ".wren") {
			append(files, full_path)
		}
	}
}
