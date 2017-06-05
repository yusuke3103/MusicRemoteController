//
//  PlayerModeViewController.m
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2014/03/24.
//  UPDATE VERSION 1.2.0 2015/07/26.
//  Copyright (c) 2014年 Yusuke Sato. All rights reserved.
//

#import "PlayerModeViewController.h"

#define SERVICE_UUID_STRING @"7865087B-D9D0-423A-9C80-042D9BBEA524"
#define MUSICINFO_UUID_STRING @"085BACFC-5FCD-49D1-B7D7-A331901F6DDE"
#define BUTTON_UUID_STRING @"608072DD-6825-4293-B3E7-324CF0B5CA08"

@interface PlayerModeViewController ()
@property CBUUID *uuid;
@end

@implementation PlayerModeViewController
-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:NO];
    
    // MPMediaPlayer
    self.player = [MPMusicPlayerController iPodMusicPlayer];
    
    if ([self.player playbackState] == MPMusicPlaybackStateStopped){
        [self.player setQueueWithQuery:[MPMediaQuery songsQuery]];
    }
    
    self.barVolume.backgroundColor = [UIColor clearColor];
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:self.barVolume.bounds];
    [self.barVolume addSubview:volumeView];
    
    self.ncenter = [NSNotificationCenter defaultCenter];
    [self.ncenter addObserver:self selector:@selector(playbackStateChange) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:self.player];
    [self.ncenter addObserver:self selector:@selector(nowPlayingItemChanged) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:self.player];
    [self.ncenter addObserver:self selector:@selector(volumeChange) name:MPMusicPlayerControllerVolumeDidChangeNotification object:self.player];
    [self.player beginGeneratingPlaybackNotifications];
    
    
    // CoreBluetooth
    self.serviceUUID = [CBUUID UUIDWithString:SERVICE_UUID_STRING];
    self.buttonUUID = [CBUUID UUIDWithString:BUTTON_UUID_STRING];
    self.musicInfoUUID = [CBUUID UUIDWithString:MUSICINFO_UUID_STRING];
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

//==========================
// CoreBluetooth Programing
//==========================
-(void) peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState");
    if (peripheral.state == CBPeripheralManagerStatePoweredOn){
        
        self.buttonCharacteristic = [[CBMutableCharacteristic alloc] initWithType:self.buttonUUID properties:(CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyNotify) value:nil permissions: (CBAttributePermissionsReadEncryptionRequired | CBAttributePermissionsWriteEncryptionRequired)];

        self.musicInfoCharacteristic = [[CBMutableCharacteristic alloc] initWithType:self.musicInfoUUID properties:(CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead) value:nil permissions: (CBAttributePermissionsReadEncryptionRequired)];
        
        CBMutableService *service = [[CBMutableService alloc] initWithType:self.serviceUUID primary:YES];
        [service setCharacteristics:@[self.buttonCharacteristic,self.musicInfoCharacteristic]];
        [peripheral addService:service];
        
    }
}

