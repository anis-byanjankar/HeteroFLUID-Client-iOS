//
//  TCPHeaderHandler.swift
//  HeteroFLUID-ProxyAPP
//
//  Created by Anish Byanjankar on 2020/05/15.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation
import NIO

class TCPHeaderHandler: ChannelInboundHandler {
    let DEBUG = false;
    public typealias InboundIn   = ByteBuffer
    public typealias OutboundOut = [UInt8]
    private var length: UInt16 = 0
    private var flushed = false
    
    var streamBuffer: [UInt8]? = nil
    
    
    var TAG: String {
        return String(describing: type(of: self))
    }
    let byteProcessorWrapper = DispatchQueue(label: "Processor",qos: .background)
    
    
    public func channelActive(context: ChannelHandlerContext) {
        print("\(TAG) -> Connection activated!")
        // We are connected. It's time to send the message to the server to initialize the ping-pong sequence
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        
        var buffer = self.unwrapInboundIn(data)
        if let receivedData = buffer.readBytes(length: buffer.readableBytes) {
            byteProcessorWrapper.async {
                TCPClientNIO.delegate?.datagramReceived(receivedData)
            }
        }
        else{
            print("\(self.TAG) -> No Data in Buffer")
        }
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("\(TAG)-> Error: ", error)
        
        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }
    
}
