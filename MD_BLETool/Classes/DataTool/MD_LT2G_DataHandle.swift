//
//  MD_LT2G_DataHandle.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/14.
//

import UIKit

// 写入下位机的头
let kCommandHeaderWrite = 0xaa
// 从下位机读的头
let kCommandHeaderNotify = 0xbb
//  采集头
let kCommandHeaderCollection = 0xa8
// 澜渟2G通用头
let kCommandHeaderCommon = 0xa7

class MD_LT2G_DataHandle: NSObject {
    private var completeCommandLength:UInt = 15
    private var seedByte:[UInt8] = [UInt8](repeating: 0, count: 4)

    private var sentKeyAgain:Bool = false       // 是否已经再次发送密钥指令
    private var sentFlashAgain:Bool = false     // 是否已经再次发送擦除指令
    private var sentDataAgain:Bool = false      // 是否已经再次发送当前数据包指令
   
    private var binDatumIndex:Int = 0    // 升级bin数据
    private var binDatum:[[UInt8]] = [[UInt8]]()    // 升级bin数据
    
    private var receivedData:[UInt8] = [UInt8]()    //数据处理

    private var batteryPowerTmpArr:[String] = [String]()
    
    /// 设备对象
    private var device : MD_BLEModel?
    
    //平滑工具
    lazy var channel_1_Smooth : MD_DataSmooth = {
        let t_smooth = MD_DataSmooth()
        t_smooth.setSmoothLength(length: 40)
        return t_smooth
    }()
    
    lazy var channel_2_Smooth : MD_DataSmooth = {
        let t_smooth = MD_DataSmooth()
        t_smooth.setSmoothLength(length: 40)
        return t_smooth
    }()
    
    init(bleModel: MD_BLEModel) {
        self.device = bleModel
    }
    
    /// 是否能通过CRC校验
    /// - Parameter data: 整包
    /// - Returns: Bool
    private func isCorrectedValueByCRC(data:[UInt8]) -> Bool {
        let dataCount = data.count
        if dataCount < 7 {
            return false
        }
        let dataCRC_H = data[dataCount-2]
        let dataCRC_L = data[dataCount-1]
        var validCommand:[UInt8] = [UInt8]()
        if data[1] == 0xa8 {
            //采集数据
            for i in 2..<data.count-2{
                validCommand.append(data[i])
            }
        }else{
            //非采集数据
            let length = data[2]
            for i in 0..<length{
                validCommand.append(data[Int(i) + 3])
            }
        }
        return MD_VerfifyTool.crcVerfifyCode_Check(bytes: validCommand, highCheck: dataCRC_H, lowCheck: dataCRC_L)
    }
    
