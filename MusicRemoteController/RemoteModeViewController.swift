//
//  RemoteModeViewController.swift
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2017/05/29.
//  Copyright © 2017年 Yusuke Sato. All rights reserved.
//

import UIKit
import CoreBluetooth
import MediaPlayer

class RemoteModeViewController : NendViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager!
    var buttonCharacteristic : CBCharacteristic!
    var musicInfoCharacteristic : CBCharacteristic!
    var notifyCharacteristic : CBCharacteristic!
    var remotePeripheral : CBPeripheral!
    
    var nowPlayItem : Data!
    
    let alert : UIAlertView = UIAlertView(title: "接続中...", message: nil, delegate: nil, cancelButtonTitle: "キャンセル")
    let indicator : UIActivityIndicatorView = UIActivityIndicatorView()
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblArtist: UILabel!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnNext: UIButton!
    @IBOutlet var btnPrev: UIButton!
    @IBOutlet var btnVolUp: UIButton!
    @IBOutlet var btnVolDown: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let notificationCenter : NotificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(RemoteModeViewController.EnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        initAlert()
        
        alert.show()
    }
    
    func EnterForeground(){
        print("EnterForeground")
        
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
            
            alert.dismiss(withClickedButtonIndex: 0, animated: false)
            
            if characteristic.uuid.isEqual(UUIDS.BUTTON) {
                print("Discovered Button Characteristics")
                buttonCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: buttonCharacteristic)
            }else if (characteristic.uuid.isEqual(UUIDS.MUSIC_INFO)){
                print("Discovered Music Info Characteristics")
                musicInfoCharacteristic = characteristic
                peripheral.readValue(for: musicInfoCharacteristic)
            }else if (characteristic.uuid.isEqual(UUIDS.NOTIFY)){
                print("Discovered Notifiy Characteristics")
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: notifyCharacteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service : CBService in invalidatedServices {
            if service.uuid.isEqual(UUIDS.SERVICE) {
                alert.show()
                centralManager = CBCentralManager(delegate: self, queue: nil)
            }
        }
    }
    

    // 値の書き込み成功
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("didWriteValueFor")
        print(descriptor)
    }
    // 値の読み込み成功
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueFor")
        
        if error != nil {
            print("Failed... error: \(String(describing: error))")
            return
        }
        
        // BUTTON
        if characteristic.uuid.isEqual(UUIDS.BUTTON){
            if Int(Array(characteristic.value!)[0]) == MPMusicPlaybackState.playing.rawValue {
                btnPlay.setImage(UIImage(named: "stop.png"), for: .normal)
            }else{
                btnPlay.setImage(UIImage(named: "Play.png"), for: .normal)
            }
        }
        // NOTIFY
        else if characteristic.uuid.isEqual(UUIDS.NOTIFY){
            peripheral.readValue(for: musicInfoCharacteristic)
        }
        // MUSIC INFO
        else if characteristic.uuid.isEqual(UUIDS.MUSIC_INFO){
            
            do{
                
                let data = try JSONSerialization.jsonObject(with: characteristic.value!, options: []) as! Dictionary<String, AnyObject>
                
                lblTitle.text = data["TITLE"] as? String
                lblArtist.text = data["ARTIST"] as? String
                
                print(data)
                
                
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
    
    func initAlert(){
        indicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        indicator.activityIndicatorViewStyle = .whiteLarge
        indicator.color = UIColor.black
    
        indicator.startAnimating()
    
        alert.setValue(indicator, forKey: "accessoryView")
    }
    
    
    // ==============
    // ボタン押下
    // ==============
    
    /**
     * Playボタン押下
     */
    @IBAction func didTouchBtnPlay(_ sender: Any) {
        
        let val : Data = Data(bytes: [0])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    /**
     * Nextボタン押下
     */
    @IBAction func didTouchBtnNext(_ sender: Any) {
        let val : Data = Data(bytes: [1])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    /**
     * Pravボタン押下
     */
    @IBAction func didTouchBtnPrev(_ sender: Any) {
        let val : Data = Data(bytes: [2])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    
    /**
     * ボリューム(UP)ボタン押下
     */
    @IBAction func didTouchBtnVolUp(_ sender: Any) {
        let val : Data = Data(bytes: [3])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
    
    /**
     * ボリューム(Down)ボタン押下
     */
    @IBAction func didTouchBtnVolDown(_ sender: Any) {
        let val : Data = Data(bytes: [4])
        remotePeripheral.writeValue(val , for: buttonCharacteristic, type: .withResponse)
    }
}
