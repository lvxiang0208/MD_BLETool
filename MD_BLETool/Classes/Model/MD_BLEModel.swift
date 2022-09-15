//
//  MD_BLEModel.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/15.
//

import UIKit
import CoreBluetooth

/// 设备类型
@objc enum MD_DeviceType:Int {
    case lt_1G = 0 //一代
    case lt_2G = 1 //二代
    case lt_other = 3 //三代
    case wxck = 4  //无线场康
    case none = 5  //未知
}

/// 设备蓝牙信号
@objc enum MD_BLERSSILEVEL:Int {
    case full = 1  //信号满格
    case strong //信号强
    case middle //信号中等
    case weak //信号弱
    case lost //失去连接
}

/*
/// 设备型号
@objc enum MD_LT_1G_DeviceModel: UInt8 {
    case none = 0  //无
    case all = 1   //全功能版
    case a0 = 2    //MLD A0 最早上市型号
    case h1s = 3   //只有电刺激
    case h1t = 4   //只有电刺激
    case h2s = 5   //只有Kegel
    case h2t = 6   //只有Kegel
    case h3s = 7   // 线上医疗版本
    case h3t = 8   // 线下医疗版本
    case hc = 9    //盆底肌肉训练仪-经典款  只有电刺激
    case ht = 10    //盆底肌肉训练仪-紧致款  只有Kegel
    case hl = 11    //盆底肌肉训练仪-尊享款
}

@objc enum MD_LT_2G_DeviceModel: UInt8 {
    case none = 0xFF // 无
    case pl10 = 0xA1 // 芝兰玉叶PL10
    case pl20 = 0xA2 // 芝兰玉叶PL20
    case pl21 = 0xA3 // 芝兰玉叶PL21
    case pl22 = 0xA4 // 芝兰玉叶PL22
    case pl36 = 0xA5 // 芝兰玉叶PL36
    case pm60 = 0xB1 // 缪斯PM60
    case pm70 = 0xB2 // 缪斯PM70
    case pq80 = 0xB3 // 缪斯PQ80
    case pq88 = 0xB4 // 缪斯PQ88
    case pl16 = 0xA6 // 芝兰玉叶PL16
    case pl26 = 0xA7 // 芝兰玉叶PL26
    case pl56 = 0xA8 // 芝兰玉叶PL56
    case pf88 = 0xC5 // PF88
    case pf68 = 0xC6 // PF68
    case pf78 = 0xC7 // PF78
    case pf98 = 0xC8 // PF98
    case pf01 = 0xF1 // f1
}

@objc enum MD_LT_3G_DeviceModel: UInt8 {
    case none = 0xFF //   //FF
//    case TwoGen = 0xC1  //新二代
    case HA30 = 0xF3  // 低端  F3
    case HD30 = 0xD3 // 高端  //D3
//    case none = 0xF3 //  先写死
}
*/

/// 设备电量
@objc enum MD_BLEDeviceBatteryStatus: UInt8 {
    case full = 0x01 //01为电池充满
    case underCharged = 0x02 //02为电池欠电
    case isCharging = 0x03 //03为电池充电中
    case isDischarging = 0x4 //04电池放电中
}

/// 设备电量
@objc enum MD_BLEDeviceBatteryLevel: UInt8 {
    case kBatteryLevel_One = 0
    case kBatteryLevel_Two = 1
    case kBatteryLevel_Three = 2
    case kBatteryLevel_Four = 3
    case kBatteryLevel_Five = 4
    case kBatteryLevel_Six = 5
}

//通道类型
@objc enum ChannelType:UInt8 {
    case first = 0x00 //1通道
    case second = 0x01  //2通道
}

@objc enum MD_BLEDeviceModel : UInt8 {
    case Device_One = 0x01 //澜渟1代
    case Device_Two = 0x02 //澜渟2代
    case Device_HA = 0x03 //澜渟3代低端
    case Device_HD  = 0x04 //澜渟3代高端
    case Device_KegelBall  = 0x10 //智能凯格尔球
}

@objc enum LT3rdPressureWorkStatus:UInt8 {
    case none = 0x00 //初始化 无状态
    case inflationStart = 0x01 //01开始充气，
    case inflationing = 0x02 //02充气中，
    case inflationOver = 0x03 //03充气结束，
    case inflationFail = 0x04 //04充气失败(失败原因见byte5)，
    case vacuumizeStart = 0x10 //10开始抽真空，
    case vacuumizeing = 0x11 //11抽真空中，
    case vacuumizeOver = 0x12 //12抽真空结束，
    case vacuumizeFail = 0x13 //13抽真空失败
}

@objc enum MD_BLEDeviceWorkingStatus : UInt8 {
    case standby = 0x00 //待机
    case collection = 0x01 //采集
    case stim = 0x02 //刺激
    case warming  = 0x3 //加热
    case warmEnd   = 0x4 //加热结束
    case upgradeOnline  = 0x5 //在线升级
    case infliate = 0x10  //充气
}

let lantingOldCharacteristicsWrite = "00001C01-D102-11E1-9B23-000efB0000A5"
let lanting1GCharacteristicsUUIDWrite = "FF01"
let lanting2GCharacteristicsUUIDWrite = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"


class MD_BLEModel: NSObject, MD_BLEHeartBeatDelegate {
    
    /// 数据处理对象
    @objc var dataHandle1G : MD_LT1G_DataHandle?
    
    /// 数据处理对象
    @objc var dataHandle2G : MD_LT2G_DataHandle?
    
    /// 数据处理对象
    @objc var dataHandle3G : MD_LT3G_DataHandle?
    
