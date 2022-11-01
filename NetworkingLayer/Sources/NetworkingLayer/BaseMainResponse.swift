//
//  BaseMainResponse.swift
//  SmilesNetworkLayerTest
//
//  Created by Hanan Ahmed on 9/27/22.
//

import Foundation

struct BaseMainResponse : Codable {

    let additionalInfo : [BaseMainResponseAdditionalInfo]?
    let responseCode : String?
    let responseMsg : String?
    let errorCode : String?
    let errorMsg : String?
    let errorTitle: String?
}




struct BaseMainResponseAdditionalInfo : Codable {
    
    let name : String?
    let value : String?

}
