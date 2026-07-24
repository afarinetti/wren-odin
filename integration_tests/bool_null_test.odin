package main

import "../wren"
import "base:runtime"
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"

// ============================================================================
// Integration Test: Boolean and Null Interop
// ============================================================================

// Return true if number is positive
is_positive :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()
	num := wren.RawGetSlotDouble(vm, 1)
	wren.RawSetSlotBool(vm, 0, num > 0)
}

// Logical AND of two booleans
bool_and :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()
	a := wren.RawGetSlotBool(vm, 1)
	b := wren.RawGetSlotBool(vm, 2)
	wren.RawSetSlotBool(vm, 0, a && b)
}

// Logical OR of two booleans
bool_or :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()
	a := wren.RawGetSlotBool(vm, 1)
	b := wren.RawGetSlotBool(vm, 2)
	wren.RawSetSlotBool(vm, 0, a || b)
}

// Negate a boolean
bool_not :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()
	a := wren.RawGetSlotBool(vm, 1)
	wren.RawSetSlotBool(vm, 0, !a)
}

// Return null
return_null :: proc "c" (vm: ^wren.RawVM) {
	wren.RawSetSlotNull(vm, 0)
}

// Check if value is null (by checking slot type)
is_null :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()
	slot_type := wren.RawGetSlotType(vm, 1)
	is_null := slot_type == wren.RawType.NULL_TYPE
	wren.RawSetSlotBool(vm, 0, is_null)
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
	fmt.println("=== Wren-Odin Boolean/Null Interop Test ===")
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
	wren.register_foreign_method("./test", "Logic", "static Logic.isPositive(_)", is_positive)
	wren.register_foreign_method("./test", "Logic", "static Logic.and(_,_)", bool_and)
	wren.register_foreign_method("./test", "Logic", "static Logic.or(_,_)", bool_or)
	wren.register_foreign_method("./test", "Logic", "static Logic.not(_)", bool_not)
	wren.register_foreign_method("./test", "Logic", "static Logic.returnNull()", return_null)
	wren.register_foreign_method("./test", "Logic", "static Logic.isNull(_)", is_null)

	// Wren test code
	wren_code := `
class Logic {
    foreign static isPositive(num)
    foreign static and(a, b)
    foreign static or(a, b)
    foreign static not(a)
    foreign static returnNull()
    foreign static isNull(val)
}

// Test 1: Positive number check
var pos = Logic.isPositive(5)
System.print("isPositive(5): %(pos)")

var neg = Logic.isPositive(-3)
System.print("isPositive(-3): %(neg)")

// Test 2: Logical AND
var andTT = Logic.and(true, true)
System.print("true AND true: %(andTT)")

var andTF = Logic.and(true, false)
System.print("true AND false: %(andTF)")

// Test 3: Logical OR
var orFF = Logic.or(false, false)
System.print("false OR false: %(orFF)")

var orFT = Logic.or(false, true)
System.print("false OR true: %(orFT)")

// Test 4: Logical NOT
var notTrue = Logic.not(true)
System.print("NOT true: %(notTrue)")

// Test 5: Null handling
var nullVal = Logic.returnNull()
System.print("returnNull(): %(nullVal)")

var isNullCheck = Logic.isNull(nullVal)
System.print("isNull(null): %(isNullCheck)")

var isNotNull = Logic.isNull(42)
System.print("isNull(42): %(isNotNull)")
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
	expected := "isPositive(5): true\nisPositive(-3): false\ntrue AND true: true\ntrue AND false: false\nfalse OR false: false\nfalse OR true: true\nNOT true: false\nreturnNull(): null\nisNull(null): true\nisNull(42): false\n"

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
