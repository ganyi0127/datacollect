//
//  PeripheralExtension.swift
//  DataCollect
//
//  Created by ganyi on 16/8/4.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum ActionType {
    case binding    //绑定
    case unbinding  //解绑
    case responceType //回复活动状态
    case activated  //实时数据请求
}

private var actionMap:[ActionType:[UInt8]]?{
    let map:[ActionType:[UInt8]] = [.binding:[0x04, 0x01, 0x01, 0x83, 0x55, 0xaa],
                                    .unbinding:[0x04, 0x02, 0x55, 0xaa, 0x55, 0xaa],
                                    .responceType:[0x07, 0xA1, 0x01],
                                    .activated:[0x02, 0xA1]]
    return map
}

extension CBPeripheral{
    
    //MARK:根据指令类型发送命令
    public func write(withActionType actionType:ActionType, writeType:CBCharacteristicWriteType = .withResponse){
        
        guard var val = actionMap![actionType] else{
            return
        }
        
        //多类型实时数据，需添加动作类型
        if actionType == .activated{
            val.append(currentType)
        }
        
        while val.count < 20 {
            val.append(0x00)
        }
        let data = Data(bytes: UnsafePointer<UInt8>(val), count: val.count)
        
        if let characteristic = characteristicMap[.write]{
            
            self.writeValue(data, for: characteristic, type: writeType)
        }
    }
    
    //MARK:自定义写入
    public func write(withValue value:[UInt8]){
        
        var val = Array<UInt8>(value)
        
        while val.count < 20 {
            val.append(0x00)
        }
        let data = Data(bytes: UnsafePointer<UInt8>(val), count: val.count)
        
        if let characteristic = characteristicMap[.write]{
            writeValue(data, for: characteristic, type: .withoutResponse)
        }
    }
}
