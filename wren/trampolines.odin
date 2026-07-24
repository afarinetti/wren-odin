package wren

import "base:runtime"
import "core:c"
import "core:strings"

// Import C standard library functions
foreign import libc "system:c"

foreign libc {
	malloc :: proc(size: c.size_t) -> rawptr ---
	@(link_name = "free")
	free_c :: proc(ptr: rawptr) ---
}

// ============================================================================
// Foreign Method Dispatch
// ============================================================================

// Global dispatch table for foreign methods
g_foreign_method_handlers: [dynamic]ForeignMethodHandler
g_foreign_class_handlers: [dynamic]ForeignClassHandler

ForeignMethodHandler :: struct {
	module:     string,
	class_name: string,
	signature:  string,
	fn:         RawForeignMethodFn,
}

ForeignClassHandler :: struct {
	module:     string,
	class_name: string,
	allocate:   RawForeignMethodFn,
	finalize:   RawFinalizerFn,
}

// Register a foreign method handler
register_foreign_method :: proc(
	module: string,
	class_name: string,
	signature: string,
	fn: RawForeignMethodFn,
) {
	append(
		&g_foreign_method_handlers,
		ForeignMethodHandler {
			module = module,
			class_name = class_name,
			signature = signature,
			fn = fn,
		},
	)
}

// Register a foreign class handler
register_foreign_class :: proc(
	module: string,
	class_name: string,
	allocate: RawForeignMethodFn,
	finalize: RawFinalizerFn,
) {
	append(
		&g_foreign_class_handlers,
		ForeignClassHandler {
			module = module,
			class_name = class_name,
			allocate = allocate,
			finalize = finalize,
		},
	)
}

// Clear all registered handlers
clear_foreign_handlers :: proc() {
	g_foreign_method_handlers = nil
	g_foreign_class_handlers = nil
}

// ============================================================================
// Trampolines — bridge C callbacks to Odin callbacks
// ============================================================================

cstring_to_string :: proc(cs: cstring) -> string {
	if cs == nil {
		return ""
	}
	// Copy the C string data to avoid dangling pointer
	ptr := cast([^]byte)(rawptr(cs))
	len := 0
	for ptr[len] != 0 {
		len += 1
	}
	bytes := make([]byte, len)
	for i in 0 ..< len {
		bytes[i] = ptr[i]
	}
	return string(bytes)
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
			module_str = cstring_to_string(module)
		}
		message_str := ""
		if message != nil {
			message_str = cstring_to_string(message)
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
			// Allocate with libc malloc so Wren can free with its allocator
			c_source := cast([^]byte)(malloc(c.size_t(len(lr.source) + 1)))
			if c_source != nil {
				for i in 0 ..< len(lr.source) {
					c_source[i] = lr.source[i]
				}
				c_source[len(lr.source)] = 0
				result.source = cast(cstring)(rawptr(c_source))
				result.on_complete = load_module_complete_trampoline
			}
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
		free_c(rawptr(result.source))
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
			// Allocate with libc malloc so Wren can free with its allocator
			c_str := cast([^]byte)(malloc(c.size_t(len(resolved) + 1)))
			if c_str != nil {
				for i in 0 ..< len(resolved) {
					c_str[i] = resolved[i]
				}
				c_str[len(resolved)] = 0
				return cast(cstring)(rawptr(c_str))
			}
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
		// Call Odin callback first
		fn := callbacks.bind_foreign_method_fn(
			vm,
			cstring_to_string(module),
			cstring_to_string(class_name),
			is_static,
			cstring_to_string(signature),
		)
		if fn != nil {
			// fn is a ForeignMethodFn (Odin callback), but we need RawForeignMethodFn (C callback)
			// We can't directly return it - we need to look up in dispatch table
			// For now, fall through to dispatch table lookup
		}
	}
	// Fall back to global dispatch table
	// Build full signature like C test runner: "static ClassName.signature"
	module_str := cstring_to_string(module)
	class_str := cstring_to_string(class_name)
	sig_str := cstring_to_string(signature)

	full_name := ""
	if is_static {
		full_name = "static "
	}
	full_name = strings.concatenate({full_name, class_str, ".", sig_str}, context.allocator)

	for handler in g_foreign_method_handlers {
		if handler.module == module_str && handler.signature == full_name {
			return handler.fn
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
		// methods.allocate is ForeignMethodFn (Odin), but result.allocate is RawForeignMethodFn (C)
		// We need to look up in dispatch table instead
	}
	// Fall back to global dispatch table
	module_str := cstring_to_string(module)
	class_str := cstring_to_string(class_name)

	for handler in g_foreign_class_handlers {
		if handler.module == module_str && handler.class_name == class_str {
			result.allocate = handler.allocate
			result.finalize = handler.finalize
			return result
		}
	}
	return result
}
