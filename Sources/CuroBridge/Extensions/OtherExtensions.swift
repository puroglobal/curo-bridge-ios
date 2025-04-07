//
//  OtherExtensions.swift
//  CuroBridge
//
//  Created by Magnus Fernandes on 07/04/25.
//

import Foundation

extension String {
    func starts(withHexPrefix prefix: String) -> Bool {
        guard let range = self.range(of: prefix, options: .caseInsensitive) else {
            return false
        }
        return range.lowerBound == self.startIndex
    }
}

extension Double {
    func toFahrenheit() -> Double {
        let fahrenheit = (self * 9/5) + 32
        return Double(String(format: "%.1f", fahrenheit)) ?? 0.0
    }
}
