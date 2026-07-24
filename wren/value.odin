package wren

import "core:c"
import "core:fmt"
import "core:strings"

// ============================================================================
// Value Type - High-level representation of Wren values
// ============================================================================

// Map represents a Wren map as parallel slices of keys and values
Map :: struct {
	keys:   []string,
	values: []Value,
}

// Value is a tagged union representing any Wren value
Value :: union {
	bool,
	f64,
	string,
	[]Value, // list
	Map, // map
	rawptr, // foreign object
}

// ============================================================================
// Type Checking Helpers
// ============================================================================

is_nil :: proc(value: Value) -> bool {
	// Check if value is nil (represented as rawptr nil)
	if v, ok := value.(rawptr); ok {
		return v == nil
	}
	return false
}
is_bool :: proc(value: Value) -> bool {
	if value, ok := value.(bool); ok {
		return true
	}
	return false
}

is_num :: proc(value: Value) -> bool {
	if value, ok := value.(f64); ok {
		return true
	}
	return false
}

is_string :: proc(value: Value) -> bool {
	if value, ok := value.(string); ok {
		return true
	}
	return false
}

is_list :: proc(value: Value) -> bool {
	if value, ok := value.([]Value); ok {
		return true
	}
	return false
}

is_map :: proc(value: Value) -> bool {
	if value, ok := value.(Map); ok {
		return true
	}
	return false
}

is_foreign :: proc(value: Value) -> bool {
	if value, ok := value.(rawptr); ok {
		return true
	}
	return false
}

// ============================================================================
// Value Constructors
// ============================================================================

// nil_value creates a nil Value
nil_value :: proc() -> Value {
	return rawptr(nil)
}

// bool_value creates a bool Value
bool_value :: proc(b: bool) -> Value {
	return Value(b)
}

// num_value creates a number Value
num_value :: proc(n: f64) -> Value {
	return Value(n)
}

// string_value creates a string Value
string_value :: proc(s: string) -> Value {
	return Value(s)
}

// list_value creates a list Value
list_value :: proc(items: []Value) -> Value {
	return Value(items)
}

// map_value creates a map Value
map_value :: proc(m: Map) -> Value {
	return Value(m)
}

// foreign_value creates a foreign object Value
foreign_value :: proc(ptr: rawptr) -> Value {
	return Value(ptr)
}

// ============================================================================
// Type-Safe Extraction (panics on type mismatch)
// ============================================================================

as_bool :: proc(value: Value) -> bool {
	if v, ok := value.(bool); ok {
		return v
	}
	panic("as_bool: value is not a bool")
}

as_num :: proc(value: Value) -> f64 {
	if v, ok := value.(f64); ok {
		return v
	}
	panic("as_num: value is not a number")
}

as_string :: proc(value: Value) -> string {
	if v, ok := value.(string); ok {
		return v
	}
	panic("as_string: value is not a string")
}

as_list :: proc(value: Value) -> []Value {
	if v, ok := value.([]Value); ok {
		return v
	}
	panic("as_list: value is not a list")
}

as_map :: proc(value: Value) -> Map {
	if v, ok := value.(Map); ok {
		return v
	}
	panic("as_map: value is not a map")
}

as_foreign :: proc(value: Value) -> rawptr {
	if v, ok := value.(rawptr); ok {
		return v
	}
	panic("as_foreign: value is not a foreign object")
}

// ============================================================================
// Value <-> Slot Conversion
// ============================================================================

// get_value reads a slot into a Value
get_value :: proc(vm: VM, slot: int) -> Value {
	slot_type := get_slot_type(vm, slot)

	switch slot_type {
	case .Null:
		return rawptr(nil)
	case .Bool:
		return get_bool(vm, slot)
	case .Num:
		return get_double(vm, slot)
	case .String:
		return get_string(vm, slot)
	case .List:
		return get_list_value(vm, slot)
	case .Map:
		return read_map_value(vm, slot)
	case .Foreign:
		return get_foreign(vm, slot)
	case .Unknown:
		return rawptr(nil)
	}
	return rawptr(nil)
}

