//
//  Queue.swift
//  H264DecodeFromFile
//
//  Created by Anish Byanjankar on 2020/04/28.
//  Copyright © 2020 Anish Byanjankar. All rights reserved.
//

import Foundation

class Queue{
    
    var items:[Data] = []
    let serialQueue = DispatchQueue(label: "synchronous queue")
    var size: Int! = 0;
    
    func enqueue(element: Data)
    {
        self.items.append(element)
        self.size = self.items.count
        print("Enque: "+String(items.count))
        
    }
    
    func dequeue() -> Data?
    {
        serialQueue.sync {
            
            //            if items.isEmpty {
            //                sleep(1)
            //                let x = self.dequeue()
            //                return x;
            //            }
            //            else{
            let tempElement = items.first
           
            self.items.remove(at: 0)
            print("Dequeu: "+String(self.items.count))
            self.size = self.items.count
            return tempElement
            //            }
        }
    }
    
    func Size() -> Int{
        var count: Int!
        serialQueue.sync {
            count = self.items.count;
        }
        
        return count
    }
}

