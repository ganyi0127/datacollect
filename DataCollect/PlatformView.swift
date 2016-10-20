//
//  PlatformView.swift
//  DataCollect
//
//  Created by ganyi on 16/8/6.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit

@IBDesignable
class PlatformView: UIView {
    
    var dataViewList = [DataView]()
    
    init(){
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: viewSize.height, height: viewSize.width)))

        config()
        createContents()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func config(){
        
    }
    
    fileprivate func createContents(){
        
        (0..<8).forEach(){
            i in
            let dataView = DataView(withTag: i)
            addSubview(dataView)
            
            dataViewList.append(dataView)
        }
    }
}

extension PlatformView{
    
    
}
