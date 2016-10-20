//
//  Tree.swift
//  IDOViewer
//
//  Created by ganyi on 16/7/27.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import Foundation
import SpriteKit
class Tree: SKSpriteNode {
    init(){
        let tex = SKTexture(imageNamed: "tree")
        super.init(texture: tex, color: .clear, size: tex.size())
        
        config(withSpeed: Speed.tree)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
