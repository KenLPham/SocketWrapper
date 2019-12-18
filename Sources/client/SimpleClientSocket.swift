//
//  main.swift
//  client
//
//  Created by Marco Masser on 2016-03-11.
//  Copyright © 2016 Objective Development Software GmbH. All rights reserved.
//

struct SimpleClientSocket: ClientSocketType {
    let socket: Socket
    let address: SocketAddress
}

class SocketClient {
	func start () {
		do {
			let socket = try SimpleClientSocket(host: "192.168.1.16", port: "42069")
			try socket.connect()
			try socket.send(message: "Hello, Server!")
			if let string = try socket.receiveUTF8String(blocking: true) {
				print("Server said: \(string)")
			}
		} catch {
			print("Error: \(error)")
		}
	}
}
