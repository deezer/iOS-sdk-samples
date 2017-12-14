//
//  ConnectionCell.m
//  DeezerSample
//
//  Created by Hadrien Pezier on 13/03/12.
//  Copyright (c) 2012 Deezer. All rights reserved.
//

#import "ConnectionCell.h"

@implementation ConnectionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
