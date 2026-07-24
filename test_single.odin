package main

import "./wren"
import "core:fmt"
import "core:os"
import "core:strings"

g_output_builder: strings.Builder
g_error_msg: string

test_write_fn :: proc(vm: wren.VM, text: string) {
	strings.write_string(&g_output_builder, text)
}

test_error_fn :: proc(
	vm: wren.VM,
	error_type: wren.ErrorType,
	module: string,
	line: int,
	message: string,
) {
	if error_type == .Runtime || error_type == .Compile {
		g_error_msg = message
	}
}

main :: proc() {
	fmt.println("Testing single file...")
	
	strings.builder_init(&g_output_builder)
	
	content, err := os.read_entire_file_from_path(
		"vendor/wren/test/core/bool/bool.wren",
		context.allocator,
	)
	if err != os.ERROR_NONE {
		fmt.printf("Failed to read file: %v\n", err)
		return
	}
	defer delete(content)
	
	content_bytes := make([]byte, len(content))
	for i in 0 ..< len(content) {
		content_bytes[i] = content[i]
	}
	content_str := string(content_bytes)
	
	fmt.printf("Read %d bytes\n", len(content_str))
	
	config := wren.make_configuration()
	wren.set_write_fn(&config, test_write_fn)
	wren.set_error_fn(&config, test_error_fn)
	
	fmt.println("Created configuration")
	
	vm := wren.new_vm(&config)
	fmt.println("Created VM")
	
	result := wren.interpret(vm, "./test/core/bool/bool", content_str)
	fmt.printf("Interpret result: %v\n", result)
	
	output := strings.to_string(g_output_builder)
	fmt.printf("Output: %s\n", output)
	
	wren.free_vm(&vm)
	fmt.println("Done!")
}
