//
//  ViewController.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/04/24.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import UIKit
import VideoToolbox
import AVFoundation


class ViewController: UIViewController,RTPPacketDelegate,VideoDecoderDelegate {
    let TAG: String = "ViewController"
    let DEBUG: Bool! = true;
    let videoProcessor = DispatchQueue(label: "VideoDecoder",qos: .userInteractive)
    let displayProcessor = DispatchQueue(label: "Display Blit Processor",qos: .userInteractive)
    
    
    var formatDesc: CMVideoFormatDescription?
    var decompressionSession: VTDecompressionSession?
    var videoLayer: AVSampleBufferDisplayLayer?
    
    var spsSize: Int = 0
    var ppsSize: Int = 0
    
    var sps: Array<UInt8>?
    var pps: Array<UInt8>?
    
    var rtpParser: RTPParser?
    var defragmenter: AVCDefragmenter?
    
    
    var source: String? = "H264"
    var AOSPServer: String = "192.168.0.7"
    var port: UInt16 = 9879
    
    var client: TCPClient? = nil
    
    let mode: String = "TCP"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Send Static SPS AND PPS
        //                var SPS: [UInt8] = [0, 0, 0, 1, // header
        //                0x67, 0x42, 0x80, 0x0a, 0xda,
        //                0x01, 0x68, 0x05, 0x27, 0xe6,
        //                0x80, 0x6d, 0x0a, 0x13, 0x50]
        //                var PPS: [UInt8] = [0, 0, 0, 1, // header
        //                0x68, 0xce, 0x06, 0xf2]
        
        // 1. Fix the RTP Parser
        switch self.mode{
        case "UDP":
            self.rtpParser = RTPParser();
        case "TCP":
            self.rtpParser = TCPRTPParser();
        default:
            self.rtpParser = RTPParser();
            break
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.SendClientDimension()//Send the dimension of device to android.
            
            
            
            
            self.client = TCPClient(host: self.AOSPServer, port: self.port,delegate: self.rtpParser!)
            //            sleep(2)
            
            while self.client?.connected == false{
                self.client?.stop()
                self.client = TCPClient(host: self.AOSPServer, port: self.port,delegate: self.rtpParser!)
                sleep(1)
                self.client?.delegate = self.rtpParser
                
            }
        }
        
        
        rtpParser?.delegate = self
        //        _ = try! UDPServer(port: 9876,parser: rtpParser!)//HardCoded in the AOSP ARTPWriter
        //        sleep(1)
        
        defragmenter = AVCDefragmenter()
        defragmenter?.delegate = self
        
        configDecoding(fromFile: false)
        
        //******************************TESTING*********************************
        //testUDPServer()
        //testSeparatePacket()
        //              fxnA() // Dispatch Thread testing.
        
