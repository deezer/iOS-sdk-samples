#import "DeezerSampleAppDelegate.h"

#import "DeezerSessionViewController.h"
#import "DeezerSearchViewController.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "DeezerSession.h"


#if DEBUG

@implementation NSURLRequest (NSURLRequestWithIgnoreSSL)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
{
    return YES;
}
@end

#endif


@interface DeezerSampleAppDelegate () <UITabBarDelegate>
@property (nonatomic, strong) UINavigationController *registeredPart;
@property (nonatomic, strong) UINavigationController *unregisteredPart;
@end

@implementation DeezerSampleAppDelegate
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    UIViewController* sessionViewController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        sessionViewController =
            [[DeezerSessionViewController alloc] initWithNibName:@"DeezerSessionViewController_iPhone" bundle:nil];
    }
    else {
        sessionViewController =
            [[DeezerSessionViewController alloc] initWithNibName:@"DeezerSessionViewController_iPad" bundle:nil];
    }
    self.registeredPart = [[UINavigationController alloc] initWithRootViewController:sessionViewController];
    self.registeredPart.navigationBar.translucent = NO;
    self.registeredPart.tabBarItem =
        [[UITabBarItem alloc] initWithTitle:@"Registered" image:[UIImage imageNamed:@"user-50"] tag:0];
    
    self.unregisteredPart = [[UINavigationController alloc]
        initWithRootViewController:[[DeezerSearchViewController alloc] initWithActiveButtons:SearchButton_ALBUMS
                                                                                             | SearchButton_ARTISTS
                                                                                             | SearchButton_TRACKS]];
    self.unregisteredPart.navigationBar.translucent = NO;
    self.unregisteredPart.tabBarItem =
        [[UITabBarItem alloc] initWithTitle:@"Unregistred" image:[UIImage imageNamed:@"fraud-50"] tag:1];

    UITabBarController* rootVC = [[UITabBarController alloc] init];
    [rootVC setViewControllers:@[ self.registeredPart, self.unregisteredPart ] animated:NO];
    rootVC.delegate = self;
    rootVC.tabBar.translucent = NO;

    [self.window setRootViewController:rootVC];
    [self.window makeKeyAndVisible];

    [self configureAudioSession];

    return YES;
}

- (void)configureAudioSession
{
    /*
     * This will make the audio played even if the sound of the device is on mute.
     */
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     * To read the audio in background
     * Don't forget to add "App plays audio" in "Required background modes", in the plist of the project.
     */
    bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });
}

#pragma mark - UITabBarDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    [self.registeredPart popToRootViewControllerAnimated:NO];
    [self.unregisteredPart popToRootViewControllerAnimated:NO];

    if (viewController == self.registeredPart) {
        [[DeezerSession sharedSession] retrieveTokenAndExpirationDate];
        [self.registeredPart.viewControllers[0] checkConnection];
    }
    else if (viewController == self.unregisteredPart) {
        [[DeezerSession sharedSession] disconnect];
    }
}

@end
