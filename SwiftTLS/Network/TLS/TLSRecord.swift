//
//  TLSRecord.swift
//  Chat
//
//  Created by Nico Schmidt on 14.03.15.
//  Copyright (c) 2015 Nico Schmidt. All rights reserved.
//

import Foundation

enum ContentType : UInt8 {
    case ChangeCipherSpec = 20
    case Alert = 21
    case Handshake = 22
    case ApplicationData = 23
}

let TLS_RecordHeaderLength = 5

class TLSRecord : BinaryStreamable, BinaryReadable {
    var contentType : ContentType
    var protocolVersion : ProtocolVersion
    var body : [UInt8]
    
    required init?(inputStream: BinaryInputStreamType) {
        
        var contentType : ContentType?
        var protocolVersion : ProtocolVersion?
        var body : [UInt8]?
        
        if let c : UInt8 = inputStream.read() {
            if let ct = ContentType(rawValue: c) {
                contentType = ct
            }
        }
        
        if let major : UInt8? = inputStream.read(),
            minor : UInt8? = inputStream.read(),
            v = ProtocolVersion(major: major!, minor: minor!)
        {
            protocolVersion = v
        }
        
        if let bodyLength : UInt16 = inputStream.read() {
            body = inputStream.read(Int(bodyLength))
        }

        if  let c = contentType,
            let v = protocolVersion,
            let b = body
        {
            self.contentType = c
            self.protocolVersion = v
            self.body = b
        }
        else {
            self.contentType = .Alert
            self.protocolVersion = .TLS_v1_0
            self.body = []
            
            return nil
        }
    }
    
    init(var contentType : ContentType, var body : [UInt8])
    {
        self.contentType = contentType
        self.protocolVersion = .TLS_v1_0
        self.body = body
    }
    
    class var headerProbeLength : Int {
        get {
            return TLS_RecordHeaderLength
        }
    }
    
    class func probeHeader(headerData : [UInt8]) -> (contentType: ContentType, bodyLength : Int)?
    {
        if headerData.count < TLS_RecordHeaderLength {
            return nil
        }
        
        var rawContentType = headerData[0]
        if let contentType = ContentType(rawValue: rawContentType) {
            var bodyLength = Int(headerData[3]) << 8 + Int(headerData[4])
            return (contentType, bodyLength)
        }
        
        return nil
    }
    
    func writeTo<Target : BinaryOutputStreamType>(inout target: Target) {
        target.write(self.contentType.rawValue)
        target.write(self.protocolVersion.rawValue)
        target.write(UInt16(self.body.count))
        target.write(self.body)
    }
}
