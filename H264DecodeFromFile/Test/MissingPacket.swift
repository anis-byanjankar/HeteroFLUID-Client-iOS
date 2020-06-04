//
//  MissingPacket.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/05/28.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation
class MissingPacket{
    public static var current: UInt8? = nil;
    
    
    func check(_ data: [UInt8]) -> Bool{
        var i = 0;
        while i < data.count{
            
            if MissingPacket.current != nil{
                if MissingPacket.current != data[i]{
                    print("ERROR")
                    MissingPacket.current = nil
                    return false
                }
            }
            else{
                MissingPacket.current = data[0]
            }
            
            if MissingPacket.current == 0xff{
                MissingPacket.current = 0x00;
            }
            else{
                MissingPacket.current = MissingPacket.current! + 1
            }
            
            i=i+1;
        }
        return true
    }
    
    
    
    //Pass by reference checking.
    func fxnA(){
        var a: UInt8! = 0x87
        var b: UInt8! = 0x80
        DispatchQueue.global(qos: .userInteractive).async {
            sleep(3)
            self.fxnB(&a)
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            sleep(1)
            self.fxnB(&b)
        }
    }
    
    func fxnB(_ data: inout UInt8){
        for _ in 1...50{
            print(data)
            sleep(1)
        }
    }
    //Pass by reference Checking end.
    func testSeparatePacket(){
        var dummy: [UInt8] = [0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x00,0x00,0x00,0x01,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x00,0x00,0x00,0x01,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFA,0x1B]
        var dummy2: [UInt8] = [0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFA,0x1B]
        //        self.rtpParser?.separatePackets(&dummy);
        //        self.rtpParser?.separatePackets(&dummy2);
        
    }
    
    func testUDPServer(){
        
        
        //        DispatchQueue.global(qos: .background).async {
        //            let x = try! UDPServer(port: 9876)//HardCoded in the AOSP ARTPWriter
        //
        //            for _ in 1...2{
        //                sleep(1)
        //                print(String(decoding: x.Receive() ?? Data("NO DATA REDEIVED".utf8), as: UTF8.self))
        //            }
        //        }
    }
    
    func testTCPClient(){
        let x = TCPClient(host: "localhost",port: 2399,delegate: nil)
        for i in 1...5{
            _ = x.send(data: Data("Test String \(i)\n".utf8))
            sleep(3)
        }
        
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
