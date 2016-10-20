//
//  SpriteNodeExtension.swift
//  IDOViewer
//
//  Created by ganyi on 16/7/27.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import Foundation
import SpriteKit
extension SKSpriteNode:SKNodeSetDelegate{
    
    public func config(withSpeed moveSpeed:CGFloat){
        
        //delegate
        reset(init: true)
        
        lightingBitMask = 1
        let moveAct = SKAction.moveBy(x: moveSpeed, y: 0, duration: 1)
        run(SKAction.repeatForever(moveAct))
    }
    
}
