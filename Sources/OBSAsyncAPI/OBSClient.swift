//
//  OBSAsyncAPI.swift
//  
//
//  Created by Kit Transue on 2022-09-02.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit
import DeftLog
import OBSWebsocket
import Combine

let logger = DeftLog.logger(label: "com.didactek.obswebsocket")

/// Errors thrown by OBSAsyncAPI.
public enum APIError: Error {
    /// A request was made when the client was not connected to the server.
    case notConnected
    /// A response was not received within the ``OBSClient/connectTimeout`` window.
    case timeout
    /// The OBS server replied to a request with an unexpected response type.
    case mismatchedResponse(request: String, got: OBSResponse)
    /// A response could not be decoded by the strongly-typed API. The server JSON
    /// is supplied in case the caller can try a different decoding.
    case jsonParseError(encapsulateError: Error, source: String)
    /// Internal error constructing the wsURL from host and port.
    case badWSURL
    
    // FIXME: add authentication error? (Server seems to abruptly hang up on authentication error.)
}

/// The object that establishes a connection to an obs-websocket server and provides
/// methods for using the websocket services.
public actor OBSClient {
    
    /// An encapsulation of parameters needed to connect ot OBS.
    public struct ConnectionInfo: Codable, Equatable  {
        /// Server hostname or address; "localhost" if nil.
        public var host: String?

        /// Server port; 4455 if nil.
        public var port: Int?
        
        /// Server password, or nil if authentication is not enabled.
        public var password: String?
        
        public init(host: String? = nil, port: Int? = nil, password: String? = nil) {
            self.host = host
            self.port = port
            self.password = password
        }
        
        public func wsURL() throws -> URL {
            guard let url = URL(string: "ws://\(host ?? "localhost"):\(port ?? 4455)") else {
                throw APIError.badWSURL
            }
            return url
        }
    }

    var connectionSetup: ConnectionInfo
    
    /// Update connection information to use during ``connect()``.
    public func setConnectionInfo(_ setup: ConnectionInfo) {
        connectionSetup = setup
    }
    
    /// Timeout to use for ``connect()``.
    ///
    /// Provided/defaults during init; may be changed after client initialization.
    public var connectTimeout: DispatchQueue.SchedulerTimeType.Stride
    
    
    var urlSession:  URLSession?
    var webSocketTask: URLSessionWebSocketTask?
    
    /// A Boolean value puiblisher that indicates whether the client is connected to and authenticated with an obs-websocket server.
    public nonisolated let isConnected = CurrentValueSubject<Bool, Never>(false)
    
    /// The OBS event types to which this client is subscribed.
    ///
    /// If written while the client is connected, the client will re-subscribe to
    /// the provided subscriptions.
    public var eventSubscriptions: EventSubscription {
        // Note: these are not Combine-related
        didSet {
            resubscribe(to: eventSubscriptions)
        }
    }
    
    /// Publisher of events received from the OBS server.
    ///
    /// Subscriptions are initially requested in the initializer and can be maintained using ``eventSubscriptions``.
    ///
    /// See OBSWebsocket documentation for OBSEvent objects.
    public nonisolated let events = PassthroughSubject<OBSEvent, Never>()
    
    /// Establish a websocket connection and wait for connection acknowledgement.
    ///
    /// Set up a URLSession with the OBS server, send Identify/authentication, then
    /// await successful connection. Subscribe to events.
    ///
    /// On non-throwing return: ``isConnected`` should be true, the client
    /// can make requests, and subscribed events will be published on ``events``.
    ///
    /// - Throws: ``APIError/timeout`` if not connected within the ``connectTimeout`` allowance.
    public func connect() async throws {
        // FIXME: create delegate to handle authentication errors; manage our own logging
        urlSession = URLSession(configuration: .default)

        let wsURL = try connectionSetup.wsURL()

        webSocketTask = urlSession!.webSocketTask(with: wsURL)
        webSocketTask!.resume()
        
        listenForMessages()
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
            var subscriptions = Set<AnyCancellable>()
            isConnected
                .first(where: {$0 == true})
                .timeout(connectTimeout, scheduler: DispatchQueue.global(qos: .userInitiated))
                .sink(receiveCompletion: {_ in
                    subscriptions.removeAll()
                    continuation.resume(throwing: APIError.timeout)
                }, receiveValue: { _ in
                    subscriptions.removeAll()
                    continuation.resume()
                })
                .store(in: &subscriptions)
        }
        
    }
    
    func resubscribe(to subscriptions: EventSubscription) {
        guard isConnected.value else {return}
        let params = Reidentify(eventSubscriptions: subscriptions)
        let opCode = OpCode.reidentify(params)
        send(opCode: opCode)
    }
    
    /// Creates a client for communicating with an obs-websocket server.
    ///
    /// - Parameters:
    ///   - hostname: Server hostname; "localhost" if nil.
    ///   - port: Server port; 4455 if nil.
    ///   - connectTimeout: Override default connect timeout.
    ///   - password: Server password, or nil if authentication is not enabled.
    ///   - eventSubscriptions: Kinds of events the server should deliver to the client.
    public init(hostname: String? = nil,
                port: Int?,
                connectTimeout: DispatchQueue.SchedulerTimeType.Stride? = nil,
                password: String? = nil,
                eventSubscriptions: EventSubscription = .all) {
        // Use nil rather than default argument values in case the UI wants to fall back to defaults.
        self.connectionSetup = ConnectionInfo(host: hostname, port: port, password: password)
        
        self.connectTimeout = connectTimeout ?? .milliseconds(2_000)
        
 
        self.eventSubscriptions = eventSubscriptions
    }
    
    private func processMessage(result: Result<URLSessionWebSocketTask.Message, any Error>) {
        do {  // FIXME: remove 'do' (here to preserve indentation from when this code was in listenForMessages)
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    do {
                        let decoder = JSONDecoder()
                        let opcode = try decoder.decode(OpCode.self, from: text.data(using: .utf8)!)
                        logger.trace("listenForMessages decoded opcode: \(opcode)")
                        switch opcode {
                        case .hello(let requirements):
                            identify(authRequirement: requirements.authentication)
                        case .identify:
                            logger.warning("Server sent Identify message (usually made by client).")
                        case .identified:
                            isConnected.value = true
                        case .reidentify:
                            logger.warning("Server sent Identify message (usually made by client).")
                        case .event(let event):
                            events.send(event)
                        case .request:
                            logger.warning("Server sent request (usually made by client).")
                        case .response(let response):
                            processResponse(response: response)
                        case .requestBatch:
                            logger.warning("Server sent batch request message (usually made by client).")
                        case .requestBatchResponse:
                            logger.warning("Server sent batch response message (client batch requests are not implemented).")
                        }
                    } catch OBSWebsocketError.identifiedResponse(let abc, let encapsulatedError) {
                        guard let uuid = UUID(uuidString: abc),
                              let requestContinuation = pending.removeValue(forKey: uuid)
                        else {
                            logger.debug("Caught error for unknown requestId \(abc). Ignoring.")
                            logger.trace("Ignored error \(encapsulatedError) came parsing \(text).")
                            break
                        }
                        requestContinuation.resume(throwing: APIError.jsonParseError(encapsulateError: encapsulatedError, source: text))
                    } catch {
                        logger.debug("listenForMessages: failed parse: \(text)")
                    }
                case .data:
                    logger.warning("expected JSON text; got raw data")
                default:
                    logger.warning("unexpected websocket encoding received")
                }
                listenForMessages()
            case .failure(let error):
                logger.debug("Failure message from server: \(error)")
                connectionClosed()
            }
        }
    }

    private func listenForMessages() {
        webSocketTask!.receive { [unowned self] result in
            // FIXME: adapt webSocketTask callback to actor-isolated context
            self.processMessage(result: result)
        }
    }
    
    /// Clean up after a connection is closed
    func connectionClosed() {
        isConnected.value = false
        while let outstanding = pending.popFirst() {
            outstanding.value.resume(throwing: APIError.notConnected)
        }
        webSocketTask = nil
        urlSession = nil
    }
    
    // FIXME: keep connection alive w/ ping every 10s? (OBS seems OK keeping a quiet connection open)
    
    func identify(authRequirement: Hello.Authentication?) {
        let auth: String?
        if let authRequirement = authRequirement {
            auth = authenticationString(challenge: authRequirement.challenge, salt: authRequirement.salt)
        } else {
            auth = nil
        }
        let id = Identify(rpcVersion: 1, authentication: auth, eventSubscriptions: eventSubscriptions)
        let message = OpCode.identify(id)
        
        send(opCode: message)
    }
    
    var pending: [UUID: CheckedContinuation<OBSResponse, Error>] = [:]
    
    private func queueContinuation(_ contination: CheckedContinuation<OBSResponse, Error>,
                                   for uuid: UUID,
                                   opCode: OpCode
    ) async {
        pending[uuid] = contination
        send(opCode: opCode)
    }
    
    func request(_ req: OBSRequest) async throws -> OBSResponse {
        guard isConnected.value else {
            throw APIError.notConnected
        }
        let id = UUID()
        let request = RequestEnvelope(request: req, id: id.uuidString)
        let opCode = OpCode.request(request)
        return try await withCheckedThrowingContinuation { continuation in
            // convolution to make sure pending is updated in actor-protected context:
            Task.init {
                await queueContinuation(continuation, for: id, opCode: opCode)
            }
        }
    }
    
    func processResponse(response: ResponseEnvelope) {
        guard let id = UUID(uuidString: response.id),
              let continuation = pending.removeValue(forKey: id) else {
            // If you see this, check for leaked/dropped continuation.
            logger.debug("Received response for unknown requestId \(response.id). Ignoring.")
            logger.trace("Response was: \(response)")
            return
        }
        continuation.resume(returning: response.response)
    }
    
    func send(opCode: OpCode) {
        let encoder = JSONEncoder()
        let text = try! String(data: encoder.encode(opCode), encoding: .utf8)!
        
        logger.trace("sending \(text)")
        
        webSocketTask!.send(URLSessionWebSocketTask.Message.string(text))  { (err: Error?) in
            if let err = err {
                logger.warning("send error: \(err)")
            }
        }
    }
    
    func authenticationString(challenge: String, salt: String) -> String? {
        guard let password = connectionSetup.password else {
            return nil
        }
        func digest256x64(_ input: String) -> String {
            let digest = SHA256.hash(data: input.data(using: .utf8)!)  // FIXME: confirm UTF-8 works for non-ASCII code points entered on server
            return Data(digest).base64EncodedString()
        }
        let secret = digest256x64(password + salt)
        let authentication = digest256x64(secret + challenge)
        return authentication
    }
    
    deinit {
        urlSession?.invalidateAndCancel()
    }
}
