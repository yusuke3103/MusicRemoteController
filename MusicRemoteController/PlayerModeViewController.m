//
//  PlayerModeViewController.m
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2014/03/24.
//  Copyright (c) 2014年 Yusuke Sato. All rights reserved.
//

#import "PlayerModeViewController.h"

@interface PlayerModeViewController ()
@property CBUUID *uuid;
@end

@implementation PlayerModeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	_player = [MPMusicPlayerController iPodMusicPlayer];
    
    [self playerStateCheck];
    
    _vi_volume.backgroundColor = [UIColor clearColor];
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:_vi_volume.bounds];
    [_vi_volume addSubview:volumeView];
    
    _ncenter = [NSNotificationCenter defaultCenter];
    [_ncenter addObserver:self selector:@selector(handle_PlaybackStateChange) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:_player];
    [_ncenter addObserver:self selector:@selector(handle_NowPlayingItemChanged) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:_player];
    [_ncenter addObserver:self selector:@selector(handle_VolumeChange) name:MPMusicPlayerControllerVolumeDidChangeNotification object:_player];
    [_player beginGeneratingPlaybackNotifications];
    
    
    
    
    
    
    
    // CoreBluetooth
    
    // UUID
    St_Service = @"7865087B-D9D0-423A-9C80-042D9BBEA524";
    St_Characteristic = @"608072DD-6825-4293-B3E7-324CF0B5CA08";
    
    UUID_Service = [CBUUID UUIDWithString:St_Service];
    UUID_Characteristic = [CBUUID UUIDWithString:St_Characteristic];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//==========================
// MediaPlayer Programing
//==========================

- (void) handle_PlaybackStateChange
{
    NSLog(@"Playback State Item Change");
    [self playerStateCheck];
    
}

- (void) handle_NowPlayingItemChanged
{
    NSLog(@"Playing Item Changed");
    MPMediaItem *NowPlayingItem = [_player nowPlayingItem];
    NSString *SongTitle = [NowPlayingItem valueForProperty:MPMediaItemPropertyTitle];
    NSString *SongArtist = [NowPlayingItem valueForProperty:MPMediaItemPropertyArtist];
    MPMediaItemArtwork *SongArtwork = [NowPlayingItem valueForProperty:MPMediaItemPropertyArtwork];
    
    //====
    //再生中の音楽情報セット
    //====
    
    // タイトル
    _lb_Title.text = SongTitle;
    
    // アーティスト
    _lb_Artist.text = SongArtist;
    
    // アートワーク
    UIImage *image = [SongArtwork imageWithSize:CGSizeMake(280.0f,280.0f)];
    if (image == NULL){
        image = [UIImage imageNamed:@"nonimage.png"];
    }
    [_im_Artwork setImage:image];
    
}

- (void) handle_VolumeChange
{
    NSLog(@"Volume Change");
    NSLog(@"%@",_vi_volume);
}


- (IBAction)bt_Prev_Push:(id)sender {
    [_player skipToPreviousItem];
}

- (IBAction)bt_Play_Push:(id)sender {
    if(_isPlaying == NO) {
        [_bt_Play setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
        [_player play];
        _isPlaying = YES;
    }else{
        _isPlaying = NO;
        [_bt_Play setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
        [_player pause];
        
    }
}

- (IBAction)bt_Next_Push:(id)sender {
    [_player skipToNextItem];
}

//==========================
// CoreBluetooth Programing
//==========================

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            break;
        case CBCentralManagerStatePoweredOn:
            
            [_centralManager scanForPeripheralsWithServices:@[UUID_Service] options:nil];
            break;
        default:
            break;
    }
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    _peripheral = peripheral;
    [_centralManager stopScan];
    [_centralManager connectPeripheral:peripheral options:nil];
    
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    _peripheral.delegate = self;
    [_peripheral discoverServices:@[UUID_Service]];
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services){
        if([service.UUID isEqual:UUID_Service]){
            [_peripheral discoverCharacteristics:@[UUID_Characteristic] forService:service];
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if([service.UUID isEqual:UUID_Service]){
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:UUID_Characteristic]){
                [_peripheral setNotifyValue:YES forCharacteristic:characteristic];            }
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices
{
    [_centralManager scanForPeripheralsWithServices:@[UUID_Service] options:nil];
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error){
        NSLog(@"%@",error.description);
    }else{
        [_peripheral readValueForCharacteristic:characteristic];
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (characteristic.value != nil){
        NSData *data = characteristic.value;
        int data_num = *(int *)([data bytes]);
        NSLog(@"%d",data_num);
        switch (data_num) {
            case 0:
                NSLog(@"PeripheralでPlayボタンが押されました。");
                if (_isPlaying == YES){
                    [_player pause];
                    _isPlaying = NO;
                }else{
                    [_player play];
                    _isPlaying = YES;
                }
                break;
            case 1: //巻き戻し
                NSLog(@"PeripheralでRevボタンが押されました。");
                [_player skipToPreviousItem];
                break;
            case 2: //早送り
                NSLog(@"PeripheralでNextボタンが押されました。");
                [_player skipToNextItem];
                break;
            case 3: // VolUp
                
                break;
            case 4: // VolDown
                
                break;
            default:
                NSLog(@"error");
                break;
        }
    }
}

- (void) playerStateCheck
{
    int state = [_player playbackState];
    if (state == 1){
        [_bt_Play setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
    }else{
        [_bt_Play setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
    }
}

@end

