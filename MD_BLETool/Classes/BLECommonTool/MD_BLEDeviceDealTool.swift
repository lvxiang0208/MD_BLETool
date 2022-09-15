//
//  MD_BLEDeviceDealTool.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/15.
//

import UIKit
import CoreBluetooth

////一代设备名称
//let lt_1G_BLENames = ["Medlander","MLD-V2"]
//// 澜渟2G
//let lt_2G_BLENames = ["MD-01","MD-01","MD-A1","MD-A2","MD-A3","MD-A4","MD-A5","MD-B1","MD-B2","MD-B3","MD-B4","MD-PL10","MD-PL20","MD-PL21","MD-PL22","MD-PL36","MD-PM60","MD-PM70","MD-PQ80","MD-PQ88"]
//let lt_2G_BLESerialName = ["A1CA","A2CA","A3CA","A4CA","A5CA","A6CA","A7CA","A8CA","B1CA","B2CA","B3CA","B4CA","C5CA","C6CA","C7CA","C8CA"]
//let lt_2G_NewerBLENames = ["MD2222222"]
//// 澜渟3G
//let lt_3G_BLENames = ["MD2"]

let APP_DOC_PATH_BLE = NSHomeDirectory() + "/Documents/"

//蓝牙型号加序列号保存本地key YYCache
let kDeviceSerialNumberCache = "deviceSerialNumberCache"
let kDeviceSerialNumberKey = "deviceSerialNumberKey"

let Full_PercentBattery = 4.12   //4.15->4.12
let Ninety_PercentBattery = 4.05   //4.06->4.05
let Eighty_PercentBattery = 3.98
let Seventy_PercentBattery = 3.92
let Sixty_PercentBattery = 3.87
let Fifty_PercentBattery = 3.82
let Fourty_PercentBattery = 3.79
let Thirty_PercentBattery = 3.77
let Twenty_PercentBattery = 3.74
let Ten_PercentBattery = 3.68
let Five_PercentBattery = 3.45
let Zero_PercentBattery = 3.00

class MD_BLEDeviceDealTool: NSObject {
    
    /// 是否是合理的外设名称
    /// - Parameter name: 外设名称
    /// - Returns: Bool
    static func isValidPeripheralName(name: String) -> Bool {
        // 1G
        for constantName in MD_BLEConnectManager.shared.lt_1G_BLENames {
            if name.hasPrefix(constantName) {
                return true
            }
        }
        // 2G
        for constantName in MD_BLEConnectManager.shared.lt_2G_BLENames {
            if name.hasPrefix(constantName) {
                return true
            }
        }
        // 3G
        for constantName in MD_BLEConnectManager.shared.lt_NewerBLENames {
            if name.hasPrefix(constantName) {
                return true
            }
        }
        for constantName in MD_BLEConnectManager.shared.lt_DFUBLENames {
            if name.hasPrefix(constantName) {
                return true
            }
        }
        return false
    }
    
    
    /// 获取设备类型
    /// - Parameter peripheral: CBPeripheral
    /// - Returns: MD_DeviceType
    @objc static func getDeviceTypeByPeripheral(peripheral: CBPeripheral) -> MD_DeviceType {
        var peripheralName: String = peripheral.name ?? ""
        peripheralName = peripheralName.trimmingCharacters(in: .whitespacesAndNewlines)
        // 1G
        for constantName in MD_BLEConnectManager.shared.lt_1G_BLENames {
            if peripheralName.hasPrefix(constantName) {
                return .lt_1G
            }
        }
        // 2G
        for constantName in MD_BLEConnectManager.shared.lt_2G_BLENames {
            if peripheralName.hasPrefix(constantName) {
                return .lt_2G
            }
        }
        // 3G
        for constantName in MD_BLEConnectManager.shared.lt_NewerBLENames {
            if peripheralName.hasPrefix(constantName) {
                return .lt_other
            }
        }
        // 3G
        for constantName in MD_BLEConnectManager.shared.lt_DFUBLENames {
            if peripheralName.hasPrefix(constantName) {
                return .lt_other
            }
        }
        return .lt_1G
    }
    
