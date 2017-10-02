//
//  InterfaceController.swift
//  MusicRemoteController WatchKit Extension
//
//  Created by Yusuke Sato on 2017/10/01.
//  Copyright © 2017年 Yusuke Sato. All rights reserved.
//

import WatchKit
import Foundation
import CoreBluetooth

class InterfaceController: WKInterfaceController, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet var lblState: WKInterfaceLabel!
    @IBOutlet var lblTitle: WKInterfaceLabel!
    @IBOutlet var lblArtist: WKInterfaceLabel!
    
    @IBOutlet var btnPlay: WKInterfaceButton!
    @IBOutlet var btnPrev: WKInterfaceButton!
    @IBOutlet var btnNext: WKInterfaceButton!
    @IBOutlet var btnVolDown: WKInterfaceButton!
    @IBOutlet var btnVolUp: WKInterfaceButton!
    
    /** セントラルマネージャ */
    var _centralManager: CBCentralManager!
    /** remotePeripheral */
    var _remotePeripheral : CBPeripheral!
    /** Characteristic(ボタン) */
    var _buttonCharacteristic : CBCharacteristic!
    /** Characteristic(音楽) */
    var _musicInfoCharacteristic : CBCharacteristic!
    /** Characteristic(通知) */
    var _notifyCharacteristic : CBCharacteristic!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
    }
    
    override func willActivate() {
        print ("willActivate")
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        
        if (_remotePeripheral == nil){
            setButtonEnable(state: false)
            _centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    // ===========================
    // CoreBluetooth
    // ===========================
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState")
        
        if central.state.rawValue == CBCentralManagerState.poweredOn.rawValue {
            // Peripheral検索開始
            _centralManager.scanForPeripherals(withServices: [UUIDS.SERVICE], options: nil)
        }else{
            print( central.state.rawValue )
        }
    }
    
    /** Peripheralを発見 */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("didDiscoverPeripheral")
        // スキャン停止
        _centralManager.stopScan()
        _remotePeripheral = peripheral
        // 接続開始
        _centralManager.connect(peripheral, options: nil)
    }
    
    /** 接続成功 */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connect Success!")
        
        _remotePeripheral.delegate = self
        // サービス検索
        peripheral.discoverServices([UUIDS.SERVICE])
    }
    
    /** サービス発見 */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices")
        
        for service in peripheral.services! {
            if service.uuid.isEqual((UUIDS.SERVICE)) == true{
                // Characteristicsを探索
                peripheral.discoverCharacteristics([UUIDS.BUTTON,UUIDS.MUSIC_INFO,UUIDS.NOTIFY], for: service)
            }
        }
    }
    
    /** Characteristics発見 */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor")
        
        if error != nil {
            print("\(String(describing: error))")
        }
        
        
        let discoverCharacteristics : [CBCharacteristic] = service.characteristics!
        if discoverCharacteristics.count >= 0 {
            // くるくる停止
            setButtonEnable(state: true)
        }
        
        for characteristic in discoverCharacteristics {
            if characteristic.uuid.isEqual(UUIDS.BUTTON) {
                print("Discovered Button Characteristics")
                _buttonCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: _buttonCharacteristic)
            }else if (characteristic.uuid.isEqual(UUIDS.MUSIC_INFO)){
                print("Discovered Music Info Characteristics")
                _musicInfoCharacteristic = characteristic
                peripheral.readValue(for: _musicInfoCharacteristic)
            }else if (characteristic.uuid.isEqual(UUIDS.NOTIFY)){
                print("Discovered Notifiy Characteristics")
                _notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: _notifyCharacteristic)
            }
        }
    }
    
    /** 書き込み受信 */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("didWriteValueFor")
    }
    
    /** 読み込み受信 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        print("didUpdateValueFor")
        
        if error != nil {
            print("Failed... error: \(String(describing: error))")
            return
        }
        
        if characteristic.uuid.isEqual(UUIDS.BUTTON){ // BUTTON
            
            if Int(Array(characteristic.value!)[0]) == 1 {
                btnPlay.setTitle("停止")
                
            }else{
                btnPlay.setTitle("再生")
            }
        } else if characteristic.uuid.isEqual(UUIDS.NOTIFY){  // NOTIFY
            peripheral.readValue(for: _musicInfoCharacteristic)
        } else if characteristic.uuid.isEqual(UUIDS.MUSIC_INFO){ // MUSIC INFO
            do{
                
                let data = try JSONSerialization.jsonObject(with: characteristic.value!, options: []) as! Dictionary<String, AnyObject>
                lblTitle.setText(data["TITLE"] as? String)
                lblArtist.setText(data["ARTIST"] as? String)
                
            }catch{
                print("ERROR")
            }
        }
        
    }
    
    /** 通知 */
    // 通知受信
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            print("Notify状態更新失敗...error: \(String(describing: error))")
        } else {
            print("Notify状態更新成功！ isNotifying: \(characteristic.isNotifying)")
        }
    }
    
    /** didModifyServices */
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("didModifyServices")
        for service : CBService in invalidatedServices {
            if service.uuid.isEqual(UUIDS.SERVICE) {
                setButtonEnable(state: true)
                _centralManager = CBCentralManager(delegate: self, queue: nil)
            }
        }
    }
    
    func setButtonEnable(state: Bool){
        
        if state == false {
            lblState.setText("NG")
            lblState.setTextColor(UIColor.red)
        }else{
            lblState.setText("OK")
            lblState.setTextColor(UIColor.green)
        }
        
        btnPlay.setEnabled(state)
        btnNext.setEnabled(state)
        btnPrev.setEnabled(state)
        btnVolUp.setEnabled(state)
        btnVolDown.setEnabled(state)
        
    }
    
    // ===========================
    // Action
    // ===========================
    @IBAction func TouchPlay() {
        let val : Data = Data(bytes: [0])
        _remotePeripheral.writeValue(val , for: _buttonCharacteristic, type: .withResponse)
    }
    @IBAction func TouchPrev() {
        let val : Data = Data(bytes: [1])
        _remotePeripheral.writeValue(val , for: _buttonCharacteristic, type: .withResponse)
    }
    @IBAction func TouchNext() {
        let val : Data = Data(bytes: [2])
        _remotePeripheral.writeValue(val , for: _buttonCharacteristic, type: .withResponse)
    }
    @IBAction func TouchVolDown() {
        let val : Data = Data(bytes: [4])
        _remotePeripheral.writeValue(val , for: _buttonCharacteristic, type: .withResponse)
    }
    @IBAction func TouchVolUp() {
        let val : Data = Data(bytes: [3])
        _remotePeripheral.writeValue(val , for: _buttonCharacteristic, type: .withResponse)
    }
    
}
