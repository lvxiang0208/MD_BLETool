//
//  MD_BLEConnectManager.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/14.
//

import UIKit
import CoreBluetooth

class MD_BLEConnectManager: NSObject {
    
    //一代设备名称 "Medlander","MLD-V2"
    @objc var lt_1G_BLENames = [String]()
    // 澜渟2G "MD-01","MD-01","MD-A1","MD-A2","MD-A3","MD-A4","MD-A5","MD-B1","MD-B2","MD-B3","MD-B4","MD-PL10","MD-PL20","MD-PL21","MD-PL22","MD-PL36","MD-PM60","MD-PM70","MD-PQ80","MD-PQ88"
    @objc var lt_2G_BLENames = [String]()
    //"MD2-"
    @objc var lt_NewerBLENames = [String]()
    //dfu升级失败后 蓝牙名称
    @objc var lt_DFUBLENames = ["MD2-HA-Boot","Dfu"]
    @objc var lt_deviceConfig = [Dictionary<String, String>]();
    
    let kCollectionTimerName = "kCollectionTimerName"
    let kCollectionTimeInterval = 0.03125
    var timer : DispatchSourceTimer?
    
    @objc var isPoweredOn = false
    
    //dfu 升级蓝牙会断开并迅速重连,dfu升级蓝牙第一次断开不处理
    @objc var isDFUUpgrade = false
    
    @objc var isConnected:Bool {
        get {
            if connectedBLEModels.count > 0 && MD_BLEConnectManager.shared.getConnected_Device()?.isReady == true {
                return true
            }
            return false
        }
    }
    
    @objc var isLanting1G:Bool {
        get {
            if self.ltGen == .lt_1G {
                return true
            }
            return false
        }
    }
    
    @objc var isLanting2G:Bool {
        get {
            if self.ltGen == .lt_2G || (self.ltGen == .lt_other && self.getConnected_Device()?.is2GUp ?? false) {
                return true
            }
            return false
        }
    }
    
    @objc var isLanting3G:Bool {
        get {
            if self.ltGen == .lt_other && !(self.getConnected_Device()?.is2GUp ?? false) {
                return true
            }
            return false
        }
    }
    
    @objc var isShowScore:Bool {
        get {
            return self.getConnected_Device()?.isShowScore ?? false
        }
    }
    
    @objc var ltGen : MD_DeviceType {
        get {
            return connectedBLEModels.last?.deviceType ?? .none
        }
    }
    
    //是否是三代高端
    @objc var isLT3GenHigh : Bool {
        get {
            return self.getConnected_Device()?.isHighEnd ?? false
        }
    }
    
    /** 是否包含私密检测功能 */
    @objc var isPrivacy : Bool {
        get {
            //盆瑜伽（全 高 低）
            let isFull = self.getConnected_Device()?.support_function.contains(COMPACT_DETECTION as NSString) ?? false
            let isHigh =  self.getConnected_Device()?.support_function.contains(COMPACT_DETECTION_HIGH as NSString) ?? false
            let isLow = self.getConnected_Device()?.support_function.contains(COMPACT_DETECTION_LOW as NSString) ?? false
            return (isFull || isHigh || isLow)
        }
    }
    
    /** 是否包含私密检测功能 */
    @objc var isPrivacyWithoutLow : Bool {
        get {
            //盆瑜伽（全 高）
            let isFull = self.getConnected_Device()?.support_function.contains(COMPACT_DETECTION as NSString) ?? false
            let isHigh =  self.getConnected_Device()?.support_function.contains(COMPACT_DETECTION_HIGH as NSString) ?? false
            return (isFull || isHigh)
        }
    }
    
    /** 是否包含私密检测全功能 */
    @objc var isPrivacyFull : Bool {
        get {
            //盆瑜伽（全）
            let isFull = self.getConnected_Device()?.support_function.contains(COMPACT_DETECTION as NSString) ?? false
            return isFull
        }
    }
    
    /** 是否包含私密检测高功能 */
    @objc var isPrivacyHigh : Bool {
        get {
            //盆瑜伽（高）
            let isHigh =  self.getConnected_Device()?.support_function.contains(COMPACT_DETECTION_HIGH as NSString) ?? false
            return isHigh
        }
    }
    
