//
//  MD_VerfifyTool.swift
//  MDBLETool
//
//  Created by wu henglong on 2021/1/14.
//

import UIKit

class MD_VerfifyTool: NSObject {
    
    
    /// CRC校验 hex注释
    /// - Parameter data: Data
    /// - Returns: Data
    static func upgradecrcVerfifyCode_Cal(bytes:[UInt8]) -> [UInt8] {
        var CRC:Int = 0x0000ffff  //初始值
        let POLYNOMIAL:Int = 0x0000a001
        
        let length = bytes.count
        for i in 0..<length{
            CRC ^= (Int(bytes[i] & 0x000000ff))
            for _ in 0..<8{
                if((CRC & 0x00000001) != 0 ){
                    CRC >>= 1
                    CRC ^= POLYNOMIAL
                }else{
                    CRC >>= 1
                }
            }
        }
        let crc1 :UInt8 = UInt8(0xff & (((CRC >> 8) >> 8) >> 8))
        let crc2 :UInt8 = UInt8(0xff & ((CRC >> 8) >> 8))
        let crc3:UInt8 = UInt8(0xff & (CRC >> 8))
        let crc4:UInt8 = UInt8(0xff & CRC)
        let arrayCRC:[UInt8] = [crc1,crc2,crc3,crc4]
        return arrayCRC
    }
    
    /// CRC校验
    /// - Parameter data: Data
    /// - Returns: Data
    static func crcVerfifyCode_Cal(bytes:[UInt8]) -> [UInt8] {
        var CRC:Int = 0x0000ffff  //初始值
        let POLYNOMIAL:Int = 0x0000a001
        
        let length = bytes.count
        for i in 0..<length{
            CRC ^= (Int(bytes[i] & 0x000000ff))
            for _ in 0..<8{
                if((CRC & 0x00000001) != 0 ){
                    CRC >>= 1
                    CRC ^= POLYNOMIAL
                }else{
                    CRC >>= 1
                }
            }
        }
        let crcHigh:UInt8 = UInt8(0xff & (CRC >> 8))
        let crcLow:UInt8 = UInt8(0xff & CRC)
        let arrayCRC:[UInt8] = [crcHigh,crcLow]
        return arrayCRC
    }
    
    /// CRC校验检查
    /// - Parameters:
    ///   - bytes: bytes 需要校验的data
    ///   - highCheck: 校验结果高位
    ///   - lowCheck: 校验结果地位
    /// - Returns: Bool
    static func crcVerfifyCode_Check(bytes:[UInt8], highCheck:UInt8, lowCheck:UInt8) -> Bool{
        let checkCRCData:[UInt8] = MD_VerfifyTool.crcVerfifyCode_Cal(bytes: bytes)
        if highCheck != checkCRCData[0] && lowCheck != checkCRCData[1] {
//            print("CRC校验成功")
            return false
        }
//        print("CRC校验失败")
        return true
    }
    
    
    /// 校验和计算
    /// - Parameter bytes:[UInt8]
    /// - Returns: UInt8
    static func sumVerfifyCode_Cal(bytes:[UInt8]) -> UInt8 {
        var sum:UInt = 0
        let length = bytes.count
        for i in 0..<length{
            sum += UInt(bytes[i])
        }
        let sumUint8 = UInt8(sum % 256)
        return sumUint8
    }
    
    /// 校验和检查
    /// - Parameter data: Data
    /// - Returns: Data
    static func sumVerfifyCode_Check(bytes:[UInt8]) -> Bool {
        var sum:UInt = 0
        let length = bytes.count
        for i in 1..<length-1{
            sum += UInt(bytes[i])
        }
        let sumUint8 = UInt8(sum % 256)
        if sumUint8 == bytes[length-1] {
            return true
        }
        return false
    }
    
    //hex 升级种子加密
    static func upgradeSecretSeed(tempByte:[UInt8]) -> [UInt8]{
        let params = (Int64(tempByte[4]) * 256 * 256 * 256) + (Int64(tempByte[5]) * 256 * 256) + (Int64(tempByte[6]) * 256) + (Int64(tempByte[7]))
        var cons:[UInt8] = [UInt8](repeating: 0, count: 4)
        var seed:[UInt8] = [UInt8](repeating: 0, count: 4)
        var key1:[UInt8] = [UInt8](repeating: 0, count: 4)
        var key2:[UInt8] = [UInt8](repeating: 0, count: 4)
        var key:[UInt8] = [UInt8](repeating: 0, count: 4)
        var j = 3
        seed[0] = UInt8((params & 0xff000000) >> 24)
        seed[1] = UInt8((params & 0x00ff0000) >> 16)
        seed[2] = UInt8((params & 0x0000ff00) >> 8)
        seed[3] = UInt8(params & 0x000000ff)
        
        let constant:Int64 = 0x20130116
        cons[3] = UInt8((constant & 0xff000000) >> 24)
        cons[2] = UInt8((constant & 0x00ff0000) >> 16)
        cons[1] = UInt8((constant & 0x0000ff00) >> 8)
        cons[0] = UInt8(constant & 0x000000ff)
    
        for i in 0..<4 {
            key1[i] = UInt8(seed[i] ^ cons[i])
            key2[i] = UInt8(seed[j] ^ cons[i])
            key[i] = UInt8((Int(key1[i]) + Int(key2[i])) & 0xff)
            j -= 1
        }
        return key
    }
    
    //hex 升级完成长度计算
    static func upgradeCalAllCode(tempByte:[UInt8]) -> [UInt8]{
        var params : UInt64 = 0
        for i in 0..<tempByte.count{
            params += UInt64(tempByte[i])
        }
        let by1 = UInt8((params >> 24) & 0xff)
        let by2 = UInt8((params >> 16) & 0xff)
        let by3 = UInt8((params >> 8) & 0xff)
        let by4 = UInt8(params & 0xff)
        return [by1,by2,by3,by4]
    }
    
    
}
