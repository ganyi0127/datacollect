//
//  SpriteView.swift
//  DataCollect
//
//  Created by ganyi on 16/8/6.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit
import SpriteKit
class SpriteView: SKView {
    @IBInspectable
    fileprivate var mainScene:MainScene?
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        config()
        createContents()
    }
    
    fileprivate func config(){
        
        ignoresSiblingOrder = true
    }
    
    fileprivate func createContents(){
        
        mainScene = MainScene(fileNamed: "MainScene.sks")
        guard let mScene = mainScene else{
            print("\n加载Scene场景失败!")
            return
        }
        mScene.scaleMode = .aspectFill
        presentScene(mScene)
    }
}
