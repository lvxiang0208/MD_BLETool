//
//  MD_BLEHeartBeat.swift
//  PelvicFloorPersonal
//
//  Created by Medo on 2021/9/6.
//  Copyright © 2021 henglongwu. All rights reserved.
//

import UIKit

@objc protocol MD_BLEHeartBeatDelegate:NSObjectProtocol {
    func bleHeartBeatKeep(_ heartBeat:MD_BLEHeartBeat)
    
    func bleHeartBeatOver(_ heartBeat:MD_BLEHeartBeat)
}

class MD_BLEHeartBeat: NSObject {

    let beatInterval:Double = 1
    
    var isheartBeating = false
    
    @objc weak var delegate : MD_BLEHeartBeatDelegate?
    
    var timer : DispatchSourceTimer?
    
    
    override init() {
        super.init()
    }
    
    @objc func heartBeat() {
        if self.isheartBeating {
            return
        }
        if timer != nil {
            timer?.resume()
        }
        weak var weakSelf = self
        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        timer?.schedule(deadline: .now(), repeating: beatInterval)
        timer?.setEventHandler {
            DispatchQueue.main.async {
                weakSelf?.p_heartBeatKeep()
            }
        }
        timer?.resume()
    }
    
    
    @objc func p_heartBeatKeep() {
        self.isheartBeating = true
        delegate?.bleHeartBeatKeep(self)
    }
    
    @objc func heartBeatOver() {
        self.isheartBeating = false
        timer?.cancel()
        timer = nil
        delegate?.bleHeartBeatOver(self)
    }
    
}
