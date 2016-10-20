//
//  MainScene.swift
//  IDOViewer
//
//  Created by ganyi on 16/7/27.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import Foundation
import SpriteKit
//层级
struct ZPos {
    static let background:CGFloat = 1
    static let bgCube:CGFloat = 3
    static let player:CGFloat = 10
    static let light:CGFloat = 20
}

//每秒速度
struct Speed{
    static let tree:CGFloat = 200
    static let building:CGFloat = 120
}

//画面尺寸
let sceneSize = CGSize(width: 1334, height: 750)

class MainScene: SKScene {
    
    //优先创建背景（需要接收player推送的消息）
    fileprivate let background = Background()
    let player = Player()
    
    fileprivate var lightNode = SKLightNode()
    
    //运动类型
    var type:(status: UInt8, code: UInt8)?{
        didSet{
            
            guard let t = type else{
                return
            }
            
            //切换动画与状态
            let rawValue = String(t.code, radix: 16)
            player.state = (action:PlayerAction(rawValue: rawValue), status: t.status)
        }
    }
    
    //init------------------------------------------------------------
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        config()
        createContents()
    }
    
    fileprivate func config(){
        
    }
    
    fileprivate func createContents(){
        
        lightNode.categoryBitMask = 0x1 
        lightNode.lightColor = UIColor(red: 179 / 255, green: 96 / 255, blue: 40 / 255, alpha: 1)
        lightNode.ambientColor = UIColor(red: 255 / 255, green: 200 / 255, blue: 146 / 255, alpha: 1)
        lightNode.zPosition = ZPos.light
        lightNode.falloff = 0.3
        lightNode.position = CGPoint(x: -sceneSize.width * 0.1, y: sceneSize.height * 1.1)
        addChild(lightNode)
        
        addChild(background)
        addChild(player)
    }
    
    override func update(_ currentTime: TimeInterval) {
        background.update(currentTime)
    }
}

//MARK:点击事件
extension MainScene{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        touches.forEach(){
            touch in
            let location = touch.location(in: self)
            guard location.x > sceneSize.width * 0.8 && location.y > sceneSize.height * 0.8 else{
                return
            }
            
            if lightNode.categoryBitMask == 0x1{
                lightNode.categoryBitMask = 0x1 << 1
            }else{
                lightNode.categoryBitMask = 0x1
            }
        }
    }
}
