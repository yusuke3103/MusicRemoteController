//
//  PlayerModeViewController.swift
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2017/09/30.
//  Copyright © 2017年 Yusuke Sato. All rights reserved.
//

import UIKit
import CoreBluetooth
import MediaPlayer

class PlayerModeViewController : NendViewController ,CBPeripheralManagerDelegate,UIAlertViewDelegate {

    @IBOutlet var imgArtwork: UIImageView!
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblArtist: UILabel!
    
    @IBOutlet var barSlider: UISlider!
    @IBOutlet var lblTime: UILabel!
    @IBOutlet var lblDuration: UILabel!
    
    @IBOutlet var btnPrev: UIButton!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnNext: UIButton!
    
    var _timer : Timer!
    
    /** 通知情報 */
    var _playInfo : Data!
    
    /** ペリフェラルマネージャ */
    var _peripheralManager : CBPeripheralManager!
    /** Characteristic(ボタン)  */
    var _buttonCharacteristic : CBCharacteristic!
    /** Characteristic(音楽) */
    var _musicInfoCharacteristic: CBCharacteristic!
    /** Characteristic(通知) */
    var _notifyCharacteristic: CBCharacteristic!
    // プレーヤーインスタンス
    var _player : MPMusicPlayerController!
    // 通知センターインスタンス
    var _notificationCenter : NotificationCenter!
    
    let options : Dictionary = [
            CBCentralManagerOptionRestoreIdentifierKey: "MRC",
            CBCentralManagerOptionShowPowerAlertKey: true
        ] as [String : Any]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if AuthUtil.isMpMediaLibrary(view: self) && AuthUtil.isCoreBluetoothAuth(view: self) {
            
            if (MPMediaQuery.songs().items?.count)! > 0 {
                // プレーヤーの初期化
                _player = MPMusicPlayerController.systemMusicPlayer
                // 通知センターの初期化
                _notificationCenter = NotificationCenter.default
                
                // 再生状態変更通知
                _notificationCenter.addObserver(self, selector: #selector(self.playbackStateChange), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: _player)
                
                // 再生状態変更通知
                _notificationCenter.addObserver(self, selector: #selector(self.playingItemChange), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: _player)
                
                // 通知開始
                _player.beginGeneratingPlaybackNotifications()
                
                // 再生中でない場合適当な全曲からランダム
                if _player.playbackState == .stopped {
                    self._player.setQueue(with: .songs())
                }
                
                playingItemChange()
                
                playbackStateChange()
                
                _peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: options)
                
            }else{
                let alert : UIAlertView = UIAlertView(title: "再生可能な曲がありません。", message: "メニューへ戻ります。", delegate: self, cancelButtonTitle: "OK")
                alert.show()
            }
        }else{
            let alert : UIAlertView = UIAlertView(title: "アプリの動作に必要な許可がありません。", message: "メニューへ戻ります。", delegate: self, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    // ===========================
    // CoreBluetooth
    // ===========================
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("peripheralManagerDidUpdateState")
        
        if _peripheralManager.state.rawValue == CBPeripheralManagerState.poweredOn.rawValue {
            
            // Characteristic(ボタン)の初期化
            _buttonCharacteristic = CBMutableCharacteristic(type: UUIDS.BUTTON, properties: [.write,.notifyEncryptionRequired], value: nil, permissions: [.writeEncryptionRequired])
            
            // Characteristic(音楽)の初期化
            _musicInfoCharacteristic = CBMutableCharacteristic(type: UUIDS.MUSIC_INFO, properties: [.read ], value: nil, permissions: [.readEncryptionRequired])
            
            // Characteristic(通知)の初期化
            _notifyCharacteristic = CBMutableCharacteristic(type: UUIDS.NOTIFY, properties: [.notify], value: nil, permissions: [.readable])
            
            // サービス作成
            let service : CBMutableService = CBMutableService(type: UUIDS.SERVICE, primary: true)
            
            // サービスにCharacteristics追加
            service.characteristics = [_buttonCharacteristic, _notifyCharacteristic, _musicInfoCharacteristic]
            
            // サービスを追加
            peripheral.add(service)
        }
    }

    /** サービス追加結果 */
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("didAddService")
        
        if error != nil {
            print("ERROR: \(String(describing: error))")
        }else{
            peripheral .startAdvertising([CBAdvertisementDataLocalNameKey:"MRC", CBAdvertisementDataServiceUUIDsKey:[UUIDS.SERVICE]])
        }
    }
    
    /** アドバタイズ開始 */
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("peripheralManagerDidStartAdvertising")
        
        if error != nil {
            print("ERROR: \(String(describing: error))")
        }
    }
    
    /** 書き込み要求 */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("didReceiveWrite")
        