        //        sleep(2)
        //        self.receivedRawVideoFrame(&SPS)
        //        self.receivedRawVideoFrame(&PPS)
        
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
        self.rtpParser?.separatePackets(&dummy);
        self.rtpParser?.separatePackets(&dummy2);
        
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
    func SendClientDimension(){
        let x = TCPClient(host: "192.168.0.7",port: 5001,delegate: nil)
        let screenSize     = UIScreen.main.bounds
        print("display:\(screenSize.width).\(screenSize.height).640\n".utf8)
        if x.send(data: Data("display:\(Int(screenSize.width)).\(Int(screenSize.height)).640\n".utf8)){
            //        if x.send(data: Data("display:140.280.140\n".utf8)){
            print("Couldn't connect to AOSP TCP Server");
        }
        else{
            print("TCP Data Sent!!!")
        }
        
    }
    func testTCPClient(){
        let x = TCPClient(host: "localhost",port: 2399,delegate: nil)
        for i in 1...5{
            _ = x.send(data: Data("Test String \(i)\n".utf8))
            sleep(3)
        }
        
    }
    //Here we receive the concatenated NAL Units
    func didReceiveNALUnit(_ nalu: inout NALUnit) {
        //        print("NAL UNITS RECEIVED!!!!")
        //        nalu.data?.hex()
        //3. Reveibed NAL UNIT now we need to send this NAL Unit to decoder.
        // Expectation : NAL Units are separated with 0x00 00 00 01. All SPS, PPS and IDR, VCL Frame. Everything must be separated
        
        //        nalu.data!.hex()
        var rawPayload: VideoPacket = [UInt8] (nalu.data!)
        // We need to separate the packets and also add sentinel at the front of each packet.
        
        //TODO: Get the data and parse it into the normal format.
        //Input:    xxxxxMxxxxxxxMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        //Output:
        //      Mxxxxx
        //      Mxxxxxxx
        //      Mxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        let startCode: [UInt8] = [0,0,0,1]
        
        //find second start code,NO StartCode: STRIPPED FROM AOSP , so startIndex = 0
        var first = true
        var startIndex = 4
        
        
        var packetSend: Array<UInt8>? = nil;
        while ((startIndex + 3) < rawPayload.count) {
            if Array(rawPayload[startIndex...startIndex+3]) == startCode {
                
                packetSend = Array(rawPayload[0..<startIndex])
                
                rawPayload.removeSubrange(0..<startIndex)
                if first == true{
                    packetSend = [UInt8] ([0,0,0,1]) + packetSend!
                    first = false
                }
                
                //Update the payload and send the RTP packet
                var tmpNALUPacket = packetSend!
                self.receivedRawVideoFrame(&tmpNALUPacket)
                
                
                if DEBUG{
//                    Data(packetSend!).hex()
                }
                startIndex = 4
            }
            startIndex += 1
        }
        
        //Only one Fragmented Packet.
        if first == true{
            rawPayload = [UInt8] ([0,0,0,1]) + rawPayload
            
        }
        
        
        //Update the payload and send the RTP packet in RTP.payload
        self.receivedRawVideoFrame(&rawPayload)
        if DEBUG{
//            Data(rawPayload).hex()
        }
        
        
        
        //        self.receivedRawVideoFrame(&pck)    //This is where we revceive the packet and process it. Here we have to receive the packet.
        
        
    }
    
    
    //Here we receive the RTP Packets from the RTPParser. We need to pass this to the Video Defragmenter
    func didReceiveRTPPacket(packet: RTPPacket) {
        guard packet.payload.count > 0 else {
            print("Received packet with empty payload")
            return
        }
        //packet.payload.hex()
        //1. Got Data and parsed datagram packet into RTP packet. Now this is send to Defragmnenter.
        self.defragmenter?.didReceiveRTPPacket(rtpPacket: packet)
        
    }
    
    
    
    func configDecoding(fromFile: Bool){
        
        //Comment 1. Layer which will process the CMSample packet and parse CMSampleBuffers.
        videoLayer = AVSampleBufferDisplayLayer()
        
        if let layer = videoLayer {
            let screenSize     = UIScreen.main.bounds
            let screenWidth    = screenSize.width
            let screenHeight   = screenSize.height
            layer.frame        = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
            layer.videoGravity = AVLayerVideoGravity.resizeAspect
            
            let _CMTimebasePointer = UnsafeMutablePointer<CMTimebase?>.allocate(capacity: 1)
            let status             = CMTimebaseCreateWithMasterClock( allocator: kCFAllocatorDefault, masterClock: CMClockGetHostTimeClock(),  timebaseOut: _CMTimebasePointer )
            layer.controlTimebase  = _CMTimebasePointer.pointee
            
            if let controlTimeBase = layer.controlTimebase, status == noErr {
                CMTimebaseSetTime(controlTimeBase, time: CMTime.zero);
                CMTimebaseSetRate(controlTimeBase, rate: 1.0);
            }
            
            self.view.layer.addSublayer(layer)
            
        }
        
        //Comment 2: Read the NALUnits from File and decode the VIDEO.
        if fromFile == true{
            DispatchQueue.global().async {
                let filePath = Bundle.main.path(forResource: self.source!, ofType: "h264")
                let url = URL(fileURLWithPath: filePath!)
                self.decodeFile(url)
            }
        }
    }
    
