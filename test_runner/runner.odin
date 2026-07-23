package main

import "../wren"
import "core:fmt"
import "core:os"
import "core:strings"

// Global test context (single-threaded test runner)
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
	// Only capture the main error message, not stack trace entries
	if error_type == .Runtime || error_type == .Compile {
		g_error_msg = message
	}
}

test_resolve_module_fn :: proc(vm: wren.VM, importer: string, name: string) -> string {
	fmt.printf("  Resolve: importer='%s', name='%s'\n", importer, name)
	// Strip ./ prefix for resolution
	var;resolved_name: string
	if len(name) >= 2 && name[0] == '.' && name[1] == '/' {
		resolved_name = name[2:]
	} else {
		resolved_name = name
	}
	fmt.printf("    -> resolved to: '%s'\n", resolved_name)
	return resolved_name
}

test_load_module_fn :: proc(vm: wren.VM, name: string) -> wren.LoadModuleResult {
	fmt.printf("  Load: name='%s'\n", name)
	// Load module from vendor/wren/test directory
	path, path_err := strings.concatenate({"vendor/wren/test/", name, ".wren"}, context.allocator)
	if path_err != nil {
		fmt.printf("    -> path concatenation failed\n")
		return wren.LoadModuleResult{source = ""}
	}
	defer delete(path)
	fmt.printf("    -> path: '%s'\n", path)

	content, content_err := os.read_entire_file_from_path(path, context.allocator)
	if content_err != os.ERROR_NONE {
		fmt.printf("    -> file read failed: %v\n", content_err)
		return wren.LoadModuleResult{source = ""}
	}
	defer delete(content)
	fmt.printf("    -> loaded %d bytes\n", len(content))

	// Copy content to avoid lifetime issues
	content_bytes := make([]byte, len(content))
	for i in 0 ..< len(content) {
		content_bytes[i] = content[i]
	}

	source := string(content_bytes)
	fmt.printf("    -> returning source (%d chars)\n", len(source))
	return wren.LoadModuleResult{source = source}
}

run_test :: proc(file: string) -> TestResult {
	result: TestResult
	result.file = file
	fmt.printf("Starting test: %s\n", file)

	// Read file content
	content, err := os.read_entire_file_from_path(file, context.allocator)
	if err != os.ERROR_NONE {
		result.error = "Failed to read file"
		return result
	}

	// Convert to string - create a copy
	content_bytes := make([]byte, len(content))
	for i in 0 ..< len(content) {
		content_bytes[i] = content[i]
	}
	delete(content)
	content_str := string(content_bytes)

	// Parse expectations
	expectations := parse_expectations(content_str)

	// Reset global state
	strings.builder_destroy(&g_output_builder)
	strings.builder_init(&g_output_builder)
	g_error_msg = ""

	// Create VM with output capture
	config := wren.make_configuration()
	wren.set_write_fn(&config, test_write_fn)
	wren.set_error_fn(&config, test_error_fn)
	wren.set_load_module_fn(&config, test_load_module_fn)
	wren.set_resolve_module_fn(&config, test_resolve_module_fn)

	vm := wren.new_vm(&config)
	defer wren.free_vm(&vm)

	// Run the test
	interpret_result := wren.interpret(vm, "main", content_str)

	// Copy the string since the builder will be reused on the next test
	actual_output := strings.to_string(g_output_builder)
	actual_output_copy := make([]byte, len(actual_output))
	for i in 0 ..< len(actual_output) {
		actual_output_copy[i] = actual_output[i]
	}
	actual_output = string(actual_output_copy)

	// Check results
	if expectations.has_compile_error {
		if interpret_result != .CompileError {
			result.passed = false
			result.error = "Expected compile error but got success"
			return result
		}
		result.passed = true
		return result
	}

	if expectations.has_runtime_error {
		if interpret_result != .RuntimeError {
			result.passed = false
			result.error = "Expected runtime error but got success"
			return result
		}
		if !strings.contains(g_error_msg, expectations.runtime_error_msg) {
			result.passed = false
			result.error = fmt.aprintf(
				"Expected error message containing '%s', got '%s'",
				expectations.runtime_error_msg,
				g_error_msg,
			)
			return result
		}
		result.passed = true
		return result
	}

	if interpret_result != .Ok {
		result.passed = false
		result.error = fmt.aprintf("Interpretation failed: %s", g_error_msg)
		return result
	}

	// Compare output with expectations
	expected_output := build_expected_output(expectations)

	if actual_output == expected_output {
		result.passed = true
	} else {
		result.passed = false
		result.expected = expected_output
		result.actual = actual_output
	}

	return result
}
