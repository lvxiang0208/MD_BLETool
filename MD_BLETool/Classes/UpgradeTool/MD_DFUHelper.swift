//
//  MD_DFUHelper.swift
//  PelvicFloorPersonal
//
//  Created by Medo on 2020/12/22.
//  Copyright © 2020 henglongwu. All rights reserved.
//

import UIKit
import iOSDFULibrary
import CoreBluetooth

class MD_DFUHelper: NSObject,DFUServiceDelegate, DFUProgressDelegate, LoggerDelegate {
    
    private var dfuServiceVC : DFUServiceController?
    
    /// 保证sharedInstance是一个常量，在创建之后不会被更改 (单例 支持懒加载, 线程安全)
    @objc static let shared = MD_DFUHelper()
    
    @objc func startDFU(resourceName:String,target:CBPeripheral?) {
        if target == nil {
            return
        }
        let filePath = MD_BLEDeviceDealTool.getLanTingDataPath() + resourceName
        //传递的是DFU文件的路径 你可以下载完成后存在沙盒然后把路径拿过来
        guard let selectedFirmware = DFUFirmware(urlToZipFile: URL(fileURLWithPath: filePath)) else { return }
        
        let initiator = DFUServiceInitiator.init(queue:  DispatchQueue.global(), delegateQueue: DispatchQueue.global(), progressQueue: DispatchQueue.global(), loggerQueue: DispatchQueue.global())
        initiator.forceDfu = false
//        initiator.packetReceiptNotificationParameter = 12
        initiator.logger = self
        initiator.delegate = self
        initiator.progressDelegate = self
        initiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        MD_BLEConnectManager.shared.isDFUUpgrade = true
        dfuServiceVC = initiator.with(firmware: selectedFirmware).start(target: target!)
    }
    
    
    // 升级状态回调
    @objc func dfuStateDidChange(to state: DFUState) {
        print("state = \(state.rawValue)")
        DispatchQueue.main.async {
            switch state {
            case .connecting:
                break
            case .starting:
                MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeValidSuccess(model: MD_BLEConnectManager.shared.getConnected_Device() ?? MD_BLEModel())
                break
                
            case .completed:
                print("升级完成")
                MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeSuccess(model: MD_BLEConnectManager.shared.getConnected_Device() ?? MD_BLEModel())
                MD_BLEConnectManager.shared.isDFUUpgrade = false
                break
            case .disconnecting:
                break
            case .aborted:
                print("dfu升级终止")
                let error = NSError.init(domain: "", code: 300, userInfo: ["msg":"升级终止"])
                MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeFailure(error: error)
                MD_BLEConnectManager.shared.isDFUUpgrade = false
                break
            default:
                break
            }
        }
    }
    

    // 升级进度回调，范围 1-100
    @objc func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        DispatchQueue.main.async {
            let progress = CGFloat(progress) / 100.0
            MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeProgress(model: MD_BLEConnectManager.shared.getConnected_Device() ?? MD_BLEModel(), progress: progress)
        }
    }
    
    @objc func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        DispatchQueue.main.async {
            let error = NSError.init(domain: "", code: 300, userInfo: ["msg":message])
            MD_DispatcherCenter.shared.dispatchLT2rdBleUpgradeFailure(error: error)
            MD_BLEConnectManager.shared.isDFUUpgrade = false
        }
    }
    
    @objc func logWith(_ level: LogLevel, message: String) {
    }
    
}
