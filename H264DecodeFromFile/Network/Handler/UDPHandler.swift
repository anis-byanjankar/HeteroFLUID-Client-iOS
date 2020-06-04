//
//  UDPHandler.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/06/03.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation
import NIO

class UDPHandler: ChannelInboundHandler {
    let DEBUG = false;
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    public typealias OutboundOut = [UInt8]
    private var length: UInt16 = 0
    private var flushed = false
    
    var streamBuffer: [UInt8]? = nil
    
    
    var TAG: String {
        return String(describing: type(of: self))
    }
    let byteProcessorWrapper = DispatchQueue(label: "Processor",qos: .userInteractive)
    
    
    public func channelActive(context: ChannelHandlerContext) {
        print("\(TAG) -> Connection activated!")
        // We are connected. It's time to send the message to the server to initialize the ping-pong sequence
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        
        var udpPacket = self.unwrapInboundIn(data)
        let dataPacket = udpPacket.data.getBytes(at: 0, length: udpPacket.data.readableBytes)
        byteProcessorWrapper.async {
            UDPServerNIO.delegate?.datagramReceived(dataPacket!)
        }
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("\(TAG)-> Error: ", error)
        
        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }
    
}
