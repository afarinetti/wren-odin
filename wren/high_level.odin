package wren

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:strings"

// ============================================================================
// High-Level Method Registration
// ============================================================================

// HighLevelMethodFn is the high-level foreign method signature
// Works with Odin values, no slot management needed
HighLevelMethodFn :: proc(args: []Value) -> Value

// HighLevelHandler stores a high-level method handler
HighLevelHandler :: struct {
	module:     string,
	class_name: string,
	signature:  string,
	handler:    HighLevelMethodFn,
}

// Global dispatch table for high-level methods
g_high_level_handlers: [dynamic]HighLevelHandler

// Maximum number of high-level methods we can register
MAX_HIGH_LEVEL_METHODS :: 64

// Array of handlers indexed by wrapper ID
g_high_level_handler_table: [MAX_HIGH_LEVEL_METHODS]HighLevelMethodFn
g_next_handler_id: int

// register_method registers a high-level foreign method
// The handler receives arguments as []Value and returns a Value
// No slot management needed - the wrapper handles all conversions
register_method :: proc(
	vm: VM,
	module: string,
	class_name: string,
	signature: string,
	handler: HighLevelMethodFn,
) {
	// Store the high-level handler
	append(
		&g_high_level_handlers,
		HighLevelHandler {
			module = module,
			class_name = class_name,
			signature = signature,
			handler = handler,
		},
	)

	// Assign an ID for this handler
	handler_id := g_next_handler_id
	g_next_handler_id += 1

	if handler_id >= MAX_HIGH_LEVEL_METHODS {
		panic("Too many high-level methods registered")
	}

	// Store handler in the table
	g_high_level_handler_table[handler_id] = handler

	// Get the wrapper function for this handler ID
	wrapper := get_wrapper_for_id(handler_id)

	// Register the wrapper with the existing trampoline system
	register_foreign_method(module, class_name, signature, wrapper)
}

// clear_high_level_handlers clears all high-level handlers
clear_high_level_handlers :: proc() {
	g_high_level_handlers = nil
	g_next_handler_id = 0
	for i in 0 ..< MAX_HIGH_LEVEL_METHODS {
		g_high_level_handler_table[i] = nil
	}
}

// ============================================================================
// High-Level Wrapper Trampoline
// ============================================================================

// call_handler is the common implementation for all wrappers
call_handler :: proc(handler_id: int, raw_vm: ^RawVM) {
	context = runtime.default_context()

	vm := VM {
		raw = raw_vm,
	}

	// Get slot count
	slot_count := get_slot_count(vm)

	// Slot 0 = receiver, slots 1..N = arguments
	if slot_count <= 0 {
		return
	}

	arg_count := slot_count - 1

	// Build args slice
	args := make([]Value, arg_count)
	for i in 0 ..< arg_count {
		args[i] = get_value(vm, i + 1)
	}

	// Get the handler from the table
	handler := g_high_level_handler_table[handler_id]

	if handler != nil {
		// Call the handler
		result := handler(args)

		// Write result back to slot 0
		set_value(vm, 0, result)
	} else {
		// No handler found - set null
		set_null(vm, 0)
	}
}

// Fixed set of wrapper functions
// Each wrapper calls call_handler with its specific ID
wrapper_0 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(0, vm)}
wrapper_1 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(1, vm)}
wrapper_2 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(2, vm)}
wrapper_3 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(3, vm)}
wrapper_4 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(4, vm)}
wrapper_5 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(5, vm)}
wrapper_6 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(6, vm)}
wrapper_7 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(7, vm)}
wrapper_8 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(8, vm)}
wrapper_9 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(9, vm)}
wrapper_10 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(10, vm)}
wrapper_11 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(11, vm)}
wrapper_12 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(12, vm)}
wrapper_13 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(13, vm)}
wrapper_14 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(14, vm)}
wrapper_15 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(15, vm)}
wrapper_16 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(16, vm)}
wrapper_17 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(17, vm)}
wrapper_18 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(18, vm)}
wrapper_19 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(19, vm)}
wrapper_20 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(20, vm)}
wrapper_21 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(21, vm)}
wrapper_22 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(22, vm)}
wrapper_23 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(23, vm)}
wrapper_24 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(24, vm)}
wrapper_25 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(25, vm)}
wrapper_26 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(26, vm)}
wrapper_27 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(27, vm)}
wrapper_28 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(28, vm)}
wrapper_29 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(29, vm)}
wrapper_30 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(30, vm)}
wrapper_31 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(31, vm)}
wrapper_32 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(32, vm)}
wrapper_33 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(33, vm)}
wrapper_34 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(34, vm)}
wrapper_35 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(35, vm)}
wrapper_36 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(36, vm)}
wrapper_37 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(37, vm)}
wrapper_38 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(38, vm)}
wrapper_39 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(39, vm)}
wrapper_40 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(40, vm)}
wrapper_41 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(41, vm)}
wrapper_42 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(42, vm)}
wrapper_43 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(43, vm)}
wrapper_44 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(44, vm)}
wrapper_45 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(45, vm)}
wrapper_46 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(46, vm)}
wrapper_47 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(47, vm)}
wrapper_48 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(48, vm)}
wrapper_49 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(49, vm)}
wrapper_50 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(50, vm)}
wrapper_51 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(51, vm)}
wrapper_52 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(52, vm)}
wrapper_53 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(53, vm)}
wrapper_54 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(54, vm)}
wrapper_55 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(55, vm)}
wrapper_56 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(56, vm)}
wrapper_57 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(57, vm)}
wrapper_58 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(58, vm)}
wrapper_59 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(59, vm)}
wrapper_60 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(60, vm)}
wrapper_61 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(61, vm)}
wrapper_62 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(62, vm)}
wrapper_63 :: proc "c" (vm: ^RawVM) {context = runtime.default_context();call_handler(63, vm)}

