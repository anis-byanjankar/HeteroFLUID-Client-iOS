//
//  UDPClient.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/04/27.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation
import Network

@available(macOS 10.14, *)
class UDPServer: Connection {
    func Receive() -> Data? {
        return nil
    }
    
    var delegate: TransportDelegate?
    
    let MTU = 65536
    
    let port: NWEndpoint.Port
    let listener: NWListener
    
    var connection: NWConnection!
    
    var didStopCallback: ((Error?) -> Void)? = nil
    
    init(port: UInt16,parser: RTPParser) throws {
        self.delegate = parser;

        self.port = NWEndpoint.Port(rawValue: port)!
        listener = try! NWListener(using: .udp, on: self.port)
        
        print("UDP Server starting...")
        listener.stateUpdateHandler   = self.stateDidChangeListener(to:)
        listener.newConnectionHandler = self.didAcceptListener(nwConnection:)
        listener.start(queue: .global(qos: .userInteractive))
    }
    
   
    
    func Send(data: Data) -> Bool {
        //TODO 
        return true
    }
    

    //    Callback handlers
    
    func stateDidChangeListener(to newState: NWListener.State) {
        switch newState {
        case .ready:
            print("UDP Server ready.")
        case .failed(let error):
            print("Server failure, error: \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        case .cancelled:
            print("Connection Cancelled!")
        default:
            break
        }
    }
    
    func stopListener() {
        self.listener.stateUpdateHandler = nil
        self.listener.newConnectionHandler = nil
        self.listener.cancel()
    }
    
    func didAcceptListener(nwConnection: NWConnection) {
        self.connection = nwConnection
        self.connection.stateUpdateHandler = self.stateDidChange(to:)
        self.setupReceive()
        self.connection.start(queue: .main)
        print("UDP Server connection initiated!!")
    }
    
    //    Connection Settings
    
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            print("UDP Connection ready")
        case .failed(let error):
            connectionDidFail(error: error)
        default:
            break
        }
    }
    
    func setupReceive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: MTU) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                DispatchQueue.global(qos: .userInteractive).sync {
                    self.delegate?.datagramReceived([UInt8] (data))
                }
            }
            if isComplete {
                self.setupReceive() // Although it is reveived keep listening and keep gathering UDP packets.
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
        }
    }
    
    private func connectionDidFail(error: Error) {
        print("connection did fail, error: \(error)")
        stop(error: error)
    }
    
    private func connectionDidEnd() {
        print("connection did end")
        stop(error: nil)
    }
    
    private func stop(error: Error?) {
        connection.stateUpdateHandler = nil
        connection.cancel()
        if let didStopCallback = didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
}
