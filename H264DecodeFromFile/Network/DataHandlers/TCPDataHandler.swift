//
//  TCPDataHandler.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/05/14.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation
import NIO

class TCPClientHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    private var numBytes = 0
    let TAG = "TCPClientHandler"
    
    public func channelActive(context: ChannelHandlerContext) {
        print("\(TAG)->Client connected to \(context.remoteAddress!)")
        
        // We are connected. It's time to send the message to the server to initialize the ping-pong sequence.
        
        
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        print("\(TAG)-> Data Received on Client!")

        let byteBuffer = self.unwrapInboundIn(data)
        self.numBytes -= byteBuffer.readableBytes
        context.fireChannelRead(self.wrapOutboundOut(byteBuffer))
//        if self.numBytes == 0 {
//            let string = String(buffer: byteBuffer)
//            print("\(TAG)->Received: '\(string)' back from the server, closing channel.")
//            context.close(promise: nil)
//        }
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("\(TAG)->error: ", error)
        
        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }
}
