#import <UIKit/UIKit.h>

@protocol PlayerAndBufferSliderDelegate;

@interface PlayerAndBufferSlider : UIView {
	id<PlayerAndBufferSliderDelegate> __weak _delegate;
    
    // Time labels
	UILabel*        _elapsedTimeLabel;
	UILabel*        _durationLabel;
    
    // Sliders
    UISlider*       _bufferSlider;
	UISlider*       _playSlider;
    
	BOOL            _forwardPlayProgressChanged;
    
	NSTimer*        _progressTimer;
    int             _progressInSeconds;
}

@property (nonatomic, weak) id<PlayerAndBufferSliderDelegate> delegate;
@property (nonatomic, assign) CGFloat   bufferProgress;
@property (nonatomic, assign) UInt32    duration;
@property (nonatomic, assign) CGFloat   playProgress;
@property (nonatomic, assign) UInt32    timePosition;

- (void)startTimer;
- (void)pauseTimer;
- (void)reset;
- (void)hideKnob;

@end

@protocol PlayerAndBufferSliderDelegate <NSObject>
- (void)changePlayProgress:(float)in_progress;
@end