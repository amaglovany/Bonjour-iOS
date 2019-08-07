//
//  StringExtensions.swift
//  Bonjour
//
//  Created by Artem Maglyovany on 10/30/17.
//  Copyright © 2017 Artem Maglyovany. All rights reserved.
//

import Foundation

extension String {
    var utf8Data: Data? { return data(using: .utf8)}
}
