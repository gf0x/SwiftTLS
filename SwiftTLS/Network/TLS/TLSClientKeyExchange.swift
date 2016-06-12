//
//  TLSClientKeyExchange.swift
//
//  Created by Nico Schmidt on 21.03.15.
//  Copyright (c) 2015 Nico Schmidt. All rights reserved.
//

import Foundation

class PreMasterSecret : Streamable
{
    static let NumberOfRandomBytes = 46
    
    init(clientVersion : TLSProtocolVersion)
    {
        self.clientVersion = clientVersion
        
        self.random = [UInt8](count: PreMasterSecret.NumberOfRandomBytes, repeatedValue: 0)
        
        arc4random_buf(&self.random, PreMasterSecret.NumberOfRandomBytes)
    }
    
    var clientVersion : TLSProtocolVersion
    var random : [UInt8] // 46 bytes
    
    required init?(inputStream : InputStreamType)
    {
        if  let major : UInt8 = inputStream.read(),
            let minor : UInt8 = inputStream.read(),
            let bytes : [UInt8] = inputStream.read(count: Random.NumberOfRandomBytes)
        {
            if let version = TLSProtocolVersion(major: major, minor: minor) {
                self.clientVersion = version
                self.random = bytes
                
                return
            }
        }

        return nil
    }
    
    func writeTo<Target : OutputStreamType>(inout target: Target) {
        target.write(self.clientVersion.rawValue)
        target.write(random)
    }
}

class TLSClientKeyExchange : TLSHandshakeMessage
{
    var encryptedPreMasterSecret : [UInt8]?
    var diffieHellmanPublicKey : BigInt?
    var ecdhPublicKey : EllipticCurvePoint?
    
    init(preMasterSecret : [UInt8], publicKey : CryptoKey)
    {
        if let crypttext = publicKey.encrypt(preMasterSecret) {
            self.encryptedPreMasterSecret = crypttext
        }
        else {
            self.encryptedPreMasterSecret = []
            assert(false)
        }
        
        super.init(type: .Handshake(.ClientKeyExchange))
    }
    
    init(diffieHellmanPublicKey : BigInt)
    {
        self.diffieHellmanPublicKey = diffieHellmanPublicKey
        
        super.init(type: .Handshake(.ClientKeyExchange))
    }
    
    init(ecdhPublicKey : EllipticCurvePoint)
    {
        self.ecdhPublicKey = ecdhPublicKey
        
        super.init(type: .Handshake(.ClientKeyExchange))
    }

    required init?(inputStream : InputStreamType, context: TLSContext)
    {
        guard let (type, _) = TLSHandshakeMessage.readHeader(inputStream) else {
            return nil
        }
        
        // TODO: check consistency of body length and the data following
        if type == TLSHandshakeType.ClientKeyExchange {

            switch context.keyExchange {
            case .ECDHE:
                if let rawPublicKeyPoint : [UInt8] = inputStream.read8() {
                    guard let ecdhPublicKey = EllipticCurvePoint(data: rawPublicKeyPoint) else { return nil }
                    self.ecdhPublicKey = ecdhPublicKey
                }
            
            case .DHE:
                if let data : [UInt8] = inputStream.read16() {
                    self.diffieHellmanPublicKey = BigInt(bigEndianParts: data)
                }
                    
            case .RSA:
                if let data : [UInt8] = inputStream.read16() {
                        self.encryptedPreMasterSecret = data
                }
            }
            
            super.init(type: .Handshake(.ClientKeyExchange))
            
            return
        }
        
        return nil        
    }

    override func writeTo<Target : OutputStreamType>(inout target: Target)
    {
        if let encryptedPreMasterSecret = self.encryptedPreMasterSecret {
            self.writeHeader(type: .ClientKeyExchange, bodyLength: encryptedPreMasterSecret.count + 2, target: &target)
            target.write(UInt16(encryptedPreMasterSecret.count))
            target.write(encryptedPreMasterSecret)
        }
        else if let diffieHellmanPublicKey = self.diffieHellmanPublicKey {
            let diffieHellmanPublicKeyData = diffieHellmanPublicKey.asBigEndianData()

            self.writeHeader(type: .ClientKeyExchange, bodyLength: diffieHellmanPublicKeyData.count + 2, target: &target)
            target.write(UInt16(diffieHellmanPublicKeyData.count))
            target.write(diffieHellmanPublicKeyData)
        }
        else if let ecdhPublicKey = self.ecdhPublicKey {
            let Q = ecdhPublicKey
            let data = Q.x.asBigEndianData() + Q.y.asBigEndianData()
            
            self.writeHeader(type: .ClientKeyExchange, bodyLength: data.count + 2, target: &target)
            target.write(UInt8(data.count + 1))
            target.write(UInt8(4)) // uncompressed ECPoint encoding
            target.write(data)
        }

    }
}
