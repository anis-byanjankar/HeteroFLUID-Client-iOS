import Foundation
import Network

@available(macOS 10.14, *)
class TCPClient {
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port
    
    let queue = DispatchQueue(label: "TCP Client Packet Receiver Queue")
    var nwConnection: NWConnection? = nil
    var connected: Bool = false
    var delegate: TransportDelegate?
    
    
    init(host: String, port: UInt16, delegate: TransportDelegate?) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
        self.delegate = nil
        
        self.start()
        
        
    }
    
    
    func start() {
        print("\nConnecting to \(host) \(port)")
        self.nwConnection = NWConnection(host: self.host, port: self.port, using: .tcp)
        self.nwConnection?.stateUpdateHandler = stateDidChange(to:)
        self.nwConnection?.start(queue: queue)
        
        
        
    }
    
    
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            self.connected = true
            self.setupReceive()
            let r: String = "Client Says Hello!"
            _ = self.send(data: r.data(using: .utf8)!)
            print("Client connection ready")
        case .failed(let error):
            connectionDidFail(error: error)
        default:
            break
        }
    }
    
    
    //Connection
    
    
    
    private func setupReceive() {
        self.nwConnection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                self.delegate?.datagramReceived([UInt8] (data))
                
                if isComplete {
                    print("Connection Completed!!")
                } else if let error = error {
                    self.connectionDidFail(error: error)
                } else {
                    self.setupReceive()
                }
            }
        }
    }
    
    
//    func processStream(){
//        //        while true{
//        //            self.receivedDataHandlerQueue.sync {
//        if self.receivedPacket!.count>14{
//            let headerChunk = [UInt8] (self.receivedPacket![0...13])
//            let dataLength = ByteUtil.bytesToUInt16(headerChunk[12...13])
//
//            let rtpPacketRaw = self.receivedPacket![0...dataLength-1]
//            self.receivedPacket = self.receivedPacket![dataLength...]
//            self.receivedPacket!.hex()
//            rtpPacketRaw.hex()
//        }
//
//        //            }
//        //        }
//    }
    
    
    func send(data: Data) -> Bool{
        self.nwConnection?.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                print("Error while sending data to server...")
                self.connectionDidFail(error: error)
                return
            }
        }))
        return true
    }
    
    func stop() {
        print("connection will stop")
        stop(error: nil)
    }
    
    private func connectionDidFail(error: Error) {
        print("Connection did fail, error: \(error)")
        self.stop(error: error)
    }
    
    private func connectionDidEnd() {
        print("connection did end")
        self.stop(error: nil)
    }
    
    private func stop(error: Error?) {
        self.nwConnection?.stateUpdateHandler = nil
        self.nwConnection?.cancel()
        didStopCallback(error: error)
        
    }
    func didStopCallback(error: Error?) {
        
        print("\(String(describing: error))")
        
        //            print(error)
        //            exit(EXIT_FAILURE)
        
    }
}
