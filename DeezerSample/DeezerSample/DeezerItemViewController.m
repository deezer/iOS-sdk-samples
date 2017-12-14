#import "DeezerItemViewController.h"
#import "DeezerObjectListViewController.h"
#import "DeezerCommentViewController.h"
#import "DeezerRateViewController.h"
#import "PlayerAndBufferSlider.h"
#import "DeezerSearchViewController.h"
#import "DeezerInputViewController.h"

#import "DZRModel.h"
#import "DZRRequestManager.h"
#import "DZRCancelable.h"
#import "DeezerAudioPlayerController.h"
#import "NSBundle+DZRBundle.h"
#import "DZRPlayer.h"
#import "DZRPlayableArray.h"
#import "UIAlertController+Utils.h"
#import "NSDictionary+Utils.h"

static NSString * const alertTitleData = @"Data";

@interface DeezerItemViewController () <DeezerObjectListViewControllerDelegate, DeezerSearchViewControllerDelegate, DeezerInputViewControllerDelegate>
{
    IBOutlet UITableView    *_tableView;
}
@property (nonatomic, strong) DZRRequestManager *manager;
@property (nonatomic, strong) DZRObject *object;
@property (nonatomic, strong) NSArray *info;
@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, strong) NSArray *actions;
@property (nonatomic, strong) NSMapTable *delegateMap;

- (id<DeezerSearchViewControllerDelegate>)addSearchDelegateBlock:(void(^)(NSArray *objects, DZRRequestManager *manager, DeezerItemViewController *vc))block
                                                     forSearchVC:(DeezerSearchViewController*)vc;
- (id<DeezerObjectListViewControllerDelegate>)addObjectListDelegate:(BOOL(^)(NSArray *objects, DZRRequestManager *manager, DeezerItemViewController *vc))block
                                                    forObjectListVC:(DeezerObjectListViewController*)vc;
- (id<DeezerInputViewControllerDelegate>)addInputDelegate:(void(^)(NSDictionary *values, DZRRequestManager *manager, DeezerItemViewController *vc))block
                                               forInputVC:(DeezerInputViewController*)vc;
@end

#pragma mark - Utilities

@interface DeezerItemViewControllerAction : NSObject
+ (instancetype)actionWithTitle:(NSString*)title block:(void(^)(void))block;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, copy) void (^block)(void);
@end

@implementation DeezerItemViewControllerAction
+ (instancetype)actionWithTitle:(NSString*)title block:(void(^)(void))block
{
    DeezerItemViewControllerAction *a = [self new];
    a.title = title;
    a.block = block;
    return a;
}
@end

#pragma mark - Monkey Patching
#pragma mark NSArray

@interface NSArray (DZRRandomize)
- (NSArray*)arrayByShuffelingElements;
@end

@implementation NSArray (DZRRandomize)
- (NSArray*)arrayByShuffelingElements
{
    NSMutableArray *temp = [self mutableCopy];
    
    for (NSUInteger i = [self count]; i > 1; i--) {
        NSUInteger j = arc4random_uniform((uint32_t)i);
        [temp exchangeObjectAtIndex:i-1 withObjectAtIndex:j];
    }
    
    return [NSArray arrayWithArray:temp];
}
@end

#pragma mark DZRModel

@interface DZRObject (DeezerItemViewAdditions)
- (void)requestDisplayableInfoWithRequestManager:(DZRRequestManager*)manager
                                        callback:(void(^)(NSArray* infos, NSError* error))callback;
- (NSArray*)actionsWithViewController:(__weak DeezerItemViewController*)vc;
@end

