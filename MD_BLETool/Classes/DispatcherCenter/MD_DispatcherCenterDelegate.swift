//
//  MD_DispatcherCenterDelegate.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/14.
//

import Foundation
import CoreBluetooth

@objc protocol MD_DispatcherCenterDelegate: NSObjectProtocol {

    /// 发现蓝牙外设
    /// - Parameter disCoveredPeripherals: 蓝牙外设数组
    @objc optional func bleConnectManagerDidDiscoverPeripherals(disCoveredPeripherals: [CBPeripheral])
    
    
    /// 仅仅蓝牙连接成功连接成功,升级DFU
    /// - Parameter peripheral: peripheral
    @objc optional func peripheralDidConnectUpgradeDFU(peripheral: CBPeripheral)
    
    /// 连接外设成功
    /// - Parameter peripheral: peripheral
    @objc optional func bleConnectManagerDidConnect(peripheral: CBPeripheral)
    
    /// 连接外设失败
    /// - Parameters:
    ///   - peripheral: peripheral
    ///   - error: error
    @objc optional func bleConnectManagerDidFailToConnect(peripheral: CBPeripheral, error: Error?)
    
    /// 与外设断开链接
    /// - Parameters:
    ///   - peripheral: peripheral
    ///   - error: error
    @objc optional func bleConnectManagerDidDisconnectPeripheral(peripheral: CBPeripheral, error: Error?)
    
    /// 蓝牙收到数据
    /// - Parameters:
    ///   - peripheral: peripheral
    ///   - error: error
    @objc optional func LTBLEDidUpdateValue(peripheral: CBPeripheral, value:Data ,error: Error?)
    
    /// 写入数据
    /// - Parameters:
    ///   - peripheral: peripheral
    ///   - error: error
    @objc optional func LTBLEWriteValue(value:Data)
    
    /// 澜渟1代 - 读取EEPROM
    /// - Parameters:
    ///   - deviceModel: 设备型号
    ///   - serialNumber: 设备序列号
    ///   - activationDate: 设备激活时间
    ///   - activationDate = nil 未激活
    @objc optional func lt1rdBleReadEEPROM(deviceModel:UInt8 , serialNumber:String, activationDate:String?)
    
    /// 一代检测是否可以连接
    /// - Parameters:
    ///   - model: 设备模型
    ///   - deviceModel: 设备型号
    @objc optional func lT1rdCheckDevice(model: MD_BLEModel,deviceModel:UInt8)
    
    /// 更新蓝牙中心状态
    @available(iOS 10.0, *)
    @objc optional func dispatchBLEDidUpdateState(state:CBManagerState)
    
    /// 更新信号强度
    /// - Parameters:
    ///   - peripheral: peripheral
    ///   - rssiValue: 信号强度
    ///   - rssiLevel: 信号等级
    @objc optional func bleModelDidUpdateRSSI(peripheral: CBPeripheral, rssiValue:Int, rssiLevel: MD_BLERSSILEVEL)
    
    /// 分发EMG肌电采集数据
    /// - Parameters:
    ///   - model: 设备模型
    ///   - pelvicData: 采集的盆底数据
    ///   - avgPelVic: 盆底数据平均值
    ///   - abdData: 腹肌肌电数据
    ///   - avgAbd: 腹肌肌电数据平均值
    @objc optional func ltEMGCollectionData(model: MD_BLEModel, pelvicData: [Double], avgPelVic: Double, abdData: [Double], avgAbd: Double)
    
    /// 采集定时器代理
    @objc optional func dispatchCollectionTimerUpdate()
    
    /// 电池电量
    /// - Parameters:
    ///   - model: 设备模型
    ///   - batteryValue: 电量原始数据
    ///   - batteryLevel: 电量等级
    @objc optional func bleDeviceDidUpdateBatteryValue(model: MD_BLEModel ,batteryValue: Int, batteryStatus: MD_BLEDeviceBatteryStatus)
    
    /// 电流大小
    /// - Parameters:
    ///   - model: 设备模型
    ///   - val_channel1: 通道1电流
    ///   - val_channel2: 通道2电流
    @objc optional func bleDeviceDidUpdateElectricity(model: MD_BLEModel, val_channel1: Double, val_channel2: Double,channel:ChannelType)
    
    /// 电极脱落
    /// - Parameters:
    ///   - model: 设备模型
    ///   - val_channel1: 通道1电流
    ///   - val_channel2: 通道2电流
    @objc optional func dispatchBLEDeviceElectrodeDidFallOff(model: MD_BLEModel, channel1_fall: Bool, channel2_fall: Bool)
    
    /// 澜渟2代 - 握手指令成功，连接设备成功
    /// - Parameters:
    ///   - model: 设备模型
    ///   - firmwareVersion: 固件版本号
    ///   - bootVersion: 固件boot版本号
    @objc optional func lt2rdBleShakeSuccess(model: MD_BLEModel, firmwareVersion: UInt8, bootVersion: UInt8)
    
