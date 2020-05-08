//
//  TCPClient1.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/05/07.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//


import Foundation
import Network

class TCPClientVideo: Connection{
    
    
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port
    let queue = DispatchQueue(label: "TCP Clinet Connection")
    var nwConnection: NWConnection!
    var didStopCallback: ((Error?) -> Void)? = nil
    
    var hostString: String
    var hostPort: UInt16
    
    init(host: String, port: UInt16) {
        hostString = host
        hostPort = port
        
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
        nwConnection = NWConnection(host: self.host, port: self.port, using: .tcp)
        nwConnection.stateUpdateHandler = stateDidChange(to:)
        nwConnection.start(queue: queue)
        
        print("TCP Connection Started")
        _ = self.Receive()
        
    }
    func Send(data: Data) -> Bool {
        var sent = true
        nwConnection!.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                sent = false
                return
            }
            print("TCP Connection did send, data: \(data as NSData)")
        }))
        return sent
    }
    
    func Receive() -> Data? {
        var receivedData: Data?
        nwConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8)
                print("\n\nConnection did receive, data: \(data as NSData) string: \(message ?? "-" )")
                receivedData = data
            }
            if isComplete {
                self.connectionDidEnd()
            } else if let error = error {
                self.connectionDidFail(error: error)
            }
        }
        return receivedData ?? nil
        
    }
    
    func didStopCallback(error: Error?) {
        if error == nil {
            exit(EXIT_SUCCESS)
        } else {
            print("\n Error Encountered: \(String(describing: error))")
            sleep(2)
            _ = TCPClientVideo(host: hostString, port: hostPort)
//            exit(EXIT_FAILURE)
        }
    }
    
    
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            print("Client connection ready")
        case .failed(let error):
            connectionDidFail(error: error)
        default:
            break
        }
    }
    
    
    
    
    func stop() {
        print("connection will stop - NO ERROR CODE RECEIVED")
        stop(error: nil)
    }
    
    private func connectionDidFail(error: Error) {
        print("connection did fail, error: \(error)")
        self.stop(error: error)
    }
    
    private func connectionDidEnd() {
        print("connection did end")
        self.stop(error: nil)
    }
    
    private func stop(error: Error?) {
        self.nwConnection.stateUpdateHandler = nil
        self.nwConnection.cancel()
        if let didStopCallback = self.didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
    
}

