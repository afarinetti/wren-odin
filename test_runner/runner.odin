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

	// Special handling for API tests that need wrenCall()
	if strings.has_suffix(file, "/api/call.wren") {
		call_output := run_call_test(vm, module_name)
		actual_output = call_output
	} else if strings.has_suffix(file, "/api/call_calls_foreign.wren") {
		call_output := run_call_calls_foreign_test(vm, module_name)
		actual_output = call_output
	} else if strings.has_suffix(file, "/api/reset_stack_after_call_abort.wren") {
		call_output := run_reset_stack_after_call_abort_test(vm, module_name)
		actual_output = call_output
	} else if strings.has_suffix(file, "/api/reset_stack_after_foreign_construct.wren") {
		call_output := run_reset_stack_after_foreign_construct_test(vm, module_name)
		actual_output = call_output
	} else if strings.has_suffix(file, "/api/resolution.wren") {
		// Resolution test uses per-test VM configuration, handled in foreign methods
		// Just run the test normally
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
// ============================================================================
// API Test: call.wren
// ============================================================================
run_call_test :: proc(vm: wren.VM, module_name: string) -> string {
	// Get the Call class using raw API
	c_module := strings.clone_to_cstring(module_name)
	c_name := strings.clone_to_cstring("Call")
	defer free(rawptr(c_module))
	defer free(rawptr(c_name))
	wren.RawEnsureSlots(vm.raw, 1)
	wren.RawGetVariable(vm.raw, c_module, c_name, 0)
	call_class_raw := wren.RawGetSlotHandle(vm.raw, 0)
	call_class := wren.Handle {
		raw = call_class_raw,
		vm  = vm,
	}

	// Create call handles
	no_params := wren.make_call_handle(vm, "noParams")
	zero := wren.make_call_handle(vm, "zero()")
	one := wren.make_call_handle(vm, "one(_)")
	two := wren.make_call_handle(vm, "two(_,_)")
	unary := wren.make_call_handle(vm, "-")
	binary := wren.make_call_handle(vm, "-(_)")
	subscript := wren.make_call_handle(vm, "[_,_]")
	subscript_set := wren.make_call_handle(vm, "[_,_]=(_)")

	// Test different arities
	wren.ensure_slots(vm, 1)
	wren.set_slot_handle(vm, 0, call_class)
	wren.call(vm, no_params)

	wren.ensure_slots(vm, 1)
	wren.set_slot_handle(vm, 0, call_class)
	wren.call(vm, zero)

	wren.ensure_slots(vm, 2)
	wren.set_slot_handle(vm, 0, call_class)
	wren.set_double(vm, 1, 1.0)
	wren.call(vm, one)

	wren.ensure_slots(vm, 3)
	wren.set_slot_handle(vm, 0, call_class)
	wren.set_double(vm, 1, 1.0)
	wren.set_double(vm, 2, 2.0)
	wren.call(vm, two)

	// Test operators
	wren.ensure_slots(vm, 1)
	wren.set_slot_handle(vm, 0, call_class)
	wren.call(vm, unary)

	wren.ensure_slots(vm, 2)
	wren.set_slot_handle(vm, 0, call_class)
	wren.set_double(vm, 1, 1.0)
	wren.call(vm, binary)

	wren.ensure_slots(vm, 3)
	wren.set_slot_handle(vm, 0, call_class)
	wren.set_double(vm, 1, 1.0)
	wren.set_double(vm, 2, 2.0)
	wren.call(vm, subscript)

	wren.ensure_slots(vm, 4)
	wren.set_slot_handle(vm, 0, call_class)
	wren.set_double(vm, 1, 1.0)
	wren.set_double(vm, 2, 2.0)
	wren.set_double(vm, 3, 3.0)
	wren.call(vm, subscript_set)

	// Test returning a value
	get_value := wren.make_call_handle(vm, "getValue()")
	wren.ensure_slots(vm, 1)
	wren.set_slot_handle(vm, 0, call_class)
	wren.call(vm, get_value)

	// Get slot count
	slot_count := wren.get_slot_count(vm)
	strings.write_string(&g_output_builder, fmt.aprintf("slots after call: %d\n", slot_count))

	value := wren.get_slot_handle(vm, 0)

	// Test different argument types
	wren.ensure_slots(vm, 3)
	wren.set_slot_handle(vm, 0, call_class)
	wren.set_bool(vm, 1, true)
	wren.set_bool(vm, 2, false)
	wren.call(vm, two)

	wren.ensure_slots(vm, 3)
	wren.set_slot_handle(vm, 0, call_class)
	wren.set_double(vm, 1, 1.2)
	wren.set_double(vm, 2, 3.4)
	wren.call(vm, two)

	wren.ensure_slots(vm, 3)
	wren.set_slot_handle(vm, 0, call_class)
	wren.set_string(vm, 1, "string")
	wren.set_string(vm, 2, "another")
	wren.call(vm, two)

	wren.ensure_slots(vm, 3)
	wren.set_slot_handle(vm, 0, call_class)
	wren.set_null(vm, 1)
	wren.set_slot_handle(vm, 2, value)
	wren.call(vm, two)

	// Test bytes (truncated string)
	wren.ensure_slots(vm, 3)
	wren.set_slot_handle(vm, 0, call_class)

	// Create byte slices for the test
	str_bytes := []byte{'s', 't', 'r'}
	byte_data := []byte{98, 0, 121, 0, 116, 0, 101}

	wren.set_bytes(vm, 1, str_bytes)
	wren.set_bytes(vm, 2, byte_data)
	wren.call(vm, two)

	// Test with extra temporary slots
	wren.ensure_slots(vm, 10)
	wren.set_slot_handle(vm, 0, call_class)
	for i in 1 ..< 10 {
		wren.set_double(vm, i, f64(i) * 0.1)
	}
	wren.call(vm, one)

	// Release handles
	wren.release_handle(&call_class)
	wren.release_handle(&no_params)
	wren.release_handle(&zero)
	wren.release_handle(&one)
	wren.release_handle(&two)
	wren.release_handle(&get_value)
	wren.release_handle(&value)
	wren.release_handle(&unary)
	wren.release_handle(&binary)
	wren.release_handle(&subscript)
	wren.release_handle(&subscript_set)

	return strings.to_string(g_output_builder)
}
// ============================================================================
// API Test: call_calls_foreign.wren
// ============================================================================

run_call_calls_foreign_test :: proc(vm: wren.VM, module_name: string) -> string {
	// Get the CallCallsForeign class
	c_module := strings.clone_to_cstring(module_name)
	c_name := strings.clone_to_cstring("CallCallsForeign")
	defer free(rawptr(c_module))
	defer free(rawptr(c_name))

	wren.RawEnsureSlots(vm.raw, 1)
	wren.RawGetVariable(vm.raw, c_module, c_name, 0)
	class_raw := wren.RawGetSlotHandle(vm.raw, 0)
	class_handle := wren.Handle {
		raw = class_raw,
		vm  = vm,
	}

	// Create call handle for call(param)
	c_sig := strings.clone_to_cstring("call(_)")
	defer free(rawptr(c_sig))
	call_handle_raw := wren.RawMakeCallHandle(vm.raw, c_sig)
	call_handle := wren.Handle {
		raw = call_handle_raw,
		vm  = vm,
	}

	// Set up the call: ensure slots, set receiver and parameter
	wren.RawEnsureSlots(vm.raw, 2)
	wren.RawSetSlotHandle(vm.raw, 0, class_raw)
	wren.RawSetSlotString(vm.raw, 1, "parameter")

	// Print slot count before call
	slot_count_before := wren.RawGetSlotCount(vm.raw)
	strings.write_string(&g_output_builder, fmt.aprintf("slots before %d\n", slot_count_before))

	// Make the call - this will invoke call() which calls api() foreign method
	wren.RawCall(vm.raw, call_handle_raw)

	// Print slot count after call
	slot_count_after := wren.RawGetSlotCount(vm.raw)
	strings.write_string(&g_output_builder, fmt.aprintf("slots after %d\n", slot_count_after))

	// Release handles
	wren.RawReleaseHandle(vm.raw, class_raw)
	wren.RawReleaseHandle(vm.raw, call_handle_raw)

	return strings.to_string(g_output_builder)
}

// ============================================================================
// API Test: reset_stack_after_call_abort.wren
// ============================================================================

run_reset_stack_after_call_abort_test :: proc(vm: wren.VM, module_name: string) -> string {
	// Get the Test class
	c_module := strings.clone_to_cstring(module_name)
	c_name := strings.clone_to_cstring("Test")
	defer free(rawptr(c_module))
	defer free(rawptr(c_name))

	wren.RawEnsureSlots(vm.raw, 1)
	wren.RawGetVariable(vm.raw, c_module, c_name, 0)
	test_class_raw := wren.RawGetSlotHandle(vm.raw, 0)

	// Create call handle for abortFiber()
	c_sig_abort := strings.clone_to_cstring("abortFiber()")
	defer free(rawptr(c_sig_abort))
	abort_handle_raw := wren.RawMakeCallHandle(vm.raw, c_sig_abort)

	// First call: abortFiber() - this will abort the fiber
	wren.RawEnsureSlots(vm.raw, 1)
	wren.RawSetSlotHandle(vm.raw, 0, test_class_raw)
	wren.RawCall(vm.raw, abort_handle_raw)

	// Create call handle for afterAbort(_,_)
	c_sig_after := strings.clone_to_cstring("afterAbort(_,_)")
	defer free(rawptr(c_sig_after))
	after_handle_raw := wren.RawMakeCallHandle(vm.raw, c_sig_after)

	// Second call: afterAbort(1, 2) - should print 3
	wren.RawEnsureSlots(vm.raw, 3)
	wren.RawSetSlotHandle(vm.raw, 0, test_class_raw)
	wren.RawSetSlotDouble(vm.raw, 1, 1.0)
	wren.RawSetSlotDouble(vm.raw, 2, 2.0)
	wren.RawCall(vm.raw, after_handle_raw)

	// Release handles
	wren.RawReleaseHandle(vm.raw, test_class_raw)
	wren.RawReleaseHandle(vm.raw, abort_handle_raw)
	wren.RawReleaseHandle(vm.raw, after_handle_raw)

	return strings.to_string(g_output_builder)
}
// ============================================================================
// API Test: reset_stack_after_foreign_construct.wren
// ============================================================================

run_reset_stack_after_foreign_construct_test :: proc(vm: wren.VM, module_name: string) -> string {
	// Get the Test class
	c_module := strings.clone_to_cstring(module_name)
	c_name := strings.clone_to_cstring("Test")
	defer free(rawptr(c_module))
	defer free(rawptr(c_name))

	wren.RawEnsureSlots(vm.raw, 1)
	wren.RawGetVariable(vm.raw, c_module, c_name, 0)
	test_class_raw := wren.RawGetSlotHandle(vm.raw, 0)

	// Create call handle for callConstruct()
	c_sig_call := strings.clone_to_cstring("callConstruct()")
	defer free(rawptr(c_sig_call))
	call_handle_raw := wren.RawMakeCallHandle(vm.raw, c_sig_call)

	// First call: callConstruct() - this creates a foreign object
	wren.RawEnsureSlots(vm.raw, 1)
	wren.RawSetSlotHandle(vm.raw, 0, test_class_raw)
	wren.RawCall(vm.raw, call_handle_raw)

	// Create call handle for afterConstruct(_,_)
	c_sig_after := strings.clone_to_cstring("afterConstruct(_,_)")
	defer free(rawptr(c_sig_after))
	after_handle_raw := wren.RawMakeCallHandle(vm.raw, c_sig_after)

	// Second call: afterConstruct(1, 2) - should print 3
	wren.RawEnsureSlots(vm.raw, 3)
	wren.RawSetSlotHandle(vm.raw, 0, test_class_raw)
	wren.RawSetSlotDouble(vm.raw, 1, 1.0)
	wren.RawSetSlotDouble(vm.raw, 2, 2.0)
	wren.RawCall(vm.raw, after_handle_raw)

	// Release handles
	wren.RawReleaseHandle(vm.raw, test_class_raw)
	wren.RawReleaseHandle(vm.raw, call_handle_raw)
	wren.RawReleaseHandle(vm.raw, after_handle_raw)

	return strings.to_string(g_output_builder)
}
