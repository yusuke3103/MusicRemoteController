//
//  ImageUtil.swift
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2017/06/10.
//  Copyright © 2017年 Yusuke Sato. All rights reserved.
//

import UIKit

class ImageUtil {
    
    static func ImageToString(image : UIImage) -> String {
        
        let data : Data = UIImagePNGRepresentation(image)!
        
        let encodeString : String = data.base64EncodedString(options: .lineLength64Characters)
        
        return encodeString
    }
    
    static func StringToImage(imageString : String) -> UIImage {
        let base64String : String = imageString.replacingOccurrences(of: " ", with: "+")
        
        let data : Data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)!
        
        let img : UIImage = UIImage(data: data)!
        
        return img
    }
}
