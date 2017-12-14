#import "DeezerAudioPlayerController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "DZRRequestManager.h"
#import "DZRPlayer.h"

#define kPlay_image_normal          [UIImage imageNamed:@"Player_Play_Normal.png"]
#define kPlay_image_highlighted     [UIImage imageNamed:@"Player_Play_Highlighted.png"]
#define kPause_image_normal         [UIImage imageNamed:@"Player_Pause_Normal.png"]
#define kPause_image_highlighted    [UIImage imageNamed:@"Player_Pause_Highlighted.png"]
#define kRepeat_image_normal        [UIImage imageNamed:@"Player_Repeat.png"]
#define kRepeat_image_All           [UIImage imageNamed:@"Player_Repeat_All_Active.png"]
#define kRepeat_image_One           [UIImage imageNamed:@"Player_Repeat_One_Active.png"]
#define kShuffle_image_normal       [UIImage imageNamed:@"Player_Shuffle.png"]
#define kShuffle_image_active       [UIImage imageNamed:@"Player_Shuffle_Active.png"]

@interface DeezerAudioPlayerController () <DZRPlayerDelegate, PlayerAndBufferSliderDelegate>
{
    IBOutlet UIImageView            *_coverImageView;
    IBOutlet UILabel                *_nameLabel;
    IBOutlet UILabel                *_artistNameLabel;
    IBOutlet UILabel                *_albumName;
    IBOutlet UIButton               *_playButton;
    IBOutlet UIButton               *_nextButton;
    IBOutlet UIButton               *_previousButton;
    IBOutlet UIButton               *_repeatButton;
    IBOutlet UIButton               *_shuffleButton;
    IBOutlet PlayerAndBufferSlider  *_progressSliderView;
}
@property (nonatomic, strong) DZRPlayer *player;
@property (nonatomic, strong) DZRRequestManager *manager;
@property (nonatomic, assign) BOOL isTwoWayPlayable;

- (void)updatePlayPauseButton;
@end

@implementation DeezerAudioPlayerController

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (id)initWithPlayable:(id<DZRPlayable>)playable
{
    return [self initWithPlayable:playable startIndex:0];
}

- (id)initWithPlayable:(id<DZRPlayable>)playable startIndex:(NSUInteger)startIndex
{
    NSString* nibName;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        nibName = @"DeezerAudioPlayerController_iPhone";
    } else {
        nibName = @"DeezerAudioPlayerController_iPad";
    }
    self = [super initWithNibName:nibName bundle:nil];
    
    if (self) {
        self.player = [[DZRPlayer alloc] initWithConnection:[DeezerSession sharedSession].deezerConnect];
        self.player.delegate = self;
        self.player.shouldUpdateNowPlayingInfo = YES;
        [self.player play:playable atIndex:startIndex];
        self.manager = [[DZRRequestManager defaultManager] subManager];
        self.isTwoWayPlayable = [(NSObject*)playable.iterator conformsToProtocol:@protocol(DZRPlayableRandomAccessIterator)];
    }
    
    return self;
}

- (void)dealloc
{
    [self.player stop];
    self.player = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_progressSliderView setDelegate:self];
//    [_progressSliderView hideKnob];
    [self updatePlayPauseButton];
    [self updateRepeatButton];
    [self updateShuffleButton];
    [_nextButton setImage:[UIImage imageNamed:@"Player_Next_Normal"] forState:UIControlStateNormal];
    [_nextButton setImage:[UIImage imageNamed:@"Player_Next_Highlighted"] forState:UIControlStateHighlighted];
    [_previousButton setImage:[UIImage imageNamed:@"Player_Previous_Normal"] forState:UIControlStateNormal];
    [_previousButton setImage:[UIImage imageNamed:@"Player_Previous_Highlighted"] forState:UIControlStateHighlighted];
    _previousButton.enabled = self.isTwoWayPlayable;
    _repeatButton.enabled = self.isTwoWayPlayable;
    _shuffleButton.enabled = self.isTwoWayPlayable;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)setTrack:(DZRTrack*)track
{
    typeof (self) __weak weakPlayerVC = self;

    [_progressSliderView setDuration:0];
    [_progressSliderView setBufferProgress:0.0];
    [_progressSliderView setPlayProgress:0.0];
    
    [track playableInfosWithRequestManager:self.manager
                 callback:^(NSDictionary *info, NSError *error) {
                     typeof(weakPlayerVC) __strong playerVC = weakPlayerVC;
                     if (playerVC == nil) return;
                     if (error) {
                         [playerVC presentError:error];
                         return;
                     }

                     playerVC->_nameLabel.text = [info objectForKey:DZRPlayableObjectInfoName];
                     playerVC->_artistNameLabel.text = [info objectForKey:DZRPlayableObjectInfoCreator];
                     playerVC->_albumName.text = [info objectForKey:DZRPlayableObjectInfoSource];
                 }];
    
    [track
     illustrationWithRequestManager:self.manager
     callback:^(UIImage *illustration, NSError *error) {
         typeof(weakPlayerVC) __strong playerVC = weakPlayerVC;
         if (playerVC) {
             playerVC->_coverImageView.image = illustration;
         }
     }];
}

