//
//  SwiftyRSAError.swift
//  SwiftyRSA
//
//  Created by Lois Di Qual on 5/15/17.
//  Contributions by Stchepinsky Nathan on 24/06/2021
//  Copyright © 2017 Scoop. All rights reserved.
//

import Foundation

public enum SwiftyRSAError: Error {

    case pemDoesNotContainKey
    case keyRepresentationFailed(error: CFError?)
    case keyGenerationFailed(error: CFError?)
    case keyCreateFailed(error: CFError?)
    case keyAddFailed(status: OSStatus)
    case keyCopyFailed(status: OSStatus)
    case tagEncodingFailed
    case asn1ParsingFailed
    case invalidAsn1RootNode
    case invalidAsn1Structure
    case invalidBase64String
    case chunkDecryptFailed(index: Int)
    case chunkEncryptFailed(index: Int)
    case stringToDataConversionFailed
    case dataToStringConversionFailed
    case invalidDigestSize(digestSize: Int, maxChunkSize: Int)
    case signatureCreateFailed(status: OSStatus)
    case signatureVerifyFailed(status: OSStatus)
    case pemFileNotFound(name: String)
    case derFileNotFound(name: String)
    case notAPublicKey
    case notAPrivateKey
    case x509CertificateFailed

    var localizedDescription: String {
        switch self {
        case .pemDoesNotContainKey:
            return "Couldn't get data from PEM key: no data available after stripping headers"
        case let .keyRepresentationFailed(error):
            return "Couldn't retrieve key data from the keychain: CFError \(String(describing: error))"
        case let .keyGenerationFailed(error):
            return "Couldn't generate key pair: CFError: \(String(describing: error))"
        case let .keyCreateFailed(error):
            return "Couldn't create key reference from key data: CFError \(String(describing: error))"
        case let .keyAddFailed(status):
            return "Couldn't retrieve key data from the keychain: OSStatus \(status)"
        case let .keyCopyFailed(status):
            return "Couldn't copy and retrieve key reference from the keychain: OSStatus \(status)"
        case .tagEncodingFailed:
            return "Couldn't create tag data for key"
        case .asn1ParsingFailed:
            return "Couldn't parse the ASN1 key data. Please file a bug at https://goo.gl/y67MW6"
        case .invalidAsn1RootNode:
            return "Couldn't parse the provided key because its root ASN1 node is not a sequence. The key is probably corrupt"
        case .invalidAsn1Structure:
            return "Couldn't parse the provided key because it has an unexpected ASN1 structure"
        case .invalidBase64String:
            return "The provided string is not a valid Base 64 string"
        case let .chunkDecryptFailed(index):
            return "Couldn't decrypt chunk at index \(index)"
        case let .chunkEncryptFailed(index):
            return "Couldn't encrypt chunk at index \(index)"
        case .stringToDataConversionFailed:
            return "Couldn't convert string to data using specified encoding"
        case .dataToStringConversionFailed:
            return "Couldn't convert data to string representation"
        case let .invalidDigestSize(digestSize, maxChunkSize):
            return "Provided digest type produces a size (\(digestSize)) that is bigger than the maximum chunk size \(maxChunkSize) of the RSA key"
        case let .signatureCreateFailed(status):
            return "Couldn't sign provided data: OSStatus \(status)"
        case let .signatureVerifyFailed(status):
            return "Couldn't verify signature of the provided data: OSStatus \(status)"
        case let .pemFileNotFound(name):
            return "Couldn't find a PEM file named '\(name)'"
        case let .derFileNotFound(name):
            return "Couldn't find a DER file named '\(name)'"
        case .notAPublicKey:
            return "Provided key is not a valid RSA public key"
        case .notAPrivateKey:
            return "Provided key is not a valid RSA pivate key"
        case .x509CertificateFailed:
            return "Couldn't prepend the provided key because it has an unexpected structure"
        }
    }
}