    /// 处理下位机返回的数据
    /// @param data 数据  //指令规则匹配前;两位头
    func handleNotify(data:Data) {
//        if data.count >= 15 {
//            let value = NSData(data: data)
//            var byteArray:[UInt8] = [UInt8]()
//            for i in 0..<2 {
//                var temp : UInt8 = 0
//                value.getBytes(&temp, range: NSRange(location: i, length: 1))
//                byteArray.append(temp)
//            }
//        }
        let tempByte = [UInt8](data)
        let header_0 = tempByte[0]
        let header_1 = tempByte[1]
        let value_1 = tempByte[2]
        let value_2 = tempByte[3]
        if header_0 == kCommandHeaderNotify && header_1 ==  kCommandHeaderCommon {
            if isCorrectedValueByCRC(data: tempByte) {
                if value_1 == 0x04 && value_2 == LT2GCommandType.Shake.rawValue {
                    self.handleNotifyShake(tempByte: tempByte)
                } else if value_1 == 0x09 && value_2 == LT2GCommandType.Status.rawValue {
                    self.handleNotifyStatus(tempByte: tempByte)
                } else if value_1 == 0x0a && value_2 == LT2GCommandType.EEPROMNotify.rawValue {
                    self.handleNotifyEEPROM(tempByte: tempByte)
                } else if value_1 == 0x02 && value_2 == LT2GCommandType.StimCurrent.rawValue {
                    self.handleNotifyStimCurrent(tempByte: tempByte)
                } else if value_1 == 0x02 && value_2 == LT2GCommandType.Error.rawValue {
                    self.handleNotifyError(tempByte: tempByte)
                } else if value_1 == 0x02 && value_2 == LT2GCommandType.UpgradeShake.rawValue {
                    self.handleNotifyUpgradeShake(tempByte: tempByte)
                } else if value_1 == 0x02 && value_2 == LT2GCommandType.UpgradeBoot.rawValue {
                    self.handleNotifyUpgradeBoot(tempByte: tempByte)
                } else if value_1 == 0x05 && value_2 == LT2GCommandType.UpgradeSeed.rawValue {
                    self.handleNotifyUpgradeSeed(tempByte: tempByte)
                } else if value_1 == 0x02 && value_2 == LT2GCommandType.UpgradeKey.rawValue {
                    self.handleNotifyUpgradeKey(tempByte: tempByte)
                } else if value_1 == 0x02 && value_2 == LT2GCommandType.UpgradeFlash.rawValue {
                    self.handleNotifyUpgradeFlash(tempByte: tempByte)
                } else if value_1 == 0x04 && value_2 == LT2GCommandType.UpgradeData.rawValue {
                    self.handleNotifyUpgradeData(tempByte: tempByte)
                } else if value_1 == 0x02 && value_2 == LT2GCommandType.UpgradeFinish.rawValue {
                    self.handleNotifyUpgradeFinish(tempByte: tempByte)
                } else if value_1 == 0x02 && value_2 == LT2GCommandType.UpgradeAPP.rawValue {
                    self.handleNotifyUpgradeAPP(tempByte: tempByte)
                }
            }
        }
        else if header_0 == kCommandHeaderNotify && header_1 == kCommandHeaderCollection {
            if isCorrectedValueByCRC(data: tempByte) {
                self.handleNotifyCollection(data: tempByte)
            }
        }
    }
    
    
    func handleNotifyShake(tempByte:[UInt8]) {
        let firmwareVersion = tempByte[4] // 固件版本号
        let bootVersion = tempByte[6] // 固件boot版本号
        device?.firmwareVersion = Float(firmwareVersion)
        device?.hardwareVersion = Float(bootVersion)
        // 握手指令成功，连接设备成功
        if let model = device {
            MD_DispatcherCenter.shared.dispatchLT2rdBleShakeSuccess(model: model, firmwareVersion: firmwareVersion, bootVersion: bootVersion)
        }
    }
    
    func handleNotifyStatus(tempByte:[UInt8]) {
        let electrode = tempByte[4] // 腹肌电极状态
        var vagina = tempByte[5]  // 阴道电极状态
        if vagina == 0 {
            vagina = 1
        }
        let batteryStatus = tempByte[6] // 电池状态
        let highPower = tempByte[7] // 锂电池电量高位
        let lowPower = tempByte[8] // 锂电池电量低位
        let batteryPower = UInt(highPower) * 256 + UInt(lowPower) // 锂电池电量
        let workingStatus = tempByte[9] // 工作状态
        let errorType = tempByte[10]  // 错误代码
        let mainBoardTemperature = tempByte[11] // 主板温度
        
        let temperature = 100 - mainBoardTemperature
   
        device?.vagina = LTElectrodeStatus.init(rawValue: vagina) ?? .NoTouch
        device?.abdominalElectrodeStatus = LTElectrodeStatus.init(rawValue: electrode) ?? .Unknow
        device?.batteryStatus = MD_BLEDeviceBatteryStatus(rawValue: batteryStatus) ?? .full
        device?.workingStatus = MD_BLEDeviceWorkingStatus(rawValue: workingStatus) ?? .standby
        let currentBatteryPower = MD_BLEDeviceDealTool.calculateBattery(Float(batteryPower))
        if (Float(currentBatteryPower) ?? 0 > 0) && device?.batteryStatus != .isCharging{
            if self.batteryPowerTmpArr.count == 10 {
                self.batteryPowerTmpArr.removeFirst()
            }
            self.batteryPowerTmpArr.append(currentBatteryPower)
        }
        var sumBatteryPower:Float = 0
        for str in self.batteryPowerTmpArr {
            sumBatteryPower += (Float(str) ?? 0)
        }
        var avgBatteryPower : Float = 0
        if self.batteryPowerTmpArr.count > 0 {
             avgBatteryPower = sumBatteryPower / Float(self.batteryPowerTmpArr.count)
        }
      //电量只能增加
        let batteryFloat = Float(device?.batteryPowerStr ?? "") ?? 0
        if batteryFloat < 1 || (batteryFloat > 0 && batteryFloat >= avgBatteryPower) {
            device?.batteryPowerStr = String(format: "%.f", avgBatteryPower)
        }
        
        if let model = device {
            MD_DispatcherCenter.shared.dispatchBLEDeviceDidUpdateBatteryValue(model: model, batteryValue: device?.batteryPower ?? 100, batteryStatus: device?.batteryStatus ?? .full)
        }
    }
    
