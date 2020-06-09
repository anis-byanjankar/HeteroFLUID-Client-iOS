//
//  Config.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/06/04.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation


struct Config: Codable{
    var AOSPServer:String
    var NetworkMode:String
    var ControlPort:UInt16
    var DataPort:UInt16
    var NIO:Bool
    var ClientIP:String
}
