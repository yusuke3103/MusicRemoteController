//
//  Define.swift
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2017/09/30.
//  Copyright © 2017年 Yusuke Sato. All rights reserved.
//

import CoreBluetooth


struct UUIDS {
    public static let SERVICE : CBUUID = CBUUID(string: "7865087B-D9D0-423A-9C80-042D9BBEA524")
    public static let MUSIC_INFO : CBUUID = CBUUID(string: "085BACFC-5FCD-49D1-B7D7-A331901F6DDE")
    public static let BUTTON : CBUUID = CBUUID(string: "608072DD-6825-4293-B3E7-324CF0B5CA08")
    public static let NOTIFY : CBUUID = CBUUID(string: "3054DACC-2529-4A2F-9FCA-E0E452D1D65D")
}
