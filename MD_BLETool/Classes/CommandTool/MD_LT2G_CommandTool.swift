//
//  MD_LT2G_CommandTool.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/14.
//

import UIKit

func secondCommandHeadBytes_Write() -> [UInt8] {
    var result:[UInt8] = [UInt8](repeating: 0, count: 2)
    result[0] = 0xaa
    result[1] = 0xa7
    return result
}

func secondCommandHeadBytes_Notify() -> [UInt8] {
    var result:[UInt8] = [UInt8](repeating: 0, count: 2)
    result[0] = 0xbb
    result[1] = 0xa7
    return result
}

/// 填充数据完整性
/// @param length 长度
func secondCommandComplete(length:Int) -> [UInt8] {
    var result:[UInt8] = [UInt8](repeating: 0, count: length)
    for i in 0..<length {
        result[i] = 0xff
    }
    return result
}

// 二代指令组成
/// - Parameters:
///   - head: 包头数组
///   - length: 包长度
///   - validCommand: 有效指令数组
/// - Returns: Data
func secondCommandCreat(head:[UInt8], length:UInt8, validCommand:[UInt8],userless:[UInt8]) -> Data {
    var resultCommad:[UInt8] = [UInt8]()
    resultCommad.append(contentsOf: head)
    resultCommad.append(length)
    resultCommad.append(contentsOf: validCommand)
    let crcVerify = MD_VerfifyTool.crcVerfifyCode_Cal(bytes: validCommand)
    resultCommad.append(contentsOf:userless)
    resultCommad.append(contentsOf:crcVerify)
    let resultData:Data = Data(bytes: resultCommad, count: resultCommad.count);
    
    var sendString:String = ""
    for i in 0..<resultCommad.count {
        let strVal:String = String(format: "%x  ", resultCommad[i])
        sendString.append(strVal)
    }
    return resultData
}



// 指令类型
@objc enum LT2GCommandType:UInt8 {
    case Shake = 0x01 // 握手指令
    case Status = 0x02 // 查询设备状态指令（心跳）
    case EEPROMNotify = 0x03 // 从下位机读EEPROM
    case EEPROMWrite = 0x04 // 写入下位机EEPROM
    case Stim = 0x05 // 刺激
    case Control = 0x06 // 控制指令
    case StimCurrent = 0x07 // 刺激电流调节，反馈
    case Error = 0x08 // 串口指令错误
    case UpgradeShake = 0x81 // 升级握手指令
    case UpgradeBoot = 0x82 // 跳转boot层指令
    case UpgradeSeed = 0x83 // 索要种子数据指令
    case UpgradeKey = 0x84 // 发送密钥数据指令
    case UpgradeFlash = 0x85 // 擦除flash指令
    case UpgradeData = 0x86 // 发送需要升级的数据包指令
    case UpgradeFinish = 0x87 // 发送数据完成指令
    case UpgradeAPP = 0x88 // 跳转APP指令
}

// 控制指令类型
@objc enum LT2GControlType:UInt8 {
    case Default = 0x00 // 默认
    case CollectionBegin = 0x01 // 采集开始
    case CollectionEnd = 0x02 // 采集结束
    case StimBegin = 0x03 // 刺激开始
    case StimEnd = 0x04 // 刺激结束
    case CanHeat = 0x05 // 可以加热
    case ProhibitHeat = 0x06 // 禁止加热
    case Close = 0x07 // 关机
    case FrequencyScalingStimBegin = 0x08 // 变频电刺激开始
    case StimBeginNoElectrodeStatus = 0x09 // 刺激开始(屏蔽电极片脱落)
    case FrequencyScalingStimBeginNoElectrodeStatus = 0x0A // 变频刺激开始(屏蔽电极片脱落)
}

/**
enum Lanting2GCommandHeader:UInt8 {
    case Write  = 0xaa  // 写入下位机的头
    case Notify = 0xbb  // 从下位机读的头
    case Collect = 0xa8 // 采集头
    case Common = 0xa7  // 澜渟2G通用头
}**/

