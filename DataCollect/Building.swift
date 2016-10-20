//
//  Building.swift
//  IDOViewer
//
//  Created by ganyi on 16/7/27.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import Foundation
import SpriteKit
class Building: SKSpriteNode {
    init(){
        let tex = SKTexture(imageNamed: "building")
        super.init(texture: tex, color: .clear, size: tex.size())
        
        config(withSpeed: Speed.building)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