    /** 是否包含私密检测低功能 */
    @objc var isPrivacyLow : Bool {
        get {
            //盆瑜伽（低）
            let isLow = self.getConnected_Device()?.support_function.contains(COMPACT_DETECTION_LOW as NSString) ?? false
            return isLow
        }
    }
    
    /** 是否包含自由训练的功能 */
    @objc var isSupportFree : Bool {
        get {
            let supportFuncs = self.getConnected_Device()?.support_function ?? []
            if (supportFuncs.contains(FREE_KEGEL_MEDIA as NSString) ||
                supportFuncs.contains(FREE_KEGEL_TRAIN as NSString) ||
                supportFuncs.contains(FREE_BREATHE_TRAIN as NSString) ||
                supportFuncs.contains(FREE_STRETCH_TRAIN as NSString)) {
                return true
            }
            return false
        }
    }
    
    
    /** 是否包含评估功能 */
    @objc var isAssess : Bool {
        get {
            //评估定制方案·肌电
            //盆底评估·压力
            //盆底筛查·肌电
            let supportFuncs = self.getConnected_Device()?.support_function ?? []
            if (supportFuncs.contains(ASSESS_ELECTRIC_MODE as NSString) ||
                supportFuncs.contains(ASSESS_PRESSURE_MODE as NSString) ||
                supportFuncs.contains(SCREEN_ELECTRIC_MODE as NSString)) {
                return true
            }
            return false
        }
    }
    
    //是否支持变频
    @objc var isSupportFrequencyConversion : Bool {
        get {
            //评估定制方案·肌电
            //盆底评估·压力
            //盆底筛查·肌电
            let supportFuncs = self.getConnected_Device()?.support_function ?? []
            if (supportFuncs.contains(SUPPORT_ABDOMINAL_BPDL as NSString)) {
                return true
            }
            return false
        }
    }
    
    /// 是否是手动断开
    @objc var manualDisconnected = false
    
    /// 中心外设，用于连接BLE设备
    private var centralManager: CBCentralManager?
    
    /// 初始化 中心外设
    func initCentralManager() {
        self.centralManager = CBCentralManager.init(delegate: self, queue: nil)
    }
    
    /// 扫描到的设备的集合
    var disCoveredPeripherals:[CBPeripheral] = [CBPeripheral]()
    
    /// 增加外设到搜索到的外设数组中
    /// - Parameter peripheral: 搜索到的外设
    func addPeripheralToScanedPeripherals(peripheral: CBPeripheral) {
        if !disCoveredPeripherals.contains(peripheral) {
            disCoveredPeripherals.append(peripheral)
        }
    }
    
    /// 已连接的设备数组
   var connectedBLEModels:[MD_BLEModel] = [MD_BLEModel]()
    
    /// 等待重连的设备数组
    var reconnectedBLEModels:[MD_BLEModel] = [MD_BLEModel]()
    
    var connectModel = MD_BLEModel()
    
    /// 增加外设到已连接的外设数组中
    /// - Parameter peripheral: 已连接的外设
    func addPeripheralToConnectedBLEModels(peripheral: CBPeripheral) {
        let isExist: Bool = connectedBLEModels.contains { (model) -> Bool in
            return model.peripheral == peripheral
        }
        if !isExist {
            let deviceType = MD_BLEDeviceDealTool.getDeviceTypeByPeripheral(peripheral: peripheral)
            self.connectModel.deviceType = deviceType
            self.connectModel.peripheral = peripheral
            self.connectModel.initDataHandle()
            peripheral.delegate = self.connectModel
            connectedBLEModels.append(self.connectModel)
        }
    }
    
    /// 保证sharedInstance是一个常量，在创建之后不会被更改 (单例 支持懒加载, 线程安全)
    @objc static let shared = MD_BLEConnectManager()

    /// 保证init方法在外部不会被调用
    private override init() {
        super.init()
        self.initCentralManager()
        
    }
    
    @objc func isSameAsLastBle() -> Bool {
        let currentModel = self.getConnected_Device()
        let lastModel = self.reconnectedBLEModels.last
        if currentModel?.peripheral?.identifier.uuidString == lastModel?.peripheral?.identifier.uuidString {
            return true
        }
        return false;
    }
    
    //开始采集定时器
    @objc func collectionTimerStart() {
        
        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        timer?.schedule(deadline: .now(), repeating: kCollectionTimeInterval)
        timer?.setEventHandler {
            DispatchQueue.main.async {
                MD_DispatcherCenter.shared.dispatchCollectionTimerUpdate()
            }
        }
        timer?.resume()
    }
    
