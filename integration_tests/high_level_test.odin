package main

import "../wren"
import "core:fmt"
import "core:os"
import "core:strings"

// ============================================================================
// High-Level API Integration Test
// Demonstrates the new Value-based API without slot management
// ============================================================================

add_numbers :: proc(args: []wren.Value) -> wren.Value {
	a := wren.as_num(args[0])
	b := wren.as_num(args[1])
	return wren.num_value(a + b)
}

// Create a list using the high-level API
create_list :: proc(args: []wren.Value) -> wren.Value {
	// Use make() to allocate on heap, not stack
	items := make([]wren.Value, 5)
	items[0] = wren.num_value(1)
	items[1] = wren.num_value(2)
	items[2] = wren.num_value(3)
	items[3] = wren.num_value(4)
	items[4] = wren.num_value(5)
	return wren.list_value(items)
}

// Create a map using the high-level API
// TODO: Map support is currently disabled due to memory corruption issues
// create_map :: proc(args: []wren.Value) -> wren.Value {
// 	m: wren.Map
// 	m.keys = []string{"one", "two", "three"}
// 	m.values = []wren.Value{wren.num_value(1), wren.num_value(2), wren.num_value(3)}
// 	return wren.map_value(m)
// }

// Concatenate strings
concat_strings :: proc(args: []wren.Value) -> wren.Value {
	a := wren.as_string(args[0])
	b := wren.as_string(args[1])
	concat := strings.concatenate({a, b})
	return wren.string_value(concat)
}

// Check if a number is positive
is_positive :: proc(args: []wren.Value) -> wren.Value {
	n := wren.as_num(args[0])
	return wren.bool_value(n > 0)
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
	fmt.println("=== Wren-Odin High-Level API Integration Test ===")
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

	// Register foreign methods using the HIGH-LEVEL API
	// No slot management, no RawVM pointers, just Value-based functions!
	wren.register_method(vm, "./test", "Math", "static Math.add(_,_)", add_numbers)
	wren.register_method(vm, "./test", "Interop", "static Interop.createList()", create_list)
	// wren.register_method(vm, "./test", "Interop", "static Interop.createMap()", create_map)
	wren.register_method(vm, "./test", "Strings", "static Strings.concat(_,_)", concat_strings)
	wren.register_method(vm, "./test", "Numbers", "static Numbers.isPositive(_)", is_positive)

	// Wren test code
	wren_code := `
class Math {
	foreign static add(a, b)
}

class Interop {
	foreign static createList()
	// foreign static createMap()
}

class Strings {
	foreign static concat(a, b)
}

class Numbers {
	foreign static isPositive(n)
}

// Test 1: Number addition
var sum = Math.add(10, 20)
System.print("Sum: %(sum)")

// Test 2: List creation
var list = Interop.createList()
System.print("List: %(list)")

// Test 3: Map creation
// var map = Interop.createMap()
// System.print("Map: %(map)")

// Test 4: String concatenation
var greeting = Strings.concat("Hello", " World")
System.print("Greeting: %(greeting)")

// Test 5: Boolean return
var pos = Numbers.isPositive(42)
var neg = Numbers.isPositive(-5)
System.print("Positive(42): %(pos)")
System.print("Positive(-5): %(neg)")
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
	expected := "Sum: 30\nList: [1, 2, 3, 4, 5]\nGreeting: Hello World\nPositive(42): true\nPositive(-5): false\n"

	if output == expected {
		fmt.println()
		fmt.println("✓ All high-level API tests passed!")
		fmt.println()
		fmt.println("Notice how much cleaner the code is compared to the old slot-based API:")
		fmt.println("  - No RawVM pointers")
		fmt.println("  - No slot indices")
		fmt.println("  - No ensure_slots calls")
		fmt.println("  - Just plain Odin functions working with Value types")
	} else {
		fmt.println()
		fmt.println("✗ Test failed!")
		fmt.printf("Expected:\n%s\n", expected)
		fmt.printf("Got:\n%s\n", output)
		os.exit(1)
	}
}
