//
//  PlayerModeViewController.h
//  MusicRemoteController
//
//  Created by Yusuke Sato on 2014/03/24.
//  Copyright (c) 2014年 Yusuke Sato. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <MediaPlayer/MediaPlayer.h>

@interface PlayerModeViewController : UIViewController <CBCentralManagerDelegate>
{
    NSString *St_Service;
    NSString *St_Characteristic;
    CBUUID *UUID_Service;
    CBUUID *UUID_Characteristic;
}
//==========================
// MediaPlayer Programing
//==========================
@property MPMusicPlayerController *player;
@property BOOL isPlaying;
@property NSNotificationCenter *ncenter;


@property (weak, nonatomic) IBOutlet UILabel *lb_Artist;
@property (weak, nonatomic) IBOutlet UILabel *lb_Title;
@property (weak, nonatomic) IBOutlet UIImageView *im_Artwork;
@property (weak, nonatomic) IBOutlet UIButton *bt_Prev;
@property (weak, nonatomic) IBOutlet UIButton *bt_Play;
@property (weak, nonatomic) IBOutlet UIButton *bt_Next;
@property (weak, nonatomic) IBOutlet UIView *vi_volume;

- (IBAction)bt_Prev_Push:(id)sender;
- (IBAction)bt_Play_Push:(id)sender;
- (IBAction)bt_Next_Push:(id)sender;



//==========================
// CoreBluetooth Programing
//==========================
@property (strong,nonatomic) CBCentralManager *centralManager;
@property (strong,nonatomic) CBPeripheral *peripheral;
@property (strong,nonatomic) NSMutableData *data;
@end