    /// 澜渟2代 - 握手指令失败，
    @objc optional func lt2rdBleUpgradeShakeFailure()
    
    /// 澜渟2代 - 升级握手指令成功
    /// - Parameters:
    ///   - model: 设备模型
    @objc optional func lt2rdBleUpgradeShakeSuccess(model: MD_BLEModel)

    /// 澜渟2代 - 擦除成功
    /// - Parameters:
    ///   - model: 设备模型
    @objc optional func lt2rdBleUpgradeValidSuccess(model: MD_BLEModel)
    
    /// 澜渟2代 - 成功进度
    /// - Parameters:
    ///   - model: 设备模型
    @objc optional func lt2rdBleUpgradeProgress(model: MD_BLEModel,progress:CGFloat)
    
    /// 澜渟2代 - 升级成功
    /// - Parameters:
    ///   - model: 设备模型
    @objc optional func lt2rdBleUpgradeSuccess(model: MD_BLEModel)
    
    /// 澜渟2代 - 读取EEPROM
    /// - Parameters:
    ///   - deviceModel: 设备型号
    ///   - serialNumber: 设备序列号
    ///   - activationDate: 设备激活时间
    @objc optional func lt2rdBleReadEEPROM(deviceModel:UInt8 , serialNumber:String, activationDate:String?)
    
    /// 二代检测是否可以连接
    /// - Parameters:
    ///   - model: 设备模型
    ///   - deviceModel: 设备型号
    @objc optional func lT2rdCheckDevice(model: MD_BLEModel,deviceModel:UInt8)

    /// 澜渟2代 - 升级成功
    /// - Parameters:
    ///   - deviceModel: 设备型号
    ///   - serialNumber: 设备序列号
    @objc optional func lt2rdBleDeviceUnactivated(deviceModel:UInt8 , serialNumber:String)
    
    /// 澜渟2代 - 电流更新
    /// - Parameters:
    ///   - electricity: 电流大小
    @objc optional func lt2rdBleDidUpdateElectricity(electricity:UInt8)

    /// 澜渟2代 - 采集数据
    /// - Parameters:
    ///   - smooth1: 阴道肌电信号数据
    ///   - avg1: 平均值
    ///   - smooth2: 腹肌肌电信号数据
    ///   - avg2: 平均值
    @objc optional func lt2rdBleCollectionData(smooth1:[Double], avg1:Double, smooth2:[Double], avg2:Double)
    
    /// 澜渟2代 - 设备状态更新
    /// - Parameters:
    ///   - vagina: 阴道电极状态
    ///   - electrode: 腹肌电极状态
    ///   - batteryStatus: 电池状态
    ///   - batteryPower: 锂电池电量
    ///   - workingStatus: 工作状态
    ///   - temperature: 主板温度
    ///   - errorType: 错误代码
    @objc optional func lt2rdBleDidUpdateStatusData(vagina:UInt8, electrode:UInt8, batteryStatus:UInt8, batteryPower:UInt, workingStatus:UInt8, temperature: UInt8, errorType:UInt8)
    
    
    
    /// 澜渟2代 - 更新失败
    /// - Parameters:
    ///   - vagina: 阴道电极状态
    ///   - electrode: 腹肌电极状态

    @objc optional func lt2rdBleUpgradeFailure(error:NSError)
    
    
    /// 澜渟三代握手信息反馈
    /// - Parameters:
    ///   - model: 设备模型
    @objc optional func dispatchLT3rdBleShakeSuccess(model: MD_BLEModel)
    
    
    /// 澜渟三代 - 读取EEPROM
    /// - Parameters:
    ///   - deviceModel: 设备型号
    ///   - serialNumber: 设备序列号
    ///   - activationDate: 设备激活时间
    ///   - activationDate = nil 未激活
    @objc optional func lt3rdBleReadEEPROM(deviceModel:UInt8 , serialNumber:String, activationDate:String?)
    
    /// 三代检测是否可以连接
    /// - Parameters:
    ///   - model: 设备模型
    ///   - deviceModel: 设备型号
    @objc optional func lT3rdCheckDevice(model: MD_BLEModel,deviceModel:UInt8)
    
    
    
    /// 澜渟三代压力采集反馈
    /// - Parameters:
    ///   - model: 设备模型
    ///   - pressureData: 采集的压力数据
    ///   - avgPressure: 采集的压力数据平均值
    @objc optional func lt3rdDevicePressureCollectData(model: MD_BLEModel, pressureData: [Double], avgPressure: Double)
    
    
    
    
    /// 设备异常断开结束训练
    @objc optional func dispatchBLEDisConnectAlertControlOver()
    
    /// 设备异常断开已连接上的继续训练按钮点击事件
    @objc optional func diapatchBLEDidConnectContinueTrain()
    
}