    func handleNotifyEEPROM(tempByte:[UInt8]) {
        // 块号（类型）范围0-15，其中14和15为单片机占用，手机端可以使用0~13块区域；
        let blockNum = tempByte[4]
        let blockType = Lanting2GEPROMBlockType(rawValue: blockNum)!
        self.handleEEPROMData(tempByte: tempByte, blockType: blockType)
    }
    
    func handleNotifyStimCurrent(tempByte:[UInt8]) {
        let electricity = tempByte[4]
        // 分发电流值，更新UI
        device?.electricity = Int(electricity)
        if let model = device {
            MD_DispatcherCenter.shared.dispatchBLEDeviceDidUpdateElectricity(model: model, val_channel1: Double(model.electricity), val_channel2: 0,channel: .first)
        }
    }
    
    func handleNotifyCollection(data:[UInt8]) {
        let quotient:Double = 3000000.0 / (4095.0 * 2000.0)
        
        // 阴道肌电信号数据采集
        var original_channel_1_value:[Double] = [Double](repeating: 0, count: 4)
        original_channel_1_value[0] = (Double(data[2])*256 + Double(data[3])) * quotient
        original_channel_1_value[1] = (Double(data[4])*256 + Double(data[5])) * quotient
        original_channel_1_value[2] = (Double(data[6])*256 + Double(data[7])) * quotient
        original_channel_1_value[3] = (Double(data[8])*256 + Double(data[9])) * quotient
        
        //平滑数据，取平均值
        var smooth_channel_1_value:[Double] = [Double](repeating: 0, count: 4)
        var sum_channel_1:Double = 0
        for i in 0...3 {
            smooth_channel_1_value[i] = channel_1_Smooth.smoothData(data: original_channel_1_value[i])
            if smooth_channel_1_value[i] < 0 {
                smooth_channel_1_value[i] = 0
            }
            sum_channel_1 += smooth_channel_1_value[i]
        }
        let avg_channel_1:Double = sum_channel_1/4.0
        
        // 腹肌肌电信号
        var original_channel_2_value:[Double] = [Double](repeating: 0, count: 4)
        original_channel_2_value[0] = (Double(data[10])*256 + Double(data[11])) * quotient
        original_channel_2_value[1] = (Double(data[12])*256 + Double(data[13])) * quotient
        original_channel_2_value[2] = (Double(data[14])*256 + Double(data[15])) * quotient
        original_channel_2_value[3] = (Double(data[16])*256 + Double(data[17])) * quotient
        
        //平滑数据，取平均值
        var smooth_channel_2_value:[Double] = [Double](repeating: 0, count: 4)
        var sum_channel_2:Double = 0
        for i in 0...3 {
            smooth_channel_2_value[i] = channel_2_Smooth.smoothData(data: original_channel_2_value[i])
            if smooth_channel_2_value[i] < 0 {
                smooth_channel_2_value[i] = 0
            }
            sum_channel_2 += smooth_channel_2_value[i]
        }
        let avg_channel_2:Double = sum_channel_2/4.0
        
        if let model = device {
            MD_DispatcherCenter.shared.dispatchLTEMGCollectionData(model: model, pelvicData: smooth_channel_1_value, avgPelVic: avg_channel_1, abdData: smooth_channel_2_value, avgAbd: avg_channel_2)
        }
    }
    
    func handleNotifyError(tempByte:[UInt8]) {
        let error = tempByte[4]
        if error == 0x01 {
            NSLog("包头错误")
        } else if error == 0x02 {
            NSLog("数据长度错误")
        } else if error == 0x03 {
            NSLog("命令错误")
        } else if error == 0x04 {
            NSLog("CRC校验错误")
        } else if error == 0x05 {
            NSLog("Block序号错误")
        }
    }
    
