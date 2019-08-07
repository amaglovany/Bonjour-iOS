//
//  ServiceType.swift
//  Bonjour
//
//  Created by Artem Maglyovany on 11/1/17.
//  Copyright © 2017 Artem Maglyovany. All rights reserved.
//

import Foundation

struct ServiceType {
    private let name: String
    private let serviceProtocol: ServiceProtocol
    
    var value: String { return "_\(name)._\(serviceProtocol.value)" }
    
    static let test = ServiceType(name:  "test", serviceProtocol: .tcp)
    
    struct ServiceProtocol {
        let value: String
        
        static let tcp = ServiceProtocol(value: "tcp")
    }
}
