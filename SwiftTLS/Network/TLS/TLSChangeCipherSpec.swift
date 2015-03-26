//
//  TLSChangeCipherSpec.swift
//  Chat
//
//  Created by Nico Schmidt on 25.03.15.
//  Copyright (c) 2015 Nico Schmidt. All rights reserved.
//

import Foundation

class TLSChangeCipherSpec : TLSMessage
{
    init()
    {
        super.init(type: .ChangeCipherSpec)
    }
    
    required init?(inputStream: BinaryInputStreamType) {
        if let type : UInt8? = inputStream.read() {
            if type == 1 {
                super.init(type: .ChangeCipherSpec)
                return
            }
        }

        super.init(type: .ChangeCipherSpec)
        return nil
    }
    
    override func writeTo<Target : BinaryOutputStreamType>(inout target: Target) {
    }
}