-(void) peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    NSLog(@"didAddService");
    if (error){
        NSLog(@"SERVICE ADD ERROR");
        NSLog(@"%@",[error localizedDescription]);
    }else{
        [peripheral startAdvertising:@{CBAdvertisementDataLocalNameKey:@"MRC", CBAdvertisementDataServiceUUIDsKey:@[self.serviceUUID]}];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    
    for (CBATTRequest *aRequest in requests) {
        
        if ([aRequest.characteristic.UUID isEqual:self.buttonUUID]) {
            
            // CBCharacteristicのvalueに、CBATTRequestのvalueをセット
            [self pushRemoteController:aRequest.value];
        }
    }
    
    // リクエストに応答
    [self.peripheralManager respondToRequest:requests[0]
                                  withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request
{
    if ([request.characteristic.UUID isEqual:self.buttonUUID]) {
        
        // CBMutableCharacteristicのvalueをCBATTRequestのvalueにセット
        
        request.value = [self getResponseValue];
        
        // リクエストに応答
        [self.peripheralManager respondToRequest:request
                                      withResult:CBATTErrorSuccess];
    }
    
    if ([request.characteristic.UUID isEqual:self.musicInfoUUID]){
        NSLog(@"Request Music Info");
        
        if (request.offset > self.musicInfoCharacteristic.value.length){
            NSLog(@"A");
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
            return;
        }else{
            NSLog(@"B");
            request.value = [self.musicInfoCharacteristic.value subdataWithRange:NSMakeRange(request.offset, self.musicInfoCharacteristic.value.length)];
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        }
        
        
        
    }
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral
                         central:(CBCentral *)central
    didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Subscribeリクエストを受信");
}

-(void)pushRemoteController:(NSData *)val
{
    NSLog(@"REQUEST VALUE IS %@",val);
    int param = *(int *)([val bytes]);
    switch (param) {
        case 0 :
            if (_isPlaying == YES){
                [_player pause];
                _isPlaying = NO;
            }else{
                [_player play];
                _isPlaying = YES;
            }
            break;
        case 1 :
            NSLog(@"PeripheralでRevボタンが押されました。");
            [_player skipToPreviousItem];
            break;
        case 2: //早送り
            NSLog(@"PeripheralでNextボタンが押されました。");
            [_player skipToNextItem];
            break;
        case 3: // VolUp
            [self setVolume:1];
            break;
        case 4: // VolDown
            [self setVolume:0];
            break;
        default:
            NSLog(@"error");
            break;
    }
}
//==========================
// MediaPlayer Programing
//==========================
- (void) playerStateCheck
{
    int state = [_player playbackState];
    NSLog(@"%d",state);
    if (state == 1){
        [self.btnPlay setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
    }else{
        [self.btnPlay setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
    }
}


- (void) playbackStateChange
{
    NSLog(@"Playback State Item Change");
    [self playerStateCheck];
    
}

- (void) nowPlayingItemChanged
{
    NSLog(@"Playing Item Changed");
    MPMediaItem *NowPlayingItem = [self.player nowPlayingItem];
    NSString *SongTitle = [NowPlayingItem valueForProperty:MPMediaItemPropertyTitle];
    NSString *SongArtist = [NowPlayingItem valueForProperty:MPMediaItemPropertyArtist];
    MPMediaItemArtwork *SongArtwork = [NowPlayingItem valueForProperty:MPMediaItemPropertyArtwork];
    
    //====
    //再生中の音楽情報セット
    //====
    
    // タイトル
    self.lblTitle.text = SongTitle;
    
    // アーティスト
    self.lblArtist.text = SongArtist;
    
    // アートワーク
    UIImage *image = [SongArtwork imageWithSize:CGSizeMake(200.0f,200.0f)];
    if (image == NULL){
        image = [UIImage imageNamed:@"nonimage.png"];
    }
    [self.imageArtwork setImage:image];
    
    if (self.musicInfoCharacteristic != nil){
        
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:SongTitle forKey:@"TITLE"];
        [dic setValue:SongArtist forKey:@"ARTIST"];
        //[dic setObject:image forKey:@"ARTWORK"];
   
        NSData *updValue = [NSKeyedArchiver archivedDataWithRootObject:dic];
   
        
        [self.peripheralManager updateValue:updValue forCharacteristic:_musicInfoCharacteristic onSubscribedCentrals:nil];
    }
}

- (void) volumeChange
{
    NSLog(@"Volume Change");
    NSLog(@"%f",[self.player volume]);
}


- (IBAction)btnPrevPush:(id)sender {
    [self.player skipToPreviousItem];
}

- (IBAction)btnPlayPush:(id)sender {
    if(self.isPlaying == NO) {
        [self.btnPlay setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
        [self.player play];
        self.isPlaying = YES;
    }else{
        self.isPlaying = NO;
        [self.btnPlay setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
        [self.player pause];
        
    }
}

- (IBAction)btnNextPush:(id)sender {
    [_player skipToNextItem];
}

- (void) setVolume:(int)flg
{
    float vol = [_player volume];
    switch (flg) {
        case 1:
            vol += 0.0625;
            break;
        case 0:
            vol -= 0.0625;
            break;
    }
    
    if (vol <= 0.0 ) {
        vol = 0.0;
    }else if (vol >= 1.0){
        vol = 1.0;
    }
    [self.player setVolume:vol];
}

- (NSData *)getResponseValue{
    
    uint val;
    
    if (self.isPlaying){
        val = 1;
    }else{
        val = 0;
    }
    
    return [NSData dataWithBytes:&val length:1];
    
}

@end
