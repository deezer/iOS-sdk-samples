//
//  DeezerInputViewController.m
//  DeezerSample
//
//  Created by GFaure on 13/05/2014.
//  Copyright (c) 2014 Deezer. All rights reserved.
//

#import "DeezerInputViewController.h"
#import <string.h>

@interface DeezerInputViewController ()
{
    BOOL keyboardIsShown;
    CGRect originalFrame;
}
@property (nonatomic, strong) NSArray *fields;
@property (nonatomic, strong) NSMutableDictionary *inputs;
@end

@implementation DeezerInputViewController

- (id)initWithFields:(NSArray*)fields
{
    self = [super init];
    if (self) {
        self.fields = fields;
        self.inputs = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardWillShow:)
     name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardWillHide:)
     name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIKeyboardWillHideNotification object:nil];
}

- (void)loadView
{
    UIScrollView *view = [[UIScrollView alloc]
                          initWithFrame:[UIScreen mainScreen].bounds];
    originalFrame = [UIScreen mainScreen].bounds;
    view.backgroundColor = [UIColor whiteColor];
    CGRect frame = CGRectMake(5, 5, view.bounds.size.width - 10, 31);
    for (id f in self.fields) {
        NSString *s;
        id v = @"";
        if ([f isKindOfClass:[NSString class]]) {
            s = f;
        }
        else if ([f isKindOfClass:[NSArray class]]){
            s = [f objectAtIndex:0];
            v = [f objectAtIndex:1];
        }
        
        if ([v isKindOfClass:[NSNumber class]]
            && strcmp(@encode(BOOL), ((NSNumber*)v).objCType) == 0
            && ([(NSNumber*)v charValue] == 0 || [(NSNumber*)v charValue] == 1)) {
            v = [(NSNumber*)v boolValue] ? @"true" : @"false";
        }
        
        UILabel *l;
        UITextField *t;
        
        l = [[UILabel alloc] init];
        l.frame = frame;
        l.text = [s stringByAppendingString:@":"];
        frame = CGRectApplyAffineTransform(frame, CGAffineTransformMakeTranslation(0, frame.size.height + 5));
        [view addSubview:l];
        
        t = [[UITextField alloc] init];
        t.frame = frame;
        t.borderStyle = UITextBorderStyleLine;
        t.text = [v stringValue];
        frame = CGRectApplyAffineTransform(frame, CGAffineTransformMakeTranslation(0, frame.size.height + 10));
        [view addSubview:t];
        [self.inputs setObject:t forKey:s];
    }
    
    UIButton *validate = [[UIButton alloc] initWithFrame:frame];
    [validate setTitle:@"OK" forState:UIControlStateNormal];
    [validate setTitle:@"OK" forState:UIControlStateSelected];
    [validate setTitle:@"OK" forState:UIControlStateHighlighted];
    [validate setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    validate.layer.borderColor = [UIColor redColor].CGColor;
    validate.layer.borderWidth = 1;
    [validate addTarget:self action:@selector(confirm:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:validate];
    
    view.contentSize = CGSizeMake(view.bounds.size.width, CGRectGetMaxY(validate.frame) + 5);
    
    self.view = view;
}

- (void)keyboardWillHide:(NSNotification *)n
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view setFrame:originalFrame];
    [UIView commitAnimations];
    
    keyboardIsShown = NO;
}

- (void)keyboardWillShow:(NSNotification *)n
{
    if (keyboardIsShown) {
        return;
    }
    
    originalFrame = self.view.frame;
    NSDictionary* userInfo = [n userInfo];
    
    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // resize the noteView
    CGRect viewFrame = self.view.frame;
    // I'm also subtracting a constant kTabBarHeight because my UIScrollView was offset by the UITabBar so really only the portion of the keyboard that is leftover pass the UITabBar is obscuring my UIScrollView.
    viewFrame.size.height -= keyboardSize.height;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view setFrame:viewFrame];
    [UIView commitAnimations];
    keyboardIsShown = YES;
}

- (IBAction)confirm:(id)sender
{
    if (self.delegate) {
        NSMutableDictionary *inputedText = [NSMutableDictionary dictionary];
        for (NSString *field in self.inputs.allKeys) {
            [inputedText setObject:[[self.inputs valueForKey:field] text] forKey:field];
        }
        [self.delegate deezerInputViewController:self didFinihEditing:[NSDictionary dictionaryWithDictionary:inputedText]];
    }
    [self.navigationController popViewControllerAnimated:YES];
}
@end
