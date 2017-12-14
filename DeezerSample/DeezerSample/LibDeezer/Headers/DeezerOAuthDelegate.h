#import <Foundation/Foundation.h>

@class DeezerOAuthView;


/**
 * Deezer OAuth delegate. Use into DeezerConnect class.
 * You don't have to implements this delegate, only DeezerConnect uses it.
 */
@protocol DeezerOAuthDelegate <NSObject>

@optional

/**
 * The connection OAuth succeeded.
 */
- (void)deezerOAuthSucceededWithToken:(NSString*)token expirationDate:(NSDate*)expirationDate;

/**
 * The connection OAuth not succeeded (example: when there is a wrong login/password).
 */
- (void)deezerOAuthDidNotSucceed:(BOOL)cancelled;


/**
 * The connection OAuth failed.
 */
- (void)deezerOAuth:(DeezerOAuthView*)deezerOAuth didFailWithError:(NSError *)error;

@end
