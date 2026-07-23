package wren

import "core:c"

foreign import lib "../lib/libwren.a"

// ============================================================================
// Raw Opaque Types (Internal)
// ============================================================================

RawVM     :: struct {}
RawHandle :: struct {}

// ============================================================================
// Raw Callback Types (Internal)
// ============================================================================

RawReallocateFn :: proc "c" (memory: rawptr, new_size: c.size_t, user_data: rawptr) -> rawptr
RawForeignMethodFn :: proc "c" (vm: ^RawVM)
RawFinalizerFn :: proc "c" (data: rawptr)
RawWriteFn :: proc "c" (vm: ^RawVM, text: cstring)
RawErrorFn :: proc "c" (vm: ^RawVM, error_type: c.int, module: cstring, line: c.int, message: cstring)
RawResolveModuleFn :: proc "c" (vm: ^RawVM, importer: cstring, name: cstring) -> cstring

// Forward declaration for LoadModuleResult
RawLoadModuleResult :: struct {
    source:      cstring,
    on_complete: proc "c" (vm: ^RawVM, name: cstring, result: RawLoadModuleResult),
    user_data:   rawptr,
}

RawLoadModuleFn :: proc "c" (vm: ^RawVM, name: cstring) -> RawLoadModuleResult

RawForeignClassMethods :: struct {
    allocate: RawForeignMethodFn,
    finalize: RawFinalizerFn,
}

RawBindForeignMethodFn :: proc "c" (vm: ^RawVM, module: cstring, class_name: cstring, is_static: bool, signature: cstring) -> RawForeignMethodFn
RawBindForeignClassFn :: proc "c" (vm: ^RawVM, module: cstring, class_name: cstring) -> RawForeignClassMethods

// ============================================================================
// Raw Enums (Internal)
// ============================================================================

RawInterpretResult :: enum c.int {
    SUCCESS,
    COMPILE_ERROR,
    RUNTIME_ERROR,
}

RawErrorType :: enum c.int {
    ERROR_COMPILE,
    ERROR_RUNTIME,
    ERROR_STACK_TRACE,
}

RawType :: enum c.int {
    BOOL,
    NUM,
    FOREIGN,
    LIST,
    MAP,
    NULL_TYPE,
    STRING,
    UNKNOWN,
}

// ============================================================================
// Raw Configuration Struct (Internal)
// ============================================================================

RawConfiguration :: struct {
    reallocate_fn:          RawReallocateFn,
    resolve_module_fn:      RawResolveModuleFn,
    load_module_fn:         RawLoadModuleFn,
    bind_foreign_method_fn: RawBindForeignMethodFn,
    bind_foreign_class_fn:  RawBindForeignClassFn,
    write_fn:               RawWriteFn,
    error_fn:               RawErrorFn,
    initial_heap_size:      c.size_t,
    min_heap_size:          c.size_t,
    heap_growth_percent:    c.int,
    user_data:              rawptr,
}

// ============================================================================
// Raw Foreign Function Declarations (Internal)
// ============================================================================

