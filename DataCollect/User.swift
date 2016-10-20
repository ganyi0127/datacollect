//
//  User.swift
//  DataCollect
//
//  Created by ganyi on 16/8/4.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import Foundation
import CoreBluetooth

enum FileKey:String {
    case BindingUUID = "bindingUUID"        //绑定的UUID
    case ByteConfigure = "byteconfigure"    //数据配置
    case SettingName = "settingname"        //搜索设备名
    case SettingRSSI = "settingrssi"        //搜索信号强度
}

class User {
    
    private static var __once: () = {
            singleton.instance = User()
        }()
    
    fileprivate let boundPath = Bundle.main.path(forResource: "User", ofType: "plist")!
    
    //绑定UUID
    var bandingUUID:UUID?{
        get{
            guard let uuidString = select(fromKey: .BindingUUID) , uuidString.lengthOfBytes(using: String.Encoding.utf8) != 0 else{
                return nil
            }
            return UUID(uuidString: uuidString)
        }
    }
    
    //数据配置
    var configure:[[[Int]]]{
        get{
            return [
                [[0], [1], [2], [3]],
                [[4], [5], [6]],
                [[8], [9], [10]],
                [[12], [13], [14]],
                [[16], [17], [18]]
            ]
        }
    }
    
    //设备名
    var settingName:String?{
        get{
            guard let name = selectSettingName() else{
                return nil
            }
            return name
        }
    }
    
    //设备强度
    var settingRSSI:NSNumber?{
        get{
            guard let rssi = selectSettingRSSI() else{
                return nil
            }
            return rssi
        }
    }
    
    //MARK: init--------------------------------------------
    struct singleton{
        static var onceToken:Int = 0
        static var instance:User! = nil
    }
    class func shareInstance() -> User{

        _ = User.__once
        
        return singleton.instance
    }
    
    fileprivate func documentPath() -> String{
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)
        let path = paths[0]
        return path + "/User.plist"
    }
    
    fileprivate func readFile() -> NSMutableDictionary{
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: documentPath()) {
            return NSMutableDictionary(contentsOfFile: documentPath())!
        }
        return NSMutableDictionary(contentsOfFile: boundPath)!
    }
    
    //MARK:-写入数据
    func update(_ value: String?, forKey key: FileKey) -> Bool{
        
        let result = readFile()
        result.setValue(value, forKey: key.rawValue)
        result.write(toFile: documentPath(), atomically: true)
        return true
    }
    
    //MARK:读取数据
    fileprivate func select(fromKey key:FileKey) -> String? {
        
        let result = readFile()
        return result.value(forKey: key.rawValue) as? String
    }
    
    //MARK:写入配置数据
    func updateConfig(_ byteConfig:[[[Int]]], forKey key:FileKey = .ByteConfigure) -> Bool{
        
        let result = readFile()
        result.setValue(byteConfig, forKey: key.rawValue)
        result.write(toFile: documentPath(), atomically: true)
        return true
    }
    
    //MARK:读取配置数据
    fileprivate func selectConfig(fromKey key:FileKey = .ByteConfigure) -> [[[Int]]]? {
        let result = readFile()
        return result.value(forKey: key.rawValue) as? [[[Int]]]
    }
    
    //MARK:写入搜索设备名
    func updateSettingName(_ name: String?) -> Bool{
        
        let result = readFile()
        if let n = name{
            result.setValue(n, forKey: FileKey.SettingName.rawValue)
        }else{
            result.setValue(nil, forKey: FileKey.SettingName.rawValue)
        }
        result.write(toFile: documentPath(), atomically: true)
        return true
    }
    
    //MARK:读取搜索设备名
    fileprivate func selectSettingName() -> String?{
        let result = readFile()
        return result.value(forKey: FileKey.SettingName.rawValue) as? String
    }
    
    //MARK:写入搜索RSSI
    func updateSettingRSSI(_ rssi: NSNumber?) -> Bool{
        
        let result = readFile()
        if let r = rssi{
            result.setValue(r, forKey: FileKey.SettingRSSI.rawValue)
        }else{
            result.setValue(nil, forKey: FileKey.SettingRSSI.rawValue)
        }
        result.write(toFile: documentPath(), atomically: true)
        return true
    }
    
    //MARK:读取搜索RSSI
    fileprivate func selectSettingRSSI() -> NSNumber?{
        let result = readFile()
        return result.value(forKey: FileKey.SettingRSSI.rawValue) as? NSNumber
    }
}
