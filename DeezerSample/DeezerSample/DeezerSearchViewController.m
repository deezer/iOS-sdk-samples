#import "DeezerSearchViewController.h"
#import "DZRModel.h"
#import "DZRRequestManager.h"
#import "DeezerItemViewController.h"

@interface DeezerSearchCell : UITableViewCell
@property (nonatomic, strong) DZRNetworkRequest *illustrationRequest;
@property (nonatomic, strong) DZRObject *object;

+ (NSString *)reuseIdentifier;
- (instancetype)init;
@end

@implementation DeezerSearchCell

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass(self);
}

+ (NSCache *)imageCache
{
    static NSCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
                  ^{
                      cache = [[NSCache alloc] init];
                  });

    return cache;
}

- (instancetype)init
{
    return [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[[self class] reuseIdentifier]];
}

- (void)prepareForReuse
{
    self.illustrationRequest = nil;
    self.imageView.image = nil;
}

- (void)setIllustrationRequest:(DZRNetworkRequest *)illustrationRequest
{
    if (_illustrationRequest != illustrationRequest) {
        [_illustrationRequest cancel];
        _illustrationRequest = illustrationRequest;
    }
}

- (void)setObject:(DZRObject *)object
{
    _object = object;
    self.illustrationRequest = nil;
    self.textLabel.text = [object description];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if ([object conformsToProtocol:NSProtocolFromString(@"DZRIllustratable")]) {
        UIImage *cachedImage = [[DeezerSearchCell imageCache] objectForKey:object.identifier];
        if (!cachedImage) {
            self.imageView.image = [UIImage imageNamed:@"CellPlaceHolder"];
            self.illustrationRequest = [(DZRObject<DZRIllustratable> *)object
                illustrationWithRequestManager:[DZRRequestManager defaultManager]
                                      callback:^(UIImage *illustration, NSError *error) {
                                          if (illustration && self.object == object) {
                                              [[DeezerSearchCell imageCache] setObject:illustration
                                                                                forKey:object.identifier];
                                              self.imageView.image = illustration;
                                          }
                                      }];
        }
        else {
            self.imageView.image = cachedImage;
        }
    }
}
@end

@interface DeezerSearchViewController ()
@property (nonatomic, strong) NSArray *resultArray;
@property (nonatomic, strong) DZRRequestManager *manager;
@end

@implementation DeezerSearchViewController

- (id)initWithActiveButtons:(NSInteger)activeButtons
{
    NSString *nibName = @"DeezerSearchViewController";

    if (self = [super initWithNibName:nibName bundle:nil]) {
        [self setTitle:@"Search"];
        _activeButtons = activeButtons;
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setActiveButtons:_activeButtons];
    self.manager = [[DZRRequestManager defaultManager] subManager];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.manager cancel];
    self.manager = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
    else {
        return YES;
    }
}

- (void)setActiveButtons:(NSInteger)activeButtons
{
    _activeButtons = activeButtons;
    [_searchTrackButton setEnabled:(activeButtons & SearchButton_TRACKS)];
    [_searchArtistButton setEnabled:(activeButtons & SearchButton_ARTISTS)];
    [_searchAlbumButton setEnabled:(activeButtons & SearchButton_ALBUMS)];
    [_searchPodcastButton setEnabled:(activeButtons & SearchButton_PODCASTS)];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_resultArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DZRObject *o = [self.resultArray objectAtIndex:indexPath.row];

    DeezerSearchCell *cell = [_tableView dequeueReusableCellWithIdentifier:[DeezerSearchCell reuseIdentifier]];
    if (cell == nil) {
        cell = [[DeezerSearchCell alloc] init];
    }

    cell.object = o;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DZRObject *o = [self.resultArray objectAtIndex:indexPath.row];
    if (self.delegate) {
        [self.delegate searchViewController:self didSelectObjects:@[ o ]];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        DeezerItemViewController *vc = [[DeezerItemViewController alloc] initWithDZRObject:o];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - IBActions

- (IBAction)onSearchButtonPressed:(UIButton *)button {
    if (_textField.text.length > 0) {
        DZRSearchType searchType = [self searchTypeForButton:button];
        [self requestObjectFromSearchType:searchType];
    }
    
    [_textField resignFirstResponder];
}

#pragma mark - Internal method

- (void)requestObjectFromSearchType:(DZRSearchType)searchType {
    [DZRObject searchFor:searchType
               withQuery:_textField.text
          requestManager:self.manager
                callback:^(DZRObjectList *results, NSError *error) {
                    [self presentError:error];
                    
                    [results allObjectsWithManager:self.manager
                                          callback:^(NSArray *objs, NSError *error) {
                                              self.resultArray = objs;
                                              [_tableView reloadData];
                                          }];
                }];
}

- (DZRSearchType)searchTypeForButton:(UIButton *)button {
    DZRSearchType type = DZRSearchTypeTrack;
    if (button == _searchTrackButton) {
        type = DZRSearchTypeTrack;
    }
    else if (button == _searchArtistButton) {
        type = DZRSearchTypeArtist;

    }
    else if (button == _searchAlbumButton) {
        type = DZRSearchTypeAlbum;
    }
    else if (button == _searchPodcastButton) {
        type = DZRSearchTypePodcast;
    }
    return type;
}

@end