    //取消采集定时器
    @objc func collectionTimerCancel() {
        timer?.cancel()
        timer = nil
    }
    
    /// 扫描设备
    @objc func scanDevices() {
        // CBCentralManagerScanOptionAllowDuplicatesKey true表示会重复扫描已经发现的设备，可用于实时更新信号强度RSSI，没有这方面需求设为false
        self.disCoveredPeripherals.removeAll()
        if self.isPoweredOn {
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
        }
        else {
            self.perform(#selector(scanDevices), with: nil, afterDelay: 0.5)
        }
        
    }
    
    /// 停止扫描设备
    @objc func stopScanDevices() {
        centralManager?.stopScan()
    }
    
    /// 连接设备
    /// - Parameter peripheral: peripheral
    @objc func connectPeripheral(_ peripheral: CBPeripheral?,model:MD_BLEModel) {
        if peripheral == nil {
            return
        }
        self.connectModel = model
        self.centralManager?.connect(peripheral!, options: nil)
    }
    
    /// 取消连接外设
    /// - Parameter peripheral: 外设
    @objc func cancelConnectPeripheral(peripheral: CBPeripheral?) {
        if peripheral == nil {
            return
        }
        for model in connectedBLEModels {
            if model.peripheral == peripheral {
                model.heartBeat.heartBeatOver()
                model.cancelReadEEPROM()
                model.isReady = false
            }
        }
        centralManager?.cancelPeripheralConnection(peripheral!)
        connectedBLEModels.removeAll()
    }
    
    /// 取消所有连接外设
    /// - Parameter peripheral: 外设
    @objc func cancelConnectDFUPeripheral() {
        if let per = self.connectModel.peripheral {
            centralManager?.cancelPeripheralConnection(per)
        }
        connectedBLEModels.removeAll()
    }
        
    /// 取消所有连接外设
    /// - Parameter peripheral: 外设
    @objc func cancelAllConnectPeripheral() {
        for model in connectedBLEModels {
            model.heartBeat.heartBeatOver()
            model.cancelReadEEPROM()
            model.isReady = false
            centralManager?.cancelPeripheralConnection(model.peripheral!)
        }
        connectedBLEModels.removeAll()
    }
    
    //重连操作
    @objc func reconectAction() {
        if let perpheral = self.reconnectedBLEModels.last?.peripheral {
            self.connectPeripheral(perpheral, model: self.reconnectedBLEModels.last ?? MD_BLEModel())
        }
    }
    
    //取消重连操作
    @objc func cancelReconectAction() {
        if let perpheral = self.reconnectedBLEModels.last?.peripheral {
            self.cancelConnectPeripheral(peripheral: perpheral)
        }
        self.cancelAllConnectPeripheral()
    }
    
    @objc func getConnectedModel(peripheral: CBPeripheral) -> MD_BLEModel {
        for device in connectedBLEModels {
            if device.peripheral == peripheral {
                return device
            }
        }
        return MD_BLEModel()
    }
    
    @objc func getReConnected_Device() -> MD_BLEModel? {
        return reconnectedBLEModels.last;
    }
    
    @objc func getConnected_Device() -> MD_BLEModel? {
        return connectedBLEModels.last;
    }
    
    @objc func writeValue(_ data: Data) {
        self.getConnected_Device()?.writeValueToDevice(data: data)
    }
    
}


extension MD_BLEConnectManager:CBCentralManagerDelegate {
    
