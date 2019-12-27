//
//  ConnectedChatClient.swift
//  ChatServer
//
//  Created by Marco Masser on 2016-03-11.
//  Copyright © 2016 Objective Development Software GmbH. All rights reserved.
//

import Foundation

class ConnectedChatClient: ConnectedClientSocketType {
    
    let socket: Socket
    let address: SocketAddress
    let host: String
    let port: String
    var name: String?
    var receiveSource: SocketDispatchSource?

    required init(socket: Socket, address: SocketAddress) throws {
        self.socket = socket
        self.address = address

        // Cache the name info right away, so it can be printed even after close():
        (host, port) = try address.nameInfo()
    }

}

extension ConnectedChatClient: Equatable {
	static func == (lhs: ConnectedChatClient, rhs: ConnectedChatClient) -> Bool {
		return lhs.socket.fileDescriptor == rhs.socket.fileDescriptor
	}
}

extension ConnectedChatClient: CustomStringConvertible {

    var description: String {
        return name ?? "\"\(host)\":\(port)"
    }

    var fullDescription: String {
        if let name = name {
            return "\(name) is \"\(host)\":\(port)"
        } else {
            return "\"\(host)\":\(port)"
        }
    }
    
}
