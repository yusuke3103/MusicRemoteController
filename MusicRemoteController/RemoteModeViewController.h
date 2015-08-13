//
//  RemoteModeViewController.h
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2014/03/24.
//  UPDATE VERSION 1.2.0 2015/07/26.
//  Copyright (c) 2014年 Yusuke Sato. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface RemoteModeViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBCharacteristic *characteristic;
@property (strong, nonatomic) CBUUID *serviceUUID;
@property (strong, nonatomic) CBUUID *characteristicUUID;

- (IBAction)btnPlay:(id)sender;
- (IBAction)btnPrevPush:(id)sender;
- (IBAction)btnNextPush:(id)sender;
- (IBAction)btnUpPush:(id)sender;
- (IBAction)btnDownPush:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIButton *btnNext;
@property (weak, nonatomic) IBOutlet UIButton *btnPrev;
@property (weak, nonatomic) IBOutlet UIButton *btnDown;
@property (weak, nonatomic) IBOutlet UIButton *btnUp;

@end
