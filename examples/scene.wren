// Scene Management Example
// Demonstrates how to organize game scenes and transitions

// Base scene class that all scenes inherit from
class Scene {
    construct new(name) {
        _name = name
        _entities = []
        _isActive = false
        _onEnterCallbacks = []
        _onExitCallbacks = []
        _onUpdateCallbacks = []
    }

    name { _name }
    isActive { _isActive }

    onEnter() {
        _isActive = true
        for (callback in _onEnterCallbacks) {
            callback.call()
        }
    }

    onExit() {
        _isActive = false
        for (callback in _onExitCallbacks) {
            callback.call()
        }
    }

    update(deltaTime) {
        if (!_isActive) return
        for (callback in _onUpdateCallbacks) {
            callback.call(deltaTime)
        }
        for (entity in _entities) {
            if (entity["onUpdate"] != null) {
                entity["onUpdate"].call(deltaTime)
            }
        }
    }

    addEntity(entity) {
        _entities.add(entity)
        return entity
    }

    removeEntity(entity) {
        var index = 0
        for (e in _entities) {
            if (e == entity) {
                _entities.removeAt(index)
                return
            }
            index = index + 1
        }
    }

    onEnterCallback(callback) {
        _onEnterCallbacks.add(callback)
    }

    onExitCallback(callback) {
        _onExitCallbacks.add(callback)
    }

    onUpdateCallback(callback) {
        _onUpdateCallbacks.add(callback)
    }

    entityCount {
        return _entities.count
    }
}

// Scene manager handles scene transitions
class SceneManager {
    construct new() {
        _scenes = {}
        _currentScene = null
        _nextScene = null
        _transitioning = false
        _transitionDuration = 0.5
        _transitionTimer = 0
    }

    currentScene { _currentScene }

    addScene(scene) {
        _scenes[scene.name] = scene
    }

    getScene(name) {
        return _scenes[name]
    }

    transitionTo(sceneName, duration) {
        if (_scenes[sceneName] == null) {
            System.print("Error: Scene not found: " + sceneName)
            return
        }

        _nextScene = _scenes[sceneName]
        _transitionDuration = duration
        _transitionTimer = 0
        _transitioning = true
    }

    update(deltaTime) {
        if (_transitioning) {
            _transitionTimer = _transitionTimer + deltaTime

            if (_transitionTimer >= _transitionDuration) {
                if (_currentScene != null) {
                    _currentScene.onExit()
                }
                _currentScene = _nextScene
                _currentScene.onEnter()
                _transitioning = false
                _nextScene = null
                _transitionTimer = 0
                System.print("Transitioned to scene: " + _currentScene.name)
            }
        } else if (_currentScene != null) {
            _currentScene.update(deltaTime)
        }
    }

    isTransitioning {
        return _transitioning
    }

    transitionProgress {
        if (!_transitioning) return 0
        return (_transitionTimer / _transitionDuration).min(1.0)
    }
}

// Initialize scene manager
var sceneManager = SceneManager.new()

// Create scenes
var menuScene = Scene.new("MainMenu")
menuScene.onEnterCallback {
    System.print("=== Main Menu ===")
    System.print("1. Start Game")
    System.print("2. Settings")
    System.print("3. Quit")
}

var gameScene = Scene.new("Game")
gameScene.onEnterCallback {
    System.print("=== Game Scene ===")
    System.print("Loading level...")
}

var settingsScene = Scene.new("Settings")
settingsScene.onEnterCallback {
    System.print("=== Settings ===")
    System.print("Volume: 80 percent")
    System.print("Graphics: High")
    System.print("Press ESC to go back")
}

// Register scenes
sceneManager.addScene(menuScene)
sceneManager.addScene(gameScene)
sceneManager.addScene(settingsScene)

// Start with main menu
sceneManager.transitionTo("MainMenu", 0)

// Simulate game loop
var deltaTime = 1.0 / 60.0
var frame = 0
while (frame < 180) {
    sceneManager.update(deltaTime)

    if (frame == 60) {
        System.print("")
        System.print("[Simulating: Press 1 to start game]")
        sceneManager.transitionTo("Game", 1.0)
    }

    if (frame == 120) {
        System.print("")
        System.print("[Simulating: Press ESC to go back]")
        sceneManager.transitionTo("MainMenu", 0.5)
    }

    frame = frame + 1
}

System.print("")
System.print("Scene management demo complete")
