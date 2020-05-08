////
////  TCPStreamProcessor.swift
////  H264DecodeFromFile
////
////  Created by Anish Byanjankar on 2020/05/08.
////  Copyright © 2020 Anish Byanjankar. All rights reserved.
////
//
//import Foundation
//
//
////typealias VideoPacket = Array<UInt8>
//
//class PacketReader: NSObject {
//    
//    let bufferCap: Int = 512 * 1024
//    var streamBuffer = Array<UInt8>()
//    
//    
//    let startCode: [UInt8] = [0x80]
//    
//  
//    
//    func netPacket() -> VideoPacket? {
//        
//        if streamBuffer.count == 0 && readStremData() == 0{
//            return nil
//        }
//        
//        //make sure start with start code
//        if streamBuffer.count < 5 || Array(streamBuffer[0...3]) != startCode {
//            return nil
//        }
//        
//        //find second start code , so startIndex = 4
//        var startIndex = 4
//        
//        while true {
//            
//            while ((startIndex + 3) < streamBuffer.count) {
//                if Array(streamBuffer[startIndex...startIndex+3]) == startCode {
//                    
//                    let packet = Array(streamBuffer[0..<startIndex])
//                    streamBuffer.removeSubrange(0..<startIndex)
//                    
//                    return packet
//                }
//                startIndex += 1
//            }
//            
//            // not found next start code , read more data
//            if readStremData() == 0 {
//                return nil
//            }
//        }
//    }
//    
//    fileprivate func readStremData() -> Int{
//        
//        if let stream = fileStream, stream.hasBytesAvailable{
//            
//            var tempArray = Array<UInt8>(repeating: 0, count: bufferCap)
//            let bytes = stream.read(&tempArray, maxLength: bufferCap)
//            
//            if bytes > 0 {
//                streamBuffer.append(contentsOf: Array(tempArray[0..<bytes]))
//            }
////            hex(data: tempArray)
//            return bytes
//        }
//        
//        return 0
//    }
//}
