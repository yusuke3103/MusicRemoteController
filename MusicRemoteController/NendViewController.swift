//
//  NendView.swift
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2017/06/06.
//  Copyright © 2017年 Yusuke Sato. All rights reserved.
//

import UIKit
import NendAd

class NendViewController : UIViewController, NADViewDelegate {
    private var nadView : NADView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rect : CGRect = UIScreen.main.bounds
        
        nadView = NADView(frame: CGRect(x: 0, y: rect.height - 50 , width: 320, height: 50))
        
        nadView.setNendID("a6eca9dd074372c898dd1df549301f277c53f2b9", spotID: "3172")
        
        nadView.isOutputLog = false
        
        nadView.load()
        
        self.view.addSubview(nadView)
        
    }
    
    
}
