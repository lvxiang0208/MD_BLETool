//
//  MD_LT1G_DataHandle.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/14.
//

import UIKit

class MD_LT1G_DataHandle: NSObject {
    
    private lazy var dataSmooth:MD_DataSmooth = {
        let tmpSmooth : MD_DataSmooth = MD_DataSmooth()
        tmpSmooth.setSmoothLength(length: 40)
        return tmpSmooth;
    }();
    //数据处理
    private var receivedData:[UInt8] = [UInt8]()
    //序列号
    private var deviceSerialNumber:String = "";
    //设备型号
    private var deviceModel:UInt8 = 0
    
    private var batteryPowerTmpArr:[String] = [String]()
    
    @objc func reset() {
        dataSmooth.setSmoothLength(length: 40)
        receivedData.removeAll()
    }
    
    /// 校验是否是合法的指令头
    /// - Parameter header: 头部指令
    /// - Returns: Bool
    private func isCorrectLT1rdNotifyHeader(header:UInt8) -> Bool {
        if(header == kCommand1GHeaderStatus ||
           header == kCommand1GHeaderCollection ||
           header == kCommand1GHeaderStim ||
           header == kCommand1GHeaderEEPROM) {
            return true;
        }
        return false;
        
    }
    
    /// 获取下位机指令类型
    /// - Parameter header: 指令头
    /// - Returns: 指令类型 Lanting1GNotifyType
    private func getCommandNotifyType(header:UInt8)->Lanting1GNotifyType {
        var commandType:Lanting1GNotifyType = .Status;
        if header == UInt8(kCommand1GHeaderStatus) {
            commandType = .Status
        } else if header == UInt8(kCommand1GHeaderCollection) {
            commandType = .Collection
        } else if header == UInt8(kCommand1GHeaderStim) {
            commandType = .StimCurrent
        } else if header == UInt8(kCommand1GHeaderEEPROM) {
            commandType = .EEPROM
        }
        return commandType;
    }
    
