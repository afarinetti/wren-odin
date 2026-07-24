package main

import "../wren"
import "core:fmt"
import "core:os"
import "core:strings"

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

test_resolve_module_fn :: proc(vm: wren.VM, importer: string, name: string) -> string {
	if len(name) >= 2 && name[0] == '.' && name[1] == '/' {
		// Find the last '/' in importer to get its directory
		last_slash := -1
		for i in 0 ..< len(importer) {
			if importer[i] == '/' {
				last_slash = i
			}
		}
		base_dir := ""
		if last_slash >= 0 {
			base_dir = importer[:last_slash + 1]
		}
		resolved := strings.concatenate({base_dir, name[2:]}, context.allocator)
		return resolved
	}
	if len(name) >= 3 && name[0] == '.' && name[1] == '.' && name[2] == '/' {
		// Handle ../ by going up one directory
		last_slash := -1
		for i in 0 ..< len(importer) {
			if importer[i] == '/' {
				last_slash = i
			}
		}
		base_dir := ""
		if last_slash >= 0 {
			base_dir = importer[:last_slash]
		}
		// Find the second-to-last '/'
		second_last_slash := -1
		for i in 0 ..< len(base_dir) {
			if base_dir[i] == '/' {
				second_last_slash = i
			}
		}
		if second_last_slash >= 0 {
			base_dir = base_dir[:second_last_slash + 1]
		}
		resolved := strings.concatenate({base_dir, name[3:]}, context.allocator)
		return resolved
	}
	return name
}

test_load_module_fn :: proc(vm: wren.VM, name: string) -> wren.LoadModuleResult {
	if name == "meta" {
		content, err := os.read_entire_file_from_path(
			"vendor/wren/src/optional/wren_opt_meta.wren",
			context.allocator,
		)
		if err == os.ERROR_NONE {
			defer delete(content)
			content_bytes := make([]byte, len(content))
			for i in 0 ..< len(content) {
				content_bytes[i] = content[i]
			}
			return wren.LoadModuleResult{source = string(content_bytes)}
		}
	}
	if name == "random" {
		content, err := os.read_entire_file_from_path(
			"vendor/wren/src/optional/wren_opt_random.wren",
			context.allocator,
		)
		if err == os.ERROR_NONE {
			defer delete(content)
			content_bytes := make([]byte, len(content))
			for i in 0 ..< len(content) {
				content_bytes[i] = content[i]
			}
			return wren.LoadModuleResult{source = string(content_bytes)}
		}
	}

	// Module names are like "./test/language/module/..."
	// Convert to file path: strip "./", prepend "vendor/wren/", append ".wren"
	module_path := name
	if strings.has_prefix(module_path, "./") {
		module_path = module_path[2:]
	}
	path, path_err := strings.concatenate(
		{"vendor/wren/", module_path, ".wren"},
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

run_test :: proc(file: string) -> TestResult {
	result: TestResult
	result.file = file

	if strings.has_prefix(file, "vendor/wren/test/benchmark/") {
		result.passed = true
		return result
	}

	content, err := os.read_entire_file_from_path(file, context.allocator)
	if err != os.ERROR_NONE {
		result.error = "Failed to read file"
		return result
	}

	content_bytes := make([]byte, len(content))
	for i in 0 ..< len(content) {
		content_bytes[i] = content[i]
	}
	delete(content)
	content_str := string(content_bytes)

	expectations := parse_expectations(content_str)

	if expectations.is_nontest {
		result.passed = true
		return result
	}

	// Convert file path to module name (match C test runner behavior)
	// C test runner: file="test/language/module/..." -> module="./test/language/module/..."
	// Our file paths are like "vendor/wren/test/language/module/..."
	module_name := file
	if strings.has_prefix(module_name, "vendor/wren/") {
		module_name = module_name[12:]
	}
	if strings.has_suffix(module_name, ".wren") {
		module_name = module_name[:len(module_name) - 5]
	}
	if !strings.has_prefix(module_name, "./") {
		module_name = strings.concatenate({"./", module_name}, context.allocator)
	}

	strings.builder_destroy(&g_output_builder)
	strings.builder_init(&g_output_builder)
	g_error_msg = ""

	config := wren.make_configuration()
	wren.set_write_fn(&config, test_write_fn)
	wren.set_error_fn(&config, test_error_fn)
	wren.set_load_module_fn(&config, test_load_module_fn)
	wren.set_resolve_module_fn(&config, test_resolve_module_fn)

	vm := wren.new_vm(&config)
	defer wren.free_vm(&vm)

	interpret_result := wren.interpret(vm, module_name, content_str)

	actual_output := strings.to_string(g_output_builder)
	actual_output_copy := make([]byte, len(actual_output))
	for i in 0 ..< len(actual_output) {
		actual_output_copy[i] = actual_output[i]
	}
	actual_output = string(actual_output_copy)

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
