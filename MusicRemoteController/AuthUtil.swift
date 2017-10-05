//
//  AuthUtil.swift
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2017/09/30.
//  Copyright © 2017年 Yusuke Sato. All rights reserved.
//

import UIKit
import MediaPlayer
import CoreBluetooth

class AuthUtil {
    
    static func isMpMediaLibrary(view : UIViewController) -> Bool {
        
        var isMpMediaLibraryAuth : Bool = false;
        
        if #available(iOS 9.3, *) {
            
            switch MPMediaLibrary.authorizationStatus() {
            case .notDetermined: // 未設定の場合
                print("Determined")
                MPMediaLibrary.requestAuthorization({ (status: MPMediaLibraryAuthorizationStatus) in
                    
                    if status != .authorized {
                        alertMessage(message: "メディアライブラリの利用が許可されていないため利用できません。メディアライブラリの使用を許可してください", view: view)
                    }
                })
                break
            case .restricted:    // 機能制限されている場合
                print("Restricted")
                alertMessage(message: "メディアライブラリの利用が許可されていないため利用できません。メディアライブラリの使用を許可してください", view: view)
                break
            case .denied:        // 許可されていない場合
                alertMessage(message: "メディアライブラリの利用が許可されていないため利用できません。メディアライブラリの使用を許可してください", view: view)
                
                break
            case .authorized:    // 許可されている場合
                print("Authorized")
                isMpMediaLibraryAuth = true
                break
            }
        }else{
            isMpMediaLibraryAuth = true
        }
        
        return isMpMediaLibraryAuth
    }
    
    static func isCoreBluetoothAuth(view : UIViewController) -> Bool {
        
        var isCoreBluetoothAuth : Bool = false;
        switch CBPeripheralManager.authorizationStatus() {
        case .notDetermined: // 未設定の場合
            print("Determined")
            isCoreBluetoothAuth = true
            break
        case .restricted:    // 機能制限されている場合
            print("Restricted")
            alertMessage(message: "Bluetoothの利用が許可されていないため利用できません。Bluetoothの使用を許可してください", view: view)
            break
        case .denied:        // 許可されていない場合
            alertMessage(message: "Bluetoothの利用が許可されていないため利用できません。Bluetoothの使用を許可してください", view: view)
            
            break
        case .authorized:    // 許可されている場合
            print("Authorized")
            isCoreBluetoothAuth = true
            break
        }
        
        return isCoreBluetoothAuth
    }
    
    
    //メッセージ出力メソッド
    private static func alertMessage(message:String, view : UIViewController) {
        
        let alertController : UIAlertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "設定", style: .cancel, handler: {(action : UIAlertAction?) in
            let url : URL =  URL(string: UIApplicationOpenSettingsURLString)!
            UIApplication.shared.openURL(url)
        }))
        
        let defaultAction = UIAlertAction(title:"キャンセル", style: .default, handler:{(action: UIAlertAction!) -> Void in view.navigationController?.popViewController(animated: true)})
        
        alertController.addAction(defaultAction)
        
        view.present(alertController, animated: true, completion: nil)
        
    }
    
}

