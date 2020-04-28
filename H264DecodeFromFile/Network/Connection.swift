 //
//  Connection.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/04/27.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation
import Network
 
 protocol Connection {
    func Receive()->Data?;
    func Send(data: Data)->Bool;
 }