#pragma mark Player

- (IBAction)onPlayButtonPushed:(id)sender
{
    if ([self.player isPlaying]) {
        [self.player pause];
    }
    else {
        [self.player play];
    }
}

- (IBAction)onRepeatButtonPushed:(id)sender
{
    [self.player updateRepeatMode:(self.player.repeatMode + 1)%3];
    [self updateRepeatButton];
}

- (IBAction)onShuffleButtonPushed:(id)sender
{
    [self.player toggleShuffleMode];
    [self updateShuffleButton];
}

- (IBAction)onNextButtonPushed:(id)sender
{
    [self.player next];
}

- (IBAction)onPreviousButtonPushed:(id)sender
{
    [self.player previous];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
        case UIEventSubtypeRemoteControlPause:
            [self onPlayButtonPushed:self];
            break;
        case UIEventSubtypeRemoteControlNextTrack:
            [self onNextButtonPushed:self];
            break;
        case UIEventSubtypeRemoteControlPreviousTrack:
            [self onPreviousButtonPushed:self];
            break;
        default:
            break;
    }
}

#pragma mark DZRPlayerDelegate

- (void)player:(DZRPlayer *)player didBuffer:(long long)bufferedBytes outOf:(long long)totalBytes
{
    float progress = (double)bufferedBytes / (double)totalBytes;
    [_progressSliderView setBufferProgress:progress];
}

- (void)player:(DZRPlayer *)player didEncounterError:(NSError *)error
{
    [self presentError:error];
    [self updatePlayPauseButton];
}

- (void)player:(DZRPlayer *)player didPlay:(long long)playedBytes outOf:(long long)totalBytes
{
    float progress = (double)playedBytes / (double)totalBytes;
    [_progressSliderView setDuration:(UInt32)self.player.currentTrackDuration];
    [_progressSliderView setBufferProgress:self.player.bufferProgress];
    [_progressSliderView setPlayProgress:progress];
    [self updatePlayPauseButton];
}

- (void)player:(DZRPlayer *)player didStartPlayingTrack:(DZRTrack *)track
{
    [self setTrack:track];
    [self updatePlayPauseButton];
}

- (void)playerDidPause:(DZRPlayer *)player
{
    [self updatePlayPauseButton];
}

#pragma mark - PlayerAndBufferSliderDelegate

- (void)changePlayProgress:(float)in_progress
{
    self.player.progress = in_progress;
}

#pragma mark - Play/Pause btn

//
// Change image to Pause.
//
- (void)activatePauseButton
{
	[_playButton setImage:kPause_image_normal forState:UIControlStateNormal];
	[_playButton setImage:kPause_image_highlighted forState:UIControlStateHighlighted];
}

//
// Change image to Play.
//
- (void)activatePlayButton
{
	[_playButton setImage:kPlay_image_normal forState:UIControlStateNormal];
	[_playButton setImage:kPlay_image_highlighted forState:UIControlStateHighlighted];
}

#pragma mark - Repeat btn

- (void)updateRepeatButton
{
    if (!self.isTwoWayPlayable) {
        _repeatButton.hidden = YES;
        return;
    }
    
    _repeatButton.hidden = NO;
    UIImage *image;
    switch ((int)self.player.repeatMode) {
        case DZRPlaybackRepeatModeAllTracks:
            image = kRepeat_image_All;
            break;
        case DZRPlaybackRepeatModeCurrentTrack:
            image = kRepeat_image_One;
            break;
        default:
            image = kRepeat_image_normal;
            break;
    }
    [_repeatButton setImage:image forState:UIControlStateNormal];
}

#pragma mark - Shuffle btn

- (void)updateShuffleButton
{
    if (!self.isTwoWayPlayable) {
        _shuffleButton.hidden = YES;
        return;
    }
    
    _shuffleButton.hidden = NO;
    UIImage *image;
    if(self.player.shuffleMode)
    {
        image = kShuffle_image_active;
    }
    else {
        image = kShuffle_image_normal;
    }
    [_shuffleButton setImage:image forState:UIControlStateNormal];
}

- (void)updatePlayPauseButton
{
    if (self.player.isReady) {
        _playButton.enabled = YES;
        _nextButton.enabled = YES;
        self.player.isPlaying ? [self activatePauseButton] : [self activatePlayButton];
    }
    else {
        [self activatePlayButton];
        _playButton.enabled = NO;
        _nextButton.enabled = NO;
    }
}
@end
