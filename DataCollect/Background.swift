//
//  Background.swift
//  IDOViewer
//
//  Created by ganyi on 16/7/27.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import Foundation
import SpriteKit
class Background: SKNode {
    
    //树
    fileprivate var treeList = [Tree]()
    //建筑
    fileprivate var buildingList = [Building]()
    //羽毛球
    fileprivate var badminton:SKSpriteNode?
    fileprivate var badmintonTexList = [
        SKTexture(imageNamed: "badminton_ball_0"),
        SKTexture(imageNamed: "badminton_ball_1")
    ]
    
    fileprivate var backgroundMap = [PlayerAction: SKTexture]() //存储背景图片
    fileprivate let bg = SKSpriteNode(color: .white, size: sceneSize)    //创建背景
    
    fileprivate var bgState:PlayerAction?   //状态
    
    fileprivate var label = SKLabelNode(fontNamed: "Futura-CondensedExtraBold")  //左上角文字
    
    private var logo: SKSpriteNode = {
        let logo = SKSpriteNode(imageNamed: "ido-logo")
        logo.isHidden = true
        logo.position = CGPoint(x: logo.size.width * 0.6, y: sceneSize.height - logo.size.height * 0.6)
        logo.setScale(0.7)
        logo.zPosition = ZPos.player
        return logo
    }()
    
    //MARK:init-------------------------------------------------
    override init() {
        super.init()
        
        config()
        createContents()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func config(){
        
        position = CGPoint.zero
        
        NotificationCenter.default.addObserver(self, selector: #selector(Background.setBackground(_:)), name: NSNotification.Name(rawValue: "state"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Background.setPause(_:)), name: NSNotification.Name(rawValue: "status"), object: nil)
    }
    
    fileprivate func createContents(){
    
        //添加底图
        bg.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        bg.xScale = sceneSize.width / bg.size.width
        bg.yScale = sceneSize.height / bg.size.height
        bg.zPosition = ZPos.background
        bg.lightingBitMask = 1
        addChild(bg)
        
        //添加左上角文字
        label.position = CGPoint(x: 40, y: sceneSize.height * 0.75)
        label.zPosition = ZPos.player
        label.horizontalAlignmentMode = .left
        label.fontSize = 60
        label.fontColor = .black
        addChild(label)
        
        initBackground()
        
        addChild(logo)
    }
    
    //MARK:初始化背景
    fileprivate func initBackground(){
        
        backgroundMap[.Walk] = SKTexture(imageNamed: "bg_walk")
        backgroundMap[.Sit] = SKTexture(imageNamed: "bg_sit")
        backgroundMap[.Code] = SKTexture(imageNamed: "bg_code")
        backgroundMap[.Ride] = SKTexture(imageNamed: "bg_walk")
        backgroundMap[.Run] = SKTexture(imageNamed: "bg_walk")
    }
    
    //MARK:根据动作切换背景
    func setBackground(_ note:Notification){
        
        //获取角色状态
        guard let stateRawValue = note.object as? String else{
            return
        }
        
        guard let state = PlayerAction(rawValue: stateRawValue) else{
            return
        }
        
        //状态无改变跳过
        guard bgState != state else{
            return
        }
        
        //修改label文字
        if state == .Runlp{
            label.text = ""
            logo.isHidden = false
        }else{
            label.text = "\(state)"
            logo.isHidden = true
        }
        
        //统一背景与角色状态
        bgState = state
        
        //修改背景
        bg.texture = backgroundMap[state]
        
        //修改配置
        
        //移除走路背景动画 或 羽毛球动画
        removeWalk()
        removeBadminton()
        
        switch state {
        case .Walk, .Run, .Ride:
            initWalk()
        case .Badminton:
            initBadminton()
        default:
            break
        }
    }
    
    func setPause(_ note:Notification){
        
        //获取信息
        guard let status = note.object as? Bool else{
            return
        }
        
        isPaused = !status
    }
    
    //MARK:初始化跑步背景
    fileprivate func initWalk(){
        
        for _ in 0..<3{
            let building = Building()
            buildingList.append(building)
            addChild(building)
        }
        
        for _ in 0..<5{
            let tree = Tree()
            treeList.append(tree)
            addChild(tree)
        }
    }
    
    fileprivate func removeWalk(){
        
        removeChildren(in: treeList)
        treeList.removeAll()
        
        removeChildren(in: buildingList)
        buildingList.removeAll()
    }
    
    //MARK:添加羽毛球
    fileprivate func initBadminton(){
        
        guard badminton == nil else{
            return
        }
        
        badminton = SKSpriteNode(imageNamed: "badminton_ball-0")
        badminton?.zPosition = ZPos.player + 1
        
        let playerPositon = (scene as! MainScene).player.position
        
        let texDownAct = SKAction.animate(with: badmintonTexList, timePerFrame: 0.01)
        let mvDownAct = SKAction.move(to: CGPoint(x: playerPositon.x + 373, y: playerPositon.y - 26), duration: 0.5)
        let downGroup = SKAction.group([texDownAct, mvDownAct])
        
        let texUpAct = texDownAct.reversed()
        let mvUpAct = SKAction.move(to: CGPoint(x: sceneSize.width, y: sceneSize.height), duration: 0.5)
        let upGroup = SKAction.group([texUpAct, mvUpAct])
        
        let seqAct = SKAction.sequence([downGroup, upGroup])
        
        badminton?.run(SKAction.repeatForever(seqAct))
    }
    
    fileprivate func removeBadminton(){
        
        guard let b = badminton else{
            return
        }
        b.removeFromParent()
        badminton = nil
    }
    
    func update(_ currentTime: TimeInterval){
        
        for building in buildingList{
            if building.position.x > sceneSize.width + building.size.width / 2{
                building.reset(init: false)
            }
        }
        
        for tree in treeList{
            if tree.position.x > sceneSize.width + tree.size.width / 2{
                tree.reset(init: false)
            }
        }
    }
    
    deinit{
      
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "state"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "status"), object: nil)
    }
}
