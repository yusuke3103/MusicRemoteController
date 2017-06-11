//
//  InterfaceController.swift
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2017/06/10.
//  Copyright © 2017年 Yusuke Sato. All rights reserved.
//

import WatchKit
import Foundation
import CoreBluetooth

class InterfaceController: WKInterfaceController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var alert : UIAlertView!
    
    var centralManager: CBCentralManager!
    var buttonCharacteristic : CBCharacteristic!
    var musicInfoCharacteristic : CBCharacteristic!
    var notifyCharacteristic : CBCharacteristic!
    var remotePeripheral : CBPeripheral!
    
    @IBOutlet var lblTitle: WKInterfaceLabel!
    @IBOutlet var lblArtist: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        initAlertDialog()
    }
    
    override func willActivate() {
        super.willActivate()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        alert.show()
    }
    
    func initAlertDialog(){
        alert = UIAlertView(title: "接続中...", message: "接続", delegate: nil, cancelButtonTitle: "キャンセル", otherButtonTitles: "OK", "")
        
    
        let indicator : UIActivityIndicatorView = UIActivityIndicatorView()
        indicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        indicator.activityIndicatorViewStyle = .whiteLarge
        indicator.color = UIColor.black
        
        indicator.startAnimating()
        
        alert.setValue(indicator, forKey: "accessoryView")
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
                peripheral.discoverCharacteristics([UUIDS.BUTTON,UUIDS.MUSIC_INFO, UUIDS.NOTIFY], for: service)
            }
        }
    }
    
    // Characteristics発見
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if error != nil {
            print("\(String(describing: error))")
        }
        
        for characteristic in service.characteristics! {
            print(characteristic.uuid)
            
            if characteristic.uuid.isEqual(UUIDS.BUTTON) {
                print("Discovered Button Characteristics")
                buttonCharacteristic = characteristic
            }else if (characteristic.uuid.isEqual(UUIDS.MUSIC_INFO)){
                print("Discovered Music Info Characteristics")
                musicInfoCharacteristic = characteristic
            }else if (characteristic.uuid.isEqual(UUIDS.NOTIFY)){
                print("Discovered Notifiy Characteristics")
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: notifyCharacteristic)
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
        
        if error != nil {
            print("Failed... error: \(String(describing: error))")
            return
        }
        
        if characteristic.uuid.isEqual(UUIDS.NOTIFY){
            peripheral.readValue(for: musicInfoCharacteristic)
        } else if characteristic.uuid.isEqual(UUIDS.MUSIC_INFO){
            
            do{
                
                let data = try JSONSerialization.jsonObject(with: characteristic.value!, options: []) as! Dictionary<String, AnyObject>
                
                lblTitle.setText(data["TITLE"] as! String)
                lblArtist.setText(data["ARTIST"] as! String)
                
            }catch{
                print("ERROR")
            }
        }
    }
    
    // 通知受信
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            print("Notify状態更新失敗...error: \(String(describing: error))")
        } else {
            print("Notify状態更新成功！ isNotifying: \(characteristic.isNotifying)")
        }
    }
    
    // ============
    //  ボタンイベント
    // ============
    
    /**
     * Playボタン押下
     */
    @IBAction func didTouchBtnPlay() {
        
        let val : Data = Data(bytes: [0])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    /**
     * Nextボタン押下
     */
    @IBAction func didTouchBtnNext() {
        let val : Data = Data(bytes: [1])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    /**
     * Pravボタン押下
     */
    @IBAction func didTouchBtnPrev() {
        let val : Data = Data(bytes: [2])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    
    /**
     * ボリューム(UP)ボタン押下
     */
    @IBAction func didTouchBtnVolUp() {
        let val : Data = Data(bytes: [3])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    /**
     * ボリューム(Down)ボタン押下
     */
    @IBAction func didTouchBtnVolDown() {
        let val : Data = Data(bytes: [4])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }

    
}
