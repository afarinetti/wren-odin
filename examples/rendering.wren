// Rendering Example
// Demonstrates 2D rendering primitives and sprite batching from Wren

// Color helper
class Color {
    construct new(r, g, b, a) {
        _r = r
        _g = g
        _b = b
        _a = a
    }

    r { _r }
    g { _g }
    b { _b }
    a { _a }

    static white() { Color.new(255, 255, 255, 255) }
    static black() { Color.new(0, 0, 0, 255) }
    static red()   { Color.new(255, 0, 0, 255) }
    static green() { Color.new(0, 255, 0, 255) }
    static blue()  { Color.new(0, 0, 255, 255) }
    static yellow() { Color.new(255, 255, 0, 255) }
    static cyan()  { Color.new(0, 255, 255, 255) }
    static magenta() { Color.new(255, 0, 255, 255) }
    static transparent() { Color.new(0, 0, 0, 0) }

    static lerp(a, b, t) {
        return Color.new(
            a.r + (b.r - a.r) * t,
            a.g + (b.g - a.g) * t,
            a.b + (b.b - a.b) * t,
            a.a + (b.a - a.a) * t
        )
    }
}

// Rectangle for bounding boxes and rendering
class Rect {
    construct new(x, y, w, h) {
        _x = x
        _y = y
        _w = w
        _h = h
    }

    x { _x }
    y { _y }
    w { _w }
    h { _h }
    left   { _x }
    right  { _x + _w }
    top    { _y }
    bottom { _y + _h }
    centerX { _x + _w / 2 }
    centerY { _y + _h / 2 }

    contains(px, py) {
        return px >= _x && px <= _x + _w && py >= _y && py <= _y + _h
    }

    intersects(other) {
        return !(_x + _w < other.x || other.x + other.w < _x ||
                 _y + _h < other.y || other.y + other.h < _y)
    }
}

// Render command that gets batched and sent to Odin
class RenderCommand {
    static TYPE_RECT   { 1 }
    static TYPE_CIRCLE { 2 }
    static TYPE_LINE   { 3 }
    static TYPE_SPRITE { 4 }
    static TYPE_TEXT   { 5 }

    construct new(type, data) {
        _type = type
        _data = data
        _zIndex = 0
    }

    type { _type }
    data { _data }
    zIndex { _zIndex }
    zIndex=(z) { _zIndex = z }
}

// Render batcher that collects draw calls and flushes them to Odin
class RenderBatcher {
    construct new() {
        _commands = []
        _cameraX = 0
        _cameraY = 0
        _screenWidth = 800
        _screenHeight = 600
    }

    cameraX { _cameraX }
    cameraY { _cameraY }
    screenWidth  { _screenWidth }
    screenHeight { _screenHeight }

    cameraX=(x) { _cameraX = x }
    cameraY=(y) { _cameraY = y }
    screenWidth=(w)  { _screenWidth = w }
    screenHeight=(h) { _screenHeight = h }

    drawRect(x, y, w, h, color) {
        _commands.add(RenderCommand.new(RenderCommand.TYPE_RECT, {
            "x": x - _cameraX, "y": y - _cameraY,
            "w": w, "h": h,
            "color": color
        }))
    }

    drawCircle(cx, cy, radius, color) {
        _commands.add(RenderCommand.new(RenderCommand.TYPE_CIRCLE, {
            "cx": cx - _cameraX, "cy": cy - _cameraY,
            "radius": radius,
            "color": color
        }))
    }

    drawLine(x1, y1, x2, y2, color, thickness) {
        var t = thickness
        if (t == null) t = 1
        _commands.add(RenderCommand.new(RenderCommand.TYPE_LINE, {
            "x1": x1 - _cameraX, "y1": y1 - _cameraY,
            "x2": x2 - _cameraX, "y2": y2 - _cameraY,
            "color": color,
            "thickness": t
        }))
    }

