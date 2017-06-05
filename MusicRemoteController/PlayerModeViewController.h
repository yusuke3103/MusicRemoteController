//
//  PlayerModeViewController.h
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2014/03/24.
//  UPDATE VERSION 1.2.0 2015/07/26.
//  Copyright (c) 2014年 Yusuke Sato. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <MediaPlayer/MediaPlayer.h>

@interface PlayerModeViewController : UIViewController <CBPeripheralManagerDelegate>
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBCharacteristic *buttonCharacteristic;
@property (strong, nonatomic) CBCharacteristic *musicInfoCharacteristic;

@property (strong, nonatomic) CBUUID *serviceUUID;
@property (strong, nonatomic) CBUUID *buttonUUID;
@property (strong, nonatomic) CBUUID *musicInfoUUID;

@property (strong, nonatomic) MPMusicPlayerController *player;
@property (strong, nonatomic) NSNotificationCenter *ncenter;
@property BOOL isPlaying;

@property (weak, nonatomic) IBOutlet UIView *barVolume;
@property (weak, nonatomic) IBOutlet UIImageView *imageArtwork;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblArtist;
@property (weak, nonatomic) IBOutlet UIButton *btnPrev;
@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIButton *btnNext;

- (IBAction)btnPrevPush:(id)sender;
- (IBAction)btnPlayPush:(id)sender;
- (IBAction)btnNextPush:(id)sender;
@end
