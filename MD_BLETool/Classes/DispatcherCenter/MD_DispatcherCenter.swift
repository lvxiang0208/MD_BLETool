//
//  MD_DispatcherCenter.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/14.
//

import UIKit
import CoreBluetooth

class MD_DispatcherCenter: NSObject {

    /// 保证sharedInstance是一个常量，在创建之后不会被更改 (单例 支持懒加载, 线程安全)
    @objc static let shared = MD_DispatcherCenter()
    
    /// 存放observer的集合
    let observerTargets:NSHashTable = NSHashTable<AnyObject>.weakObjects()
    
    /// 保证init方法在外部不会被调用
    private override init() {}
    
    /// 增加Observer
    /// - Parameter oberver: AnyObject
    @objc func addObserver(_ oberver:AnyObject) {
        if !observerTargets.contains(oberver) {
            observerTargets.add(oberver)
        }
    }
    
    /// 移除Observer
    /// - Parameter oberver: AnyObject
    @objc func removerObserver(_ oberver:AnyObject) {
        if observerTargets.contains(oberver) {
            observerTargets.remove(oberver)
        }
    }
    
    /// 判断是否是自己的observer
    /// - Parameter oberver: AnyObject
    /// - Returns: Bool
    @objc func isObserver(oberver:AnyObject) -> Bool{
        if observerTargets.contains(oberver) {
            return true
        }
        return false
    }
    
