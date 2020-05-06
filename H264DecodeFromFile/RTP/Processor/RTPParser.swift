//
//  RTPParser.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/04/28.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation

class RTPParser: TransportDelegate {
    let DEBUG: Bool = true
    let TAG: String = "RTPParser: "
    
    private var receivedPackets: UInt = 0
    private var lostPackets: UInt = 0 
    
    var delegate: RTPPacketDelegate? = nil
    
    let QUEUE_CAPACITY = 50
    var expectedRTPPacketSequence: UInt16? = nil
    var rtpPacketOrderQueue: [RTPPacket] = []
    
    func datagramReceived (_ data: [UInt8]) {
        
        // Sequence number
        let sequence = ByteUtil.bytesToUInt16(data[2...3])
        // Timestamp
        let timestamp = ByteUtil.bytesToUInt32(data[4...7])
        
        // Synchronization source (SSRC)
        let ssrc = ByteUtil.bytesToUInt32(data[8...11])
        
        // Contributing source (CSRC)
        let csrcCount = data[0] & 0x0f
        var csrc: [UInt32] = []
        
        for i in 0 ..< csrcCount {
            let csrcOffset: Int = 12 + Int(i*4)
            let csrcBytes = data[csrcOffset...(csrcOffset+4)]
            csrc.append(ByteUtil.bytesToUInt32(csrcBytes))
        }
        
        // Total length of the header (offset to payload)
        var headerLength = Int(12 + csrcCount*4)
        var extensions: Data?
        
        // Extensions (marked by 4th bit of the RTP packet header)
        // add to the standard RTP header length
        if data[0] & 0x10 == 0x10 {
            let extensionCount = ByteUtil.bytesToUInt16(data[headerLength+2...headerLength+3])
            extensions = Data(data[headerLength+4...headerLength+4+Int(extensionCount*4)-1])
            headerLength = headerLength + 4 + Int(extensionCount*4)
        }
        
        let payload = Data(data[headerLength...])
        
        
        /* Debug Start*/
        //        if headerLength>12{//Check if there is extension for the header.
        //            hex(data: data)
        //        }
        /* Debug End*/
        
        let packet = RTPPacket(payload: payload, sequence: sequence, ssrc: ssrc, csrc: csrc, timestamp: timestamp, extensions: extensions)
       
        ReceiveRTPPacket(packet)
    }
    
    
    
    // Decides whether a packet should be dispatched to the delegate
    // right away or appended to the queue
    func ReceiveRTPPacket (_ packet: RTPPacket) {
        
        receivedPackets = receivedPackets+1
        
        // First packet ever received, do not inspect sequence number
        guard expectedRTPPacketSequence != nil else {
            dispatchPacket(packet: packet)
            return
        }
        
        // Packets that arrive after a packet with higher
        // sequence number are dropped
        if packet.sequence < expectedRTPPacketSequence! && expectedRTPPacketSequence! < UInt16.max - UInt16(QUEUE_CAPACITY) && packet.sequence <= QUEUE_CAPACITY {
            print("\(TAG) Dropping out-of-order packet (expected \(expectedRTPPacketSequence!) got \(packet.sequence))")
            return
        }
        
        // Next packet in sequence arrived,
        // flush the queue
        if expectedRTPPacketSequence == packet.sequence {
            if DEBUG{
            print("\(TAG) 1Expected Packet!!")
                
            }
            dispatchPacket(packet: packet)
            
            return
        }
        else {
            if DEBUG{
                print("\(TAG) Expected packet didn't arrive: Expected Packet- \(String(describing: expectedRTPPacketSequence))! Packet Seq - \(packet.sequence) ")
            }
        }
        
        // Push to queue
        pushToQueue(packet)
        
        // Check if there are expected packets in the queue
        // already, this needs to happend for every out-of-order
        // packet to avoid skipping some packets forever that would
        // consume space in the queue indefinitely
        // For this to work, the queue needs to be ordered
        if rtpPacketOrderQueue.first!.sequence == expectedRTPPacketSequence || rtpPacketOrderQueue.count >= QUEUE_CAPACITY {
            
            repeat {
                dispatchPacket(packet: rtpPacketOrderQueue.removeFirst())
            }
                while (rtpPacketOrderQueue.first?.sequence == expectedRTPPacketSequence || rtpPacketOrderQueue.count >= QUEUE_CAPACITY)
            
        }
        
    }
    
    // Appends a packet to the queue and reorders it
    func pushToQueue (_ packet: RTPPacket) {
        
        rtpPacketOrderQueue.append(packet)
        
        rtpPacketOrderQueue.sort(by: { (a, b) -> Bool in
            let seqA: UInt16 = a.sequence
            let seqB: UInt16 = b.sequence
            return seqA <= seqB
        })
        
    }
    