    func decodeFile(_ fileURL: URL) {
        
        let videoReader = VideoFileReader()
        videoReader.openVideoFile(fileURL)
        
        while var packet = videoReader.netPacket() {//Comment 3: Read a NAL packet from the file. This is the funtion that we need to simulate form network.
            self.receivedRawVideoFrame(&packet)    //This is where we revceive the packet and process it. Here we have to receive the packet.
        }
        
    }
    
    func receivedRawVideoFrame(_ videoPacket: inout VideoPacket) {
        
        //        _ = Data(videoPacket).hex()
        //Comment 4: Replace start code with nal size for iOS.
        var biglen = CFSwapInt32HostToBig(UInt32(videoPacket.count - 4))
        memcpy(&videoPacket, &biglen, 4)
        
        let nalType = videoPacket[4] & 0x1F
        
        if DEBUG==true{
            print("\(TAG): Code:112 - Read Nalu size \(videoPacket.count)");
        }
        switch nalType {
        case 0x05:
            if DEBUG==true{
                
                print("\(TAG): Code:112 - Nal type is IDR frame")
            }
            if createDecompSession() {
                decodeVideoPacket(&videoPacket)
            }
        case 0x07:
            if DEBUG==true{
                print("\(TAG): Code:112 - Nal type is SPS")
            }
            spsSize = videoPacket.count - 4
            sps = Array(videoPacket[4..<videoPacket.count])
            
            //            _ = Data(videoPacket).hex()
        //            _ = Data(sps!).hex()
        case 0x08:
            if DEBUG==true{
                print("\(TAG): Code:112 - Nal type is PPS")
            }
            ppsSize = videoPacket.count - 4
            pps = Array(videoPacket[4..<videoPacket.count])
            
            //            _ = Data(videoPacket).hex()
        //            _ = Data(pps!).hex()
        default:
            if DEBUG==true{
                print("\(TAG): Code:112 - Nal type is B/P frame")
            }
            
            decodeVideoPacket(&videoPacket)
            break;
            
        }
        if DEBUG==true{
            print("\n")
        }
        
    }
    
    func decodeVideoPacket(_ videoPacket: inout VideoPacket) {
        //Comment 5: NAL Unit is being allocated to the pointer.
        let bufferPointer = UnsafeMutablePointer<UInt8>(mutating: videoPacket)
        
        var blockBuffer: CMBlockBuffer?
        var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,memoryBlock: bufferPointer, blockLength: videoPacket.count,
                                                        blockAllocator: kCFAllocatorNull,
                                                        customBlockSource: nil, offsetToData: 0, dataLength: videoPacket.count,
                                                        flags: 0, blockBufferOut: &blockBuffer)
        
        if status != kCMBlockBufferNoErr {
            return
        }
        
        var sampleBuffer: CMSampleBuffer?
        let sampleSizeArray = [videoPacket.count]
        
        status = CMSampleBufferCreateReady(allocator: kCFAllocatorDefault,
                                           dataBuffer: blockBuffer,
                                           formatDescription: formatDesc,
                                           sampleCount: 1, sampleTimingEntryCount: 0, sampleTimingArray: nil,
                                           sampleSizeEntryCount: 1, sampleSizeArray: sampleSizeArray,
                                           sampleBufferOut: &sampleBuffer)
        
