// Physics Example
// Demonstrates 2D physics simulation with collision detection

// Vector2D helper class
class Vec2 {
    construct new(x, y) {
        _x = x
        _y = y
    }

    x { _x }
    y { _y }

    x=(v) { _x = v }
    y=(v) { _y = v }

    static add(a, b) {
        return Vec2.new(a.x + b.x, a.y + b.y)
    }

    static sub(a, b) {
        return Vec2.new(a.x - b.x, a.y - b.y)
    }

    static mul(v, scalar) {
        return Vec2.new(v.x * scalar, v.y * scalar)
    }

    static dot(a, b) {
        return a.x * b.x + a.y * b.y
    }

    static length(v) {
        return (v.x * v.x + v.y * v.y).sqrt
    }

    static normalize(v) {
        var len = Vec2.length(v)
        if (len == 0) return Vec2.new(0, 0)
        return Vec2.new(v.x / len, v.y / len)
    }

    static distance(a, b) {
        return Vec2.length(Vec2.sub(a, b))
    }
}

// Rigidbody component for physics simulation
class Rigidbody {
    construct new(mass, position, velocity) {
        _mass = mass
        _position = position
        _velocity = velocity
        _acceleration = Vec2.new(0, 0)
        _isStatic = (mass == 0)
        _forces = []
    }

    mass { _mass }
    position { _position }
    velocity { _velocity }
    isStatic { _isStatic }

    position=(v) { _position = v }
    velocity=(v) { _velocity = v }

    // Add a force to the rigidbody
    addForce(force) {
        if (!_isStatic) {
            _forces.add(force)
        }
    }

    // Apply gravity
    applyGravity(gravity) {
        if (!_isStatic) {
            addForce(Vec2.mul(gravity, _mass))
        }
    }

    // Update physics for this frame
    update(deltaTime) {
        if (_isStatic) return

        // Calculate total force
        var totalForce = Vec2.new(0, 0)
        for (force in _forces) {
            totalForce = Vec2.add(totalForce, force)
        }

        // F = ma, so a = F/m
        var acceleration = Vec2.mul(totalForce, 1.0 / _mass)

        // Update velocity: v = v0 + at
        _velocity = Vec2.add(_velocity, Vec2.mul(acceleration, deltaTime))

        // Update position: p = p0 + vt
        _position = Vec2.add(_position, Vec2.mul(_velocity, deltaTime))

        // Clear forces for next frame
        _forces = []
    }
}

// Collider shapes
class CircleCollider {
    construct new(radius, offset) {
        _radius = radius
        _offset = offset
    }

    radius { _radius }
    offset { _offset }

    // Check collision with another circle
    static checkCollision(a, b, posA, posB) {
        var centerA = Vec2.add(posA, a.offset)
        var centerB = Vec2.add(posB, b.offset)
        var distance = Vec2.distance(centerA, centerB)
        var minDistance = a.radius + b.radius
        return distance < minDistance
    }
}

class BoxCollider {
    construct new(width, height, offset) {
        _width = width
        _height = height
        _offset = offset
    }

    width { _width }
    height { _height }
    offset { _offset }

    // Simple AABB collision check
    static checkCollision(a, b, posA, posB) {
        var centerA = Vec2.add(posA, a.offset)
        var centerB = Vec2.add(posB, b.offset)

        var halfWidthA = a.width / 2
        var halfHeightA = a.height / 2
        var halfWidthB = b.width / 2
        var halfHeightB = b.height / 2

        var overlapX = (halfWidthA + halfWidthB) - (centerB.x - centerA.x).abs
        var overlapY = (halfHeightA + halfHeightB) - (centerB.y - centerA.y).abs

        return overlapX > 0 && overlapY > 0
    }
}

// Physics world that manages all physics objects
class PhysicsWorld {
    construct new(gravity) {
        _gravity = gravity
        _bodies = []
        _colliders = []
    }

    gravity { _gravity }
    gravity=(g) { _gravity = g }

    // Add a rigidbody to the world
    addBody(body, collider) {
        _bodies.add(body)
        _colliders.add({"body": body, "collider": collider})
    }

    // Remove a body from the world
    removeBody(body) {
        var index = 0
        for (item in _colliders) {
            if (item["body"] == body) {
                _colliders.removeAt(index)
                _bodies.removeAt(index)
                return
            }
            index = index + 1
        }
    }

    // Check all collisions and return collision pairs
    checkCollisions() {
        var collisions = []
        var i = 0
        while (i < _colliders.count) {
            var j = i + 1
            while (j < _colliders.count) {
                var a = _colliders[i]
                var b = _colliders[j]

                var collided = false
                if (a["collider"] is CircleCollider && b["collider"] is CircleCollider) {
                    collided = CircleCollider.checkCollision(
                        a["collider"], b["collider"],
                        a["body"].position, b["body"].position
                    )
                } else if (a["collider"] is BoxCollider && b["collider"] is BoxCollider) {
                    collided = BoxCollider.checkCollision(
                        a["collider"], b["collider"],
                        a["body"].position, b["body"].position
                    )
                }

                if (collided) {
                    collisions.add({"a": a["body"], "b": b["body"]})
                }

                j = j + 1
            }
            i = i + 1
        }
        return collisions
    }

    // Update all physics bodies
    update(deltaTime) {
        // Apply forces and update positions
        for (body in _bodies) {
            body.applyGravity(_gravity)
            body.update(deltaTime)
        }

        // Check collisions
        var collisions = checkCollisions()
        return collisions
    }
}

// Example usage
var world = PhysicsWorld.new(Vec2.new(0, 9.8))  // Gravity pointing down

// Create ground (static)
var ground = Rigidbody.new(0, Vec2.new(400, 600), Vec2.new(0, 0))
var groundCollider = BoxCollider.new(800, 50, Vec2.new(0, 0))
world.addBody(ground, groundCollider)

// Create falling ball
var ball = Rigidbody.new(1.0, Vec2.new(400, 100), Vec2.new(50, 0))  // Moving right
var ballCollider = CircleCollider.new(20, Vec2.new(0, 0))
world.addBody(ball, ballCollider)

// Create another ball
var ball2 = Rigidbody.new(1.0, Vec2.new(450, 100), Vec2.new(-30, 0))  // Moving left
var ball2Collider = CircleCollider.new(20, Vec2.new(0, 0))
world.addBody(ball2, ball2Collider)

// Simulate physics for 60 frames (1 second at 60 FPS)
var deltaTime = 1.0 / 60.0
var frame = 0
while (frame < 60) {
    var collisions = world.update(deltaTime)

    if (collisions.count > 0) {
        System.print("Frame %(frame): %(collisions.count) collision(s) detected")
        for (collision in collisions) {
            System.print("  Collision between bodies at (%(collision["a"].position.x), %(collision["a"].position.y)) and (%(collision["b"].position.x), %(collision["b"].position.y))")
        }
    }

    // Print ball positions every 10 frames
    if (frame % 10 == 0) {
        System.print("Frame %(frame): Ball1 at (%(ball.position.x.round), %(ball.position.y.round)), Ball2 at (%(ball2.position.x.round), %(ball2.position.y.round))")
    }

    frame = frame + 1
}
