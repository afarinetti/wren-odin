package main

import "core:fmt"
import "wren"

main :: proc() {
    config: wren.RawConfiguration
    wren.RawInitConfiguration(&config)
    
    vm := wren.RawNewVM(&config)
    if vm == nil {
        fmt.println("ERROR: Failed to create VM")
        return
    }
    
    result := wren.RawInterpret(vm, "main", "System.print(\"Hello from Wren!\")")
    
    wren.RawFreeVM(vm)
    
    if result == .SUCCESS {
        fmt.println("SUCCESS: Raw bindings work!")
    } else {
        fmt.println("ERROR: Interpretation failed")
    }
}
