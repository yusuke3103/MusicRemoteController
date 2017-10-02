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
        
        nadView = NADView(isAdjustAdSize: true)
        nadView.delegate = self
        
        //nadView.setNendID("a6eca9dd074372c898dd1df549301f277c53f2b9", spotID: "3172")
        
        nadView.setNendID("af5e1829c2936cbf52f32ee3dbb40d00a4359156", spotID: "155697")
        
        nadView.isOutputLog = false
        
        nadView.load()
        
       
        
    }
    
    func nadViewDidFinishLoad(_ adView: NADView!) {
        let posX : CGFloat = (self.view.frame.size.width - nadView.frame.size.width) / 2
        let posY : CGFloat = self.view.frame.size.height - nadView.frame.size.height
        let width : CGFloat = nadView.frame.size.width
        let heigth : CGFloat = nadView.frame.size.height
        nadView.frame = CGRect(x: posX, y: posY, width: width, height: heigth)
        self.view.addSubview(nadView)
    }
    
    
}
