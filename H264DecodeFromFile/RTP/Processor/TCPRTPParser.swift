//
//  TCPRTPParser.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/05/08.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation
class TCPRTPParser: RTPParser {
    var streamBuffer: [UInt8]? = nil
    let receivedDataHandlerQueue = DispatchQueue(label: "TCP Data Handler",qos: .userInitiated)
    let stremeProcessor = DispatchQueue(label: "TCP Stream Processor",qos: .userInitiated)
    
    override func datagramReceived (_ data: [UInt8]) {
        if self.streamBuffer == nil{
            self.streamBuffer = data
            self.mode = "TCP"
        }
        else{
            self.streamBuffer = self.streamBuffer! + data
        }
        let length = ByteUtil.bytesToUInt16(self.streamBuffer![12...13])
        if DEBUG {
//            let sequence = ByteUtil.bytesToUInt16(data[2...3])
//            print("Sequence:113: \(sequence) Next first byte: \(self.streamBuffer![0])")
        }
//        if self.streamBuffer!.count > length && self.streamBuffer![0] == 0x80{
        if self.streamBuffer!.count > length{
            var packet = [UInt8] (self.streamBuffer![0..<Int(length)])
            
            self.streamBuffer!.removeSubrange(0..<Int(length))
            
            
            self.stremeProcessor.async {
                self.processStream(&packet)
            }
        }
    }
    
    func processStream(_ data: inout [UInt8]){
        
        // Sequence number
         let sequence = ByteUtil.bytesToUInt16(data[2...3])
        // Timestamp
        var timestamp = ByteUtil.bytesToUInt32(data[4...7])
        // Synchronization source (SSRC)
        let ssrc = ByteUtil.bytesToUInt32(data[8...11])
        
        if data[0] & 0xC0 == 0x00{
            timestamp = timestamp - 1 // Change the time stamp to the original one.
        }
        
        
        if DEBUG{
            print("Sequence Number:112: : \(sequence)")
        }
        
        let payload = Data(data[14...])
        
        
        let packet = RTPPacket(payload: payload, sequence: sequence, ssrc: ssrc, csrc: [], timestamp: timestamp, extensions: nil)
        
        dispatchPacket(packet: packet)
    }
    
}
