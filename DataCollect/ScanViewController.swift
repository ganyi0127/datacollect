//
//  ScanViewController.swift
//  DataCollect
//
//  Created by ganyi on 16/8/4.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit
import CoreBluetooth
import QuickLook
class ScanViewController: UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bindingButton: UIButton!
    @IBOutlet weak var rescanButton: UIButton!
    
    fileprivate var rescanButtonFrame:CGRect?
    
    //loading
    fileprivate let loading = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    //中心管理者
    fileprivate var centralManager:CBCentralManager?
    
    //服务
    var service:CBService!{
        let serviceUUID = kServiceUUID
        return CBMutableService(type: serviceUUID, primary: true)
    }
    
    //外设容器
    fileprivate var peripheralList = [(isa:CBPeripheral,RSSI:NSNumber)](){
        didSet{
            mainThread(){
                self.tableView.reloadData()
            }
        }
    }
    
    //存储文件名
    fileprivate var fileList:[String]?
    fileprivate var curFileIndex:Int?
    
    //MARK: init------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        navigationController?.navigationBar.addSubview(loading)
        let navFrame = navigationController?.navigationBar.frame
        loading.frame.origin = CGPoint(x: navFrame!.width / 2 - loading.frame.width / 2, y: navFrame!.height / 2 - loading.frame.height / 2)
        loading.hidesWhenStopped = true
        loading.stopAnimating()

        //注册蓝牙中心
        let queue:DispatchQueue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high)
        centralManager = CBCentralManager(delegate: self, queue: queue)
        
    }
    
    override func viewDidLayoutSubviews() {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        rescanButtonFrame = rescanButton.frame
        
        peripheralList.removeAll()
        config()
        
        UIView.animate(withDuration: 0.3, animations: {
            
//            self.rescanButton.frame = self.rescanButtonFrame!
            
            }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    fileprivate func config(){
        
        NotificationCenter.default.addObserver(self, selector: #selector(ScanViewController.becomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        bindingButton.isHidden = true
        
        rescanButton.frame = CGRect(x: rescanButton.frame.origin.x, y: viewSize.height / 3, width: rescanButton.frame.width, height: rescanButton.frame.height * 1.5)
        
        //判断绑定的话便自动连接
        if let uuid = User.shareInstance().bandingUUID {
            if let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [uuid as UUID]){
               
                for peripheral in peripherals {
                    
                    selectPeripheral = peripheral

                    peripheralList.append((isa:peripheral,RSSI: NSNumber(value: 0 as Float)))
                    
//                    centralManager?.connectPeripheral(peripheral, options: nil)
                }
            }
        }
    }
    
    //MARK:返回前台时调用，返回第一个页面
    func becomeActive(){
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func click(_ sender: UIButton) {
        // 0:绑定 1:扫描／重新扫描
        switch sender.tag {
        case 0:
            
            guard let p = selectPeripheral else{
                return
            }
            
            p.write(withActionType: .binding)
            
        default:
            
            bindingButton.isHidden = true
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.rescanButton.frame = self.rescanButtonFrame!
                
                }, completion: nil)
            
            //初始化
            peripheralList.removeAll()
            
            guard let cm = centralManager else{
                return
            }
            
            if cm.isScanning{
                
                stopSearch()
                
            }else{
                
                loading.startAnimating()
                
                //判断绑定的话便添加到列表
                if let uuid = User.shareInstance().bandingUUID {
                    let peripherals = cm.retrievePeripherals(withIdentifiers: [uuid as UUID])
                    for peripheral in peripherals {
                        
                        //断开之前已绑定的连接
                        cm.cancelPeripheralConnection(peripheral)
                        
                        //添加已绑定的设备到列表
//                        peripheralList.append((isa:peripheral, RSSI:NSNumber(float: 0)))
                    }
                }
                
                //判断已连接的话，添加到列表（与上文有重复）
                let peripherals = cm.retrieveConnectedPeripherals(withServices: [kServiceUUID])
                for peripheral in peripherals{
                    //判断UUID重复，避免重复存储
                    
                    cm.cancelPeripheralConnection(peripheral)
                    
                    peripheralList.append((isa:peripheral, RSSI:NSNumber(value: 0 as Float)))
                }
                
                //开始扫描设备
                cm.scanForPeripherals(withServices: [service.uuid], options: nil)
                
                //3秒后停止扫描
                delay(3){
                    self.loading.stopAnimating()
                    self.stopSearch()
                }
            }
        }
    }
    
    //MARK: 停止扫描
    fileprivate func stopSearch(){
        
        loading.stopAnimating()
        centralManager?.stopScan()
    }
    
    //MARK:载入展示页面
    fileprivate func performShowController(){
        
        mainThread(){
            
            var identiy = "animation"
            if project == 0{
                identiy = "graphic"
            }
            
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identiy)
            self.navigationController?.show(viewController, sender: nil)
        }
    }
    
    @IBAction func setting(_ sender: UIBarButtonItem) {
        
        let settingViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "setting")
        navigationController?.show(settingViewController, sender: nil)
    }
    
    fileprivate weak var curPreviewController:QLPreviewController?
    //MARK:数据文件分享与察看
    @IBAction func quickLook(_ sender: UIBarButtonItem) {
        
        let filemanager = FileManager.default
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)
        fileList = filemanager.subpaths(atPath: paths[0])!.filter(){$0.hasSuffix(".txt")}
        
        let previewController = QLPreviewController()
        previewController.delegate = self
        previewController.dataSource = self
        
        //添加新建文件按钮，删除按钮
        let newItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ScanViewController.createNewFile))
        let deleteItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(ScanViewController.deleteCurrentFile))
        
        previewController.navigationItem.rightBarButtonItems = [newItem, deleteItem]
        
        present(previewController, animated: true){
            self.curPreviewController = previewController
        }
    }
    
    //MARK: 固定文件，不再写入（新建）
    func createNewFile(){
        let newFilePath = newFile()
        fileList?.append(newFilePath)
        curPreviewController?.reloadData()
    }
    
    //MARK: 删除文件
    func deleteCurrentFile(){
        
        guard let fList = fileList else{
            return
        }
        
        guard let index = curPreviewController?.currentPreviewItemIndex , index >= 0 else{
            return
        }
     
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)
        let path = paths[0]
        
        let fileStr = "/" + fList[index]
        
        let deletePath = path + fileStr
        
        if deleteFile(filePath: deletePath){
            fileList?.remove(at: index)
            curPreviewController?.reloadData()
        }else{
            let alertController = UIAlertController(title: nil, message: "删除文件失败", preferredStyle: .alert)
            let action = UIAlertAction(title: "确定", style: .cancel, handler: nil)
            alertController.addAction(action)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    deinit{
        selectPeripheral?.delegate = nil
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
}

//MARK: tableView
extension ScanViewController: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return peripheralList.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identify = "cellfail"
      
        let peripheral = peripheralList[(indexPath as NSIndexPath).row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identify) ?? UITableViewCell(style: .value1, reuseIdentifier: identify)
        
        cell.textLabel?.text = peripheral.isa.name
        
        if let uuid = User.shareInstance().bandingUUID , uuid as UUID == peripheral.isa.identifier{
            cell.detailTextLabel?.text = "已绑定"
        }else{
            cell.detailTextLabel?.text = "\(peripheral.RSSI)"
        }
        
        //判断为已连接
        if let peripherals = centralManager?.retrieveConnectedPeripherals(withServices: [kServiceUUID]){
            
            let uuids = peripherals.map(){$0.identifier}
            
            if uuids.contains(peripheral.isa.identifier){
                
                cell.accessoryType = .checkmark

            }else{
                
                cell.accessoryType = .none
            }
        }else{
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        loading.startAnimating()
        bindingButton.isHidden = true
        
        selectPeripheral = peripheralList[(indexPath as NSIndexPath).row].isa
        centralManager?.connect(selectPeripheral!, options: nil)
        
    }
    
    //MARK: 解绑
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "解绑"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let p = selectPeripheral , p == peripheralList[(indexPath as NSIndexPath).row].isa else{
            return
        }

        guard let uuid = User.shareInstance().bandingUUID , p.identifier.uuidString == uuid.uuidString else{
            return
        }

        p.write(withActionType: .unbinding)
        
        User.shareInstance().update(nil, forKey: .BindingUUID)
        
        //顺便解除连接
        centralManager?.cancelPeripheralConnection(p)
        selectPeripheral = nil
        
        tableView.reloadData()
    }
}

