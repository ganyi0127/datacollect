//
//  SettingViewController.swift
//  DataCollect
//
//  Created by ganyi on 16/8/5.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class SettingViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var rssiTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let name = User.shareInstance().settingName{
            nameTextField.text = name
        }
        
        if let rssi = User.shareInstance().settingRSSI{
            rssiTextField.text = "\(rssi)"
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let name = nameTextField.text{
            if name == ""{
                User.shareInstance().updateSettingName(nil)
            }else{
                User.shareInstance().updateSettingName(name)
            }
        }else{
            User.shareInstance().updateSettingName(nil)
        }
        
        if let rssi = rssiTextField.text{
            if let integer = Int32(rssi){
                let uRssi = abs(integer)
                let number = NSNumber(value: uRssi as Int32)
                
                User.shareInstance().updateSettingRSSI(number)
            }
        }else{
            User.shareInstance().updateSettingRSSI(nil)
        }
    }
}

extension SettingViewController:UITextFieldDelegate{
    
    @IBAction func editChanged(_ sender: UITextField) {
        
        guard let text = sender.text else{
            return
        }
        
        var localRange:Int?
        if sender == nameTextField{
            localRange = 10
        }else{
            localRange = 2
        }
        
        if text.lengthOfBytes(using: String.Encoding.utf8) > localRange!{
            
            while sender.text?.lengthOfBytes(using: String.Encoding.utf8) > localRange!{
                let range = Range(sender.text!.startIndex..<sender.text!.characters.index(sender.text!.endIndex, offsetBy: -1))
                sender.text = sender.text?.substring(with: range)
            }
        }
    }
}
