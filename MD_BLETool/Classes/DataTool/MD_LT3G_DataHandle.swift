//
//  MD_LT3G_DataHandle.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/14.
//

import UIKit

class MD_LT3G_DataHandle: NSObject {
    
    private var completeCommandLength:UInt = 15
    private var seedByte:[UInt8] = [UInt8](repeating: 0, count: 4)
    private var startAddress:[UInt8] = [UInt8](repeating: 0, count: 4)
    private var flashSize:Int = 0
    private var sentKeyAgain:Bool = false       // 是否已经再次发送密钥指令
    private var sentFlashAgain:Bool = false     // 是否已经再次发送擦除指令
    private var sentDataAgain:Bool = false      // 是否已经再次发送当前数据包指令
    
    private var hexDatumIndex : Int = 0
    private var hexDatumModel:[MD_HexFileModel] = [MD_HexFileModel]()
    private var hexDatum:[[UInt8]] = [[UInt8]]()    // 升级hex数据
    var hexFirstData:[UInt8] = [UInt8]()  //外部hex升级握手指令使用
    private var calAllCode:[UInt8] = [UInt8]()
    
    var calAllCodeStr = ""

    //平滑工具
    private lazy var channel_1_Smooth : MD_DataSmooth = {
        let t_smooth = MD_DataSmooth()
        t_smooth.setSmoothLength(length: 40)
        return t_smooth
    }()
    private lazy var channel_2_Smooth : MD_DataSmooth = {
        let t_smooth = MD_DataSmooth()
        t_smooth.setSmoothLength(length: 40)
        return t_smooth
    }()
    
    //停止压力采集把他清空
    lazy var pressureValue_Smooth : MD_DataSmooth = {
        let t_smooth = MD_DataSmooth()
        t_smooth.setSmoothLength(length: 40)
        return t_smooth
    }()
    
    /// 设备对象
    private var device : MD_BLEModel?
    
    private var batteryPowerTmpArr:[String] = [String]()
    
    init(bleModel: MD_BLEModel) {
        self.device = bleModel
    }
    
    //数据处理
    var receivedData:[UInt8] = [UInt8]()
    
    @objc func reset() {
        channel_1_Smooth.setSmoothLength(length: 40)
        channel_2_Smooth.setSmoothLength(length: 40)
        pressureValue_Smooth.setSmoothLength(length: 40)
        receivedData.removeAll()
    }
    
    /// 接受数据处理
    @objc func dataHandleDidUpdateValue(data:Data){
        
        //接受到的数据放到数组中
        receivedData.append(contentsOf: [UInt8](data))
        //判断数组个数
        if receivedData.count <= 0 {
            return
        }
        
        var i:Int = 0
        let dataLegth = receivedData.count
        
        while i < dataLegth - 7  {
            
            //如果不是正确的包头，继续往下遍历
            if !isCorrectLT3rdNotifyHeader(head_1: receivedData[i], head_2: receivedData[i+1]) {
                i += 1
                continue
            }
            //定义装整包数据的数组
            var dealForPackageData:[UInt8] = [UInt8]()
            //加入包头
            dealForPackageData.append(receivedData[i])
            dealForPackageData.append(receivedData[i+1])
            
            //采集数据单独处理 没有包的长度
            if receivedData[i+1] == 0xa8 {
                //采集数据
                //特别注意采集数据包，包头和其余的不同，没有数据长度位，该包数据共20个byte，有效数据为16个byte；
                if receivedData.count - i < 20 {
                    return
                }
                for usefulIndex in 2..<20 {
                    dealForPackageData.append(receivedData[i+Int(usefulIndex)])
                }
            }else{
                //非采集数据
                dealForPackageData.append(receivedData[i+2])
                //是正确的包头 先取出包中的数据长度
                let packageLength = receivedData[i+2]
                //判断数据是否能够装有完整的数据包 完整的数据包长度为 packageLength + 2个包头 + 1个包长度 + 2个校验和
                if receivedData.count - i < 5 + packageLength {
                    return
                }
                //根据有效数据的长度，取出包中的数据
                for usefulIndex in 0..<packageLength + 2 {
                    dealForPackageData.append(receivedData[i+Int(usefulIndex)+3])
                }
            }
            
            //校验包中的数据
            if !isCorrectedValueByCRC(data: dealForPackageData) {
                i += 1
                continue
            }
            if isCorrectLT3rdNotifyHeaderForUpgrade(head_1: receivedData[i], head_2: receivedData[i+1]) {
                //校验通过，处理业务数据
                dataHandleByFullPackageForUpgrade(data: dealForPackageData)
            } else {
                //校验通过，处理业务数据
                dataHandleByFullPackage(data: dealForPackageData)
            }
            
            //继续遍历接下来的数据
            i += dealForPackageData.count
        }
        if i > 0 {
            //移除前i个元素
            receivedData.removeFirst(i)
        }
    }
    
