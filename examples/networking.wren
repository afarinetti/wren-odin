// Networking Example
// Demonstrates client-server communication and message handling

// Network message types
class NetworkMessage {
    construct new(type, data) {
        _type = type
        _data = data
        _timestamp = 0
        _senderId = 0
    }

    type { _type }
    data { _data }
    timestamp { _timestamp }
    senderId { _senderId }

    timestamp=(t) { _timestamp = t }
    senderId=(id) { _senderId = id }
}

// Network client that connects to a server
class NetworkClient {
    construct new() {
        _connected = false
        _serverAddress = ""
        _serverPort = 0
        _clientId = 0
        _messageHandlers = {}
        _outgoingQueue = []
        _incomingQueue = []
        _ping = 0
        _lastPingTime = 0
    }

    connected { _connected }
    clientId { _clientId }
    ping { _ping }

    connect(address, port, callback) {
        _serverAddress = address
        _serverPort = port

        System.print("Connecting to " + address + ":" + port.toString + "...")

        _connected = true
        _clientId = 12345

        if (callback != null) {
            callback.call(true)
        }
        System.print("Connected! Client ID: " + _clientId.toString)
    }

    disconnect() {
        if (!_connected) return

        sendMessage(NetworkMessage.new(2, {}))

        _connected = false
        System.print("Disconnected from server")
    }

    sendMessage(message) {
        if (!_connected) {
            System.print("Error: Not connected")
            return
        }

        _outgoingQueue.add(message)
    }

    onMessage(type, handler) {
        _messageHandlers[type] = handler
    }

    processMessages() {
        for (message in _incomingQueue) {
            var handler = _messageHandlers[message.type]
            if (handler != null) {
                handler.call(message)
            }
        }
        _incomingQueue = []
    }

    simulateIncomingMessage(message) {
        _incomingQueue.add(message)
    }

    update(deltaTime) {
        if (!_connected) return

        _lastPingTime = _lastPingTime + deltaTime
        if (_lastPingTime >= 1.0) {
            _lastPingTime = 0
            sendMessage(NetworkMessage.new(1, {"ping": true}))
        }

        processMessages()
    }
}

// Network server that handles multiple clients
class NetworkServer {
    construct new() {
        _running = false
        _port = 0
        _clients = {}
        _nextClientId = 1
        _messageHandlers = {}
    }

    running { _running }
    clientCount { _clients.count }

    startServer(port) {
        _port = port
        _running = true

        System.print("Server started on port " + port.toString)
    }

    stopServer() {
        if (!_running) return

        for (clientId in _clients.keys) {
            _clients.remove(clientId)
        }

        _running = false
        System.print("Server stopped")
    }

    onClientConnect(clientId, address) {
        _clients[clientId] = {
            "id": clientId,
            "address": address,
            "connectedAt": 0,
            "lastPing": 0
        }
        System.print("Client " + clientId.toString + " connected from " + address)
    }

    onClientDisconnect(clientId) {
        _clients.remove(clientId)
        System.print("Client " + clientId.toString + " disconnected")
    }

    broadcast(message) {
        for (client in _clients.values) {
            // In real implementation, call Odin to send to client
        }
    }

    sendToClient(clientId, message) {
        if (_clients[clientId] == null) {
            System.print("Error: Client " + clientId.toString + " not found")
            return
        }
    }

    onMessage(type, handler) {
        _messageHandlers[type] = handler
    }

    processMessages() {
        // In real implementation, this would be called from Odin
    }

    update(deltaTime) {
        if (!_running) return
        processMessages()
    }
}

// Example: Chat application
System.print("=== Network Chat Example ===")
System.print("")

var server = NetworkServer.new()
server.startServer(8080)

var client = NetworkClient.new()

client.onMessage(3) { |message|
    System.print("[Chat] " + message.data["sender"] + ": " + message.data["text"])
}

client.onMessage(4) { |message|
    System.print("[PlayerPos] Player " + message.senderId.toString + " at (" + message.data["x"].toString + ", " + message.data["y"].toString + ")")
}

client.connect("localhost", 8080) { |success|
    if (success) {
        System.print("Successfully connected to server")

        var chatMsg = NetworkMessage.new(3, {
            "sender": "Player1",
            "text": "Hello everyone!"
        })
        client.sendMessage(chatMsg)

        var posMsg = NetworkMessage.new(4, {
            "x": 100,
            "y": 200
        })
        client.sendMessage(posMsg)
    }
}

System.print("")
System.print("--- Simulating server processing ---")
server.onClientConnect(client.clientId, "127.0.0.1")

var incomingChat = NetworkMessage.new(3, {
    "sender": "Player2",
    "text": "Hi Player1!"
})
incomingChat.senderId = 67890
client.simulateIncomingMessage(incomingChat)

var incomingPos = NetworkMessage.new(4, {
    "x": 300,
    "y": 400
})
incomingPos.senderId = 67890
client.simulateIncomingMessage(incomingPos)

client.update(0.016)

var chatMsg2 = NetworkMessage.new(3, {
    "sender": "Player1",
    "text": "Nice to meet you!"
})
client.sendMessage(chatMsg2)

System.print("")
System.print("--- Server stats ---")
System.print("Server running: " + server.running.toString)
System.print("Connected clients: " + server.clientCount.toString)
System.print("Client connected: " + client.connected.toString)
System.print("Client ID: " + client.clientId.toString)
System.print("Ping: " + client.ping.toString + "ms")

client.disconnect()
server.stopServer()
