#import <UIKit/UIKit.h>
#import "DeezerSession.h"

#import "PlayerAndBufferSlider.h"
#import "DZRModel.h"

@interface DeezerAudioPlayerController : UIViewController
- (id)initWithPlayable:(id<DZRPlayable>)playable startIndex:(NSUInteger)startIndex;
- (id)initWithPlayable:(id<DZRPlayable>)playable;
- (IBAction)onPlayButtonPushed:(id)sender;
@end
