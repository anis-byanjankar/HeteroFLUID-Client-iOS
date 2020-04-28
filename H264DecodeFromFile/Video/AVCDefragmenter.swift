//
//  AVCDefragmenter.swift
//  VideoStream
//
//  Created by Ondřej Šebelík on 03.08.18.
//  Copyright © 2018 O2 Czech Republic. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox

class AVCDefragmenter {
    var delegate: VideoDecoderDelegate?
    // Intermediate container for holding
    // NALU fragments
    private var fragmentedNALU: FragmentedNALU? = nil
    
    
    
    //This where we receive RTP packets. Form here on we try to convert it into NAL Units
    //    func didReceiveRTPPacket(_ data: Data?, timestamp: CMTime, sequenceNumber: UInt16) {
    func didReceiveRTPPacket(rtpPacket: RTPPacket) {
        
        
        guard rtpPacket.payload.count != 0 else {
            print("No NALU data received")
            return
        }
        let ts = CMTimeMake(value: Int64(rtpPacket.timestamp), timescale: 90000);
        let nalu = AVCNALUnit(data: rtpPacket.payload, timestamp: ts)
        
        if nalu.type == .AVC_RTP_FU_A || nalu.type == .AVC_RTP_FU_B {
            didReceiveFU(AVCNALUFragment(data: nalu.data!, timestamp: ts, sequenceNumber: rtpPacket.sequence, type: nalu.type))
            return
        }
        
        delegate?.didReceiveNALUnit(nalu)
        
    }
    
    
    // This function assembles complete NAL units
    // from NALU fragments
    func didReceiveFU (_ fragment: NALUFragment) {
        
        if fragmentedNALU == nil {
            fragmentedNALU = FragmentedNALU(timestamp: fragment.timestamp)
        }
        
        // If the current fragmented NALU timestamp does not
        // match the received unit, close the current NALU
        if fragmentedNALU != nil && fragmentedNALU!.timestamp != fragment.timestamp {
            didAssembleFU(fragmentedNALU!)
            fragmentedNALU = nil
        }
        
        guard fragmentedNALU != nil else {
            print("No previous fragment found, dropping fragment")
            return
        }
        DispatchQueue.global(qos: .background).sync { [weak self] in
            print(fragment)
            self?.fragmentedNALU?.fragments.append(fragment)

        }
    }
    
    
    
    
    // Implementing classes are expected to override
    // this method to perform the final dispatch of
    // the assembled NALU
    func didAssembleFU (_ nalu: FragmentedNALU) {
        guard let unitData = nalu.data else {
            print("Skipping fragmented NALU because it does not contain any data")
            return
        }
        
        delegate?.didReceiveNALUnit(AVCNALUnit(data: unitData, timestamp: nalu.timestamp))
        
    }
    
    
    
    
    
    
}
