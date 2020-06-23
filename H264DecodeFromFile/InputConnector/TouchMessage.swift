//
//  TouchMessage.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/06/23.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation

class TouchMessage{
    
    var x:Int
    var y:Int
    var action:Int
    
    init(x:Int, y:Int, z:Int){
        self.x = x
        self.y = y
        self.action = z
    }
    
}
