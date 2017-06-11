//
//  PlayerModeViewController.swift
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2017/06/01.
//  Copyright © 2017年 Yusuke Sato. All rights reserved.
//

import UIKit
import CoreBluetooth
import MediaPlayer

class PlayerModeViewController : NendViewController ,CBPeripheralManagerDelegate {
    

    
    @IBOutlet var imgArtwork: UIImageView!
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblArtist: UILabel!
    
    @IBOutlet var barVolume: UIView!
    @IBOutlet var btnPrev: UIButton!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnNext: UIButton!
    
    var peripheralManager : CBPeripheralManager!
    var buttonCharacteristic : CBCharacteristic!
    var musicInfoCharacteristic: CBCharacteristic!
    var notifyCharacteristic: CBCharacteristic!
    var notificationCenter : NotificationCenter!
    var player : MPMusicPlayerController!
    
    var nowItem : Data!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        initPlyer()
        
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    
    // =================
    // MPMediaPlayer
    // =================
    
    
    /**
     * MPMediaPlayer初期化
     */
    func initPlyer(){
        
        // MPMediaPlayer
        player = MPMusicPlayerController.systemMusicPlayer()
        
        // 再生中でない場合適当な全曲からランダム
        if player.playbackState == .stopped {
            self.player.setQueue(with: .songs())
        }
        
        
        //
        barVolume.backgroundColor = UIColor.clear
        barVolume.addSubview(MPVolumeView(frame: barVolume.bounds))
        
        // NotificationCenter
        notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(PlayerModeViewController.playbackStateChange), name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: player)
        notificationCenter.addObserver(self, selector: #selector(PlayerModeViewController.nowPlayingItemChanged), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
        notificationCenter.addObserver(self, selector: #selector(PlayerModeViewController.volumeChange), name: NSNotification.Name.MPMusicPlayerControllerVolumeDidChange, object: player)
        
        player.beginGeneratingPlaybackNotifications()
        
        setPlayingItem()
        
    }
    
    /**
     * MPMediaPlayer状態変化
     */
    func playbackStateChange() {
    }
    
    /**
     * 再生中のアイテム変更
     */
    func nowPlayingItemChanged(){
    
        setPlayingItem()
        
        if notifyCharacteristic != nil{
            peripheralManager.updateValue(nowItem, for: notifyCharacteristic as! CBMutableCharacteristic, onSubscribedCentrals: nil)
        }
    }
    
    func setPlayingItem() {
        
        let nowplayingItem : MPMediaItem = player.nowPlayingItem!
        
        let title : String = nowplayingItem.title!
        let artist : String = nowplayingItem.artist!
        
        // アートワーク
        var artwork = (nowplayingItem.artwork?.image(at: CGSize(width: 200, height: 200)))
        if artwork == nil {
            artwork = UIImage(named: "nonimage.png")
        }
        
        lblTitle.text = title
        lblArtist.text = artist
        imgArtwork.image = artwork
        
        var info : Dictionary<String, AnyObject> = [:]
        info["TITLE"] = lblTitle.text as AnyObject
        info["ARTIST"] = lblArtist.text as AnyObject
        
        do{
            nowItem = try JSONSerialization.data(withJSONObject: info, options: .prettyPrinted)
        }catch{
            print("ERROR:JSONSerialization")
        }
    }

    /**
     * 音量変更
     */
    func volumeChange () {
        
    }
    
    // =================
    // CoreBluetooth
    // =================
    
    /**
     * Peripheral Manager 状態変化
     */
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("peripheralManagerDidUpdateState")
        if peripheral.state.rawValue == CBPeripheralManagerState.poweredOn.rawValue {
            
            // ボタン押下イベント用
            buttonCharacteristic = CBMutableCharacteristic(type: UUIDS.BUTTON, properties: [.write], value: nil, permissions: [.writeEncryptionRequired])
            
            // 再生楽曲情報用
            musicInfoCharacteristic = CBMutableCharacteristic(type: UUIDS.MUSIC_INFO, properties: [.read ], value: nil, permissions: [.readEncryptionRequired])
            
            notifyCharacteristic = CBMutableCharacteristic(type: UUIDS.NOTIFY, properties: [.notify], value: nil, permissions: [.readable])
            
            let service : CBMutableService = CBMutableService(type: UUIDS.SERVICE, primary: true)
            service.characteristics = [buttonCharacteristic, notifyCharacteristic, musicInfoCharacteristic]
            // サービス追加
            peripheral.add(service)
            
        }
        
    }

    /**
     * サービス追加結果
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("didAddService")
        
        if error != nil {
            print("ERROR: \(String(describing: error))")
        }else{
            peripheral .startAdvertising([CBAdvertisementDataLocalNameKey:"MRC", CBAdvertisementDataServiceUUIDsKey:[UUIDS.SERVICE]])
        }
    }
    
    
    /**
     * アドバタイズ開始
     */
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("peripheralManagerDidStartAdvertising")
        if error != nil {
            print("ERROR: \(String(describing: error))")
        }
    }
    

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("didReceiveWrite")
    
        
        for request in requests {
            
            if request.characteristic.uuid.isEqual(buttonCharacteristic.uuid) {
                WriteRequest(data: requests[0].value!)
            }
        }
        
        
        peripheralManager.respond(to: requests[0], withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if (request.characteristic.uuid.isEqual(UUIDS.MUSIC_INFO)) {
            
            print(request.offset)
            
            
            
            if request.offset > nowItem.count {
                
            }else{
            
                print(Range(uncheckedBounds: (request.offset, nowItem.count)))
                
                request.value = nowItem.subdata(in: Range(uncheckedBounds: (request.offset, nowItem.count)))
                
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
    
    func WriteRequest(data: Data){
        let val = data.hashValue
        switch val {
        case 0:
            if player.playbackState.rawValue == MPMusicPlaybackState.playing.rawValue {
                player.pause()
            }else{
                player.play()
            }
            break;
        case 1:
            player.skipToNextItem()
            break;
        case 2:
            player.skipToPreviousItem()
            break;
        case 3:
            var volume : Double = player.value(forKey: "volume") as! Double
            volume += 0.0625;
            if volume >= 1.0 {
                volume = 1.0
            }
            
            player.setValue(volume, forKey: "volume")
           print(volume)
           break;
        case 4:
            var volume : Double = player.value(forKey: "volume") as! Double
            volume -= 0.0625;
            if volume <= 0.0 {
                volume = 0.0
            }
            
            player.setValue(volume, forKey: "volume")
            break;
        default:
            break;
        }
    }
    
    // =================
    // Action
    // =================
    @IBAction func clickedPrev(_ sender: Any) {
        player.skipToPreviousItem()
    }
    
    @IBAction func clickedPlay(_ sender: Any) {
        
        if player.playbackState == .stopped || player.playbackState == .paused {
            player.play()
        }else if player.playbackState == .playing{
            player.pause()
        }
    }
    
    @IBAction func clickedNext(_ sender: Any) {
        player.skipToNextItem()
    }
    
    
}
