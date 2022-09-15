//
//  MD_DataSmooth.swift
//  PelvicFloorPersonal
//
//  Created by wu henglong on 2020/12/2.
//  Copyright © 2020 henglongwu. All rights reserved.
//

import UIKit

class MD_DataSmooth: NSObject {

    //平滑长度
    var iSmoothLength:Int = 10
    
    //存储的数据数组
    var dataArray:[Double] = [Double]()
    
    override init() {
        super.init()
    }
    
    /// 设置平滑长度
    /// - Parameter length: 平滑长度
    func setSmoothLength(length:Int){
        iSmoothLength = length
        dataArray.removeAll()
    }
    
    func smoothData(data:Double) -> Double {
        if iSmoothLength <= 0 {
            return data
        }
        if dataArray.count == iSmoothLength {
            dataArray.remove(at: 0)
        }
        dataArray.append(data)
        
        var resultData:Double = 0.0
        for number in dataArray {
            resultData += number
        }
        resultData /= Double(dataArray.count)
        
        return resultData
        
    }
}
