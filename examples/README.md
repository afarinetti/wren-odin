# Wren-Odin Game Development Examples

This directory contains comprehensive Wren examples demonstrating typical game development patterns for embedding Wren in Odin applications.

## Examples Overview

### 1. **ecs.wren** - Entity Component System
Demonstrates how to create and manage game entities with components from Wren.

**Key Concepts:**
- Entity creation and management
- Component-based architecture
- Entity queries and filtering
- Data-driven game object design

**Odin Integration Points:**
- Entity storage and queries in Odin
- Component data synchronization
- Performance-critical operations in Odin

---

### 2. **input.wren** - Input Handling
Shows how to handle keyboard, mouse, and gamepad input from Wren.

**Key Concepts:**
- Input state tracking (pressed, released, held)
- Input action mapping system
- Multi-device input support
- Input buffering

**Odin Integration Points:**
- Raw input polling in Odin
- Input state updates each frame
- Platform-specific input handling

---

### 3. **physics.wren** - Physics Simulation
Demonstrates 2D physics with collision detection.

**Key Concepts:**
- Rigidbody dynamics
- Collision detection (circle-circle, box-box)
- Physics world management
- Force application and gravity

**Odin Integration Points:**
- Physics simulation in Odin for performance
- Collision detection in Odin
- Position/velocity synchronization

---

### 4. **scene.wren** - Scene Management
Shows how to organize game scenes and transitions.

**Key Concepts:**
- Scene lifecycle (onEnter, onUpdate, onExit)
- Scene transitions with timing
- Scene manager pattern
- Game state management

**Odin Integration Points:**
- Scene rendering in Odin
- Resource loading per scene
- Transition effects

---

### 5. **audio.wren** - Audio Manager
Demonstrates sound effect and music management.

**Key Concepts:**
- Audio channels and mixing
- Sound effect pooling
- Music playback and looping
- Volume control

**Odin Integration Points:**
- Audio playback via Odin audio library
- Sound loading and caching
- 3D spatial audio

---

### 6. **rendering.wren** - 2D Rendering
Shows how to issue render commands from Wren.

**Key Concepts:**
- Render command batching
- Camera system
- Draw order and z-indexing
- Sprite rendering

**Odin Integration Points:**
- Actual GPU rendering in Odin
- Texture management
- Render batch flushing

---

### 7. **resources.wren** - Resource Manager
Demonstrates async asset loading and caching.

**Key Concepts:**
- Async resource loading
- Resource caching and deduplication
- Loading queues and limits
- Resource lifecycle management

**Odin Integration Points:**
- File I/O in Odin
- Async loading with callbacks
- Memory management

---

### 8. **animation.wren** - Animation System
Shows sprite animation and state-based animation control.

**Key Concepts:**
- Frame-based animation
- Sprite sheet support
- Animation state machine
- Animation blending

**Odin Integration Points:**
- Sprite sheet loading
- Texture atlas management
- Animation playback control

---

### 9. **networking.wren** - Networking
Demonstrates client-server communication.

**Key Concepts:**
- Message-based networking
- Client-server architecture
- Message handlers
- Connection management

**Odin Integration Points:**
- Socket communication in Odin
- Message serialization
- Network threading

---

## How to Use These Examples

### 1. Define Foreign Methods in Odin

```odin
// In your Odin code, register the foreign methods that Wren will call
import "wren"

// Example: Register input polling
wren.register_method(vm, "./input", "Input", "static Input.update(_,_,_)", update_input)

// Example: Register rendering
wren.register_method(vm, "./render", "RenderBatcher", "flush()", flush_render_commands)
```

### 2. Load and Execute Wren Scripts

```odin
// Load Wren source from file or embed it
source := read_file("examples/ecs.wren")

// Execute in Wren VM
result := wren.interpret(vm, "main", source)
if result == .Ok {
    fmt.println("Wren script executed successfully")
}
```

### 3. Call Wren from Odin

```odin
// Call Wren functions from Odin
wren.ensure_slots(vm, 1)
wren.get_variable(vm, "main", "EntityManager", 0)
handle := wren.get_slot_handle(vm, 0)

method_handle := wren.make_call_handle(vm, "createEntity()")
wren.ensure_slots(vm, 1)
wren.set_slot_handle(vm, 0, handle)
wren.call(vm, method_handle)
```

### 4. Implement Foreign Methods

```odin
// Implement foreign methods that Wren calls
update_input :: proc(args: []wren.Value) -> wren.Value {
    // Get key states from Odin's input system
    key_states := get_key_states()
    mouse_state := get_mouse_state()
    gamepad_states := get_gamepad_states()

    // Return as Wren-compatible values
    return wren.map_value({
        "keys": key_states,
        "mouse": mouse_state,
        "gamepads": gamepad_states,
    })
}
```

---

## Architecture Recommendations

### Keep Performance-Critical Code in Odin

```odin
// GOOD: Physics simulation in Odin
physics_update :: proc(deltaTime: f64) {
    // Run physics simulation
    for body in physics_world.bodies {
        body.apply_forces()
        body.integrate(deltaTime)
    }
    physics_world.check_collisions()
}

// GOOD: Expose results to Wren
get_physics_state :: proc(args: []wren.Value) -> wren.Value {
    return serialize_physics_state()
}
```

### Use Wren for Game Logic and Scripting

```wren
// GOOD: Game logic in Wren
class PlayerController {
    static update(player, deltaTime) {
        if (Input.isKeyDown("space") && player.onGround) {
            player.jump()
        }
        if (Input.isKeyDown("left")) {
            player.moveLeft(deltaTime)
        }
    }
}
```

### Synchronize State Between Odin and Wren

```odin
// Odin: Update game state
update_game :: proc(deltaTime: f64) {
    // Update physics in Odin
    physics_world.update(deltaTime)

    // Sync positions to Wren entities
    for entity in wren_entities {
        var body := physics_world.get_body(entity.id)
        entity.set_position(body.position)
        entity.set_velocity(body.velocity)
    }

    // Call Wren update
    call_wren_update(deltaTime)
}
```

---

## Best Practices

1. **Minimize Cross-Boundary Calls**
   - Batch data transfers between Odin and Wren
   - Avoid calling Wren methods in tight loops
   - Pass arrays/maps instead of individual values

2. **Use Value Types Efficiently**
   - Prefer numbers and strings over complex objects
   - Use lists for collections
   - Avoid deep nesting of maps

3. **Handle Errors Gracefully**
   - Check return values from Odin functions
   - Validate data from Wren before processing
   - Provide meaningful error messages

4. **Memory Management**
   - Let Odin own heavy resources (textures, sounds)
   - Use handles/IDs to reference Odin resources from Wren
   - Implement proper cleanup in Wren's finalize methods

5. **Performance**
   - Profile to identify bottlenecks
   - Move hot paths to Odin
   - Use Wren for high-level logic and scripting

---

## Running the Examples

Each example is self-contained and can be run independently:

```bash
# Run a specific example
odin run examples_runner.odin --example=ecs

# Run all examples
odin run examples_runner.odin --all

# Run with debug output
odin run examples_runner.odin --example=physics --debug
```

---

## Extending the Examples

These examples provide a foundation. Extend them for your specific needs:

- **Add more component types** to the ECS example
- **Implement spatial hashing** for physics collision broadphase
- **Add tweening/easing** to the animation system
- **Implement prediction and interpolation** for networking
- **Add shader support** to the rendering system

---

## License

These examples are provided as-is for educational purposes. Adapt them freely for your projects.
