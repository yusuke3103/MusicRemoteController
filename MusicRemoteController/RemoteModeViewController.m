//
//  RemoteModeViewController.m
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2014/03/24.
//  Copyright (c) 2014年 Yusuke Sato. All rights reserved.
//

#import "RemoteModeViewController.h"

@interface RemotoModeViewController ()

@end

@implementation RemotoModeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    St_Service = @"7865087B-D9D0-423A-9C80-042D9BBEA524";
    St_Characteristic = @"608072DD-6825-4293-B3E7-324CF0B5CA08";
    
    UUID_Service = [CBUUID UUIDWithString:St_Service];
    UUID_Characteristic = [CBUUID UUIDWithString:St_Characteristic];
    
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
}

//==========================
// CoreBluetooth Programing
//==========================

- (void) peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            [self setUpService];
            break;
            
        default:
            break;
    }
}

- (void) setUpService
{
    /*
     _characteristic = [[CBMutableCharacteristic alloc] initWithType:UUID_Characteristic properties:CBCharacteristicPropertyIndicate value:nil permissions:CBAttributePermissionsReadable];
     */
    
    _characteristic = [[CBMutableCharacteristic alloc] initWithType:UUID_Characteristic properties:CBCharacteristicPropertyIndicateEncryptionRequired value:nil permissions:CBAttributePermissionsReadEncryptionRequired];
    
    _service = [[CBMutableService alloc] initWithType:UUID_Service primary:YES];
    
    [_service setCharacteristics:@[_characteristic]];
    
    [_peripheralManager addService:_service];
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog (@"Error:%@",[error localizedDescription]);
    }else{
        [_peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey:@"iPhone",CBAdvertisementDataServiceUUIDsKey:@[UUID_Service]}];
    }
}

- (void) peripheralManager:(CBPeripheralManager *)peripher central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)bt_Play_Push:(id)sender {
    uint update = 0;
    NSData *updatedValue = [NSData dataWithBytes:&update length:sizeof(update)];
    BOOL didSendValue = [_peripheralManager updateValue:updatedValue forCharacteristic:_characteristic onSubscribedCentrals:nil];
}

- (IBAction)bt_Next_Push:(id)sender {
    uint update = 1;
    NSData *updatedValue = [NSData dataWithBytes:&update length:sizeof(update)];
    BOOL didSendValue = [_peripheralManager updateValue:updatedValue forCharacteristic:_characteristic onSubscribedCentrals:nil];
}

- (IBAction)bt_Prev_Push:(id)sender {
    uint update = 2;
    NSData *updatedValue = [NSData dataWithBytes:&update length:sizeof(update)];
    BOOL didSendValue = [_peripheralManager updateValue:updatedValue forCharacteristic:_characteristic onSubscribedCentrals:nil];
}

- (IBAction)bt_Up_Push:(id)sender {
    uint update = 3;
    NSData *updatedValue = [NSData dataWithBytes:&update length:sizeof(update)];
    BOOL didSendValue = [_peripheralManager updateValue:updatedValue forCharacteristic:_characteristic onSubscribedCentrals:nil];
}

- (IBAction)bt_Down_Push:(id)sender {
    uint update = 4;
    NSData *updatedValue = [NSData dataWithBytes:&update length:sizeof(update)];
    BOOL didSendValue = [_peripheralManager updateValue:updatedValue forCharacteristic:_characteristic onSubscribedCentrals:nil];
}

@end
