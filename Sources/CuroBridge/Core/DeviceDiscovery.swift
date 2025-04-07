//
//  DeviceDiscovery.swift
//  CuroBridge
//
//  Created by Magnus Fernandes on 05/04/25.
//

import Foundation
import CoreBluetooth

public class DeviceDiscovery: NSObject {
    public var updateOtoscopeEspId: ((String) -> Void)?
    
    var centralManager: CBCentralManager?
    
    var allPeripherals: [CBPeripheral] = []
    
    var alphaDevice: CBPeripheral?
    var stethoscopeDevice: CBPeripheral?
    
    var alphaStatusCharacteristic: CBCharacteristic?
    var alphaModuleCharacteristic: CBCharacteristic?
    
    // managers
    var alphaStatusManager: AlphaStatusManager?
    var alphaModuleManager: AlphaModuleManager?
    
    func startDeviceDiscovery() {
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func connectDevice(_ peripheral: CBPeripheral) {
        self.centralManager?.connect(peripheral)
    }
    
    func disconnectDevice(_ peripheral: CBPeripheral) {
        self.centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    func clearDeviceList() {
        allPeripherals.removeAll()
    }
}

extension DeviceDiscovery {
    func setAlphaStatusManager(_ manager: AlphaStatusManager) {
        self.alphaStatusManager = manager
    }
    
    func setAlphaModuleManager(_ manager: AlphaModuleManager) {
        self.alphaModuleManager = manager
    }
}

extension DeviceDiscovery: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.centralManager?.scanForPeripherals(withServices: CuroUUIDs.curoServices)
        default:
            print("Unhandled state: ", central.state)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !allPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            self.allPeripherals.append(peripheral)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(CuroUUIDs.curoServices)
    }
}

extension DeviceDiscovery: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error = error {
            print("Error discovering services: \(error)")
            return
        }
        
        guard let services = peripheral.services else { return }
        for service in services {
            if service == CuroUUIDs.alphaService {
                alphaDevice = peripheral
            } else if service == CuroUUIDs.stethoscopeService {
                stethoscopeDevice = peripheral
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error = error {
            print("Error discovering characteristics: \(error)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            checkCharacteristics(characteristic)
        }
    }
    
    public func checkCharacteristics(_ characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CuroUUIDs.alphaStatusCharacteristic:
            self.alphaStatusCharacteristic = characteristic
            enableNotifyForCharacteristic(peripheral: self.alphaDevice, characteristic: characteristic)
        case CuroUUIDs.alphaModuleCharacteristic:
            self.alphaModuleCharacteristic = characteristic
            enableNotifyForCharacteristic(peripheral: self.alphaDevice, characteristic: characteristic)
        default:
            print("Unknown characteristic: ", characteristic.uuid.uuidString)
        }
    }
}

extension DeviceDiscovery {
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            print("Error writing to characteristics: \(error)")
            return
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            print("Error reading value for characteristics: \(error)")
            return
        }
        
        if let value = characteristic.value {
            switch characteristic {
            case CuroUUIDs.alphaStatusCharacteristic:
                alphaStatusManager?.processPayload(value)
            case CuroUUIDs.alphaModuleCharacteristic:
                alphaModuleManager?.processPayload(value)
            default:
                print("Unhandled characteristics: \(characteristic.uuid.uuidString)")
            }
        }
    }
}

extension DeviceDiscovery {
    func enableNotifyForCharacteristic(peripheral: CBPeripheral?, characteristic: CBCharacteristic?) {
        if let peripheral = peripheral, let characteristic = characteristic {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
}
