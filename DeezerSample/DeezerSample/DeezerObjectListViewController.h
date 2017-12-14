//
//  DeezerObjectListViewController.h
//  DeezerSample
//
//  Created by GFaure on 09/05/2014.
//  Copyright (c) 2014 Deezer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DZRObject.h"

@class DZRObjectList;
@class DeezerObjectListViewController;

@protocol DeezerObjectListViewControllerDelegate <NSObject>
- (BOOL)objectListViewControllor:(DeezerObjectListViewController*)objectList
                didSelectObjects:(NSArray*)objects;
@end

@interface DeezerObjectListViewController : UIViewController
@property (nonatomic, weak) id<DeezerObjectListViewControllerDelegate> delegate;
- (id)initWithDZRObjectList:(DZRObjectList*)list;
- (id)initWithDZRObjectList:(DZRObjectList *)list fromPlayable:(id<DZRPlayable>)playable;
@end
