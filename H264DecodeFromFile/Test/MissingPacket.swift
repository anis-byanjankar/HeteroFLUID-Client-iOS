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
    
}
