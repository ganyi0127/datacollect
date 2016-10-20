  //
//  ButtonExtension.swift
//  DataCollect
//
//  Created by ganyi on 16/8/4.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit
extension UIButton{
    open override func awakeFromNib() {
        
        let font = UIFont(name: fontName, size: titleLabel!.font.pointSize)
        self.titleLabel?.font = font
        
        backgroundColor = defautColor
        setTitleColor(.white, for: UIControlState())
        
        layer.cornerRadius = kCornerRadius
    }
}
