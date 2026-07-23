package wren

import "core:c"
import "core:strings"

// ============================================================================
// Configuration
// ============================================================================

Configuration :: struct {
	raw:       RawConfiguration,
	callbacks: ^VMCallbacks,
}

make_configuration :: proc() -> Configuration {
	callbacks := new(VMCallbacks)
	config: Configuration
	config.callbacks = callbacks
	RawInitConfiguration(&config.raw)
	config.raw.write_fn = write_trampoline
	config.raw.error_fn = error_trampoline
	config.raw.load_module_fn = load_module_trampoline
	config.raw.resolve_module_fn = resolve_module_trampoline
	config.raw.bind_foreign_method_fn = bind_foreign_method_trampoline
	config.raw.bind_foreign_class_fn = bind_foreign_class_trampoline
	return config
}

set_write_fn :: proc(config: ^Configuration, fn: WriteFn) {
	config.callbacks.write_fn = fn
}

set_error_fn :: proc(config: ^Configuration, fn: ErrorFn) {
	config.callbacks.error_fn = fn
}

set_load_module_fn :: proc(config: ^Configuration, fn: LoadModuleFn) {
	config.callbacks.load_module_fn = fn
}

set_resolve_module_fn :: proc(config: ^Configuration, fn: ResolveModuleFn) {
	config.callbacks.resolve_module_fn = fn
}

set_bind_foreign_method_fn :: proc(config: ^Configuration, fn: BindForeignMethodFn) {
	config.callbacks.bind_foreign_method_fn = fn
}

set_bind_foreign_class_fn :: proc(config: ^Configuration, fn: BindForeignClassFn) {
	config.callbacks.bind_foreign_class_fn = fn
}

set_heap :: proc(config: ^Configuration, initial_size: int, min_size: int, growth_percent: int) {
	config.raw.initial_heap_size = c.size_t(initial_size)
	config.raw.min_heap_size = c.size_t(min_size)
	config.raw.heap_growth_percent = c.int(growth_percent)
}
