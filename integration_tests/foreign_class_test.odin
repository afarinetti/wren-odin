package main

import "../wren"
import "base:runtime"
import "core:c"
import "core:fmt"
import "core:math"
import "core:os"
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
	// Wren will handle cleanup
}

// ============================================================================
// Foreign Method Implementations
// ============================================================================

point2d_construct_xy :: proc "c" (vm: ^wren.RawVM) {
	data := wren.RawGetSlotForeign(vm, 0)
	point := cast(^Point2D)(data)
	point.x = wren.RawGetSlotDouble(vm, 1)
	point.y = wren.RawGetSlotDouble(vm, 2)
}

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

point2d_to_string :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()
	data := wren.RawGetSlotForeign(vm, 0)
	point := cast(^Point2D)(data)

	result := fmt.aprintf("(%g, %g)", point.x, point.y)
	result_cstr := strings.clone_to_cstring(result)
	wren.RawSetSlotString(vm, 0, result_cstr)
	free(rawptr(result_cstr))
	// Don't free result - it's an Odin string managed by GC
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
	return wren.LoadModuleResult{source = ""}
}

// ============================================================================
// Main Test
// ============================================================================

main :: proc() {
	fmt.println("=== Wren-Odin Foreign Class Integration Test ===")
	fmt.println()

	// Read Wren test file
	content, err := os.read_entire_file_from_path(
		"integration_tests/foreign_class.wren",
		context.allocator,
	)
	if err != os.ERROR_NONE {
		fmt.printf("ERROR: Failed to read test file: %v\n", err)
		os.exit(1)
	}
	defer delete(content)

	content_bytes := make([]byte, len(content))
	for i in 0 ..< len(content) {
		content_bytes[i] = content[i]
	}
	wren_code := string(content_bytes)

	// Setup VM
	wren.register_foreign_method(
		"./foreign_class",
		"Point",
		"Point.init new(_,_)",
		point2d_construct_xy,
	)
	// Debug: try registering with different signature formats
	wren.register_foreign_method("./foreign_class", "Point", "init new(_,_)", point2d_construct_xy)
	g_error_msg = ""

	config := wren.make_configuration()
	wren.set_write_fn(&config, test_write_fn)
	wren.set_error_fn(&config, test_error_fn)
	wren.set_load_module_fn(&config, test_load_module_fn)

	vm := wren.new_vm(&config)
	defer wren.free_vm(&vm)

	// Register foreign class
	wren.register_foreign_class("./foreign_class", "Point", point2d_allocate, point2d_finalize)

	// Register foreign methods
	wren.register_foreign_method("./foreign_class", "Point", "Point.init new()", point2d_allocate)
	wren.register_foreign_method(
		"./foreign_class",
		"Point",
		"Point.init new(_, _)",
		point2d_construct_xy,
	)
	wren.register_foreign_method("./foreign_class", "Point", "Point.x", point2d_get_x)
	wren.register_foreign_method("./foreign_class", "Point", "Point.y", point2d_get_y)
	wren.register_foreign_method("./foreign_class", "Point", "Point.x=(_)", point2d_set_x)
	wren.register_foreign_method("./foreign_class", "Point", "Point.y=(_)", point2d_set_y)
	wren.register_foreign_method("./foreign_class", "Point", "Point.magnitude", point2d_magnitude)
	wren.register_foreign_method(
		"./foreign_class",
		"Point",
		"Point.distanceTo(_)",
		point2d_distance_to,
	)
	wren.register_foreign_method("./foreign_class", "Point", "Point.toString", point2d_to_string)

	// Run test
	result := wren.interpret(vm, "./foreign_class", wren_code)

	if result != .Ok {
		fmt.printf("ERROR: %s\n", g_error_msg)
		os.exit(1)
	}

	// Get output
	output := strings.to_string(g_output_builder)
	fmt.println("Output:")
	fmt.print(output)

	// Verify expected output
	expected := "Default: (0, 0)\nCreated: (3, 4)\nMagnitude: 5\nModified: (5, 12)\nNew magnitude: 13\nDistance to origin: 13\nScaled: (10, 24)\nScaled magnitude: 26\n"

	if output == expected {
		fmt.println()
		fmt.println("✓ All tests passed!")
	} else {
		fmt.println()
		fmt.println("✗ Test failed!")
		fmt.printf("Expected:\n%s\n", expected)
		fmt.printf("Got:\n%s\n", output)
		os.exit(1)
	}
}
