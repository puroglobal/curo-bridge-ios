//
//  AlphaStatusManager.swift
//  CuroBridge
//
//  Created by Magnus Fernandes on 06/04/25.
//

import Foundation

class AlphaStatusManager {
    var onDeviceStatus: ((Int) -> Void)?
    var onCameraIdReceived: ((String) -> Void)?
    var onIpReceived: ((String) -> Void)?
    
    func processPayload(_ payload: Data) {
        let statusStr = String(decoding: payload, as: UTF8.self)
        if statusStr.starts(with: "STAT:") {
            processStatus(statusStr)
        } else if statusStr.starts(with: "ID:") {
            processCameraId(statusStr)
        } else if statusStr.starts(with: "IP:") {
            processDeviceIp(statusStr)
        }
    }
    
    func processStatus(_ statusString: String) {
        let status = statusString.replacingOccurrences(of: "STAT:", with: "")
        if let statusInt = Int(status) {
            onDeviceStatus?(statusInt)
        }
    }
    
    func processCameraId(_ statusString: String) {
        let cameraID = statusString.replacingOccurrences(of: "ID:", with: "")
        onCameraIdReceived?(cameraID)
    }
    
    func processDeviceIp(_ statusString: String) {
        let ipString = statusString.replacingOccurrences(of: "IP:", with: "")
        if ipString.count > 0 && ipString != "0.0.0.0" {
            onIpReceived?(ipString)
        }
    }
}
