package main

import "../wren"
import "base:runtime"
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"

// ============================================================================
// Integration Test: Complex Data Structures
// ============================================================================

// Create a nested list: [[1, 2], [3, 4], [5, 6]]
create_nested_list :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()

	// Create outer list
	wren.RawEnsureSlots(vm, 4)
	wren.RawSetSlotNewList(vm, 0)

	// Create inner lists
	for i in 0 ..< 3 {
		wren.RawSetSlotNewList(vm, 1)

		// Add two numbers to each inner list
		wren.RawSetSlotDouble(vm, 2, f64(i * 2 + 1))
		wren.RawInsertInList(vm, 1, 0, 2)

		wren.RawSetSlotDouble(vm, 2, f64(i * 2 + 2))
		wren.RawInsertInList(vm, 1, 1, 2)

		// Add inner list to outer list
		wren.RawInsertInList(vm, 0, c.int(i), 1)
	}
}

// Create a map with mixed value types
create_mixed_map :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()

	// Create map
	wren.RawSetSlotNewMap(vm, 0)

	// Add string value
	wren.RawSetSlotString(vm, 1, "name")
	wren.RawSetSlotString(vm, 2, "Alice")
	wren.RawSetMapValue(vm, 0, 1, 2)

	// Add number value
	wren.RawSetSlotString(vm, 1, "age")
	wren.RawSetSlotDouble(vm, 2, 30.0)
	wren.RawSetMapValue(vm, 0, 1, 2)

	// Add boolean value
	wren.RawSetSlotString(vm, 1, "active")
	wren.RawSetSlotBool(vm, 2, true)
	wren.RawSetMapValue(vm, 0, 1, 2)
}

// Process a list of numbers and return statistics as a map
process_numbers :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()

	// Get input list
	list_count := int(wren.RawGetListCount(vm, 1))

	// Calculate statistics
	sum: f64 = 0
	min_val: f64 = 999999.0
	max_val: f64 = -999999.0

	for i in 0 ..< list_count {
		wren.RawGetListElement(vm, 1, c.int(i), 2)
		val := wren.RawGetSlotDouble(vm, 2)
		sum += val
		if val < min_val {
			min_val = val
		}
		if val > max_val {
			max_val = val
		}
	}

	// Create result map
	wren.RawSetSlotNewMap(vm, 0)

	// Add sum
	wren.RawSetSlotString(vm, 1, "sum")
	wren.RawSetSlotDouble(vm, 2, sum)
	wren.RawSetMapValue(vm, 0, 1, 2)

	// Add average
	wren.RawSetSlotString(vm, 1, "average")
	wren.RawSetSlotDouble(vm, 2, sum / f64(list_count))
	wren.RawSetMapValue(vm, 0, 1, 2)

	// Add min
	wren.RawSetSlotString(vm, 1, "min")
	wren.RawSetSlotDouble(vm, 2, min_val)
	wren.RawSetMapValue(vm, 0, 1, 2)

	// Add max
	wren.RawSetSlotString(vm, 1, "max")
	wren.RawSetSlotDouble(vm, 2, max_val)
	wren.RawSetMapValue(vm, 0, 1, 2)

	// Add count
	wren.RawSetSlotString(vm, 1, "count")
	wren.RawSetSlotDouble(vm, 2, f64(list_count))
	wren.RawSetMapValue(vm, 0, 1, 2)
}

// Flatten a nested list into a single list
flatten_list :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()

	// Get outer list
	outer_count := int(wren.RawGetListCount(vm, 1))

	// Create result list
	wren.RawSetSlotNewList(vm, 0)

	result_idx: int = 0
	for i in 0 ..< outer_count {
		// Get inner list
		wren.RawGetListElement(vm, 1, c.int(i), 2)
		inner_count := int(wren.RawGetListCount(vm, 2))

		// Add each element to result
		for j in 0 ..< inner_count {
			wren.RawGetListElement(vm, 2, c.int(j), 3)
			wren.RawInsertInList(vm, 0, c.int(result_idx), 3)
			result_idx += 1
		}
	}
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
	fmt.println("=== Wren-Odin Complex Data Structures Test ===")
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
		"Data",
		"static Data.createNestedList()",
		create_nested_list,
	)
	wren.register_foreign_method(
		"./test",
		"Data",
		"static Data.createMixedMap()",
		create_mixed_map,
	)
	wren.register_foreign_method(
		"./test",
		"Data",
		"static Data.processNumbers(_)",
		process_numbers,
	)
	wren.register_foreign_method("./test", "Data", "static Data.flattenList(_)", flatten_list)

	// Wren test code
	wren_code := `
class Data {
    foreign static createNestedList()
    foreign static createMixedMap()
    foreign static processNumbers(list)
    foreign static flattenList(nested)
}

// Test 1: Nested list creation
var nested = Data.createNestedList()
System.print("Nested list: %(nested)")

// Test 2: Mixed type map
var mixed = Data.createMixedMap()
System.print("Mixed map: %(mixed)")

// Test 3: Process numbers
var numbers = [10, 20, 30, 40, 50]
var stats = Data.processNumbers(numbers)
System.print("Statistics: %(stats)")

// Test 4: Flatten nested list
var flat = Data.flattenList(nested)
System.print("Flattened: %(flat)")
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
	expected := "Nested list: [[1, 2], [3, 4], [5, 6]]\nMixed map: {name: Alice, age: 30, active: true}\nStatistics: {count: 5, min: 10, sum: 150, average: 30, max: 50}\nFlattened: [1, 2, 3, 4, 5, 6]\n"

	if output == expected {
		fmt.println()
		fmt.println("v All tests passed!")
	} else {
		fmt.println()
		fmt.println("x Test failed!")
		fmt.printf("Expected:\n%s\n", expected)
		fmt.printf("Got:\n%s\n", output)
		os.exit(1)
	}
}
