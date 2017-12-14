//
//  UIAlertController+Utils.h
//  DeezerSample
//
//  Created by Guillaume Mirambeau on 06/01/2017.
//  Copyright © 2017 Deezer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Utils)

+ (void)alertWithTitle:(NSString *)title
               message:(NSString *)message
        fromController:(UIViewController *)controller;

@end