    /// 蓝牙状态变更回调
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.isPoweredOn = true
            break
        case .poweredOff:
            self.isPoweredOn = false
            break
        default:
            break
        }
        if #available(iOS 10.0, *) {
            MD_DispatcherCenter.shared.dispatchBLEDidUpdateState(state: central.state)
        } else {
        }
    }
    
    /// 发现设备
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name?.count ?? 0 > 0 {
            var peripheralName: String = peripheral.name ?? ""
            peripheralName = peripheralName.trimmingCharacters(in: .whitespacesAndNewlines)
            var localName: String = advertisementData["kCBAdvDataLocalName"] as? String ?? ":"
            localName = localName.trimmingCharacters(in: .whitespacesAndNewlines)
            print("perName = %@",peripheral.name ?? "");
            if MD_BLEDeviceDealTool.isValidPeripheralName(name: peripheralName) ||
                MD_BLEDeviceDealTool.isValidPeripheralName(name: localName) {
                self.dealSerialNumWithBLE(peripheral: peripheral, peripheralName: peripheralName, name: localName)
    
                addPeripheralToScanedPeripherals(peripheral: peripheral)
                MD_DispatcherCenter.shared.dispatchBLEConnectManagerDiscoveredPeripherals(disCoveredPeripherals: disCoveredPeripherals)
            }
        }
    }
    
    func isDfuDevices(perName:String) -> Bool {
        for constantName in MD_BLEConnectManager.shared.lt_DFUBLENames {
            if perName.hasPrefix(constantName) {
                return true
            }
        }
        return false
    }
    
    /// 连接设备
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("连接成功")
        stopScanDevices()
        addPeripheralToConnectedBLEModels(peripheral: peripheral)
        
        var peripheralName: String = peripheral.name ?? ""
        peripheralName = peripheralName.trimmingCharacters(in: .whitespacesAndNewlines)
        if isDfuDevices(perName: peripheralName) {
            MD_DispatcherCenter.shared.dispatchPeripheralUpgradeDFU(peripheral: peripheral)
        } else {
            peripheral.discoverServices(nil)
        }
    }
    /// 连接失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.cancelAllConnectPeripheral()
        MD_DispatcherCenter.shared.dispatchBLEConnectManagerDidFailToConnect(peripheral: peripheral, error: error)
        print("连接失败")
    }
    
    /// 断开连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if MD_BLEConnectManager.shared.getConnected_Device() != nil {
            MD_BLEConnectManager.shared.getConnected_Device()?.heartBeat.heartBeatOver()
            self.reconnectedBLEModels.append(MD_BLEConnectManager.shared.getConnected_Device() ?? MD_BLEModel())
        }
        
        self.cancelAllConnectPeripheral()
        MD_DispatcherCenter.shared.dispatchBLEConnectManagerDidDisconnectPeripheral(peripheral: peripheral, error: error)
        print("连接断开")
    }
    
    
    func dealSerialNumWithBLE(peripheral : CBPeripheral,peripheralName:String,name:String) {
        var bleName = ""
        var isSerialName = false
        for constantName in self.lt_2G_BLENames {
            if name.hasPrefix(constantName) {
                bleName = name
                isSerialName = true
                break
            }
            if peripheralName.hasPrefix(constantName) {
                bleName = peripheralName
                isSerialName = true
                break
            }
        }
        for constantName in self.lt_NewerBLENames {
            if name.hasPrefix(constantName) {
                let bleNames = name.components(separatedBy: "-")
                bleName = bleNames.last ?? ""
                isSerialName = true
                break
            }
            if peripheralName.hasPrefix(constantName) {
                let bleNames = name.components(separatedBy: "-")
                bleName = bleNames.last ?? ""
                isSerialName = true
                break
            }
        }
        if isSerialName {
            if bleName.count < 2 {
                return;
            }
            let pName = NSString.init(string: bleName)
            let modelName = pName.substring(to: 2)
            let productSerialNumber = pName.substring(from: 2)
            let uuidStr = peripheral.identifier.uuidString
            let modelNum = UInt(modelName,radix: 16) ?? 0
            let modelType = MD_BLEDeviceDealTool.getDisplayName(model: modelName)
            
            if productSerialNumber.count == 0 || modelType == "无" || modelType == "未知" {
                return
            }
            let strSerialNumberShow_ = String(format: "%@-%@", modelType,pName)
            let cache = YYCache.init(name: kDeviceSerialNumberCache)
            let localDict = cache?.object(forKey: kDeviceSerialNumberKey) as? NSDictionary
            let saveDic = localDict?.mutableCopy() as? NSMutableDictionary ?? NSMutableDictionary()
            let allValues = localDict?.allValues as NSArray?
            if allValues?.contains(productSerialNumber ) == false || allValues == nil {
                saveDic.setValue(strSerialNumberShow_, forKey: uuidStr)
                cache?.setObject(saveDic, forKey: kDeviceSerialNumberKey)
            }
            
        }
    }
}

extension CBPeripheral : Identifiable {
    
    func getPeripheralName() -> String {
        return name ?? ""
    }
    
}
