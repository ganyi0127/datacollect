//
//  Player.swift
//  IDOViewer
//
//  Created by ganyi on 16/7/27.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import Foundation
import SpriteKit
//状态机 坐、立、卧、打字，走路、 跑步、自行车、爬楼梯、哑铃、跳绳、仰卧起坐、俯卧撑、（体重秤）打篮球、羽毛球
//0x02:秤重;0x03:静坐; 0x04:站立; 0x05:躺着; 0x06:打字; 0x10: 步行;0x11:跑步;0x12:骑行;0x13:跳绳;0x14:哑铃; 0x15:篮球运动; 0x16:羽毛球运动;0x17:跑步机运动;0x18:仰卧起坐运动;0x19:俯卧撑运动;
enum PlayerAction:String {
    case Walk = "10"
    case WalkPre
    case WalkSuf
    case Sit = "3"
    case Stand = "4"
    case Lie = "5"
    case LiePre
    case LieSuf
    case Code = "6"
    case Run = "11"
    case Ride = "12"
    case Rope = "13"
    case Lift = "14"
    case Runlp = "17"
    case Situps = "18"
    case Pushups = "19"
    case Weight = "2"
    case Basketball = "15"
    case BasketballSuf
    case Badminton = "16"
}
class Player: SKSpriteNode {
    
    fileprivate var actionMap = [PlayerAction:SKAction]()
    
    var state:(action:PlayerAction?, status:UInt8)?{
        didSet{
            //状态无改变跳过
            guard let exValue = oldValue , state!.action != exValue.action || state?.status != exValue.status else{
                
                setState(state!.action!, actionOrStop: state!.status)
                
                return
            }
            
            //状态为空跳过
            guard let ste = state!.action else{
                return
            }
            //切换状态
            setState(ste, actionOrStop: state!.status)
        }
    }
    
    //当前运动状态
    fileprivate var status:UInt8 = 0x01
    //当前动作
    fileprivate var action:PlayerAction?
    
    //init------------------------------------------------------------
    init(){
        let tex = SKTexture(imageNamed: "walk_suf_0")
        super.init(texture: tex, color: .clear, size: tex.size())
        
        config()
        createContents()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func config(){
        
        lightingBitMask = 1
        
        anchorPoint = CGPoint(x: 0.5, y: 0)
        position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height * 0.06)
        zPosition = ZPos.player
        
    }
    
    fileprivate func createContents(){
        
        addTextures()
        
        state = (action: .Stand, status: 0x01)
    }
    
    //MARK:切换状态
    fileprivate func setState(_ state:PlayerAction, actionOrStop actionStatus: UInt8 = 0x01){

        //向背景发送切换消息
        NotificationCenter.default.post(name: Notification.Name(rawValue: "state"), object: state.rawValue)
        
        //向背景发送状态消息
        var flag = true
        if actionStatus == 0x00{
            flag = false
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "status"), object: flag)
        
        guard let currentAction = actionMap[state] else{
            return
        }
        
        guard action != state || actionStatus != status else{
            return
        }
        
        if action != state{
            removeAllActions()
        }
    
        switch state {
        case .Walk:
            //跑步
            if action != state || status != actionStatus{
                if actionStatus != 0x00{
                    if let preAct = actionMap[.WalkPre]{
                        run(preAct, completion: {
                            self.run(currentAction)
                        })
                    }
                }else{
                    if let sufAct = actionMap[.WalkSuf]{
                        run(sufAct)
                    }
                }
            }
        case .Stand:
            //站立
            
            if action == .Sit {
                if let sitStand = actionMap[.Sit]{
                    run(sitStand.reversed())
                }
            }else if action == .Lie{
                if let lieStand = actionMap[.LieSuf]{
                    run(lieStand)
                }
            }else{
                texture = SKTexture(imageNamed: "burpee_0")
                size = texture!.size()
            }
        case .Sit:
            //坐
          
            if action == .Stand{
                if let sitStand = actionMap[.Sit]{
                    run(sitStand)
                }
            }else{
                texture = SKTexture(imageNamed: "sit_10")
                size = texture!.size()
            }
        case .Lie:
            //卧
          
            if action == .Stand{
                if let liePre = actionMap[.LiePre]{
                    run(liePre)
                }
            }else{
                texture = SKTexture(imageNamed: "burpee_11")
                size = texture!.size()
            }
        case .Basketball:
            //篮球
            
            if action != state || status != actionStatus{
                if actionStatus == 0x03{
                    //投篮
                    if let sufAct = actionMap[.BasketballSuf]{
                        run(sufAct, completion: {
                            self.runCurrentAction(currentAction, actionStatus: actionStatus)
                        })
                    }
                }else{
                    runCurrentAction(currentAction, actionStatus: actionStatus)
                }
            }
            
        default:
            
            runCurrentAction(currentAction, actionStatus: actionStatus)
        }
        
