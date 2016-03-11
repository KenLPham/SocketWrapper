# SocketWrapper 

This is a POSIX socket API wrapper written in Swift.

It is intended for testing networking stuff in [Little Snitch](https://obdev.at/littlesnitch) where exact control over the low-level socket API calls is important. Also, we wanted to try out some concepts in Swift, especially in regard to protocol oriented programming.

It is not intended as a general purpose networking library that makes your life as an app developer easier. There are other things for that out there.

A presentation of this code and its implementation was first shown to the public at a CocoaHeads meetup in Vienna on 2016-03-10.

# TODO

Here’s a very incomplete list of things that could be added or changed:
- Implement support for other protocols than TCP. The low-level `Socket` struct probably doesn’t need any changes for that, but the higher-level `SocketType` sub-protocols don’t expose initializers for that.
- getaddrinfo() returns a linked list of results and only the very first one is used for `connect()`/`accept()`. That list should probably be traversed until those calls actually succeed. 
