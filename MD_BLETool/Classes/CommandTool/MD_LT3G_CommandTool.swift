//
//  MD_LT3G_CommandTool.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/14.
//

import UIKit

func thirdCommandHeadBytes_Upgrade() -> [UInt8] {
    var result:[UInt8] = [UInt8](repeating: 0, count: 2)
    result[0] = 0xaa
    result[1] = 0xa7
    return result
}

func thirdCommandHeadBytes_Write() -> [UInt8] {
    var result:[UInt8] = [UInt8](repeating: 0, count: 2)
    result[0] = 0xaa
    result[1] = 0xa5
    return result
}
func thirdCommandHeadBytes_Notify() -> [UInt8] {
    var result:[UInt8] = [UInt8](repeating: 0, count: 2)
    result[0] = 0xbb
    result[1] = 0xa5
    return result
}

@objc enum LT_3rdEEPROMNotify :UInt8 {
    case Lanting3GEEPROMBlockTypeModel = 0x00 // 型号
    case Lanting3GEEPROMBlockTypeSerialNumber = 0x01 // 序列号
    case Lanting3GEEPROMBlockTypeBuildInScheme = 0x02 // 内置方案
    case Lanting3GEEPROMBlockTypeActivationDate = 0x03  //激活日期

}

enum LT_3rdCommandUpgradeWrite:UInt8 {
    case shakeHand = 0x02 //02 MCU握手指令
    case selectModel = 0x22 //模块选择
    case upgradeBoot = 0x03 //app层跳转boot层
    case upgradeSeed = 0x04  //索要种子
    case upgradeKey = 0x05  //解密秘钥
    case upgardeAdress = 0x23 //发送起始地址
    case upgardeFlashSize = 0x24  //发送字节数
    case upgradeFlash = 0x06  //擦除Flash指令
    case upgradeData = 0x10  //升级数据
    case upgradeFinsh = 0x11 //升级完成
    case upgaradeApp = 0x12   //跳转app指令
}

enum LT_3rdCommandUpgradeNotify:UInt8 {
    case shakeHand = 0x02 //MCU握手信息反馈
    case supportUpgrade = 0x21  //反馈支持升级信息
    case selectModel = 0x22 //模块选择com
    case upgradeBoot = 0x03 //app层跳转boot层
    case upgradeSeed = 0x04  //索要种子
    case upgradeKey = 0x05  //解密秘钥
    case upgardeAdress = 0x23 //发送起始地址
    case upgardeFlashSize = 0x24  //发送字节数
    case upgradeFlash = 0x06  //擦除Flash指令
    case upgradeData = 0x10  //升级数据
    case upgradeFinsh = 0x11 //升级完成
    case upgaradeApp = 0x12   //跳转app指令
    case wait = 0x0A    //下位机等待
}

enum LT_3rdCommandTypeWrite:UInt8 {
    case shakeHand = 0x01 //01 开机握手指令
    case firmwareVersionCommand = 0x02 // 读取固件版本号指令
    case checkDeviceStatus = 0x03 //03 查询设备状态指令
    case readEPPROM = 0x05 //03 读取EEPROM块指令
    case writeEPPROM = 0x04 //04 写EEPROM块指令
    case collection = 0x10 //10 采集指令
    case wave = 0x11 //11 刺激方案参数指令--波形
    case pulse = 0x12 //12 刺激方案参数指令--脉宽
    case frequency = 0x13 //13 刺激方案参数指令--频率
    case time = 0x14 //14 刺激方案参数指令--时间
    case control = 0x15 //15 控制指令
    case stimAdjust = 0x16 //16 刺激电流调节指令
    case pressureParamSetting = 0x20 //20 压力参数设定指令
    case pressureModeControl = 0x21 //21 压力模块控制指令
    case pressureCollectControl = 0x22 //22 压力采集指令
}

