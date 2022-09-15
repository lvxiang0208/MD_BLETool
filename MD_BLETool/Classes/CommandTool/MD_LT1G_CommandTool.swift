//
//  MD_LT1G_CommandTool.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/14.
//

import UIKit

//下行控制指令,写指令
enum LT_1rdCommandTypeWrite:UInt8 {
    case PulseWidth = 0x11  // 脉宽
    case Frequency = 0x12 // 频率
    case Electricity = 0x13 // 电流
    case RiseTime = 0x14// 上升时间
    case FallTime = 0x15// 下降时间
    case StimStart = 0x16// 刺激开始
    case WatchDog = 0x17// 喂狗
    case EMGBFStartOrStop = 0x18// 触发电刺激开始/停止
    case DeviceWakeUp = 0x19// 设备唤醒
    case ElectricityNewVersion = 0x1A // 新版本电流
    case EEPROMRead = 0x20 //0x20 读取EEPROM指令
    //0x30 清除测试数据计数
    //0x31 进行一轮数据测试后，读取下位机统计的测试状态
}

//开始和结束刺激指令
enum Lanting1GStimStatus:UInt8 {
    case Start = 0x01 // 开始刺激
    case End = 0x02 // 结束刺激
}
//开始采集和结束采集指令
enum Lanting1GCollectionStatus:UInt8 {
    case Start = 0x01// 开始采集
    case End = 0x02 // 结束采集
}

// 读EEPROM目标块
enum Lanting1GEPROMBlockType:UInt8 {
    case Model = 0x00 // 型号
    case SerialNumber = 0x01 // 序列号
    case BuildInScheme = 0x02 // 内置方案
    case ActivationDate = 0x03 // 激活日期
};

enum Lanting1GNotifyType {
    case Status //状态上传
    case Collection //采集数据
    case StimCurrent //刺激电流反馈
    case EEPROM //EEPROM块信息上传
}
///上行数据相关
//状态指令头
let kCommand1GHeaderStatus = 0xaa;
//采集指令头
let kCommand1GHeaderCollection = 0xbb;
//刺激电流信息头
let kCommand1GHeaderStim = 0xcc;
//EEPROM指令头
let kCommand1GHeaderEEPROM = 0xee;

// 放大倍数
let magnifications:Double = 2000;
let calculateUV = 3000000.0 / 4095.0;

let dataSmoothLength = 40;
/// 澜渟一代指令工具
class MD_LT1G_CommandTool: NSObject {

    /// 澜渟一代约定的指令头部
    /// - Returns: 澜渟一代约定的指令头部 0xaa 0xbb 开头
    func commandHeaderCommonWrite1G()->[UInt8] {
        var command:[UInt8] = [UInt8]();
        command.append(UInt8(kCommand1GHeaderStatus));
        command.append(UInt8(kCommand1GHeaderCollection));
        return command;
    }
    
    
    /// 一代写指令方法
    /// - Parameters:
    ///   - validCommand: 有效指令数组
    ///   - head: 包头数组，可缺省
    /// - Returns: Data
    func firstCommandCreat( validCommand:[UInt8], head:[UInt8]? = nil) -> Data {
        var headerCommand:[UInt8] = [UInt8]();
        var resultCommand:[UInt8] = [UInt8]();

        if head != nil {
            headerCommand = head!;
        } else {
            headerCommand = commandHeaderCommonWrite1G();
        }
        resultCommand.append(contentsOf: headerCommand);
        resultCommand.append(contentsOf: validCommand);
        resultCommand.append(MD_VerfifyTool.sumVerfifyCode_Cal(bytes: validCommand))
        let resultData:Data = Data(bytes: resultCommand, count: resultCommand.count);

        var sendString:String = ""
        for i in 0..<resultCommand.count {
            let strVal:String = String(format: "%x  ", resultCommand[i])
            sendString.append(strVal)
        }
        return resultData
    }
    
