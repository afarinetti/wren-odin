// Example Runner for Wren-Odin Integration
// Demonstrates how to load and execute Wren scripts with Odin integration

package main

import "core:fmt"
import "core:os"
import "core:strings"
import "../wren"

// ============================================================================
// Global State
// ============================================================================

g_output: strings.Builder
g_error_msg: string

// ============================================================================
// Callback Implementations
// ============================================================================

write_fn :: proc(vm: wren.VM, text: string) {
	strings.write_string(&g_output, text)
}

error_fn :: proc(
	vm: wren.VM,
	error_type: wren.ErrorType,
	module: string,
	line: int,
	message: string,
) {
	fmt.printf("ERROR [%s:%d] %s\n", module, line, message)
	g_error_msg = message
}

load_module_fn :: proc(vm: wren.VM, name: string) -> wren.LoadModuleResult {
	// In a real application, load from file system
	// For examples, we return empty source
	return wren.LoadModuleResult{source = ""}
}

// ============================================================================
// Foreign Method Implementations
// ============================================================================

// Input system mock
input_keys: [dynamic]bool
input_mouse_x: f64
input_mouse_y: f64

update_input :: proc(args: []wren.Value) -> wren.Value {
	// Simulate input state
	key_states := make([]wren.Value, 0)
	// Add some mock key states
	key_states = append(key_states, wren.string_value("space"))
	key_states = append(key_states, wren.bool_value(true))

	mouse_state := make([]wren.Value, 0)
	mouse_state = append(mouse_state, wren.string_value("x"))
	mouse_state = append(mouse_state, wren.num_value(input_mouse_x))
	mouse_state = append(mouse_state, wren.string_value("y"))
	mouse_state = append(mouse_state, wren.num_value(input_mouse_y))

	// Build result map
	result_keys := []string{"keys", "mouse"}
	result_values := []wren.Value{
		wren.list_value(key_states),
		wren.list_value(mouse_state),
	}

	return wren.map_value(wren.Map{
		keys:   result_keys,
		values: result_values,
	})
}

// Rendering mock
render_commands: [dynamic]wren.Value

draw_rect :: proc(args: []wren.Value) -> wren.Value {
	x := wren.as_num(args[0])
	y := wren.as_num(args[1])
	w := wren.as_num(args[2])
	h := wren.as_num(args[3])
	// color := args[4] // Would be a Color object

	fmt.printf("DrawRect: (%.0f, %.0f, %.0f, %.0f)\n", x, y, w, h)
	return wren.nil_value()
}

draw_circle :: proc(args: []wren.Value) -> wren.Value {
	cx := wren.as_num(args[0])
	cy := wren.as_num(args[1])
	radius := wren.as_num(args[2])

	fmt.printf("DrawCircle: (%.0f, %.0f, radius=%.0f)\n", cx, cy, radius)
	return wren.nil_value()
}

draw_text :: proc(args: []wren.Value) -> wren.Value {
	text := wren.as_string(args[0])
	x := wren.as_num(args[1])
	y := wren.as_num(args[2])

	fmt.printf("DrawText: '%s' at (%.0f, %.0f)\n", text, x, y)
	return wren.nil_value()
}

flush_render :: proc(args: []wren.Value) -> wren.Value {
	fmt.printf("Flushing %d render commands\n", len(render_commands))
	render_commands = nil
	return wren.nil_value()
}

// Audio mock
play_sound :: proc(args: []wren.Value) -> wren.Value {
	channel := wren.as_string(args[0])
	clip := wren.as_string(args[1])

	fmt.printf("PlaySound: channel='%s', clip='%s'\n", channel, clip)
	return wren.nil_value()
}

stop_all_sounds :: proc(args: []wren.Value) -> wren.Value {
	fmt.println("StopAllSounds")
	return wren.nil_value()
}

// Resource loading mock
load_resource :: proc(args: []wren.Value) -> wren.Value {
	path := wren.as_string(args[0])
	resource_type := wren.as_string(args[1])

	fmt.printf("LoadResource: '%s' (type: %s)\n", path, resource_type)

	// Simulate successful load
	return wren.map_value(wren.Map{
		keys:   []string{"path", "type", "loaded"},
		values: []wren.Value{wren.string_value(path), wren.string_value(resource_type), wren.bool_value(true)},
	})
}

// ============================================================================
// Example Runner
// ============================================================================

run_example :: proc(name: string, source: string) {
	fmt.printf("\n=== Running Example: %s ===\n", name)

	// Reset state
	g_output = strings.Builder{}
	g_error_msg = ""

	// Create VM
	config := wren.make_configuration()
	wren.set_write_fn(&config, write_fn)
	wren.set_error_fn(&config, error_fn)
	wren.set_load_module_fn(&config, load_module_fn)

	vm := wren.new_vm(&config)
	defer wren.free_vm(&vm)

	// Register foreign methods based on example
	switch name {
	case "input":
		wren.register_method(vm, "./input", "Input", "static Input.update(_,_,_)", update_input)
	case "rendering":
		wren.register_method(vm, "./render", "RenderBatcher", "drawRect(_,_,_,_,_)", draw_rect)
		wren.register_method(vm, "./render", "RenderBatcher", "drawCircle(_,_,_,_)", draw_circle)
		wren.register_method(vm, "./render", "RenderBatcher", "drawText(_,_,_,_)", draw_text)
		wren.register_method(vm, "./render", "RenderBatcher", "flush()", flush_render)
	case "audio":
		wren.register_method(vm, "./audio", "AudioManager", "playSound(_,_)", play_sound)
		wren.register_method(vm, "./audio", "AudioManager", "stopAllSounds()", stop_all_sounds)
	case "resources":
		wren.register_method(vm, "./resources", "ResourceManager", "loadResource(_,_)", load_resource)
	}

	// Execute Wren code
	result := wren.interpret(vm, "main", source)

	// Print output
	output := strings.to_string(g_output)
	if len(output) > 0 {
		fmt.print(output)
	}

	// Check result
	if result == .Ok {
		fmt.println("\n✓ Example completed successfully")
	} else {
		fmt.println("\n✗ Example failed")
		if len(g_error_msg) > 0 {
			fmt.printf("Error: %s\n", g_error_msg)
		}
	}
}

// ============================================================================
// Main
// ============================================================================

main :: proc() {
	args := os.args

	if len(args) < 2 {
		fmt.println("Usage: example_runner <example_name>")
		fmt.println("\nAvailable examples:")
		fmt.println("  ecs         - Entity Component System")
		fmt.println("  input       - Input Handling")
		fmt.println("  physics     - Physics Simulation")
		fmt.println("  scene       - Scene Management")
		fmt.println("  audio       - Audio Manager")
		fmt.println("  rendering   - 2D Rendering")
		fmt.println("  resources   - Resource Manager")
		fmt.println("  animation   - Animation System")
		fmt.println("  networking  - Networking")
		os.exit(1)
	}

	example_name := args[1]

	// Load example source
	example_path := fmt.tprintf("examples/%s.wren", example_name)
	source_bytes, err := os.read_entire_file(example_path)

	if err != nil {
		fmt.printf("Error loading example '%s': %s\n", example_name, err)
		os.exit(1)
	}

	source := string(source_bytes)

	// Run the example
	run_example(example_name, source)
}