    func handleNotifyUpgradeShake(tempByte:[UInt8]) {
        seedByte.removeAll()
        let res = tempByte[4]
        if res == 0x01 {
            // 如果固件在APP层，发送跳转到boot层指令
            self.upgradeBoot()
            if let model = device {
                model.p_upgradeShakeSucess()
                MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeShakeSuccess(model: model)
            }
            self.perform(#selector(upgradeFailure), with: nil, afterDelay: 2.0)
        } else {
            // 固件在boot层，发送索要种子数据指令
            self.upgradeSeed()
        }
    }
    
    func handleNotifyUpgradeBoot(tempByte:[UInt8]) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(upgradeFailure), object: nil)
        let res = tempByte[4]
        if res == 0x01 {
            // 跳转到boot层成功，发送索要种子数据指令
            print("索要种子")
            if seedByte.count == 0 { //已经有种子了,表示已经发送过解密,跳转boot应答会回复两次,导致重复发送解密
                self.upgradeSeed()
            }
        }
        else {
            //TODO:-- 失败，需要重新升级
            self.upgradeFailure()
        }
    }
    
    func handleNotifyUpgradeSeed(tempByte:[UInt8]) {
        seedByte = MD_VerfifyTool.upgradeSecretSeed(tempByte: tempByte)
        self.upgradeKey(seedData: seedByte)
        self.sentKeyAgain = false
    }
    
    func handleNotifyUpgradeKey(tempByte:[UInt8]) {
        let res = tempByte[4]
        if res == 0x01 {
            self.upgradeFlash() // 解密成功
        } else {
            if self.sentKeyAgain {
                self.upgradeFailure() //TODO:-- 再次解密失败,弹窗
            } else {
                self.upgradeKey(seedData: seedByte)
                self.sentKeyAgain = true
            }
        }
        self.sentFlashAgain = false
    }
    
    func handleNotifyUpgradeFlash(tempByte:[UInt8]) {
        let res = tempByte[4]
        if res == 0x01 {
            if let model = device {
                MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeValidSuccess(model: model)
                self.startSendUpgradeData() // 擦除成功，发送升级数据包
            }
        } else {
            // 擦除失败
            if self.sentFlashAgain {
                //TODO:-- 再次擦除失败,需要重新升级
                self.upgradeFailure()
            } else {
                self.upgradeFlash()
                self.sentFlashAgain = true
            }
        }
    }
    func handleNotifyUpgradeData(tempByte:[UInt8]) {
        let res = tempByte[6]
        if res == 0x01 {
            self.sentDataAgain = false
            if self.binDatumIndex >= self.binDatum.count - 1 {
                self.upgradeFinish() //包已经上传完毕
            } else {
                // 成功，发送下一个包
                self.binDatumIndex += 1
                self.upgradeData()
                let progress = CGFloat(self.binDatumIndex) / CGFloat(self.binDatum.count)
                if let model = device {
                    MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeProgress(model: model,progress:progress)
                }
                NSLog("progress====%f",progress)
            }
        } else {
            if self.sentDataAgain {
                //TODO:-- 上报数据失败，需要重新升级
                self.upgradeFailure()
            } else {
                self.sentDataAgain = true
                self.upgradeData()
            }
        }
    }
    
    func handleNotifyUpgradeFinish(tempByte:[UInt8]) {
        let res = tempByte[4]
        if res == 0x01 {
            self.upgradeToAPP()
        } else {
            //TODO:-- 失败，需要重新升级
            self.upgradeFailure()
        }
    }
    
    func handleNotifyUpgradeAPP(tempByte:[UInt8]) {
        let res = tempByte[4]
        if res == 0x01 {
            // 升级成功
            if let model = device {
                MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeSuccess(model: model)
                NSLog("升级成功")
            }
        } else {
            //TODO:-- 失败，需要重新升级
            self.upgradeFailure()
        }
    }
    
    func handleEEPROMData(tempByte:[UInt8], blockType:Lanting2GEPROMBlockType) {
        let deviceModel = device?.deviceM ?? 0xff
        let deviceSerialNumber = device?.serialNumber ?? ""
        if blockType == Lanting2GEPROMBlockType.Model {
            device?.deviceM = tempByte[5]
        } else if blockType == Lanting2GEPROMBlockType.SerialNumber {
            // 产品序列号
            let year = UInt(tempByte[5])
            let tempNo = UInt(tempByte[6]) * 65536 + UInt(tempByte[7]) * 256 + UInt(tempByte[8])
            let serialNumber = MD_BLEDeviceDealTool.getSerialNumber(year: year, number: tempNo)
            self.device?.serialNumber = serialNumber;
        } else if blockType == Lanting2GEPROMBlockType.BuildInScheme {
            NSLog("")
        } else if blockType == Lanting2GEPROMBlockType.ActivationDate {

            if (device?.deviceM == 0xFF) {
                return;
            } else if ((deviceSerialNumber.count) < 5) {
                //TODO:-- 信息不完整，设备故障
                NSLog("信息不完整，设备故障");
                return;
            } else {
                // 激活日期 & 日期数据校验
                let year = tempByte[5]
                let month = tempByte[6]
                let day = tempByte[7]
                let sum = (UInt(year)+UInt(month)+UInt(day)+251)*3;
                let sumInt8 = UInt8(sum % 256)
                if (sumInt8 == tempByte[8]) {
                    let activationDate = String.init(format: "20%lu-%02lu-%02lu", year, month, day)
                    let serNo = String(format: "%lx%@", deviceModel,deviceSerialNumber).uppercased()
                    device?.serialNumber = serNo
                    device?.activationDate = activationDate
                    MD_DispatcherCenter.shared.dispatchLT2rdBleReadEEPROM(device: device ?? MD_BLEModel(), deviceModel: deviceModel, serialNumber: serNo, activationDate: activationDate)
                } else {
                    //TODO:--没有写过,向服务器申请时间,写入当前日期
                    device?.activationDate = nil
                    let serNo = String(format: "%lx%@", deviceModel,deviceSerialNumber).uppercased()
                    device?.serialNumber = serNo
                    MD_DispatcherCenter.shared.dispatchLT2rdBleReadEEPROM(device: device ?? MD_BLEModel(), deviceModel: deviceModel, serialNumber: serNo, activationDate: nil)
                }
                self.reset()
            }
        }
    }
    
    func upgradeBoot() {
        let sendData:Data = MD_LT2G_CommandTool.commandUpgradeBoot();
        device?.writeValueToDevice(data: sendData)
    }
    
    func upgradeSeed() {
        let sendData:Data = MD_LT2G_CommandTool.commandUpgradeSeed();
        device?.writeValueToDevice(data: sendData)
    }
    
    func upgradeKey(seedData:[UInt8]) {
        let sendData:Data = MD_LT2G_CommandTool.commandUpgradeKey(seedData: seedData);
        device?.writeValueToDevice(data: sendData)
    }
    
    func upgradeFlash() {
        let sendData:Data = MD_LT2G_CommandTool.commandUpgradeFlash();
        device?.writeValueToDevice(data: sendData)
    }
    
    func upgradeFinish() {
        let sendData:Data = MD_LT2G_CommandTool.commandUpgradeFinish();
        device?.writeValueToDevice(data: sendData)
    }
    
    func upgradeToAPP() {
        let sendData:Data = MD_LT2G_CommandTool.commandUpgradeAPP();
        device?.writeValueToDevice(data: sendData)
    }
    
    @objc func upgradeFailure() {
        let error:NSError = NSError.init(domain: "固件升级失败", code: 510, userInfo: nil)
        MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeFailure(error: error)
    }
    
    func upgradeData() {
        if self.binDatum.count <= 0 || self.binDatumIndex >= self.binDatum.count{
            self.upgradeFailure()
            return
        }
        let data:[UInt8] = self.binDatum[self.binDatumIndex]
        let blockNum = self.binDatumIndex
        let sendData = MD_LT2G_CommandTool.commandUpgradeData(data: Data.init(data), blockNum: blockNum)
        device?.writeValueToDevice(data: sendData)
    }
    
    func startSendUpgradeData() {
        self.sentDataAgain = false
        self.binDatumIndex = 0
        self.readBinFile()
        self.upgradeData()
    }
    
    
    func readBinFile() {
        
        let path = MD_BLEDeviceDealTool.getLanTingDataPath() + "/lanting2GUpgrade.bin"
        let binData = NSData.init(contentsOfFile: path)
        self.binDatum.removeAll()
       
        
        if let binDataLength = binData?.length {
            let index = binDataLength / 128
            for i in 0...index {
                if i == index {
                    let length = binDataLength % 128
                    var emptyByte:[UInt8] = [UInt8].init(repeating: 0, count: 128-length)
                    for j in 0..<128-length {
                        emptyByte[j] = 0xff
                    }
                    if let packageData = binData?.subdata(with: NSRange.init(location: i*128, length: length)) {
                        var fullData = Data()
                        fullData.append(contentsOf: [UInt8](packageData))
                        fullData.append(contentsOf: [UInt8](NSData.init(bytes: emptyByte, length: emptyByte.count)))
                        binDatum.append([UInt8](fullData))
                    }
                } else {
                    if let packageData = binData?.subdata(with: NSRange.init(location: i*128, length: 128)) {
                        binDatum.append([UInt8](packageData))
                    }
                }
            }
        }
 
    }
    
    func reset() {
        channel_1_Smooth.setSmoothLength(length: 40)
        channel_2_Smooth.setSmoothLength(length: 40)
        receivedData.removeAll()
    }
    
}
