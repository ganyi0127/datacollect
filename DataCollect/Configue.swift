//
//  Configue.swift
//  DataCollect
//
//  Created by ganyi on 16/8/4.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit
import CoreBluetooth

//MARK: 区分项目 0:图表 1:动画
var project = 0

//MARK: 蓝牙UUID
let kServiceUUID =          CBUUID(string: "00000af0-0000-1000-8000-00805f9b34fb")
let kCharacteristicUUID =   CBUUID(string: "00001531-1212-EFDE-1523-785FEABCD123")
let kWriteUUID =            CBUUID(string: "00000af6-0000-1000-8000-00805f9b34fb")  //写入ble
let kReadUUID =             CBUUID(string: "00000af7-0000-1000-8000-00805f9b34fb")  //读取ble
let kBigWriteUUID =         CBUUID(string: "00000af1-0000-1000-8000-00805f9b34fb")  //用于读取健康相关数据
let kBigReadUUID =          CBUUID(string: "00000af2-0000-1000-8000-00805f9b34fb")  //用于读取健康相关数据
let kSensorWriteUUID =      CBUUID(string: "00000af3-0000-1000-8000-00805f9b34fb")  //写入传感器数据
let kSensorReadUUID =       CBUUID(string: "00000af4-0000-1000-8000-00805f9b34fb")  //读取传感器数据
let kBandingUUID =          CBUUID(string: "2A27")
let kInfoUUID =             CBUUID(string: "180A")
let kUpdateUUID =           CBUUID(string: "00001530-1212-EFDE-1523-785FEABCD123")
let kControllerUUID =       CBUUID(string: "00001531-1212-EFDE-1523-785FEABCD123")
let kPacketUUID =           CBUUID(string: "00001532-1212-EFDE-1523-785FEABCD123")
let kVersionUUID =          CBUUID(string: "00001534-1212-EFDE-1523-785FEABCD123")

//MARK: 储存特征 CBCharacteristic
enum CharacteristicType{
    case write
    case read
    case bigWrite
    case bigRead
}
var characteristicMap = [CharacteristicType:CBCharacteristic]()

//MARK: 选择的外设
var selectPeripheral:CBPeripheral?

//当前多类型实时数据类型type-默认步行
var currentType:UInt8 = 0x10

//MARK: 尺寸
let viewSize = UIScreen.main.bounds.size

//MARK: 圆角
let kCornerRadius:CGFloat = 10

//MARK: 通用字体、颜色
let fontName = "Optima-ExtraBlack"
let defautColor = UIColor(red: 91 / 255, green: 180 / 255, blue: 255 / 255, alpha: 1)

//MARK: 定时器
typealias Task = (_ cancel:Bool)->()

