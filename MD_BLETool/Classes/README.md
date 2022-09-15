***集成MD_BLETool***
**工程配置**
1. info.plist添加key-value获取蓝牙权限(Privacy - Bluetooth Always Usage Description-"App在连接设备时需要使用蓝牙权限")
2. podfile 添加  pod 'YYCache'   pod 'iOSDFULibrary' 执行pod install
3. 蓝牙库MD_BLETool添加至项目 

**如何使用OC(swift类似)**
1. 根据需要业务页面添加蓝牙代理,并遵守MD_DispatcherCenterDelegate协议,
[[MD_DispatcherCenter shared] addObserver:self]; 
并在合适地方移除监听,一般在页面销毁时移除
[[MD_DispatcherCenter shared] removerObserver:self]; 

2. 扫描蓝牙设备  
[[MD_BLEConnectManager shared] scanDevices];
扫描到设备
-(void)bleConnectManagerDidDiscoverPeripheralsWithDisCoveredPeripherals:(NSArray<CBPeripheral *> *)disCoveredPeripherals{}
 停止扫描 ,连接前停止扫描设备
[[MD_BLEConnectManager shared] stopScanDevices];

3. 连接设备
model:根据蓝牙设备自定义
[[MD_BLEConnectManager shared] connectPeripheral:peripheral model: [MD_SWUtils getDeviceModel:peripheral]];
*说明:蓝牙连接成功,读取EPPROM,EPPROM读取成功,调用MD_BLEModel的checkDeviceConnect() 方法,该方法需要在自定义Model内重写检查连接逻辑并分发连接成功*
MD_DispatcherCenter.shared.dispatchBLEConnectManagerDidConnect(peripheral: self.peripheral!)
蓝牙连接成功
- (void)bleConnectManagerDidConnectWithPeripheral:(CBPeripheral *)peripheral {}

4. 发送工作指令 由 [[MD_BLEConnectManager shared] getConnected_Device]获取BleModel调用下述方法
/// 开始采集数据肌电
@objc func startCollectData(){}
/// 停止肌电采集数据 肌电
@objc func stopCollectData(){}
/// 非变频电刺激参数设置
@objc func sendStimParamToDevice_NotInverterFreq(pulse: UInt, freq: UInt, riseTime: UInt, fallTime: UInt, stimValue: Double,workTime:UInt, restTime:UInt,preSetElectricity:Bool,_ channel:ChannelType = .first) {}
/// 变频电刺激参数设置
@objc func sendStimParamToDevice_InverterFreq(pluse_1: UInt, pluse_2: UInt, pluse_3: UInt, freq_1: UInt, freq_2: UInt, freq_3: UInt, riseTime: UInt, fallTime: UInt, stimValue: Double,workTime:UInt, restTime:UInt,preSetElectricity:Bool,_ channel:ChannelType = .first) {}
/// 刺激电流设置
/// - Parameter stimValue: 电流值
@objc func stimElectricitySet(stimValue: Double,_ channel:ChannelType = .first) {}
/// 刺激开始
@objc func stimStart(_ channel:ChannelType = .first) {}
/// 刺激开始(屏蔽电极片脱落功能)  2代和三代
@objc func stimStartNoElectrodeStatus(_ channel:ChannelType = .first) {}
/// 变频刺激开始  2代 3代
@objc func frequencyScalingStimStart(_ channel:ChannelType = .first) {}
/// 变频刺激开始(屏蔽电极片脱落功能) 2代 3代
@objc func frequencyScalingStimStartNoElectrodeStatus(_ channel:ChannelType = .first) {}
/// 刺激结束
@objc func stimEnd(_ channel:ChannelType = .first) {}
/// 开始充气
/// - Parameter pressureVal: 压力值 mmHg
@objc func startInfliate(pressureVal:UInt) {}
/// 停止充气
@objc func stopInfliate() {}
/// 放气
@objc func startVacuuming() {}

**接收BLE设备上传数据处理**
遵守MD_DispatcherCenterDelegate的页面或UI,实现MD_DispatcherCenterDelegate里的方法处理蓝牙数据

**固件升级**
*需要提前将升级所需文件下载到MD_BLEDeviceDealTool.getLanTingDataPath()文件夹下*
1. bin或hex升级 :  @objc func startUpgrade() {}
//resourceName:升级文件沙盒地址,target :目标设备
2. DFU升级: @objc func startDFU(resourceName:String,target:CBPeripheral?) 
3. 升级过程
//升级进度
@objc optional func lt2rdBleUpgradeProgress(model: MD_BLEModel,progress:CGFloat){}
//升级成功
@objc optional func lt2rdBleUpgradeSuccess(model: MD_BLEModel){}
//升级失败
@objc optional func lt2rdBleUpgradeFailure(error:NSError)

**设备重连**
设备断开用户模型保存MD_BLEConnectManager.shared.reconnectedBLEModels 数组中
///业务中对蓝牙断开连接代理进行处理
- (void)bleConnectManagerDidDisconnectPeripheralWithPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {}
开始重连
[[MD_BLEConnectManager shared] reconectAction];
取消重连
[[MD_BLEConnectManager shared] cancelReconectAction];