    @objc var lt_deviceModel : String {
        get {
            //1代型号是10进制
            if self.deviceType == .lt_1G {
                return String(format: "%ld", self.deviceM)
            }
            return String(format: "%lx", self.deviceM)
        }
    }
    
    //升级成功或者失败否会跳转到App,防止升级假成功
    //是否发送过ToAPP指令,true 升级成功,false 升级失败
    @objc var isHexUpgradeSuccess = false
    
    //三代计时开始
    @objc var isTrainStart  = false
    
    //设备是否准备好了:读取设备参数成功
    @objc var isReady = false
    
    @objc var startCollectCommand = false
    
    var writeCharacter : CBCharacteristic?

    lazy var heartBeat :MD_BLEHeartBeat = {
        let hb = MD_BLEHeartBeat()
        hb.delegate = self
        return hb
    }()
    
    //电流调节倍数  1代2代1倍数  1代医疗2倍  3代 10倍
    @objc var electricityMultiple : Double {
        get {
            if self.deviceType == .lt_other {
                return 10
            } else if self.deviceType == .lt_1G {
                return 1
            }
            else {
                if self.is2GUp {
                    return 10
                }
                return 1
            }
        }
    }
    
    //支持功能列表
    @objc var support_function = [NSString]()
    //支持方案类型列表
    @objc var support_course_code = [NSString]()
    @objc var is_medical = 0  //是否是医疗设备
    @objc var isShowScore : Bool = false
    @objc var maxMuscleForceValue: CGFloat = 0
    @objc var minMuscleForceValue : CGFloat = 0
    @objc var maxPressureForceValue: CGFloat = 0
    @objc var minPressureForceValue: CGFloat = 0
    /** 是否具有压力生物反馈技术【判断是否具有气囊的接入口】*/
    @objc var isPressureCollect:Bool = false
    /// 是否是评估【肌电的标准评估6分17秒】
    @objc var isAssessType : Bool = false
    @objc var isPressureAssess : Bool = false
    @objc var max_electricity : Int = 0
    @objc var isSuppotEMGStim : Bool = false
    
    @objc var isSuppotAbdominal : Bool = false
    @objc var isSuppotHeat = false
    /// 是否提示过低电量提示 %20
    @objc var hasAlertLowBattery = false
    @objc var readEEPROMTimes = 3
    
    @objc var upgradeShakeTimes = 5
    @objc var isUpgrading = false
    /** 是否是开机第一次连接 true 回到首页 */
    @objc var isBootConnect = false
    //boot版本
    @objc var hardwareVersion : Float = 0
//        //固件版本号
    @objc var firmwareVersion : Float = 0
//        //子版本号
    @objc var subversion : Float = 0
    
    //根据训练手动发送心跳
    @objc var useManualHeatBeat = false
    
    //主板固件版本号/zip
    @objc var mainBoardFirmwareV : String = ""
    //从板固件版本号/hex
    @objc var subBoardFirmwareV : String = ""
    
    // 阴道电极状态
    @objc var vagina:LTElectrodeStatus = .Unknow
    
    //腹肌电极状态
    @objc var abdominalElectrodeStatus:LTElectrodeStatus = .Unknow
    
    /// 外设对象
    @objc var peripheral:CBPeripheral?
    
    /// 搜索到的服务
    var services:[CBService] = [CBService]()
    
    /// 搜索到的特征值
    var characteristices:[CBCharacteristic] = [CBCharacteristic]()
    
    /// 信号值
    @objc var rssiValue:Int = -1
    
    /// 信号等级
    @objc var rssiLevel: MD_BLERSSILEVEL = .lost
    
    /// 设备类型
    @objc var deviceType: MD_DeviceType = .lt_1G
    
    /// 电池状态。01为电池充满，02为电池欠电，03为电池充电中，04电池放电中；
    @objc var batteryStatus:MD_BLEDeviceBatteryStatus = .full
    
    @objc var workingStatus:MD_BLEDeviceWorkingStatus = .standby
    
    /// 锂电池电量AD值 原始值；
    @objc var batteryPower:Int = 0
    /// 电池电量百分比
    @objc var batteryPowerStr = ""

    //电池图标
    @objc var batteryLevel: MD_BLEDeviceBatteryLevel {
        get {
            return MD_BLEDeviceDealTool.CalculationBatteryLevel(Double(batteryPowerStr) ?? 0)
        }
    }
    
    /// 设备序列号
    @objc var serialNumber : String?
    
    /// 设备激活日期
    @objc var activationDate : String?
    
    //服务器返回的激活日期
    @objc var serverActionDate:String?
    
    //腹肌通道 二代
    @objc var absChannel : LT2GAbsChannel {
        get {
            if self.isSuppotAbdominal {
                return .Access
            }
            return .NoAccess
        }
    }
    
    @objc var is2GUp:Bool = false
    
    /// 当前电流值 - 1代&2代
    @objc var electricity:Int = 0
    //是否需要强制关机 - 1代
    @objc var isForcedShutdown:Bool = false
    
    //是否是三代高端 - 三代
    @objc var isHighEnd = false
    //模块型号 - 三代
    @objc var module : MD_BLEDeviceModel = .Device_HA
    /// 当前通道1电流 - 三代
    @objc var electricity_channel1 : Double = 0
    /// 当前通道2电流 - 三代
    @objc var electricity_channel2 : Double = 0
    /// 通道1电极脱落 - 三代
    @objc var channel_1_electrodeFallOff:Bool = false
    /// 通道2电极脱落 - 三代
    @objc var channel_2_electrodeFallOff:Bool = false
    /// 压力值 - 三代
    @objc var pressureVal:Int = 0
    //压力工作状态 - 三代
    @objc var pressureWorkedStatus:LT3rdPressureWorkStatus = .none
    