func delay(_ time:TimeInterval,task:@escaping ()->()) -> Task? {
    
    func dispatch_later(_ block:@escaping ()->()){
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: block)
    }
    
    var closure:(()->())? = task
    var result:Task?
    
    let delayedClosure:Task = {
        cancel in
        if let internalClosure = closure {
            if !cancel {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }
    
    result = delayedClosure
    
    dispatch_later(){
        if let delayedClosure = result{
            delayedClosure(false)
        }
    }
    return result
}

func cancel(_ task:Task?) {
    task?(true)
}

//MARK: 线程
func mainThread(_ closure:@escaping ()->()) {
    DispatchQueue.main.async(execute: closure)
}

func globalThread(_ closure:@escaping ()->()){
    DispatchQueue(label: "com.idoor.global").async(execute: closure)
}

//坐、立、卧、打字、走路、跑步、自行车、爬楼梯、哑铃、跳绳、仰卧起坐、俯卧撑、体重秤、打篮球、羽毛球
//0x02:秤重;0x03:静坐; 0x04:站立; 0x05:躺着; 0x06:打字; 0x10: 步行;0x11:跑步;0x12:骑行;0x13:跳绳;0x14:哑铃; 0x15:篮球运动; 0x16:羽毛球运动;0x17:跑步机运动;0x18:仰卧起坐运动;0x19:俯卧撑运动;
let dataList:[UInt8: [(String,[Int])]] = [
    //秤重
    UInt8("02", radix: 16)!:[
        ("体重", [3, 4]),
        ("体脂量", [5, 6])
    ],
    //静坐
    UInt8("03", radix: 16)!:[
    ],
    //站立
    UInt8("04", radix: 16)!:[
    ],
    //躺
    UInt8("05", radix: 16)!:[
    ],
    //打字
    UInt8("06", radix: 16)!:[
    ],
    //步行
    UInt8("10", radix: 16)!:[
        ("步数", [4, 5]),
        ("卡路里", [6, 7]),
        ("距离", [8, 9]),
        ("活动时长", [10, 11]),
        ("步速", [12, 13]),
        ("速度", [14, 15]),
        ("心率", [16])
    ],
    //跑步
    UInt8("11", radix: 16)!: [
        ("步数", [4, 5]),
        ("卡路里", [6, 7]),
        ("距离", [8, 9]),
        ("活动时长", [10, 11]),
        ("步速", [12, 13]),
        ("速度", [14, 15]),
        ("心率", [16])
    ],
    //骑行
    UInt8("12", radix: 16)!:[
        ("踏频速度", [4, 5]),
        ("卡路里", [6, 7]),
        ("距离", [8, 9]),
        ("活动时长", [10, 11]),
        ("速度", [12, 13]),
        ("心率", [14])
    ],
    //跳绳
    UInt8("13", radix: 16)!:[
        ("次数", [4, 5]),
        ("卡路里", [6, 7]),
        ("活动时长", [8, 9]),
        ("频率", [10, 11]),
        ("心率", [12])
    ],
    //哑铃
    UInt8("14", radix: 16)!:[
        ("次数", [4, 5]),
        ("卡路里", [6, 7]),
        ("活动时长", [8, 9]),
        ("心率", [10])
    ],
    //篮球
    UInt8("15", radix: 16)!:[
        ("投篮次数", [3, 4]),
        ("命中次数", [5, 6]),
        ("运球次数", [7, 8]),
        ("卡路里", [9, 10]),
        ("活动时长", [11, 12]),
        ("心率", [13])
    ],
    //羽毛球
    UInt8("16", radix: 16)!:[
        ("接球次数", [4, 5]),
        ("发球次数", [6, 7]),
        ("扣球次数", [8, 9]),
        ("卡路里", [10, 11]),
        ("活动时长", [12, 13]),
        ("心率", [14])
    ],
    //跑步机
    UInt8("17", radix: 16)!:[
        ("步数", [4, 5]),
        ("卡路里", [6, 7]),
        ("距离", [8, 9]),
        ("活动时长", [10, 11]),
        ("步速", [12, 13]),
        ("速度", [14, 15]),
        ("心率", [16])
    ],
    //仰卧起坐
    UInt8("18", radix: 16)!:[
        ("次数", [4, 5]),
        ("卡路里", [6, 7]),
        ("活动时长", [8, 9]),
        ("心率", [10])
    ],
    //俯卧撑
    UInt8("19", radix: 16)!:[
        ("次数", [4, 5]),
        ("卡路里", [6, 7]),
        ("活动时长", [8, 9]),
        ("心率", [10])
    ]
]

//MARK:动画数据
let keyList:[UInt8: (duration:Double, points:[[CGPoint]])] = [
    //秤重
    UInt8("02", radix: 16)!:(
        duration:0.5,
        points:[
            [
                point(x: 1054, y: 219),
                point(x: 1054, y: 219),
                point(x: 1054, y: 219)
            ],
            [
                point(x: 457, y: 487),
                point(x: 457, y: 487),
                point(x: 457, y: 487)
            ]
    ]),
    //静坐
    UInt8("03", radix: 16)!:(duration:0, points:[
        ]),
    //站立
    UInt8("04", radix: 16)!:(duration:0, points:[
        ]),
    //躺
    UInt8("05", radix: 16)!:(duration:0, points:[
        ]),
    //打字
    UInt8("06", radix: 16)!:(duration:0, points:[
        ]),
    //步行
    UInt8("10", radix: 16)!:(
        duration:1.1,
        points:
        [
            [
                point(x: 366, y: 212),
                point(x: 366, y: 220),
                point(x: 366, y: 212),
                point(x: 366, y: 220),
                point(x: 366, y: 212)
            ],
            [
                point(x: 271, y: 354),
                point(x: 271, y: 362),
                point(x: 271, y: 354),
                point(x: 271, y: 362),
                point(x: 271, y: 354)
            ],
            [
                point(x: 300, y: 499),
                point(x: 300, y: 507),
                point(x: 300, y: 499),
                point(x: 300, y: 507),
                point(x: 300, y: 499)
            ],
            [
                point(x: 341, y: 641),
                point(x: 341, y: 649),
                point(x: 341, y: 641),
                point(x: 341, y: 649),
                point(x: 341, y: 641)
            ],
            [
                point(x: 965, y: 120),
                point(x: 965, y: 128),
                point(x: 965, y: 120),
                point(x: 965, y: 128),
                point(x: 965, y: 120)
            ],
            [
                point(x: 1101, y: 265),
                point(x: 1101, y: 273),
                point(x: 1101, y: 265),
                point(x: 1101, y: 273),
                point(x: 1101, y: 265)
            ],
            [
                point(x: 1029, y: 420),
                point(x: 1029, y: 428),
                point(x: 1029, y: 420),
                point(x: 1029, y: 428),
                point(x: 1029, y: 420)
            ]
        ]),
    //跑步
    UInt8("11", radix: 16)!:(
        duration:1.1,
        points:[
            [
                point(x: 326, y: 179),
                point(x: 316, y: 169),
                point(x: 326, y: 179)
            ],
            [
                point(x: 205, y: 321),
                point(x: 195, y: 311),
                point(x: 205, y: 321)
            ],
            [
                point(x: 257, y: 455),
                point(x: 247, y: 455),
                point(x: 257, y: 455)
            ],
            [
                point(x: 280, y: 598),
                point(x: 270, y: 588),
                point(x: 280, y: 598)
            ],
            [
                point(x: 1003, y: 221),
                point(x: 993, y: 211),
                point(x: 1003, y: 221)
            ],
            [
                point(x: 1118, y: 406),
                point(x: 1108, y: 396),
                point(x: 1118, y: 406)
            ],
            [
                point(x: 1003, y: 598),
                point(x: 993, y: 588),
                point(x: 1003, y: 598)
            ]
        ]),
    //骑行
    UInt8("12", radix: 16)!:(
        duration:2,
        points:[
            [
                point(x: 305, y: 159),
                point(x: 295, y: 149),
                point(x: 305, y: 159)
            ],
            [
                point(x: 173, y: 371),
                point(x: 163, y: 361),
                point(x: 173, y: 371)
            ],
            [
                point(x: 234, y: 476),
                point(x: 224, y: 466),
                point(x: 234, y: 476)
            ],
            [
                point(x: 261, y: 626),
                point(x: 251, y: 616),
                point(x: 261, y: 626)
            ],
            [
                point(x: 1050, y: 205),
                point(x: 950, y: 195),
                point(x: 1050, y: 205)
            ],
            [
                point(x: 1161, y: 391),
                point(x: 1151, y: 381),
                point(x: 1161, y: 391)
            ],
            [
                point(x: 1100, y: 576),
                point(x: 1090, y: 566),
                point(x: 1100, y: 576)
            ]
        ]),
    //跳绳
    UInt8("13", radix: 16)!:(
        duration:0.9,
        points:[
            [
                point(x: 300, y: 144),
                point(x: 300, y: 134),
                point(x: 300, y: 144)
            ],
            [
                point(x: 179, y: 293),
                point(x: 179, y: 283),
                point(x: 179, y: 293)
            ],
            [
                point(x: 264, y: 453),
                point(x: 264, y: 443),
                point(x: 264, y: 453)
            ],
            [
                point(x: 390, y: 607),
                point(x: 390, y: 597),
                point(x: 390, y: 607)
            ],
            [
                point(x: 1005, y: 219),
                point(x: 1005, y: 209),
                point(x: 1005, y: 219)
            ],
            [
                point(x: 1109, y: 308),
                point(x: 1109, y: 298),
                point(x: 1109, y: 308)
            ],
            [
                point(x: 1045, y: 578),
                point(x: 1045, y: 568),
                point(x: 1045, y: 578)
            ]
        ]),
    //哑铃
    UInt8("14", radix: 16)!:(
        duration:1,
        points:[
            [
                point(x: 292, y: 154),
                point(x: 282, y: 144),
                point(x: 292, y: 154)
            ],
            [
                point(x: 208, y: 308),
                point(x: 198, y: 298),
                point(x: 208, y: 308)
            ],
            [
                point(x: 292, y: 470),
                point(x: 282, y: 460),
                point(x: 292, y: 470)
            ],
            [
                point(x: 358, y: 633),
                point(x: 348, y: 623),
                point(x: 358, y: 633)
            ],
            [
                point(x: 1112, y: 308),
                point(x: 1122, y: 298),
                point(x: 1112, y: 308)
            ],
            [
                point(x: 1112, y: 470),
                point(x: 1122, y: 460),
                point(x: 1112, y: 470)
            ],
            [
                point(x: 1007, y: 611),
                point(x: 1017, y: 601),
                point(x: 1007, y: 611)
            ]
        ]),
    //篮球
    UInt8("15", radix: 16)!:(
        duration:0.8,
        points:[
            [
                point(x: 577, y: 170),
                point(x: 577, y: 180),
                point(x: 577, y: 170)
            ],
            [
                point(x: 384, y: 299),
                point(x: 384, y: 309),
                point(x: 384, y: 299)
            ],
            [
                point(x: 277, y: 403),
                point(x: 277, y: 413),
                point(x: 277, y: 403)
            ],
            [
                point(x: 368, y: 522),
                point(x: 368, y: 532),
                point(x: 368, y: 522)
            ],
            [
                point(x: 517, y: 642),
                point(x: 517, y: 652),
                point(x: 517, y: 642)
            ],
            [
                point(x: 1148, y: 289),
                point(x: 1148, y: 299),
                point(x: 1148, y: 289)
            ],
            [
                point(x: 1148, y: 453),
                point(x: 1148, y: 463),
                point(x: 1148, y: 453)
            ]
        ]),
    //羽毛球
    UInt8("16", radix: 16)!:(
        duration:1,
        points:[
            [
                point(x: 389, y: 105),
                point(x: 374, y: 110),
                point(x: 389, y: 105)
            ],
            [
                point(x: 215, y: 270),
                point(x: 200, y: 275),
                point(x: 215, y: 270)
            ],
            [
                point(x: 273, y: 436),
                point(x: 258, y: 441),
                point(x: 273, y: 436)
            ],
            [
                point(x: 239, y: 629),
                point(x: 224, y: 634),
                point(x: 239, y: 629)
            ],
            [
                point(x: 1003, y: 598),
                point(x: 988, y: 603),
                point(x: 1003, y: 598)
            ],
            [
                point(x: 1134, y: 425),
                point(x: 1119, y: 430),
                point(x: 1134, y: 425)
            ],
            [
                point(x: 1067, y: 240),
                point(x: 1052, y: 245),
                point(x: 1067, y: 240)
            ]
        ]),
    //跑步机
    UInt8("17", radix: 16)!:(
        duration:1,
        points:[
            [
                point(x: 326, y: 179),
                point(x: 316, y: 169),
                point(x: 326, y: 179)
            ],
            [
                point(x: 205, y: 321),
                point(x: 195, y: 311),
                point(x: 205, y: 321)
            ],
            [
                point(x: 257, y: 455),
                point(x: 247, y: 455),
                point(x: 257, y: 455)
            ],
            [
                point(x: 280, y: 598),
                point(x: 270, y: 588),
                point(x: 280, y: 598)
            ],
            [
                point(x: 1003, y: 221),
                point(x: 993, y: 211),
                point(x: 1003, y: 221)
            ],
            [
                point(x: 1118, y: 406),
                point(x: 1108, y: 396),
                point(x: 1118, y: 406)
            ],
            [
                point(x: 1003, y: 598),
                point(x: 993, y: 588),
                point(x: 1003, y: 598)
            ]
        ]),
    //仰卧起坐
    UInt8("18", radix: 16)!:(
        duration:2,
        points:[
            [
                point(x: 698, y: 127),
                point(x: 688, y: 117),
                point(x: 698, y: 127)
            ],
            [
                point(x: 377, y: 254),
                point(x: 367, y: 244),
                point(x: 377, y: 254)
            ],
            [
                point(x: 267, y: 421),
                point(x: 257, y: 411),
                point(x: 267, y: 421)
            ],
            [
                point(x: 332, y: 676),
                point(x: 322, y: 666),
                point(x: 332, y: 676)
            ],
            [
                point(x: 1058, y: 676),
                point(x: 1048, y: 666),
                point(x: 1058, y: 676)
            ],
            [
                point(x: 1158, y: 421),
                point(x: 1148, y: 411),
                point(x: 1158, y: 421)
            ],
            [
                point(x: 999, y: 254),
                point(x: 989, y: 244),
                point(x: 999, y: 254)
            ]
        ]),
    //俯卧撑
    UInt8("19", radix: 16)!:(
        duration:2,
        points:[
            [
                point(x: 360, y: 131),
                point(x: 360, y: 141),
                point(x: 360, y: 131)
            ],
            [
                point(x: 210, y: 294),
                point(x: 210, y: 304),
                point(x: 210, y: 294)
            ],
            [
                point(x: 325, y: 603),
                point(x: 325, y: 613),
                point(x: 325, y: 603)
            ],
            [
                point(x: 764, y: 634),
                point(x: 764, y: 644),
                point(x: 764, y: 634)
            ],
            [
                point(x: 1135, y: 518),
                point(x: 1135, y: 528),
                point(x: 1135, y: 518)
            ],
            [
                point(x: 1135, y: 158),
                point(x: 1135, y: 168),
                point(x: 1135, y: 158)
            ],
            [
                point(x: 736, y: 208),
                point(x: 736, y: 218),
                point(x: 736, y: 208)
            ]
        ])
]

private func point(x: CGFloat, y: CGFloat) -> CGPoint{
    return CGPoint(x: x * viewSize.height / 1334, y: y * viewSize.width / 750)
}
