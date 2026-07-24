package main

import "../wren"
import "core:c"
import "core:fmt"
import "core:math"
import "core:os"
import "core:path/filepath"
import "core:strings"

// ============================================================================
// Odin Struct for Wren Interop
// ============================================================================

Point2D :: struct {
	x: f64,
	y: f64,
}

// ============================================================================
// Foreign Class Callbacks
// ============================================================================
point2d_allocate :: proc "c" (vm: ^wren.RawVM) {
	data := wren.RawSetSlotNewForeign(vm, 0, 0, c.size_t(size_of(Point2D)))
	point := cast(^Point2D)(data)
	point.x = 0
	point.y = 0
}

point2d_finalize :: proc "c" (data: rawptr) {
	// Wren will handle cleanup - no need to free manually
}

// ============================================================================
// Foreign Method Implementations
// ============================================================================

point2d_get_x :: proc "c" (vm: ^wren.RawVM) {
	data := wren.RawGetSlotForeign(vm, 0)
	point := cast(^Point2D)(data)
	wren.RawSetSlotDouble(vm, 0, point.x)
}

point2d_get_y :: proc "c" (vm: ^wren.RawVM) {
	data := wren.RawGetSlotForeign(vm, 0)
	point := cast(^Point2D)(data)
	wren.RawSetSlotDouble(vm, 0, point.y)
}

point2d_set_x :: proc "c" (vm: ^wren.RawVM) {
	data := wren.RawGetSlotForeign(vm, 0)
	point := cast(^Point2D)(data)
	point.x = wren.RawGetSlotDouble(vm, 1)
}

point2d_set_y :: proc "c" (vm: ^wren.RawVM) {
	data := wren.RawGetSlotForeign(vm, 0)
	point := cast(^Point2D)(data)
	point.y = wren.RawGetSlotDouble(vm, 1)
}

point2d_magnitude :: proc "c" (vm: ^wren.RawVM) {
	data := wren.RawGetSlotForeign(vm, 0)
	point := cast(^Point2D)(data)
	mag := math.sqrt(point.x * point.x + point.y * point.y)
	wren.RawSetSlotDouble(vm, 0, mag)
}

point2d_distance_to :: proc "c" (vm: ^wren.RawVM) {
	data := wren.RawGetSlotForeign(vm, 0)
	point1 := cast(^Point2D)(data)

	other_data := wren.RawGetSlotForeign(vm, 1)
	point2 := cast(^Point2D)(other_data)

	dx := point1.x - point2.x
	dy := point1.y - point2.y
	dist := math.sqrt(dx * dx + dy * dy)
	wren.RawSetSlotDouble(vm, 0, dist)
}

// ============================================================================
// Test Infrastructure
// ============================================================================

g_output_builder: strings.Builder
g_error_msg: string

test_write_fn :: proc(vm: wren.VM, text: string) {
	strings.write_string(&g_output_builder, text)
}

test_error_fn :: proc(
	vm: wren.VM,
	error_type: wren.ErrorType,
	module: string,
	line: int,
	message: string,
) {
	if error_type == .Runtime || error_type == .Compile {
		g_error_msg = message
	}
}

test_load_module_fn :: proc(vm: wren.VM, name: string) -> wren.LoadModuleResult {
	if name == "meta" {
		return wren.LoadModuleResult{source = ""}
	}
	if name == "random" {
		return wren.LoadModuleResult{source = ""}
	}

	module_path := name
	if strings.has_prefix(module_path, "./") {
		module_path = module_path[2:]
	}
	path, path_err := strings.concatenate(
		{"integration_tests/", module_path, ".wren"},
		context.allocator,
	)
	if path_err != nil {
		return wren.LoadModuleResult{source = ""}
	}
	defer delete(path)

	content, content_err := os.read_entire_file_from_path(path, context.allocator)
	if content_err != os.ERROR_NONE {
		return wren.LoadModuleResult{source = ""}
	}
	defer delete(content)

	content_bytes := make([]byte, len(content))
	for i in 0 ..< len(content) {
		content_bytes[i] = content[i]
	}

	return wren.LoadModuleResult{source = string(content_bytes)}
}

register_integration_tests :: proc() {
	// Point2D foreign class
	wren.register_foreign_class("./struct_to_class", "Point", point2d_allocate, point2d_finalize)

	// Point2D foreign methods - constructors
	wren.register_foreign_method(
		"./struct_to_class",
		"Point",
		"Point.init new()",
		point2d_allocate,
	)
	wren.register_foreign_method(
		"./struct_to_class",
		"Point",
		"Point.init new(_, _)",
		point2d_construct_xy,
	)

	// Point2D foreign methods - getters and setters
	wren.register_foreign_method("./struct_to_class", "Point", "Point.x", point2d_get_x)
	wren.register_foreign_method("./struct_to_class", "Point", "Point.y", point2d_get_y)
	wren.register_foreign_method("./struct_to_class", "Point", "Point.x=(_)", point2d_set_x)
	wren.register_foreign_method("./struct_to_class", "Point", "Point.y=(_)", point2d_set_y)
	wren.register_foreign_method(
		"./struct_to_class",
		"Point",
		"Point.magnitude",
		point2d_magnitude,
	)
	wren.register_foreign_method(
		"./struct_to_class",
		"Point",
		"Point.distanceTo(_)",
		point2d_distance_to,
	)
}
point2d_construct_xy :: proc "c" (vm: ^wren.RawVM) {
	data := wren.RawGetSlotForeign(vm, 0)
	point := cast(^Point2D)(data)
	point.x = wren.RawGetSlotDouble(vm, 1)
	point.y = wren.RawGetSlotDouble(vm, 2)
}