enum LT_3rdCommandTypeNotify:UInt8 {
    case shakeHand = 0x01 //握手信息上传
    case firmwareVersionCommand = 0x02 // 读取固件版本号指令
    case deviceStatus = 0x03 //02.1 状态上传
//    case deviceStatus_2 = 0x16 //02.2 状态上传
    case eppromUpload = 0x05 //03 EEPROM块信息上传
    case stimulatingCurrent = 0x16 //16 刺激电流反馈
    case electricalStimulationReceiving = 0x17 //17 电刺激接收数据反馈
    case electrodeFallOff = 0x18 //18 电极脱落反馈
    case pressureParameterAdjustment = 0x20 //20 压力参数调节实时反馈
    case pressureModuleParameterSetting = 0x21 //21 压力模块参数设定反馈
    case pressureModuleCollection = 0x22 //21 压力模块采集数据反馈
}

/// 三代指令组成
/// - Parameters:
///   - head: 包头数组
///   - length: 包长度
///   - validCommand: 有效指令数组
/// - Returns: Data
func thirdCommandCreat(head:[UInt8], length:UInt8, validCommand:[UInt8]) -> Data {
    var resultCommad:[UInt8] = [UInt8]()
    resultCommad.append(contentsOf: head)
    resultCommad.append(length)
    resultCommad.append(contentsOf: validCommand)
    resultCommad.append(contentsOf: MD_VerfifyTool.crcVerfifyCode_Cal(bytes: validCommand))
    
    let resultData:Data = Data(bytes: resultCommad, count: resultCommad.count);
    
    var sendString:String = ""
    for i in 0..<resultCommad.count {
        let strVal:String = String(format: "%x  ", resultCommad[i])
        sendString.append(strVal)
    }
    return resultData
}


class MD_LT3G_CommandTool: NSObject {

    //MARK: -- 开机握手指令
    @objc class func  commandShakeHande() -> Data{
        //数据长度
        let length:UInt8 = 0x01
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 1)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.shakeHand.rawValue
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    //MARK: -- 读取固件版本号指令
    @objc class func  commandReadFirmwareVersion() -> Data{
        //数据长度
        let length:UInt8 = 0x01
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 1)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.firmwareVersionCommand.rawValue
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    
    
    //MARK: -- 02查询设备状态指令
    @objc enum Notch:Int {
        case none  //00：屏蔽固件陷波
        case hz_50 //50Hz陷波
        case hz_60 //60Hz陷波；
    }
    @objc enum WatchDog:Int {
        case startUp //启动并喂狗
        case closed  //屏蔽看门狗
    }
    
    @objc enum TrainStatus:Int {
        case await = 0x00 //待机
        case start = 0x01  //方案开始
        case pause = 0x02 //方案暂停
        case over = 0x03 //方案结束
    }
    