    /// 获取信号等级
    /// @param value 信号值
    static func getBLERSSILevelByValue(value: Int) -> MD_BLERSSILEVEL {
        var rssi: Int = value + 100
        if rssi < 0 {
            rssi = 0
        }else if rssi > 100 {
            rssi = 100
        }
        if rssi >= 40 {  //-60 ~ 0
            return .full;  //满格
        }
        else if rssi >= 30 {//-60 ~ -70
            return .strong
        }
        else if rssi >= 20 {//-70 ~ -80
            return .middle
        }
        return .weak
    }
    
    static func getSerialNumber(year:UInt, number:UInt) -> String {
        // 年份
        let str1 = self.getCharacterByNumber(number: year/10)
        let str2 = self.getCharacterByNumber(number: year%10)
        let yearStr = NSString(format: "CA%@%@", str1, str2)
        // 5位数编号，不满5位补0
        let numberStr = NSString(format: "%05lu", number)
        return NSString(format: "%@%@", yearStr,numberStr) as String
    }
    
    /**
     产品激活年份数字转字符对应表

     @param number 年份中的某一位，如：2019中的9
     @return 对应的字母
     */
    static func getCharacterByNumber(number:UInt) -> String{
        switch (number) {
            case 0: return "A"
            case 1: return "B"
            case 2: return "C"
            case 3: return "D"
            case 4: return "E"
            case 5: return "F"
            case 6: return "G"
            case 7: return "H"
            case 8: return "I"
            case 9: return "J"
            default:
                break;
        }
        return "";
    }
    
