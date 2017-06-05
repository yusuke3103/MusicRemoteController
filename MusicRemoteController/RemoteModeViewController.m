//
//  RemoteModeViewController.m
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2014/03/24.
//  UPDATE VERSION 1.2.0 2015/07/26.
//  Copyright (c) 2014年 Yusuke Sato. All rights reserved.
//

#import "RemoteModeViewController.h"

#define SERVICE_UUID_STRING @""
#define MUSICINFO_UUID_STRING @""
#define BUTTON_UUID_STRING @""


@implementation RemoteModeViewController

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:NO];
    [self btnStateChange:NO];
    self.serviceUUID = [CBUUID UUIDWithString:SERVICE_UUID_STRING];
    self.buttonUUID = [CBUUID UUIDWithString:BUTTON_UUID_STRING];
    self.musicInfoUUID = [CBUUID UUIDWithString:MUSICINFO_UUID_STRING];
    
    // セントラルマネージャ初期化
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

-(void) btnStateChange:(BOOL)flg{
    
    [self.btnPrev setEnabled:flg];
    [self.btnPlay setEnabled:flg];
    [self.btnNext setEnabled:flg];
    [self.btnUp setEnabled:flg];
    [self.btnDown setEnabled:flg];
}


// ==========================
//      CoreBluetooth
// ==========================
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManagerDidUpdateState");
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        [central scanForPeripheralsWithServices:@[self.serviceUUID] options:nil];
    }
}

-(void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"didDiscoverPeripheral");
    
    self.peripheral = peripheral;
    [central stopScan];
    NSLog(@"%@",peripheral);
    [central connectPeripheral:peripheral options:nil];
}

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral");
    
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:@[self.serviceUUID]];
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices");
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:self.serviceUUID]) {
            [peripheral discoverCharacteristics:@[self.buttonUUID,self.musicInfoUUID] forService:service];
        }
    }
}
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:self.serviceUUID]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:self.buttonUUID]) {
                NSLog(@"Discoverd BUTTON UUID");

                self.buttonCharacteristic = characteristic;
                [self.peripheral readValueForCharacteristic:self.buttonCharacteristic];
                //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            if ([characteristic.UUID isEqual:self.musicInfoUUID]){
                self.musicInfoCharacteristic = characteristic;
                NSLog(@"Discoverd MUSIC INFO UUID");
                [peripheral setNotifyValue:YES forCharacteristic:self.musicInfoCharacteristic];
            }
        }
    }
}


- (IBAction)btnPlay:(id)sender {
    uint val = 0;
    NSData *data = [NSData dataWithBytes:&val length:1];
    [self.peripheral writeValue:data forCharacteristic:self.buttonCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (IBAction)btnPrevPush:(id)sender {
    uint val = 2;
    NSData *data = [NSData dataWithBytes:&val length:1];
    [self.peripheral writeValue:data forCharacteristic:self.buttonCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (IBAction)btnNextPush:(id)sender {
    uint val = 1;
    NSData *data = [NSData dataWithBytes:&val length:1];
    [self.peripheral writeValue:data forCharacteristic:self.buttonCharacteristic type:CBCharacteristicWriteWithResponse];
}


- (IBAction)btnUpPush:(id)sender {
    uint val = 3;
    NSData *data = [NSData dataWithBytes:&val length:1];
    [self.peripheral writeValue:data forCharacteristic:self.buttonCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (IBAction)btnDownPush:(id)sender {
    uint val = 4;
    NSData *data = [NSData dataWithBytes:&val length:1];
    [self.peripheral writeValue:data forCharacteristic:self.buttonCharacteristic type:CBCharacteristicWriteWithResponse];
    
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Write失敗...error:%@", error);
        return;
    }
    
    NSLog(@"Write成功！");
}

- (void) peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
              error:(NSError *)error
{
    if (error) {
        NSLog(@"Failed... error: %@", error);
        return;
    }
    
    [self btnStateChange:YES];

    NSDictionary *reverse = [NSKeyedUnarchiver unarchiveObjectWithData:characteristic.value];
    
    NSLog(@"Succeeded！ service uuid:%@, characteristice uuid:%@, value%@",
            characteristic.service.UUID, characteristic.UUID, characteristic.value);
}



- (void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if ([characteristic.UUID isEqual:self.musicInfoUUID]){
        
        NSLog(@"Notifiy Music Info -%lu-",characteristic.value.length);
        
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
            [self.peripheral readValueForCharacteristic:self.musicInfoCharacteristic];
        }
    }
}
@end
