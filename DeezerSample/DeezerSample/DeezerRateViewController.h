//
//  DeezerRateViewController.h
//  DeezerSample
//
//  Created by GFaure on 12/05/2014.
//  Copyright (c) 2014 Deezer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DZRModel.h"

@interface DeezerRateViewController : UIViewController
@property (nonatomic, strong) DZRObject<DZRRatable> *object;
@end
