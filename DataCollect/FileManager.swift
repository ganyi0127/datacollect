//
//  FileManager.swift
//  DataCollect
//
//  Created by ganyi on 16/8/4.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import Foundation

//MARK: 获取当前路径 flag 手动添加文件路径：日期后加下标
private func dataPath() -> String {
    
    let filemanager = FileManager.default
    
    //获取当前日期
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    let dateStr = formatter.string(from: Date())
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)
    let path = paths[0]
    let filePath = path + "/\(dateStr).txt"
    
    //返回最新的文档
    var fileList = filemanager.subpaths(atPath: path)!.filter(){$0.hasSuffix(".txt")}
    if fileList.isEmpty{
        return filePath
    }else{
        
        fileList = fileList.sorted(){
            argu1, argu2 in
            let fp1 = path + "/\(argu1)"
            let fp2 = path + "/\(argu2)"
            do{
                
                let attributes1 = try filemanager.attributesOfItem(atPath: fp1)
                let attributes2 = try filemanager.attributesOfItem(atPath: fp2)
                
                if let createDate1:Date = attributes1[FileAttributeKey.modificationDate] as? Date, let createDate2:Date = attributes2[FileAttributeKey.modificationDate] as? Date{
                    return (createDate1 == (createDate1 as NSDate).earlierDate(createDate2))
                }
            }catch let err{
                print("\n获取文件信息错误: \(err)")
            }
            return true
        }
        
        return path + ("/" + fileList.last!)
    }
}

func newFile() -> String{
    
    let filemanager = FileManager.default
    
    //获取当前日期
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyMMdd"
    let dateStr = formatter.string(from: Date())
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)
    let path = paths[0]
    var result = "/\(dateStr).txt"
    var filePath = path + result
    
    
    //返回最新的文档
    let fileList = filemanager.subpaths(atPath: path)!.filter(){$0.hasSuffix(".txt")}
    if fileList.isEmpty{
        do{
            try String().write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
            
        }catch let error{
            print("\n创建新文件错误:\(error)\n")
        }
    }else{
        var i = 0
        while filemanager.fileExists(atPath: filePath) {
            i += 1
            result = "/\(dateStr)-\(i).txt"
            filePath = path + result
        }
        do{
            try String().write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        }catch let error{
            print("\n创建新文件错误:\(error)\n")
        }
    }
    
    return result
}

//MARK:写入文件内容
func writeData(_ data:String?, reset:Bool = false) -> Bool{
    
    if !FileManager.default.fileExists(atPath: dataPath()){
        do {
            try String().write(toFile: dataPath(), atomically: true, encoding: String.Encoding.utf8)
            
        }catch let error{
            print("\n初始化写入文件错误:\(error)\n")
        }
    }
    
    //重置文件
    if reset{
        let emptyData = ""
        do{
            try emptyData.write(toFile: dataPath(), atomically: true, encoding: String.Encoding.utf8)
        }catch let error{
            print("\n清空文件错误:\(error)\n")
        }
        return true
    }
    
    //追加文件
    guard let fileHandle = FileHandle(forWritingAtPath: dataPath()) else{
        print("\n未获取到文件句柄")
        return false
    }
    
    //判断写入数据非空
    guard let seekData:String = data else{
        print("\n写入数据非法null")
        return false
    }
    
    let result = seekData + "\n"
    
    fileHandle.seekToEndOfFile()
    
    fileHandle.write(result.data(using: String.Encoding.utf8)!)
    fileHandle.closeFile()
    
    return true
}

//MARK: 删除文件
func deleteFile(filePath path: String) -> Bool{
    
    do{
        
        try FileManager.default.removeItem(atPath: path)
        
    }catch let err{
        print("\n删除文件错误: \(err)")
        return false
    }
    return true
}
