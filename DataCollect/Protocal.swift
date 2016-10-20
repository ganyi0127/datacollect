//
//  Protocal.swift
//  IDOViewer
//
//  Created by ganyi on 16/7/27.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import Foundation
import SpriteKit
protocol SKNodeSetDelegate {
    //MARK:重置位置，大小
    func reset(init flag:Bool)
}

extension SKNodeSetDelegate where Self:SKSpriteNode{
    func reset(init flag: Bool) {
        if flag{
            anchorPoint = CGPoint(x: 0.5, y: 0)
        }
        
        let rand = CGFloat(arc4random_uniform(4)) / 10
        let posX = flag ? CGFloat(arc4random_uniform(UInt32(sceneSize.width))): -CGFloat(arc4random_uniform(UInt32(sceneSize.width))) - size.width / 2
        let posY = sceneSize.height * 0.2
        self.zPosition = ZPos.bgCube - rand
        self.position = CGPoint(x: posX, y: posY)
        self.setScale((1 - rand) * 2 + 0.5)

        switch self {
        case is Tree:
            self.zPosition = ZPos.bgCube - rand + 1
        default:
            self.zPosition = ZPos.bgCube - rand
        }
    }
}