// 读EEPROM目标块
@objc enum Lanting2GEPROMBlockType:UInt8 {
    case Model = 0x00 // 型号
    case SerialNumber = 0x01 // 序列号
    case BuildInScheme = 0x02 // 内置方案
    case ActivationDate = 0x03 // 激活日期
}

// 腹肌通道
@objc enum LT2GAbsChannel:UInt8 {
    case Access = 0x01 // 腹肌通道接入
    case NoAccess = 0x02 // 腹肌通道未接入
}
// 阴道电极状态
@objc enum LTElectrodeStatus:UInt8 {
    case Unknow = 0x00 // 未知（默认）
    case Touch = 0x01 // 通道接触到人
    case NoTouch  = 0x02 //通道未接触到人
}


class MD_LT2G_CommandTool: NSObject {

    /// 01 - 握手指令
    /// - Returns: Data
    @objc static func commandShakeHand() -> Data{
        //AA A7 01 01 FF FF FF FF FF FF FF FF FF 80 7E
        // 指令组成：头+长度+有效数据+填充+crc校验和
        // 数据长度
        let length:UInt8 = 0x01
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 1)
        validCommand[0] = 0x01
        let userless = secondCommandComplete(length: 9)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    /// 02 - 心跳指令（查询设备状态指令）
    /// - Returns: Data
    @objc static func commandHeartBeat() -> Data{
        //AA A7 01 01 FF FF FF FF FF FF FF FF FF 80 7E
        // 指令组成：头+长度+有效数据+填充+crc校验和
        // 数据长度
        let length:UInt8 = 0x01
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 1)
        validCommand[0] = 0x02
        let userless = secondCommandComplete(length: 9)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    /// 03 - 读取EEPROM块指令
    /// - Parameter blockNum: blockNum description
    /// - Returns: Data
    @objc static func  readEPPROM(blockNum:Lanting2GEPROMBlockType) -> Data{
        // 读EEPROM指令
        // AA A7 02 03 01 FF FF FF FF FF FF FF FF 80 c0
        // 指令组成：头+长度+有效数据+填充+crc校验和
        
        //数据长度
        let length:UInt8 = 0x02
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 2)
        validCommand[0] = 0x03
        validCommand[1] = blockNum.rawValue
        let userless = secondCommandComplete(length: 8)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    //04 写入EEPROM块指令
    @objc static func writeEPPROM(blockNum:Lanting2GEPROMBlockType) -> Data{
        // AA A7 02 03 01 FF FF FF FF FF FF FF FF 80 c0
        // 指令组成：头+长度+有效数据+填充+crc校验和
        //数据长度
        let length:UInt8 = 0x02
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 3)
        validCommand[0] = 0x04
        validCommand[1] = blockNum.rawValue
        let userless = secondCommandComplete(length: 8)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    //06 写EEPROM指令（激活时间）
    @objc static func writeEPPROMActiveDate(year:UInt, month:UInt, day:UInt) -> Data{
        // AA A7 02 03 01 FF FF FF FF FF FF FF FF 80 c0
        // 指令组成：头+长度+有效数据+填充+crc校验和
        //数据长度
        let length:UInt8 = 0x0a
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 6)
        validCommand[0] = 0x04
        validCommand[1] = Lanting2GEPROMBlockType.ActivationDate.rawValue
        validCommand[2] = UInt8(year%100)
        validCommand[3] = UInt8(month)
        validCommand[4] = UInt8(day)
        let sumInt = (UInt(validCommand[2]) + UInt(validCommand[3]) + UInt(validCommand[4]) + 251)*3
        validCommand[5] = UInt8(sumInt % 256)
        