        if let buffer = sampleBuffer, let session = decompressionSession, status == kCMBlockBufferNoErr {
            
            let attachments:CFArray? = CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: true)
            if let attachmentArray = attachments {
                let dic = unsafeBitCast(CFArrayGetValueAtIndex(attachmentArray, 0), to: CFMutableDictionary.self)
                
                CFDictionarySetValue(dic,
                                     Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                     Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
            }
            
            
            //Comment 6: diaplay with AVSampleBufferDisplayLayer by enqueing the buffer into the queue.
            self.videoLayer?.enqueue(buffer)
            
            displayProcessor.async(execute: {
                self.videoLayer?.setNeedsDisplay()
            })
            
            // or decompression to CVPixcelBuffer
            var flagOut = VTDecodeInfoFlags(rawValue: 0)
            var outputBuffer = UnsafeMutablePointer<CVPixelBuffer>.allocate(capacity: 1)
            
            status = VTDecompressionSessionDecodeFrame(session, sampleBuffer: buffer,
                                                       flags: [._EnableAsynchronousDecompression],
                                                       frameRefcon: &outputBuffer, infoFlagsOut: &flagOut)
            if status == noErr {
                if DEBUG==true{
                    print("VideoSession: OK!!!")
                }
            }else if(status == kVTInvalidSessionErr) {
                print("IOS8VT: Invalid session, reset decoder session");
            } else if(status == kVTVideoDecoderBadDataErr) {
                print("IOS8VT: decode failed status=\(status)(Bad data)");
            } else if(status != noErr) {
                print("IOS8VT: decode failed status=\(status)");
            }
        }
        else{
            print("*********************************\nError: SampleBuffer OR DecompressionSession OR Error Status Reveiced!!!!!\nBasically occurs for not having decompressionSession!\n*********************************")
        }
    }
    
    func createDecompSession() -> Bool{
        formatDesc = nil
        
        if let spsData = sps, let ppsData = pps {
            let pointerSPS = UnsafePointer<UInt8>(spsData)
            let pointerPPS = UnsafePointer<UInt8>(ppsData)
            
            // make pointers array
            let dataParamArray = [pointerSPS, pointerPPS]
            let parameterSetPointers = UnsafePointer<UnsafePointer<UInt8>>(dataParamArray)
            
            // make parameter sizes array
            let sizeParamArray = [spsData.count, ppsData.count]
            let parameterSetSizes = UnsafePointer<Int>(sizeParamArray)
            
            
            let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault, parameterSetCount: 2, parameterSetPointers: parameterSetPointers, parameterSetSizes: parameterSetSizes, nalUnitHeaderLength: 4, formatDescriptionOut: &formatDesc)
            
            if let desc = formatDesc, status == noErr {
                
                if let session = decompressionSession {
                    VTDecompressionSessionInvalidate(session)
                    decompressionSession = nil
                }
                
                var videoSessionM : VTDecompressionSession?
                
                let decoderParameters = NSMutableDictionary()
                let destinationPixelBufferAttributes = NSMutableDictionary()
                destinationPixelBufferAttributes.setValue(NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32), forKey: kCVPixelBufferPixelFormatTypeKey as String)
                
                var outputCallback = VTDecompressionOutputCallbackRecord()
                outputCallback.decompressionOutputCallback = decompressionSessionDecodeFrameCallback
                outputCallback.decompressionOutputRefCon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
                
                let status = VTDecompressionSessionCreate(allocator: kCFAllocatorDefault,
                                                          formatDescription: desc, decoderSpecification: decoderParameters,
                                                          imageBufferAttributes: destinationPixelBufferAttributes,outputCallback: &outputCallback,
                                                          decompressionSessionOut: &videoSessionM)
                
                if(status != noErr) {
                    print("\t\t VTD ERROR type: \(status)")
                }
                
                self.decompressionSession = videoSessionM
            }else {
                print("IOS8VT: reset decoder session failed status=\(status)")
            }
        }
        return true
    }
    
    func displayDecodedFrame(_ imageBuffer: CVImageBuffer?) {
        if DEBUG==true{
            
            print("\(TAG): Frame Parsed")
        }
    }
    
}

private func decompressionSessionDecodeFrameCallback(_ decompressionOutputRefCon: UnsafeMutableRawPointer?, _ sourceFrameRefCon: UnsafeMutableRawPointer?, _ status: OSStatus, _ infoFlags: VTDecodeInfoFlags, _ imageBuffer: CVImageBuffer?, _ presentationTimeStamp: CMTime, _ presentationDuration: CMTime) -> Void {
    
    let streamManager: ViewController = unsafeBitCast(decompressionOutputRefCon, to: ViewController.self)
    
    if status == noErr {
        // do something with your resulting CVImageBufferRef that is your decompressed frame
        streamManager.displayDecodedFrame(imageBuffer);
    }
    else{
        if status == kVTVideoDecoderBadDataErr{
            print("Error: \(status) -> kVTVideoDecoderBadDataErr")
        }
        else{
            print("ERROR in decoding Data!!- Error Code: \(status)")
            //https://stackoverflow.com/questions/29525000/how-to-use-videotoolbox-to-decompress-h-264-video-stream
        }
        
    }
}
