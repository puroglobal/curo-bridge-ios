//
//  DeviceDiscovery.swift
//  CuroBridge
//
//  Created by Magnus Fernandes on 05/04/25.
//

import Foundation
import CoreBluetooth

public class DeviceDiscovery: NSObject {
    public var onPeripheralListUpdated: (([CBPeripheral]) -> Void)?
    public var updateOtoscopeEspId: ((String) -> Void)?
    
    var centralManager: CBCentralManager?
    
    var servicesToScan = [CBUUID]()
    var allPeripherals: [CBPeripheral] = []
    
    var alphaDevice: CBPeripheral?
    var stethoscopeDevice: CBPeripheral?
    
    var alphaStatusCharacteristic: CBCharacteristic?
    var alphaModuleCharacteristic: CBCharacteristic?
    
    // managers
    var alphaStatusManager: AlphaStatusManager?
    var alphaModuleManager: AlphaModuleManager?
    
    public func startDeviceDiscovery(_ devices: [CuroDevice]?) {
        let deviceTypes = devices ?? [CuroDevice.alpha, CuroDevice.stethoscope]
        servicesToScan.removeAll()
        if deviceTypes.contains(where: { deviceType in
            deviceType == .alpha
        }) {
            servicesToScan.append(CuroUUIDs.alphaService)
        }
        if deviceTypes.contains(where: { deviceType in
            deviceType == .stethoscope
        }) {
            servicesToScan.append(CuroUUIDs.stethoscopeService)
        }
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    public func connectDevice(_ peripheral: CBPeripheral) {
        self.centralManager?.connect(peripheral)
    }
    
    public func disconnectDevice(_ peripheral: CBPeripheral) {
        self.centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    public func clearDeviceList() {
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
            self.centralManager?.scanForPeripherals(withServices: servicesToScan)
        default:
            print("Unhandled state: ", central.state)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !allPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            self.allPeripherals.append(peripheral)
            self.onPeripheralListUpdated?(self.allPeripherals)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to device: \(peripheral.name ?? "Unknown device")")
        peripheral.delegate = self
        peripheral.discoverServices(servicesToScan)
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
            peripheral.discoverCharacteristics(nil, for: service)
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
        print("Found characteristic: \(characteristic.uuid.uuidString)")
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
            print("Characteristic \(characteristic.uuid.uuidString) value: \(String(decoding: value, as: UTF8.self))")
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
        print("enableNotifyForCharacteristic: \(characteristic?.uuid.uuidString ?? "N/A")")
        if let peripheral = peripheral, let characteristic = characteristic {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    public func writeToModuleCharacteristics(_ data: Data) {
        if let alphaModuleCharacteristic = self.alphaModuleCharacteristic {
            writeToAlpha(data: data, characteristic: alphaModuleCharacteristic)
        }
    }
    
    public func writeToStatusCharacteristics(_ data: Data) {
        if let alphaStatusCharacteristic = self.alphaStatusCharacteristic {
            writeToAlpha(data: data, characteristic: alphaStatusCharacteristic)
        }
    }
    
    private func writeToAlpha(data: Data, characteristic: CBCharacteristic) {
        print("Writing to ALPHA: \(characteristic.uuid.uuidString)")
        if let alphaDevice = self.alphaDevice {
            alphaDevice.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
}
