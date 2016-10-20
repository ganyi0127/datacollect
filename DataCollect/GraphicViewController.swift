//
//  GraphicViewController.swift
//  DataCollect
//
//  Created by ganyi on 16/8/4.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit
import CoreBluetooth
class GraphicViewController: UIViewController {
  
    @IBOutlet weak var bindingImageView: UIImageView!
    @IBOutlet weak var pauseButton: UIButton!
    
    //数据显示开关
    @IBOutlet weak var data0Button: UIButton!
    @IBOutlet weak var data1Button: UIButton!
    @IBOutlet weak var data2Button: UIButton!
    @IBOutlet weak var data3Button: UIButton!
    
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
        
        let cornerRadius = data0Button.frame.height / 2
        data0Button.backgroundColor = UIColor(red: 180 / 255, green: 180 / 255, blue: 180 / 255, alpha: 0.5)
        data0Button.layer.cornerRadius = cornerRadius
        data1Button.backgroundColor = UIColor(red: 113 / 255, green: 123 / 255, blue: 236 / 255, alpha: 0.5)
        data1Button.layer.cornerRadius = cornerRadius
        data2Button.backgroundColor = UIColor(red: 123 / 255, green: 252 / 255, blue: 252 / 255, alpha: 0.5)
        data2Button.layer.cornerRadius = cornerRadius
        data3Button.backgroundColor = UIColor(red: 236 / 255, green: 100 / 255, blue: 106 / 255, alpha: 0.5)
        data3Button.layer.cornerRadius = cornerRadius
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        navigationController?.navigationBar.isHidden = false
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    fileprivate func config(){
        
        bindingImageView.layer.shadowColor = UIColor.black.cgColor
        bindingImageView.layer.shadowOffset = CGSize(width: 1, height: 1)
        bindingImageView.layer.shadowRadius = 1
        bindingImageView.layer.shadowOpacity = 0.8
        
        NotificationCenter.default.addObserver(self, selector: #selector(GraphicViewController.receiveRotation),name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
    }
    
    //MARK:检测自动旋转
    func receiveRotation(){

        if isFirstResponder{
            
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            
        }
    }
    
    //MARK:点击返回
    @IBAction func back(_ sender: UIButton) {
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    //MARK:暂停数据接收
    @IBAction func pause(_ sender: UIButton) {
        
        let flag = (view as! DataGraphiscView).pause
        
        if flag{
            (view as! DataGraphiscView).pause = false
            pauseButton.setTitle("II", for: UIControlState())
        }else{
            (view as! DataGraphiscView).pause = true
            pauseButton.setTitle(">", for: UIControlState())
        }
    }
    //MARK:点击切换数据展示
    @IBAction func selectData(_ sender: UIButton) {
        
        let mask = (view as! DataGraphiscView).dataMask
        let tagMask:UInt32 = UInt32(sender.tag)
        
        let anim = CABasicAnimation(keyPath: "transform.scale.x")
        if mask & tagMask > 0{
            anim.fromValue = 1
            anim.toValue = sender.frame.height / sender.frame.width
            
            (view as! DataGraphiscView).dataMask = mask ^ tagMask
        }else{
            anim.fromValue = sender.frame.height / sender.frame.width
            anim.toValue = 1
            
            (view as! DataGraphiscView).dataMask = mask | tagMask
        }

        anim.duration = 0.2
        anim.fillMode = kCAFillModeBoth
        anim.isRemovedOnCompletion = false
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        sender.layer.add(anim, forKey: nil)
    }
    
    //MARK:清除文件数据
    @IBAction func clearFileData(_ sender: UIButton){
        
        let anim = CAKeyframeAnimation(keyPath: "transform.scale.x")
        anim.values = [0.8, 1]
        anim.keyTimes = [0.1, 0.3]
        anim.fillMode = kCAFillModeBoth
        anim.isRemovedOnCompletion = false
        anim.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut), CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)]
        sender.layer.add(anim, forKey: nil)
        if writeData(nil, reset: true){
            (view as! DataGraphiscView).dataList.removeAll()
        }
    }
    
    deinit{
        
        selectPeripheral?.delegate = nil
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
}

extension GraphicViewController{
    
    override func viewControllerPeripheral(didUpdateValueForCharacteristic characteristic: CBCharacteristic, data: Data) {
        
        guard let flag:Bool = (view as? DataGraphiscView)?.pause , !flag else{
            return
        }
        
        var val:[UInt8] = Array(repeating: 0, count: 20)
        (data as NSData).getBytes(&val, length: val.count)
        
        var hexStr = ""
        for (index,hex) in val.enumerated(){
            
            if index != 0{
                hexStr += " "
            }
            
            var dataStr = String(format: "%x", hex)
            while dataStr.characters.count < 2{
                dataStr = "0\(dataStr)"
            }
            
            hexStr += dataStr
            
        }
        writeData(hexStr)
        
        //处理数据
        let configure = User.shareInstance().configure
        print("configure:\(configure)")
        
        //分包
        for package in configure{
            //需要展示的数据包
            var result = [UInt32]()
            
            package.forEach(){
                byteIndexList in
                
                var byte:UInt32 = 0
                
                for (index, byteIndex) in byteIndexList.enumerated(){
                    
                    byte = byte | UInt32(val[byteIndex]) << UInt32((byteIndexList.count - 1 - index) * 8)
                    
                }
                
                result.append(byte)
                
            }
            //print("result:\(result)")
            //绘制数据包
            mainThread(){
                
                (self.view as! DataGraphiscView).drawWhenAddNewData(newData: result)
            }
        }
    }
}
