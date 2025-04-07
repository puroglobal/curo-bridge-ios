//
//  AlphaModuleManager.swift
//  CuroBridge
//
//  Created by Magnus Fernandes on 07/04/25.
//

import Foundation

public enum ModuleError: Error {
    case temperatureReadingError
    case oximeterReadingError
}

extension ModuleError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .temperatureReadingError:
            return "Encountered an error while reading the temperature"
        case .oximeterReadingError:
            return "Encountered an error while reading the oximeter"
        }
    }
}

public class AlphaModuleManager {
    public var onTemperatureReading: ((Double, Double) -> Void)?
    public var onOximetry: ((Int, Int) -> Void)?
    public var onError: ((ModuleError) -> Void)?
    
    func processPayload(_ payload: Data) {
        let payloadStr = String(decoding: payload, as: UTF8.self)
        if payloadStr.starts(with: "OB:") {
            processTemperature(payloadStr)
        } else if payloadStr.starts(with: "HR:") {
            processOximeter(payloadStr)
        }
    }
    
    func processTemperature(_ payloadString: String) {
        let temperatures = payloadString.components(separatedBy: ",")
        if temperatures.count == 2 {
            let celsiusReading = temperatures[0].replacingOccurrences(of: "OB:", with: "")
            let celsius = Double(celsiusReading) ?? 0
            if celsius > 0 {
                onTemperatureReading?(celsius, celsius.toFahrenheit())
            } else {
                onError?(.temperatureReadingError)
            }
        } else {
            onError?(.temperatureReadingError)
        }
    }
    
    func processOximeter(_ payloadString: String) {
        let oximeterReadings = payloadString.components(separatedBy: ",")
        if oximeterReadings.count == 2 {
            let pulseRateString = oximeterReadings[0].replacingOccurrences(of: "HR:", with: "")
            let oxygenSaturationString = oximeterReadings[1].replacingOccurrences(of: "O2:", with: "")
            
            let pulseRate = Double(pulseRateString) ?? 0
            var oxygenSaturation = Double(oxygenSaturationString) ?? 0
            
            if oxygenSaturation > 0 && oxygenSaturation < 100 {
                // delta fix
                if oxygenSaturation > 50 {
                    oxygenSaturation = oxygenSaturation + 1
                }
                onOximetry?(
                    Int(oxygenSaturation.rounded()),
                    Int(pulseRate.rounded())
                )
            } else {
                onError?(.oximeterReadingError)
            }
        } else {
            onError?(.oximeterReadingError)
        }
    }
}