    /// 通知页面搜索到外设
    /// - Parameter disCoveredPeripherals: 通知页面搜索到外设
    func dispatchBLEConnectManagerDiscoveredPeripherals(disCoveredPeripherals: [CBPeripheral]){
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.bleConnectManagerDidDiscoverPeripherals?(disCoveredPeripherals: disCoveredPeripherals)
            }
        }
    }
    
    /// 通知页面连接外设成功,升级DFU
    /// - Parameter peripheral: peripheral
    func dispatchPeripheralUpgradeDFU(peripheral: CBPeripheral){
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.peripheralDidConnectUpgradeDFU?(peripheral: peripheral)
            }
        }
    }
    
    /// 通知页面连接外设成功
    /// - Parameter peripheral: peripheral
    func dispatchBLEConnectManagerDidConnect(peripheral: CBPeripheral){
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.bleConnectManagerDidConnect?(peripheral: peripheral)
            }
        }
    }
    
    
    
    /// 通知页面连接外设失败
    /// - Parameters:
    ///   - peripheral: peripheral
    ///   - error: error
    func dispatchBLEConnectManagerDidFailToConnect(peripheral: CBPeripheral, error: Error?){
        self.resetStatus(peripheral: peripheral)
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.bleConnectManagerDidFailToConnect?(peripheral: peripheral, error: error)
            }
        }
    }
    
    /// 通知页面与外设断开链接
    /// - Parameters:
    ///   - peripheral: peripheral
    ///   - error: error
    func dispatchBLEConnectManagerDidDisconnectPeripheral(peripheral: CBPeripheral, error: Error?){
        self.resetStatus(peripheral: peripheral)
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.bleConnectManagerDidDisconnectPeripheral?(peripheral: peripheral, error: error)
            }
        }
    }
    
    /// 通知页面收到蓝牙数据
    /// - Parameters:
    ///   - peripheral: peripheral
    ///   - error: error
    
    func dispatchBLEDidUpdateValue(peripheral: CBPeripheral, value:Data ,error: Error?){
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.LTBLEDidUpdateValue?(peripheral: peripheral, value: value, error: error)
            }
        }
    }
    
    func dispatchBLEWriteValue(value:Data) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.LTBLEWriteValue?(value: value)
            }
        }
    }
    
    func dispatchBleShakeSuccess(model: MD_BLEModel) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.dispatchLT3rdBleShakeSuccess?(model: model)
            }
        }
        model.bleShakeSuccess()
    }
    
    
    /// 连接时设备状态,isBoot = true
    ///训练中正在
    /// - Parameters:
    ///   - model: 设备模型
    ///   - isBoot: 设备刚刚通电
    func dispatchLT2rdBleShakeSuccess(model: MD_BLEModel, firmwareVersion: UInt8, bootVersion: UInt8) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleShakeSuccess?(model: model, firmwareVersion: firmwareVersion, bootVersion: bootVersion)
            }
        }
        model.bleShakeSuccess()
    }
    
    
    /// 澜渟1代 - 读取EEPROM
    func dispatchLT1rdBleReadEEPROM(device:MD_BLEModel ,deviceModel: UInt8, serialNumber:String, activationDate:String?) {
        device.cancelReadEEPROM()
       
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt1rdBleReadEEPROM?(deviceModel: deviceModel, serialNumber: serialNumber, activationDate: activationDate)
            }
        }
        self.dispatchLT1rdCheckDevice(model: device, deviceModel: deviceModel)
    }
    
    /// 一代检测是否可以连接
    /// - Parameters:
    ///   - model: 设备模型
    ///   - deviceModel: 1代设备型号
    func dispatchLT1rdCheckDevice(model:MD_BLEModel, deviceModel:UInt8){
        model.checkDeviceConnect()
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lT1rdCheckDevice?(model: model, deviceModel: deviceModel)
            }
        }
    }
    
    @available(iOS 10.0, *)
    func dispatchBLEDidUpdateState(state:CBManagerState) {
        if state == .poweredOff {
            if let peripheral = MD_BLEConnectManager.shared.getConnected_Device()?.peripheral {
                MD_BLEConnectManager.shared.getConnected_Device()?.heartBeat.heartBeatOver()
                MD_BLEConnectManager.shared.reconnectedBLEModels.append(MD_BLEConnectManager.shared.getConnected_Device() ?? MD_BLEModel())
                self.resetStatus(peripheral: peripheral)
            }
        }
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.dispatchBLEDidUpdateState?(state: state)
            }
        }
    }
    
    /// 更新信号强度
    /// - Parameters:
    ///   - peripheral: peripheral
    ///   - rssiValue: 信号强度
    ///   - rssiLevel: 信号等级
    func dispatchBLEModelDidUpdateRSSI(peripheral: CBPeripheral, rssiValue:Int, rssiLevel: MD_BLERSSILEVEL) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.bleModelDidUpdateRSSI?(peripheral: peripheral, rssiValue: rssiValue, rssiLevel: rssiLevel)
            }
        }
    }

    /// 分发EMG肌电采集数据
    /// - Parameters:
    ///   - model: 设备模型
    ///   - pelvicData: 采集的盆底数据
    ///   - avgPelVic: 盆底数据平均值
    ///   - abdData: 腹肌肌电数据
    ///   - avgAbd: 腹肌肌电数据平均值
    func dispatchLTEMGCollectionData(model: MD_BLEModel, pelvicData: [Double], avgPelVic: Double, abdData: [Double], avgAbd: Double) {
        //未获取到设备配置,不分发采集数据,防止手机蓝牙关闭打开 采集线提前走
        if MD_BLEConnectManager.shared.getConnected_Device()?.isReady == false {
            return
        }
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.ltEMGCollectionData?(model: model, pelvicData: pelvicData, avgPelVic: avgPelVic, abdData: abdData, avgAbd: avgAbd)
            }
        }
    }
    
    //采集定时器
    func dispatchCollectionTimerUpdate() {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.dispatchCollectionTimerUpdate?()
            }
        }
    }
    
    /// 电池电量
    /// - Parameters:
    ///   - model: 设备模型
    ///   - batteryValue: 电量原始数据
    ///   - batteryLevel: 电量等级
    func dispatchBLEDeviceDidUpdateBatteryValue(model: MD_BLEModel ,batteryValue: Int, batteryStatus: MD_BLEDeviceBatteryStatus) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.bleDeviceDidUpdateBatteryValue?(model: model, batteryValue: batteryValue, batteryStatus: batteryStatus)
            }
        }
    }
    
    /// 电流大小
    /// - Parameters:
    ///   - model: 设备模型
    ///   - val_channel1: 通道1电流
    ///   - val_channel2: 通道2电流
    func dispatchBLEDeviceDidUpdateElectricity(model: MD_BLEModel, val_channel1: Double, val_channel2: Double,channel:ChannelType) {
        let mul = MD_BLEConnectManager.shared.getConnected_Device()?.electricityMultiple ?? 1
        let val1 = val_channel1 / mul
        let val2 = val_channel2 / mul
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.bleDeviceDidUpdateElectricity?(model: model, val_channel1: val1, val_channel2: val2, channel: channel)
            }
        }
    }
    
    /// 点击脱落
    /// - Parameters:
    ///   - model: 设备模型
    ///   - val_channel1: 通道1电流
    ///   - val_channel2: 通道2电流
    func dispatchBLEDeviceElectrodeDidFallOff(model: MD_BLEModel, channel1_fall: Bool, channel2_fall: Bool) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.dispatchBLEDeviceElectrodeDidFallOff?(model: model, channel1_fall: channel1_fall, channel2_fall: channel2_fall)
            }
        }
    }
    
    
    //升级握手失败
    func dispatchUpgradeShakeFailure() {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleUpgradeShakeFailure?()
            }
        }
        let model = MD_BLEConnectManager.shared.getConnected_Device()
        model?.heartBeat.heartBeat()
    }
    
    /// 澜渟2代 - 升级握手指令成功，连接设备成功
    func dispatchLT2rdBleUpgradeShakeSuccess(model: MD_BLEModel) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleUpgradeShakeSuccess?(model: model)
            }
        }
    }
    
    /// 澜渟2代 - 擦除成功
    func dispatchLT2rdBleUpgradeValidSuccess(model: MD_BLEModel) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleUpgradeValidSuccess?(model: model)
            }
        }
    }
    
    /// 澜渟2代 - 成功进度
    func dispatchLT2rdBleUpgradeProgress(model: MD_BLEModel,progress:CGFloat) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleUpgradeProgress?(model: model,progress:progress)
            }
        }
    }
    
    /// 澜渟2代 - 升级成功
    func dispatchLT2rdBleUpgradeSuccess(model: MD_BLEModel) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleUpgradeSuccess?(model: model)
            }
        }
        let model = MD_BLEConnectManager.shared.getConnected_Device()
        model?.heartBeat.heartBeat()
    }
    
    /// 澜渟2代 - 设备更新失败
    func dispatchLT2rdBleUpgradeFailure(error:NSError) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleUpgradeFailure?(error:error)
            }
        }
        let model = MD_BLEConnectManager.shared.getConnected_Device()
        model?.heartBeat.heartBeat()
    }
    
    /// 澜渟2代 - 读取EEPROM
    func dispatchLT2rdBleReadEEPROM(device:MD_BLEModel,deviceModel: UInt8, serialNumber:String, activationDate:String?) {
        device.cancelReadEEPROM()
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleReadEEPROM?(deviceModel: deviceModel, serialNumber: serialNumber, activationDate: activationDate)
            }
        }
        self.dispatchLT2rdCheckDevice(model: device, deviceModel: deviceModel)
    }
    
    /// 二代检测是否可以连接
    /// - Parameters:
    ///   - model: 设备模型
    ///   - deviceModel: 1代设备型号
    func dispatchLT2rdCheckDevice(model:MD_BLEModel, deviceModel:UInt8){
        model.checkDeviceConnect()
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lT2rdCheckDevice?(model: model, deviceModel: deviceModel)
            }
        }
    }
    
    /// 澜渟2代 - 设备未激活
    func dispatchLT2rdBleDeviceUnactivated(deviceModel: UInt8, serialNumber:String) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleDeviceUnactivated?(deviceModel: deviceModel, serialNumber: serialNumber)
            }
        }
    }
    
    /// 澜渟2代 - 电流更新
    func dispatchLT2rdBleDidUpdateElectricity(electricity: UInt8) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleDidUpdateElectricity?(electricity: electricity)
            }
        }
    }
    
    /// 澜渟2代 - 采集更新
    func dispatchLT2rdBleCollectionData(smooth1:[Double], avg1:Double, smooth2:[Double], avg2:Double) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleCollectionData?(smooth1:smooth1, avg1:avg1, smooth2:smooth2, avg2:avg2)
            }
        }
    }
    
    /// 澜渟2代 - 设备状态更新
    func dispatchLT2rdBleDidUpdateStatusData(vagina:UInt8, electrode:UInt8, batteryStatus:UInt8, batteryPower:UInt, workingStatus:UInt8, temperature: UInt8, errorType:UInt8) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt2rdBleDidUpdateStatusData?(vagina:vagina, electrode:electrode, batteryStatus:batteryStatus, batteryPower:batteryPower, workingStatus:workingStatus, temperature: temperature, errorType:errorType)
            }
        }
    }
    
    func dispatchLT3rdBleShakeSuccess(model: MD_BLEModel) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.dispatchLT3rdBleShakeSuccess?(model: model)
            }
        }
        model.bleShakeSuccess()
    }
    
    /// 澜渟三代 - 读取EEPROM
    func dispatchLT3rdBleReadEEPROM(device:MD_BLEModel ,deviceModel: UInt8, serialNumber:String, activationDate:String?) {
        device.cancelReadEEPROM()
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt3rdBleReadEEPROM?(deviceModel: deviceModel, serialNumber: serialNumber, activationDate: activationDate)
            }
        }
        self.dispatchLT3rdCheckDevice(model: device, deviceModel: deviceModel)
    }
    
    /// 三代检测是否可以连接
    /// - Parameters:
    ///   - model: 设备模型
    ///   - deviceModel: 1代设备型号
    func dispatchLT3rdCheckDevice(model:MD_BLEModel, deviceModel:UInt8){
       
        model.checkDeviceConnect()
        
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lT3rdCheckDevice?(model: model, deviceModel: deviceModel)
            }
        }
    }
    
    
    /// 澜渟三代压力采集反馈
    /// - Parameters:
    ///   - model: 设备模型
    ///   - pressureData: 采集的压力数据
    ///   - avgPressure: 采集的压力数据平均值
    func dispatchLT3rdDevicePressureCollectData(model: MD_BLEModel, pressureData: [Double], avgPressure: Double) {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.lt3rdDevicePressureCollectData?(model: model, pressureData: pressureData, avgPressure: avgPressure)
            }
        }
    }
    
    
    
    /// 设备异常断开结束训练
    @objc func dispatchBLEDisConnectAlertControlOver() {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.dispatchBLEDisConnectAlertControlOver?()
            }
        }
    }
    /// 设备异常断开已连接上的继续训练按钮点击事件
    @objc func diapatchBLEDidConnectContinueTrain() {
        for object in observerTargets.allObjects {
            if let delegate = object as? MD_DispatcherCenterDelegate {
                delegate.diapatchBLEDidConnectContinueTrain?()
            }
        }
    }
    
    
    
    //失去连接
    func resetStatus(peripheral : CBPeripheral) {
        MD_BLEConnectManager.shared.cancelAllConnectPeripheral()
    }
}
