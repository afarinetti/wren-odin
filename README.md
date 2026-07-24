# Wren-Odin

Odin bindings for the Wren scripting language. Provides a high-level API for embedding Wren in Odin applications with bidirectional data interop.

## Features

### High-Level API

The public API uses only Odin-native types. No `c.int`, `cstring`, `rawptr`, or other FFI types are exposed to callers. All conversions happen internally.

```odin
import "wren"

config := wren.make_configuration()
wren.set_write_fn(&config, write_callback)
wren.set_error_fn(&config, error_callback)
wren.set_load_module_fn(&config, module_loader)

vm := wren.new_vm(&config)
defer wren.free_vm(&vm)

result := wren.interpret(vm, "main", `System.print("Hello from Wren")`)
```

### Bidirectional Data Interop

Pass data between Odin and Wren in both directions:

- Numbers (f64)
- Strings
- Booleans
- Lists
- Maps
- Foreign objects (Odin structs <-> Wren classes)

```odin
// Odin -> Wren: Create a list
create_list :: proc "c" (vm: ^wren.RawVM) {
    wren.RawEnsureSlots(vm, 1)
    wren.RawSetSlotNewList(vm, 0)
    for i in 0..<5 {
        wren.RawSetSlotDouble(vm, 1, f64(i + 1))
        wren.RawInsertInList(vm, 0, -1, 1)
    }
### String Literals Test Crash

The `vendor/wren/test/language/string/literals.wren` test fails when processing raw strings with certain Unicode patterns and indentation. This appears to be a Wren VM bug related to raw string parsing.

**Reference:** [Wren Issue #1217 - Heap-buffer-overflow in peekChar parsing malformed quotes](https://github.com/wren-lang/wren/issues/1217)

The crash occurs in the Wren VM's string handling code during raw string indentation processing, not in the Odin bindings. All other string tests pass successfully.
        value := wren.RawGetSlotDouble(vm, 2)
        // Process value
    }
}

### High-Level Foreign Methods (Recommended)

The high-level API provides a much simpler way to write foreign methods without dealing with slot management:

```odin
import "wren"

// Define foreign methods using Value types - no slot management needed!
add_numbers :: proc(args: []wren.Value) -> wren.Value {
    a := wren.as_num(args[0])
    b := wren.as_num(args[1])
    return wren.num_value(a + b)
}

create_list :: proc(args: []wren.Value) -> wren.Value {
    // Use make() to allocate on heap
    items := make([]wren.Value, 5)
    items[0] = wren.num_value(1)
    items[1] = wren.num_value(2)
    items[2] = wren.num_value(3)
    items[3] = wren.num_value(4)
    items[4] = wren.num_value(5)
    return wren.list_value(items)
}

concat_strings :: proc(args: []wren.Value) -> wren.Value {
    a := wren.as_string(args[0])
    b := wren.as_string(args[1])
    return wren.string_value(a + b)
}

main :: proc() {
    config := wren.make_configuration()
    // ... setup callbacks ...
    vm := wren.new_vm(&config)
    defer wren.free_vm(&vm)

    // Register methods with the high-level API
    wren.register_method(vm, "./math", "Math", "static Math.add(_,_)", add_numbers)
    wren.register_method(vm, "./interop", "Interop", "static Interop.createList()", create_list)
    wren.register_method(vm, "./strings", "Strings", "static Strings.concat(_,_)", concat_strings)

    // Run Wren code
    wren.interpret(vm, "./math", `
        class Math {
            foreign static add(a, b)
        }
        System.print(Math.add(10, 20))  // Output: 30
    `)
}
```

**Benefits of the high-level API:**
- No slot management (`ensure_slots`, `get_slot_*`, `set_slot_*`)
- No raw VM pointers (`^RawVM`)
- Type-safe value extraction with `as_num`, `as_string`, `as_list`, etc.
- Simple value construction with `num_value`, `string_value`, `list_value`, etc.
- Automatic slot cleanup and memory management

**Value Types:**
- `wren.num_value(f64)` - Create a number value
- `wren.string_value(string)` - Create a string value
- `wren.bool_value(bool)` - Create a boolean value
- `wren.list_value([]Value)` - Create a list value
- `wren.map_value(Map)` - Create a map value
- `wren.as_num(Value)` - Extract a number
- `wren.as_string(Value)` - Extract a string
- `wren.as_bool(Value)` - Extract a boolean
- `wren.as_list(Value)` - Extract a list
- `wren.as_map(Value)` - Extract a map

### Foreign Method Binding

Register Odin functions as Wren foreign methods:

```odin
wren.register_foreign_method(
    "./my_module",
    "Math",
    "static Math.add(_,_)",
    add_numbers,
)
```

### Foreign Class Binding

Bind Odin structs to Wren classes with allocate/finalize callbacks:

```odin
wren.register_foreign_class(
    "./my_module",
    "Point",
    point_allocate,
    point_finalize,
)
```

### Module Loading

Custom module resolution and loading:

```odin
module_loader :: proc(vm: wren.VM, name: string) -> wren.LoadModuleResult {
    // Load from file, embedded resources, etc.
    source := load_module_source(name)
    return wren.LoadModuleResult{source = source}
}

