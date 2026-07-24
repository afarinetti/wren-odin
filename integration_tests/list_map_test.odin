package main

import "../wren"
import "core:c"
import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"

// ============================================================================
// Integration Test: List and Map Interop
// ============================================================================

// Create a list from Odin
create_list :: proc "c" (vm: ^wren.RawVM) {
	wren.RawSetSlotNewList(vm, 0)
	wren.RawEnsureSlots(vm, 2)

	for i in 0 ..< 5 {
		wren.RawSetSlotDouble(vm, 1, f64(i + 1))
		wren.RawInsertInList(vm, 0, c.int(i), 1)
	}
}

// Process a list from Wren (double each element)
process_list :: proc "c" (vm: ^wren.RawVM) {
	count := wren.RawGetListCount(vm, 1)
	wren.RawSetSlotNewList(vm, 0)
	wren.RawEnsureSlots(vm, 3)

	for i in 0 ..< int(count) {
		wren.RawGetListElement(vm, 1, c.int(i), 2)
		val := wren.RawGetSlotDouble(vm, 2)
		wren.RawSetSlotDouble(vm, 2, val * 2)
		wren.RawInsertInList(vm, 0, c.int(i), 2)
	}
}

// Create a map from Odin
create_map :: proc "c" (vm: ^wren.RawVM) {
	wren.RawSetSlotNewMap(vm, 0)
	wren.RawEnsureSlots(vm, 3)

	wren.RawSetSlotString(vm, 1, "one")
	wren.RawSetSlotDouble(vm, 2, 1.0)
	wren.RawSetMapValue(vm, 0, 1, 2)

	wren.RawSetSlotString(vm, 1, "two")
	wren.RawSetSlotDouble(vm, 2, 2.0)
	wren.RawSetMapValue(vm, 0, 1, 2)

	wren.RawSetSlotString(vm, 1, "three")
	wren.RawSetSlotDouble(vm, 2, 3.0)
	wren.RawSetMapValue(vm, 0, 1, 2)
}

// Get value from map
get_map_value :: proc "c" (vm: ^wren.RawVM) {
	wren.RawEnsureSlots(vm, 3)
	wren.RawSetSlotString(vm, 2, "two")
	wren.RawGetMapValue(vm, 1, 2, 0)
}

// Check if map contains key
map_contains_key :: proc "c" (vm: ^wren.RawVM) {
	wren.RawEnsureSlots(vm, 3)
	wren.RawSetSlotString(vm, 2, "three")
	result := wren.RawGetMapContainsKey(vm, 1, 2)
	wren.RawSetSlotBool(vm, 0, result)
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
	fmt.println("=== Wren-Odin List/Map Interop Test ===")
	fmt.println()

	// Setup VM
	strings.builder_init(&g_output_builder)
	g_error_msg = ""

	config := wren.make_configuration()
	wren.set_write_fn(&config, test_write_fn)
	wren.set_error_fn(&config, test_error_fn)
	wren.set_load_module_fn(&config, test_load_module_fn)

	vm := wren.new_vm(&config)
	defer wren.free_vm(&vm)

	// Register foreign methods
	wren.register_foreign_method("./test", "Interop", "static Interop.createList()", create_list)
	wren.register_foreign_method(
		"./test",
		"Interop",
		"static Interop.processList(_)",
		process_list,
	)
	wren.register_foreign_method("./test", "Interop", "static Interop.createMap()", create_map)
	wren.register_foreign_method(
		"./test",
		"Interop",
		"static Interop.getMapValue(_)",
		get_map_value,
	)
	wren.register_foreign_method(
		"./test",
		"Interop",
		"static Interop.mapContainsKey(_)",
		map_contains_key,
	)

	// Wren test code
	wren_code := `
class Interop {
    foreign static createList()
    foreign static processList(list)
    foreign static createMap()
    foreign static getMapValue(map)
    foreign static mapContainsKey(map)
}

// Test 1: Create list from Odin
var list = Interop.createList()
System.print("List: %(list)")

// Test 2: Process list from Wren
var doubled = Interop.processList(list)
System.print("Doubled: %(doubled)")

// Test 3: Create map from Odin
var map = Interop.createMap()
System.print("Map: %(map)")

// Test 4: Get value from map
var value = Interop.getMapValue(map)
System.print("Value for 'two': %(value)")

// Test 5: Check if map contains key
var contains = Interop.mapContainsKey(map)
System.print("Contains 'three': %(contains)")
`


	// Run test
	result := wren.interpret(vm, "./test", wren_code)

	if result != .Ok {
		fmt.printf("ERROR: %s\n", g_error_msg)
		os.exit(1)
	}

	// Get output
	output := strings.to_string(g_output_builder)
	fmt.println("Output:")
	fmt.print(output)

	// Verify expected output
	expected := "List: [1, 2, 3, 4, 5]\nDoubled: [2, 4, 6, 8, 10]\nMap: {three: 3, two: 2, one: 1}\nValue for 'two': 2\nContains 'three': true\n"

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
