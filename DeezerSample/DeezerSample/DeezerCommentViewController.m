//
//  DeezerCommentViewController.m
//  DeezerSample
//
//  Created by GFaure on 12/05/2014.
//  Copyright (c) 2014 Deezer. All rights reserved.
//

#import "DeezerCommentViewController.h"
#import "DZRRequestManager.h"

@interface DeezerCommentViewController () <UITextViewDelegate>
{
    IBOutlet UITextView *text;
    IBOutlet UIButton *comment;
    
    Boolean keyboardIsShowing;
    CGRect keyboardBounds;
}

@end

@implementation DeezerCommentViewController
- (id)init
{
    NSString* nibName;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        nibName = @"DeezerCommentViewController_iPhone";
    } else {
        nibName = @"DeezerCommentViewController_iPad";
    }
    
    return [super initWithNibName:nibName bundle:nil];
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    [[NSNotificationCenter defaultCenter]
//     addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter]
//     addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
//}
//
//- (void)viewWillDisappear:(BOOL)animated {
//	[[NSNotificationCenter defaultCenter]
//     removeObserver:self name:UIKeyboardWillShowNotification object:nil];
//	[[NSNotificationCenter defaultCenter]
//     removeObserver:self name:UIKeyboardWillHideNotification object:nil];
//}
//
#pragma mark Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	[keyboardBoundsValue getValue:&keyboardBounds];
	keyboardIsShowing = YES;
	[self resizeViewControllerToFitScreen];
}

- (void)keyboardWillHide:(NSNotification *)note {
	keyboardIsShowing = NO;
	keyboardBounds = CGRectMake(0, 0, 0, 0);
	[self resizeViewControllerToFitScreen];
}

- (void)resizeViewControllerToFitScreen {
	// Needs adjustment for portrait orientation!
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	CGRect frame = self.view.frame;
	frame.size.height = applicationFrame.size.height;
    
	if (keyboardIsShowing)
		frame.size.height -= keyboardBounds.size.height;
    
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.3f];
	self.view.frame = frame;
	[UIView commitAnimations];
}

- (IBAction)comment:(id)sender
{
    [self.object
     postComment:text.text withRequestManager:[DZRRequestManager defaultManager]
     callback:^(DZRComment *c, NSError *error) {
         [self.navigationController popViewControllerAnimated:YES];
     }];
}
@end