    // Dispatches the packet to the delegate
    func dispatchPacket (packet: RTPPacket) {
        expectedRTPPacketSequence = UInt16((Int(packet.sequence) + 1) % 65535)
        //        print(packet)
        print("\(TAG) Sequence Number UDP: \(packet.sequence)")
        //        print(packet.timestamp)
        //        packet.payload.hex()
        
        DispatchQueue.global(qos: .userInteractive).sync {
            self.delegate?.didReceiveRTPPacket(packet: packet)
        }
        
        
        
        
        //PAYLOAD PROCEDDING START FOR SPS|PPS|IDR
        
        //        var tmpPacket = packet
        //        tmpPacket.STAP = true; // To recognige that the packet is first packet with SPS,PPS and IDR
        //        var rawPayload = [UInt8] (packet.payload)
        //
        //        //TODO: Get the data and parse it into the normal format.
        //        //Input:    xxxxxMxxxxxxxMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        //        //Output:
        //        //      Mxxxxx
        //        //      Mxxxxxxx
        //        //      Mxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        //        let startCode: [UInt8] = [0,0,0,1]
        //
        //        //find second start code,NO StartCode: STRIPPED FROM AOSP , so startIndex = 0
        //        var first = true
        //        var startIndex = 1
        //
        //        while ((startIndex + 3) < rawPayload.count) {
        //            if Array(rawPayload[startIndex...startIndex+3]) == startCode {
        //
        //                var packetSend = Array(rawPayload[0..<startIndex])
        //                rawPayload.removeSubrange(0..<startIndex)
        //                if first == true{
        //                    packetSend = [UInt8] ([0,0,0,1]) + packetSend
        //                    first = false
        //                }
        //
        //                //Update the payload and send the RTP packet
        //                tmpPacket.payload = Data(packetSend)
        //                DispatchQueue.global(qos: .userInteractive).async {
        //                    self.delegate?.didReceiveRTPPacket(packet: tmpPacket)
        //                }
        //
        //                if DEBUG{
        //                    print(TAG)
        //                    Data(packetSend).hex()
        //                }
        //                startIndex = 1
        //
        //            }
        //            startIndex += 1
        //        }
        //
        //        //Only one Fragmented Packet.
        //        if first == true{
        //            tmpPacket.STAP = false
        //            rawPayload = [UInt8] ([0,0,0,1]) + rawPayload
        //            first = false
        //        }
        //
        //
        //        //Update the payload and send the RTP packet in RTP.payload
        //        tmpPacket.payload = Data(rawPayload)
        //        DispatchQueue.global(qos: .userInteractive).async {
        //            self.delegate?.didReceiveRTPPacket(packet: tmpPacket)
        //        }
        //        if DEBUG{
        //            print(TAG)
        //            Data(rawPayload).hex()
        //        }
        
        //PAYLOAD PROCEDDING END FOR SPS|PPS|IDR
    }
    
    
    //Not used function. Used for testing.
    func separatePackets(_ videoPacket: inout [UInt8]){
        //********************************************************************************
        //TODO:     Get the data and parse it into the normal format.
        //Input:    xxxxxMxxxxxxxMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        //Output:
        //          Mxxxxx
        //          Mxxxxxxx
        //          Mxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        //********************************************************************************
        
        //********************************************************************************
        //Static Test for Adding 0x00 0x00 0x00 0x01 padding
        //********************************************************************************
        //var dummy: [UInt8] = [0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x00,0x00,0x00,0x01,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x00,0x00,0x00,0x01,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFA,0x1B]
        //self.separatePackets(&dummy);
        //********************************************************************************
        
        let startCode: [UInt8] = [0,0,0,1]
        
        //find second start code,NO StartCode: STRIPPED FROM AOSP , so startIndex = 0
        var first = true
        var startIndex = 1
        
        while ((startIndex + 3) < videoPacket.count) {
            if Array(videoPacket[startIndex...startIndex+3]) == startCode {
                
                var packet = Array(videoPacket[0..<startIndex])
                videoPacket.removeSubrange(0..<startIndex)
                if first == true{
                    packet = [UInt8] ([0,0,0,1]) + packet
                    first = false
                }
                
                Data(packet).hex()
                
                startIndex = 1
                
            }
            startIndex += 1
        }
        if first == true{
            videoPacket = [UInt8] ([0,0,0,1]) + videoPacket
            first = false
        }
        
        Data(videoPacket).hex()
    }
    
    
}