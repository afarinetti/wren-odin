package wren

import "core:c"

// ============================================================================
// Public Types
// ============================================================================

VM :: struct {
	raw: ^RawVM,
}

Handle :: struct {
	raw: ^RawHandle,
	vm:  VM,
}

Result :: enum {
	Ok,
	CompileError,
	RuntimeError,
}

ValueType :: enum {
	Bool,
	Num,
	Foreign,
	List,
	Map,
	Null,
	String,
	Unknown,
}

ErrorType :: enum {
	Compile,
	Runtime,
	StackTrace,
}

LoadModuleResult :: struct {
	source: string,
}

ForeignClassMethods :: struct {
	allocate: ForeignMethodFn,
	finalize: proc "c" (data: rawptr),
}

// ============================================================================
// Public Callback Types (Odin-native, no FFI types)
// ============================================================================

WriteFn :: proc(vm: VM, text: string)
ErrorFn :: proc(vm: VM, error_type: ErrorType, module: string, line: int, message: string)
LoadModuleFn :: proc(vm: VM, name: string) -> LoadModuleResult
ResolveModuleFn :: proc(vm: VM, importer: string, name: string) -> string
ForeignMethodFn :: proc(vm: VM)
BindForeignMethodFn :: proc(
	vm: VM,
	module: string,
	class_name: string,
	is_static: bool,
	signature: string,
) -> ForeignMethodFn
BindForeignClassFn :: proc(vm: VM, module: string, class_name: string) -> ForeignClassMethods

// ============================================================================
// Internal: Callback Storage
// ============================================================================

VMCallbacks :: struct {
	write_fn:               WriteFn,
	error_fn:               ErrorFn,
	load_module_fn:         LoadModuleFn,
	resolve_module_fn:      ResolveModuleFn,
	bind_foreign_method_fn: BindForeignMethodFn,
	bind_foreign_class_fn:  BindForeignClassFn,
}
