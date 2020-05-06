//
//  AVCNALUFragment.swift
//  VideoStream
//
//  Created by Ondřej Šebelík on 02.08.18.
//  Copyright © 2018 O2 Czech Republic. All rights reserved.
//

import Foundation
import AVFoundation

class AVCNALUFragment: NALUFragment {
    
    var data: Data?
    var sequenceNumber: UInt16
    var type: NALUType
    var timestamp: CMTime
    
    init (data: Data, timestamp: CMTime, sequenceNumber: UInt16, type: NALUType) {
        self.data = data
        self.timestamp = timestamp
        self.sequenceNumber = sequenceNumber
        self.type = type
    }
    
    var header: UInt8 {//Calssifies firstPacket, lastPacket and nalType. For first and last packet MASK HEADER WITH 0xE0 and for nalType mask with 0x1F.
        //AOSP Code:
        //----------
        //    data[13] =
        //             (firstPacket ? 0x80 : 0x00)
        //             | (lastPacket ? 0x40 : 0x00)
        //             | (nalType & 0x1f);
        return data![1]
    }
    
    var payload: Data {
        return (type == .AVC_RTP_FU_B) ? data![4...] : data![2...]
}
    
    var naluType: UInt8 {
        return header & 0x1f
    }
    
    var naluHeader: [UInt8] {
        let nri = data![0] & 0x60
        return [naluType | nri]
    }
    
}
