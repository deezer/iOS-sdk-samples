#import "PlayerAndBufferSlider.h"

#define PROGRESS_TIMER_UPDATE_TIMEOUT 10

#define kLabelsOffset 3
#define kLabelsFont [UIFont fontWithName:@"Helvetica-Bold" size:11]
#define kLabelsSize [@"00:00" sizeWithAttributes:@{NSFontAttributeName:kLabelsFont}]

@interface PlayerAndBufferSlider ()
@property (nonatomic, strong) NSTimer* progressTimer;
- (NSString*)getTimeStringFromSeconds:(UInt32)seconds;
@end

@implementation PlayerAndBufferSlider

@synthesize delegate = _delegate;
@synthesize duration = _duration;
@synthesize playProgress = _playProgress;
@synthesize progressTimer = _progressTimer;
@synthesize timePosition = _timePosition;

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        {
            _elapsedTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kLabelsSize.width, [self bounds].size.height)];
            [_elapsedTimeLabel setBackgroundColor:[UIColor clearColor]];
            [_elapsedTimeLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
            [_elapsedTimeLabel setFont:kLabelsFont];
            [_elapsedTimeLabel setText:@"--:--"];
            [_elapsedTimeLabel setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
            [self addSubview:_elapsedTimeLabel];
        }
        
        {
            _durationLabel = [[UILabel alloc] initWithFrame:CGRectMake([self bounds].size.width - kLabelsSize.width, 0, kLabelsSize.width, [self bounds].size.height)];
            [_durationLabel setBackgroundColor:[UIColor clearColor]];
            [_durationLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
            [_durationLabel setTextAlignment:NSTextAlignmentRight];
            [_durationLabel setFont:kLabelsFont];
            [_durationLabel setText:@"--:--"];
            [_durationLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
            [self addSubview:_durationLabel];
        }
        
        CGRect slidersFrame = CGRectMake([_elapsedTimeLabel bounds].size.width + kLabelsOffset,
                                         0,
                                         [self bounds].size.width - 2 * ([_elapsedTimeLabel bounds].size.width + kLabelsOffset),
                                         [self bounds].size.height);
        {
            // Instead of using a custom UIProgressView (available since ios5 only), we customize a UISlider with a transparent image for the knob
            _bufferSlider = [[UISlider alloc] initWithFrame:slidersFrame];
            [_bufferSlider setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
            UIImage *stetchLeftTrack = [[UIImage imageNamed:@"Player_ProgressSlider_DownloadProgress.png"] stretchableImageWithLeftCapWidth:3.0 topCapHeight:0.0];
            [_bufferSlider setMinimumTrackImage:stetchLeftTrack forState:UIControlStateNormal];
            UIImage *stetchRightTrack = [[UIImage imageNamed:@"Player_ProgressSlider_Background.png"] stretchableImageWithLeftCapWidth:3.0 topCapHeight:0.0];
            [_bufferSlider setMaximumTrackImage:stetchRightTrack forState:UIControlStateNormal];
            UIImage *fakeKnobImage = [UIImage imageNamed:@"transparentImage.png"];
            [_bufferSlider setThumbImage:fakeKnobImage forState:UIControlStateNormal];
            [_bufferSlider setContinuous:NO];
            [self addSubview:_bufferSlider];
        }
        
        {
            _playSlider = [[UISlider alloc] initWithFrame:slidersFrame];
            [_playSlider setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
            UIImage *stetchLeftTrack = [[UIImage imageNamed:@"Player_ProgressSlider_PlayProgress.png"] stretchableImageWithLeftCapWidth:3.0 topCapHeight:0.0];
            [_playSlider setMinimumTrackImage:stetchLeftTrack forState:UIControlStateNormal];
            UIImage *stetchRightTrack = [UIImage imageNamed:@"transparentImage.png"];
            [_playSlider setMaximumTrackImage:stetchRightTrack forState:UIControlStateNormal];
            [_playSlider setContinuous:NO];
            
            [_playSlider addTarget:self action:@selector(sliderValueChanged:event:) forControlEvents:UIControlEventValueChanged];
            
            [self addSubview:_playSlider];
        }
	}
    return self;
}


- (void)dealloc {
    [_progressTimer invalidate];
}

- (CGFloat)bufferProgress {
    return [_bufferSlider value];
}

- (void)setBufferProgress:(CGFloat)bufferProgress {
    [_bufferSlider setValue:bufferProgress];
}

- (void)setDuration:(UInt32)duration {
	_duration = duration;
    [_durationLabel setText:[self getTimeStringFromSeconds:_duration]];
}

- (void)setPlayProgress:(CGFloat)playProgress {
    _playProgress = playProgress;
    _timePosition = _playProgress * _duration;
    
    [_playSlider setValue:_playProgress];
    [_elapsedTimeLabel setText:[self getTimeStringFromSeconds:_timePosition]];
}

- (void)setTimePosition:(UInt32)timePosition {
    _timePosition = timePosition;
    _playProgress = (CGFloat)_timePosition / (CGFloat)_duration;
    
    [_playSlider setValue:_playProgress];
    [_elapsedTimeLabel setText:[self getTimeStringFromSeconds:_timePosition]];
}

- (void)startTimer {
    [_progressTimer invalidate];
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                          target:self
                                                        selector:@selector(timerTicked:)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)pauseTimer {
	[_progressTimer invalidate];
	self.progressTimer = nil;
}

- (void)hideKnob {
    UIImage *fakeKnobImage = [UIImage imageNamed:@"transparentImage.png"];
    [_playSlider setThumbImage:fakeKnobImage forState:UIControlStateNormal];
}

- (void)reset {
    [self setBufferProgress:0.0];
    [self setPlayProgress:0.0];
    [self setDuration:0];
	[self pauseTimer];
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    [_playSlider setUserInteractionEnabled:userInteractionEnabled];
}

- (void)timerTicked:(NSTimer*)timer {
    [self setTimePosition:(_timePosition + 1)];
}

- (NSString*)getTimeStringFromSeconds:(UInt32)seconds {
    if (seconds == 0) {
        return @"--:--";
    }
    UInt32 minutes = seconds / 60;
    seconds -= (minutes * 60);
    return [NSString stringWithFormat:@"%d:%.2d", (unsigned int)minutes, (unsigned int)seconds];
}

- (void)sliderValueChanged:(id)sender event:(id)event {
    [self setPlayProgress:[_playSlider value]];
    if ([_delegate respondsToSelector:@selector(changePlayProgress:)]) {
        [_delegate changePlayProgress:[_playSlider value]];
    }
}

@end
