package wren

import "core:c"
import "core:strings"

// ============================================================================
// VM Lifecycle
// ============================================================================

new_vm :: proc(config: ^Configuration) -> VM {
	config.raw.user_data = rawptr(config.callbacks)
	raw_vm := RawNewVM(&config.raw)
	return VM{raw = raw_vm}
}

free_vm :: proc(vm: ^VM) {
	if vm.raw != nil {
		callbacks := cast(^VMCallbacks)(RawGetUserData(vm.raw))
		if callbacks != nil {
			free(callbacks)
		}
		RawFreeVM(vm.raw)
		vm.raw = nil
	}
}

interpret :: proc(vm: VM, module: string, source: string) -> Result {
	c_module := strings.clone_to_cstring(module)
	c_source := strings.clone_to_cstring(source)
	defer free(rawptr(c_module))
	defer free(rawptr(c_source))
	result := RawInterpret(vm.raw, c_module, c_source)
	return convert_result(result)
}

call :: proc(vm: VM, method: Handle) -> Result {
	result := RawCall(vm.raw, method.raw)
	return convert_result(result)
}

collect_garbage :: proc(vm: VM) {
	RawCollectGarbage(vm.raw)
}

convert_result :: proc(result: RawInterpretResult) -> Result {
	switch result {
	case .SUCCESS:
		return .Ok
	case .COMPILE_ERROR:
		return .CompileError
	case .RUNTIME_ERROR:
		return .RuntimeError
	}
	return .RuntimeError
}

// ============================================================================
// Handle Management
// ============================================================================

make_call_handle :: proc(vm: VM, signature: string) -> Handle {
	c_sig := strings.clone_to_cstring(signature)
	defer free(rawptr(c_sig))
	raw_handle := RawMakeCallHandle(vm.raw, c_sig)
	return Handle{raw = raw_handle, vm = vm}
}

release_handle :: proc(h: ^Handle) {
	if h.raw != nil {
		RawReleaseHandle(h.vm.raw, h.raw)
		h.raw = nil
	}
}
