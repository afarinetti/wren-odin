package main

import "../wren"
import "core:fmt"
import "core:os"
import "core:strings"

// ============================================================================
// Test Infrastructure
// ============================================================================

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
	fmt.printf("ERROR [%s:%d] %s\n", module, line, message)
	g_error_msg = message
}

test_load_module_fn :: proc(vm: wren.VM, name: string) -> wren.LoadModuleResult {
	return wren.LoadModuleResult{source = ""}
}

// ============================================================================
// Foreign Method Implementations for Examples
// ============================================================================

// --- Input System Mock ---

input_update :: proc(args: []wren.Value) -> wren.Value {
	// Simulate input state
	key_states := make([]wren.Value, 4)
	key_states[0] = wren.string_value("space")
	key_states[1] = wren.bool_value(true)
	key_states[2] = wren.string_value("a")
	key_states[3] = wren.bool_value(false)

	mouse_state := make([]wren.Value, 4)
	mouse_state[0] = wren.string_value("x")
	mouse_state[1] = wren.num_value(100)
	mouse_state[2] = wren.string_value("y")
	mouse_state[3] = wren.num_value(200)

	gamepad_states := make([]wren.Value, 0)

	result_keys := []string{"keys", "mouse", "gamepads"}
	result_values := []wren.Value {
		wren.list_value(key_states),
		wren.list_value(mouse_state),
		wren.list_value(gamepad_states),
	}

	return wren.map_value(wren.Map{keys = result_keys, values = result_values})
}

// --- Rendering Mock ---

draw_rect :: proc(args: []wren.Value) -> wren.Value {
	// x := wren.as_num(args[0])
	// y := wren.as_num(args[1])
	// w := wren.as_num(args[2])
	// h := wren.as_num(args[3])
	// color := args[4]
	return wren.nil_value()
}

draw_circle :: proc(args: []wren.Value) -> wren.Value {
	// cx := wren.as_num(args[0])
	// cy := wren.as_num(args[1])
	// radius := wren.as_num(args[2])
	// color := args[3]
	return wren.nil_value()
}

draw_line :: proc(args: []wren.Value) -> wren.Value {
	// x1 := wren.as_num(args[0])
	// y1 := wren.as_num(args[1])
	// x2 := wren.as_num(args[2])
	// y2 := wren.as_num(args[3])
	// color := args[4]
	// thickness := args[5]
	return wren.nil_value()
}

draw_text :: proc(args: []wren.Value) -> wren.Value {
	// text := wren.as_string(args[0])
	// x := wren.as_num(args[1])
	// y := wren.as_num(args[2])
	// size := wren.as_num(args[3])
	// color := args[4]
	return wren.nil_value()
}

flush_render :: proc(args: []wren.Value) -> wren.Value {
	stats_keys := []string{"count", "rects", "circles", "lines", "sprites", "texts"}
	stats_values := []wren.Value {
		wren.num_value(10),
		wren.num_value(3),
		wren.num_value(2),
		wren.num_value(1),
		wren.num_value(0),
		wren.num_value(2),
	}
	return wren.map_value(wren.Map{keys = stats_keys, values = stats_values})
}

// --- Audio Mock ---

audio_play :: proc(args: []wren.Value) -> wren.Value {
	// channel := wren.as_string(args[0])
	// clip := wren.as_string(args[1])
	return wren.nil_value()
}

audio_stop_all :: proc(args: []wren.Value) -> wren.Value {
	return wren.nil_value()
}

// --- Resource Loading Mock ---

resource_load :: proc(args: []wren.Value) -> wren.Value {
	path := wren.as_string(args[0])
	// resource_type := wren.as_string(args[1])

	result_keys := []string{"path", "type", "loaded"}
	result_values := []wren.Value {
		wren.string_value(path),
		wren.string_value("texture"),
		wren.bool_value(true),
	}
	return wren.map_value(wren.Map{keys = result_keys, values = result_values})
}

// ============================================================================
// Helper: Load Wren file
// ============================================================================

load_wren_file :: proc(path: string) -> string {
	data, err := os.read_entire_file_from_path(path, context.allocator)
	if err != nil {
		fmt.printf("Error loading %s: %s\n", path, err)
		os.exit(1)
	}
	return string(data)
}

// ============================================================================
// Helper: Run example test
// ============================================================================

run_example_test :: proc(
	name: string,
	wren_code: string,
	register_methods: proc(vm: wren.VM),
) -> bool {
	fmt.printf("\n--- Testing: %s ---\n", name)

	// Reset state
	g_output_builder = strings.Builder{}
	strings.builder_init(&g_output_builder)
	g_error_msg = ""

	// Create VM
	config := wren.make_configuration()
	wren.set_write_fn(&config, test_write_fn)
	wren.set_error_fn(&config, test_error_fn)
	wren.set_load_module_fn(&config, test_load_module_fn)

	vm := wren.new_vm(&config)
	defer wren.free_vm(&vm)

	// Register foreign methods
	register_methods(vm)

	// Execute Wren code
	result := wren.interpret(vm, "main", wren_code)

	if result != .Ok {
		fmt.printf("  ✗ FAILED: %s\n", g_error_msg)
		return false
	}

	fmt.println("  ✓ PASSED")
	return true
}

