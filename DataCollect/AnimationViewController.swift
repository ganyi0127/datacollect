//
//  AnimationViewController.swift
//  DataCollect
//
//  Created by ganyi on 16/8/6.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit
import CoreBluetooth
import AVFoundation

class AnimationViewController: UIViewController {
    
    var backButton: UIButton!
    var pauseButton: UIButton!
    
    fileprivate var pause = false
    
    //存储数据展示view
    fileprivate var platformView:PlatformView?
    
    fileprivate var task:Task?
    
    //SpriteKit
    fileprivate var spriteView:SpriteView?
    
    //MARK: init-----------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        config()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        selectPeripheral?.delegate = self
        
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        navigationController?.navigationBar.isHidden = true
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        createContents()
        
        update()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        cancel(task)
        task = nil
        
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        navigationController?.navigationBar.isHidden = false
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    //MARK:检测自动旋转
    func receiveRotation(){
        
        if isFirstResponder{
            
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            
        }
    }
    
    fileprivate func config(){
        NotificationCenter.default.addObserver(self, selector: #selector(GraphicViewController.receiveRotation),name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    fileprivate func createContents(){
        
        //添加spriteKit
        spriteView = SpriteView(frame: view.frame)
        view.addSubview(spriteView!)
        
        //添加数据展示view
        platformView = PlatformView()
        view.addSubview(platformView!)

        //创建按钮
        backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 46, height: 46))
        backButton.addTarget(self, action: #selector(AnimationViewController.back(_:)), for: .touchUpInside)
        backButton.setTitle("<", for: UIControlState())
        view.addSubview(backButton)
        
//        pauseButton = UIButton(frame: CGRect(x: 54, y: 0, width: 46, height: 46))
//        pauseButton.addTarget(self, action: #selector(AnimationViewController.pause(_:)), forControlEvents: .TouchUpInside)
//        pauseButton.setTitle("II", forState: .Normal)
//        view.addSubview(pauseButton)
    }
    
    //MARK:点击返回
    func back(_ sender: UIButton) {
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    //MARK:暂停数据接收
    func pause(_ sender: UIButton) {
        
        let flag = pause
        
        if flag{
            pause = false
            pauseButton.setTitle("II", for: UIControlState())
        }else{
            pause = true
            pauseButton.setTitle(">", for: UIControlState())
        }
    }
    
    //MARK:发送活动数据请求
    func update(){
        
        selectPeripheral?.write(withActionType: ActionType.activated)
        
        task = delay(1){
            
            self.update()
        }
    }

    deinit{
        
        selectPeripheral?.delegate = nil
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
}

extension AnimationViewController{
    
    override func viewControllerPeripheral(didUpdateValueForCharacteristic characteristic: CBCharacteristic, data: Data) {
        
        //暂停不接收数据
        guard !pause else{
            return
        }
        
        //获取返回的数据信息
        var val:[UInt8] = Array(repeating: 0, count: 20)
        
        (data as NSData).getBytes(&val, length: data.count)
        
        print("\n\(val)")
        //切换运动状态
        if let commandId:UInt8 = val[0], let keyId:UInt8 = val[2] , commandId == 0x07{
            
            //回应状态切换
            selectPeripheral?.write(withActionType: .responceType, writeType: .withoutResponse)
            
            //切换多类型实时数据状态
            currentType = keyId
            print("\n\(currentType)")

            //动画切换
            guard let scene = self.spriteView?.scene else{
                return
            }
            
            mainThread(){
                
                //key == 0 跳过
                guard currentType != 0 else{
                    (scene as! MainScene).player.isHidden = true
                    return
                }
                (scene as! MainScene).player.isHidden = false
                
                //运动或停止，当运动类型支持停止时使用
//                if let status:UInt8 = val[3], type:UInt8 = val[2] where Array<UInt8>([10, 11, 13, 14, 16, 17, 18, 19, 20]).contains(type){
//                    if status == 0x01{
//                        //运行
//                        (scene as! MainScene).type = (true, currentType)
//                    }else{
//                        //暂停
//                        (scene as! MainScene).type = (false, currentType)
//                    }
//                }else{
//                }
                (scene as! MainScene).type = (0x01, currentType)
            }
        }
        
        //获取实时数据
        if let commandId:UInt8 = val[0] , commandId == 0xA1{
            
            //过滤
            guard let type:UInt8 = val[2] , type == currentType else{
                return
            }
            
            //展示数据
            mainThread(){
                
                //运动或停止，当运动类型支持停止时使用
                if let status:UInt8 = val[3], let type:UInt8 = val[2] , Array<UInt8>([10, 11, 13, 14, 16, 17, 18, 19, 20]).contains(type){
//                    if status == 0x01{
//                        //运行
//                        (self.spriteView?.scene as! MainScene).type = (true, currentType)
//                    }else{
//                        //暂停
//                        (self.spriteView?.scene as! MainScene).type = (false, currentType)
//                    }
                    (self.spriteView?.scene as! MainScene).type = (status, currentType)
                }else{
                    (self.spriteView?.scene as! MainScene).type = (0x01, currentType)
                }
                
                //展示数据
                self.platformView?.dataViewList.enumerated().forEach(){
                    index, dataView in
                    
                    dataView.value = (type: currentType, data: val)
                }
            }
        }
    }
}
