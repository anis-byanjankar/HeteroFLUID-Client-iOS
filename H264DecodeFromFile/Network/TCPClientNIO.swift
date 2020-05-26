//
//  NetworkParser.swift
//  HeteroFLUID-ProxyAPP
//
//  Created by Anish Byanjankar on 2020/05/15.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation
import NIO

enum TCPClientError: Error {
    case invalidHost
    case invalidPort
}
protocol NALSource {
    // start() Must always be starting on a new async thread.
    // This will start to get the NAL Units from the source and delegate to the "NALUnitReceived" at Video Controller.
    func start() throws
}


public class TCPClientNIO: NALSource {
    var TAG: String {
        return String(describing: type(of: self))
    }
    var DEBUG: Bool! = true;
    
    static var delegate: TransportDelegate?

    var networkType: String? // Defines enum TCP, UDP, and Dual.
    
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    private var host: String?
    private var port: Int?
    var channel: Channel?
    var bootstrap: ClientBootstrap {
        return ClientBootstrap(group: group)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelOption(ChannelOptions.socketOption(.so_keepalive), value: 1)
            
            .channelInitializer { channel in
                channel.pipeline.addHandler(TCPHeaderHandler())
        }
    }
    
    init(host: String, port: Int, delegate: TransportDelegate){
        self.host     = host
        self.port     = port
        TCPClientNIO.delegate = delegate
    }
    
    func start() throws {
        //Main function which start to get the data and send it to the delegate handing NAL Unit Packets.
        guard let host = host else {
            throw TCPClientError.invalidHost
        }
        guard let port = port else {
            throw TCPClientError.invalidPort
        }
        do {
            channel = try bootstrap.connect(host: host, port: port).wait()
            
            print("\(TAG): Connected To TCP Data Packet Server!!!")
            
        } catch let error {
            print("\(TAG): Error: \(error.localizedDescription)")
            sleep(2)
            print("\nReconnecting...")
            try start()
            throw error
        }
    }
    
    func stop() {
        do {
            try group.syncShutdownGracefully()
        } catch let error {
            print("\(TAG): Error shutting down \(error.localizedDescription)")
            exit(0)
        }
        print("\(TAG): TCPClient connection closed")
    }
    
}

