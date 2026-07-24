// Animation System Example
// Demonstrates sprite animation and state-based animation control

class AnimFrame {
    construct new(texture, x, y, w, h, duration) {
        _texture = texture
        _x = x
        _y = y
        _w = w
        _h = h
        _duration = duration
    }

    texture { _texture }
    x { _x }
    y { _y }
    w { _w }
    h { _h }
    duration { _duration }
}

class AnimClip {
    construct new(name, loop, frameRate) {
        _name = name
        _frames = []
        _loop = loop
        _frameRate = frameRate
        _currentTime = 0
        _currentFrameIndex = 0
        _playing = false
    }

    name { _name }
    loop { _loop }
    frameRate { _frameRate }
    isPlaying { _playing }
    frameCount { _frames.count }

    currentFrame {
        if (_frames.count == 0) return null
        return _frames[_currentFrameIndex]
    }

    addFrame(texture, x, y, w, h, duration) {
        _frames.add(AnimFrame.new(texture, x, y, w, h, duration))
    }

    addSpriteSheetFrames(texture, startX, startY, frameW, frameH, frameCount, duration, direction) {
        var dir = direction
        if (dir == null) dir = "right"
        var i = 0
        while (i < frameCount) {
            var x = startX
            var y = startY

            if (dir == "right") {
                x = startX + i * frameW
            } else if (dir == "down") {
                y = startY + i * frameH
            } else if (dir == "left") {
                x = startX - i * frameW
            } else if (dir == "up") {
                y = startY - i * frameH
            }

            addFrame(texture, x, y, frameW, frameH, duration)
            i = i + 1
        }
    }

    play() {
        _playing = true
        _currentTime = 0
        _currentFrameIndex = 0
    }

    stop() {
        _playing = false
    }

    reset() {
        _currentTime = 0
        _currentFrameIndex = 0
    }

    update(deltaTime) {
        if (!_playing) return

        _currentTime = _currentTime + deltaTime

        var frameDuration = 1.0 / _frameRate
        if (_currentTime >= frameDuration) {
            _currentTime = _currentTime - frameDuration
            _currentFrameIndex = _currentFrameIndex + 1

            if (_currentFrameIndex >= _frames.count) {
                if (_loop) {
                    _currentFrameIndex = 0
                } else {
                    _currentFrameIndex = _frames.count - 1
                    _playing = false
                }
            }
        }
    }

    currentFrameData {
        if (_frames.count == 0) return null
        var frame = _frames[_currentFrameIndex]
        return {
            "texture": frame.texture,
            "x": frame.x,
            "y": frame.y,
            "w": frame.w,
            "h": frame.h
        }
    }

    currentFrameNumber {
        return _currentFrameIndex + 1
    }
}

class Animator {
    construct new() {
        _clips = {}
        _currentClip = null
        _direction = "idle"
    }

    currentClip { _currentClip }
    direction { _direction }

    addClip(name, clip) {
        _clips[name] = clip
    }

    play(name) {
        if (_clips[name] == null) {
            System.print("Error: Animation not found: " + name)
            return
        }

        if (_currentClip != null) {
            _currentClip.stop()
        }

        _currentClip = _clips[name]
        _currentClip.play()
    }

    setDirection(dir) {
        _direction = dir
    }

    update(deltaTime) {
        if (_currentClip != null) {
            _currentClip.update(deltaTime)
        }
    }

    currentFrameData {
        if (_currentClip == null) return null
        return _currentClip.currentFrameData
    }
}

// Example: Create character animations
var animator = Animator.new()

var idleClip = AnimClip.new("idle", true, 8)
idleClip.addSpriteSheetFrames("player_sprites", 0, 0, 32, 32, 4, 0.125, "right")
animator.addClip("idle", idleClip)

var walkClip = AnimClip.new("walk", true, 12)
walkClip.addSpriteSheetFrames("player_sprites", 0, 32, 32, 32, 8, 0.083, "right")
animator.addClip("walk", walkClip)

var jumpClip = AnimClip.new("jump", false, 10)
jumpClip.addSpriteSheetFrames("player_sprites", 0, 64, 32, 32, 4, 0.1, "right")
animator.addClip("jump", jumpClip)

var attackClip = AnimClip.new("attack", false, 15)
attackClip.addSpriteSheetFrames("player_sprites", 0, 96, 32, 32, 6, 0.067, "right")
animator.addClip("attack", attackClip)

animator.play("idle")

var deltaTime = 1.0 / 60.0
var frame = 0
var state = "idle"

System.print("Animation Demo:")
System.print("Starting with idle animation")
System.print("")

while (frame < 180) {
    animator.update(deltaTime)

    if (frame == 60 && state == "idle") {
        System.print("Frame 60: Start walking")
        animator.play("walk")
        state = "walk"
    } else if (frame == 120 && state == "walk") {
        System.print("Frame 120: Jump!")
        animator.play("jump")
        state = "jump"
    } else if (frame == 150 && state == "jump") {
        System.print("Frame 150: Attack!")
        animator.play("attack")
        state = "attack"
    }

    if (frame % 30 == 0 && animator.currentClip != null) {
        System.print("Frame " + frame.toString + ": Playing '" + animator.currentClip.name + "', frame " + animator.currentClip.currentFrameNumber.toString + "/" + animator.currentClip.frameCount.toString)
    }

    frame = frame + 1
}

System.print("")
System.print("Animation complete!")
