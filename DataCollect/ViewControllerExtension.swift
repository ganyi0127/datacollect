//
//  ViewControllerExtension.swift
//  DataCollect
//
//  Created by ganyi on 16/8/4.
//  Copyright © 2016年 ganyi. All rights reserved.
//
/*
 
 拓展UIViewController,实现peripheral协议，实现peripheral回调协议
 
 */

import UIKit
import CoreBluetooth

//MARK:protocol Peripheral
protocol ViewControllerPeripheralDelegate {
    
    //发现服务
    func viewControllerPeripheralDidDiscoverServices()
    //发现特征
    func viewControllerPeripheral(didDiscoverCharacteristicsForService service:CBService?, peripheral: CBPeripheral, bindingBle bind:Bool)
    //写入返回
    func viewControllerPeripheral(didWriteValueForCharacteristic characteristic:CBCharacteristic)
    //读取
    func viewControllerPeripheral(didUpdateValueForCharacteristic characteristic:CBCharacteristic, data:Data)
}

//MARK:拓展UIViewController,实现peripheral协议，实现peripheral回调协议
extension UIViewController:CBPeripheralDelegate,ViewControllerPeripheralDelegate{
    
    //ViewControllerPeripheralDelegate - 发现服务
    func viewControllerPeripheralDidDiscoverServices(){
        
    }
    
    //ViewControllerPeripheralDelegate - 发现特征
    func viewControllerPeripheral(didDiscoverCharacteristicsForService service:CBService?, peripheral: CBPeripheral, bindingBle bind:Bool){
        
    }
    
    //ViewControllerPeripheralDelegate - 写入返回
    func viewControllerPeripheral(didWriteValueForCharacteristic characteristic:CBCharacteristic){
        
    }
    
    //ViewControllerPeripheralDelegate - 读取
    func viewControllerPeripheral(didUpdateValueForCharacteristic characteristic:CBCharacteristic, data:Data){
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let err = error else {
            
            viewControllerPeripheralDidDiscoverServices()
            
            print("服务:\(peripheral)获取service成功")
            
            let serviceList = peripheral.services
            
            if let services = serviceList{
                
                for service in services {
                    print("serviceUUID:\(service.uuid) kServiceUUID:\(kServiceUUID)")
                    
                    peripheral.discoverCharacteristics(nil, for: service)
                    
                }
            }
            return
        }
        
        print("发现服务error:\n error:\(err)\n")
        mainThread(){
            
            let name = peripheral.name ?? ""
            
            let alertController = UIAlertController(title: "Error", message: "\(name)\n连接服务失败", preferredStyle: .alert)
            let action = UIAlertAction(title: "返回", style: .default){
                _ in
            }
            alertController.addAction(action)
            
            self.present(alertController, animated: true, completion: nil)
            
        }
    }
    
    //service特征所属服务
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let err = error else{
            
            let characteristicList = service.characteristics
            
            if let characteristics = characteristicList {
                for characteristic in characteristics {
                    
                    switch characteristic.uuid {
                    case kReadUUID:
                        
                        characteristicMap[.read] = characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                        
                    case kWriteUUID:
                        characteristicMap[.write] = characteristic
                    case kBigWriteUUID:
                        characteristicMap[.bigWrite] = characteristic
                    case kBigReadUUID:
                        
                        characteristicMap[.bigRead] = characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                        
                    case kBandingUUID:
                        print("kBandingUUID:\(characteristic.descriptors)")
                    case kInfoUUID:
                        print("kInfoUUID:\(characteristic.descriptors)")
                    case kUpdateUUID:
                        print("kUpdateUUID:\(characteristic.descriptors)")
                    case kControllerUUID:
                        print("kControllerUUID:\(characteristic.descriptors)")
                    case kPacketUUID:
                        print("kPacketUUID:\(characteristic.descriptors)")
                    case kVersionUUID:
                        print("kVersionUUID:\(characteristic.descriptors)")
                    default:
                        print("otherUUID:\(characteristic.descriptors)")
                    }
                }
            }
            
            print("ble提供的服务characteristicMap:\(characteristicMap)\n")
            
            
            
            //提示是否绑定设备
            mainThread(){
                
                //如果已绑定该设备，则直接跳过
                if let UUID = User.shareInstance().bandingUUID , UUID.uuidString == peripheral.identifier.uuidString {
                    self.viewControllerPeripheral(didDiscoverCharacteristicsForService: service, peripheral: peripheral, bindingBle: true)
                    
                    return
                }

                self.viewControllerPeripheral(didDiscoverCharacteristicsForService: service, peripheral: peripheral, bindingBle: false)
                
            }
            return
        }
        
        print("获取特征error:\n error:\(err)")
        
        mainThread(){
            
            let alertController = UIAlertController(title: "Error", message: "获取设备特征失败", preferredStyle: .alert)
            let action = UIAlertAction(title: "返回", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    //MARK:发送数据结束
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let err = error else{
            
            viewControllerPeripheral(didWriteValueForCharacteristic: characteristic)
            
            return
        }
        
        print("写入数据error:\n error:\(err)\n")
    }
    
    //MARK:接收返回数据
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let err = error else{
            
            guard let data = characteristic.value else{
                return
            }
            
            var val:[UInt8] = Array(repeating: 0, count: 20)
            (data as NSData).getBytes(&val, length: data.count)
            
            //截取全局命令-绑定命令
            if let commandId:UInt8 = val[0], let keyId:UInt8 = val[1] , commandId == 0x4{
                
                var success:Bool?
                
                if keyId == 0x01 {
                    //绑定
                    if let statusCode:UInt8 = val[3]{
                        if statusCode == 0x00{
                            //绑定成功
                            success = true
                        }else if statusCode == 0x01{
                            //绑定失败
                            success = false
                        }
                        
                        //绑定回调
                        viewControllerPeripheral(didDiscoverCharacteristicsForService: nil, peripheral: peripheral, bindingBle: success!)
                    }
                }
                
                var message = ""
                if let suc = success{
                    message = suc ? "绑定成功" : "绑定失败"
                    User.shareInstance().update("", forKey: .BindingUUID)
                    
                    let UUIDString = selectPeripheral!.identifier.uuidString
                    User.shareInstance().update(UUIDString, forKey: .BindingUUID)
                }else{
                    message = "解绑成功"
                    User.shareInstance().update(nil, forKey: .BindingUUID)
                }
                
                
                mainThread(){
                    
                    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                    let action = UIAlertAction(title: "确定"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  , style: .cancel, handler: nil)
                    alertController.addAction(action)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            
            //推送数据
            viewControllerPeripheral(didUpdateValueForCharacteristic: characteristic,data: data)
            
            return
        }
        
        //获取数据❌提示
        mainThread(){
            
            let alertController = UIAlertController(title: "通信错误", message: "\(err)", preferredStyle: .alert)
            let action = UIAlertAction(title: "返回", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
