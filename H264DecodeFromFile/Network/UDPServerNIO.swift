//
//  UDPServerNIO.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/05/28.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation
import NIO

public class UDPServerNIO: NALSource {
    var TAG: String {
        return String(describing: type(of: self))
    }
    var DEBUG: Bool! = false;
    
    static var delegate: TransportDelegate?
    
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    private var host: String?
    private var port: Int?
    var channel: Channel?
    var bootstrap: DatagramBootstrap {
        return DatagramBootstrap(group: group)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            
            .channelInitializer { channel in
                channel.pipeline.addHandler(UDPHandler())
        }
    }
 
    
    init(host: String, port: Int, delegate: TransportDelegate){
        self.host     = host
        self.port     = port
        UDPServerNIO.delegate = delegate
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
//            channel = try { () -> Channel in
//                return try bootstrap.bind(host: host, port: port).wait()
//                }()
        
            channel = try! bootstrap.bind(host: host, port: port).wait()

            print("\(TAG): Started UDP Server!!!")
            try channel!.closeFuture.wait()

            
        } catch let error {
            print("\(TAG): Error: \(error.localizedDescription)")
//            sleep(2)
//            print("\nReconnecting...")
//            try start()
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

