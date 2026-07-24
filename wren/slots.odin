package wren

import "core:c"
import "core:fmt"
import "core:strings"

// ============================================================================
// Slot Operations (Odin-Native Types)
// ============================================================================

ensure_slots :: proc(vm: VM, count: int) {
	RawEnsureSlots(vm.raw, c.int(count))
}

get_slot_count :: proc(vm: VM) -> int {
	return int(RawGetSlotCount(vm.raw))
}

set_null :: proc(vm: VM, slot: int) {
	RawSetSlotNull(vm.raw, c.int(slot))
}

set_bool :: proc(vm: VM, slot: int, value: bool) {
	RawSetSlotBool(vm.raw, c.int(slot), value)
}

set_double :: proc(vm: VM, slot: int, value: f64) {
	RawSetSlotDouble(vm.raw, c.int(slot), value)
}
set_string :: proc(vm: VM, slot: int, value: string) {
	c_str := strings.clone_to_cstring(value)
	defer free(rawptr(c_str))
	RawSetSlotString(vm.raw, c.int(slot), c_str)
}

get_bool :: proc(vm: VM, slot: int) -> bool {
	return RawGetSlotBool(vm.raw, c.int(slot))
}

get_double :: proc(vm: VM, slot: int) -> f64 {
	return RawGetSlotDouble(vm.raw, c.int(slot))
}

get_string :: proc(vm: VM, slot: int) -> string {
	c_str := RawGetSlotString(vm.raw, c.int(slot))
	return string(c_str)
}

get_bytes :: proc(vm: VM, slot: int) -> []byte {
	length: c.int = 0
	ptr := RawGetSlotBytes(vm.raw, c.int(slot), &length)
	if ptr == nil || length <= 0 {
		return nil
	}
	// Convert cstring to byte slice
	byte_ptr := cast(^byte)(ptr)
	return (cast([^]byte)(byte_ptr))[0:int(length)]
}

set_bytes :: proc(vm: VM, slot: int, data: []byte) {
	RawSetSlotBytes(vm.raw, c.int(slot), cstring(&data[0]), c.size_t(len(data)))
}

get_foreign :: proc(vm: VM, slot: int) -> rawptr {
	return RawGetSlotForeign(vm.raw, c.int(slot))
}

set_slot_new_foreign :: proc(vm: VM, slot: int, class_slot: int, size: int) -> rawptr {
	return RawSetSlotNewForeign(vm.raw, c.int(slot), c.int(class_slot), c.size_t(size))
}

get_slot_type :: proc(vm: VM, slot: int) -> ValueType {
	raw_type := RawGetSlotType(vm.raw, c.int(slot))
	return convert_value_type(raw_type)
}

convert_value_type :: proc(raw_type: RawType) -> ValueType {
	switch raw_type {
	case .BOOL:
		return .Bool
	case .NUM:
		return .Num
	case .FOREIGN:
		return .Foreign
	case .LIST:
		return .List
	case .MAP:
		return .Map
	case .NULL_TYPE:
		return .Null
	case .STRING:
		return .String
	case .UNKNOWN:
		return .Unknown
	}
	return .Unknown
}

get_slot_handle :: proc(vm: VM, slot: int) -> Handle {
	raw_handle := RawGetSlotHandle(vm.raw, c.int(slot))
	return Handle{raw = raw_handle, vm = vm}
}

set_slot_handle :: proc(vm: VM, slot: int, handle: Handle) {
	RawSetSlotHandle(vm.raw, c.int(slot), handle.raw)
}

// ============================================================================
// Variable Lookup
// ============================================================================

get_variable :: proc(vm: VM, module: string, name: string, slot: int) {
	c_module := strings.clone_to_cstring(module)
	c_name := strings.clone_to_cstring(name)
	defer free(rawptr(c_module))
	defer free(rawptr(c_name))
	RawGetVariable(vm.raw, c_module, c_name, c.int(slot))
}

has_variable :: proc(vm: VM, module: string, name: string) -> bool {
	c_module := strings.clone_to_cstring(module)
	c_name := strings.clone_to_cstring(name)
	defer free(rawptr(c_module))
	defer free(rawptr(c_name))
	return RawHasVariable(vm.raw, c_module, c_name)
}

has_module :: proc(vm: VM, module: string) -> bool {
	c_module := strings.clone_to_cstring(module)
	defer free(rawptr(c_module))
	return RawHasModule(vm.raw, c_module)
}

// ============================================================================
// List Operations
// ============================================================================

get_list_count :: proc(vm: VM, slot: int) -> int {
	return int(RawGetListCount(vm.raw, c.int(slot)))
}

get_list_element :: proc(vm: VM, list_slot: int, index: int, element_slot: int) {
	RawGetListElement(vm.raw, c.int(list_slot), c.int(index), c.int(element_slot))
}

set_list_element :: proc(vm: VM, list_slot: int, index: int, element_slot: int) {
	RawSetListElement(vm.raw, c.int(list_slot), c.int(index), c.int(element_slot))
}

insert_in_list :: proc(vm: VM, list_slot: int, index: int, element_slot: int) {
	RawInsertInList(vm.raw, c.int(list_slot), c.int(index), c.int(element_slot))
}

// ============================================================================
// Map Operations
// ============================================================================

get_map_count :: proc(vm: VM, slot: int) -> int {
	return int(RawGetMapCount(vm.raw, c.int(slot)))
}

get_map_contains_key :: proc(vm: VM, map_slot: int, key_slot: int) -> bool {
	return RawGetMapContainsKey(vm.raw, c.int(map_slot), c.int(key_slot))
}

get_map_value :: proc(vm: VM, map_slot: int, key_slot: int, value_slot: int) {
	RawGetMapValue(vm.raw, c.int(map_slot), c.int(key_slot), c.int(value_slot))
}

set_map_value :: proc(vm: VM, map_slot: int, key_slot: int, value_slot: int) {
	RawSetMapValue(vm.raw, c.int(map_slot), c.int(key_slot), c.int(value_slot))
}

remove_map_value :: proc(vm: VM, map_slot: int, key_slot: int, removed_value_slot: int) {
	RawRemoveMapValue(vm.raw, c.int(map_slot), c.int(key_slot), c.int(removed_value_slot))
}

// ============================================================================
// Fiber Control
// ============================================================================

abort_fiber :: proc(vm: VM, slot: int) {
	RawAbortFiber(vm.raw, c.int(slot))
}

// ============================================================================
// User Data
// ============================================================================

get_user_data :: proc(vm: VM) -> rawptr {
	return RawGetUserData(vm.raw)
}

set_user_data :: proc(vm: VM, user_data: rawptr) {
	RawSetUserData(vm.raw, user_data)
}
