//
//  InterfaceController.h
//  MusicRemoteController WatchKit Extension
//
//  Created by Yusuke Sato on 2015/08/09.
//  Copyright (c) 2015年 Yusuke Sato. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface InterfaceController : WKInterfaceController<CBCentralManagerDelegate, CBPeripheralDelegate>
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

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *lblStatus;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *btnPlay;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *btnNext;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *btnPrev;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *btnDown;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *btnUp;


@end
