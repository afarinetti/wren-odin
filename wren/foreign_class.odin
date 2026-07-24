package wren

// ============================================================================
// Declarative Foreign Class Binding (Future Work)
// ============================================================================

// The declarative class binding using reflection is complex and requires
// careful handling of Odin's reflection API. For now, users should use
// the manual registration approach shown in the integration tests.
//
// Future implementation will provide:
// - register_class(vm, module, class_name, T) for automatic binding
// - Struct tags like `wren:"get,set"` for field exposure
// - Automatic generation of allocate/finalize/getters/setters
//
// For now, use the high-level register_method API which provides
// significant improvements over the raw slot-based API.
