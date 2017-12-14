//
//  NSDictionary+Utils.m
//  DeezerSample
//
//  Created by Guillaume Mirambeau on 06/01/2017.
//  Copyright © 2017 Deezer. All rights reserved.
//

#import "NSDictionary+Utils.h"

@implementation NSDictionary (Utils)

- (NSString *)toString {
    NSMutableString *mutableString = [[NSMutableString alloc] init];
    
    for (NSString *key in [self allKeys]) {
        [mutableString appendFormat:@"%@ : %@\n", key, [self objectForKey:key]];
    }
    
    return mutableString;
}

@end
