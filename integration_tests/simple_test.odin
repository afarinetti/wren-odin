package main

import "../wren"
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"

// ============================================================================
// Foreign Method Implementations - Simple operations only
// ============================================================================

// Number interop
add_numbers :: proc "c" (vm: ^wren.RawVM) {
	a := wren.RawGetSlotDouble(vm, 1)
	b := wren.RawGetSlotDouble(vm, 2)
	wren.RawSetSlotDouble(vm, 0, a + b)
}

// List interop - create a list with values 1-5
create_list :: proc "c" (vm: ^wren.RawVM) {
	wren.RawSetSlotNewList(vm, 0)
	wren.RawEnsureSlots(vm, 2)

	for i in 0 ..< 5 {
		wren.RawSetSlotDouble(vm, 1, f64(i + 1))
		wren.RawInsertInList(vm, 0, c.int(i), 1)
	}
}

// Map interop - create a map with string keys
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
	fmt.println("=== Wren-Odin Integration Test ===")
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
	wren.register_foreign_method(
		"./test",
		"Interop",
		"static Interop.addNumbers(_,_)",
		add_numbers,
	)
	wren.register_foreign_method("./test", "Interop", "static Interop.createList()", create_list)
	wren.register_foreign_method("./test", "Interop", "static Interop.createMap()", create_map)

	// Wren test code
	wren_code := `
class Interop {
    foreign static addNumbers(a, b)
    foreign static createList()
    foreign static createMap()
}

var sum = Interop.addNumbers(10, 20)
System.print("Sum: %(sum)")

var list = Interop.createList()
System.print("List: %(list)")

var map = Interop.createMap()
System.print("Map: %(map)")
`


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
	expected := "Sum: 30\nList: [1, 2, 3, 4, 5]\nMap: {three: 3, two: 2, one: 1}\n"

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