// ============================================================================
// Test Runner
// ============================================================================

run_integration_test :: proc(file: string) -> bool {
	content, err := os.read_entire_file_from_path(file, context.allocator)
	if err != os.ERROR_NONE {
		fmt.printf("  ERROR: Failed to read %s\n", file)
		return false
	}

	content_bytes := make([]byte, len(content))
	for i in 0 ..< len(content) {
		content_bytes[i] = content[i]
	}
	delete(content)
	content_str := string(content_bytes)

	// Parse expectations
	expectation_list: [dynamic]string
	for line in strings.split(content_str, "\n") {
		if strings.has_prefix(line, "// expect: ") {
			expected := line[len("// expect: "):]
			append(&expectation_list, expected)
		}
	}

	// Setup VM
	strings.builder_destroy(&g_output_builder)
	strings.builder_init(&g_output_builder)
	g_error_msg = ""

	config := wren.make_configuration()
	wren.set_write_fn(&config, test_write_fn)
	wren.set_error_fn(&config, test_error_fn)
	wren.set_load_module_fn(&config, test_load_module_fn)

	vm := wren.new_vm(&config)
	defer wren.free_vm(&vm)

	// Register integration test bindings
	register_integration_tests()

	// Convert file path to module name
	module_name := file
	if strings.has_prefix(module_name, "integration_tests/") {
		module_name = module_name[len("integration_tests/"):]
	}
	if strings.has_suffix(module_name, ".wren") {
		module_name = module_name[:len(module_name) - 5]
	}
	if !strings.has_prefix(module_name, "./") {
		module_name = strings.concatenate({"./", module_name}, context.allocator)
	}

	// Run test
	interpret_result := wren.interpret(vm, module_name, content_str)

	if interpret_result != .Ok {
		fmt.printf("  ERROR: %s\n", g_error_msg)
		return false
	}

	// Check output
	actual_output := strings.to_string(g_output_builder)

	// Compare with expectations
	passed := true
	actual_lines := strings.split(actual_output, "\n")

	if len(actual_lines) != len(expectation_list) {
		fmt.printf(
			"  ERROR: Expected %d lines, got %d\n",
			len(expectation_list),
			len(actual_lines),
		)
		fmt.printf("  Actual output:\n%s\n", actual_output)
		return false
	}

	for i in 0 ..< len(expectation_list) {
		if actual_lines[i] != expectation_list[i] {
			fmt.printf("  ERROR: Line %d mismatch\n", i + 1)
			fmt.printf("    Expected: %s\n", expectation_list[i])
			fmt.printf("    Actual:   %s\n", actual_lines[i])
			passed = false
		}
	}

	return passed
}

find_integration_test_files :: proc(dir: string) -> [dynamic]string {
	files: [dynamic]string

	entries, err := os.read_all_directory_by_path(dir, context.allocator)
	if err != os.ERROR_NONE {
		fmt.printf("  ERROR: Failed to read directory %s: %v\n", dir, err)
		return files
	}
	defer delete(entries)

	fmt.printf("  Found %d entries in %s\n", len(entries), dir)

	for entry in entries {
		fmt.printf("    Entry: %s\n", entry.name)
		if strings.has_suffix(entry.name, ".wren") {
			full_path, join_err := filepath.join({dir, entry.name}, context.allocator)
			if join_err == nil {
				fmt.printf("      Adding: %s\n", full_path)
				append(&files, full_path)
				// Don't delete - the array now owns the string
			} else {
				fmt.printf("      Join error: %v\n", join_err)
			}
		}
	}

	fmt.printf("  Returning %d files\n", len(files))
	return files
}

main :: proc() {
	fmt.println("=== Wren-Odin Integration Tests ===")
	fmt.println()

	// Find all integration test files
	test_files := find_integration_test_files("integration_tests")

	fmt.printf("Found %d integration test files\n", len(test_files))
	fmt.println()

	passed := 0
	failed := 0

	for file in test_files {
		fmt.printf("Running %s...\n", file)
		if run_integration_test(file) {
			fmt.printf("  ✓ PASS\n")
			passed += 1
		} else {
			fmt.printf("   FAIL\n")
			failed += 1
		}
		fmt.println()
	}

	fmt.println()
	fmt.printf("Total:  %d\n", passed + failed)
	fmt.printf("Passed: %d\n", passed)
	fmt.printf("Failed: %d\n", failed)

	if failed > 0 {
		os.exit(1)
	}
}
