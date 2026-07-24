// Entity Component System (ECS) Example
// Demonstrates how to create and manage game entities from Wren

// Entity represents a game object with components
class Entity {
    construct new(id) {
        _id = id
        _components = {}
    }

    id { _id }

    // Add a component to this entity
    addComponent(name, data) {
        _components[name] = data
        return this
    }

    // Get a component by name
    getComponent(name) {
        return _components[name]
    }

    // Check if entity has a component
    hasComponent(name) {
        return _components.containsKey(name)
    }

    // Remove a component
    removeComponent(name) {
        _components.remove(name)
        return this
    }

    // Get all component names
    componentNames {
        return _components.keys.toList
    }
}

// Component factory for creating common game components
class Component {
    // Create a transform component
    static createTransform(x, y, z) {
        return {
            "type": "transform",
            "position": {"x": x, "y": y, "z": z},
            "rotation": {"x": 0, "y": 0, "z": 0},
            "scale": {"x": 1, "y": 1, "z": 1}
        }
    }

    // Create a sprite component
    static createSprite(texture, width, height) {
        return {
            "type": "sprite",
            "texture": texture,
            "width": width,
            "height": height,
            "visible": true,
            "color": {"r": 255, "g": 255, "b": 255, "a": 255}
        }
    }

    // Create a physics component
    static createPhysics(mass, velocity) {
        return {
            "type": "physics",
            "mass": mass,
            "velocity": velocity,
            "isStatic": false,
            "collider": "box"
        }
    }

    // Create a health component
    static createHealth(maxHealth) {
        return {
            "type": "health",
            "current": maxHealth,
            "max": maxHealth,
            "isAlive": true
        }
    }
}

// EntityManager handles entity creation and queries
class EntityManager {
    construct new() {
        _entities = {}
        _nextId = 1
    }

    // Create a new entity
    createEntity() {
        var entity = Entity.new(_nextId)
        _entities[_nextId] = entity
        _nextId = _nextId + 1
        return entity
    }

    // Get entity by ID
    getEntity(id) {
        return _entities[id]
    }

    // Destroy an entity
    destroyEntity(id) {
        _entities.remove(id)
    }

    // Get all entities
    allEntities {
        return _entities.values.toList
    }

    // Query entities with specific components
    query(componentName) {
        var result = []
        for (entity in _entities.values) {
            if (entity.hasComponent(componentName)) {
                result.add(entity)
            }
        }
        return result
    }

    // Get entity count
    count {
        return _entities.count
    }
}

// Example usage
var manager = EntityManager.new()

// Create a player entity
var player = manager.createEntity()
player.addComponent("transform", Component.createTransform(0, 0, 0))
player.addComponent("sprite", Component.createSprite("player.png", 32, 32))
player.addComponent("health", Component.createHealth(100))
player.addComponent("physics", Component.createPhysics(1.0, {"x": 0, "y": 0, "z": 0}))

// Create an enemy entity
var enemy = manager.createEntity()
enemy.addComponent("transform", Component.createTransform(100, 50, 0))
enemy.addComponent("sprite", Component.createSprite("enemy.png", 32, 32))
enemy.addComponent("health", Component.createHealth(50))

// Query all entities with health component
var entitiesWithHealth = manager.query("health")
System.print("Entities with health: %(entitiesWithHealth.count)")

// Query all entities with transform component
var entitiesWithTransform = manager.query("transform")
System.print("Entities with transform: %(entitiesWithTransform.count)")

// Access entity data
var playerHealth = player.getComponent("health")
System.print("Player health: %(playerHealth["current"])/%(playerHealth["max"])")

var playerTransform = player.getComponent("transform")
System.print("Player position: (%(playerTransform["position"]["x"]), %(playerTransform["position"]["y"]), %(playerTransform["position"]["z"]))")
