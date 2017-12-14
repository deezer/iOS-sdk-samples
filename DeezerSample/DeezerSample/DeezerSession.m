#import "DeezerSession.h"
#import "DZRModel.h"
#import "DZRRequestManager.h"

#define DEEZER_TOKEN_KEY @"DeezerTokenKey"
#define DEEZER_EXPIRATION_DATE_KEY @"DeezerExpirationDateKey"
#define DEEZER_USER_ID_KEY @"DeezerUserId"



@interface DeezerSession (Token_methods)
- (void)retrieveTokenAndExpirationDate;
- (void)saveToken:(NSString*)token andExpirationDate:(NSDate*)expirationDate forUserId:(NSString*)userId;
- (void)clearTokenAndExpirationDate;
@end

@implementation DeezerSession

@synthesize connectionDelegate = _connectionDelegate;
@synthesize requestDelegate = _requestDelegate;
@synthesize deezerConnect = _deezerConnect;
@synthesize currentUser = _currentUser;

#pragma mark - NSObject

- (id)init
{
    if (self = [super init]) {
        _deezerConnect = [[DeezerConnect alloc] initWithAppId:kDeezerAppId andDelegate:self];
        [[DZRRequestManager defaultManager] setDzrConnect:_deezerConnect];
        [self retrieveTokenAndExpirationDate];
    }
    return self;
}

#pragma mark - Connection
/**************\
|* Connection *|
\**************/

// See http://www.deezer.com/fr/developers/simpleapi/permissions
// for a description of the permissions
- (void)connectToDeezerWithPermissions:(NSArray*)permissionsArray {
    [_deezerConnect authorize:permissionsArray];
}

- (void)disconnect
{
    [_deezerConnect logout];
}

- (void)logOut
{
    [self clearTokenAndExpirationDate];
    [self disconnect];
}

- (BOOL)isSessionValid {
    return [_deezerConnect isSessionValid];
}

#pragma mark - Token
// The token needs to be saved on the device
- (void)retrieveTokenAndExpirationDate {
    NSUserDefaults* standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [_deezerConnect setAccessToken:[standardUserDefaults objectForKey:DEEZER_TOKEN_KEY]];
    [_deezerConnect setExpirationDate:[standardUserDefaults objectForKey:DEEZER_EXPIRATION_DATE_KEY]];
    [_deezerConnect setUserId:[standardUserDefaults objectForKey:DEEZER_USER_ID_KEY]];
}

- (void)saveToken:(NSString*)token andExpirationDate:(NSDate*)expirationDate forUserId:(NSString*)userId {
    NSUserDefaults* standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:token forKey:DEEZER_TOKEN_KEY];
    [standardUserDefaults setObject:expirationDate forKey:DEEZER_EXPIRATION_DATE_KEY];
    [standardUserDefaults setObject:userId forKey:DEEZER_USER_ID_KEY];
    [standardUserDefaults synchronize];
}

- (void)clearTokenAndExpirationDate {
    NSUserDefaults* standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults removeObjectForKey:DEEZER_TOKEN_KEY];
    [standardUserDefaults removeObjectForKey:DEEZER_EXPIRATION_DATE_KEY];
    [standardUserDefaults removeObjectForKey:DEEZER_USER_ID_KEY];
    [standardUserDefaults synchronize];
}

#pragma mark - DeezerSessionDelegate

- (void)deezerDidLogin {
    NSLog(@"Deezer did login");
    [self saveToken:[_deezerConnect accessToken] andExpirationDate:[_deezerConnect expirationDate] forUserId:[_deezerConnect userId]];
    if ([_connectionDelegate respondsToSelector:@selector(deezerSessionDidConnect)]) {
        [_connectionDelegate deezerSessionDidConnect];
    }
}

- (void)deezerDidNotLogin:(BOOL)cancelled {
    NSLog(@"Deezer Did not login : %@", cancelled ? @"Cancelled" : @"Not Cancelled");
}

- (void)deezerDidLogout {
    NSLog(@"Deezer Did logout");
    if ([_connectionDelegate respondsToSelector:@selector(deezerSessionDidDisconnect)]) {
        [_connectionDelegate deezerSessionDidDisconnect];
    }
}

#pragma mark - Singleton methods

static DeezerSession* _sharedSessionManager = nil;

+ (DeezerSession*)sharedSession {
    if (_sharedSessionManager == nil) {
        _sharedSessionManager = [[super alloc] init];
    }
    return _sharedSessionManager;
}

@end