//MARK:蓝牙delegate
extension ScanViewController:CBCentralManagerDelegate{
    
    //搜索到外设时调用
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("扫描到:\(peripheral) withData:\(advertisementData) withRSSI: \(RSSI)\n")
        //"kCBAdvDataLocalName"
        
        //判断UUID重复，避免重复存储
        let sameList = peripheralList.filter(){$0.isa.identifier.uuidString == peripheral.identifier.uuidString}
        guard sameList.isEmpty else{
            return
        }
        
        guard let peripheralName = peripheral.name else{
            return
        }
        
        print("\nsettingName: \(User.shareInstance().settingName)")
        //如果不包含指定名称，跳过
        if let searchName = User.shareInstance().settingName{
            
            if !peripheralName.contains(searchName){
                return
            }
        }
        
        //如果信号强度不匹配，跳过
        if let seachRSSI = User.shareInstance().settingRSSI{
            if seachRSSI.int32Value < abs(RSSI.int32Value){
                return
            }
        }
        
        peripheralList.append((isa:peripheral,RSSI:RSSI))
    }
    
    //连接外设成功时调用
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("连接到\(peripheral)成功\n")
        if let selPeripheral = selectPeripheral{
            
            selPeripheral.discoverServices([service!.uuid])
            selPeripheral.delegate = self
        }
        
        mainThread(){
            self.tableView.reloadData()
        }
    }
    
    //连接外设失败时调用
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接到\(peripheral)失败\n")
    }
    
    //断开外设时调用
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("断开与\(peripheral)的连接\n")
        
        mainThread(){
            
            //重连提示
            let name = peripheral.name ?? ""
            
            let alertController = UIAlertController(title: nil, message: "\(name)\n连接已断开", preferredStyle: .alert)
            let reconnectAction = UIAlertAction(title: "重新连接", style: .destructive){
                _ in
                //重连
                self.centralManager?.connect(peripheral, options: nil)
            }
            let backAction = UIAlertAction(title: "返回", style: .cancel){
                _ in
                
                //返回
                self.navigationController?.popToRootViewController(animated: true)
            }
            alertController.addAction(backAction)
            alertController.addAction(reconnectAction)
            self.present(alertController, animated: true, completion: nil)
            
            self.tableView.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("restoreState:\(dict)")
    }
    
    //检测蓝牙状态
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("中心管理状态:\(central.state.rawValue)")
        switch central.state {
        case .unknown:
            break
        case .resetting:
            break
        case .unsupported:
            break
        case .unauthorized:
            break
        case .poweredOff:
            break
        case .poweredOn:
            break
        }
    }
}

