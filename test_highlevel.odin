package main

import "core:fmt"
import "wren"

main :: proc() {
    fmt.println("=== Testing High-Level Wren API ===")
    
    // Test 1: Basic VM creation and interpretation
    fmt.println("\nTest 1: Basic VM creation and interpretation")
    config := wren.make_configuration()
    vm := wren.new_vm(&config)
    
    result := wren.interpret(vm, "main", "System.print(\"Hello from Wren!\")")
    if result == .Ok {
        fmt.println("✓ Basic interpretation successful")
    } else {
        fmt.println("✗ Basic interpretation failed")
    }
    
    wren.free_vm(&vm)
    
    // Test 2: Write callback
    fmt.println("\nTest 2: Write callback")
    config2 := wren.make_configuration()
    wren.set_write_fn(&config2, my_write_fn)
    vm2 := wren.new_vm(&config2)
    
    wren.interpret(vm2, "main", "System.print(\"Custom write callback\")")
    wren.free_vm(&vm2)
    
    // Test 3: Error callback
    fmt.println("\nTest 3: Error callback")
    config3 := wren.make_configuration()
    wren.set_error_fn(&config3, my_error_fn)
    vm3 := wren.new_vm(&config3)
    
    result3 := wren.interpret(vm3, "main", "var x = ")
    if result3 == .CompileError {
        fmt.println("✓ Compile error detected correctly")
    }
    
    wren.free_vm(&vm3)
    
    // Test 4: Slot operations
    fmt.println("\nTest 4: Slot operations")
    config4 := wren.make_configuration()
    vm4 := wren.new_vm(&config4)
    
    wren.interpret(vm4, "main", "var x = 42")
    
    wren.ensure_slots(vm4, 1)
    wren.get_variable(vm4, "main", "x", 0)
    
    value := wren.get_double(vm4, 0)
    if value == 42.0 {
        fmt.println("✓ Slot operations work correctly")
    } else {
        fmt.printf("✗ Expected 42.0, got %f\n", value)
    }
    
    wren.free_vm(&vm4)
    
    // Test 5: List operations
    fmt.println("\nTest 5: List operations")
    config5 := wren.make_configuration()
    vm5 := wren.new_vm(&config5)
    
    wren.interpret(vm5, "main", "var list = [1, 2, 3, 4, 5]")
    
    wren.ensure_slots(vm5, 2)
    wren.get_variable(vm5, "main", "list", 0)
    
    count := wren.get_list_count(vm5, 0)
    if count == 5 {
        fmt.println("✓ List count correct")
    } else {
        fmt.printf("✗ Expected list count 5, got %d\n", count)
    }
    
    wren.get_list_element(vm5, 0, 2, 1)
    element := wren.get_double(vm5, 1)
    if element == 3.0 {
        fmt.println("✓ List element access correct")
    } else {
        fmt.printf("✗ Expected element 3.0, got %f\n", element)
    }
    
    wren.free_vm(&vm5)
    
    // Test 6: Map operations
    fmt.println("\nTest 6: Map operations")
    config6 := wren.make_configuration()
    vm6 := wren.new_vm(&config6)
    
    wren.interpret(vm6, "main", "var map = {\"a\": 1, \"b\": 2, \"c\": 3}")
    
    wren.ensure_slots(vm6, 3)
    wren.get_variable(vm6, "main", "map", 0)
    
    map_count := wren.get_map_count(vm6, 0)
    if map_count == 3 {
        fmt.println("✓ Map count correct")
    } else {
        fmt.printf("✗ Expected map count 3, got %d\n", map_count)
    }
    
    wren.set_string(vm6, 1, "b")
    wren.get_map_value(vm6, 0, 1, 2)
    map_value := wren.get_double(vm6, 2)
    if map_value == 2.0 {
        fmt.println("✓ Map value access correct")
    } else {
        fmt.printf("✗ Expected map value 2.0, got %f\n", map_value)
    }
    
    wren.free_vm(&vm6)
    
    fmt.println("\n=== All tests completed ===")
}

my_write_fn :: proc(vm: wren.VM, text: string) {
    fmt.printf("[WRITE] %s", text)
}

my_error_fn :: proc(vm: wren.VM, error_type: wren.ErrorType, module: string, line: int, message: string) {
    fmt.printf("[ERROR] Type: %d, Module: %s, Line: %d, Message: %s\n", 
               error_type, module, line, message)
}
