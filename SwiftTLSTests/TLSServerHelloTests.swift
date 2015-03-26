//
//  TLSServerHelloTests.swift
//  Chat
//
//  Created by Nico Schmidt on 15.03.15.
//  Copyright (c) 2015 Nico Schmidt. All rights reserved.
//

import Cocoa
import XCTest

class TLSServerHelloTests: XCTestCase {
    
    func test_writeTo__givesCorrectBinaryRepresentation() {
        var random = Random()
        var clientHello = TLSServerHello(
            serverVersion: ProtocolVersion.TLS_v1_0,
            random: random,
            sessionID: nil,
            cipherSuite: .TLS_RSA_WITH_RC4_128_SHA,
            compressionMethod: .NULL)
        
        var buffer = DataBuffer()
        clientHello.writeTo(&buffer)
        
        var expectedData = [UInt8]([TLSHandshakeType.ClientHello.rawValue, 0, 0, 38, 3, 1])
        var randomData = DataBuffer()
        random.writeTo(&randomData)
        expectedData.extend(randomData.buffer)
        expectedData.extend([0, 0, 5, 0])
        XCTAssert(buffer.buffer == expectedData)
    }
    
    var testServerHelloData : [UInt8] {
        get {
            var rc4_md5  = CipherSuite.TLS_RSA_WITH_RC4_128_MD5.rawValue
            var nullCompressionMethod = CompressionMethod.NULL.rawValue
            
            return [UInt8]([TLSHandshakeType.ServerHello.rawValue, 0, 0, 41, 3, 1,
                // random
                1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16,
                17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
                // sessionID
                32,
                1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16,
                17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
                // cipher suite
                UInt8((rc4_md5) >> 8), UInt8(rc4_md5 & 0xff),
                // compression method
                nullCompressionMethod])
        }
    }
    
    func test_initWithBinaryInputStream_givesClientHello() {
        var serverHello = TLSServerHello(inputStream: BinaryInputStream(data: self.testServerHelloData))
        
        XCTAssert(serverHello != nil)
    }
    
    func test_initWithBinaryInputStream_hasCorrectRandom() {
        var serverHello = TLSServerHello(inputStream: BinaryInputStream(data: self.testServerHelloData))
        
        var expectedRandom = Random(inputStream: BinaryInputStream(data: [UInt8]([1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16,
            17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32])))!
        
        var random = serverHello!.random
        
        XCTAssert(random.randomBytes == expectedRandom.randomBytes && random.gmtUnixTime == expectedRandom.gmtUnixTime)
    }
    
    func test_initWithBinaryInputStream_hasCorrectCipherSuites() {
        var serverHello = TLSServerHello(inputStream: BinaryInputStream(data: self.testServerHelloData))
        
        var expectedCiperSuite = CipherSuite.TLS_RSA_WITH_RC4_128_MD5
        
        XCTAssert(serverHello!.cipherSuite == expectedCiperSuite)
    }
    
}
