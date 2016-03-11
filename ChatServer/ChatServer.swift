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
        broadcast("Stopping chat server")
        acceptSource?.cancel()
        acceptSource = nil

        _ = try? close()

        for client in chatClients {
            disconnect(client, broadcastToOthers: false)
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
            broadcast("\(client) connected")
        } catch {
            log("Error handling new client: \(error)")
        }
    }

    func handlePendingMessage(from client: ConnectedChatClient) {
        do {
            guard let message = try client.receiveUTF8String() else {
                send("Invalid message received", to: client, ignoringErrors: true)
                disconnect(client)
                return
            }

            let trimmedMessage = message.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
            if !handleCommand(trimmedMessage.lowercaseString, from: client) && !trimmedMessage.isEmpty {
                broadcast(trimmedMessage, from: client)
            }
        } catch Socket.Error.ConnectionClosed {
            disconnect(client)
        } catch {
            log("Error handling message from: \(client): \(error)")
            disconnect(client)
        }
    }

    func send(message: String, to client: ConnectedChatClient, ignoringErrors: Bool = false) {
        do {
            log("Sending to \(client): \(message)")
            try client.send(message + "\n")
        } catch {
            if !ignoringErrors {
                log("Error sending message to: \(client), message: \(message)")
                disconnect(client)
            }
        }
    }

    func broadcast(message: String, from sender: ConnectedChatClient? = nil) {
        let serverName = "Server"
        let broadcastMessage = "\(sender?.description ?? serverName): \(message)\n"
        log(broadcastMessage, terminator: "")

        for receiver in chatClients where receiver != sender {
            do {
                try receiver.send(broadcastMessage)
            } catch {
                log("Error broadcasting message to: \(receiver)")
                disconnect(receiver)
            }
        }
    }

    func disconnect(client: ConnectedChatClient, broadcastToOthers: Bool = true) {
        if broadcastToOthers {
            broadcast("\(client) disconnected")
        }

        _ = try? client.close()

        if let index = chatClients.indexOf(client) {
            chatClients.removeAtIndex(index)
        }
    }

}

extension ChatServer {

    /// - Returns: `true` if `command` was actually a command, `false` otherwise.
    func handleCommand(command: String, from client: ConnectedChatClient) -> Bool {
        switch command {
        case "/exit":
            log("\(client) sent command: \(command)")
            disconnect(client)
            return true

        case "/who":
            log("\(client) sent command: \(command)")
            let chatClientDescriptions = chatClients.map { $0.fullDescription }.joinWithSeparator(", ")
            send(chatClientDescriptions, to: client)
            return true

        case "/stopserver":
            log("\(client) sent command: \(command)")
            stop()
            return true

        case "/whoami":
            log("\(client) sent command: \(command)")
            send("You are \(client)", to: client)
            return true

        default:
            // Wasn't a single word command.
            break
        }

        let commandComponents = command.componentsSeparatedByString(" ")
        guard !commandComponents.isEmpty else {
            return false
        }

        switch commandComponents[0] {
        case "/name":
            log("\(client) sent command: \(command)")
            guard commandComponents.count == 2 else {
                send("Invalid command", to: client)
                return true
            }
            let oldName = client.description
            client.name = commandComponents[1]
            broadcast("\(oldName) is now \(client)")
            return true
            
        default:
            break
        }
        
        // Wasn't a command:
        return false
    }
    
}
