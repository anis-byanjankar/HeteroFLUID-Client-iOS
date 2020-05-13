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
    let DEBUG: Bool = true;
    let TAG: String = "AVCDefragmenter";

    var delegate: VideoDecoderDelegate?
    // Intermediate container for holding
    // NALU fragments
    private var fragmentedNALU: FragmentedNALU? = nil
    
    //This where we receive RTP packets. Form here on we try to convert it into NAL Units
    //    func didReceiveRTPPacket(_ data: Data?, timestamp: CMTime, sequenceNumber: UInt16) {
    func didReceiveRTPPacket(rtpPacket: RTPPacket) {
        
        //2. Reveived RTP packet and We will try to parse this into NAL Units to send it to Decoder.
        guard rtpPacket.payload.count != 0 else {
            if DEBUG{
                print("\(TAG): No NALU data received")
            }
            return
        }
        
        let ts = CMTimeMake(value: Int64(rtpPacket.timestamp), timescale: 90000);
        var nalu: NALUnit = AVCNALUnit(data: rtpPacket.payload, timestamp: ts)
        
        if nalu.type == .AVC_RTP_FU_A || nalu.type == .AVC_RTP_FU_B {
            var fragmentedPacket: NALUFragment = AVCNALUFragment(data: nalu.data!, timestamp: ts, sequenceNumber: rtpPacket.sequence, type: nalu.type);
            
            didReceiveFU(&fragmentedPacket)
            return
        }
        //For packet containing single NAL Unit.
        delegate?.didReceiveNALUnit(&nalu)
    }
    
    // This function assembles complete NAL units
    // from NALU fragments
    func didReceiveFU (_ fragment: inout NALUFragment) {
        // If the current fragmented NALU timestamp does not
        // match the received unit, close the current NALU
        if fragmentedNALU != nil && fragmentedNALU!.timestamp != fragment.timestamp {
            didAssembleFU(&fragmentedNALU!)//Send the portion of data that we have collected so far in the past.
            fragmentedNALU = nil
        }
        if fragmentedNALU == nil {
            fragmentedNALU = FragmentedNALU(timestamp: fragment.timestamp)
        }
        guard fragmentedNALU != nil else {
            print("No previous fragment found, dropping fragment")
            return
        }
        fragmentedNALU?.fragments.append(fragment)
    }
    
    //Assembles the FU Packets
    func didAssembleFU (_ nalu: inout FragmentedNALU) {
        guard let unitData = nalu.data else {
            print("Skipping fragmented NALU because it does not contain any data")
            return
        }
        var nalUnitToSend: NALUnit = AVCNALUnit(data: unitData, timestamp: nalu.timestamp)
        delegate?.didReceiveNALUnit(&nalUnitToSend)
    }
}
