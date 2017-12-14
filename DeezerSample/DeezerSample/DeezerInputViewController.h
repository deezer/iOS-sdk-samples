//
//  DeezerInputViewController.h
//  DeezerSample
//
//  Created by GFaure on 13/05/2014.
//  Copyright (c) 2014 Deezer. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DeezerInputViewController;

@protocol DeezerInputViewControllerDelegate <NSObject>
- (void)deezerInputViewController:(DeezerInputViewController*)inputViewController didFinihEditing:(NSDictionary*)fields;
@end

@interface DeezerInputViewController : UIViewController
- (id)initWithFields:(NSArray*)fields;
@property (nonatomic, weak) id<DeezerInputViewControllerDelegate> delegate;
@end
