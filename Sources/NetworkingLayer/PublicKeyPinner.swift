//
//  PublicKeyPinner.swift
//  House
//
//  Created by Abdul Rehman Amjad on 13/02/2023.
//  Copyright © 2023 Ahmed samir ali. All rights reserved.
//

import Foundation
import CryptoKit
import CryptoSwift

@objc final class PublicKeyPinner: NSObject {
    /// Stored public key hashes
    private var hashes = [String]()

    override init() {
        if let hashKey = Bundle.main.infoDictionary?["SSL_HASH_KEY"] as? String {
            print("HASH KEY: \(hashKey)")
            self.hashes.append(hashKey)
        }
    }

    /// ASN1 header for our public key to re-create the subject public key info
    private let rsa2048Asn1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]

    /// Validates an object used to evaluate trust's certificate by comparing their's public key hashes to the known, trused key hashes stored in the app
    /// Configuration.
    /// - Parameter serverTrust: The object used to evaluate trust.
    @objc func validate(serverTrust: SecTrust) -> Bool {
        
        // Set SSL policies for domain name check, if needed
//        if let domain = domain {
//            let policies = NSMutableArray()
//            policies.add(SecPolicyCreateSSL(true, domain as CFString))
//            SecTrustSetPolicies(serverTrust, policies)
//        }
        
        // Check if the trust is valid
        let isValid = SecTrustEvaluateWithError(serverTrust, nil)

        guard isValid else { return false }

        // For each certificate in the valid trust:
        for index in 0..<SecTrustGetCertificateCount(serverTrust) {
            // Get the public key data for the certificate at the current index of the loop.
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, index),
                  let publicKey = SecCertificateCopyKey(certificate),
                let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) else {
                    return false
            }

            // Hash the key, and check it's validity.
            let keyHash = hash(data: (publicKeyData as NSData) as Data)
            if hashes.contains(keyHash) {
                // Success! This is our server!
                return true
            }
        }

        // If none of the calculated hashes match any of our stored hashes, the connection we tried to establish is untrusted.
        return false
    }

    /// Creates a hash from the received data using the `sha256` algorithm.
    /// `Returns` the `base64` encoded representation of the hash.
    ///
    /// To replicate the output of the `openssl dgst -sha256` command, an array of specific bytes need to be appended to
    /// the beginning of the data to be hashed.
    /// - Parameter data: The data to be hashed.
    private func hash(data: Data) -> String {
        // Add the missing ASN1 header for public keys to re-create the subject public key info
        var keyWithHeader = Data(rsa2048Asn1Header)
        keyWithHeader.append(data)

        return keyWithHeader.sha256().base64EncodedString()
    }
}