@implementation DZRObject (DeezerItemViewAdditions)
- (void)requestDisplayableInfoWithRequestManager:(DZRRequestManager *)manager
                                        callback:(void (^)(NSArray *, NSError *))callback
{
    NSArray *keys = self.supportedInfoKeys;
    [self
            valuesForKeyPaths:keys
           withRequestManager:manager
                     callback:^(NSDictionary *values, NSError *error) {
        if (error) {
            callback(nil, error);
        }
        else {
            callback([values objectsForKeys:keys notFoundMarker:[NSNull null]], nil);
        }
    }];
}
- (NSArray*)actionsWithViewController:(__weak DeezerItemViewController*)itemVC
{
    NSMutableArray *actions = [NSMutableArray array];
    
    if (self.isPlayable) {
        [actions
         addObject:[DeezerItemViewControllerAction
                    actionWithTitle:@"Play" block:^{
                        DeezerAudioPlayerController *vc = [[DeezerAudioPlayerController alloc] initWithPlayable:(DZRObject<DZRPlayable>*)self];
                        [itemVC.navigationController pushViewController:vc animated:YES];
                    }]];
    }
    if (self.isCommentable) {
        [actions
         addObject:[DeezerItemViewControllerAction
                    actionWithTitle:@"Comment object"
                    block:^{
                        DeezerCommentViewController *vc = [[DeezerCommentViewController alloc] init];
                        vc.object = (DZRObject<DZRCommentable>*)self;
                        [itemVC.navigationController pushViewController:vc animated:YES];
                    }]];
    }
    if (self.isRatable) {
        [actions
         addObject:[DeezerItemViewControllerAction
                    actionWithTitle:@"Rate object" block:^{
                        DeezerRateViewController *vc = [[DeezerRateViewController alloc] init];
                        vc.object = (DZRObject<DZRRatable>*)self;
                        [itemVC.navigationController pushViewController:vc animated:YES];
                    }]];
    }
    if (self.isFlowable) {
        [actions addObject:
         [DeezerItemViewControllerAction actionWithTitle:@"Flow Radio" block: ^{
            [(DZRObject<DZRFlowable>*)self flowRadioWithRequestManager:itemVC.manager callback:^(DZRManagedRadio *radio, NSError *error) {
                if (error) {
                    NSLog(@"%@", error);
                }
                else {
                    DeezerItemViewController *vc = [[DeezerItemViewController alloc] initWithDZRObject:radio];
                    [itemVC.navigationController pushViewController:vc animated:YES];
                }
            }];
        }]];
    }
    if (self.isRadioStreamable) {
        [actions addObject:[DeezerItemViewControllerAction actionWithTitle:@"Radio" block:^{
            [(DZRObject <DZRRadioStreamable> *) self radioWithRequestManager:itemVC.manager
                                                                    callback:^(DZRManagedRadio *radio,
                                                                        NSError *error) {
                if (error) {
                    NSLog(@"%@", error);
                }
                else {
                    DeezerItemViewController *vc = [[DeezerItemViewController alloc] initWithDZRObject:radio];
                    [itemVC.navigationController pushViewController:vc animated:YES];
                }
            }
            ];
        }]];
    }
    if (self.isDeletable) {
        [actions
         addObject:[DeezerItemViewControllerAction
                    actionWithTitle:@"Delete object"
                    block:^{
                        [(DZRObject<DZRDeletable>*)self deleteObjectWithRequestManager:itemVC.manager callback:^(NSError *error) {
                            NSLog(@"%@", error);
                            [itemVC.navigationController popViewControllerAnimated:YES];
                        }];
                    }]];
    }

    return [NSArray arrayWithArray:actions];
}
@end

