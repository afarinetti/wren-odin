package main

import "core:fmt"
import "core:os"
import "core:strings"
import "wren"

test_write_fn :: proc(vm: wren.VM, text: string) {
    fmt.print(text)
}

test_error_fn :: proc(vm: wren.VM, error_type: wren.ErrorType, module: string, line: int, message: string) {
    fmt.printf("Error: %s\n", message)
}

test_resolve_module_fn :: proc(vm: wren.VM, importer: string, name: string) -> string {
    if len(name) >= 2 && name[0] == '.' && name[1] == '/' {
        result := make([]byte, len(name) - 2)
        for i in 0 ..< len(name) - 2 {
            result[i] = name[i + 2]
        }
        return string(result)
    }
    result := make([]byte, len(name))
    for i in 0 ..< len(name) {
        result[i] = name[i]
    }
    return string(result)
}

test_load_module_fn :: proc(vm: wren.VM, name: string) -> wren.LoadModuleResult {
    path, path_err := strings.concatenate({"vendor/wren/test/", name, ".wren"}, context.allocator)
    if path_err != nil {
        return wren.LoadModuleResult{source = ""}
    }
    defer delete(path)
    
    content, content_err := os.read_entire_file_from_path(path, context.allocator)
    if content_err != os.ERROR_NONE {
        return wren.LoadModuleResult{source = ""}
    }
    defer delete(content)
    
    content_bytes := make([]byte, len(content))
    for i in 0 ..< len(content) {
        content_bytes[i] = content[i]
    }
    
    return wren.LoadModuleResult{source = string(content_bytes)}
}

main :: proc() {
    config := wren.make_configuration()
    wren.set_write_fn(&config, test_write_fn)
    wren.set_error_fn(&config, test_error_fn)
    wren.set_load_module_fn(&config, test_load_module_fn)
    wren.set_resolve_module_fn(&config, test_resolve_module_fn)
    
    vm := wren.new_vm(&config)
    defer wren.free_vm(&vm)
    
    content, err := os.read_entire_file_from_path("vendor/wren/test/core/bool/type.wren", context.allocator)
    if err != os.ERROR_NONE {
        fmt.println("Failed to read file")
        return
    }
    defer delete(content)
    
    content_bytes := make([]byte, len(content))
    for i in 0 ..< len(content) {
        content_bytes[i] = content[i]
    }
    
    result := wren.interpret(vm, "main", string(content_bytes))
    fmt.printf("\nResult: %v\n", result)
}