        let userless = secondCommandComplete(length: 4)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    // 控制指令
    @objc static func commandControl(type:LT2GControlType, channel:LT2GAbsChannel) -> Data{
        // 指令组成：头+长度+有效数据+填充+crc校验和
        //数据长度
        let length:UInt8 = 0x03
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 3)
        validCommand[0] = 0x06
        validCommand[1] = type.rawValue // 电流0~70mA，1mA调节。
        validCommand[2] = channel.rawValue

        let userless = secondCommandComplete(length: 7)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    // 刺激方案参数指令
    @objc static func commandStimParams(frequency:UInt, pulseWidth:UInt, electricity:UInt, riseTime:UInt, fallTime:UInt, workTime:UInt, restTime:UInt) -> Data{
        //数据长度
        let length:UInt8 = 0x09
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 9)
        validCommand[0] = 0x05 // 命令类型
        validCommand[1] = 0x02 //波形。01为单向波，02为双向波；
        validCommand[2] = UInt8(frequency) // 频率5~200HZ，1HZ调节；
        validCommand[3] = UInt8(pulseWidth / 10) // 脉宽50~400us，10us调节；需要发送5~40，下位机做乘10处理；
        validCommand[4] = UInt8(electricity) // 电流0~70mA，1mA调节；
        validCommand[5] = UInt8(riseTime * 10) // 上升时间,0~20s可调，0.1s调节；需要发送0~200，下位机做除以10处理
        validCommand[6] = UInt8(fallTime * 10) // 下降时间,同上
        validCommand[7] = UInt8(workTime * 10) // 工作时间,同上
        validCommand[8] = UInt8(restTime * 10) // 休息时间,同上