        for request in requests {
            if request.characteristic.uuid.isEqual(_buttonCharacteristic.uuid) {
                WriteRequest(data: requests[0].value!)
            }
        }
        _peripheralManager.respond(to: requests[0], withResult: .success)
    }
    
    /** 読み込み要求 */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
        // RECEIVED MUSIC INFO READ
        if (request.characteristic.uuid.isEqual(UUIDS.MUSIC_INFO)) {
            if request.offset > _playInfo.count {
                
            }else{
                
                print(Range(uncheckedBounds: (request.offset, _playInfo.count)))
                
                request.value = _playInfo.subdata(in: Range(uncheckedBounds: (request.offset, _playInfo.count)))
                
                peripheral.respond(to: request, withResult: .success)
                
                print("Read success")
            }
        }else{
            print("Read fail: wrong characteristic uuid:", request.characteristic.uuid)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("didUnsubscribeFrom")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print("willRestoreState")
        
        let val = dict[CBCentralManagerRestoredStatePeripheralsKey]
        
        if val == nil {
            self.peripheralManagerDidUpdateState(peripheral)
        }
    }
    
    // ===========================
    // Event
    // ===========================
    /** 再生状態変更 */
    @objc func playbackStateChange() {
        print("playbackStateChange")
        
        if _player.playbackState == .playing {
            _timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updatePlayingTimer), userInfo: nil, repeats: true)
            btnPlay.setImage(UIImage(named: "stop.png"), for: .normal)
        }else{
            btnPlay.setImage(UIImage(named: "Play.png"), for: .normal)
        }
        
        if _buttonCharacteristic != nil{
            _peripheralManager.updateValue(Data(bytes: [UInt8(_player.playbackState.rawValue)]), for: _buttonCharacteristic as! CBMutableCharacteristic, onSubscribedCentrals: nil)
        }
    }
    
    /** 再生楽曲変更 */
    @objc func playingItemChange(){
        print("playingItemChange")
        
        setDisplay()
        
        setPlayInfo()
        
        if _notifyCharacteristic != nil {
            // 変更通知
            _peripheralManager.updateValue(_playInfo, for: _notifyCharacteristic as! CBMutableCharacteristic, onSubscribedCentrals: nil)
        }
    }
    
    /** currentTime更新 */
    @objc func updatePlayingTimer(){
        barSlider.value = Float(_player.currentPlaybackTime)
        lblTime.text = convertDoubleToTimeString(time: _player.currentPlaybackTime)
    }
    
    // ===========================
    // Action
    // ===========================
    /** アラートビューボタン押下 */
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 0 {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func clickedPrev(_ sender: Any) {
        _player.skipToPreviousItem()
    }
    
    @IBAction func clickedPlay(_ sender: Any) {
        
        if _player.playbackState == .stopped || _player.playbackState == .paused {
            _player.play()
        }else if _player.playbackState == .playing{
            _player.pause()
        }
    }
    
    @IBAction func clickedNext(_ sender: Any) {
        _player.skipToNextItem()
    }
    
    @IBAction func changePosition(_ sender: Any) {
        _player.currentPlaybackTime = Double(barSlider.value)
        updatePlayingTimer()
    }
    
    // ===========================
    // Other
    // ===========================
    /** DOUBLE => hh:mm:ss */
    func convertDoubleToTimeString(time : Double) -> String{
        
        let s : Int = Int(time.truncatingRemainder(dividingBy: 60))
        let m : Int = Int(((time - Double(s)) / 60).truncatingRemainder(dividingBy: 60))
        let h : Int = Int(((time - Double(m) - Double(s)) / 3600 ).truncatingRemainder(dividingBy: 3600))
        
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    /** 画面表示 */
    func setDisplay(){
        var title : String = "";
        var artist : String = "";
        var artwork : UIImage = UIImage(named: "nonimage.png")!
        var durationTime : String = "00:00:00"
        var max : Float = Float(1)
        
        if (_player.nowPlayingItem != nil){
            let item : MPMediaItem = _player.nowPlayingItem!
            
            if item.title != nil {
                title = item.title!
            }else{
                title = ""
            }
            
            if item.artist != nil{
                artist = item.artist!
            }else{
                artist = ""
            }
            
            max = Float(item.playbackDuration)
            durationTime = convertDoubleToTimeString(time: (_player.nowPlayingItem?.playbackDuration)!)
            
            if (item.artwork != nil){
                artwork = (item.artwork?.image(at: CGSize(width: 200, height: 200)))!
            }
        }
        
        lblTitle.text = title;
        lblArtist.text = artist;
        imgArtwork.image = artwork
        lblDuration.text = durationTime
        barSlider.maximumValue = max
    }
    
    /** 通知情報設定 */
    func setPlayInfo(){
        var info : Dictionary<String, AnyObject> = [:]
        info["TITLE"] = lblTitle.text as AnyObject
        info["ARTIST"] = lblArtist.text as AnyObject
        
        do{
            _playInfo = try JSONSerialization.data(withJSONObject: info, options: .prettyPrinted)
        }catch{
            _playInfo = nil
        }
    }
    
    /** 書き込み要求 */
    func WriteRequest(data: Data){
        let val = data.hashValue
        
        if val == 0 {
            // Centralで再生ボタンが押された
            if _player.playbackState == .playing {
                // 再生中の場合、一時停止
                _player.pause()
            }else{
                _player.play()
            }
        }else if val == 1 {
            // CentralでNextボタンが押された
            _player.skipToNextItem()
        }else if val == 2 {
            // CentralでPrevボタンが押された
            _player.skipToPreviousItem()
        }else if val == 3 {
            // CentralでVolume Upが押された
            setVolume(mode: true)
        }else if val == 4 {
            // CentralでVolume Downが押された
            setVolume(mode: false)
        }
    }
    
    /** 音量設定 */
    func setVolume(mode: Bool){
        var vol : Double = _player.value(forKey: "volume") as! Double
        if (mode == false){
            vol -= 0.0625
            if (vol <= 0){
                vol = 0
            }
        }else{
            vol += 0.0625
            if (vol >= 1){
                vol = 1
            }
        }
        
        _player.setValue(vol, forKey: "volume")
    }
}
