//
//  ErrorManager.swift
//  DeezerSampleSwift
//
//  Created by Steven Martreux on 09/11/2017.
//  Copyright © 2017 Steven Martreux. All rights reserved.
//

import Foundation

let domainDeezerSDK = "com.DeezerSampleSwift.errorSDK"

enum DeezerErrorType: Int, Error {
    case noConnection            = -1009
    case quota                  = 4
    case itemLimitExceeded      = 100
    case permission             = 200
    case tokenInvalid           = 300
    case parameter              = 500
    case parameterMissing       = 501
    case queryInvalid           = 600
    case serviceBusy            = 700
    case dataNotFound           = 800
    case unknownError          = 666
    
    var description: String {
        switch self {
        case .noConnection:
            return "The internet connection appears to be offline CODE = \(self.rawValue)"
        case .quota:
            return "Quota invalid CODE = \(self.rawValue)"
        case .itemLimitExceeded:
            return "Item limit exceeded CODE = \(self.rawValue)"
        case .permission:
            return "Permission invalid CODE = \(self.rawValue)"
        case .tokenInvalid:
            return "Token invalid CODE = \(self.rawValue)"
        case .parameter:
            return "Need parameter CODE = \(self.rawValue)"
        case .parameterMissing:
            return "Missing parameter CODE = \(self.rawValue)"
        case .queryInvalid:
            return "Your query is invalide CODE = \(self.rawValue)"
        case .serviceBusy:
            return "Service is busy please try later CODE = \(self.rawValue)"
        case .dataNotFound:
            return "Not data found  = \(self.rawValue)"
        default:
            return "An unknown error occured CODE = \(self.rawValue)"
        }
    }
}

extension Error {
    
    static func instance(type: DeezerErrorType, userInfo: [String: Any]? = nil) -> Error {
        return NSError(domain: domainDeezerSDK, code: type.rawValue, userInfo: userInfo) as Error
    }
 
    var type: DeezerErrorType {return DeezerErrorType(rawValue: code) ?? .unknownError}
    var code: Int {return (self as NSError).code}
    var domain: String {return (self as NSError).domain}
    
}
