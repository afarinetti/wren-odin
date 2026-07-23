package main

import "core:fmt"
import "wren"

test_load_fn :: proc(vm: wren.VM, name: string) -> wren.LoadModuleResult {
    fmt.printf("Loading module: '%s'\n", name)
    return wren.LoadModuleResult{source = ""}
}

main :: proc() {
    config := wren.make_configuration()
    wren.set_load_module_fn(&config, test_load_fn)
    
    vm := wren.new_vm(&config)
    defer wren.free_vm(&vm)
    
    source := `import "./test_module"`
    wren.interpret(vm, "main", source)
}
