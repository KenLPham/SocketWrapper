//
//  main.swift
//  server
//
//  Created by Marco Masser on 2016-03-11.
//  Copyright © 2016 Objective Development Software GmbH. All rights reserved.
//

struct SimpleServerSocket: ServerSocketType {
    let socket: Socket
    let address: SocketAddress
}

do {
    let port = "1234"
    let socket = try SimpleServerSocket(port: port)
    try socket.bind(reuseAddress: true)
    try socket.listen()

    print("Listening on port \(port)")
    while true {
        let clientSocket = try socket.accept(blocking: true)
        print("Client connected, sending string and closing connection")
        try clientSocket.send("Hello, Client!\n")
        try clientSocket.close()
    }
} catch {
    print("Error: \(error)")
}
