//
//  ChatServer.swift
//  ChatServer
//
//  Created by Marco Masser on 2016-03-11.
//  Copyright © 2016 Objective Development Software GmbH. All rights reserved.
//

import Foundation

class ChatServer: ServerSocketType {
    
    let socket: Socket
    let address: SocketAddress
    var acceptSource: SocketDispatchSource?
    var chatClients = [ConnectedChatClient]()

    required init(socket: Socket, address: SocketAddress) {
        self.socket = socket
        self.address = address
    }

    deinit {
        stop()
    }

}

extension ChatServer {

    func start() throws {
        try bind()
        try listen()

        acceptSource = acceptAsync {
            self.acceptChatClient()
        }
    }

    func stop() {
		broadcast(message: "Stopping chat server")
        acceptSource?.cancel()
        acceptSource = nil

        _ = try? close()

        for client in chatClients {
			disconnect(client: client, broadcastToOthers: false)
        }
    }

    func log(message: String, terminator: String = "\n") {
        print(message, terminator: terminator)
    }

}

extension ChatServer {

    func acceptChatClient() {
        do {
            let client = try accept { socket, address in
                return try ConnectedChatClient(socket: socket, address: address)
            }
            client.receiveSource = client.receiveAsync {
                self.handlePendingMessage(from: client)
            }
            chatClients.append(client)
			broadcast(message: "\(client) connected")
        } catch {
			log(message: "Error handling new client: \(error)")
        }
    }

    func handlePendingMessage(from client: ConnectedChatClient) {
        do {
            guard let message = try client.receiveUTF8String() else {
				send(message: "Invalid message received", to: client, ignoringErrors: true)
				disconnect(client: client)
                return
            }
			
            let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
			if !handleCommand(command: trimmedMessage.lowercased(), from: client) && !trimmedMessage.isEmpty {
				broadcast(message: trimmedMessage, from: client)
            }
        } catch Socket.POSIXError.ConnectionClosed {
			disconnect(client: client)
        } catch {
			log(message: "Error handling message from: \(client): \(error)")
			disconnect(client: client)
        }
    }

    func send(message: String, to client: ConnectedChatClient, ignoringErrors: Bool = false) {
        do {
			log(message: "Sending to \(client): \(message)")
			try client.send(message: message + "\n")
        } catch {
            if !ignoringErrors {
				log(message: "Error sending message to: \(client), message: \(message)")
				disconnect(client: client)
            }
        }
    }

    func broadcast(message: String, from sender: ConnectedChatClient? = nil) {
        let serverName = "Server"
        let broadcastMessage = "\(sender?.description ?? serverName): \(message)\n"
		log(message: broadcastMessage, terminator: "")

        for receiver in chatClients where receiver != sender {
            do {
				try receiver.send(message: broadcastMessage)
            } catch {
				log(message: "Error broadcasting message to: \(receiver)")
				disconnect(client: receiver)
            }
        }
    }

    func disconnect(client: ConnectedChatClient, broadcastToOthers: Bool = true) {
        if broadcastToOthers {
			broadcast(message: "\(client) disconnected")
        }

        _ = try? client.close()
		
		if let index = chatClients.firstIndex(of: client) {
			chatClients.remove(at: index)
        }
    }

}

extension ChatServer {

    /// - Returns: `true` if `command` was actually a command, `false` otherwise.
    func handleCommand(command: String, from client: ConnectedChatClient) -> Bool {
        switch command {
        case "/exit":
			log(message: "\(client) sent command: \(command)")
			disconnect(client: client)
            return true
        case "/who":
			log(message: "\(client) sent command: \(command)")
			let chatClientDescriptions = chatClients.map { $0.fullDescription }.joined(separator: ", ")
			send(message: chatClientDescriptions, to: client)
            return true
        case "/stopserver":
			log(message: "\(client) sent command: \(command)")
            stop()
            return true
        case "/whoami":
			log(message: "\(client) sent command: \(command)")
			send(message: "You are \(client)", to: client)
            return true
        default:
            // Wasn't a single word command.
            break
        }

		let commandComponents = command.components(separatedBy: " ")
        guard !commandComponents.isEmpty else {
            return false
        }

        switch commandComponents[0] {
        case "/name":
			log(message: "\(client) sent command: \(command)")
            guard commandComponents.count == 2 else {
				send(message: "Invalid command", to: client)
                return true
            }
            let oldName = client.description
            client.name = commandComponents[1]
			broadcast(message: "\(oldName) is now \(client)")
            return true
        default:
            break
        }
        
        // Wasn't a command:
        return false
    }
    
}
