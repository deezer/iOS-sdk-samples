//
//  DeezerObjectListViewController.m
//  DeezerSample
//
//  Created by GFaure on 09/05/2014.
//  Copyright (c) 2014 Deezer. All rights reserved.
//

#import "DeezerObjectListViewController.h"
#import "DeezerItemViewController.h"
#import "DZRModel.h"
#import "DZRRequestManager.h"
#import "DZRCancelable.h"
#import "DeezerAudioPlayerController.h"

@interface DeezerObjectListViewController () <UITableViewDataSource, UITableViewDelegate>
{
    IBOutlet UITableView *objectsView;
}

@property(nonatomic, strong) DZRRequestManager *manager;
@property(nonatomic, strong) DZRRequestManager *illustrationManager;
@property(nonatomic, strong) DZRObjectList *list;
@property(nonatomic, strong) id<DZRPlayable> playable;
@property(nonatomic, strong) NSArray *data;
@property(nonatomic, strong) NSCache *imageCache;
@end

@implementation DeezerObjectListViewController

- (id)initWithDZRObjectList:(DZRObjectList *)list
{
    return [self initWithDZRObjectList:list fromPlayable:nil];
}

- (id)initWithDZRObjectList:(DZRObjectList *)list fromPlayable:(id)playable
{
    NSString *nibName;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        nibName = @"DeezerObjectListViewController_iPhone";
    } else {
        nibName = @"DeezerObjectListViewController_iPad";
    }

    if (self = [super initWithNibName:nibName bundle:nil]) {
        self.imageCache = [NSCache new];
        self.imageCache.countLimit = 50;
        self.manager = [[DZRRequestManager defaultManager] subManager];
        self.list = list;
        self.playable = playable;
    }
    return self;
}

- (void)dealloc
{
    self.data = nil;
    [self.manager cancel];
    self.manager = nil;
    self.imageCache = nil;
    self.list = nil;
}

- (void)setList:(DZRObjectList *)list
{
    if (_list != list) {
        _list = list;
        [_list allObjectsWithManager:self.manager callback:^(NSArray *objs, NSError *error) {
            self.data = objs;
            [objectsView reloadData];
            [self scrollViewDidEndDecelerating:objectsView];
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [objectsView reloadData];
    [self scrollViewDidEndDecelerating:objectsView];
}

#pragma mark UITableVieWDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"item";
    DZRObject *o = [self.data objectAtIndex:indexPath.row];

    UITableViewCell *cell = [objectsView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }

    cell.textLabel.text = [o description];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;

    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DZRObject *o = [self.data objectAtIndex:indexPath.row];

    if (self.delegate && [self.delegate objectListViewControllor:self didSelectObjects:@[o]]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        if (self.playable != nil) {
            DeezerAudioPlayerController *playerVC = [[DeezerAudioPlayerController alloc] initWithPlayable:self.playable startIndex:indexPath.row];
            [self.navigationController pushViewController:playerVC animated:YES];
        }
        else {
            DeezerItemViewController *details = [[DeezerItemViewController alloc] initWithDZRObject:o];
            [self.navigationController pushViewController:details animated:YES];
        }
    }
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.illustrationManager = [self.manager subManager];
    [[objectsView visibleCells] enumerateObjectsUsingBlock:^(UITableViewCell *cell, NSUInteger idx, BOOL *stop) {
        DZRObject *o = [self.data objectAtIndex:[objectsView indexPathForCell:cell].row];
        if (o.isIllustratable) {
            UIImage *cachedImage = [self.imageCache objectForKey:o];
            __weak NSCache *cache = self.imageCache;
            if (!cachedImage) {
                [(DZRObject <DZRIllustratable> *) o
                        illustrationWithRequestManager:self.manager
                                              callback:^(UIImage *illustration, NSError *error)
                        {
                            if (illustration) {
                                [cache setObject:illustration forKey:o];
                                cell.imageView.image = illustration;
                                [cell setNeedsLayout];
                            }
                        }];
            }
            else {
                cell.imageView.image = cachedImage;
                [cell setNeedsLayout];
            }
        }
    }];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.illustrationManager cancel];
    self.illustrationManager = nil;
}
@end