//MARK:外设delegate
extension ScanViewController{
    
    override func viewControllerPeripheralDidDiscoverServices() {
        
    }
    
    override func viewControllerPeripheral(didDiscoverCharacteristicsForService service: CBService?, peripheral: CBPeripheral, bindingBle bind: Bool) {
        
        loading.stopAnimating()
        
        mainThread(){
            
            if bind{
                
                guard let navigation = self.navigationController else{
                    return
                }
                
                guard let lastViewController = navigation.viewControllers.last else{
                    return
                }
                
                if lastViewController.isKind(of: ScanViewController.self){
                    
                    self.performShowController()
                }else{
                    
                    let alert = UIAlertController(title: nil, message: "连接成功", preferredStyle: .alert)
                    let action = UIAlertAction(title: "确定", style: .cancel, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true){
                        selectPeripheral?.delegate = lastViewController
                    }
                }
            }else{
                self.bindingButton.isHidden = false
                
            }
            
            self.tableView.reloadData()
        }
    }
    
    override func viewControllerPeripheral(didWriteValueForCharacteristic characteristic: CBCharacteristic) {
        
    }
    
    override func viewControllerPeripheral(didUpdateValueForCharacteristic characteristic: CBCharacteristic, data: Data) {
        
        tableView.reloadData()
    }
}

//MARK:数据文件快速查看delegate
extension ScanViewController:QLPreviewControllerDelegate,QLPreviewControllerDataSource{
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        
        guard let files = fileList else{
            return 0
        }
        
        return files.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)
        let path = paths[0]
        
        let fileStr = "/" + fileList![index]
        
        let filePath = path + fileStr
        
        return URL(fileURLWithPath: filePath) as QLPreviewItem
    }
    
}
