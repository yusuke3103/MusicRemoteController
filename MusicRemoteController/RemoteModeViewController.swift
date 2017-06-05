//
//  RemoteModeViewController.swift
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2017/05/29.
//  Copyright © 2017年 Yusuke Sato. All rights reserved.
//

import UIKit
import CoreBluetooth

class RemoteModeViewController : UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager!
    var buttonCharacteristic : CBCharacteristic!
    var musicInfoCharacteristic : CBCharacteristic!
    var remotePeripheral : CBPeripheral!
    
    @IBOutlet var btnPlay: UIButton!
    
    @IBAction func didTouchBtnPlay(_ sender: Any) {
        
        let val : Data = Data(bytes: [0])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    @IBOutlet var btnNext: UIButton!
    
    @IBAction func didTouchBtnNext(_ sender: Any) {
        let val : Data = Data(bytes: [1])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    @IBOutlet var btnPrev: UIButton!
    
    @IBAction func didTouchBtnPrev(_ sender: Any) {
        let val : Data = Data(bytes: [2])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    @IBOutlet var btnVolUp: UIButton!
    
    @IBAction func didTouchBtnVolUp(_ sender: Any) {
        let val : Data = Data(bytes: [3])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    @IBOutlet var btnVolDown: UIButton!
    
    @IBAction func didTouchBtnVolDown(_ sender: Any) {
        let val : Data = Data(bytes: [4])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager Did Update State");
        
        if central.state.rawValue == CBCentralManagerState.poweredOn.rawValue {
            centralManager.scanForPeripherals(withServices: [UUIDS.SERVICE], options: nil)
            
        }

    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // スキャン停止
        centralManager.stopScan()
        
        
        self.remotePeripheral = peripheral
        
        centralManager.connect(peripheral, options: nil)
        
    }
    
    //  ペリフェラル接続成功時
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connect success!")
        
        self.remotePeripheral.delegate = self
        
        peripheral.discoverServices([UUIDS.SERVICE])
    }
    
    //  ペリフェラル接続失敗時
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Connect failed...")
    }
    
    // サービス発見
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        for service in peripheral.services! {
            if service.uuid.isEqual(UUIDS.SERVICE) {
                // Characteristic探索開始
                peripheral.discoverCharacteristics([UUIDS.BUTTON,UUIDS.MUSIC_INFO], for: service)
            }
        }
    }
    
    // Characteristics発見
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            if characteristic.uuid.isEqual(UUIDS.BUTTON) {
                print("Discovered Button Characteristics")
                buttonCharacteristic = characteristic
            }else if (characteristic.uuid.isEqual(UUIDS.MUSIC_INFO)){
                print("Discovered Music Info Characteristics")
                musicInfoCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: musicInfoCharacteristic)
            }
        }
    }
    

    // 値の書き込み成功
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("didWriteValueFor")
    }
    // 値の読み込み成功
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueFor")
        peripheral.readValue(for: characteristic)
    }
    // 通知受信
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            print("Notify状態更新失敗...error: \(String(describing: error))")
        } else {
            print("Notify状態更新成功！ isNotifying: \(characteristic.isNotifying)")
        }
    }
    
    
}
