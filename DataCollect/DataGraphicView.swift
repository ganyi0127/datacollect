//
//  DataGraphicView.swift
//  DataCollect
//
//  Created by ganyi on 16/8/4.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit
@IBDesignable
class DataGraphiscView: UIView {
    
    //缓冲区
    fileprivate var vertexData:[Float] = []
    
    //保存的数据范围
    var dataRange = 500{
        didSet{
            if dataRange < 50{
                dataRange = 50
            }else if dataRange > 5000{
                dataRange = 5000
            }
            
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    var dataList:[[UInt32]] = {
        var dataList = [[UInt32]]()
        
        return dataList
        }(){
        didSet{
            
            //数据超过5000，移除最早的数据
            dataList.enumerated().forEach(){
                index, datas in
                if datas.count > 5000{
                    dataList[index].removeFirst()
                }
            }
            
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    //察看数据偏移 offset <= 0
    var viewOffset = 0{
        didSet{
            
            if dataList.isEmpty{
                viewOffset = 0
                return
            }
            
            if viewOffset > 0 || dataList[0].count < dataRange{
                viewOffset = 0
            }else if dataList[0].count + viewOffset < dataRange{
                viewOffset = dataRange - dataList[0].count
            }
            
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    //暂停
    var pause = false
    
    //需要展示的数据映射:默认为所有数据
    var dataMask:UInt32 = 0xF{
        didSet{
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    //数据线颜色
    var dataColors = [
        UIColor(red: 113 / 255, green: 123 / 255, blue: 236 / 255, alpha: 0.5).cgColor,
        UIColor(red: 123 / 255, green: 252 / 255, blue: 252 / 255, alpha: 0.5).cgColor,
        UIColor(red: 236 / 255, green: 100 / 255, blue: 106 / 255, alpha: 0.5).cgColor,
        UIColor(red: 156 / 255, green: 255 / 255, blue: 170 / 255, alpha: 0.5).cgColor,
        UIColor(red: 255 / 255, green: 255 / 255, blue: 170 / 255, alpha: 0.5).cgColor
    ]
    
    fileprivate let backColor = UIColor(red: 255 / 255, green: 248 / 255, blue: 245 / 255, alpha: 1).cgColor
    
    //上下极值
    fileprivate var maxY:UInt32{
        get{
            var maxY:UInt32 = 127
            for data in dataList{
                if let max = data.max() , max > maxY{
                    maxY = max
                }
            }
            return maxY
        }
    }
    
    fileprivate var minY:UInt32{
        get{
            var minY:UInt32 = maxY
            for data in dataList{
                if let min = data.min() , min < minY{
                    minY = min
                }
                
            }
            return minY
        }
    }
    
    //init------------------------------------------------------------------------------------
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        config()
        createContents()
    }
    
    fileprivate func config(){
        
        layer.shouldRasterize = true
        
        isUserInteractionEnabled = true
    }
    
    fileprivate func createContents(){
        
        //注册捏合事件
        let pin = UIPinchGestureRecognizer(target: self, action: #selector(DataGraphiscView.pin(_:)))
        addGestureRecognizer(pin)
        
    }
    
    //MARK:捏合手势，控制数据范围
    fileprivate var originDataRange = 0
    func pin(_ gesture:UIPinchGestureRecognizer){
        
        originDataRange = dataRange
        
        if gesture.state == .began{
            originDataRange = dataRange
        }else if gesture.state == .ended{
            //dataRange = originDataRange
        }
        
        var scale = 1 / gesture.scale

        print(scale)
        if scale > 1{
            if scale > 3{
                scale = 3
            }
            dataRange = Int(CGFloat(originDataRange) * ((scale - 1) * 0.1 + 1))
        }else{
            if gesture.scale > 3{
                scale = 1 / 3
            }
            dataRange = Int(CGFloat(originDataRange) * (1 / ((1 / scale - 1) * 0.1 + 1)))
        }
    }
    
    //MARK:offset 触摸事件
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches{
            
            let curLocationX = touch.location(in: self).x
            let preLocationX = touch.previousLocation(in: self).x
            
            let delta = curLocationX - preLocationX
            
            viewOffset -= Int(delta)
        }
    }
    
    //MARK:根据数据绘制曲线
    func drawWhenAddNewData(newData data:[UInt32]){
        
        mainThread(){
            
            guard !self.pause else{
                return
            }
            
            //index:拆分的数据数量， byte:数据
            for (index, byte) in data.enumerated(){
                //如果无对应的子数组，则先添加一个空数组
                if self.dataList.count < index + 1{
                    let datas = [UInt32]()
                    self.dataList.append(datas)
                }
                
                self.dataList[index].append(byte)
                
            }
        }
    }
    
    //MARK: 旋转之后重绘
    override func layoutMarginsDidChange() {
        setNeedsLayout()
        setNeedsDisplay()
    }
}

//MARK:触摸手势
extension DataGraphiscView{

}

//MARK:layer delegate
extension DataGraphiscView{
    
    override func draw(_ rect: CGRect) {
        
        var ctx:CGContext? = UIGraphicsGetCurrentContext()
        
        ctx?.clear(rect)
        ctx?.setAllowsAntialiasing(true) //抗锯齿
        
        //填充背景
        ctx?.setFillColor(backColor)
        ctx?.fill(rect)
        
        //绘制底框：横 刻度线
        ctx?.move(to: CGPoint(x: frame.size.width * 0.06, y: frame.size.height * 0.9))
        ctx?.addLine(to: CGPoint(x: frame.size.width, y: frame.size.height * 0.9))
        
        //竖 刻度线
        ctx?.move(to: CGPoint(x: frame.size.width * 0.06, y: 0))
        ctx?.addLine(to: CGPoint(x: frame.size.width * 0.06, y: frame.size.height * 0.9))
        
        //设置
        ctx?.setLineWidth(2)
        ctx?.setStrokeColor(red: 115 / 255, green: 148 / 255, blue: 200 / 255, alpha: 0.8)
        
        ctx?.drawPath(using: .stroke)
        
        
        //绘制底框：纵线
        let horLineCount = 10 * 5
        (0..<horLineCount).forEach(){
            index in
            let x = frame.size.width * 0.06 + frame.size.width * 0.94 / CGFloat(horLineCount) * CGFloat(index + 1)
            let y = (index + 1) % 5 == 0 && index != 0 ? 0 : frame.size.height * 0.9 - 10
            ctx?.move(to: CGPoint(x: x, y: y))
            ctx?.addLine(to: CGPoint(x: x, y: frame.size.height * 0.9))
            
        }
        
        //绘制底框： 横线
        let verLineCount = 19
        (0..<verLineCount).forEach(){
            index in
            let y = frame.size.height * 0.9 / CGFloat(verLineCount + 1) * CGFloat(index + 1)
            ctx?.move(to: CGPoint(x: frame.size.width * 0.06, y: y))
            ctx?.addLine(to: CGPoint(x: frame.size.width, y: y))
            
            if index % 5 == 0 && index != 0{
                ctx?.setLineWidth(2)
            }else{
                ctx?.setLineWidth(1)
            }
            
            //设置
            ctx?.setLineDash(phase: 0, lengths: [0])
            ctx?.setStrokeColor(red: 155 / 255, green: 178 / 255, blue: 220 / 255, alpha: 0.3)
            ctx?.drawPath(using: .stroke)
        }
        
        //maxY minY
        let maxy = maxY, miny = minY
        
        //文字：配置
        let paragraphStyle:NSParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSParagraphStyle
        let attributes = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 12),
            NSForegroundColorAttributeName: UIColor.gray,
            NSParagraphStyleAttributeName: paragraphStyle]
        
        //127 参考线
        if maxy > 127 && miny < 127{
            let originY = CGFloat(maxy - 127) / CGFloat(maxy - miny) * frame.size.height
            ctx?.move(to: CGPoint(x: frame.size.width * 0.06, y: originY))
            ctx?.addLine(to: CGPoint(x: frame.size.width, y: originY))
            
            //设置
            ctx?.setStrokeColor(red: 255 / 255, green: 10 / 255, blue: 10 / 255, alpha: 0.5)
            ctx?.drawPath(using: .stroke)
            
            //127文字
            let originTitle = NSString(string: "\(127)")
            var originTitleRect = originTitle.boundingRect(with: frame.size, options: .usesLineFragmentOrigin,
                                                                   attributes: [
                                                                    NSFontAttributeName: UIFont.systemFont(ofSize: 10),
                                                                    NSForegroundColorAttributeName: UIColor.red,
                                                                    NSParagraphStyleAttributeName: paragraphStyle],
                                                                   context: nil)
            originTitleRect.origin = CGPoint(x: frame.width - originTitleRect.width, y: originY - originTitleRect.height)
            originTitle.draw(in: originTitleRect, withAttributes: [
                NSFontAttributeName: UIFont.systemFont(ofSize: 10),
                NSForegroundColorAttributeName: UIColor.red.withAlphaComponent(0.5),
                NSParagraphStyleAttributeName: paragraphStyle])
        }
        
        //绘制文字： 数据
        (0..<6).forEach(){
            index in
            let value = miny + UInt32(maxy - miny) * UInt32(index) / 5
            let dataTitle = NSString(string: "\(value)")
            var dataTitleRect = dataTitle.boundingRect(with: frame.size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            dataTitleRect.origin = CGPoint(x: frame.width * 0.06 - dataTitleRect.width, y: frame.height * 0.9 - dataTitleRect.height - CGFloat(index) / 5 * frame.height * 0.7)
            dataTitle.draw(in: dataTitleRect, withAttributes: attributes)
        }
        
        //绘制文字： 范围 最大值
        (0..<11).forEach(){
            index in
            var rangeTitle = NSString(string: "\(dataRange / 10 * index)")
            if !dataList.isEmpty && dataList[0].count >= dataRange{
                let startIndex = dataList[0].count - dataRange
                //设置开始范围>0
                if viewOffset + startIndex < 0{
                    viewOffset = -startIndex
                }
                rangeTitle = NSString(string: "\(dataRange / 10 * index + startIndex + viewOffset)")
            }
            var rangeTitleRect = rangeTitle.boundingRect(with: frame.size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            let x = frame.width * 0.06 + frame.width * 0.9 * CGFloat(index) / 10 - rangeTitleRect.width
            let y = frame.height * 0.9
            rangeTitleRect.origin = CGPoint(x: x, y: y)
            rangeTitle.draw(in: rangeTitleRect, withAttributes: attributes)
        }
        
        //绘制数据线
        (0..<dataList.count).forEach(){
            index in
            let mask:UInt32 = 0x1 << UInt32(index)
            if dataMask & mask > 0{
                
                //绘制路径
                getPath(fromData: dataList[index], ctx: &ctx!, maxYcopy: maxy, minYcopy: miny, dataIndex: index)
                
                //设置
                ctx?.setLineWidth(2)
                ctx?.setLineDash(phase: 0, lengths: [0])
                ctx?.setStrokeColor(index < dataColors.count ? dataColors[index] : UIColor.black.withAlphaComponent(0.5).cgColor)
                ctx?.setLineJoin(.round)
                ctx?.setShadow(offset: CGSize(width: 0,height: 1), blur: 0, color: UIColor.black.cgColor)
                
                ctx?.drawPath(using: .stroke)
            }
        }
    }
    
    //多钟数据添加
    fileprivate func getPath(fromData data:[UInt32],ctx: inout CGContext, maxYcopy maxy:UInt32, minYcopy miny:UInt32, dataIndex:Int = 0){
        
        //根据数组值绘制线段
        let subData = Array(data)
        
        for (index, value) in subData.enumerated(){
            
            if subData.count > dataRange{
                if index - viewOffset + dataRange < subData.count{
                    continue
                }
                else if index + viewOffset > subData.count{
                    continue
                }
            }
            
            //最后dataRange位
            let frameHeight = frame.size.height
            let y:CGFloat = frameHeight * 0.9 - (CGFloat(value - miny) / CGFloat(maxy - miny)) * frameHeight * 0.8
            
            //根据最高展示数据数量，重置起始位置index
            let fixIndex = subData.count > dataRange ?  index - (subData.count - dataRange + viewOffset): index
            
            if fixIndex == 0{
                ctx.move(to: CGPoint(x: frame.width * 0.06, y: y))
            }else{
                let point = CGPoint(x: frame.width * 0.9 / CGFloat(dataRange - 1) * CGFloat(fixIndex) + frame.width * 0.06, y: y)
                ctx.addLine(to: CGPoint(x: point.x, y: point.y))
                
            }
        }
    }
}
