//
//  RemoteModeViewController.h
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2014/03/24.
//  Copyright (c) 2014年 Yusuke Sato. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface RemotoModeViewController : UIViewController
{
    NSString *St_Service;
    NSString *St_Characteristic;
    CBUUID *UUID_Service;
    CBUUID *UUID_Characteristic;
}
@property (nonatomic,strong) CBPeripheralManager *peripheralManager;
@property (nonatomic,strong) CBCharacteristic *characteristic;
@property (nonatomic,strong) CBMutableService *service;

@property (weak, nonatomic) IBOutlet UIButton *bt_Play;
@property (weak, nonatomic) IBOutlet UIButton *bt_Next;
@property (weak, nonatomic) IBOutlet UIButton *bt_Prev;



- (IBAction)bt_Play_Push:(id)sender;
- (IBAction)bt_Next_Push:(id)sender;
- (IBAction)bt_Prev_Push:(id)sender;




@end
