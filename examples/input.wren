// Input Handling Example
// Demonstrates how to handle keyboard, mouse, and gamepad input from Wren

// Input manager that interfaces with Odin's input system
class Input {
    // Called from Odin each frame to update input state
    static update(keyStates, mouseState, gamepadStates) {
        System.print("Input.update called")
        System.print("Keys: " + keyStates.count.toString)
        System.print("Mouse: (" + mouseState["x"].toString + ", " + mouseState["y"].toString + ")")
        System.print("Gamepads: " + gamepadStates.count.toString)
    }

    // Keyboard queries
    static isKeyDown(key) {
        return false
    }

    static isKeyPressed(key) {
        return false
    }

    static isKeyReleased(key) {
        return false
    }

    // Mouse queries
    static mouseX { 0 }
    static mouseY { 0 }

    static isMouseButtonDown(button) {
        return false
    }

    static isMouseButtonPressed(button) {
        return false
    }

    static isMouseButtonReleased(button) {
        return false
    }

    // Gamepad queries
    static isGamepadButtonDown(gamepadId, button) {
        return false
    }

    static getGamepadAxis(gamepadId, axis) {
        return 0
    }
}

// Input action system for mapping inputs to game actions
class InputAction {
    construct new(name) {
        _name = name
        _bindings = []
    }

    name { _name }

    bindKey(key) {
        _bindings.add({"type": "key", "value": key})
        return this
    }

    bindMouseButton(button) {
        _bindings.add({"type": "mouse", "value": button})
        return this
    }

    bindGamepadButton(gamepadId, button) {
        _bindings.add({"type": "gamepad", "gamepadId": gamepadId, "value": button})
        return this
    }

    isActive {
        for (binding in _bindings) {
            if (binding["type"] == "key" && Input.isKeyDown(binding["value"])) {
                return true
            } else if (binding["type"] == "mouse" && Input.isMouseButtonDown(binding["value"])) {
                return true
            } else if (binding["type"] == "gamepad" && Input.isGamepadButtonDown(binding["gamepadId"], binding["value"])) {
                return true
            }
        }
        return false
    }

    isPressed {
        for (binding in _bindings) {
            if (binding["type"] == "key" && Input.isKeyPressed(binding["value"])) {
                return true
            } else if (binding["type"] == "mouse" && Input.isMouseButtonPressed(binding["value"])) {
                return true
            }
        }
        return false
    }

    isReleased {
        for (binding in _bindings) {
            if (binding["type"] == "key" && Input.isKeyReleased(binding["value"])) {
                return true
            } else if (binding["type"] == "mouse" && Input.isMouseButtonReleased(binding["value"])) {
                return true
            }
        }
        return false
    }
}

// Example: Define game actions
var moveLeft = InputAction.new("moveLeft").bindKey("a").bindKey("left")
var moveRight = InputAction.new("moveRight").bindKey("d").bindKey("right")
var jump = InputAction.new("jump").bindKey("space").bindMouseButton("left")
var shoot = InputAction.new("shoot").bindKey("f").bindGamepadButton(0, "a")

// Test input system
var mockKeys = {"space": true, "a": false}
var mockMouse = {"x": 100, "y": 200, "buttons": {"left": false}}
var mockGamepads = []

Input.update(mockKeys, mockMouse, mockGamepads)

System.print("")
System.print("Input system initialized")
System.print("Actions defined: moveLeft, moveRight, jump, shoot")
