//
//  entryModel.swift
//  Sugars
//
//  Created by Nat Dean-Lewis on 11/04/2021 AD.
//

import SwiftUI

public struct AnEntry: Codable {
    var _id: String
    let direction: String
    let sgv: Double
    let sysTime: String
    let mills: Int
    
}

extension AnEntry: Identifiable {
    public var id: String { return _id }
}
