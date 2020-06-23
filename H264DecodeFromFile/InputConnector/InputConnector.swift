//
//  InputConnector.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/06/23.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation


class InputConnector{
    let DEBUG: Bool = false
    let TAG: String = "InputConnector: "
    let sendControlCommand = DispatchQueue(label: "Control Command Send Thread",qos: .userInteractive)
    
    func sendTouchInput(x:Int, y:Int, z:Int,connection: TCPClient){
        sendControlCommand.sync {
            if connection.send(data: Data("\(x);\(y);\(z)\n".utf8)){
                if DEBUG{
                    print("Touch Sent")
                }
            }
            else{
                if DEBUG{
                    print("Touch Failed!!!")
                }
            }
        }
    }
}
