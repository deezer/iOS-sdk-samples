//
//  UIAlertController+Utils.m
//  DeezerSample
//
//  Created by Guillaume Mirambeau on 06/01/2017.
//  Copyright © 2017 Deezer. All rights reserved.
//

#import "UIAlertController+Utils.h"

static NSString * const okActionTitle = @"OK";

@implementation UIAlertController (Utils)

+ (void)alertWithTitle:(NSString *)title
               message:(NSString *)message
        fromController:(UIViewController *)controller {
    // Alert
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    // Action
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:okActionTitle
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                         }];
    [alertController addAction:cancelAction];
    
    // Show alert
    [controller presentViewController:alertController
                             animated:YES
                           completion:nil];
}

@end
