#import "DeezerSessionViewController.h"
#import "DeezerItemViewController.h"
#import "DZRModel.h"
#import "DZRRequestManager.h"

@interface DeezerSessionViewController()
{
    /******************\
     |* Authorize View *|
     \******************/
    
    // Superview
    IBOutlet UIScrollView *_authorizeView;
    
    // Permissions labels and switches
    IBOutlet UISwitch *_basicAccessSwitch;
    IBOutlet UISwitch *_emailAccessSwitch;
    IBOutlet UISwitch *_offlineAccessSwitch;
    IBOutlet UISwitch *_manageLibrarySwitch;
    IBOutlet UISwitch *_deleteLibrarySwitch;
    IBOutlet UISwitch *_listeningHistorySwitch;
    
    // Authorize button
    IBOutlet UIButton* _authorizeButton;
    
    /**************\
     |* Token View *|
     \**************/
    
    IBOutlet UIScrollView   *_loggedView;
    IBOutlet UILabel        *_tokenLabel;
    IBOutlet UILabel        *_expirationDateLabel;
}
- (void)setIsLoggedIn:(BOOL)isLoogedIn;
@end

@implementation DeezerSessionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setTitle:@"Session"];
        [self setView:_authorizeView];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithTitle:@"Disconnect"
                                                  style:UIBarButtonItemStylePlain
                                                  target:self action:@selector(disconnect:)];
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [_authorizeView setContentSize:CGSizeMake([_authorizeView bounds].size.width, [_authorizeView bounds].size.height)];
        [_loggedView setContentSize:CGSizeMake([_loggedView bounds].size.width, [_loggedView bounds].size.height)];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkConnection];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[DeezerSession sharedSession] setConnectionDelegate:nil];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)checkConnection
{
    [[DeezerSession sharedSession] setConnectionDelegate:self];
    [self setIsLoggedIn:[[DeezerSession sharedSession] isSessionValid]];
}

- (void)setIsLoggedIn:(BOOL)isLoggedIn {
    [_tokenLabel setText:[NSString stringWithFormat:@"Token : %@", [[[DeezerSession sharedSession] deezerConnect] accessToken]]];
    [_expirationDateLabel setText:[NSString stringWithFormat:@"Expiration Date : %@", [[[[DeezerSession sharedSession] deezerConnect] expirationDate] description]]];
    [self setView:isLoggedIn ? _loggedView : _authorizeView];
    [_authorizeView setHidden:isLoggedIn];
}

#pragma mark - IBAction

- (IBAction)onAuthorizeButtonPushed:(id)sender {
    
    NSMutableArray* permissionsArray = [NSMutableArray array];
    
    if ([_basicAccessSwitch isOn]) {
        [permissionsArray addObject:DeezerConnectPermissionBasicAccess];
    }
    if ([_emailAccessSwitch isOn]) {
        [permissionsArray addObject:DeezerConnectPermissionEmail];
    }
    if ([_offlineAccessSwitch isOn]) {
        [permissionsArray addObject:DeezerConnectPermissionOfflineAccess];
    }
    if ([_manageLibrarySwitch isOn]) {
        [permissionsArray addObject:DeezerConnectPermissionManageLibrary];
    }
    if ([_deleteLibrarySwitch isOn]) {
        [permissionsArray addObject:DeezerConnectPermissionDeleteLibrary];
    }
    if ([_listeningHistorySwitch isOn]) {
        [permissionsArray addObject:DeezerConnectPermissionListeningHistory];
    }
    [[DeezerSession sharedSession] connectToDeezerWithPermissions:permissionsArray];
}

- (IBAction)showUser:(id)sender {
    [DZRUser
            objectWithIdentifier:@"me"
                  requestManager:[DZRRequestManager defaultManager]
                        callback:^(DZRObject *o, NSError *error) {
        DeezerItemViewController *itemViewController = [[DeezerItemViewController alloc] initWithDZRObject:o];
        [[self navigationController] pushViewController:itemViewController animated:YES];
    }];
}

- (IBAction)disconnect:(id)sender {
    [[DeezerSession sharedSession] logOut];
}

#pragma mark - DeezerItemConnectionDelegate

- (void)deezerSessionDidConnect {
    [self setIsLoggedIn:YES];
}

- (void)deezerSessionDidFailConnectionWithError:(NSError*)error {
    
}

- (void)deezerSessionDidDisconnect {
    [self setIsLoggedIn:NO];
}

@end