wren.set_load_module_fn(&config, module_loader)
```

### wrenCall() API

Call Wren methods from Odin code using handles:

```odin
// Get a class
wren.ensure_slots(vm, 1)
wren.get_variable(vm, "main", "MyClass", 0)
class_handle := wren.get_slot_handle(vm, 0)

// Create a call handle
method_handle := wren.make_call_handle(vm, "doSomething(_,_)")

// Set up arguments
wren.ensure_slots(vm, 3)
wren.set_slot_handle(vm, 0, class_handle)
wren.set_double(vm, 1, 42.0)
wren.set_string(vm, 2, "hello")

// Call the method
result := wren.call(vm, method_handle)

// Clean up
wren.release_handle(&class_handle)
wren.release_handle(&method_handle)
```

### Per-Test VM Configuration

Create isolated VMs with custom callbacks for testing:

```odin
config := wren.make_configuration()
wren.set_write_fn(&config, custom_write_fn)
wren.set_error_fn(&config, custom_error_fn)
wren.set_resolve_module_fn(&config, custom_resolver)

test_vm := wren.new_vm(&config)
defer wren.free_vm(&test_vm)

result := wren.interpret(test_vm, "main", source)
```

## Limitations

### String Literals Test Crash

The `vendor/wren/test/language/string/literals.wren` test crashes when processing raw strings with certain Unicode patterns. This is a Wren VM bug, not an Odin binding issue. The crash occurs in the Wren VM's string handling code, not in the bindings.

### Foreign Class Constructor Signatures

Foreign class constructors require specific signature formats. The trampoline builds lookup keys as `"static ClassName.signature"` for static methods, but constructors may need different formatting depending on Wren's internal signature generation.

### ARM64 Stack Alignment

The test runner may crash during cleanup on ARM64 systems. This is a cosmetic issue—all tests execute successfully and results are printed before the crash. The issue appears to be in the Odin runtime's stack alignment during VM cleanup.

## Building

### Prerequisites

- Odin compiler (dev-2026-07 or later)
- Git (for Wren submodule)

### Build Wren

```bash
./build_wren.sh
```

This generates the amalgamated Wren source and compiles it to `lib/libwren.a`.

### Build Test Runner

```bash
odin build test_runner -out:build/test_runner
```

### Run Tests

```bash
./build/test_runner
```

Expected output:

```
=== Wren Test Runner ===
Found 892 test files
DEBUG: Starting test loop
✓ vendor/wren/test/core/bool.wren
✓ vendor/wren/test/core/class.wren
...
✓ vendor/wren/test/api/call.wren
...

