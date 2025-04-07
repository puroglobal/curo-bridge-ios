import Foundation
import CoreBluetooth

public struct CuroBridge {
    let deviceDiscovery = DeviceDiscovery()
    
    let alphaStatusManager = AlphaStatusManager()
    let alphaModuleManager = AlphaModuleManager()
    
    init() {
        deviceDiscovery.setAlphaStatusManager(alphaStatusManager)
        deviceDiscovery.setAlphaModuleManager(alphaModuleManager)
    }
}
