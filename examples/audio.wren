// Audio Manager Example
// Demonstrates how to manage sound effects and music from Wren

// Audio clip representation
class AudioClip {
    construct new(name, path, volume, loop) {
        _name = name
        _path = path
        _volume = volume
        _loop = loop
        _isPlaying = false
        _position = 0
        _duration = 0
    }

    name { _name }
    path { _path }
    volume { _volume }
    loop { _loop }
    isPlaying { _isPlaying }
    position { _position }
    duration { _duration }

    volume=(v) { _volume = v.max(0).min(1) }
    isPlaying=(v) { _isPlaying = v }
    position=(v) { _position = v }
}

// Audio channel for mixing
class AudioChannel {
    construct new(name, maxVoices) {
        _name = name
        _maxVoices = maxVoices
        _voices = []
        _muted = false
        _volume = 1.0
    }

    name { _name }
    muted { _muted }
    volume { _volume }

    muted=(m) { _muted = m }
    volume=(v) { _volume = v.max(0).min(1) }

    play(clip) {
        if (_voices.count >= _maxVoices) {
            _voices.removeAt(0)
        }
        _voices.add({
            "clip": clip,
            "volume": clip.volume * _volume,
            "position": 0,
            "playing": true
        })
        clip.isPlaying = true
    }

    stopAll() {
        for (voice in _voices) {
            voice["clip"].isPlaying = false
        }
        _voices = []
    }

    update(deltaTime) {
        if (_muted) return

        var i = 0
        while (i < _voices.count) {
            var voice = _voices[i]
            if (voice["playing"]) {
                voice["position"] = voice["position"] + deltaTime
                voice["clip"].position = voice["position"]

                if (voice["position"] >= voice["clip"].duration) {
                    if (voice["clip"].loop) {
                        voice["position"] = 0
                    } else {
                        voice["playing"] = false
                        voice["clip"].isPlaying = false
                    }
                }
            }

            if (!voice["playing"]) {
                _voices.removeAt(i)
            } else {
                i = i + 1
            }
        }
    }

    voiceCount {
        return _voices.count
    }
}

// Audio manager that coordinates all audio
class AudioManager {
    construct new() {
        _channels = {}
        _clips = {}
        _masterVolume = 1.0
        _initialized = false
    }

    masterVolume { _masterVolume }
    masterVolume=(v) { _masterVolume = v.max(0).min(1) }

    init() {
        addChannel("sfx", 16)
        addChannel("music", 2)
        addChannel("ambient", 4)
        addChannel("ui", 8)
        _initialized = true
        System.print("AudioManager initialized")
    }

    addChannel(name, maxVoices) {
        _channels[name] = AudioChannel.new(name, maxVoices)
    }

    getChannel(name) {
        return _channels[name]
    }

    loadClip(name, path, volume, loop) {
        _clips[name] = AudioClip.new(name, path, volume, loop)
    }

    getClip(name) {
        return _clips[name]
    }

    play(channelName, clipName) {
        var channel = _channels[channelName]
        var clip = _clips[clipName]

        if (channel == null) {
            System.print("Error: Channel not found: " + channelName)
            return
        }
        if (clip == null) {
            System.print("Error: Clip not found: " + clipName)
            return
        }

        channel.play(clip)
    }

    stopChannel(channelName) {
        var channel = _channels[channelName]
        if (channel != null) {
            channel.stopAll()
        }
    }

    stopAll() {
        for (channel in _channels.values) {
            channel.stopAll()
        }
    }

    update(deltaTime) {
        if (!_initialized) return

        for (channel in _channels.values) {
            channel.update(deltaTime)
        }
    }

    stats {
        var totalVoices = 0
        var channelStats = {}
        for (channel in _channels.values) {
            totalVoices = totalVoices + channel.voiceCount
            channelStats[channel.name] = channel.voiceCount
        }
        return {
            "totalVoices": totalVoices,
            "channels": channelStats,
            "masterVolume": _masterVolume
        }
    }
}

// Example usage
var audio = AudioManager.new()
audio.init()

audio.loadClip("explosion", "assets/sfx/explosion.wav", 0.8, false)
audio.loadClip("jump", "assets/sfx/jump.wav", 0.6, false)
audio.loadClip("bgm", "assets/music/battle.wav", 0.5, true)
audio.loadClip("rain", "assets/ambient/rain.wav", 0.3, true)

audio.play("sfx", "explosion")
audio.play("sfx", "jump")
audio.play("music", "bgm")
audio.play("ambient", "rain")

var deltaTime = 1.0 / 60.0
var frame = 0
while (frame < 10) {
    audio.update(deltaTime)

    if (frame == 5) {
        audio.play("sfx", "explosion")
    }

    frame = frame + 1
}

var stats = audio.stats
System.print("")
System.print("Audio Stats:")
System.print("  Total active voices: " + stats["totalVoices"].toString)
System.print("  Master volume: " + stats["masterVolume"].toString)
for (name in stats["channels"].keys) {
    System.print("  Channel '" + name + "': " + stats["channels"][name].toString + " voices")
}