        //保存角色状态：运动｜停止
        status = actionStatus
        
        //保存角色动作
        action = state
    }
    
    //MARK:调用默认动画
    fileprivate func runCurrentAction(_ action:SKAction, actionStatus: UInt8){
        
        run(action)
        
        if actionStatus != 0x00{
            isPaused = false
        }else{
            isPaused = true
        }
    }
    
    //MARK:添加序列帧
    fileprivate func addTextures(){
        
        //走路
        var walkList = [SKTexture]()
        (0..<20).forEach(){
            i in
            let tex = SKTexture(imageNamed: "walk_\(i)")
            walkList.append(tex)
        }
        let walkAct = SKAction.animate(with: walkList, timePerFrame: 0.05, resize: true, restore: true)
        actionMap[.Walk] = SKAction.repeatForever(walkAct)
        
        //走路开始
        var walkPreList = [SKTexture]()
        (0..<2).forEach(){
            i in
            let tex = SKTexture(imageNamed: "walk_suf_\(i)")
            walkPreList.append(tex)
        }
        let walkPreAct = SKAction.animate(with: walkPreList, timePerFrame: 0.1, resize: true, restore: true)
        actionMap[.WalkPre] = walkPreAct
        
        //走路结束
        let walkSufList = Array(walkPreList.reversed())
        let walkSufAct = SKAction.animate(with: walkSufList, timePerFrame: 0.1, resize: true, restore: true)
        actionMap[.WalkSuf] = walkSufAct
        
        //坐立
        var sitList = [SKTexture]()
        (0..<8).forEach(){
            i in
            let tex = SKTexture(imageNamed: "sit_\(i)")
            sitList.append(tex)
        }
        let sitAct = SKAction.animate(with: sitList, timePerFrame: 0.1, resize: true, restore: false)
        actionMap[.Sit] =  sitAct
        
        //打字
        var codeList = [SKTexture]()
        (0..<8).forEach(){
            i in
            let tex = SKTexture(imageNamed: "code_\(i)")
            codeList.append(tex)
        }
        let codeAct = SKAction.animate(with: codeList, timePerFrame: 0.1, resize: true, restore: true)
        actionMap[.Code] = SKAction.repeatForever(codeAct)
        
        //骑行
        var rideList = [SKTexture]()
        (0..<20).forEach(){
            i in
            let tex = SKTexture(imageNamed: "ride_\(i)")
            rideList.append(tex)
        }
        let rideAct = SKAction.animate(with: rideList, timePerFrame: 0.1, resize: true, restore: true)
        actionMap[.Ride] = SKAction.repeatForever(rideAct)
        
        //跑步
        var runList = [SKTexture]()
        (0..<12).forEach(){
            i in
            let tex = SKTexture(imageNamed: "run_\(i)")
            runList.append(tex)
        }
        let runAct = SKAction.animate(with: runList, timePerFrame: 0.1, resize: true, restore: true)
        actionMap[.Run] = SKAction.repeatForever(runAct)
        
        //跑步机
        var runlpList = [SKTexture]()
        (0..<10).forEach(){
            i in
            let tex = SKTexture(imageNamed: "runlp_\(i)")
            runlpList.append(tex)
        }
        let runlpAct = SKAction.animate(with: runlpList, timePerFrame: 0.1, resize: true, restore: true)
        actionMap[.Runlp] = SKAction.repeatForever(runlpAct)
        
        //羽毛球
        var badmintonList = [SKTexture]()
        (0..<10).forEach(){
            i in
            let tex = SKTexture(imageNamed: "badminton_\(i)")
            badmintonList.append(tex)
        }
        let badmintonAct = SKAction.animate(with: badmintonList, timePerFrame: 0.1, resize: true, restore: true)
        actionMap[.Badminton] = SKAction.repeatForever(badmintonAct)
        
        //举哑铃
        var liftList = [SKTexture]()
        (0..<10).forEach(){
            i in
            let tex = SKTexture(imageNamed: "lift_\(i)")
            liftList.append(tex)
        }
        let liftAct = SKAction.animate(with: liftList, timePerFrame: 0.1, resize: true, restore: true)
        actionMap[.Lift] = SKAction.repeatForever(liftAct)
        
        //仰卧起坐
        var situpsList = [SKTexture]()
        (0..<20).forEach(){
            i in
            let tex = SKTexture(imageNamed: "situps_\(i)")
            situpsList.append(tex)
        }
        let situpsAct = SKAction.animate(with: situpsList, timePerFrame: 0.1, resize: true, restore: true)
        actionMap[.Situps] = situpsAct
        
        //立卧
        var liePreList = [SKTexture]()
        (0..<12).forEach(){
            i in
            let tex = SKTexture(imageNamed: "burpee_\(i)")
            liePreList.append(tex)
        }
        let liePreAct = SKAction.animate(with: liePreList, timePerFrame: 0.1, resize: true, restore: false)
        actionMap[.LiePre] = liePreAct
        
        var lieSufList = [SKTexture]()
        (12..<22).forEach(){
            i in
            let tex = SKTexture(imageNamed: "burpee_\(i)")
            lieSufList.append(tex)
        }
        let lieSufAct = SKAction.animate(with: lieSufList, timePerFrame: 0.1, resize: true, restore: false)
        actionMap[.LieSuf] = lieSufAct
        
        //立
        let standList = [SKTexture(imageNamed: "burpee_0")]
        let standAct = SKAction.animate(with: standList, timePerFrame: 0.1, resize: true, restore: false)
        actionMap[.Stand] = standAct
        
        //篮球
        var basketballList = [SKTexture]()
        (0..<8).forEach(){
            i in
            let tex = SKTexture(imageNamed: "basketball_\(i)")
            basketballList.append(tex)
        }
        let basketballAct = SKAction.animate(with: basketballList, timePerFrame: 0.1, resize: true, restore: false)
        actionMap[.Basketball] = SKAction.repeatForever(basketballAct)
        
        var basketballSufList = [SKTexture]()
        (0..<6).forEach(){
            i in
            let tex = SKTexture(imageNamed: "basketball_suf_\(i)")
            basketballSufList.append(tex)
        }
        let basketballSufAct = SKAction.animate(with: basketballSufList, timePerFrame: 0.1, resize: true, restore: false)
        actionMap[.BasketballSuf] = basketballSufAct
        
        //跳绳
        var ropeList = [SKTexture]()
        (0..<9).forEach(){
            i in
            let tex = SKTexture(imageNamed: "rope_\(i)")
            ropeList.append(tex)
        }
        let ropeAct = SKAction.animate(with: ropeList, timePerFrame: 0.1, resize: true, restore: false)
        actionMap[.Rope] = SKAction.repeatForever(ropeAct)
        
        //上秤
        var weightList = [SKTexture]()
        (0..<5).forEach(){
            i in
            let tex = SKTexture(imageNamed: "weight_\(i)")
            weightList.append(tex)
        }
        let weightAct = SKAction.animate(with: weightList, timePerFrame: 0.1, resize: true, restore: false)
        actionMap[.Weight] = weightAct
    }
}