// ============================================================================
// Example Test Implementations
// ============================================================================

test_ecs :: proc() -> bool {
	wren_code := load_wren_file("examples/ecs.wren")

	register_methods :: proc(vm: wren.VM) {
		// ECS example doesn't need foreign methods - it's pure Wren
	}

	return run_example_test("ECS (Entity Component System)", wren_code, register_methods)
}

test_input :: proc() -> bool {
	wren_code := load_wren_file("examples/input.wren")

	register_methods :: proc(vm: wren.VM) {
		wren.register_method(vm, "./input", "Input", "static Input.update(_,_,_)", input_update)
	}

	return run_example_test("Input Handling", wren_code, register_methods)
}

test_physics :: proc() -> bool {
	wren_code := load_wren_file("examples/physics.wren")

	register_methods :: proc(vm: wren.VM) {
		// Physics example doesn't need foreign methods - it's pure Wren
	}

	return run_example_test("Physics Simulation", wren_code, register_methods)
}

test_scene :: proc() -> bool {
	wren_code := load_wren_file("examples/scene.wren")

	register_methods :: proc(vm: wren.VM) {
		wren.register_method(vm, "./input", "Input", "static Input.update(_,_,_)", input_update)
	}

	return run_example_test("Scene Management", wren_code, register_methods)
}

test_audio :: proc() -> bool {
	wren_code := load_wren_file("examples/audio.wren")

	register_methods :: proc(vm: wren.VM) {
		wren.register_method(vm, "./audio", "AudioManager", "playSound(_,_)", audio_play)
		wren.register_method(vm, "./audio", "AudioManager", "stopAllSounds()", audio_stop_all)
	}

	return run_example_test("Audio Manager", wren_code, register_methods)
}

test_rendering :: proc() -> bool {
	wren_code := load_wren_file("examples/rendering.wren")

	register_methods :: proc(vm: wren.VM) {
		wren.register_method(vm, "./render", "RenderBatcher", "drawRect(_,_,_,_,_)", draw_rect)
		wren.register_method(vm, "./render", "RenderBatcher", "drawCircle(_,_,_,_)", draw_circle)
		wren.register_method(vm, "./render", "RenderBatcher", "drawLine(_,_,_,_,_,_)", draw_line)
		wren.register_method(vm, "./render", "RenderBatcher", "drawText(_,_,_,_,_)", draw_text)
		wren.register_method(vm, "./render", "RenderBatcher", "flush()", flush_render)
	}

	return run_example_test("2D Rendering", wren_code, register_methods)
}

test_resources :: proc() -> bool {
	wren_code := load_wren_file("examples/resources.wren")

	register_methods :: proc(vm: wren.VM) {
		wren.register_method(
			vm,
			"./resources",
			"ResourceManager",
			"loadResource(_,_)",
			resource_load,
		)
	}

	return run_example_test("Resource Manager", wren_code, register_methods)
}

test_animation :: proc() -> bool {
	wren_code := load_wren_file("examples/animation.wren")

	register_methods :: proc(vm: wren.VM) {
		// Animation example doesn't need foreign methods - it's pure Wren
	}

	return run_example_test("Animation System", wren_code, register_methods)
}

test_networking :: proc() -> bool {
	wren_code := load_wren_file("examples/networking.wren")

	register_methods :: proc(vm: wren.VM) {
		// Networking example doesn't need foreign methods - it's pure Wren
	}

	return run_example_test("Networking", wren_code, register_methods)
}

// ============================================================================
// Main Test
// ============================================================================

main :: proc() {
	fmt.println("=== Wren-Odin Examples Integration Tests ===")
	fmt.println()

	passed := 0
	failed := 0

	// Run all example tests
	if test_ecs() {
		passed += 1
	} else {
		failed += 1
	}

	if test_input() {
		passed += 1
	} else {
		failed += 1
	}

	if test_physics() {
		passed += 1
	} else {
		failed += 1
	}

	if test_scene() {
		passed += 1
	} else {
		failed += 1
	}

	if test_audio() {
		passed += 1
	} else {
		failed += 1
	}

	if test_rendering() {
		passed += 1
	} else {
		failed += 1
	}

	if test_resources() {
		passed += 1
	} else {
		failed += 1
	}

	if test_animation() {
		passed += 1
	} else {
		failed += 1
	}

	if test_networking() {
		passed += 1
	} else {
		failed += 1
	}

	// Summary
	fmt.println()
	fmt.println("=== Test Summary ===")
	fmt.printf("Passed: %d\n", passed)
	fmt.printf("Failed: %d\n", failed)
	fmt.printf("Total:  %d\n", passed + failed)
	fmt.println()

	if failed > 0 {
		fmt.println("✗ Some tests failed!")
		os.exit(1)
	} else {
		fmt.println("✓ All example tests passed!")
	}
}
