//
//  RTPPacketDelegate.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/04/28.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation


protocol RTPPacketDelegate {
    func didReceiveRTPPacket(packet: RTPPacket)
}
