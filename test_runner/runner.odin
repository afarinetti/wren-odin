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

run_test :: proc(file: string) -> TestResult {
	result: TestResult
	result.file = file

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

	vm := wren.new_vm(&config)
	defer wren.free_vm(&vm)

	// Run the test
	interpret_result := wren.interpret(vm, "main", content_str)

	actual_output := strings.to_string(g_output_builder)

	// Check results
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