    /// 开始和结束刺激
    /// - Parameter stimStatus: 的状态:开始和结束
    /// - Returns: 开始和结束刺激命令
    func commandStim(stimStatus:Lanting1GStimStatus) -> Data {
        var validCommand:[UInt8] = [UInt8]();
        validCommand.append(LT_1rdCommandTypeWrite.StimStart.rawValue);
        validCommand.append(stimStatus.rawValue)
        validCommand.append(UInt8(0x00))
        return firstCommandCreat(validCommand: validCommand);
    }
    
    
    /// 开始和结束采集指令
    /// - Parameter commandStatus:
    /// - Returns: Data
    func commandCollection(commandStatus:Lanting1GCollectionStatus) -> Data {
        var validCommand:[UInt8] = [UInt8]();
        validCommand.append(LT_1rdCommandTypeWrite.EMGBFStartOrStop.rawValue);
        validCommand.append(commandStatus.rawValue)
        validCommand.append(UInt8(0x00))
        return firstCommandCreat(validCommand: validCommand);
    }
    
    
    /// 心跳指令
    /// - Returns: Data
    func commandHeartBeat1G() -> Data {
        var validCommand:[UInt8] = [UInt8]();
        validCommand.append(LT_1rdCommandTypeWrite.WatchDog.rawValue);
        validCommand.append(UInt8(0x01))
        validCommand.append(UInt8(0x00))
        return firstCommandCreat(validCommand: validCommand);
    }
    
    
    /// 读取EEPROM
    /// - Parameter commandType: Lanting2GEEPROMBlockType
    /// - Returns: Data
    func commandReadEEPROM1G(commandType:Lanting1GEPROMBlockType) -> Data {
        var validCommand:[UInt8] = [UInt8]();
        validCommand.append(LT_1rdCommandTypeWrite.EEPROMRead.rawValue);
        validCommand.append(commandType.rawValue)
        validCommand.append(UInt8(0x00))
        return firstCommandCreat(validCommand: validCommand);
    }
    
    
    /// 写激活日期
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    ///   - day: 日
    /// - Returns: Data
    func commandNotifyEEPROM1GActivationDate(year:Int, month:Int, day:Int)->Data {
        var validCommand:[UInt8] = [UInt8]();
        validCommand.append(UInt8(kCommand1GHeaderEEPROM));
        validCommand.append(Lanting1GEPROMBlockType.ActivationDate.rawValue)
        validCommand.append(UInt8(year%100))
        validCommand.append(UInt8(month))
        validCommand.append(UInt8(day))
        let sumInt = (UInt(validCommand[2]) + UInt(validCommand[3]) + UInt(validCommand[4]) + 251)*3
        validCommand.append(UInt8(sumInt % 256))
        let lastSumInt = UInt(validCommand[1])+UInt(validCommand[2])+UInt(validCommand[3])+UInt(validCommand[4])+UInt(validCommand[5])
        validCommand.append(UInt8(lastSumInt % 256));
        return firstCommandCreat(validCommand: validCommand);
    }
    
    
    /// 刺激相关指令
    /// - Parameters:
    ///   - stimType: 指令类型
    ///   - value: 指令参数
    /// - Returns: Data
    func commandStimParam(stimType:LT_1rdCommandTypeWrite,value:Int) -> Data {
        var validCommand:[UInt8] = [UInt8]();
        //刺激对应的类型
        validCommand.append(stimType.rawValue)
        //刺激对应的参数
        if stimType == .PulseWidth {
            //波宽特殊处理
            validCommand.append(UInt8(value/256));
            validCommand.append(UInt8(value%256))
        } else if stimType == .RiseTime || stimType == .FallTime {
            //上升和下降时间特殊处理
            validCommand.append(UInt8(value*10));
            validCommand.append(UInt8(0x00))
        } else {
            validCommand.append(UInt8(value%256));
            validCommand.append(UInt8(0x00))
        }
        
        return firstCommandCreat(validCommand: validCommand);
    }
    
    
    

    
}