    /// 根据类型处理下位机返回的数据
    /// - Parameters:
    ///   - notifyType: 指令类型
    ///   - data: Data
    private func handleDataByNotifyType(notifyType:Lanting1GNotifyType,data:[UInt8]){
        switch notifyType {
        case .Status:
            //阴道电极状态
            device?.vagina = LTElectrodeStatus(rawValue: data[1]) ?? .Unknow
            //是否充电
            if data[4] == 0x01 {
                device?.batteryStatus = .isCharging
            }
            
            let batteryPower = Int(data[2])*256 + Int(data[3])
            //锂电池电量
            device?.batteryPower = batteryPower
            let currentBatteryPower = MD_BLEDeviceDealTool.calculateBattery(Float(batteryPower))
            if (Float(currentBatteryPower) ?? 0 > 0) && device?.batteryStatus != .isCharging {
                if self.batteryPowerTmpArr.count == 20 {
                    self.batteryPowerTmpArr.remove(at: 0)
                }
                self.batteryPowerTmpArr.append(currentBatteryPower)
            }
            var sumBatteryPower:Float = 0
            for str in self.batteryPowerTmpArr {
                sumBatteryPower += (Float(str) ?? 0)
            }
            var avgBatteryPower:Float = 0
            if self.batteryPowerTmpArr.count > 0 {
                avgBatteryPower = sumBatteryPower / Float(self.batteryPowerTmpArr.count)
            }
            //电量只能减少
            let batteryFloat = Float(device?.batteryPowerStr ?? "") ?? 0
            if batteryFloat < 1 || (batteryFloat > 0 && batteryFloat >= avgBatteryPower) {
                device?.batteryPowerStr = String(format: "%.f", avgBatteryPower)
            }
            
            //是否需要强制关机
            if data[5] == 0x01 {
                device?.isForcedShutdown = true
            }
            //当前电流值
            device?.electricity = Int(data[6])
            //todo 分发电流值，更新UI 以什么形式将数据给MD_BLEModel.swift 参考MD_LT3G_DeviceInfo 以对象形式
            if let model = device {
                MD_DispatcherCenter.shared.dispatchBLEDeviceDidUpdateBatteryValue(model: model, batteryValue: device?.batteryPower ?? 100, batteryStatus: device?.batteryStatus ?? .full)
            }
            
        case .Collection:
            //数据采集
            let quotient:Double = 3000000.0 / (4095.0 * 2000.0)
            // 这里-1.5是一代采集基线偏高，做一个偏值校准
            var temp:[Double] = [Double](repeating: 0, count: 4)
            temp[0] = (Double(data[1])*256 + Double(data[2])) * quotient - 1.5
            temp[1] = (Double(data[3])*256 + Double(data[4])) * quotient - 1.5
            temp[2] = (Double(data[5])*256 + Double(data[6])) * quotient - 1.5
            temp[3] = (Double(data[7])*256 + Double(data[8])) * quotient - 1.5
            //平滑数据，取平均值
            var smooth:[Double] = [Double](repeating: 0, count: 4)
            var sum:Double = 0
            for i in 0...3 {
                smooth[i] = dataSmooth.smoothData(data: temp[i])
                if smooth[i] < 0 {
                    smooth[i] = 0
                }
                sum += smooth[i]
            }
            let avg:Double = sum/4.0
            //todo 数据应用
            let temp1:[Double] = [Double](repeating: 0, count: 4)
            if let model = device {
                MD_DispatcherCenter.shared.dispatchLTEMGCollectionData(model: model, pelvicData: smooth, avgPelVic: avg, abdData: temp1, avgAbd: 0)
            }
            break
            
        case .StimCurrent:
            device?.electricity = Int(data[1])
            if let model = device {
                MD_DispatcherCenter.shared.dispatchBLEDeviceDidUpdateElectricity(model: model, val_channel1: Double(model.electricity), val_channel2: 0, channel: .first)
            }
            break
        case .EEPROM:
            let blockType = Lanting1GEPROMBlockType(rawValue: data[1])
            handleEEPROMData(data: data, blockType: blockType!)
            break
            
        }
    }
    
    
    /// 处理EEPROdata
    /// - Parameters:
    ///   - data: 数据
    ///   - blockType: 数据类型
    private func handleEEPROMData(data:[UInt8], blockType:Lanting1GEPROMBlockType) {
        switch blockType {
        case .Model:
            let deviceModel = data[2]
            self.deviceModel = deviceModel
            device?.deviceM = deviceModel
            break
        case .SerialNumber:
            let year = data[2]
            let tempNo:Int = (Int)(data[3])*65536 + (Int)(data[4])*256 + (Int)(data[5])
            //TODO getSerialNumber 方法 和实现读取序列号的代理方法
            self.deviceSerialNumber = MD_BLEDeviceDealTool.getSerialNumber(year: UInt(year), number: UInt(tempNo))
            device?.serialNumber = self.deviceSerialNumber
            break
        case .BuildInScheme:
            break
        case .ActivationDate:
            if self.deviceModel == 0 {
                return
            } else if self.deviceSerialNumber.count < 5 {
                return
            } else {
                let year = data[2]
                let month = data[3]
                let day = data[4]
                let sum = (UInt(year)+UInt(month)+UInt(day)+251)*3;
                let sumInt8 = UInt8(sum % 256)
                if sumInt8 == data[5] {
                    //有激活日期
                    let activationDate:String = String(format: "20%lu-%02lu-%02lu", year, month, day)
                    device?.activationDate = activationDate
                    //调用实现读取激活日期的代理方法
                    MD_DispatcherCenter.shared.dispatchLT1rdBleReadEEPROM(device: device ?? MD_BLEModel(),deviceModel: deviceModel, serialNumber: self.deviceSerialNumber, activationDate: activationDate)
                } else {
                    //TODO:--没有写过,向服务器申请时间,写入当前日期
                    device?.activationDate = nil
                    MD_DispatcherCenter.shared.dispatchLT1rdBleReadEEPROM(device: device ?? MD_BLEModel(),deviceModel: deviceModel, serialNumber: self.deviceSerialNumber, activationDate: nil)
                }
            }
            break
            
        default:
            break
        }
    }
    
    
    /// 处理接收的数据
    /// - Parameter data: data
    @objc func dataHandleDidUpdateValue(data:Data){
        //接受到的数据放到数组中
        receivedData.append(contentsOf: [UInt8](data))
        //判断数组个数
        if receivedData.count <= 0 {
            return
        }
        
        var i:Int = 0
        let dataLegth = receivedData.count
        while i + 10 <= dataLegth {
            //校验头
            if !isCorrectLT1rdNotifyHeader(header: receivedData[i]) {
                i = i + 1
                continue
            }
            var dealForPackageData:[UInt8] = [UInt8]()
            //头正确，截取长度10处理
            for index in i..<i + 10 {
                dealForPackageData.append(receivedData[index])
            }
            //指令数据解析,和校验
            if !MD_VerfifyTool.sumVerfifyCode_Check(bytes: dealForPackageData) {
                i = i + 1
                continue
            }
            let notifyType:Lanting1GNotifyType = getCommandNotifyType(header: receivedData[i])
            handleDataByNotifyType(notifyType: notifyType, data: dealForPackageData)
            i = i + 10
        }
        if i > 0 {
            receivedData.removeFirst(i)
        }
        
    }
    /// 设备对象
    private var device : MD_BLEModel?
    
    init(bleModel: MD_BLEModel) {
        self.device = bleModel
    }
    
    
}