@(default_calling_convention="c", link_prefix="wren")
foreign lib {
    // VM Lifecycle
    GetVersionNumber      :: proc() -> c.int ---
    InitConfiguration     :: proc(config: ^RawConfiguration) ---
    NewVM                 :: proc(config: ^RawConfiguration) -> ^RawVM ---
    FreeVM                :: proc(vm: ^RawVM) ---
    CollectGarbage        :: proc(vm: ^RawVM) ---
    
    // Interpretation
    Interpret             :: proc(vm: ^RawVM, module: cstring, source: cstring) -> RawInterpretResult ---
    
    // Handle Management
    MakeCallHandle        :: proc(vm: ^RawVM, signature: cstring) -> ^RawHandle ---
    Call                  :: proc(vm: ^RawVM, method: ^RawHandle) -> RawInterpretResult ---
    ReleaseHandle         :: proc(vm: ^RawVM, handle: ^RawHandle) ---
    
    // Slot Operations
    GetSlotCount          :: proc(vm: ^RawVM) -> c.int ---
    EnsureSlots           :: proc(vm: ^RawVM, num_slots: c.int) ---
    GetSlotType           :: proc(vm: ^RawVM, slot: c.int) -> RawType ---
    GetSlotBool           :: proc(vm: ^RawVM, slot: c.int) -> bool ---
    GetSlotBytes          :: proc(vm: ^RawVM, slot: c.int, length: ^c.int) -> cstring ---
    GetSlotDouble         :: proc(vm: ^RawVM, slot: c.int) -> f64 ---
    GetSlotForeign        :: proc(vm: ^RawVM, slot: c.int) -> rawptr ---
    GetSlotString         :: proc(vm: ^RawVM, slot: c.int) -> cstring ---
    GetSlotHandle         :: proc(vm: ^RawVM, slot: c.int) -> ^RawHandle ---
    
    SetSlotBool           :: proc(vm: ^RawVM, slot: c.int, value: bool) ---
    SetSlotBytes          :: proc(vm: ^RawVM, slot: c.int, bytes: cstring, length: c.size_t) ---
    SetSlotDouble         :: proc(vm: ^RawVM, slot: c.int, value: f64) ---
    SetSlotNewForeign     :: proc(vm: ^RawVM, slot: c.int, class_slot: c.int, size: c.size_t) -> rawptr ---
    SetSlotNewList        :: proc(vm: ^RawVM, slot: c.int) ---
    SetSlotNewMap         :: proc(vm: ^RawVM, slot: c.int) ---
    SetSlotNull           :: proc(vm: ^RawVM, slot: c.int) ---
    SetSlotString         :: proc(vm: ^RawVM, slot: c.int, text: cstring) ---
    SetSlotHandle         :: proc(vm: ^RawVM, slot: c.int, handle: ^RawHandle) ---
    
    // List Operations
    GetListCount          :: proc(vm: ^RawVM, slot: c.int) -> c.int ---
    GetListElement        :: proc(vm: ^RawVM, list_slot: c.int, index: c.int, element_slot: c.int) ---
    SetListElement        :: proc(vm: ^RawVM, list_slot: c.int, index: c.int, element_slot: c.int) ---
    InsertInList          :: proc(vm: ^RawVM, list_slot: c.int, index: c.int, element_slot: c.int) ---
    
    // Map Operations
    GetMapCount           :: proc(vm: ^RawVM, slot: c.int) -> c.int ---
    GetMapContainsKey     :: proc(vm: ^RawVM, map_slot: c.int, key_slot: c.int) -> bool ---
    GetMapValue           :: proc(vm: ^RawVM, map_slot: c.int, key_slot: c.int, value_slot: c.int) ---
    SetMapValue           :: proc(vm: ^RawVM, map_slot: c.int, key_slot: c.int, value_slot: c.int) ---
    RemoveMapValue        :: proc(vm: ^RawVM, map_slot: c.int, key_slot: c.int, removed_value_slot: c.int) ---
    
    // Variable Lookup
    GetVariable           :: proc(vm: ^RawVM, module: cstring, name: cstring, slot: c.int) ---
    HasVariable           :: proc(vm: ^RawVM, module: cstring, name: cstring) -> bool ---
    HasModule             :: proc(vm: ^RawVM, module: cstring) -> bool ---
    
    // Fiber Control
    AbortFiber            :: proc(vm: ^RawVM, slot: c.int) ---
    
    // User Data
    GetUserData           :: proc(vm: ^RawVM) -> rawptr ---
    SetUserData           :: proc(vm: ^RawVM, user_data: rawptr) ---
}

// ============================================================================
// Raw Aliases (Internal)
// ============================================================================

RawGetVersionNumber      := GetVersionNumber
RawInitConfiguration     := InitConfiguration
RawNewVM                 := NewVM
RawFreeVM                := FreeVM
RawCollectGarbage        := CollectGarbage
RawInterpret             := Interpret
RawMakeCallHandle        := MakeCallHandle
RawCall                  := Call
RawReleaseHandle         := ReleaseHandle
RawGetSlotCount          := GetSlotCount
RawEnsureSlots           := EnsureSlots
RawGetSlotType           := GetSlotType
RawGetSlotBool           := GetSlotBool
RawGetSlotBytes          := GetSlotBytes
RawGetSlotDouble         := GetSlotDouble
RawGetSlotForeign        := GetSlotForeign
RawGetSlotString         := GetSlotString
RawGetSlotHandle         := GetSlotHandle
RawSetSlotBool           := SetSlotBool
RawSetSlotBytes          := SetSlotBytes
RawSetSlotDouble         := SetSlotDouble
RawSetSlotNewForeign     := SetSlotNewForeign
RawSetSlotNewList        := SetSlotNewList
RawSetSlotNewMap         := SetSlotNewMap
RawSetSlotNull           := SetSlotNull
RawSetSlotString         := SetSlotString
RawSetSlotHandle         := SetSlotHandle
RawGetListCount          := GetListCount
RawGetListElement        := GetListElement
RawSetListElement        := SetListElement
RawInsertInList          := InsertInList
RawGetMapCount           := GetMapCount
RawGetMapContainsKey     := GetMapContainsKey
RawGetMapValue           := GetMapValue
RawSetMapValue           := SetMapValue
RawRemoveMapValue        := RemoveMapValue
RawGetVariable           := GetVariable
RawHasVariable           := HasVariable
RawHasModule             := HasModule
RawAbortFiber            := AbortFiber
RawGetUserData           := GetUserData
RawSetUserData           := SetUserData
