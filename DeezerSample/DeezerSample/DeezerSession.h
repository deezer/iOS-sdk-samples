#import <Foundation/Foundation.h>
#import "DeezerConnect.h"

#define kDeezerAppId @"100041"

#define kDeezerPermissions nil

@class DeezerUser;

@protocol DeezerSessionConnectionDelegate;
@protocol DeezerSessionRequestDelegate;

@interface DeezerSession : NSObject <DeezerSessionDelegate>

@property (nonatomic, weak)   id<DeezerSessionConnectionDelegate> connectionDelegate;
@property (nonatomic, weak)   id<DeezerSessionRequestDelegate>    requestDelegate;
@property (nonatomic, readonly) DeezerConnect* deezerConnect;
@property (nonatomic, strong)   DeezerUser* currentUser;

+ (DeezerSession*)sharedSession;

#pragma mark - Connection
- (void)connectToDeezerWithPermissions:(NSArray*)permissionsArray;
- (void)disconnect;
- (void)logOut;
- (BOOL)isSessionValid;
- (void)retrieveTokenAndExpirationDate;
@end


@protocol DeezerSessionConnectionDelegate <NSObject>
@optional
- (void)deezerSessionDidConnect;
- (void)deezerSessionConnectionDidFailWithError:(NSError*)error;
- (void)deezerSessionDidDisconnect;
@end


@protocol DeezerSessionRequestDelegate <NSObject>

@optional
- (void)deezerSessionRequestDidReceiveResponse:(NSData*)data;
- (void)deezerSessionRequestDidFailWithError:(NSError*)error;

@end