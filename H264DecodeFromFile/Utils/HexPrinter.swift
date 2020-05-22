//
//  HexPrinter.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/04/28.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation


extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hex(options: HexEncodingOptions = []) {
        let format = options.contains(.upperCase) ? "%02hhX " : "%02hhx "
        print( map { String(format: format, $0) }.joined())
    }
}


func hex(_ data: [UInt8]){
    print(Data(data).hex())
}
