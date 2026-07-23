package main

import "core:os"
import "core:path/filepath"
import "core:strings"

find_test_files :: proc(dir: string) -> []string {
	regular: [dynamic]string
	benchmarks: [dynamic]string

	// Walk directory recursively, separating benchmarks
	walk_dir(dir, &regular, &benchmarks)

	// Append benchmarks at the end
	for b in benchmarks {
		append(&regular, b)
	}

	return regular[:]
}

walk_dir :: proc(dir: string, files: ^[dynamic]string, benchmarks: ^[dynamic]string) {
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
			walk_dir(full_path, files, benchmarks)
		} else if strings.has_suffix(entry.name, ".wren") {
			// Separate benchmark tests to run last
			if strings.has_prefix(dir, "vendor/wren/test/benchmark") ||
			   strings.has_prefix(full_path, "vendor/wren/test/benchmark") {
				append(benchmarks, full_path)
			} else {
				append(files, full_path)
			}
		}
	}
}