    //文件、文件夹有关
    static func createDirectory(path:String){
        let fileManger = FileManager.default
        if !fileManger.fileExists(atPath: path) {
            try! fileManger.createDirectory(atPath:path, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    /// 固件升级地址 + 文件名, 业务下载bin或hex文件存到该文件夹下
    static func getLanTingDataPath() -> String{
        let homeDirectory = APP_DOC_PATH_BLE
        let path = homeDirectory + "LandTingData"
        self.createDirectory(path: path)
        return path
    }
    
    static func dateYear(date:Date) -> Int {
        //设置成中国阳历
        let calendar = Calendar.init(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        return year
    }
    
    static func dateMonth(date:Date) -> Int {
        //设置成中国阳历
        let calendar = Calendar.init(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        return month
    }
    
    static func dateDay(date:Date) -> Int {
        //设置成中国阳历
        let calendar = Calendar.init(identifier: .gregorian)
        let day = calendar.component(.day, from: date)
        return day
    }
    
    static func dateFromString(str:String) -> Date {
        let dateFormat = Utils.dateFormatter() ?? DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormat.date(from: str) ?? Date()
    }
    
    static func getDisplayName(model:String) -> String {
        let configs = MD_BLEConnectManager.shared.lt_deviceConfig
        for dic in configs {
            let str = dic["model"] ?? ""
            if str == model.uppercased() {
                return dic["name"] ?? ""
            }
        }
        return "未知"
    }
    
    static func getShortName(model:String) -> String {
        let configs = MD_BLEConnectManager.shared.lt_deviceConfig
        for dic in configs {
            let str = dic["model"] ?? ""
            if str == model.uppercased() {
                return str
            }
        }
        return "未知"
    }
    
    //获取搜索页面展示的前缀
    @objc static func getSearchShowName(model:String) -> String {
        let configs = MD_BLEConnectManager.shared.lt_deviceConfig
        for dic in configs {
            let str = dic["model"] ?? ""
            if str == model.uppercased() {
                return dic["cn_name"] ?? ""
            }
        }
        return "盆底康复仪"
    }
    
 /*
    static func getLT1GDisplayName(model : MD_LT_1G_DeviceModel) -> String {
        var modelName = ""
        switch model {
        case .none:
            modelName = "无"
            break
        case .all:
            modelName = "全功能版"
            break
        case .a0:
            modelName = "MLD A0"
            break
        case .h1s:
            modelName = "MLD H1S"
            break
        case .h1t:
            modelName = "MLD H1T"
            break
        case .h2s:
            modelName = "MLD H2S"
            break
        case .h2t:
            modelName = "MLD H2T"
            break
        case .h3s:
            modelName = "MLD H3S"
            break
        case .h3t:
            modelName = "MLD H3T"
            break
        case .hc:
            modelName = "MLD HC"
            break
        case .ht:
            modelName = "MLD HT"
        case .hl:
            modelName = "MLD HL"
            break
        default:
            modelName = "无"
            break
        }
        return modelName
    }
    
    static func getLT1GDisplayNameShort(model : MD_LT_1G_DeviceModel) -> String {
        var modelName = ""
        switch model {
        case .none:
            modelName = "无"
            break
        case .all:
            modelName = "全功能版"
            break
        case .a0:
            modelName = "A0"
            break
        case .h1s:
            modelName = "H1S"
            break
        case .h1t:
            modelName = "H1T"
            break
        case .h2s:
            modelName = "H2S"
            break
        case .h2t:
            modelName = "H2T"
            break
        case .h3s:
            modelName = "H3S"
            break
        case .h3t:
            modelName = "H3T"
            break
        case .hc:
            modelName = "HC"
            break
        case .ht:
            modelName = "HT"
        case .hl:
            modelName = "HL"
            break
        default:
            modelName = "无"
            break
        }
        return modelName
    }
    
    static func getLT2GDisplayName(model : MD_LT_2G_DeviceModel) -> String {
        var modelName = ""
        switch model {
        case .none:
            modelName = "未知"
            break
        case .pl10:
            modelName = "MD PL10"
            break
        case .pl20:
            modelName = "MD PL20"
            break
        case .pl21:
            modelName = "MD PL21"
            break
        case .pl22:
            modelName = "MD PL22"
            break
        case .pl36:
            modelName = "MLD PL36"
            break
        case .pm60:
            modelName = "MD PM60"
            break
        case .pm70:
            modelName = "MD PM70"
            break
        case .pq80:
            modelName = "MD PQ80"
            break
        case .pq88:
            modelName = "MD PQ88"
            break
        case .pl16:
            modelName = "MD PL16"
        case .pl26:
            modelName = "MD PL26"
            break
        case .pl56:
            modelName = "MD PL56"
            break
        case .pf88:
            modelName = "MD PF88"
            break
        case .pf68:
            modelName = "MD PF68"
            break
        case .pf78:
            modelName = "MD PF78"
            break
        case .pf98:
            modelName = "MD PF98"
            break
        case .pf01:
            modelName = "MD PF01"
            break
        default:
            modelName = "未知"
            break
        }
        return modelName
    }
    
    static func getLT2GDisplayNameShort(model : MD_LT_2G_DeviceModel) -> String {
        var modelName = ""
        switch model {
        case .none:
            modelName = "未知"
            break
        case .pl10:
            modelName = "PL10"
            break
        case .pl20:
            modelName = "PL20"
            break
        case .pl21:
            modelName = "PL21"
            break
        case .pl22:
            modelName = "PL22"
            break
        case .pl36:
            modelName = "H2S"
            break
        case .pm60:
            modelName = "PM60"
            break
        case .pm70:
            modelName = "PM70"
            break
        case .pq80:
            modelName = "PQ80"
            break
        case .pq88:
            modelName = "PQ88"
            break
        case .pl16:
            modelName = "PL16"
        case .pl26:
            modelName = "PL26"
            break
        case .pl56:
            modelName = "PL56"
            break
        case .pf88:
            modelName = "PF88"
            break
        case .pf68:
            modelName = "PF68"
            break
        case .pf78:
            modelName = "PF78"
            break
        case .pf98:
            modelName = "PF98"
            break
        case .pf01:
            modelName = "PF01"
            break
        default:
            modelName = "未知"
            break
        }
        return modelName
    }
    
    
    static func getLT3GDisplayName(model : MD_LT_3G_DeviceModel) -> String {
        var modelName = ""
        switch model {
        case .none:
            modelName = "HA C3"
            break
        case .HA30:
            modelName = "HA 30"
            break
        case .HD30:
            modelName = "HD 30"
            break
        default:
            modelName = "未知"
            break
        }
        return modelName
    }
    
    static func getLT3GDisplayNameShort(model : MD_LT_3G_DeviceModel) -> String {
        var modelName = ""
        switch model {
        case .none:
            modelName = "C3"
            break
        default:
            modelName = "未知"
            break
        }
        return modelName
    }
  */
    
    static func calculatePerResultForBattery(_ maximumInterval : Double,minimumInterval:Double,currentValue:Double,needPlusPer:Double) -> Double{
        var result : Double = 0
        let percent = currentValue<=3.45 ? 0.05 : 0.1
        result = (currentValue - minimumInterval) / (maximumInterval-minimumInterval) * percent + needPlusPer
        result = result * 100
        if result > 100 {
            result = 100
        }
        return result
    }
    
    static func calculateBattery(_ batteryValue : Float) -> String {
        let volValue = (batteryValue * 2 * 3) / 4096
        var perResult: Double = 0
        let doubleValue = Double(volValue)
        if doubleValue >= Full_PercentBattery {
            perResult = 100
        } else if doubleValue >= Ninety_PercentBattery {
            perResult = calculatePerResultForBattery(Full_PercentBattery, minimumInterval: Ninety_PercentBattery, currentValue: doubleValue, needPlusPer: 0.9)
        }
        else if doubleValue >= Eighty_PercentBattery {
            perResult = calculatePerResultForBattery(Ninety_PercentBattery, minimumInterval: Eighty_PercentBattery, currentValue: doubleValue, needPlusPer: 0.8)
        }
        else if doubleValue >= Seventy_PercentBattery {
            perResult = calculatePerResultForBattery(Eighty_PercentBattery, minimumInterval: Seventy_PercentBattery, currentValue: doubleValue, needPlusPer: 0.7)
        }
        else if doubleValue >= Sixty_PercentBattery {
            perResult = calculatePerResultForBattery(Seventy_PercentBattery, minimumInterval: Sixty_PercentBattery, currentValue: doubleValue, needPlusPer: 0.6)
        }
        else if doubleValue >= Fifty_PercentBattery {
            perResult = calculatePerResultForBattery(Sixty_PercentBattery, minimumInterval: Five_PercentBattery, currentValue: doubleValue, needPlusPer: 0.5)
        }
        else if doubleValue >= Fourty_PercentBattery {
            perResult = calculatePerResultForBattery(Fifty_PercentBattery, minimumInterval: Fourty_PercentBattery, currentValue: doubleValue, needPlusPer: 0.4)
        }
        else if doubleValue >= Thirty_PercentBattery {
            perResult = calculatePerResultForBattery(Fourty_PercentBattery, minimumInterval: Thirty_PercentBattery, currentValue: doubleValue, needPlusPer: 0.3)
        }
        else if doubleValue >= Twenty_PercentBattery {
            perResult = calculatePerResultForBattery(Thirty_PercentBattery, minimumInterval: Twenty_PercentBattery, currentValue: doubleValue, needPlusPer: 0.2)
        }
        else if doubleValue >= Ten_PercentBattery {
            perResult = calculatePerResultForBattery(Twenty_PercentBattery, minimumInterval: Ten_PercentBattery, currentValue: doubleValue, needPlusPer: 0.1)
        }
        else if doubleValue >= Five_PercentBattery {
            perResult = calculatePerResultForBattery(Ten_PercentBattery, minimumInterval: Five_PercentBattery, currentValue: doubleValue, needPlusPer: 0.05)
        }
        else if(doubleValue >= Zero_PercentBattery){
            // 0% ~ 5%
            perResult = calculatePerResultForBattery(Five_PercentBattery, minimumInterval: Zero_PercentBattery, currentValue: doubleValue, needPlusPer: 0)
        } else{
            // < 0%
            perResult = 0;
        }
        let stringResult = String(format: "%.0f", perResult)
        return stringResult;
    }
    
    
    static func CalculationBatteryLevel(_ percent : Double) -> MD_BLEDeviceBatteryLevel {
        if percent >= 90 {
            return MD_BLEDeviceBatteryLevel.kBatteryLevel_One
        } else if percent >= 70 {
            return MD_BLEDeviceBatteryLevel.kBatteryLevel_Two
        } else if percent >= 50 {
            return MD_BLEDeviceBatteryLevel.kBatteryLevel_Three
        } else if percent >= 20 {
            return MD_BLEDeviceBatteryLevel.kBatteryLevel_Four
        } else if percent >= 6 {
            return MD_BLEDeviceBatteryLevel.kBatteryLevel_Five
        } else {
           return MD_BLEDeviceBatteryLevel.kBatteryLevel_Six
       }
    }
    
    static func outPutCommandStr(data:[UInt8]) -> String {
        var outPutStr = ""
        for order in data {
            let command = String(format: "%02x",order)
            outPutStr = outPutStr + command + " "
        }
        outPutStr = outPutStr.uppercased()
        return outPutStr
    }
}