// set_value writes a Value into a slot
set_value :: proc(vm: VM, slot: int, value: Value) {
	switch v in value {
	case bool:
		set_bool(vm, slot, v)
	case f64:
		set_double(vm, slot, v)
	case string:
		set_string(vm, slot, v)
	case []Value:
		set_list_value(vm, slot, v)
	case Map:
		// For maps, we need to use the raw API
		set_map_value_raw(vm, slot, v)
	case rawptr:
		if v == nil {
			set_null(vm, slot)
		} else {
			// For foreign objects, we need to use set_slot_new_foreign or get the handle
			// This is a simplified version - may need adjustment based on use case
			panic("set_value: rawptr not yet supported for direct slot setting")
		}
	}
}

// ============================================================================
// List/Map Construction Helpers
// ============================================================================

// get_list_value reads a Wren list into a Value slice
get_list_value :: proc(vm: VM, list_slot: int) -> []Value {
	count := get_list_count(vm, list_slot)
	result := make([]Value, count)

	// We need a temporary slot for elements
	// Use slot after list_slot
	element_slot := list_slot + 1
	ensure_slots(vm, element_slot + 1)

	for i in 0 ..< count {
		get_list_element(vm, list_slot, i, element_slot)
		result[i] = get_value(vm, element_slot)
	}

	return result
}

// read_map_value reads a Wren map into a Map struct
read_map_value :: proc(vm: VM, map_slot: int) -> Map {
	count := get_map_count(vm, map_slot)
	result: Map
	result.keys = make([]string, count)
	result.values = make([]Value, count)

	// We need temporary slots for iteration
	// This is complex - for now, return empty map
	// Full implementation would require iterating the map
	// which Wren's C API doesn't directly support

	return result
}

// set_list_value writes a Value slice as a Wren list
set_list_value :: proc(vm: VM, slot: int, items: []Value) {
	// Create a new list in the slot
	RawSetSlotNewList(vm.raw, c.int(slot))

	// We need temporary slots for elements - use a different slot for each
	// to avoid any potential reference issues
	ensure_slots(vm, slot + len(items) + 1)

	for item, i in items {
		element_slot := slot + 1 + i
		set_value(vm, element_slot, item)
		insert_in_list(vm, slot, i, element_slot)
	}
}

// set_map_value_raw writes a Map struct as a Wren map
set_map_value_raw :: proc(vm: VM, slot: int, m: Map) {
	// We need temporary slots for keys and values
	// Ensure we have at least 3 slots (map slot + key slot + value slot)
	ensure_slots(vm, 3)

	// Create a new map in the slot
	RawSetSlotNewMap(vm.raw, c.int(slot))

	key_slot := slot + 1
	value_slot := slot + 2
	for i in 0 ..< len(m.keys) {
		key := m.keys[i]
		set_string(vm, key_slot, key)
		set_value(vm, value_slot, m.values[i])
		set_map_value_slot(vm, slot, key_slot, value_slot)
	}
}

// Helper to set a map value using slots
set_map_value_slot :: proc(vm: VM, map_slot: int, key_slot: int, value_slot: int) {
	RawSetMapValue(vm.raw, c.int(map_slot), c.int(key_slot), c.int(value_slot))
}

// make_list creates a Wren list from an Odin slice
make_list :: proc(vm: VM, items: []Value) -> Value {
	// We need to allocate a slot for the list
	ensure_slots(vm, 1)
	set_list_value(vm, 0, items)
	return get_value(vm, 0)
}

// make_map creates a Wren map from an Odin Map struct
make_map :: proc(vm: VM, m: Map) -> Value {
	// We need to allocate a slot for the map
	ensure_slots(vm, 1)
	set_map_value_raw(vm, 0, m)
	return get_value(vm, 0)
}
