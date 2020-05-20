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
    let stremeProcessor = DispatchQueue(label: "TCP Stream Processor",qos: .userInteractive)
    
    override func datagramReceived (_ data: [UInt8]) {
        //Append new data to the buffer
        if self.streamBuffer == nil{
            self.streamBuffer = data
            self.mode = "TCP"
        }
        else{
            self.streamBuffer = self.streamBuffer! + data
        }
        
        
        //Release a RTP Packet from buffer.
        var length = ByteUtil.bytesToUInt16(self.streamBuffer![12...13])
        while self.streamBuffer!.count > length{

            var packet = [UInt8] (self.streamBuffer![0..<Int(length)])
            
            self.streamBuffer!.removeSubrange(0..<Int(length))
            
            
            self.stremeProcessor.async {
                self.processStream(&packet)
                if self.DEBUG{
                    print("TCP Handler 2 :113: Next first byte: \(packet[0]) Size: \(self.streamBuffer?.count ?? 0) Length: \(length)")
                }
            }
            
            if self.streamBuffer!.count > 14{
                length = ByteUtil.bytesToUInt16(self.streamBuffer![12...13])
            }
            else{
                break
            }
        }

        
        if DEBUG{
            print("TCP Handler 1 :113: Next first byte: \(self.streamBuffer![0]) Size: \(self.streamBuffer?.count ?? 0) Length: \(length) RS: \(data.count)")
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
        // No need to send sort the packages as TCP packets are always in order. So delegate the packet.
        self.delegate?.didReceiveRTPPacket(packet: packet)
        //        dispatchPacket(packet: packet)
    }
    
}
