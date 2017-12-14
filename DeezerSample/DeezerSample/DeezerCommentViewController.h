//
//  DeezerCommentViewController.h
//  DeezerSample
//
//  Created by GFaure on 12/05/2014.
//  Copyright (c) 2014 Deezer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DZRModel.h"

@interface DeezerCommentViewController : UIViewController
@property (nonatomic, strong) DZRObject<DZRCommentable> *object;
@end