// get_wrapper_for_id returns the wrapper function for a given handler ID
get_wrapper_for_id :: proc(id: int) -> proc "c" (vm: ^RawVM) {
	switch id {
	case 0:
		return wrapper_0
	case 1:
		return wrapper_1
	case 2:
		return wrapper_2
	case 3:
		return wrapper_3
	case 4:
		return wrapper_4
	case 5:
		return wrapper_5
	case 6:
		return wrapper_6
	case 7:
		return wrapper_7
	case 8:
		return wrapper_8
	case 9:
		return wrapper_9
	case 10:
		return wrapper_10
	case 11:
		return wrapper_11
	case 12:
		return wrapper_12
	case 13:
		return wrapper_13
	case 14:
		return wrapper_14
	case 15:
		return wrapper_15
	case 16:
		return wrapper_16
	case 17:
		return wrapper_17
	case 18:
		return wrapper_18
	case 19:
		return wrapper_19
	case 20:
		return wrapper_20
	case 21:
		return wrapper_21
	case 22:
		return wrapper_22
	case 23:
		return wrapper_23
	case 24:
		return wrapper_24
	case 25:
		return wrapper_25
	case 26:
		return wrapper_26
	case 27:
		return wrapper_27
	case 28:
		return wrapper_28
	case 29:
		return wrapper_29
	case 30:
		return wrapper_30
	case 31:
		return wrapper_31
	case 32:
		return wrapper_32
	case 33:
		return wrapper_33
	case 34:
		return wrapper_34
	case 35:
		return wrapper_35
	case 36:
		return wrapper_36
	case 37:
		return wrapper_37
	case 38:
		return wrapper_38
	case 39:
		return wrapper_39
	case 40:
		return wrapper_40
	case 41:
		return wrapper_41
	case 42:
		return wrapper_42
	case 43:
		return wrapper_43
	case 44:
		return wrapper_44
	case 45:
		return wrapper_45
	case 46:
		return wrapper_46
	case 47:
		return wrapper_47
	case 48:
		return wrapper_48
	case 49:
		return wrapper_49
	case 50:
		return wrapper_50
	case 51:
		return wrapper_51
	case 52:
		return wrapper_52
	case 53:
		return wrapper_53
	case 54:
		return wrapper_54
	case 55:
		return wrapper_55
	case 56:
		return wrapper_56
	case 57:
		return wrapper_57
	case 58:
		return wrapper_58
	case 59:
		return wrapper_59
	case 60:
		return wrapper_60
	case 61:
		return wrapper_61
	case 62:
		return wrapper_62
	case 63:
		return wrapper_63
	case:
		panic("Invalid handler ID")
	}
	return nil
}

// ============================================================================
// Convenience Functions
// ============================================================================

// make_vm creates a VM with default configuration
// This is a convenience function for simple use cases
make_vm :: proc() -> VM {
	config := make_configuration()
	// Set sensible defaults
	set_write_fn(&config, default_write_fn)
	set_error_fn(&config, default_error_fn)
	set_load_module_fn(&config, default_load_module_fn)
	return new_vm(&config)
}

// default_write_fn is a no-op write function
default_write_fn :: proc(vm: VM, text: string) {
	// No-op by default
}

// default_error_fn is a no-op error function
default_error_fn :: proc(
	vm: VM,
	error_type: ErrorType,
	module: string,
	line: int,
	message: string,
) {
	// No-op by default
}

// default_load_module_fn returns empty source for all modules
default_load_module_fn :: proc(vm: VM, name: string) -> LoadModuleResult {
	return LoadModuleResult{source = ""}
}

// call_method calls a Wren method and gets the result as a Value
// This is a convenience wrapper around the slot-based call API
call_method :: proc(
	vm: VM,
	module: string,
	variable: string,
	signature: string,
	args: []Value,
) -> (
	Value,
	Result,
) {
	// Ensure slots for receiver + args
	ensure_slots(vm, 1 + len(args))

	// Get the variable
	get_variable(vm, module, variable, 0)

	// Set arguments
	for arg, i in args {
		set_value(vm, i + 1, arg)
	}

	// Make call handle and call
	handle := make_call_handle(vm, signature)
	result := call(vm, handle)

	// Get return value from slot 0
	return_value := get_value(vm, 0)

	// Cleanup
	release_handle(&handle)

	return return_value, result
}
