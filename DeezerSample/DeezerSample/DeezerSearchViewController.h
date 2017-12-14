#import <UIKit/UIKit.h>
#import "DeezerSession.h"

typedef enum {
    SearchButton_TRACKS   = 1 << 0,
    SearchButton_ARTISTS  = 1 << 1,
    SearchButton_ALBUMS   = 1 << 2,
    SearchButton_PODCASTS = 1 << 3,
    SearchButton_EPISODES = 1 << 4,
} SearchButton;

@class DeezerSearchViewController;

@protocol DeezerSearchViewControllerDelegate <NSObject>
- (void)searchViewController:(DeezerSearchViewController*)SearchViewController didSelectObjects:(NSArray*)objects;
@end

@interface DeezerSearchViewController : UIViewController <DeezerSessionRequestDelegate, UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITextField* _textField;
    IBOutlet UIButton* _searchTrackButton;
    IBOutlet UIButton* _searchArtistButton;
    IBOutlet UIButton* _searchAlbumButton;
    IBOutlet UIButton* _searchPodcastButton;

    IBOutlet UITableView* _tableView;
    
    NSArray* _resultArray;
}

@property (nonatomic, weak) id<DeezerSearchViewControllerDelegate> delegate;
@property (nonatomic, assign) NSInteger activeButtons;

- (id)initWithActiveButtons:(NSInteger)activeButtons;

@end
