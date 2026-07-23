package wren

import "base:runtime"
import "core:c"
import "core:strings"

// ============================================================================
// Trampolines — bridge C callbacks to Odin callbacks
// ============================================================================

cstring_to_string :: proc(cs: cstring) -> string {
	if cs == nil {
		return ""
	}
	return string(cs)
}

write_trampoline :: proc "c" (raw_vm: ^RawVM, text: cstring) {
	context = runtime.default_context()
	callbacks := cast(^VMCallbacks)(RawGetUserData(raw_vm))
	if callbacks != nil && callbacks.write_fn != nil {
		vm := VM {
			raw = raw_vm,
		}
		callbacks.write_fn(vm, cstring_to_string(text))
	}
}

error_trampoline :: proc "c" (
	raw_vm: ^RawVM,
	error_type: c.int,
	module: cstring,
	line: c.int,
	message: cstring,
) {
	context = runtime.default_context()
	callbacks := cast(^VMCallbacks)(RawGetUserData(raw_vm))
	if callbacks != nil && callbacks.error_fn != nil {
		vm := VM {
			raw = raw_vm,
		}
		et: ErrorType
		switch error_type {
		case c.int(RawErrorType.ERROR_COMPILE):
			et = .Compile
		case c.int(RawErrorType.ERROR_RUNTIME):
			et = .Runtime
		case c.int(RawErrorType.ERROR_STACK_TRACE):
			et = .StackTrace
		}
		// Copy strings since they're only valid during the callback
		module_str := ""
		if module != nil {
			module_str = string(module)
		}
		message_str := ""
		if message != nil {
			message_str = string(message)
		}
		callbacks.error_fn(vm, et, module_str, int(line), message_str)
	}
}

load_module_trampoline :: proc "c" (raw_vm: ^RawVM, name: cstring) -> RawLoadModuleResult {
	context = runtime.default_context()
	callbacks := cast(^VMCallbacks)(RawGetUserData(raw_vm))
	result: RawLoadModuleResult
	if callbacks != nil && callbacks.load_module_fn != nil {
		vm := VM {
			raw = raw_vm,
		}
		lr := callbacks.load_module_fn(vm, cstring_to_string(name))
		if len(lr.source) > 0 {
			c_source := strings.clone_to_cstring(lr.source)
			result.source = c_source
			result.on_complete = load_module_complete_trampoline
		}
	}
	return result
}

load_module_complete_trampoline :: proc "c" (
	raw_vm: ^RawVM,
	name: cstring,
	result: RawLoadModuleResult,
) {
	context = runtime.default_context()
	if result.source != nil {
		free(rawptr(result.source))
	}
}

resolve_module_trampoline :: proc "c" (
	raw_vm: ^RawVM,
	importer: cstring,
	name: cstring,
) -> cstring {
	context = runtime.default_context()
	callbacks := cast(^VMCallbacks)(RawGetUserData(raw_vm))
	if callbacks != nil && callbacks.resolve_module_fn != nil {
		vm := VM {
			raw = raw_vm,
		}
		resolved := callbacks.resolve_module_fn(
			vm,
			cstring_to_string(importer),
			cstring_to_string(name),
		)
		if len(resolved) > 0 {
			return strings.clone_to_cstring(resolved)
		}
	}
	return nil
}

bind_foreign_method_trampoline :: proc "c" (
	raw_vm: ^RawVM,
	module: cstring,
	class_name: cstring,
	is_static: bool,
	signature: cstring,
) -> RawForeignMethodFn {
	context = runtime.default_context()
	callbacks := cast(^VMCallbacks)(RawGetUserData(raw_vm))
	if callbacks != nil && callbacks.bind_foreign_method_fn != nil {
		vm := VM {
			raw = raw_vm,
		}
		fn := callbacks.bind_foreign_method_fn(
			vm,
			cstring_to_string(module),
			cstring_to_string(class_name),
			is_static,
			cstring_to_string(signature),
		)
		if fn != nil {
			return foreign_method_dispatch_trampoline
		}
	}
	return nil
}

bind_foreign_class_trampoline :: proc "c" (
	raw_vm: ^RawVM,
	module: cstring,
	class_name: cstring,
) -> RawForeignClassMethods {
	context = runtime.default_context()
	callbacks := cast(^VMCallbacks)(RawGetUserData(raw_vm))
	result: RawForeignClassMethods
	if callbacks != nil && callbacks.bind_foreign_class_fn != nil {
		vm := VM {
			raw = raw_vm,
		}
		methods := callbacks.bind_foreign_class_fn(
			vm,
			cstring_to_string(module),
			cstring_to_string(class_name),
		)
		if methods.allocate != nil {
			result.allocate = foreign_class_allocate_dispatch
			result.finalize = methods.finalize
		}
	}
	return result
}

// Placeholder trampolines for foreign method dispatch
foreign_method_dispatch_trampoline :: proc "c" (raw_vm: ^RawVM) {
	// No-op placeholder — overridden by API test support
}

foreign_class_allocate_dispatch :: proc "c" (raw_vm: ^RawVM) {
	// No-op placeholder — overridden by API test support
}
