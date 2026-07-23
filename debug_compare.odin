package main

import "core:fmt"
import "core:os"
import "core:strings"
import "wren"

g_output_builder: strings.Builder

test_write_fn :: proc(vm: wren.VM, text: string) {
    strings.write_string(&g_output_builder, text)
}

main :: proc() {
    strings.builder_init(&g_output_builder)
    defer strings.builder_destroy(&g_output_builder)
    
    config := wren.make_configuration()
    wren.set_write_fn(&config, test_write_fn)
    
    vm := wren.new_vm(&config)
    defer wren.free_vm(&vm)
    
    source := `System.print(true)
System.print(true)
System.print(false)
System.print(true)`
    
    wren.interpret(vm, "main", source)
    
    actual := strings.to_string(g_output_builder)
    fmt.printf("Actual bytes: %d\n", len(actual))
    for i in 0..<len(actual) {
        fmt.printf("%d: %d ('%c')\n", i, actual[i], actual[i])
    }
}