        let userless = secondCommandComplete(length: 1)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    // 变频刺激方案参数指令
    @objc static func commandFrequencyScalingStimParams(frequency2:UInt, frequency3:UInt, pulseWidth2:UInt, pulseWidth3:UInt, frequencyScalingDuration:UInt) -> Data{
        // 指令组成：头+长度+有效数据+填充+crc校验和
        //数据长度
        let length:UInt8 = 0x07
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 7)
        validCommand[0] = 0x09
        validCommand[1] = UInt8(frequency2) // 频率2：5~200HZ，1HZ调节；
        validCommand[2] = UInt8(frequency3) // 频率3：5~200HZ，1HZ调节；
        validCommand[3] = UInt8(pulseWidth2 / 10) // 脉宽2：50~400us，10us调节；需要发送5~40，下位机做乘10处；
        validCommand[4] = UInt8(pulseWidth3 / 10) // 脉宽3：50~400us，10us调节；需要发送5~40，下位机做乘10处理；
        // 变频时间。20~500，单位0.1s，变频电刺激时间的设定要求是工作时间=上升时间+下降时间+变频时间，
        // 其中变频时间最小为2s，最大为50s；如果工作时间和休息时间都为0，即变频连续工作，手机端同样发送变频时间；
        let fsH:UInt8 = UInt8(0xff & (frequencyScalingDuration >> 8));
        let fsL:UInt8 = UInt8(0xff & (frequencyScalingDuration % 256))
        validCommand[5] = fsH // 高位
        validCommand[6] = fsL // 低位
        let userless = secondCommandComplete(length: 3)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    // 刺激电流调节指令
    @objc static func commandSetStimCurrent(value:UInt) -> Data{
        // AA A7 09 05 01 64 0A 32 0A 0A 64 64 FF 35 e0
        // 指令组成：头+长度+有效数据+填充+crc校验和
        //数据长度
        let length:UInt8 = 0x02
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 2)
        validCommand[0] = 0x07
        validCommand[1] = UInt8(value) // 电流0~70mA，1mA调节。
        let userless = secondCommandComplete(length: 8)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    // 升级握手指令
    @objc static func commandUpgradeShakeHand() -> Data{
        // 指令组成：头+长度+有效数据+填充+crc校验和
        // 数据头
        let length:UInt8 = 0x05
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        validCommand[0] = LT2GCommandType.UpgradeShake.rawValue;
        validCommand[1] = 0x20;
        validCommand[2] = 0x13;
        validCommand[3] = 0x01;
        validCommand[4] = 0x16;
        let userless = secondCommandComplete(length: 5)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }

    
    // 跳到boot层指令
    @objc static func commandUpgradeBoot() -> Data{
        // 指令组成：头+长度+有效数据+填充+crc校验和
        // 数据头
        let length:UInt8 = 0x05
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        validCommand[0] = LT2GCommandType.UpgradeBoot.rawValue;
        validCommand[1] = 0x20;
        validCommand[2] = 0x13;
        validCommand[3] = 0x01;
        validCommand[4] = 0x16;
        let userless = secondCommandComplete(length: 5)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    // 索要种子数据指令
    @objc static func commandUpgradeSeed() -> Data{
        // 指令组成：头+长度+有效数据+填充+crc校验和
        // 数据头
        let length:UInt8 = 0x05
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        validCommand[0] = LT2GCommandType.UpgradeSeed.rawValue;
        validCommand[1] = 0x20;
        validCommand[2] = 0x13;
        validCommand[3] = 0x01;
        validCommand[4] = 0x16;
        let userless = secondCommandComplete(length: 5)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    // 发送密钥数据指令
    @objc static func commandUpgradeKey(seedData:[UInt8]) -> Data{
        // 指令组成：头+长度+有效数据+填充+crc校验和
        // 数据头
        let length:UInt8 = 0x05
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        validCommand[0] = LT2GCommandType.UpgradeKey.rawValue;
        validCommand[1] = seedData[0];//0x20;
        validCommand[2] = seedData[1];
        validCommand[3] = seedData[2];
        validCommand[4] = seedData[3];
        let userless = secondCommandComplete(length: 5)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    // 擦除flash指令
    @objc static func commandUpgradeFlash() -> Data{
        // 指令组成：头+长度+有效数据+填充+crc校验和
        // 数据头
        let length:UInt8 = 0x05
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        validCommand[0] = LT2GCommandType.UpgradeFlash.rawValue;
        validCommand[1] = 0x20;
        validCommand[2] = 0x13;
        validCommand[3] = 0x01;
        validCommand[4] = 0x16;
        let userless = secondCommandComplete(length: 5)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    
    /// 发送需要升级的数据包指令
    @objc static func commandUpgradeData(data:Data, blockNum:Int) -> Data{
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
        validCommand.append(LT2GCommandType.UpgradeData.rawValue)
        validCommand.append(UInt8(0xff & (blockNumber >> 8)))
        validCommand.append(UInt8(0xff & blockNumber))
        //填充数据
        validCommand.append(contentsOf: data)
        return secondCommandCreat(head: headCommand, length: length, validCommand: validCommand,userless: [])
    }
    // 发送数据完成指令
    @objc static func commandUpgradeFinish() -> Data{
        // 指令组成：头+长度+有效数据+填充+crc校验和
        // 数据头
        let length:UInt8 = 0x05
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        validCommand[0] = LT2GCommandType.UpgradeFinish.rawValue;
        validCommand[1] = 0x20;
        validCommand[2] = 0x13;
        validCommand[3] = 0x01;
        validCommand[4] = 0x16;
        let userless = secondCommandComplete(length: 5)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
    }
    /// 跳转APP指令
    @objc static func commandUpgradeAPP() -> Data{
        // 指令组成：头+长度+有效数据+填充+crc校验和
        // 数据头
        let length:UInt8 = 0x05
        //可计入校验和的有效数据
        var validCommand:[UInt8] = [UInt8](repeating: 0, count: 5)
        validCommand[0] = LT2GCommandType.UpgradeAPP.rawValue;
        validCommand[1] = 0x20;
        validCommand[2] = 0x13;
        validCommand[3] = 0x01;
        validCommand[4] = 0x16;
        let userless = secondCommandComplete(length: 5)
        return secondCommandCreat(head: secondCommandHeadBytes_Write(), length: length, validCommand: validCommand,userless: userless)
        
    }
    
}