    /// 是否是正确的澜渟三代的数据头
    /// - Parameters:
    ///   - head_1: 包头
    ///   - head_2: 包头
    /// - Returns: Bool
    private func isCorrectLT3rdNotifyHeader(head_1:UInt8, head_2:UInt8) -> Bool {
        if head_1 == 0xbb {
            if head_2 == 0xa5 || head_2 == 0xa8 {
                return true
            }
        }
        if head_1 == 0xfe && head_2 == 0xa9{   //hex 升级包头
            return true
        }
        return false
    }
    
    private func isCorrectLT3rdNotifyHeaderForUpgrade(head_1:UInt8, head_2:UInt8) -> Bool {
        if head_1 == 0xfe && head_2 == 0xa9 {   //hex 升级包头
            return true
        }
        return false
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
            for i in 3..<data.count-2{
                validCommand.append(data[i])
            }
        }
        return MD_VerfifyTool.crcVerfifyCode_Check(bytes: validCommand, highCheck: dataCRC_H, lowCheck: dataCRC_L)
    }
    
    
    /// 处理整包数据-hex升级
    /// - Parameter data: 完整的包数据
    private func dataHandleByFullPackageForUpgrade(data:[UInt8]) {
        
        var receivedString:String = ""
        for i in 0..<data.count {
            receivedString.append("\(data[i])" + "  ")
        }
        
        if data[1] == 0xa8 {
        } else {
            //非采集数据
            if let commandTypeNotify:LT_3rdCommandUpgradeNotify = LT_3rdCommandUpgradeNotify(rawValue: data[3]) {
                switch commandTypeNotify {
                case .shakeHand:
                    print("握手反馈=\([UInt8](data))")
                    handleNotifyUpgradeShake(tempByte: data)
                    break
                case .supportUpgrade:
                    print("支持升级反馈=\([UInt8](data))")
                    handleNotifyUpgradeSupport(tempByte: data)
                    break
                case .selectModel:
                    print("selectmodel反馈=\([UInt8](data))")
                    handleNotifySelectModel(tempByte: data)
                case .upgradeBoot:
                    print("upgradeBoot反馈=\([UInt8](data))")
                    handleNotifyUpgradeBoot(tempByte: data)
                case .upgradeSeed:
                    print("upgradeSeed反馈=\([UInt8](data))")
                    handleNotifyUpgradeSeed(tempByte: data)
                case .upgradeKey:
                    print("upgradeKey反馈=\([UInt8](data))")
                    handleNotifyUpgradeKey(tempByte: data)
                case .upgardeAdress:
                    print("upgardeAdress反馈=\([UInt8](data))")
                    handleNotifyUpgradeStartAdress(tempByte: data)
                case .upgardeFlashSize:
                    print("upgardeFlashSize反馈=\([UInt8](data))")
                    handleNotifyUpgradeFlashSize(tempByte: data)
                case .upgradeFlash:
                    print("upgradeFlash反馈=\([UInt8](data))")
                    handleNotifyUpgradeFlash(tempByte: data)
                case .upgradeData:
                    print("upgradeData反馈=\([UInt8](data))")
                    handleNotifyUpgradeData(tempByte: data)
                case .upgradeFinsh:
                    print("upgradeFinsh反馈=\([UInt8](data))")
                    handleNotifyUpgradeFinish(tempByte: data)
                case .upgaradeApp:
                    print("upgaradeApp反馈=\([UInt8](data))")
                    handleNotifyUpgradeAPP(tempByte: data)
                case .wait:
                    print("上位机等待=\([UInt8](data))")
                    handleWaitCommand(tempByte: data)
                }
            }
        }
    }
    
    /// 处理整包数据
    /// - Parameter data: 完整的包数据
    private func dataHandleByFullPackage(data:[UInt8]) {
        
        var receivedString:String = ""
        for i in 0..<data.count {
            receivedString.append("\(data[i])" + "  ")
        }
//        print("3rdReceivedData ----  " + receivedString)
        
        if data[1] == 0xa8 {
            //采集数据
            dataHandleBy_Collection(data: data)
        } else {
            //非采集数据
            if let commandTypeNotify:LT_3rdCommandTypeNotify = LT_3rdCommandTypeNotify(rawValue: data[3]) {
                switch commandTypeNotify {
                case .shakeHand:
                    dataHandleBy_shakeHand(data: data)
                    break
                case .deviceStatus:
                    dataHandleBy_deviceStatus(data: data)
                    break
                case .eppromUpload:
                    dataHandleBy_eppromUpload(data: data)
                    break
                case .stimulatingCurrent:
                    dataHandleBy_stimulatingCurrent(data: data)
                    break
                case .electricalStimulationReceiving:
                    dataHandleBy_electricalStimulationReceiving(data: data)
                    break
                case .electrodeFallOff:
                    dataHandleBy_electrodeFallOff(data: data)
                    break
                case .pressureParameterAdjustment:
                    dataHandleBy_pressureParameterAdjustment(data: data)
                    break
                case .pressureModuleParameterSetting:
                    dataHandleBy_pressureModuleParameterSetting(data: data)
                    break
                case .pressureModuleCollection:
                    dataHandleBy_pressureDataCollection(data: data)
                    break
                case .firmwareVersionCommand:
                    dataHandleBy_Firmversion(data: data)
                    break
                }
            }
        }
    }
    
    
    //MARK: -- 采集数据上传处理
    private func dataHandleBy_Collection(data:[UInt8]) {
        
//        let quotient:Double = 3000000.0 / (4095.0 * 2000.0)
        let quotient:Double = 1
        
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
    
    //MARK: -- 握手信息
    private func dataHandleBy_shakeHand(data:[UInt8]) {
//        //模块型号
        device?.module = MD_BLEDeviceModel.init(rawValue: data[4]) ?? .Device_HD
        device?.isHighEnd = device?.module == .Device_HD
        device?.is2GUp = device?.module == .Device_Two
//        //设备型号
        device?.deviceM = data[5]
//        //硬件版本号
        device?.hardwareVersion = Float(data[6])
//        //固件版本号
        device?.firmwareVersion = Float(data[7])
//        //子版本号
        device?.subversion = Float(data[8])
        //是否是刚开机连接
        device?.isBootConnect = Int(data[9]) == 1
        if let model = device {
            MD_DispatcherCenter.shared.dispatchLT3rdBleShakeSuccess(model: model)
        }
        
    }
    
    //MARK: -- 握手信息
    private func dataHandleBy_Firmversion(data:[UInt8]) {
        let mainFirstV = data[4]
        let mainsubV = data[5]
        let subFirstV = data[7]
        let subSubV = data[8]
        if mainFirstV == 1 {
            device?.mainBoardFirmwareV = String(format: "1.0.%ld", mainsubV)
        } else {
            device?.mainBoardFirmwareV = String(format: "%.1lf.%ld", Float(mainFirstV + 18) * 0.1,mainsubV)
        }
        if subFirstV == 1 {
            device?.subBoardFirmwareV = String(format: "1.0.%ld", subSubV)
        } else {
            device?.subBoardFirmwareV = String(format: "%.1lf.%ld", Float(subFirstV + 18) * 0.1,subSubV)
        }
        
    }
    
    //MARK: -- 状态上传
    private func dataHandleBy_deviceStatus(data:[UInt8]) {
//        if data[2] == 0x0D {
//            //错误状态
//        } else
        if data[2] == 0x09 || data[2] == 0x0D{
            //电池状态。01为电池充满，02为电池欠电，03为电池充电中，04电池放电中；
            
            device?.batteryStatus = MD_BLEDeviceBatteryStatus(rawValue: data[5]) ?? .full
            //锂电池电量AD值
            let batteryPower = Int(data[6])*256 + Int(data[7])
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
            //取平均值
            if (self.batteryPowerTmpArr.count > 0) {
                avgBatteryPower = sumBatteryPower / Float(self.batteryPowerTmpArr.count)
            }
            let batteryFloat = Float(device?.batteryPowerStr ?? "") ?? 0
            if batteryFloat == 0 || (batteryFloat > 0 && batteryFloat >= avgBatteryPower) {
                device?.batteryPowerStr = String(format: "%.f", avgBatteryPower)
            }
//            //主板温度，偏移量为-40°C，即收到100的数值，代表100-40=60°C；
//            device.mainBoardTemperature = 100 - Int(data[8])
//            //工作状态：00待机，01采集(采集不分1/2通道)，02通道1刺激，04通道2刺激，08：抽真空，10：充气；
            device?.workingStatus = MD_BLEDeviceWorkingStatus(rawValue: data[9]) ?? .standby
//            //信号强度RSSI=RSSI_H*256+RSSI_L-1000，单位dBm；
            if let model = device {
                MD_DispatcherCenter.shared.dispatchBLEDeviceDidUpdateBatteryValue(model: model,
                                                                                  batteryValue: model.batteryPower,
                                                                                  batteryStatus: model.batteryStatus)
            }
        }
    }
    //MARK: -- EEPROM块信息上传
    private func dataHandleBy_eppromUpload(data:[UInt8]) {
        let blockNum = data[4]
        var serialNumber = ""
        if blockNum == LT_3rdEEPROMNotify.Lanting3GEEPROMBlockTypeModel.rawValue {
//            let deviceModel = data[5]
//            device?.deviceM = deviceModel
        }
        else if blockNum == LT_3rdEEPROMNotify.Lanting3GEEPROMBlockTypeSerialNumber.rawValue {
            // 产品序列号
            let year = data[5];
            let tempNo = (UInt(data[6]) * 65536) + (UInt(data[7]) * 256) + UInt(data[8]);
            serialNumber = MD_BLEDeviceDealTool.getSerialNumber(year: UInt(year), number: UInt(tempNo))
            serialNumber = (device?.getDevice_modelStr() ?? "") + serialNumber
            device?.serialNumber = serialNumber
        }
        else if blockNum == LT_3rdEEPROMNotify.Lanting3GEEPROMBlockTypeActivationDate.rawValue {
//            if device?.deviceModel == MD_LT_3G_DeviceModel.none {
//                return
//            }
//            else if device?.serialNumber?.count < 5 {
//                return;
//            }
            let year = data[5]
            let month = data[6]
            let day = data[7]
            let sum = (UInt(year)+UInt(month)+UInt(day)+251)*3;
            let sumInt8 = UInt8(sum % 256)
            if sumInt8 == data[8] {
                //有激活日期
                let activationDate:String = String(format: "20%lu-%02lu-%02lu", year, month, day)
                device?.activationDate = activationDate
                //调用实现读取激活日期的代理方法
                MD_DispatcherCenter.shared.dispatchLT3rdBleReadEEPROM(device: device ?? MD_BLEModel(), deviceModel: device?.deviceM ?? 0x00, serialNumber: device?.serialNumber ?? "", activationDate: activationDate)
            } else {
                //TODO:--没有写过,向服务器申请时间,写入当前日期
                device?.activationDate = nil
                MD_DispatcherCenter.shared.dispatchLT3rdBleReadEEPROM(device: device ?? MD_BLEModel(), deviceModel: device?.deviceM ?? 0x00, serialNumber: device?.serialNumber ?? "", activationDate: nil)
            }
        }
        
        
        
    }
    
    //MARK: -- 刺激电流反馈
    private func dataHandleBy_stimulatingCurrent(data:[UInt8]) {
        var channel = ChannelType.first
        if data[4] == ChannelType.first.rawValue {
            device?.electricity_channel1 = (Double(data[5])*256 + Double(data[6]))
        } else if data[4] == ChannelType.second.rawValue {
            device?.electricity_channel2 = (Double(data[5])*256 + Double(data[6]))
            channel = .second
        }
        if let model = device {
            MD_DispatcherCenter.shared.dispatchBLEDeviceDidUpdateElectricity(model: model,
                                                                             val_channel1: model.electricity_channel1,
                                                                             val_channel2: model.electricity_channel2,channel: channel)
        }
    }
    //MARK: -- 电刺激接收数据反馈
    private func dataHandleBy_electricalStimulationReceiving(data:[UInt8]) {
//        byte4：数据范围：0~1，代表通道1~2；
//        byte5：电刺激指令。00：未知指令，01：定频电刺激指令，02：变频电刺激指令，03：中频电刺激指令，10：电刺激停止指令，11：电刺激紧急停止指令；
//        byte6：电刺激开始停止状态。01：电刺激指令执行成功(byte7/byte8为00)，02：电刺激指令执行失败(失败原因见byte7/byte8参数说明)；
//        byte7：参数说明H:00：正常，01：脉宽参数异常，02：频率参数异常，04：电流参数异常，08：波形极性参数异常，10：交替参数异常，20：上升时间参数异常，40：下降时间参数异常，80：变频时间参数异常；
//        byte8：参数说明L:00：正常，01：爆发工作时间参数异常，02：爆发休息时间参数异常；
//        byte9：预留，数据填充；
        if data[4] == ChannelType.first.rawValue {
        } else if data[4] == ChannelType.second.rawValue {
        }
    }
    //MARK: --  电极脱落反馈
    private func dataHandleBy_electrodeFallOff(data:[UInt8]) {
        if data[4] == ChannelType.first.rawValue {
            device?.channel_1_electrodeFallOff = true
        } else if data[4] == ChannelType.second.rawValue {
            device?.channel_2_electrodeFallOff = true
        }
        if let model = device {
            MD_DispatcherCenter.shared.dispatchBLEDeviceElectrodeDidFallOff(model: model, channel1_fall: model.channel_1_electrodeFallOff, channel2_fall: model.channel_2_electrodeFallOff)
        }
        
    }
    //MARK: -- 压力参数调节实时反馈
    private func dataHandleBy_pressureParameterAdjustment(data:[UInt8]) {
        device?.pressureVal = Int(data[4])*256 + Int(data[5])
    }
    //MARK: -- 21 压力模块参数设定反馈
    private func dataHandleBy_pressureModuleParameterSetting(data:[UInt8]) {
        let pressureWorkStatus:LT3rdPressureWorkStatus = LT3rdPressureWorkStatus(rawValue: data[4]) ?? .none
        device?.pressureWorkedStatus = pressureWorkStatus
    
    }
    //MARK: -- 21 压力模块采集数据反馈
    private func dataHandleBy_pressureDataCollection(data:[UInt8]) {
        //压力值参数范围0~30000，代表0~300mmHg，精度0.01mmHg，单位换算100kPa≈750mmHg；
        let mmHgValue:Double = 0.01
        
        // 压力信号数据采集
        var original_pressure_value:[Double] = [Double](repeating: 0, count: 4)
        original_pressure_value[0] = (Double(data[4])*256 + Double(data[5])) * mmHgValue
        original_pressure_value[1] = (Double(data[6])*256 + Double(data[7])) * mmHgValue
        original_pressure_value[2] = (Double(data[8])*256 + Double(data[9])) * mmHgValue
        original_pressure_value[3] = (Double(data[10])*256 + Double(data[11])) * mmHgValue
        
        //压力数据，取平均值
        var pressure_Smooth_Value:[Double] = [Double](repeating: 0, count: 4)
        var sum_pressure_value:Double = 0
        for i in 0...3 {
            pressure_Smooth_Value[i] = pressureValue_Smooth.smoothData(data: original_pressure_value[i])
            if pressure_Smooth_Value[i] < 0 {
                pressure_Smooth_Value[i] = 0
            }
            sum_pressure_value += pressure_Smooth_Value[i]
        }
        let avg_pressure_value:Double = sum_pressure_value/4.0
        
        if let model = device {
            MD_DispatcherCenter.shared.dispatchLT3rdDevicePressureCollectData(model: model,
                                                                              pressureData: pressure_Smooth_Value,
                                                                              avgPressure: avg_pressure_value)
        }
    }
    
    
    ///MCU握手成功
    func handleNotifyUpgradeShake(tempByte:[UInt8]) {
/*
        let res = tempByte[4]
        if res == 0x01 {
            //选择模块
            self.upgradeSelectModel()
            self.perform(#selector(upgradeShakeFailure), with: nil, afterDelay: 2.0)
        } else {
            //不支持升级
            self.upgradeShakeFailure()
        }*/
        
        if let model = device {
            model.p_upgradeShakeSucess()
        }
    }

        
    ///
    func handleNotifyUpgradeSupport(tempByte:[UInt8]) {
        //选择模块
        self.upgradeSelectModel()
        self.perform(#selector(upgradeShakeFailure), with: nil, afterDelay: 3.0)
        if let model = device {
            model.p_upgradeShakeSucess()
        }
    }
    
    
    func handleNotifySelectModel(tempByte:[UInt8]) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeShakeFailure), object: nil)
        let res = tempByte[7]
        if res == 0x01 {
            // 如果固件在APP层，发送跳转到boot层指令
            self.upgradeBoot()
            
            self.perform(#selector(upgradeFailure), with: nil, afterDelay: 3.0)
        } else {
            //不支持升级
            self.upgradeShakeFailure()
        }
    }
    
    func handleNotifyUpgradeBoot(tempByte:[UInt8]) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeFailure), object: nil)
        let res = tempByte[7]
        if res == 0x00 {
            // 跳转到boot层成功，发送索要种子数据指令
            self.upgradeSeed()
            
            self.perform(#selector(upgradeFailure), with: nil, afterDelay: 3.0)
        } else {
            //跳转失败
            self.upgradeShakeFailure()
        }
    }
    
    func handleNotifyUpgradeSeed(tempByte:[UInt8]) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeFailure), object: nil)
        seedByte = MD_VerfifyTool.upgradeSecretSeed(tempByte: tempByte)  //8F 06 02 6F
        self.sentKeyAgain = false
        self.upgradeKey()
       //加上重发的3s
        self.perform(#selector(upgradeFailure), with: nil, afterDelay: 6.0)
    }
    
    func handleNotifyUpgradeKey(tempByte:[UInt8]) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeFailure), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeKey), object: nil)
        self.sentKeyAgain = false
        let res = tempByte[7]
        if res == 0x01 {
            self.upgradeStartAddress()// 解密成功,发送起始地址
            self.perform(#selector(upgradeFailure), with: nil, afterDelay: 3.0)
        } else {
            self.upgradeFailure() //TODO:-- 再次解密失败,弹窗
        }
    }
    
    func handleNotifyUpgradeStartAdress(tempByte:[UInt8]) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeFailure), object: nil)
        let res = tempByte[7]
        if res == 0x01 {
            //发送地址成功,发送字节数
            self.upgradeFlashSize()
            self.perform(#selector(upgradeFailure), with: nil, afterDelay: 3.0)
        } else {
            self.upgradeFailure()
        }
    }
    
    func handleNotifyUpgradeFlashSize(tempByte:[UInt8]) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeFailure), object: nil)
        self.sentFlashAgain = false
        let res = tempByte[7]
        if res == 0x01 {
            self.upgradeFlash()
            self.perform(#selector(upgradeFailure), with: nil, afterDelay: 6.0)
        } else {
            self.upgradeFailure()
        }
    }
    
    func handleNotifyUpgradeFlash(tempByte:[UInt8]) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeFailure), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeFlash), object: nil)
        self.sentFlashAgain = false
        let res = tempByte[7]
        if res == 0x01 {
            if let model = device {
                MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeValidSuccess(model: model)
                // 擦除成功，发送升级数据包
                self.startSendUpgradeData()
            }
        } else {
            self.upgradeFailure()
        }
    }
    
    func handleNotifyUpgradeData(tempByte:[UInt8]) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeFailure), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeData), object: nil)
        self.sentDataAgain = false
        let res = tempByte[7]
        if res == 0x00 {
            //累加校验
            print("hexIndex\(self.hexDatumIndex)")
            if self.hexDatumIndex >= self.hexDatum.count - 1 {
                self.upgradeFinish() //包已经上传完毕
                self.perform(#selector(upgradeFailure), with: nil, afterDelay: 3.0)
            } else {
                // 成功，发送下一个包 ,需要延时200ms
                Thread.sleep(forTimeInterval: 0.2)
                self.hexDatumIndex += 1
                self.upgradeData()
                let progress = CGFloat(self.hexDatumIndex+1) / CGFloat(self.hexDatum.count)
                if let model = device {
                    MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeProgress(model: model,progress:progress)
                }
                self.perform(#selector(upgradeFailure), with: nil, afterDelay: 6)
                NSLog("progress====%f",progress)
            }
        } else {
            self.upgradeFailure()
        }
    }
    
    func handleNotifyUpgradeFinish(tempByte:[UInt8]) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeFailure), object: nil)
        let res = tempByte[7]
        if res == 0x00 {
            self.upgradeToAPP()
            self.perform(#selector(upgradeFailure), with: nil, afterDelay: 3.0)
        } else {
            //TODO:-- 失败，需要重新升级
            self.upgradeFailure()
        }
    }
    
    func handleNotifyUpgradeAPP(tempByte:[UInt8]) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeFailure), object: nil)
        let res = tempByte[7]
        if res == 0x00 {
            // 升级成功
            if let model = device {
                if device?.isHexUpgradeSuccess ?? false {
                    MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeProgress(model: model,progress:1.0)
                    MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeSuccess(model: model)
                    NSLog("升级成功")
                }
            }
        } else {
            //TODO:-- 失败，需要重新升级
            if device?.isHexUpgradeSuccess ?? false {
                self.upgradeFailure()
            }
        }
    }
    
    func handleWaitCommand(tempByte:[UInt8]) {
        let time = tempByte[7]
        let waitT = Double(time) * 0.1
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.upgradeFailure), object: nil)
        self.perform(#selector(upgradeFailure), with: nil, afterDelay: 3.0 + waitT)
    }
    
    
    //发送指令
    func upgradeSelectModel() {
        
        let sendData:Data = MD_LT3G_CommandTool.commandUpgradeSeletModelHand();
        device?.writeValueToDevice(data: sendData)
    }
    
    func upgradeBoot() {
        let sendData:Data = MD_LT3G_CommandTool.commandUpgradeBoot();
        print("writeValue = \([UInt8](sendData))")
        device?.writeValueToDevice(data: sendData)
    }
    
    func upgradeSeed() {
        let sendData:Data = MD_LT3G_CommandTool.commandUpgradeSeed();
        device?.writeValueToDevice(data: sendData)
    }
    
    //解密需要重发
    @objc func upgradeKey() {
        let sendData:Data = MD_LT3G_CommandTool.commandUpgradeKey(seedData: seedByte);
        device?.writeValueToDevice(data: sendData)
        
        if !self.sentKeyAgain {
            self.perform(#selector(self.upgradeKey), with: nil, afterDelay: 3)
            self.sentKeyAgain = true
        }
        
    }
    
    func upgradeStartAddress() {
        let sendData:Data = MD_LT3G_CommandTool.commandUpgradeStartAddress(seedData: self.startAddress);
        print("发送起始地址")
        print(sendData)
        device?.writeValueToDevice(data: sendData)
    }
    
    func upgradeFlashSize() {
        let crc1 :UInt8 = UInt8(0xff & (((self.flashSize >> 8) >> 8) >> 8))
        let crc2 :UInt8 = UInt8(0xff & ((self.flashSize >> 8) >> 8))
        let crc3:UInt8 = UInt8(0xff & (self.flashSize >> 8))
        let crc4:UInt8 = UInt8(0xff & self.flashSize)
        let arrayCRC:[UInt8] = [crc1,crc2,crc3,crc4]
        
        let sendData:Data = MD_LT3G_CommandTool.commandUpgradeFlashSize(seedData: arrayCRC);
        device?.writeValueToDevice(data: sendData)
    }
    
    //擦除需要重发
    @objc func upgradeFlash() {
        let sendData:Data = MD_LT3G_CommandTool.commandUpgradeFlash();
        device?.writeValueToDevice(data: sendData)
        
        if !self.sentFlashAgain {
            self.perform(#selector(self.upgradeFlash), with: nil, afterDelay: 3)
            self.sentFlashAgain = true
        }
    }
    
    func upgradeFinish() {
        let calData = MD_VerfifyTool.upgradeCalAllCode(tempByte: self.calAllCode)
        let sendData:Data = MD_LT3G_CommandTool.commandUpgradeFinish(calData:calData);
        device?.writeValueToDevice(data: sendData)
        //AA A7 05 11 00 18 8E A8 1A 3C
    }
    
    func upgradeToAPP() {
        device?.isHexUpgradeSuccess = true;
        let sendData:Data = MD_LT3G_CommandTool.commandUpgradeAPP()
        device?.writeValueToDevice(data: sendData)
    }
    
    @objc func upgradeFailure() {
        self.sentKeyAgain = false
        self.sentFlashAgain = false
        self.sentDataAgain = false
        let error:NSError = NSError.init(domain: "固件升级失败", code: 510, userInfo: nil)
        MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeFailure(error: error)
    }
    
    @objc func upgradeShakeFailure() {
//        let error:NSError = NSError.init(domain: "握手失败", code: 510, userInfo: nil)
        MD_DispatcherCenter.shared.dispatchUpgradeShakeFailure()
    }
    
    @objc func upgradeData() {
        if self.hexDatum.count <= 0 {
            return
        }
        let data:[UInt8] = self.hexDatum[self.hexDatumIndex]
        let blockNum = self.hexDatumIndex
        let sendData = MD_LT3G_CommandTool.commandUpgradeData(data: data, blockNum: blockNum)
        device?.writeValueToDevice(data: sendData)
        
        if !self.sentDataAgain {
            self.perform(#selector(self.upgradeData), with: nil, afterDelay: 3)
            self.sentDataAgain = true
        } else {
            print("重发了一次数据")
        }
    }
    
    @objc func startSendUpgradeData() {
        self.sentDataAgain = false
        self.hexDatumIndex = 0
        self.upgradeData()
        
        self.perform(#selector(upgradeFailure), with: nil, afterDelay: 6)
    }
    
    
    func readHexFile() {

        let path = MD_BLEDeviceDealTool.getLanTingDataPath() + "/lantingUpgradeHex.hex"
        self.startAddress.removeAll()
        self.hexDatumModel.removeAll()
        self.hexDatum.removeAll()
        
        //处理包数据一包128
        var upgradeFullStr = ""
        self.calAllCodeStr = ""
        self.calAllCode.removeAll()
        
        do {
            let hexS =  try String(contentsOfFile: path)
            if !hexS.hasPrefix(":") {
                return
            }
            let hexStr = hexS.replacingOccurrences(of: "\r\n", with: "")
            var hexList = hexStr.components(separatedBy: ":")
            hexList.removeFirst()
            for (i,hexLine) in hexList.enumerated() {
                if i == 0 {    //第一行特殊处理
                    self.hexFirstData.removeAll()
                    if hexLine.count > 8 {
                        let pointString = (hexLine as NSString).substring(with: NSRange(location: hexLine.count - 8, length: 8))
                        for k in stride(from: 0, to: pointString.count, by: 2) {
                            if k + 1 < pointString.count { //防止越界
                                let hStr = (pointString as NSString).substring(with: NSRange(location: k, length: 2))
                                let hHex = UInt(hStr,radix: 16) ?? 0
                                self.hexFirstData.append(UInt8(hHex))
                            }
                        }
                    }
                    
                    continue
                }
                let model = MD_HexFileModel.init()
                if i == 1 || i == 2 {
                    var pointString = ""
                    if i == 1 {
                        if hexLine.count > 11 {
                            pointString = (hexLine as NSString).substring(with: NSRange(location: 8, length: 4))
                        }
                    } else {
                        if hexLine.count > 5 {
                            pointString = (hexLine as NSString).substring(with: NSRange(location: 2, length: 4))
                        }
                    }
                    for k in stride(from: 0, to: pointString.count, by: 2) {
                        if k + 1 < pointString.count { //防止越界
                            let hStr = (pointString as NSString).substring(with: NSRange(location: k, length: 2))
                            let hHex = UInt(hStr,radix: 16) ?? 0
                            self.startAddress.append(UInt8(hHex))
                        }
                    }
                }
                if i == 1 {
                    continue
                }
               
                if hexLine.count >= 11 {
                    model.length = (hexLine as NSString).substring(with: NSRange(location: 0, length: 2))
                    model.offSet = (hexLine as NSString).substring(with: NSRange(location: 2, length: 4))
                    model.type = (hexLine as NSString).substring(with: NSRange(location: 6, length: 2))
                    if model.type == "05" || model.type == "01" { //不处理01类型的数据
                        continue
                    }
                    let lengthInt = self.hexadecimalToDecimal(hexS: model.length)
                    if lengthInt > 0 {
                        model.data = (hexLine as NSString).substring(with: NSRange(location: 8, length: lengthInt * 2))
                    }
                    self.hexDatumModel.append(model)
                    upgradeFullStr.append(model.data)
                    if model.type == "00" {
                        self.calAllCodeStr.append(contentsOf: model.data)
                    }
                }
            }
            
        
            for k in stride(from: 0, to: self.calAllCodeStr.count, by: 2) {
                if k + 1 < self.calAllCodeStr.count { //防止越界
                    let hStr = (self.calAllCodeStr as NSString).substring(with: NSRange(location: k, length: 2))
                    let hHex = UInt(hStr,radix: 16) ?? 0
                    self.calAllCode.append(UInt8(hHex))
                }
            }
            
            self.flashSize = upgradeFullStr.count / 2
            //每两个两位数作为一个字节
            let index = upgradeFullStr.count / 256  // /2/128
            var validCommand:[UInt8] = [UInt8]()
            for i in 0...index {
                validCommand.removeAll()
                if i == index {  //最后一个余数
                    let length = upgradeFullStr.count % 256
                    var emptyByte:[UInt8] = [UInt8].init(repeating: 0, count: 128-(length / 2))
                    for j in 0..<128-(length / 2) {
                        emptyByte[j] = 0xff
                    }
                    let pointString = (upgradeFullStr as NSString).substring(with: NSRange(location: i * 256, length: length))
                    for k in stride(from: 0, to: pointString.count, by: 2) {
                        if k + 1 < pointString.count { //防止越界
                            let hStr = (pointString as NSString).substring(with: NSRange(location: k, length: 2))
                            let hHex = UInt(hStr,radix: 16) ?? 0
                            validCommand.append(UInt8(hHex))
                        }
                    }
                    validCommand.append(contentsOf: emptyByte)
                    self.hexDatum.append(validCommand)
                } else {
                    let pointString = (upgradeFullStr as NSString).substring(with: NSRange(location: i * 256, length: 256))
                    for k in stride(from: 0, to: pointString.count, by: 2) {
                        if k + 1 < pointString.count { //防止越界
                            let hStr = (pointString as NSString).substring(with: NSRange(location: k, length: 2))
                            let hHex = UInt(hStr,radix: 16) ?? 0
                            validCommand.append(UInt8(hHex))
                        }
                    }
                    self.hexDatum.append(validCommand)
                }
            }
            device?.hexFirstData = self.hexFirstData
          
        } catch {
            //读取文件失败
        }
        
    }
    
    
    
    func hexadecimalToDecimal(hexS:String) -> Int {
        let str = hexS.uppercased()
        var sum = 0
        for i in str.utf8 {
            // 0-9 从48开始
            sum = sum * 16 + Int(i) - 48
            // A-Z 从65开始，但有初始值10，所以应该是减去55
            if i >= 65 {
                sum -= 7
            }
        }
        return sum
    }
    
}
