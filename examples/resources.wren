// Resource Manager Example
// Demonstrates how to load, cache, and manage game assets from Wren

// Resource handle that tracks loading state
class ResourceHandle {
    construct new(path, type) {
        _path = path
        _type = type
        _state = 1
        _data = null
        _error = null
        _loadTime = 0
    }

    path { _path }
    type { _type }
    state { _state }
    data { _data }
    error { _error }
    loadTime { _loadTime }

    isLoaded  { _state == 2 }
    isLoading { _state == 1 }
    isError   { _state == 3 }

    state=(s) { _state = s }
    data=(d) { _data = d }
    error=(e) { _error = e }
    loadTime=(t) { _loadTime = t }

    markLoaded(data, loadTime) {
        _state = 2
        _data = data
        _loadTime = loadTime
    }

    markError(error) {
        _state = 3
        _error = error
    }
}

// Resource manager with async loading and caching
class ResourceManager {
    construct new() {
        _cache = {}
        _loadingQueue = []
        _loadedCallbacks = {}
        _maxConcurrentLoads = 4
        _activeLoads = 0
    }

    load(path, type, callback) {
        if (_cache[path] != null) {
            var handle = _cache[path]
            if (handle.isLoaded) {
                if (callback != null) {
                    callback.call(handle.data)
                }
                return handle
            }
        }

        var handle = ResourceHandle.new(path, type)
        _cache[path] = handle

        _loadingQueue.add({"handle": handle, "callback": callback})

        processQueue()

        return handle
    }

    processQueue() {
        while (_activeLoads < _maxConcurrentLoads && _loadingQueue.count > 0) {
            var item = _loadingQueue.removeAt(0)
            _activeLoads = _activeLoads + 1

            System.print("Loading: " + item["handle"].path)

            simulateLoad(item["handle"], item["callback"])
        }
    }

    simulateLoad(handle, callback) {
        var loadTime = 0.1

        handle.markLoaded({"path": handle.path, "type": handle.type}, loadTime)
        _activeLoads = _activeLoads - 1

        if (callback != null) {
            callback.call(handle.data)
        }

        processQueue()
    }

    get(path) {
        var handle = _cache[path]
        if (handle == null) return null
        if (!handle.isLoaded) return null
        return handle.data
    }

    isLoaded(path) {
        var handle = _cache[path]
        if (handle == null) return false
        return handle.isLoaded
    }

    unload(path) {
        var handle = _cache[path]
        if (handle != null) {
            _cache.remove(path)
            System.print("Unloaded: " + path)
        }
    }

    unloadAll() {
        for (path in _cache.keys) {
            unload(path)
        }
    }

    stats {
        var loaded = 0
        var loading = 0
        var errors = 0
        for (handle in _cache.values) {
            if (handle.isLoaded)  loaded = loaded + 1
            if (handle.isLoading) loading = loading + 1
            if (handle.isError)   errors = errors + 1
        }
        return {
            "total": _cache.count,
            "loaded": loaded,
            "loading": loading,
            "errors": errors,
            "queueSize": _loadingQueue.count,
            "activeLoads": _activeLoads
        }
    }
}

// Example: Load game assets
var resources = ResourceManager.new()

resources.load("assets/textures/player.png", "texture") { |data|
    System.print("Loaded player texture: " + data["path"])
}

resources.load("assets/textures/enemy.png", "texture") { |data|
    System.print("Loaded enemy texture: " + data["path"])
}

resources.load("assets/textures/background.png", "texture") { |data|
    System.print("Loaded background texture: " + data["path"])
}

resources.load("assets/sfx/jump.wav", "audio") { |data|
    System.print("Loaded jump sound: " + data["path"])
}

resources.load("assets/sfx/explosion.wav", "audio") { |data|
    System.print("Loaded explosion sound: " + data["path"])
}

resources.load("assets/music/bgm.wav", "audio") { |data|
    System.print("Loaded BGM: " + data["path"])
}

resources.load("assets/levels/level1.json", "data") { |data|
    System.print("Loaded level 1: " + data["path"])
}

var stats = resources.stats
System.print("")
System.print("Resource Stats:")
System.print("  Total: " + stats["total"].toString)
System.print("  Loaded: " + stats["loaded"].toString)
System.print("  Loading: " + stats["loading"].toString)
System.print("  Errors: " + stats["errors"].toString)

var playerTex = resources.get("assets/textures/player.png")
if (playerTex != null) {
    System.print("")
    System.print("Player texture loaded: " + playerTex["path"])
}

resources.unload("assets/textures/background.png")

stats = resources.stats
System.print("")
System.print("After unload:")
System.print("  Total: " + stats["total"].toString)
System.print("  Loaded: " + stats["loaded"].toString)
