package main

import "../wren"
import "base:runtime"
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"

// ============================================================================
// Integration Test: String Interop
// ============================================================================

// Concatenate two strings
concat_strings :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()

	// Use high-level API to get strings
	vm_hl := wren.VM {
		raw = vm,
	}
	s1 := wren.get_string(vm_hl, 1)
	s2 := wren.get_string(vm_hl, 2)

	// Concatenate
	result := strings.concatenate({s1, s2}, context.allocator)
	defer delete(result)

	result_cstr := strings.clone_to_cstring(result)
	wren.RawSetSlotString(vm, 0, result_cstr)
	free(rawptr(result_cstr))
}

// Get string length
string_length :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()
	vm_hl := wren.VM {
		raw = vm,
	}
	s := wren.get_string(vm_hl, 1)
	wren.RawSetSlotDouble(vm, 0, f64(len(s)))
}

// Convert string to uppercase
to_uppercase :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()
	vm_hl := wren.VM {
		raw = vm,
	}
	s := wren.get_string(vm_hl, 1)

	// Build uppercase version
	result_bytes := make([]u8, len(s))
	for i in 0 ..< len(s) {
		ch := s[i]
		if ch >= 'a' && ch <= 'z' {
			result_bytes[i] = ch - 32
		} else {
			result_bytes[i] = ch
		}
	}

	result := string(result_bytes)
	result_cstr := strings.clone_to_cstring(result)
	wren.RawSetSlotString(vm, 0, result_cstr)
	free(rawptr(result_cstr))
}

// Check if string contains substring
string_contains :: proc "c" (vm: ^wren.RawVM) {
	context = runtime.default_context()
	vm_hl := wren.VM {
		raw = vm,
	}
	s := wren.get_string(vm_hl, 1)
	sub := wren.get_string(vm_hl, 2)

	found := strings.contains(s, sub)
	wren.RawSetSlotBool(vm, 0, found)
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
	fmt.println("=== Wren-Odin String Interop Test ===")
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
	wren.register_foreign_method("./test", "Strings", "static Strings.concat(_,_)", concat_strings)
	wren.register_foreign_method("./test", "Strings", "static Strings.length(_)", string_length)
	wren.register_foreign_method(
		"./test",
		"Strings",
		"static Strings.toUpperCase(_)",
		to_uppercase,
	)
	wren.register_foreign_method(
		"./test",
		"Strings",
		"static Strings.contains(_,_)",
		string_contains,
	)

	// Wren test code
	wren_code := `
class Strings {
    foreign static concat(a, b)
    foreign static length(str)
    foreign static toUpperCase(str)
    foreign static contains(str, substr)
}

// Test 1: Concatenate strings
var greeting = Strings.concat("Hello", " World")
System.print("Concat: %(greeting)")

// Test 2: Get string length
var len = Strings.length("Hello")
System.print("Length: %(len)")

// Test 3: Convert to uppercase
var upper = Strings.toUpperCase("hello world")
System.print("Uppercase: %(upper)")

// Test 4: Check if string contains substring
var hasWorld = Strings.contains("Hello World", "World")
System.print("Contains 'World': %(hasWorld)")

var hasOdin = Strings.contains("Hello World", "Odin")
System.print("Contains 'Odin': %(hasOdin)")
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
	expected := "Concat: Hello World\nLength: 5\nUppercase: HELLO WORLD\nContains 'World': true\nContains 'Odin': false\n"

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