    //新二代hex升级第一行数据处理
    var hexFirstData:[UInt8] = [UInt8]()
    
    
    ///设备型号原始数据
    var deviceM :UInt8 = 0
    
    /// 接收数据同步锁
    private var receivedLock:NSLock = NSLock()
    
    /// 发送数据同步锁
    private var sendLock:NSLock = NSLock()
    
    private var activationYear:Int = 0
    private var activationMonth:Int = 0
    private var activationDay:Int = 0
    
    //获取信息
    @objc func getDevice_type() -> String { return "" }
    
    ///eg. MD PL-36  MLD A0
    @objc func getDevice_model() -> String {  return "" }
    
    ///eg. PL36 A0
    @objc func getDevice_modelShort() -> String {  return "" }
    
    ///eg. A0 , 10
    @objc func getDevice_modelStr() -> String { return "" }
    
    //序列号
    @objc func getSerialNumber() -> String { return "" }
    ///A5-系列号
    
    @objc func getModelAndSerialNumnber() -> String { return "" }
    
    /// MD_BLEHeartBeat Delegate
    //心跳保持
    func bleHeartBeatKeep(_ heartBeat: MD_BLEHeartBeat) {
        if deviceType == .lt_1G {
            let data = MD_LT1G_CommandTool().commandHeartBeat1G()
            self.writeValueToDevice(data: data)
        } else if deviceType == .lt_2G {
            let data = MD_LT2G_CommandTool.commandHeartBeat()
            self.writeValueToDevice(data: data)
        } else if deviceType == .lt_other {
            let data = MD_LT3G_CommandTool.commadnCheckDeviceStatus(hzType: .hz_50, highPassFilter: 20, lowPassFilter: 500, dogUse: .startUp)
            self.writeValueToDevice(data: data)
        }
    }
    