    /// 查询设备状态指令
    /// - Parameters:
    ///   - hzType: 50Hz/60Hz陷波选择，00：屏蔽固件陷波，01：50Hz陷波，02：60Hz陷波；
    ///   - highPassFilter: 高通滤波，0~500Hz(默认20Hz)
    ///   - lowPassFilter: 低通滤波，100~1000Hz(默认550Hz)
    ///   - dogUse: 看门狗有效性，01启动并喂狗，02屏蔽看门狗
    /// - Returns: Data
    @objc class func  commadnCheckDeviceStatus(hzType:Notch = .none,highPassFilter:UInt = 20, lowPassFilter:UInt = 550, dogUse:WatchDog = .startUp) -> Data{
//        备注：
//        1.1s时间循环下发，在采集时下发，设备不回复，因为设备已经是采集状态中；
//        2.有效数据长度byte2为byte3~byte9；
//        3.CRC校验仅为有效数据byte3~byte9的校验和。
        //有效数据长度
        let length:UInt8 = 0x07
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 7)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.checkDeviceStatus.rawValue
        //50Hz/60Hz陷波选择，00：屏蔽固件陷波，01：50Hz陷波，02：60Hz陷波；
        switch hzType {
        case .none:
            validCommand[1] = 0x00
            break
        case .hz_50:
            validCommand[1] = 0x01
            break
        case .hz_60:
            validCommand[1] = 0x02
            break
        }
        //byte5~6：高通滤波，0~500Hz(默认20Hz)；
        validCommand[2] = UInt8(0xff & (highPassFilter >> 8))
        validCommand[3] = UInt8(0xff & (highPassFilter % 256))
        //byte7~8：低通滤波，100~1000Hz(默认550Hz)；
        validCommand[4] = UInt8(0xff & (lowPassFilter >> 8))
        validCommand[5] = UInt8(0xff & (lowPassFilter % 256))
        //byte9：看门狗有效性，01启动并喂狗，02屏蔽看门狗；
        switch dogUse {
        case .startUp:
            validCommand[6] = 0x01
            break
        case .closed:
            validCommand[6] = 0x02
            break
        }
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    
    /// 查询设备状态指令
    /// - Parameters:
    ///   - hzType: 50Hz/60Hz陷波选择，00：屏蔽固件陷波，01：50Hz陷波，02：60Hz陷波；
    ///   - highPassFilter: 高通滤波，0~500Hz(默认20Hz)
    ///   - lowPassFilter: 低通滤波，100~1000Hz(默认550Hz)
    ///   - dogUse: 看门狗有效性，01启动并喂狗，02屏蔽看门狗
    /// - Returns: Data
    @objc class func  commandDeviceStatus(hzType:Notch = .none,highPassFilter:UInt = 20, lowPassFilter:UInt = 550, dogUse:WatchDog = .startUp, minute:UInt,sec:UInt,trainStatus:TrainStatus = .await) -> Data{
//        备注：
//        1.1s时间循环下发，在采集时下发，设备不回复，因为设备已经是采集状态中；
//        2.有效数据长度byte2为byte3~byte9；
//        3.CRC校验仅为有效数据byte3~byte9的校验和。
        //有效数据长度
        let length:UInt8 = 0x0A
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 10)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.checkDeviceStatus.rawValue
        //50Hz/60Hz陷波选择，00：屏蔽固件陷波，01：50Hz陷波，02：60Hz陷波；
        switch hzType {
        case .none:
            validCommand[1] = 0x00
            break
        case .hz_50:
            validCommand[1] = 0x01
            break
        case .hz_60:
            validCommand[1] = 0x02
            break
        }
        //byte5~6：高通滤波，0~500Hz(默认20Hz)；
        validCommand[2] = UInt8(0xff & (highPassFilter >> 8))
        validCommand[3] = UInt8(0xff & (highPassFilter % 256))
        //byte7~8：低通滤波，100~1000Hz(默认550Hz)；
        validCommand[4] = UInt8(0xff & (lowPassFilter >> 8))
        validCommand[5] = UInt8(0xff & (lowPassFilter % 256))
        //byte9：看门狗有效性，01启动并喂狗，02屏蔽看门狗；
        switch dogUse {
        case .startUp:
            validCommand[6] = 0x01
            break
        case .closed:
            validCommand[6] = 0x02
            break
        }
        validCommand[7] = UInt8(minute)
        validCommand[8] = UInt8(sec)
        validCommand[9] = UInt8(trainStatus.rawValue)
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    
    //MARK: -- 03 读取EEPROM块指令
    @objc class func  readEPPROM(blockNum:LT_3rdEEPROMNotify) -> Data{
        //数据长度
        let length:UInt8 = 0x03
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 3)
        validCommand[0] = 0x05
        validCommand[1] = blockNum.rawValue
        validCommand[2] = 0xff

        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    
    @objc enum CollectionType:UInt8 {
        case start = 0x01 //采集开始
        case stop = 0x02  //采集停止
    }
    @objc enum AbdominalMusclesJoinType:UInt8 {
        case joinIn = 0x01 //腹肌参与
        case notJoin = 0x02  //腹肌不参与
    }
    //MARK: -- 10采集指令
    @objc class func  commandCollection(collectType:CollectionType, abMJoinType:AbdominalMusclesJoinType) -> Data{
        //有效数据长度
        let length:UInt8 = 0x03
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 3)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.collection.rawValue
        validCommand[1] = collectType.rawValue
        validCommand[2] = abMJoinType.rawValue
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }

    //MARK: -- 11 刺激方案参数指令--波形

    //波形类型
    @objc enum WaveType:UInt8 {
        case square = 0x01 //01方波
        case sine = 0x02  //02正弦波
        case triangle = 0x03  //03三角波
        case exponentialTriangle = 0x04  //04指数三角波
        case cs = 0x05  //05波形CS
        case ci = 0x06  //06波形CI(其中CS和CI只支持双极性)；
    }
    //波形极性
    @objc enum WavePolarity:UInt8 {
        case oneWay = 0x01 //01为单向波
        case twoWay = 0x02 //02为双向波
    }
    //波形交替选择
    @objc enum WaveAlternateType:UInt8 {
        case alternate = 0x01 //01交替
        case notAlternate = 0x02 //02非交替
    }
    @objc class func  commandWave(channel:ChannelType, wave:WaveType, polarity:WavePolarity, alternate:WaveAlternateType) -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.wave.rawValue
        validCommand[1] = channel.rawValue
        validCommand[2] = wave.rawValue
        validCommand[3] = polarity.rawValue
        validCommand[4] = alternate.rawValue
       
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    //MARK: -- 12 刺激方案参数指令--脉宽  非变频情况下，脉宽2,脉宽3 为0；
    @objc class func  commandPulse(channel:ChannelType,pulse_1:UInt,pulse_2:UInt = 0,pulse_3:UInt = 0) -> Data{
        //有效数据长度
        let length:UInt8 = 0x09
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 9)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.pulse.rawValue
        validCommand[1] = channel.rawValue
        
        validCommand[2] = UInt8(0xff & (pulse_1 >> 8))
        validCommand[3] = UInt8(0xff & (pulse_1 % 256))
        
        validCommand[4] = UInt8(0xff & (pulse_2 >> 8))
        validCommand[5] = UInt8(0xff & (pulse_2 % 256))
        
        validCommand[6] = UInt8(0xff & (pulse_3 >> 8))
        validCommand[7] = UInt8(0xff & (pulse_3 % 256))
        
        validCommand[8] = 0xff
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    //MARK: -- 13 刺激方案参数指令--频率 非变频情况下，频率2 频率2 为0；
    @objc class func  commandFrequency(channel:ChannelType,freq_1:UInt,freq_2:UInt = 0,freq_3:UInt = 0) -> Data{
        //有效数据长度
        let length:UInt8 = 0x09
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 9)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.frequency.rawValue
        validCommand[1] = channel.rawValue
        let freq_one = freq_1 * 10
        let freq_two = freq_2 * 10
        let freq_three = freq_3 * 10
        validCommand[2] = UInt8(0xff & (freq_one >> 8))
        validCommand[3] = UInt8(0xff & (freq_one % 256))
        
        validCommand[4] = UInt8(0xff & (freq_two >> 8))
        validCommand[5] = UInt8(0xff & (freq_two % 256))
        
        validCommand[6] = UInt8(0xff & (freq_three >> 8))
        validCommand[7] = UInt8(0xff & (freq_three % 256))
        
        validCommand[8] = 0xff
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    //MARK: -- 14 刺激方案参数指令--时间
    @objc class func  commandTime(channel:ChannelType,upTime:UInt,downTime:UInt,frequencyConversion:UInt, outbreakWorkingTime:UInt, outbreakRestTime:UInt) -> Data{
//        byte4: 数据范围：0~1，代表通道1~2；
//        byte5~6：上升时间：数值范围0~1000，单位0.1s，有效数据为0~100s；
//        byte7~8：下降时间：数值范围0~1000，单位0.1s，有效数据为0~100s；
//        byte9~10：变频时间：20~500，单位0.1s，变频电刺激时间的设定要求是 工作时间=上升时间+下降时间+变频时间；如果非变频模式，变频时间设定0；
//        byte11~12：爆发工作时间10~500，单位ms；(预留，非爆发模式设定0)
//        byte13~14：爆发休息时间10~500，单位ms；(预留，非爆发模式设定0)
        
        
        //有效数据长度
        let length:UInt8 = 0x0d
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 13)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.time.rawValue
        validCommand[1] = channel.rawValue
        
        validCommand[2] = UInt8(0xff & (upTime >> 8))
        validCommand[3] = UInt8(0xff & (upTime % 256))
        
        validCommand[4] = UInt8(0xff & (downTime >> 8))
        validCommand[5] = UInt8(0xff & (downTime % 256))
        
        validCommand[6] = UInt8(0xff & (frequencyConversion >> 8))
        validCommand[7] = UInt8(0xff & (frequencyConversion % 256))
        
        validCommand[8] = UInt8(0xff & (outbreakWorkingTime >> 8))
        validCommand[9] = UInt8(0xff & (outbreakWorkingTime % 256))
        
        validCommand[10] = UInt8(0xff & (outbreakRestTime >> 8))
        validCommand[11] = UInt8(0xff & (outbreakRestTime % 256))
        
        validCommand[12] = 0xff
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    //MARK: -- 15 控制指令
    //波形交替选择
    @objc enum ElectrodeFallOffCheckType:UInt8 {
        case useful = 0x01 //01脱落功能正常
        case nonUse = 0x02 //02脱落功能屏蔽；
    }
    //工作指令
    @objc enum LT3rdDeviceWorkType:UInt8 {
        case constantFreqStimStart = 0x01 //01为定频刺激开始；
        case exchangeFreqStimStart = 0x02 //02变频电刺激开始；
        case breakOurStimStart = 0x03 //03：爆发模式电刺激开始；
        case stimStop = 0x10 //10为刺激结束；
        case emergencyStop = 0x11 //11紧急停止(该指令不会考虑下降时间，立即停止输出)；
        case shutDown = 0x12 //12关机
    }
    
    
    /// 写激活日期
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    ///   - day: 日
    /// - Returns: Data
    @objc class func commandNotifyEEPROM3GActivationDate(year:Int, month:Int, day:Int)->Data {
        //有效数据长度
        let length:UInt8 = 0x0b
        var validCommand:[UInt8] = [UInt8]()
        validCommand.append(0x06)
        validCommand.append(0x03)
        validCommand.append(UInt8(year%100))
        validCommand.append(UInt8(month))
        validCommand.append(UInt8(day))
        let sum1 = (UInt(validCommand[2])+UInt(validCommand[3])+UInt(validCommand[4])+251) * 3 % 256
        validCommand.append(UInt8(sum1))
        let sum2 = (UInt(validCommand[1])+UInt(validCommand[2])+UInt(validCommand[3])+UInt(validCommand[4])+UInt(validCommand[5])) % 256
        validCommand.append(UInt8(sum2))
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    
    
    @objc class func  commandControl(channel:ChannelType,fallOffType:ElectrodeFallOffCheckType, workType:LT3rdDeviceWorkType) -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.control.rawValue
        validCommand[1] = channel.rawValue
        
        validCommand[2] = fallOffType.rawValue
        validCommand[3] = workType.rawValue
        
        validCommand[4] = 0xff
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    @objc enum LT3rdDeviceStimSetType:UInt8 {
        case setting = 0x01 //设置电流
        case adjust = 0x02 //调节电流
    }
    //MARK: -- 16 刺激电流调节指令
    @objc class func  commandStimAdjust(channel:ChannelType,stimVal:Int, settingType:LT3rdDeviceStimSetType) -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.stimAdjust.rawValue
        validCommand[1] = channel.rawValue
        
        validCommand[2] = settingType.rawValue
        
        let sendStimVal = stimVal
        validCommand[3] = UInt8(0xff & (sendStimVal >> 8))
        validCommand[4] = UInt8(0xff & (sendStimVal % 256))

        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    //MARK: -- 20 压力参数设定指令  inflatedTime 充气时间，数值范围5~2000，单位0.1s，即有效值为0.5s~200s；
    @objc class func  commandPressureParamAdjustment(pressureVal:UInt,inflatedTime:UInt = 20) -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.pressureParamSetting.rawValue
        
        validCommand[1] = UInt8(0xff & (pressureVal >> 8))
        validCommand[2] = UInt8(0xff & (pressureVal % 256))
        
        validCommand[3] = UInt8(0xff & (inflatedTime >> 8))
        validCommand[4] = UInt8(0xff & (inflatedTime % 256))
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    //MARK: -- 21 压力模块控制指令
    @objc enum LT3rdPressureControlType:UInt8 {
        case inflateStart = 0x01 //01充气开始
        case inflateEnd = 0x02 //02充气结束
        case vacuumingStart = 0x03 //03放气开始
        case vacuumingEnd = 0x4 //放气结束；
    }
    @objc enum LT3rdInflateMode:UInt8 {
        case smart = 0x01 //01智能充气
        case notSmart = 0x02 //02非智能充气
    }
    @objc public class func  commandPressureModeControl(controlType:LT3rdPressureControlType,inflateMode:LT3rdInflateMode = .smart) -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.pressureModeControl.rawValue
        
        validCommand[1] = controlType.rawValue
        validCommand[2] = inflateMode.rawValue
        
        validCommand[3] = 0xff
        validCommand[4] = 0xff
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    
    //MARK: -- 22 压力模块开始采集指令
    @objc class func  commandPressureCollectStart() -> Data{
        //有效数据长度
        let length:UInt8 = 0x03
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: Int(length))
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.pressureCollectControl.rawValue
        
        validCommand[1] = 0x01
        validCommand[2] = 0xff
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    //MARK: -- 22 压力模块停止采集指令
    @objc class func  commandPressureCollectStop() -> Data{

        //有效数据长度
        let length:UInt8 = 0x03
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: Int(length))
        //命令
        validCommand[0] = LT_3rdCommandTypeWrite.pressureCollectControl.rawValue
        
        validCommand[1] = 0x02
        validCommand[2] = 0xff
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Write(), length: length, validCommand: validCommand)
    }
    
    // 升级握手指令
    @objc static func commandUpgradeShakeHand(shakeData:[UInt8]) -> Data{
        // 指令组成：头+长度+有效数据+填充+crc校验和
        // 数据头
        let length:UInt8 = 0x05
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        validCommand[0] = LT_3rdCommandUpgradeWrite.shakeHand.rawValue;
        
        if shakeData.count > 3 {
            validCommand[1] = shakeData[0]
            validCommand[2] = shakeData[1]
            validCommand[3] = shakeData[2]
            validCommand[4] = shakeData[3]
        }
        return thirdCommandCreat(head: thirdCommandHeadBytes_Upgrade(), length: length, validCommand: validCommand)
    }
    
    
    //握手选择模块指令
    @objc class func commandUpgradeSeletModelHand() -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: Int(length))
        //命令
        validCommand[0] = LT_3rdCommandUpgradeWrite.selectModel.rawValue;
        validCommand[1] = 0x01 //选择升级模块序号1-32 目前只有1
        validCommand[2] = 0x00
        validCommand[3] = 0x00
        validCommand[4] = 0x00
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Upgrade(), length: length, validCommand: validCommand)
    }
    
    
    //跳转boot
    @objc class func commandUpgradeBoot() -> Data {
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: Int(length))
        //命令
        validCommand[0] = LT_3rdCommandUpgradeWrite.upgradeBoot.rawValue;
        validCommand[1] = 0x20 //选择升级模块序号1-32 目前只有1
        validCommand[2] = 0x13
        validCommand[3] = 0x01
        validCommand[4] = 0x16
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Upgrade(), length: length, validCommand: validCommand)
    }
    
    //索要种子
    @objc class func commandUpgradeSeed() -> Data {
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: Int(length))
        //命令
        validCommand[0] = LT_3rdCommandUpgradeWrite.upgradeSeed.rawValue;
        validCommand[1] = 0x20 //选择升级模块序号1-32 目前只有1
        validCommand[2] = 0x13
        validCommand[3] = 0x01
        validCommand[4] = 0x16
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Upgrade(), length: length, validCommand: validCommand)
    }
    
    @objc static func commandUpgradeKey(seedData:[UInt8]) -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: Int(length))
        //命令
        validCommand[0] = LT_3rdCommandUpgradeWrite.upgradeKey.rawValue;
        validCommand[1] = seedData[0]
        validCommand[2] = seedData[1]
        validCommand[3] = seedData[2]
        validCommand[4] = seedData[3]
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Upgrade(), length: length, validCommand: validCommand)
    }
    
    @objc static func commandUpgradeStartAddress(seedData:[UInt8]) -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: Int(length))
        //命令
        validCommand[0] = LT_3rdCommandUpgradeWrite.upgardeAdress.rawValue;
        validCommand[1] = seedData[0]
        validCommand[2] = seedData[1]
        validCommand[3] = seedData[2]
        validCommand[4] = seedData[3]
        return thirdCommandCreat(head: thirdCommandHeadBytes_Upgrade(), length: length, validCommand: validCommand)
    }
    
    @objc static func commandUpgradeFlashSize(seedData:[UInt8]) -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: Int(length))
        //命令
        validCommand[0] = LT_3rdCommandUpgradeWrite.upgardeFlashSize.rawValue;
        validCommand[1] = seedData[0]
        validCommand[2] = seedData[1]
        validCommand[3] = seedData[2]
        validCommand[4] = seedData[3]
        return thirdCommandCreat(head: thirdCommandHeadBytes_Upgrade(), length: length, validCommand: validCommand)
    }
    
    @objc static func commandUpgradeFlash() -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: Int(length))
        //命令
        validCommand[0] = LT_3rdCommandUpgradeWrite.upgradeFlash.rawValue;
        validCommand[1] = 0x20
        validCommand[2] = 0x13
        validCommand[3] = 0x01
        validCommand[4] = 0x16
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Upgrade(), length: length, validCommand: validCommand)
    }
    
    @objc static func commandUpgradeData(data:[UInt8], blockNum:Int) -> Data{
        // 指令组成：头+长度+有效数据+填充+crc校验和
        // 数据头
        let blockNumber = blockNum + 1
        var headCommand:[UInt8] = [UInt8](repeating: 0, count: 2)
        headCommand[0] = 0xaa
        headCommand[1] = 0xab
        // 数据长度
        let length:UInt8 = 0x83
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8]()
        validCommand.append(LT_3rdCommandUpgradeWrite.upgradeData.rawValue)
        validCommand.append(UInt8(0xff & (blockNumber >> 8)))
        validCommand.append(UInt8(0xff & blockNumber))
        //填充数据
        validCommand.append(contentsOf: data)
        
        var resultCommad:[UInt8] = [UInt8]()
        resultCommad.append(contentsOf: headCommand)
        resultCommad.append(0x00)  //长度高位 ,没超过255 写死 0
        resultCommad.append(length)
        resultCommad.append(contentsOf: validCommand)
        resultCommad.append(contentsOf: MD_VerfifyTool.crcVerfifyCode_Cal(bytes: validCommand))
        let resultData:Data = Data(bytes: resultCommad, count: resultCommad.count);
        return resultData
    }
    
    //发送数据完成
    @objc static func commandUpgradeFinish(calData:[UInt8]) -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: Int(length))
        //命令
        validCommand[0] = LT_3rdCommandUpgradeWrite.upgradeFinsh.rawValue;
        validCommand[1] = calData[0]
        validCommand[2] = calData[1]
        validCommand[3] = calData[2]
        validCommand[4] = calData[3]
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Upgrade(), length: length, validCommand: validCommand)
    }
    
    //发送数据完成
    @objc static func commandUpgradeAPP() -> Data{
        //有效数据长度
        let length:UInt8 = 0x05
        //有效数据数组
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: Int(length))
        //命令
        validCommand[0] = LT_3rdCommandUpgradeWrite.upgaradeApp.rawValue;
        validCommand[1] = 0x20
        validCommand[2] = 0x13
        validCommand[3] = 0x01
        validCommand[4] = 0x16
        
        return thirdCommandCreat(head: thirdCommandHeadBytes_Upgrade(), length: length, validCommand: validCommand)
    }
    
    
    
}
