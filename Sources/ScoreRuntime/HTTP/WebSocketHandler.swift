import Foundation
import NIOCore
import NIOWebSocket

/// A message received from or sent to a WebSocket client.
public enum WebSocketMessage: Sendable {
    /// A text frame.
    case text(String)
    /// A binary frame.
    case binary(Data)
}

/// A handler for a WebSocket connection.
///
/// ### Example
///
/// ```swift
/// WebSocketRoute(path: "/ws") { connection in
///     for try await message in connection.receive() {
///         try await connection.send(.text("Echo: \(message)"))
///     }
/// }
/// ```
public protocol WebSocketDelegate: Sendable {
    /// Called when a new WebSocket connection is established.
    func webSocketDidConnect(_ connection: WebSocketConnection) async
    /// Called when a message is received.
    func webSocket(_ connection: WebSocketConnection, didReceive message: WebSocketMessage) async
    /// Called when the connection is closed.
    func webSocket(_ connection: WebSocketConnection, didDisconnectWithCode code: UInt16) async
}

extension WebSocketDelegate {
    public func webSocketDidConnect(_ connection: WebSocketConnection) async {}
    public func webSocket(_ connection: WebSocketConnection, didDisconnectWithCode code: UInt16) async {}
}

/// Represents an active WebSocket connection.
public final class WebSocketConnection: Sendable {

    /// A unique identifier for this connection.
    public let id: String

    private let channel: NIOLoopBound<any Channel>

    init(id: String = UUID().uuidString, channel: any Channel) {
        self.id = id
        self.channel = NIOLoopBound(channel, eventLoop: channel.eventLoop)
    }

    /// Sends a message to the client.
    public func send(_ message: WebSocketMessage) {
        let channel = self.channel.value
        let frame: WebSocketFrame
        switch message {
        case .text(let string):
            var buffer = channel.allocator.buffer(capacity: string.utf8.count)
            buffer.writeString(string)
            frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
        case .binary(let data):
            var buffer = channel.allocator.buffer(capacity: data.count)
            buffer.writeBytes(data)
            frame = WebSocketFrame(fin: true, opcode: .binary, data: buffer)
        }
        channel.writeAndFlush(frame, promise: nil)
    }

    /// Closes the WebSocket connection.
    public func close(code: WebSocketErrorCode = .normalClosure) {
        let channel = self.channel.value
        var buffer = channel.allocator.buffer(capacity: 2)
        buffer.write(webSocketErrorCode: code)
        let frame = WebSocketFrame(fin: true, opcode: .connectionClose, data: buffer)
        channel.writeAndFlush(frame, promise: nil)
    }
}

/// A WebSocket route definition.
public struct WebSocketRoute: Sendable {

    /// The URL path for this WebSocket endpoint.
    public let path: String

    /// The delegate handling WebSocket events.
    public let delegate: any WebSocketDelegate

    public init(path: String, delegate: any WebSocketDelegate) {
        self.path = path
        self.delegate = delegate
    }
}

/// A simple closure-based WebSocket delegate.
public struct ClosureWebSocketDelegate: WebSocketDelegate {

    private let onMessageHandler: @Sendable (WebSocketConnection, WebSocketMessage) async -> Void

    public init(onMessage: @escaping @Sendable (WebSocketConnection, WebSocketMessage) async -> Void) {
        self.onMessageHandler = onMessage
    }

    public func webSocket(_ connection: WebSocketConnection, didReceive message: WebSocketMessage) async {
        await onMessageHandler(connection, message)
    }
}