    drawSprite(texture, x, y, w, h, flipX, flipY, rotation) {
        var fx = flipX || false
        var fy = flipY || false
        var rot = rotation || 0
        _commands.add(RenderCommand.new(RenderCommand.TYPE_SPRITE, {
            "texture": texture,
            "x": x - _cameraX, "y": y - _cameraY,
            "w": w, "h": h,
            "flipX": fx,
            "flipY": fy,
            "rotation": rot
        }))
    }

    drawText(text, x, y, size, color) {
        var s = size
        if (s == null) s = 16
        var c = color
        if (c == null) c = Color.white()
        _commands.add(RenderCommand.new(RenderCommand.TYPE_TEXT, {
            "text": text,
            "x": x - _cameraX, "y": y - _cameraY,
            "size": s,
            "color": c
        }))
    }

    clear(color) {
        _commands = []
        _commands.add(RenderCommand.new(RenderCommand.TYPE_RECT, {
            "x": 0, "y": 0,
            "w": _screenWidth, "h": _screenHeight,
            "color": color,
            "isClear": true
        }))
    }

    sort() {
        var i = 1
        while (i < _commands.count) {
            var key = _commands[i]
            var j = i - 1
            while (j >= 0 && _commands[j].zIndex > key.zIndex) {
                _commands[j + 1] = _commands[j]
                j = j - 1
            }
            _commands[j + 1] = key
            i = i + 1
        }
    }

    flush() {
        sort()
        var stats = {
            "count": _commands.count,
            "rects": 0,
            "circles": 0,
            "lines": 0,
            "sprites": 0,
            "texts": 0
        }
        for (cmd in _commands) {
            if (cmd.type == RenderCommand.TYPE_RECT)    stats["rects"] = stats["rects"] + 1
            if (cmd.type == RenderCommand.TYPE_CIRCLE)  stats["circles"] = stats["circles"] + 1
            if (cmd.type == RenderCommand.TYPE_LINE)    stats["lines"] = stats["lines"] + 1
            if (cmd.type == RenderCommand.TYPE_SPRITE)  stats["sprites"] = stats["sprites"] + 1
            if (cmd.type == RenderCommand.TYPE_TEXT)    stats["texts"] = stats["texts"] + 1
        }
        _commands = []
        return stats
    }

    commandCount { _commands.count }
}

// Example: Draw a simple scene
var renderer = RenderBatcher.new()
renderer.screenWidth = 800
renderer.screenHeight = 600

renderer.clear(Color.new(30, 30, 40, 255))

var gridSpacing = 50
var gx = 0
while (gx < 800) {
    renderer.drawLine(gx, 0, gx, 600, Color.new(50, 50, 60, 255), 1)
    gx = gx + gridSpacing
}
var gy = 0
while (gy < 600) {
    renderer.drawLine(0, gy, 800, gy, Color.new(50, 50, 60, 255), 1)
    gy = gy + gridSpacing
}

renderer.drawRect(100, 100, 80, 80, Color.red())
renderer.drawRect(200, 150, 60, 60, Color.green())
renderer.drawRect(300, 120, 100, 40, Color.blue())

renderer.drawCircle(500, 200, 40, Color.yellow())
renderer.drawCircle(600, 300, 60, Color.cyan())

renderer.drawLine(50, 400, 750, 400, Color.magenta(), 3)

renderer.drawText("Wren-Odin Rendering Demo", 250, 30, 20, Color.white())
renderer.drawText("FPS: 60", 10, 580, 14, Color.green())
renderer.drawText("Draw calls: " + renderer.commandCount.toString, 10, 560, 14, Color.cyan())

var stats = renderer.flush()
System.print("Render stats:")
System.print("  Total commands: " + stats["count"].toString)
System.print("  Rects: " + stats["rects"].toString)
System.print("  Circles: " + stats["circles"].toString)
System.print("  Lines: " + stats["lines"].toString)
System.print("  Sprites: " + stats["sprites"].toString)
System.print("  Texts: " + stats["texts"].toString)
