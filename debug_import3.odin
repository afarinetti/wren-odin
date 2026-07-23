package main

import "core:fmt"
import "wren"

test_resolve_fn :: proc(vm: wren.VM, importer: string, name: string) -> string {
    fmt.printf("Resolve: importer='%s', name='%s'\n", importer, name)
    // Return the resolved module name
    return name
}

test_load_fn :: proc(vm: wren.VM, name: string) -> wren.LoadModuleResult {
    fmt.printf("Loading module: '%s'\n", name)
    // Return empty source to simulate module not found
    return wren.LoadModuleResult{source = ""}
}

main :: proc() {
    config := wren.make_configuration()
    wren.set_resolve_module_fn(&config, test_resolve_fn)
    wren.set_load_module_fn(&config, test_load_fn)
    
    vm := wren.new_vm(&config)
    defer wren.free_vm(&vm)
    
    source := `import "./test_module"`
    result := wren.interpret(vm, "main", source)
    fmt.printf("Result: %v\n", result)
}