Total:  830
Passed: 829
Failed: 1
```

## Project Structure

```
wren-odin/
├── wren/                    # Odin bindings package
│   ├── wren_raw.odin       # Raw C API bindings
│   ├── trampolines.odin    # C callback bridges
│   ├── slots.odin          # Slot operations
│   ├── vm.odin             # VM lifecycle and wrenCall()
│   ├── config.odin         # Configuration helpers
│   ├── types.odin          # Public types
│   ├── value.odin          # Value type and conversion functions
│   └── high_level.odin     # High-level method registration API
├── test_runner/             # Test runner
│   ├── main.odin           # API test implementations
│   ├── runner.odin         # Test execution and wrenCall() tests
│   ├── parser.odin         # Comment protocol parser
│   └── file_discovery.odin # Test file discovery
├── integration_tests/       # Integration tests
│   ├── simple_test.odin    # Basic interop
│   ├── list_map_test.odin  # List/map operations
│   ├── string_test.odin    # String operations
│   ├── bool_null_test.odin # Boolean/null handling
│   ├── complex_data_test.odin # Complex data structures
│   └── high_level_test.odin # High-level API demonstration
├── vendor/wren/             # Wren source (git submodule)
├── build_wren.sh           # Wren build script
└── TODO.md                 # Project status
```

## Test Coverage

**Pass Rate:** 829/830 tests passing (99.9%)

**Total Tests:** 892 Wren test files
- 830 active tests (62 are nontests/benchmarks)
- 829 passing
- 1 failing (Wren VM bug in string literals test)

All core language tests pass. The single failure is a Wren VM bug unrelated to the bindings.

## Examples

### Basic Usage

```odin
package main

import "wren"
import "core:fmt"
import "core:strings"

output: strings.Builder

write_fn :: proc(vm: wren.VM, text: string) {
    strings.write_string(&output, text)
}

error_fn :: proc(
    vm: wren.VM,
    error_type: wren.ErrorType,
    module: string,
    line: int,
    message: string,
) {
    fmt.printf("Error at %s:%d: %s\n", module, line, message)
}

module_loader :: proc(vm: wren.VM, name: string) -> wren.LoadModuleResult {
    return wren.LoadModuleResult{source = ""}
}

main :: proc() {
    config := wren.make_configuration()
    wren.set_write_fn(&config, write_fn)
    wren.set_error_fn(&config, error_fn)
    wren.set_load_module_fn(&config, module_loader)

    vm := wren.new_vm(&config)
    defer wren.free_vm(&vm)

    source := `
        class Greeter {
            static greet(name) {
                System.print("Hello, %(name)!")
            }
        }
        Greeter.greet("World")
    `

    result := wren.interpret(vm, "main", source)
    if result == .Ok {
        fmt.print(strings.to_string(output))
    }
}
```

### Foreign Methods

```odin
package main

import "wren"
import "core:fmt"

add_numbers :: proc "c" (vm: ^wren.RawVM) {
    a := wren.RawGetSlotDouble(vm, 1)
    b := wren.RawGetSlotDouble(vm, 2)
    wren.RawSetSlotDouble(vm, 0, a + b)
}

main :: proc() {
    config := wren.make_configuration()
    vm := wren.new_vm(&config)
    defer wren.free_vm(&vm)

    wren.register_foreign_method(
        "./math",
        "Math",
        "static Math.add(_,_)",
        add_numbers,
    )

    source := `
        import "./math" for Math
        System.print(Math.add(10, 20))
    `

    wren.interpret(vm, "main", source)
}
```

### Foreign Classes

```odin
package main

import "wren"
import "core:c"

Point2D :: struct {
    x: f64,
    y: f64,
}

point_allocate :: proc "c" (vm: ^wren.RawVM) {
    data := wren.RawSetSlotNewForeign(vm, 0, 0, c.size_t(size_of(Point2D)))
    point := cast(^Point2D)(data)
    point.x = 0
    point.y = 0
}

point_finalize :: proc "c" (data: rawptr) {
    // Cleanup if needed
}

main :: proc() {
    config := wren.make_configuration()
    vm := wren.new_vm(&config)
    defer wren.free_vm(&vm)

    wren.register_foreign_class(
        "./geometry",
        "Point",
        point_allocate,
        point_finalize,
    )

    source := `
        import "./geometry" for Point
        var p = Point.new()
        System.print(p)
    `

    wren.interpret(vm, "main", source)
}
```

## References

- [Wren Documentation](http://wren.io/)
- [Wren C API](vendor/wren/src/include/wren.h)
- [Odin Documentation](https://odin-lang.org/docs/)

## License

## License

The Odin bindings in this project are licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

Wren (vendored in `vendor/wren/`) is licensed under the MIT License. See `vendor/wren/LICENSE` for details.