    //心跳结束
    func bleHeartBeatOver(_ heartBeat: MD_BLEHeartBeat) {}
    
    
    /// 初始化DataHandle对象  子类实现
    func initDataHandle(){}
    
    
    //二代握手成功 //三代握手成功
     func bleShakeSuccess() {
         //读取固件版本号
         //新的协议从握手中获取型号,吧读型号改成读取主板和从板的固件版本
        self.heartBeat.heartBeat()
        self.readEEPROMTimes = 3
        self.perform(#selector(readEEPROM), with: nil, afterDelay: 2.0)
    }
    
    
    /// 从EPPROM中读取型号 序列号 激活日期
    @objc func readEEPROM(){
        if self.readEEPROMTimes <= 0 {
            let error = NSError.init(domain: "设备异常", code: 500, userInfo: nil)
            MD_BLEConnectManager.shared.cancelAllConnectPeripheral()
            MD_DispatcherCenter.shared.dispatchBLEConnectManagerDidFailToConnect(peripheral: self.peripheral!, error: error)
            return
        }
        if deviceType == .lt_1G {
            let modelData = MD_LT1G_CommandTool().commandReadEEPROM1G(commandType: .Model)
            self.writeValueToDevice(data: modelData)
            let snData = MD_LT1G_CommandTool().commandReadEEPROM1G(commandType: .SerialNumber)
            self.writeValueToDevice(data: snData)
            let dateData = MD_LT1G_CommandTool().commandReadEEPROM1G(commandType: .ActivationDate)
            self.writeValueToDevice(data: dateData)
            self.perform(#selector(readEEPROM), with: nil, afterDelay: 2.0)
            self.readEEPROMTimes -= 1
        } else if deviceType == .lt_2G {
            let modelData = MD_LT2G_CommandTool.readEPPROM(blockNum: .Model)
            self.writeValueToDevice(data: modelData)
            Thread.sleep(forTimeInterval: 0.2)
            let snData = MD_LT2G_CommandTool.readEPPROM(blockNum: .SerialNumber)
            self.writeValueToDevice(data: snData)
            Thread.sleep(forTimeInterval: 0.2)
            let dateData = MD_LT2G_CommandTool.readEPPROM(blockNum: .ActivationDate)
            self.writeValueToDevice(data: dateData)
            self.perform(#selector(readEEPROM), with: nil, afterDelay: 2.0)
            self.readEEPROMTimes -= 1
        } else if deviceType == .lt_other {
            let modelData = MD_LT3G_CommandTool.commandReadFirmwareVersion()
            self.writeValueToDevice(data: modelData)
            Thread.sleep(forTimeInterval: 0.2)
            let readData = MD_LT3G_CommandTool.readEPPROM(blockNum: .Lanting3GEEPROMBlockTypeSerialNumber)
            self.writeValueToDevice(data: readData)
            Thread.sleep(forTimeInterval: 0.2)
            let dateData = MD_LT3G_CommandTool.readEPPROM(blockNum: .Lanting3GEEPROMBlockTypeActivationDate)
            self.writeValueToDevice(data: dateData)
            self.perform(#selector(readEEPROM), with: nil, afterDelay: 2.0)
            self.readEEPROMTimes -= 1
        }
    }
    
    //检测设备是否可以连接
    @objc func checkDeviceConnect(){}
    
    @objc func cancelReadEEPROM() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(readEEPROM), object: nil)
    }
    
    /// 开始采集数据肌电
    @objc func startCollectData(){
        if self.deviceType == .lt_1G {
            let data = MD_LT1G_CommandTool().commandCollection(commandStatus: .Start)
            self.writeValueToDevice(data: data)
        }
        else if self.deviceType == .lt_2G {
            let data = MD_LT2G_CommandTool.commandControl(type: .CollectionBegin, channel: self.absChannel)
            self.writeValueToDevice(data: data)
            
        }
        else if self.deviceType == .lt_other {
            if self.isSuppotAbdominal {
                let data = MD_LT3G_CommandTool.commandCollection(collectType: .start, abMJoinType: .joinIn)
                self.writeValueToDevice(data: data)
            } else {
                let data = MD_LT3G_CommandTool.commandCollection(collectType: .start, abMJoinType: .notJoin)
                self.writeValueToDevice(data: data)
            }
        }
    }
    
    /// 停止肌电采集数据 肌电
    @objc func stopCollectData(){
        if self.deviceType == .lt_1G {
            let data = MD_LT1G_CommandTool().commandCollection(commandStatus: .End)
            self.writeValueToDevice(data: data)
        }
        else if self.deviceType == .lt_2G {
            
            let data = MD_LT2G_CommandTool.commandControl(type: .CollectionEnd, channel: self.absChannel)
                self.writeValueToDevice(data: data)
            
        }
        else if self.deviceType == .lt_other {
            if self.isSuppotAbdominal {
                let data = MD_LT3G_CommandTool.commandCollection(collectType: .stop, abMJoinType: .joinIn)
                self.writeValueToDevice(data: data)
            } else {
                let data = MD_LT3G_CommandTool.commandCollection(collectType: .stop, abMJoinType: .notJoin)
                self.writeValueToDevice(data: data)
            }
        }
    }
    
    /// 非变频电刺激参数设置
    /// - Parameters:
    ///   - pulse: 脉宽
    ///   - freq: 频率
    ///   - riseTime: 上升时间
    ///   - fallTime: 下降时间
    ///   - stimValue: 电刺激强度
    ///   - preSetElectricity 预设电流阶段
    ///   preSetElectricity == true riseTime,fallTime,workTime,restTime传0
    @objc func sendStimParamToDevice_NotInverterFreq(pulse: UInt, freq: UInt, riseTime: UInt, fallTime: UInt, stimValue: Double,workTime:UInt, restTime:UInt,preSetElectricity:Bool,_ channel:ChannelType = .first) {
        let riseTimeUse = preSetElectricity == true ? 1 : riseTime
        let fallTimeUse = preSetElectricity == true ? 1 : fallTime
        let workTimeUse = preSetElectricity == true ? 0 : workTime
        let resetTimeUse = preSetElectricity == true ? 0 : restTime
        let mul = self.electricityMultiple
        if self.deviceType == .lt_1G {
            let pulseData = MD_LT1G_CommandTool().commandStimParam(stimType: .PulseWidth, value: Int(pulse))
            self.writeValueToDevice(data: pulseData)
            let freqData = MD_LT1G_CommandTool().commandStimParam(stimType: .Frequency, value: Int(freq))
            self.writeValueToDevice(data: freqData)
            
            let riseData = MD_LT1G_CommandTool().commandStimParam(stimType: .RiseTime, value: Int(riseTimeUse))
            self.writeValueToDevice(data: riseData)
            
            let fallData = MD_LT1G_CommandTool().commandStimParam(stimType: .FallTime, value: Int(fallTimeUse))
            self.writeValueToDevice(data: fallData)
            
            self.stimElectricitySet(stimValue: stimValue)

        }
        else if self.deviceType == .lt_2G {
            let data = MD_LT2G_CommandTool.commandStimParams(frequency: freq, pulseWidth: pulse, electricity: UInt(stimValue * mul), riseTime: riseTimeUse, fallTime: fallTimeUse, workTime: workTimeUse, restTime: resetTimeUse)
            self.writeValueToDevice(data: data)
        }
        else {
            var waveData = MD_LT3G_CommandTool.commandWave(channel: channel, wave: .square, polarity: .twoWay, alternate: .notAlternate)
            if self.is2GUp {  //新二代交替
                waveData = MD_LT3G_CommandTool.commandWave(channel: channel, wave: .square, polarity: .twoWay, alternate: .alternate)
            }
            self.writeValueToDevice(data: waveData)
            
            let pulseData = MD_LT3G_CommandTool.commandPulse(channel: channel, pulse_1: pulse, pulse_2: 0, pulse_3: 0)
            self.writeValueToDevice(data: pulseData)
            let freqData = MD_LT3G_CommandTool.commandFrequency(channel: channel, freq_1: freq)
            self.writeValueToDevice(data: freqData)
            
            let riseData = MD_LT3G_CommandTool.commandTime(channel: channel, upTime: riseTimeUse * 10, downTime: fallTimeUse * 10, frequencyConversion: 0, outbreakWorkingTime: workTime * 10, outbreakRestTime: workTime * 10)
            self.writeValueToDevice(data: riseData)

            let electricData = MD_LT3G_CommandTool.commandStimAdjust(channel: channel, stimVal: Int(stimValue * mul), settingType: .setting)
            self.writeValueToDevice(data: electricData)
        }
        
    }
    
    /// 变频电刺激参数设置
    /// - Parameters:
    ///   - pluse_1: 脉宽 1
    ///   - pluse_2: 脉宽 2
    ///   - pluse_3: 脉宽 3
    ///   - freq_1: 频率 1
    ///   - freq_2: 频率 2
    ///   - freq_3: 频率 3
    ///   - riseTime: 上升时间
    ///   - fallTime: 下降时间
    ///   - stimValue: 电刺激强度
    ///   preSetElectricity == true riseTime,fallTime,workTime,restTime传0
    @objc func sendStimParamToDevice_InverterFreq(pluse_1: UInt, pluse_2: UInt, pluse_3: UInt, freq_1: UInt, freq_2: UInt, freq_3: UInt, riseTime: UInt, fallTime: UInt, stimValue: Double,workTime:UInt, restTime:UInt,preSetElectricity:Bool,_ channel:ChannelType = .first) {
        let riseTimeUse = preSetElectricity == true ? 1 : riseTime
        let fallTimeUse = preSetElectricity == true ? 1 : fallTime
        let workTimeUse = preSetElectricity == true ? 0 : workTime
        let resetTimeUse = preSetElectricity == true ? 0 : restTime
        let mul = self.electricityMultiple
        if self.deviceType == .lt_1G {
            let pulseData = MD_LT1G_CommandTool().commandStimParam(stimType: .PulseWidth, value: Int(pluse_1))
            self.writeValueToDevice(data: pulseData)
            let freqData = MD_LT1G_CommandTool().commandStimParam(stimType: .Frequency, value: Int(freq_1))
            self.writeValueToDevice(data: freqData)
            let riseData = MD_LT1G_CommandTool().commandStimParam(stimType: .RiseTime, value: Int(riseTimeUse))
            self.writeValueToDevice(data: riseData)
            let fallData = MD_LT1G_CommandTool().commandStimParam(stimType: .FallTime, value: Int(fallTimeUse))
            self.writeValueToDevice(data: fallData)
            
            self.stimElectricitySet(stimValue: stimValue)
        }
        else if self.deviceType == .lt_2G {
            if preSetElectricity {
                let temp1 = freq_1 * pluse_1
                let temp2 = freq_2 * pluse_2
                let temp3 = freq_3 * pluse_3
                var maxFreq : UInt = 0
                var maxPulseWidth : UInt = 0
                if temp1 > temp2 {
                    if temp1 > temp3 {
                        maxFreq = freq_1
                        maxPulseWidth = pluse_1
                    }
                    else {
                        maxFreq = freq_3
                        maxPulseWidth = pluse_3
                    }
                } else {
                    if temp2 > temp3 {
                        maxFreq = freq_2
                        maxPulseWidth = pluse_2
                    }
                    else {
                        maxFreq = freq_3
                        maxPulseWidth = pluse_3
                    }
                }
                
                let paramData = MD_LT2G_CommandTool.commandStimParams(frequency: maxFreq, pulseWidth: maxPulseWidth, electricity: UInt(stimValue * mul), riseTime: riseTimeUse, fallTime: fallTimeUse, workTime: workTimeUse, restTime: resetTimeUse)
                self.writeValueToDevice(data: paramData)
            }
            else {
                let paramData = MD_LT2G_CommandTool.commandStimParams(frequency: freq_1, pulseWidth: pluse_1, electricity: UInt(stimValue * mul), riseTime: riseTimeUse, fallTime: fallTimeUse, workTime: workTimeUse, restTime: resetTimeUse)
                self.writeValueToDevice(data: paramData)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let fsDuration = workTime - riseTime - fallTime
                    let data1 = MD_LT2G_CommandTool.commandFrequencyScalingStimParams(frequency2: freq_2, frequency3: freq_3, pulseWidth2: pluse_2, pulseWidth3: pluse_3, frequencyScalingDuration: fsDuration * 10)
                    self.writeValueToDevice(data: data1)
                }
            }
        }
        else {  //lt3G
            var waveData = MD_LT3G_CommandTool.commandWave(channel: channel, wave: .square, polarity: .twoWay, alternate: .notAlternate)
            if self.is2GUp {  //新二代交替
                waveData = MD_LT3G_CommandTool.commandWave(channel: channel, wave: .square, polarity: .twoWay, alternate: .alternate)
            }
            self.writeValueToDevice(data: waveData)
            if preSetElectricity {
                let temp1 = freq_1 * pluse_1
                let temp2 = freq_2 * pluse_2
                let temp3 = freq_3 * pluse_3
                var maxFreq : UInt = 0
                var maxPulseWidth : UInt = 0
                if temp1 > temp2 {
                    if temp1 > temp3 {
                        maxFreq = freq_1
                        maxPulseWidth = pluse_1
                    }
                    else {
                        maxFreq = freq_3
                        maxPulseWidth = pluse_3
                    }
                } else {
                    if temp2 > temp3 {
                        maxFreq = freq_2
                        maxPulseWidth = pluse_2
                    }
                    else {
                        maxFreq = freq_3
                        maxPulseWidth = pluse_3
                    }
                }
                let pulseData = MD_LT3G_CommandTool.commandPulse(channel: channel, pulse_1: maxPulseWidth, pulse_2: 0, pulse_3: 0)
                self.writeValueToDevice(data: pulseData)
                let freqData = MD_LT3G_CommandTool.commandFrequency(channel: channel, freq_1: maxFreq, freq_2: 0, freq_3: 0)
                self.writeValueToDevice(data: freqData)
                let riseData = MD_LT3G_CommandTool.commandTime(channel: channel, upTime: riseTimeUse * 10, downTime: fallTimeUse * 10, frequencyConversion: 0, outbreakWorkingTime: workTime * 10, outbreakRestTime: workTime * 10)
                self.writeValueToDevice(data: riseData)
                
                let electricData = MD_LT3G_CommandTool.commandStimAdjust(channel: channel, stimVal: Int(stimValue * mul), settingType: .setting)
                self.writeValueToDevice(data: electricData)
            }
            else {
                let pulseData = MD_LT3G_CommandTool.commandPulse(channel: channel, pulse_1: pluse_1, pulse_2: pluse_2, pulse_3: pluse_3)
                self.writeValueToDevice(data: pulseData)
                let freqData = MD_LT3G_CommandTool.commandFrequency(channel: channel, freq_1: freq_1, freq_2: freq_2, freq_3: freq_3)
                self.writeValueToDevice(data: freqData)
                let freqTime = workTime - riseTime - fallTime
                let riseData = MD_LT3G_CommandTool.commandTime(channel: channel, upTime: riseTimeUse * 10, downTime: fallTimeUse * 10, frequencyConversion: freqTime * 10, outbreakWorkingTime: workTime * 10, outbreakRestTime: workTime * 10)
                self.writeValueToDevice(data: riseData)
                
                let electricData = MD_LT3G_CommandTool.commandStimAdjust(channel: channel, stimVal: Int(stimValue * mul), settingType: .setting)
                self.writeValueToDevice(data: electricData)
            }
        }
    }

    /// 刺激电流设置
    /// - Parameter stimValue: 电流值
    @objc func stimElectricitySet(stimValue: Double,_ channel:ChannelType = .first) {
        let mul = self.electricityMultiple
        if self.deviceType == .lt_1G {
            let data = MD_LT1G_CommandTool().commandStimParam(stimType: .Electricity, value: Int(stimValue * mul))
            self.writeValueToDevice(data: data)
        }
        else if self.deviceType == .lt_2G {
            let data = MD_LT2G_CommandTool.commandSetStimCurrent(value: UInt(stimValue * mul))
            self.writeValueToDevice(data: data)
        }
        else {  //三代
            let data = MD_LT3G_CommandTool.commandStimAdjust(channel: channel, stimVal:Int(stimValue * mul), settingType: .adjust)
            self.writeValueToDevice(data: data)
        }
    }

    /// 刺激开始
    @objc func stimStart(_ channel:ChannelType = .first) {
        if self.deviceType == .lt_1G {
            let data = MD_LT1G_CommandTool().commandStim(stimStatus: .Start)
            self.writeValueToDevice(data: data)
        } else if self.deviceType == .lt_2G {
            let data = MD_LT2G_CommandTool.commandControl(type: .StimBegin, channel: self.absChannel)
            self.writeValueToDevice(data: data)
        } else {  //三代
            let data = MD_LT3G_CommandTool.commandControl(channel: channel, fallOffType: .useful, workType: .constantFreqStimStart)
            self.writeValueToDevice(data: data)
        }
    }
    
    /// 刺激开始(屏蔽电极片脱落功能)  2代和三代
    @objc func stimStartNoElectrodeStatus(_ channel:ChannelType = .first) {
         if self.deviceType == .lt_2G {
            
                let data = MD_LT2G_CommandTool.commandControl(type: .StimBeginNoElectrodeStatus, channel: self.absChannel)
                self.writeValueToDevice(data: data)
            
        }
        else {  //三代
            let data = MD_LT3G_CommandTool.commandControl(channel: channel, fallOffType: .nonUse, workType: .constantFreqStimStart)
            self.writeValueToDevice(data: data)
        }
    }
    
    /// 变频刺激开始  2代 3代
    @objc func frequencyScalingStimStart(_ channel:ChannelType = .first) {
        if self.deviceType == .lt_2G {
           
               let data = MD_LT2G_CommandTool.commandControl(type: .FrequencyScalingStimBegin, channel: self.absChannel)
               self.writeValueToDevice(data: data)
           
       }
       else {  //三代
           let data = MD_LT3G_CommandTool.commandControl(channel: channel, fallOffType: .useful, workType: .exchangeFreqStimStart)
           self.writeValueToDevice(data: data)
       }
    }
    
    /// 变频刺激开始(屏蔽电极片脱落功能) 2代 3代
    @objc func frequencyScalingStimStartNoElectrodeStatus(_ channel:ChannelType = .first) {
        if self.deviceType == .lt_2G {
            let data = MD_LT2G_CommandTool.commandControl(type: .FrequencyScalingStimBeginNoElectrodeStatus, channel: self.absChannel)
            self.writeValueToDevice(data: data)
        }
       else {  //三代
           let data = MD_LT3G_CommandTool.commandControl(channel: channel, fallOffType: .nonUse, workType: .exchangeFreqStimStart)
           self.writeValueToDevice(data: data)
       }
    }
    
    /// 刺激结束
    @objc func stimEnd(_ channel:ChannelType = .first) {
        if self.deviceType == .lt_1G {
            let data = MD_LT1G_CommandTool().commandStim(stimStatus: .End)
            self.writeValueToDevice(data: data)
        }
        else if self.deviceType == .lt_2G {
            let data = MD_LT2G_CommandTool.commandControl(type: .StimEnd, channel: self.absChannel)
            self.writeValueToDevice(data: data)
        }
        else {  //三代
            let data = MD_LT3G_CommandTool.commandControl(channel: channel, fallOffType: .useful, workType: .stimStop)
            self.writeValueToDevice(data: data)
        }
    }
    
    @objc func heatStart() {
        let data = MD_LT2G_CommandTool.commandControl(type: .CanHeat, channel: self.absChannel)
        self.writeValueToDevice(data: data)
    }
    
    @objc func heatEnd() {
        let data = MD_LT2G_CommandTool.commandControl(type: .ProhibitHeat, channel: self.absChannel)
        self.writeValueToDevice(data: data)
    }
    
    
    /// 开始压力采集
    @objc func startPressureCollect() {
        let sendData = MD_LT3G_CommandTool.commandPressureCollectStart()
        writeValueToDevice(data: sendData)
    }
    
    /// 停止压力采集
    @objc func stopPressureCollect() {
        //清空平滑工具
        self.dataHandle3G?.pressureValue_Smooth.setSmoothLength(length: 40)
        let sendData = MD_LT3G_CommandTool.commandPressureCollectStop()
        writeValueToDevice(data: sendData)
    }
    
    /// 开始充气
    /// - Parameter pressureVal: 压力值 mmHg
    @objc func startInfliate(pressureVal:Double) {
        //发送抽真空结束
        let endVacuuming = MD_LT3G_CommandTool.commandPressureModeControl(controlType: .vacuumingEnd)
        writeValueToDevice(data: endVacuuming)
        let pressureSet = pressureVal * 100
        //(1)设定压力值
        let pressValData = MD_LT3G_CommandTool.commandPressureParamAdjustment(pressureVal: UInt(pressureSet))
        writeValueToDevice(data: pressValData)
        //(2)开始充气
        let startInfliateData = MD_LT3G_CommandTool.commandPressureModeControl(controlType: .inflateStart)
        writeValueToDevice(data: startInfliateData)
    }
    
    /// 停止充气
    @objc func stopInfliate() {
        let sendData = MD_LT3G_CommandTool.commandPressureModeControl(controlType: .inflateEnd)
        writeValueToDevice(data: sendData)
    }
    
    /// 放气,打开气阀
    @objc func startVacuuming() {
        let endData = MD_LT3G_CommandTool.commandPressureModeControl(controlType: .inflateEnd)
        writeValueToDevice(data: endData)
        weak var weakSelf = self
        DispatchQueue.main.asyncAfter(deadline: .now()+0.04, execute:{
            let sendData = MD_LT3G_CommandTool.commandPressureModeControl(controlType: .vacuumingStart)
            weakSelf?.writeValueToDevice(data: sendData)
        })
    }
    
    //关闭气阀
    @objc func closeAirValve() {
        //发送抽真空结束
        let endVacuuming = MD_LT3G_CommandTool.commandPressureModeControl(controlType: .vacuumingEnd)
        writeValueToDevice(data: endVacuuming)
    }
    
    //给设备发送方案开始状态-三代高端
    @objc func trainStatusStart() {}
    
    //给设备发送方案结束状态-三代高端
    @objc func trainStatusEnd() {}
    //关机
    @objc func powerOff() {
        if deviceType == .lt_2G {
            let data = MD_LT2G_CommandTool.commandControl(type: .Close, channel: absChannel)
            self.writeValueToDevice(data: data)
        }
    }
    //开始升级
    @objc func startUpgrade(isHex: Bool) {
        self.isHexUpgradeSuccess = false
        if MD_BLEConnectManager.shared.ltGen == .lt_other {
            if isHex {
                self.upgradeShakeTimes = 2
                self.p_upgradeShake()
                self.isUpgrading = true
            }
            else {  //DFU升级
                MD_DFUHelper.shared.startDFU(resourceName: "/lantingUpgradeZip.zip", target: self.peripheral)
                self.isUpgrading = true;
            }
        } else {
            self.upgradeShakeTimes = 5
            self.p_upgradeShake()
            self.isUpgrading = true
        }
    }
    
    //升级握手
    @objc func p_upgradeShake() {
        if self.upgradeShakeTimes <= 0 {
            MD_DispatcherCenter.shared.dispatchUpgradeShakeFailure()
            return
        }
        if MD_BLEConnectManager.shared.ltGen == .lt_other {
            //创建队列
            let queue = DispatchQueue(label: "hexQuene",qos: .default, attributes: .concurrent)
            queue.async {
                self.dataHandle3G?.readHexFile()
            }
            queue.async(group: nil, qos: .default, flags: .barrier) {
                let shakeData = self.dataHandle3G?.hexFirstData ?? []
                let data = MD_LT3G_CommandTool.commandUpgradeShakeHand(shakeData: shakeData)
                self.writeValueToDevice(data: data)
                //停止心跳
                self.heartBeat.heartBeatOver()
                self.perform(#selector(self.p_upgradeShake), with: nil, afterDelay: 2)
            }
        } else {
            let data = MD_LT2G_CommandTool.commandUpgradeShakeHand()
            self.writeValueToDevice(data: data)
            //停止心跳
            self.heartBeat.heartBeatOver()
            self.perform(#selector(p_upgradeShake), with: nil, afterDelay: 1)
        }
        
        self.upgradeShakeTimes -= 1;
    }
    
    //升级握手成功
    @objc func p_upgradeShakeSucess() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(p_upgradeShake), object: nil)
    }
    
    
    /// 写数据到蓝牙设备
    /// - Parameter data: 需要写的数据
    @objc func writeValueToDevice(data: Data) {
        if ([UInt8](data))[2] != LT_1rdCommandTypeWrite.WatchDog.rawValue && ([UInt8](data))[3] != LT2GCommandType.Status.rawValue && ([UInt8](data))[3] != LT_3rdCommandTypeWrite.checkDeviceStatus.rawValue{
            let str = MD_BLEDeviceDealTool.outPutCommandStr(data: [UInt8](data))
            print("writeValue = \(str)")
        }
        MD_DispatcherCenter.shared.dispatchBLEWriteValue(value: data)
        
        if let characteristic = self.writeCharacter {
            if self.writeCharacter?.properties.contains(.write) ?? false{
                self.peripheral?.writeValue(data, for: characteristic, type: .withResponse)
            } else if self.writeCharacter?.properties.contains(.writeWithoutResponse) ?? false {
                if characteristic.uuid == CBUUID.init(string: lantingOldCharacteristicsWrite) {
                    //老的A0设备必须使用带返回值的
                    self.peripheral?.writeValue(data, for: characteristic, type: .withResponse)
                } else {
                    self.peripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
                }
                
                
            }
        }
       
    }
}


extension MD_BLEModel:CBPeripheralDelegate {
    /// 发现服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if (error != nil) {
            //分发连接失败
            MD_DispatcherCenter.shared.dispatchBLEConnectManagerDidFailToConnect(peripheral: peripheral, error: error)
        }
        services.removeAll()
        if let pServices = peripheral.services {
            if pServices.count > 0 {
                services.append(contentsOf: pServices)
            }
        }
        for service: CBService in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    /// 发现特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            //分发连接失败
            MD_DispatcherCenter.shared.dispatchBLEConnectManagerDidFailToConnect(peripheral: peripheral, error: error)
        }
        characteristices.removeAll()
        if let pCharacteristices = service.characteristics {
            if pCharacteristices.count > 0 {
                characteristices.append(contentsOf: pCharacteristices)
            }
        }
        for characteristic: CBCharacteristic in characteristices {
            if characteristic.properties.contains(.notify) {
                //订阅通道
                peripheral.setNotifyValue(true, for: characteristic)
            }else  if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                //写通道
                if self.p_isValidCharacteristicWriteUUID(uuid: characteristic.uuid) {
                    self.writeCharacter = characteristic
                    if MD_BLEConnectManager.shared.ltGen == .lt_2G {
                        let data = MD_LT2G_CommandTool.commandShakeHand()
                        DispatchQueue.main.asyncAfter(deadline: .now()+1.4) {
                            self.writeValueToDevice(data: data)
                        }
                    } else if MD_BLEConnectManager.shared.ltGen == .lt_other {
                        let data = MD_LT3G_CommandTool.commandShakeHande()
                        DispatchQueue.main.asyncAfter(deadline: .now()+1.4) {
                            self.writeValueToDevice(data: data)
                        }
                    }
                    else {
                        self.heartBeat.heartBeat()
                        self.readEEPROMTimes = 3
                        self.perform(#selector(readEEPROM), with: nil, afterDelay: 2.0)
                    }
                }
            }
        }
        
        
        //读取设备信号
        peripheral.readRSSI()
    }
    
    /// 是否是有效的写特征UUID
    /// @param uuid uuid
    @objc func p_isValidCharacteristicWriteUUID(uuid:CBUUID) -> Bool{
        if uuid.uuidString == lantingOldCharacteristicsWrite || uuid.uuidString == lanting2GCharacteristicsUUIDWrite || uuid.uuidString.contains(lanting1GCharacteristicsUUIDWrite)  {
            return true
        }
        return false
    }
   
    
    /// 订阅状态
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    /// 接收到数据
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        let value = characteristic.value ?? Data()
        MD_DispatcherCenter.shared.dispatchBLEDidUpdateValue(peripheral: peripheral, value: value, error: error)
        
        receivedLock.lock()
        if let receivedData = characteristic.value {
            if receivedData.count > 0 {
                //解析数据
                if deviceType == .lt_1G {
                    dataHandle1G?.dataHandleDidUpdateValue(data: receivedData)
                } else if deviceType == .lt_2G{
                    dataHandle2G?.handleNotify(data: receivedData)
                } else if deviceType == .lt_other {
                    dataHandle3G?.dataHandleDidUpdateValue(data: receivedData)
                }
            }
        }
        receivedLock.unlock()
    }
   
    /// 写入数据
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("写入失败")
        }else {
        }
    }
    
    /// 接收到RSSI
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI:NSNumber, error: Error?){
        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + 2,execute:{
            peripheral.readRSSI()
        })
        
        let rssiOriginal = RSSI.intValue
        rssiValue = rssiOriginal + 100
        rssiLevel = MD_BLEDeviceDealTool.getBLERSSILevelByValue(value: rssiOriginal)
        MD_DispatcherCenter.shared.dispatchBLEModelDidUpdateRSSI(peripheral: peripheral, rssiValue: rssiValue, rssiLevel: rssiLevel)
    }
    
    
    func dealActivationDate(serverActivationDate:String) {
        let activeInterval = TimeInterval(serverActivationDate) ?? 0
        let activationDate = Date.init(timeIntervalSinceReferenceDate: activeInterval)
        self.activationYear = MD_BLEDeviceDealTool.dateYear(date: activationDate)
        self.activationMonth = MD_BLEDeviceDealTool.dateMonth(date: activationDate)
        self.activationDay = MD_BLEDeviceDealTool.dateDay(date: activationDate)
        self.serverActionDate = String(format:"%lu-%lu-%lu", self.activationYear,self.activationMonth,self.activationDay)
    }
    
    //用服务器时间写激活日期
    func p_writeActivationDate() {
        let year = UInt(self.activationYear)
        let month = UInt(self.activationMonth)
        let day = UInt(self.activationDay)
        self.activationDate = self.serverActionDate
        if deviceType == .lt_1G {
            let data = MD_LT1G_CommandTool().commandNotifyEEPROM1GActivationDate(year: Int(year), month: Int(month), day: Int(day))
            self.writeValueToDevice(data: data)
        } else if deviceType == .lt_2G {
            let data = MD_LT2G_CommandTool.writeEPPROMActiveDate(year: year, month: month, day: day)
            self.writeValueToDevice(data: data)
        } else if deviceType == .lt_other {
            let data = MD_LT3G_CommandTool.commandNotifyEEPROM3GActivationDate(year: Int(year), month: Int(month), day: Int(day))
            self.writeValueToDevice(data: data)
        }
        
    }
}
