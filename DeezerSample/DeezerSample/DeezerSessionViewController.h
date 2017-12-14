#import <UIKit/UIKit.h>
#import "DeezerSession.h"

@interface DeezerSessionViewController : UIViewController <DeezerSessionConnectionDelegate>
- (void)checkConnection;
@end
