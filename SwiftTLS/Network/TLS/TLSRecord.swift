//
//  TLSRecord.swift
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

class TLSRecord : Streamable {
    var contentType : ContentType
    var protocolVersion : TLSProtocolVersion
    var body : [UInt8]
    
    required init?(inputStream: InputStreamType) {
        
        var contentType : ContentType?
        var protocolVersion : TLSProtocolVersion?
        var body : [UInt8]?
        
        if let c : UInt8 = inputStream.read() {
            if let ct = ContentType(rawValue: c) {
                contentType = ct
            }
        }
        
        if let major : UInt8? = inputStream.read(),
            minor : UInt8? = inputStream.read(),
            v = TLSProtocolVersion(major: major!, minor: minor!)
        {
            protocolVersion = v
        }
        
        if let bodyLength : UInt16 = inputStream.read() {
            body = inputStream.read(count: Int(bodyLength))
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
            return nil
        }
    }
    
    init(contentType : ContentType, protocolVersion: TLSProtocolVersion, body : [UInt8])
    {
        self.contentType = contentType
        self.protocolVersion = protocolVersion
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
        
        let rawContentType = headerData[0]
        if let contentType = ContentType(rawValue: rawContentType) {
            let bodyLength = Int(headerData[3]) << 8 + Int(headerData[4])
            return (contentType, bodyLength)
        }
        
        return nil
    }
    
    class func writeRecordHeader<Target : OutputStreamType>(inout target: Target, contentType: ContentType, protocolVersion : TLSProtocolVersion, contentLength : Int)
    {
        target.write(contentType.rawValue)
        target.write(protocolVersion.rawValue)
        target.write(UInt16(contentLength))
    }
    
    func writeTo<Target : OutputStreamType>(inout target: Target)
    {
        self.dynamicType.writeRecordHeader(&target, contentType: self.contentType, protocolVersion: self.protocolVersion, contentLength: self.body.count)
        target.write(self.body)
    }
}
