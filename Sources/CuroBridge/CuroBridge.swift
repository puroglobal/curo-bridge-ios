import Foundation
import CoreBluetooth

public struct CuroBridge {
    public let deviceDiscovery: DeviceDiscovery
    public let alphaStatusManager: AlphaStatusManager
    public let alphaModuleManager: AlphaModuleManager
    
    public init() {
        self.deviceDiscovery = DeviceDiscovery()
        self.alphaStatusManager = AlphaStatusManager()
        self.alphaModuleManager = AlphaModuleManager()
        
        deviceDiscovery.setAlphaStatusManager(alphaStatusManager)
        deviceDiscovery.setAlphaModuleManager(alphaModuleManager)
    }
}

