package main

import "core:fmt"
import "core:os"
import "core:strings"
import "wren"

g_output_builder: strings.Builder
g_write_called: bool

test_write_fn :: proc(vm: wren.VM, text: string) {
    g_write_called = true
    fmt.printf("Write callback called with: '%s'\n", text)
    strings.write_string(&g_output_builder, text)
}

main :: proc() {
    strings.builder_init(&g_output_builder)
    defer strings.builder_destroy(&g_output_builder)
    
    config := wren.make_configuration()
    wren.set_write_fn(&config, test_write_fn)
    
    vm := wren.new_vm(&config)
    defer wren.free_vm(&vm)
    
    source := `System.print(true)`
    fmt.printf("Interpreting: %s\n", source)
    
    result := wren.interpret(vm, "main", source)
    fmt.printf("Result: %v\n", result)
    fmt.printf("Write called: %v\n", g_write_called)
    fmt.printf("Output: '%s'\n", strings.to_string(g_output_builder))
}
