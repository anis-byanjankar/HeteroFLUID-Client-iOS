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
    var mode: String = "UDP"
    
    let rtpProcessor = DispatchQueue(label: "RTP Parser",qos: .userInteractive)
    
    private var lostPackets: UInt = 0
    
    var delegate: RTPPacketDelegate? = nil
    
    let QUEUE_CAPACITY = 50000
    var expectedRTPPacketSequence: UInt16? = nil
    var lastProcessedPacketTime: UInt32? = nil
    
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
        
        let packet = RTPPacket(payload: payload, sequence: sequence, ssrc: ssrc, csrc: csrc, timestamp: timestamp, extensions: extensions)
        pushToMinDelayBuffer(packet)
    }
    
    
    
    // Decides whether a packet should be dispatched to the delegate
    // right away or appended to the queue
    func pushToMinDelayBuffer (_ packet: RTPPacket) {
        
        
        // First packet ever received, do not inspect sequence number
        guard expectedRTPPacketSequence != nil else {
            dispatchPacket(packet: packet)
            return
        }
        
        // Packets that arrive after a packet with higher
        // sequence number are dropped
        //        if packet.sequence < expectedRTPPacketSequence! && expectedRTPPacketSequence! < UInt16.max - UInt16(QUEUE_CAPACITY) && packet.sequence <= QUEUE_CAPACITY {
        if packet.sequence < expectedRTPPacketSequence!{
            print("\(TAG) Dropping out-of-order packet (expected \(expectedRTPPacketSequence!) got \(packet.sequence))")
            return
        }
        
        // Next packet in sequence arrived,
        // flush the queue
        if expectedRTPPacketSequence == packet.sequence {
            dispatchPacket(packet: packet)
            
            return
        }
        else {
            if DEBUG{
                print("\(TAG) Expected packet didn't arrive: Expected Packet- \(String(describing: expectedRTPPacketSequence))! Packet Seq - \(packet.sequence) ")
            }
            if ((packet.timestamp/90 - lastProcessedPacketTime!) > UInt32(ViewController.config!.NODELAY_TIMEOUT)!){
                rtpPacketOrderQueue.removeAll()
                print("QUEUE Cleared for having old data.")
                expectedRTPPacketSequence = packet.sequence
            }
            pushToQueue(packet)
        }
        
        // Check if there are expected packets in the queue
        // already, this needs to happend for every out-of-order
        // packet to avoid skipping some packets forever that would
        // consume space in the queue indefinitely
        // For this to work, the queue needs to be ordered
        if rtpPacketOrderQueue.first!.sequence == expectedRTPPacketSequence{
            //if rtpPacketOrderQueue.first!.sequence == expectedRTPPacketSequence || rtpPacketOrderQueue.count >= QUEUE_CAPACITY {
            repeat {
                dispatchPacket(packet: rtpPacketOrderQueue.removeFirst())
            }
            while (rtpPacketOrderQueue.first?.sequence == expectedRTPPacketSequence )
            //while (rtpPacketOrderQueue.first?.sequence == expectedRTPPacketSequence || rtpPacketOrderQueue.count >= QUEUE_CAPACITY)
        }
        else if rtpPacketOrderQueue.count >= QUEUE_CAPACITY {
            rtpPacketOrderQueue.removeAll()
            print("QUEUE EMPTY")
            pushToQueue(packet)
            expectedRTPPacketSequence = packet.sequence

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
        if mode == "UDP"{
            expectedRTPPacketSequence = UInt16((Int(packet.sequence) + 1) % 65535)
            lastProcessedPacketTime = packet.timestamp/90
        }
        if DEBUG{
            print("\(TAG) DIspatched Sequence Number: \(packet.sequence)")
        }
        
        rtpProcessor.async {
            self.delegate?.didReceiveRTPPacket(packet: packet)
        }
    }
}
