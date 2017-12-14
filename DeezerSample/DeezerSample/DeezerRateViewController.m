//
//  DeezerRateViewController.m
//  DeezerSample
//
//  Created by GFaure on 12/05/2014.
//  Copyright (c) 2014 Deezer. All rights reserved.
//

#import "DeezerRateViewController.h"

#import "DZRRequestManager.h"

@interface DeezerRateViewController ()
{
    IBOutlet UIButton *rate;
    IBOutlet UIButton *note1;
    IBOutlet UIButton *note2;
    IBOutlet UIButton *note3;
    IBOutlet UIButton *note4;
    IBOutlet UIButton *note5;
    
    NSUInteger note;
    
    CADisplayLink *link;
}

@end

@implementation DeezerRateViewController
- (id)init
{
    NSString* nibName;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        nibName = @"DeezerRateViewController_iPhone";
    } else {
        nibName = @"DeezerRateViewController_iPad";
    }
    
    return [super initWithNibName:nibName bundle:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    link = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    link.frameInterval = 5;
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [link invalidate];
}

- (void)render:(CADisplayLink*)link
{
    [@[note1, note2, note3, note4, note5] enumerateObjectsUsingBlock:^(UIButton *notei, NSUInteger idx, BOOL *stop) {
        if (idx+1 <= note) {
            notei.highlighted = YES;
        }
        else {
            notei.highlighted = NO;
        }
    }];
}

- (IBAction)setNote:(id)sender
{
    note = [@[note1, note2, note3, note4, note5] indexOfObject:sender] + 1;
}

- (IBAction)rate:(id)sender
{
    [self.object rateObject:note withRequestManager:[DZRRequestManager defaultManager] callback:^(NSError *error) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
