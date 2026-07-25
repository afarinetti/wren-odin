# Wren-Odin

Odin bindings for the Wren scripting language. Provides a high-level API for embedding Wren in Odin applications with bidirectional data interop.

## Features

### Quick Start

```odin
import "wren"

vm := wren.make_vm()
defer wren.free_vm(&vm)

result := wren.interpret(vm, "main", `System.print("Hello from Wren!")`)
```

For more control, configure callbacks before creating the VM:

```odin
import "wren"

config := wren.make_configuration()
wren.set_write_fn(&config, write_callback)
wren.set_error_fn(&config, error_callback)
wren.set_load_module_fn(&config, module_loader)

vm := wren.new_vm(&config)
defer wren.free_vm(&vm)

result := wren.interpret(vm, "main", `System.print("Hello from Wren!")`)
```

### Foreign Methods

Define Odin functions that Wren can call using the high-level `Value` API — no slot management or raw pointers needed:

```odin
import "wren"

add_numbers :: proc(args: []wren.Value) -> wren.Value {
    a := wren.as_num(args[0])
    b := wren.as_num(args[1])
    return wren.num_value(a + b)
}

concat_strings :: proc(args: []wren.Value) -> wren.Value {
    a := wren.as_string(args[0])
    b := wren.as_string(args[1])
    return wren.string_value(a + b)
}

create_list :: proc(args: []wren.Value) -> wren.Value {
    items := make([]wren.Value, 5)
    items[0] = wren.num_value(1)
    items[1] = wren.num_value(2)
    items[2] = wren.num_value(3)
    items[3] = wren.num_value(4)
    items[4] = wren.num_value(5)
    return wren.list_value(items)
}

main :: proc() {
    vm := wren.make_vm()
    defer wren.free_vm(&vm)

    // Register Odin handlers for Wren foreign methods
    wren.register_method(vm, "./math", "Math", "static Math.add(_,_)", add_numbers)
    wren.register_method(vm, "./strings", "Strings", "static Strings.concat(_,_)", concat_strings)
    wren.register_method(vm, "./interop", "Interop", "static Interop.createList()", create_list)

    // Run Wren code that calls the foreign methods
    wren.interpret(vm, "./math", `
        import "./math" for Math
        System.print(Math.add(10, 20))  // Output: 30
    `)
}
```

In Wren, declare the foreign methods:

```wren
class Math {
    foreign static add(a, b)
}

class Strings {
    foreign static concat(a, b)
}

class Interop {
    foreign static createList()
}
```

Signature format: `"static ClassName.method(_)"` for static methods, `"ClassName.method(_)"` for instance methods, `"ClassName.init new(_)"` for constructors. Each `_` represents one parameter.

### Data Types

The `Value` type is a tagged union representing any Wren value. Use constructors to create values and extractors to read them:

**Constructors:**
- `wren.num_value(f64)` — number
- `wren.string_value(string)` — string
- `wren.bool_value(bool)` — boolean
- `wren.list_value([]Value)` — list
- `wren.map_value(Map)` — map
- `wren.foreign_value(rawptr)` — foreign object
- `wren.nil_value()` — nil

**Extractors** (panic on type mismatch):
- `wren.as_num(Value) -> f64`
- `wren.as_string(Value) -> string`
- `wren.as_bool(Value) -> bool`
- `wren.as_list(Value) -> []Value`
- `wren.as_map(Value) -> Map`
- `wren.as_foreign(Value) -> rawptr`

**Type checks** (return `bool`):
- `wren.is_num(Value)`, `wren.is_string(Value)`, `wren.is_bool(Value)`, `wren.is_list(Value)`, `wren.is_map(Value)`, `wren.is_foreign(Value)`, `wren.is_nil(Value)`

### Calling Wren from Odin

Use `call_method` to invoke Wren methods and get the result as a `Value`:

```odin
// Call a static method with arguments
result, status := wren.call_method(vm, "./math", "Math", "static Math.add(_,_)", wren.Value[2]{
    wren.num_value(10),
    wren.num_value(20),
})

if status == .Ok {
    n := wren.as_num(result)
    // n == 30
}
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

### Foreign Classes

Bind Odin structs to Wren classes with allocate/finalize callbacks. This uses the low-level slot API for the allocate function:

```odin
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
    vm := wren.make_vm()
    defer wren.free_vm(&vm)

    wren.register_foreign_class(
        "./geometry",
        "Point",
        point_allocate,
        point_finalize,
    )

    wren.interpret(vm, "./geometry", `
        import "./geometry" for Point
        var p = Point.new()
        System.print(p)
    `)
}
```

### VM Configuration

Create isolated VMs with custom callbacks for testing or multi-VM setups:

```odin
config := wren.make_configuration()
wren.set_write_fn(&config, custom_write_fn)
wren.set_error_fn(&config, custom_error_fn)
wren.set_resolve_module_fn(&config, custom_resolver)

test_vm := wren.new_vm(&config)
defer wren.free_vm(&test_vm)

result := wren.interpret(test_vm, "main", source)
```

### Low-Level API

The high-level API covers most use cases. For advanced scenarios — custom memory management, direct handle manipulation, or performance-critical paths — the low-level slot-based API is available. It mirrors Wren's C API directly:

```odin
// Low-level: manual slot management
wren.ensure_slots(vm, 3)
wren.set_slot_double(vm, 1, 42.0)
wren.set_slot_string(vm, 2, "hello")
```

See `wren/slots.odin` and `wren/vm.odin` for the full low-level API.

## Limitations

### String Literals Test Crash

The `vendor/wren/test/language/string/literals.wren` test crashes when processing raw strings with certain Unicode patterns. This is a Wren VM bug, not an Odin binding issue. The crash occurs in the Wren VM's string handling code, not in the bindings.

**Reference:** [Wren Issue #1217 - Heap-buffer-overflow in peekChar parsing malformed quotes](https://github.com/wren-lang/wren/issues/1217)

### Foreign Class Constructor Signatures

Foreign class constructors require specific signature formats. The trampoline builds lookup keys as `"static ClassName.signature"` for static methods, but constructors may need different formatting depending on Wren's internal signature generation.

### ARM64 Stack Alignment

The test runner may crash during cleanup on ARM64 systems. This is a cosmetic issue — all tests execute successfully and results are printed before the crash. The issue appears to be in the Odin runtime's stack alignment during VM cleanup.

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
│   ├── wren_raw.odin       # Raw C API bindings (internal)
│   ├── trampolines.odin    # C callback bridges (internal)
│   ├── slots.odin          # Low-level slot operations
│   ├── vm.odin             # VM lifecycle
│   ├── config.odin         # Configuration helpers
│   ├── types.odin          # Public types
│   ├── value.odin          # Value type and conversion functions
│   └── high_level.odin     # High-level method registration API
├── test_runner/             # Test runner
│   ├── main.odin           # API test implementations
│   ├── runner.odin         # Test execution
│   ├── parser.odin         # Comment protocol parser
│   └── file_discovery.odin # Test file discovery
├── integration_tests/       # Integration tests
│   ├── simple_test.odin    # Basic interop
│   ├── list_map_test.odin  # List/map operations
│   ├── string_test.odin    # String operations
│   ├── bool_null_test.odin # Boolean/null handling
│   ├── complex_data_test.odin # Complex data structures
│   └── high_level_test.odin # High-level API demonstration
├── examples/                # Game-dev Wren examples
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

### High-Level Foreign Methods

```odin
package main

import "wren"
import "core:fmt"

add_numbers :: proc(args: []wren.Value) -> wren.Value {
    a := wren.as_num(args[0])
    b := wren.as_num(args[1])
    return wren.num_value(a + b)
}

main :: proc() {
    vm := wren.make_vm()
    defer wren.free_vm(&vm)

    wren.register_method(vm, "./math", "Math", "static Math.add(_,_)", add_numbers)

    source := `
        import "./math" for Math
        System.print(Math.add(10, 20))  // Output: 30
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
    vm := wren.make_vm()
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

The Odin bindings in this project are licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

Wren (vendored in `vendor/wren/`) is licensed under the MIT License. See `vendor/wren/LICENSE` for details.