@implementation DZRUser (DeezerItemViewAdditions)
- (NSArray *)actionsWithViewController:(__weak DeezerItemViewController *)itemVC
{
    void (^addFavorite)(NSArray *, DZRRequestManager*, DeezerItemViewController*) = ^(NSArray *objects, DZRRequestManager *manager, DeezerItemViewController *vc) {
        for (DZRObject *o in objects) {
            [self
             addFavorite:o
             withRequestManager:manager
             callback:^(NSError *error) {
                 if (error) NSLog(@"Cannot add a favorite: %@", error);
             }];
        }
    };
    
    BOOL (^deleteFavorite)(NSArray *, DZRRequestManager*, DeezerItemViewController*) =  ^(NSArray *objects, DZRRequestManager *manager, DeezerItemViewController *vc) {
        for (DZRObject *o in objects) {
            [self
             deleteFavorite:o
             withRequestManager:manager callback:^(NSError *error) {
                 if (error) NSLog(@"Cannot delete favorite: %@", error);
             }];
        }
        return YES;
    };
    
    void (^createPlaylist)(NSDictionary*, DZRRequestManager*, DeezerItemViewController*) = ^(NSDictionary *fields, DZRRequestManager *manager, DeezerItemViewController *vc) {
        [self
         createPlaylist:[fields valueForKey:@"title"] containingTracks:nil
         withRequestManager:manager
         callback:^(DZRPlaylist *playlist, NSError *error) {
             NSLog(@"%@", playlist);
         }];
    };
    
    return [[super actionsWithViewController:itemVC] arrayByAddingObjectsFromArray:
            @[[DeezerItemViewControllerAction
               actionWithTitle:@"Add Favorite Track"
               block:^{
                   DeezerSearchViewController *vc = [[DeezerSearchViewController alloc] initWithActiveButtons:SearchButton_TRACKS];
                   vc.delegate = [itemVC addSearchDelegateBlock:addFavorite forSearchVC:vc];
                   [itemVC.navigationController pushViewController:vc animated:YES];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Add Favorite Album" block:^{
                   DeezerSearchViewController *vc = [[DeezerSearchViewController alloc] initWithActiveButtons:SearchButton_ALBUMS];
                   vc.delegate = [itemVC addSearchDelegateBlock:addFavorite forSearchVC:vc];
                   [itemVC.navigationController pushViewController:vc animated:YES];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Add Favorite Artist" block:^{
                   DeezerSearchViewController *vc = [[DeezerSearchViewController alloc] initWithActiveButtons:SearchButton_ARTISTS];
                   vc.delegate = [itemVC addSearchDelegateBlock:addFavorite forSearchVC:vc];
                   [itemVC.navigationController pushViewController:vc animated:YES];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Add Favotite Object" block:^{
                   DeezerSearchViewController *vc = [[DeezerSearchViewController alloc] initWithActiveButtons:SearchButton_TRACKS |SearchButton_ARTISTS | SearchButton_ALBUMS];
                   vc.delegate = [itemVC addSearchDelegateBlock:addFavorite forSearchVC:vc];
                   [itemVC.navigationController pushViewController:vc animated:YES];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Add Favorite Podcast"
               block:^{
                   DeezerSearchViewController *vc = [[DeezerSearchViewController alloc] initWithActiveButtons:SearchButton_PODCASTS];
                   vc.delegate = [itemVC addSearchDelegateBlock:addFavorite forSearchVC:vc];
                   [itemVC.navigationController pushViewController:vc animated:YES];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Delete Favorite Track" block:^{
                  [self valueForKey:@"tracks" withRequestManager:itemVC.manager callback:^(DZRObjectList *tracks, NSError *error) {
                      DeezerObjectListViewController *vc = [[DeezerObjectListViewController alloc] initWithDZRObjectList:tracks];
                      vc.delegate = [itemVC addObjectListDelegate:deleteFavorite forObjectListVC:vc];
                      [itemVC.navigationController pushViewController:vc animated:YES];
                  }];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Delete Favorite Album" block:^{
                  [self valueForKey:@"albums" withRequestManager:itemVC.manager callback:^(DZRObjectList *tracks, NSError *error) {
                      DeezerObjectListViewController *vc = [[DeezerObjectListViewController alloc] initWithDZRObjectList:tracks];
                      vc.delegate = [itemVC addObjectListDelegate:deleteFavorite forObjectListVC:vc];
                      [itemVC.navigationController pushViewController:vc animated:YES];
                  }];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Delete Favorite Artist" block:^{
                  [self valueForKey:@"artists" withRequestManager:itemVC.manager callback:^(DZRObjectList *tracks, NSError *error) {
                      DeezerObjectListViewController *vc = [[DeezerObjectListViewController alloc] initWithDZRObjectList:tracks];
                      vc.delegate = [itemVC addObjectListDelegate:deleteFavorite forObjectListVC:vc];
                      [itemVC.navigationController pushViewController:vc animated:YES];
                  }];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Delete Favorite Playlist" block:^{
                  [self valueForKey:@"playlists" withRequestManager:itemVC.manager callback:^(DZRObjectList *tracks, NSError *error) {
                      DeezerObjectListViewController *vc = [[DeezerObjectListViewController alloc] initWithDZRObjectList:tracks];
                      vc.delegate = [itemVC addObjectListDelegate:deleteFavorite forObjectListVC:vc];
                      [itemVC.navigationController pushViewController:vc animated:YES];
                  }];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Delete Favorite Podcast" block:^{
                   [self valueForKey:@"podcasts" withRequestManager:itemVC.manager callback:^(DZRObjectList *tracks, NSError *error) {
                       DeezerObjectListViewController *vc = [[DeezerObjectListViewController alloc] initWithDZRObjectList:tracks];
                       vc.delegate = [itemVC addObjectListDelegate:deleteFavorite forObjectListVC:vc];
                       [itemVC.navigationController pushViewController:vc animated:YES];
                   }];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Create Playlist" block:^{
                   DeezerInputViewController *vc = [[DeezerInputViewController alloc] initWithFields:@[@"title"]];
                   vc.delegate = [itemVC addInputDelegate:createPlaylist forInputVC:vc];
                   [itemVC.navigationController pushViewController:vc animated:YES];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Chart Tracks"
               block:^{
                   [DZRTrack chartWithRequestManager:itemVC.manager numberOfItems:50 callback:^(id value, NSError *error) {
                       if (error) {
                           [itemVC presentError:error];
                       }
                       else if ([value isKindOfClass:[DZRObjectList class]]) {
                           UIViewController *details = [[DeezerObjectListViewController alloc] initWithDZRObjectList:value];
                           [itemVC.navigationController pushViewController:details animated:YES];
                       }
                   }];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Chart Albums"
               block:^{
                   [DZRAlbum chartWithRequestManager:itemVC.manager numberOfItems:50 callback:^(id value, NSError *error) {
                       if (error) {
                           [itemVC presentError:error];
                       }
                       else if ([value isKindOfClass:[DZRObjectList class]]) {
                           UIViewController *details = [[DeezerObjectListViewController alloc] initWithDZRObjectList:value];
                           [itemVC.navigationController pushViewController:details animated:YES];
                       }
                   }];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Chart Artists"
               block:^{
                   [DZRArtist chartWithRequestManager:itemVC.manager numberOfItems:50 callback:^(id value, NSError *error) {
                       if (error) {
                           [itemVC presentError:error];
                       }
                       else if ([value isKindOfClass:[DZRObjectList class]]) {
                           UIViewController *details = [[DeezerObjectListViewController alloc] initWithDZRObjectList:value];
                           [itemVC.navigationController pushViewController:details animated:YES];
                       }
                   }];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Chart Playlists"
               block:^{
                   [DZRPlaylist chartWithRequestManager:itemVC.manager numberOfItems:50 callback:^(id value, NSError *error) {
                       if (error) {
                           [itemVC presentError:error];
                       }
                       else if ([value isKindOfClass:[DZRObjectList class]]) {
                           UIViewController *details = [[DeezerObjectListViewController alloc] initWithDZRObjectList:value];
                           [itemVC.navigationController pushViewController:details animated:YES];
                       }
                   }];
               }],
              [DeezerItemViewControllerAction
               actionWithTitle:@"Test"
               block:^{
                   [DZRTrack objectWithIdentifier:@"-146325575" requestManager:itemVC.manager callback:^(DZRObject *o, NSError *error) {
                       [itemVC.navigationController pushViewController:[[DeezerItemViewController alloc] initWithDZRObject:o] animated:YES];
                   }];
               }]]];
}
@end

@implementation DZRPlaylist (DeezerItemViewAdditions)
- (NSArray *)actionsWithViewController:(__weak DeezerItemViewController *)itemVC
{
    return [[super actionsWithViewController:itemVC] arrayByAddingObjectsFromArray:
    @[[DeezerItemViewControllerAction
       actionWithTitle:@"Edit playlist info" block:^{
                [self
                        valuesForKeyPaths:@[@"title", @"description", @"public", @"collaborative"]
                       withRequestManager:itemVC.manager callback:^(NSDictionary *values, NSError *error) {
                    NSMutableArray *fields = [NSMutableArray array];
                    for (NSString *k in values) {
                        [fields addObject:[NSArray arrayWithObjects:k, [values objectForKey:k], nil]];
                    }

                    DeezerInputViewController *vc = [[DeezerInputViewController alloc]
                            initWithFields:fields];
                    vc.delegate = [itemVC
                            addInputDelegate:^(NSDictionary *values, DZRRequestManager *manager, DeezerItemViewController *vc) {
                                [self
                                        setValues:values
                               withRequestManager:manager
                                         callback:^(NSError *error) {
                                    [vc presentError:error];
                                }];
                            }
                                  forInputVC:vc];
                    [itemVC.navigationController pushViewController:vc animated:YES];
                }];
       }],
      [DeezerItemViewControllerAction
       actionWithTitle:@"Add Tracks to playlist" block:^{
           DeezerSearchViewController *vc = [[DeezerSearchViewController alloc] initWithActiveButtons:SearchButton_TRACKS];
           vc.delegate = [itemVC
                          addSearchDelegateBlock:^(NSArray *objects, DZRRequestManager *manager, DeezerItemViewController *vc) {
                              [self
                               addTracks:objects
                               withRequestManager:manager
                               callback:^(NSError *error) {
                                  NSLog(@"%@", error);
                              }];
                          }
                          forSearchVC:vc];
           [itemVC.navigationController pushViewController:vc animated:YES];
       }],
      [DeezerItemViewControllerAction
       actionWithTitle:@"Delete tracks from playlist"
       block:^{
          [self valueForKey:@"tracks" withRequestManager:itemVC.manager callback:^(id value, NSError *error) {
              DeezerObjectListViewController *vc = [[DeezerObjectListViewController alloc] initWithDZRObjectList:value];
              vc.delegate = [itemVC
                      addObjectListDelegate:^BOOL(NSArray *objects, DZRRequestManager *manager, DeezerItemViewController *vc) {
                          [self
                                  deleteTracks:objects
                            withRequestManager:manager
                                      callback:^(NSError *error) {

                          }];
                          return YES;
                      }
                            forObjectListVC:vc];
              [itemVC.navigationController pushViewController:vc animated:YES];
          }];
       }],
      [DeezerItemViewControllerAction
       actionWithTitle:@"Shuffle playlist's tracks"
       block:^{
          [self valueForKey:@"tracks" withRequestManager:itemVC.manager callback:^(DZRObjectList *tracks, NSError *error) {
              [tracks allObjectsWithManager:itemVC.manager callback:^(NSArray *tracks, NSError *error) {
                  [self orderTracks:[tracks arrayByShuffelingElements] withRequestManager:itemVC.manager callback:^(NSError *error) {
                      NSLog(@"%@", error);
                  }];
              }];
          }];
       }]]];
}
@end

@implementation DZRArtist (DeezerItemViewAdditions)
- (NSArray *)actionsWithViewController:(__weak DeezerItemViewController *)itemVC
{
    return [[super actionsWithViewController:itemVC] arrayByAddingObjectsFromArray:
            @[[DeezerItemViewControllerAction
               actionWithTitle:@"Play Top" block:^{
                   [self
                    valueForKeyPath:@"top"
                    withRequestManager:itemVC.manager callback:^(DZRObjectList *tracks, NSError *error) {
                        DZRPlayableArray *playable = [[DZRPlayableArray alloc] init];
                        [playable setTracks:tracks error:error];
                        DeezerAudioPlayerController *vc = [[DeezerAudioPlayerController alloc]
                                                         initWithPlayable:playable];
                        [itemVC.navigationController pushViewController:vc animated:YES];
                    }];
               }]]];
}
@end

#pragma mark - Implement the VC


@implementation DeezerItemViewController

- (id)initWithDZRObject:(DZRObject*)object
{
    NSString* nibName;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        nibName = @"DeezerItemViewController_iPhone";
    } else {
        nibName = @"DeezerItemViewController_iPad";
    }

    if (self = [super initWithNibName:nibName bundle:nil]) {
        self.imageCache = [[NSCache alloc] init];
        self.imageCache.countLimit = 50;
        self.manager = [[DZRRequestManager defaultManager] subManager];
        self.object = object;
        self.title = self.object.description;
        self.delegateMap = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

- (void)dealloc {
    _item = nil;
    [self.manager cancel];
    self.manager = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    id o = self.object;
    self.object = nil;
    self.object = o;
    [_tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)reload
{
    __weak DeezerItemViewController *my = self;

    [my.object
            valueForKey:@"title" withRequestManager:self.manager
               callback:^(id value, NSError *error) {
        my.title = value;
    }];
    
    [my.object
     requestDisplayableInfoWithRequestManager:self.manager
     callback:^(NSArray *info, NSError *error) {
         my.info = info;
         
         [_tableView reloadData];
     }];
}

#pragma mark - Setters

- (void)setObject:(DZRObject *)object
{
    if (_object != object) {
        _object = object;
        self.actions = [self.object actionsWithViewController:self];
        [self reload];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return self.info.count;
        case 1:
            return self.object.supportedMethodKeys.count;
        case 2:
            return self.actions.count;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Info";
        case 1:
            return @"Methods";
        case 2:
            return @"Actions";
        default:
            return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            return [self infoCellForRow:indexPath.row];
        case 1:
            return [self methodCellForRow:indexPath.row];
        case 2:
            return [self actionCellForRow:indexPath.row];
        default:
            return nil;
    }
}

- (UITableViewCell*)infoCellForRow:(NSUInteger)row
{
    static NSString* reuseIdentifier = @"info";
    
    __weak DeezerItemViewController *my = self;
    NSString *title = [self.object.supportedInfoKeys objectAtIndex:row];
    id value = [self.info objectAtIndex:row];
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    
    cell.textLabel.text = [@[title, value] componentsJoinedByString:@": "];
    if ([value isKindOfClass:[DZRObject class]]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if ([value conformsToProtocol:NSProtocolFromString(@"DZRIllustratable")]) {
        UIImage *cachedImage = [self.imageCache objectForKey:value];
        if (!cachedImage) {
            [(DZRObject<DZRIllustratable>*)value
             illustrationWithRequestManager:self.manager
             callback:^(UIImage *illustration, NSError *error) {
                 if (error) return;
                 [my.imageCache setObject:illustration forKey:value];
                 cell.imageView.image = illustration;
                 [cell setNeedsLayout];
             }];
        }
        else {
            cell.imageView.image = cachedImage;
        }
    }
    else {
        cell.imageView.image = nil;
    }
    return cell;
}

- (UITableViewCell*)methodCellForRow:(NSUInteger)row
{
    static NSString * reuseIdentifier = @"method";
    NSString *title = [self.object.supportedMethodKeys objectAtIndex:row];
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = title;
    return cell;
}

- (UITableViewCell*)actionCellForRow:(NSUInteger)row
{
    static NSString *reuseIdentifier = @"action";
    NSString *title = ((DeezerItemViewControllerAction*)[self.actions objectAtIndex:row]).title;
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = title;
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            id value = [self.info objectAtIndex:indexPath.row];
            
            if ([value isKindOfClass:[DZRObject class]]) {
                DeezerItemViewController *details = [[DeezerItemViewController alloc] initWithDZRObject:value];
                [[self navigationController] pushViewController:details animated:YES];
            }
        }
            break;
        case 1: {
            NSString *method = [self.object.supportedMethodKeys objectAtIndex:indexPath.row];
            [self.object
                    valueForKey:method
             withRequestManager:self.manager
                       callback:^(id value, NSError *error) {
                if (error) {
                    [self presentError:error];
                }
                else if ([value isKindOfClass:[DZRObjectList class]] && [self.object isPlayable]) {
                    UIViewController *details = [[DeezerObjectListViewController alloc] initWithDZRObjectList:value fromPlayable:(id<DZRPlayable>)self.object];
                    [self.navigationController pushViewController:details animated:YES];
                }
                else if ([value isKindOfClass:[DZRObjectList class]]) {
                    UIViewController *details = [[DeezerObjectListViewController alloc] initWithDZRObjectList:value];
                    [self.navigationController pushViewController:details animated:YES];
                }
                else if ([value isKindOfClass:[DZRObject class]]) {
                    DeezerItemViewController *details = [[DeezerItemViewController alloc] initWithDZRObject:value];
                    [[self navigationController] pushViewController:details animated:YES];
                }
                else if ([value isKindOfClass:[NSDictionary class]]) {
                    [UIAlertController alertWithTitle:alertTitleData
                                              message:[value toString]
                                       fromController:self];
                }
                else {
#pragma warning Implement
                }
            }];
        }
            break;
        case 2: {
            ((DeezerItemViewControllerAction*)[self.actions objectAtIndex:indexPath.row]).block();
        }
        default:
            break;
    }
}

#pragma mark DeezerSearchViewControllerDelegate

- (id<DeezerSearchViewControllerDelegate>)addSearchDelegateBlock:(void (^)(NSArray *, DZRRequestManager *, DeezerItemViewController *))block
                                                     forSearchVC:(DeezerSearchViewController *)vc
{
    [self.delegateMap setObject:block forKey:vc];
    return self;
}

- (void)searchViewController:(DeezerSearchViewController *)SearchViewController didSelectObjects:(NSArray *)objects
{
    void (^block)(NSArray*, DZRRequestManager*, DeezerItemViewController*) = [self.delegateMap objectForKey:SearchViewController];
    if (block) block(objects, self.manager, self);
}

#pragma mark DeezerObjectListViewControllerDelegate

- (id<DeezerObjectListViewControllerDelegate>)addObjectListDelegate:(BOOL (^)(NSArray *objects, DZRRequestManager *, DeezerItemViewController *))block
                                                    forObjectListVC:(DeezerObjectListViewController *)vc
{
    [self.delegateMap setObject:block forKey:vc];
    return self;
}

- (BOOL)objectListViewControllor:(DeezerObjectListViewController *)objectList didSelectObjects:(NSArray *)objects
{
    BOOL (^block)(NSArray*, DZRRequestManager*, DeezerItemViewController*) = [self.delegateMap objectForKey:objectList];
    if (block) {
        return block(objects, self.manager, self);
    }
    else {
        return NO;
    }
}

#pragma mark DeezerInputViewController

- (id<DeezerInputViewControllerDelegate>)addInputDelegate:(void (^)(NSDictionary *, DZRRequestManager *, DeezerItemViewController *))block
                                               forInputVC:(DeezerInputViewController *)vc
{
    [self.delegateMap setObject:block forKey:vc];
    return self;
}

- (void)deezerInputViewController:(DeezerInputViewController *)inputViewController didFinihEditing:(NSDictionary *)fields
{
    void (^block)(NSDictionary*, DZRRequestManager*, DeezerItemViewController*) = [self.delegateMap objectForKey:inputViewController];
    if (block) {
        block(fields, self.manager, self);
    }
}
@end
