//
//  RemoteModeViewController.swift
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2017/10/01.
//  Copyright © 2017年 Yusuke Sato. All rights reserved.
//

import UIKit
import CoreBluetooth
import MediaPlayer

class RemoteModeViewController : NendViewController, CBCentralManagerDelegate , UIAlertViewDelegate, CBPeripheralDelegate {
    
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
    /** 検索中ダイアログ */
    var _altSearch : UIAlertView!
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblArtist: UILabel!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnNext: UIButton!
    @IBOutlet var btnPrev: UIButton!
    @IBOutlet var btnVolUp: UIButton!
    @IBOutlet var btnVolDown: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 通知設定
        let notificationCenter : NotificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.EnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
        // ぐるぐるの初期化
        _altSearch = UIAlertView(title: "接続中...", message: "接続可能端末を探しています", delegate: self, cancelButtonTitle: "キャンセル")
        let indicator : UIActivityIndicatorView = UIActivityIndicatorView()
        indicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        indicator.activityIndicatorViewStyle = .whiteLarge
        indicator.color = UIColor.black
        indicator.startAnimating()
        _altSearch.setValue(indicator, forKey: "accessoryView")
        
        // ぐるぐる表示
        _altSearch.show()
        
        // セントラルマネージャ初期化
        _centralManager = CBCentralManager(delegate: self, queue: nil, options:nil)
    }
    
    // ===========================
    // CoreBluetooth
    // ===========================
    /**  */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState")
        
        if central.state.rawValue == CBCentralManagerState.poweredOn.rawValue {
            // Peripheral検索開始
            _centralManager.scanForPeripherals(withServices: [UUIDS.SERVICE], options: nil)
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
            _altSearch.dismiss(withClickedButtonIndex: 0, animated: true)
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
            if Int(Array(characteristic.value!)[0]) == MPMusicPlaybackState.playing.rawValue {
                btnPlay.setImage(UIImage(named: "stop.png"), for: .normal)
            }else{
                btnPlay.setImage(UIImage(named: "Play.png"), for: .normal)
            }
        } else if characteristic.uuid.isEqual(UUIDS.NOTIFY){  // NOTIFY
            peripheral.readValue(for: _musicInfoCharacteristic)
        } else if characteristic.uuid.isEqual(UUIDS.MUSIC_INFO){ // MUSIC INFO
            do{
                
                let data = try JSONSerialization.jsonObject(with: characteristic.value!, options: []) as! Dictionary<String, AnyObject>
                
                lblTitle.text = data["TITLE"] as? String
                lblArtist.text = data["ARTIST"] as? String
                
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
                _altSearch.show()
                _centralManager = CBCentralManager(delegate: self, queue: nil, options:nil)
            }
        }
    }
    
    // ==========================
    // イベント
    // ==========================
    @objc func EnterForeground(){
        print("EnterForeground")
        _centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 0 {
            //self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    // ==========================
    // アクション
    // ==========================
    /**
     * Playボタン押下
     */
    @IBAction func didTouchBtnPlay(_ sender: Any) {
        
        let val : Data = Data(bytes: [0])
        _remotePeripheral.writeValue(val , for: _buttonCharacteristic, type: .withResponse)
    }
    
    /**
     * Nextボタン押下
     */
    @IBAction func didTouchBtnNext(_ sender: Any) {
        let val : Data = Data(bytes: [1])
        _remotePeripheral.writeValue(val , for: _buttonCharacteristic, type: .withResponse)
    }
    
    /**
     * Pravボタン押下
     */
    @IBAction func didTouchBtnPrev(_ sender: Any) {
        let val : Data = Data(bytes: [2])
        _remotePeripheral.writeValue(val , for: _buttonCharacteristic, type: .withResponse)
    }
    
    
    /**
     * ボリューム(UP)ボタン押下
     */
    @IBAction func didTouchBtnVolUp(_ sender: Any) {
        let val : Data = Data(bytes: [3])
        _remotePeripheral.writeValue(val , for: _buttonCharacteristic, type: .withResponse)
    }
    
    /**
     * ボリューム(Down)ボタン押下
     */
    @IBAction func didTouchBtnVolDown(_ sender: Any) {
        let val : Data = Data(bytes: [4])
        _remotePeripheral.writeValue(val , for: _buttonCharacteristic, type: .withResponse)
    }
}
