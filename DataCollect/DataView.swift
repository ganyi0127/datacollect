//
//  DataView.swift
//  DataCollect
//
//  Created by ganyi on 16/8/6.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit
class DataView: UIView {

    var value:(type:UInt8,data:[UInt8]) = (0x00,[]){
        didSet{
            
            guard let tupleList = dataList[value.type] else{
                isHidden = true
                return
            }
            
            guard let index:Int = dataTag! , index < tupleList.count else{
                isHidden = true
                return
            }
            
            guard let tuple:(String, [Int]) = tupleList[index] else{
                isHidden = true
                return
            }
            
            isHidden = false
            
            let title = tuple.0
            let byteIndexList = tuple.1
            var result:UInt32 = 0x0
            byteIndexList.enumerated().forEach(){
                index, byteIndex in
                
                result = result | UInt32(value.data[byteIndex]) << UInt32(8 * index)
            }
            
            var floatResult = Float(result)
            
            //数据后缀，icon
            var imageName:String?
            var suffix = ""
            switch title {
            case "步数":
                suffix = "步"
                imageName = "icon_step"
            case "卡路里":
                suffix = "大卡"
                imageName = "icon_calories"
                //跑步机
                if value.type == UInt8("17", radix: 16)!{
                    floatResult /= 10
                }
            case "距离":
                suffix = "m"
                imageName = "icon_distance"
            case "活动时长":
                suffix = "s"
                imageName = "icon_time"
            case "体重":
                suffix = "kg"
                //放大100倍
                floatResult /= 100
                imageName = "icon_weight"
            case "体脂率":
                suffix = "%"
                //放大100倍
                floatResult /= 100
                imageName = "icon_fat"
            case "步速":
                suffix = "步/分钟"
                imageName = "icon_stepspeed"
            case "速度":
                suffix = "km/h"
                imageName = "icon_speed"
                //跑步机
                if value.type == UInt8("17", radix: 16)!{
                    floatResult /= 10
                }
            case "踏频速度":
                suffix = "次/分钟"
                imageName = "icon_ridespeed"
            case "次数":
                suffix = "次"
                imageName = "icon_count"
            case "心率":
                suffix = "BPM"
                imageName = "icon_rate"
            case "频率":
                suffix = "次/分钟"
                imageName = "icon_frequency"
            default:
                suffix = ""
            }
            
            label?.text = "\(title)\n\(floatResult) \(suffix)"
            
            //移除动画
            if value.type != oldValue.type{
//                layer.removeAllAnimations()
                
                //重设动画
                setAnim(value.type)
            }
            
            //添加icon
            if let name = imageName{
                image = UIImage(named: name)
            }
        }
    }
    fileprivate var label:UILabel?
    fileprivate var imageView:UIImageView?
    fileprivate var image:UIImage?{
        didSet{
            imageView?.image = image
        }
    }
    
    //属性次序,用于标示运动数据的类型
    var dataTag:Int?
    
    init(withTag initDataTag: Int){
        
        let initFrame = CGRect(x: 0, y: 0, width: 300 * viewSize.height / 1334, height: 100 * viewSize.width / 750)
        super.init(frame: initFrame)
        
        dataTag = initDataTag
        
        config()
        createContents()
    }
    
    fileprivate func config(){
        
        backgroundColor = UIColor.black.withAlphaComponent(0.1)
        
        layer.cornerRadius = 2
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 2
        
        layer.zPosition = 100
        layer.opacity = 0.6
        
        isHidden = true
    }
    
    fileprivate func createContents(){
        
        label = UILabel(frame: CGRect(origin: CGPoint.zero, size: frame.size))
        label?.textAlignment = .right
        label?.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        label?.textColor = .white
        label?.numberOfLines = 3
        label?.text = "\(value.type)\r\(value.data)"
        addSubview(label!)
        
        imageView = UIImageView()
        imageView?.frame = CGRect(origin: .zero, size: CGSize(width: 95 * viewSize.width / 750, height: 95 * viewSize.width / 750))
        addSubview(imageView!)
        
        //排列数据
        frame.origin = CGPoint(x: viewSize.height / 8 * CGFloat(dataTag!), y: 0)
        
//        //透视与偏移
//        if dataTag! < 4{
//            frame.origin = CGPoint(x: 50, y: 0)
//        }else{
//            frame.origin = CGPoint(x: viewSize.height - frame.size.width - 50, y: 0)
//        }
//        
//        layer.zPosition = 1000
//        
//        var transform = CATransform3DIdentity
//        transform.m34 = -1 / 550
//        let fix:CGFloat = dataTag! < 4 ? 1 : -1
//        transform = CATransform3DRotate(transform, CGFloat(M_PI_4), 0.4, 1 * fix, 0.3 * fix)
//        transform = CATransform3DTranslate(transform, 0, CGFloat(dataTag! % 4) * 50 + 30, 0)
//        
//        layer.transform = transform
    }
    
    fileprivate func setAnim(_ type:UInt8){

        guard let valuesList = keyList[type] , dataTag! < valuesList.points.count else{
            return
        }
        
        if let points:[CGPoint] = valuesList.points[dataTag!], let duration:Double = valuesList.duration{
            
            let values = points.map(){NSValue(cgPoint: $0)}
            
            //动画，跟随角色运动
            let anim = CAKeyframeAnimation(keyPath: "position")
            anim.values = values
            anim.duration = duration
            anim.repeatCount = HUGE
            anim.fillMode = kCAFillModeBoth
            anim.isRemovedOnCompletion = false
            layer.add(anim, forKey: nil)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DataView{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.toValue = 1.2
        anim.duration = 0.2
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        layer.add(anim, forKey: nil)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        let scaleAnim = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnim.values = [0.9, 1]
        scaleAnim.keyTimes = [0.1, 0.1]
        scaleAnim.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
                                     CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)]
        layer.add(scaleAnim, forKey: nil)
    }
}

